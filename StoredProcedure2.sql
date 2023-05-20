use caso3;
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'ProducirProductos')
    DROP PROCEDURE ProducirProductos;
GO
IF EXISTS (SELECT * FROM sys.table_types WHERE name = 'ProductosTVP')
    DROP TYPE ProductosTVP;
GO

CREATE TYPE ProductosTVP AS TABLE
(
    cantidad INT,
    posttime DATETIME,
    user_id SMALLINT,
    producto_id SMALLINT
    --contrato_id SMALLINT
);
GO

CREATE PROCEDURE ProducirProductos
    @productosTVP AS ProductosTVP READONLY
AS
BEGIN
    SET NOCOUNT ON -- no retorne metadatos

	DECLARE @ErrorNumber INT, @ErrorSeverity INT, @ErrorState INT, @CustomError INT
	DECLARE @Message VARCHAR(200)
	DECLARE @InicieTransaccion BIT

	SET @InicieTransaccion = 0
	IF @@TRANCOUNT=0 BEGIN
		SET @InicieTransaccion = 1
		SET TRANSACTION ISOLATION LEVEL READ COMMITTED
		BEGIN TRANSACTION
	END

	BEGIN TRY
		SET @CustomError = 2001

        UPDATE pp
        SET cantidad = pp.cantidad + p.cantidad
        FROM productos_producidos pp
        INNER JOIN @productosTVP p ON pp.producto_id = p.producto_id /*and pp.contrato_id = p.contrato_id*/;

		IF @InicieTransaccion=1 BEGIN
			COMMIT
		END
	END TRY
	BEGIN CATCH
		SET @ErrorNumber = ERROR_NUMBER()
		SET @ErrorSeverity = ERROR_SEVERITY()
		SET @ErrorState = ERROR_STATE()
		SET @Message = ERROR_MESSAGE()

		IF @InicieTransaccion=1 BEGIN
			ROLLBACK
		END
		RAISERROR('%s - Error Number: %i',
			@ErrorSeverity, @ErrorState, @Message, @CustomError)
	END CATCH
END
RETURN 0
GO

-- Para hacer inserts al TVP

DECLARE @misProductos AS ProductosTVP;

-- Rellenar la variable de tabla con los datos de venta
INSERT INTO @misProductos (cantidad, posttime, user_id, producto_id)
VALUES
    (32,'2023-05-20', 2, 2);

-- Llamar al stored procedure para insertar las ventas
EXEC ProducirProductos @productosTVP = @misProductos;



/*select * from productos_producidos
DBCC CHECKIDENT ('ventas', RESEED, 0);
DELETE from ventas where venta_id>0;*/