use caso3;

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'InsertarVentas')
    DROP PROCEDURE InsertarVentas;
GO
IF EXISTS (SELECT * FROM sys.table_types WHERE name = 'VentasTVP')
    DROP TYPE VentasTVP;
GO
CREATE TYPE VentasTVP AS TABLE
(
    producto_id INT,
    cantidad INT,
    precioUnitario DECIMAL(10, 2),
    fecha DATE,
    moneda_id INT,
    tipo_cambio_id INT
);
GO
CREATE PROCEDURE InsertarVentas
    @ventasTVP AS VentasTVP READONLY
AS
BEGIN
    SET NOCOUNT ON -- do not return metadata

    DECLARE @ErrorNumber INT, @ErrorSeverity INT, @ErrorState INT, @CustomError INT
    DECLARE @Message VARCHAR(200)
    DECLARE @InicieTransaccion BIT
	DECLARE @Total DECIMAL(10,2)

    SET @InicieTransaccion = 0
    IF @@TRANCOUNT = 0 BEGIN
        SET @InicieTransaccion = 1
        SET TRANSACTION ISOLATION LEVEL READ COMMITTED
        BEGIN TRANSACTION
    END

    BEGIN TRY
        SET @CustomError = 2001

        -- Insertar ventas
        INSERT INTO ventas (producto_id, monto, fecha, cantidad, moneda_id, tipo_cambio_id)
        SELECT v.producto_id, (v.cantidad * v.precioUnitario * tc.tipo_Cambio), v.fecha, v.cantidad, v.moneda_id, v.tipo_cambio_id
        FROM @ventasTVP v
        INNER JOIN tipo_cambio tc ON v.tipo_cambio_id = tc.tipo_cambio_id AND v.moneda_id = tc.moneda_id;

		SELECT @Total = monto from ventas where ventas.venta_id = (select MAX(venta_id) from ventas)

        -- Actualizar cantidad
        UPDATE pp
        SET cantidad = pp.cantidad - v.cantidad
        FROM productos_producidos pp
        INNER JOIN @ventasTVP v ON pp.producto_id = v.producto_id;

        WAITFOR DELAY '00:00:05'


        -- Validate available quantity
        IF EXISTS (SELECT * FROM productos_producidos WHERE cantidad < 0)
        BEGIN
            IF @InicieTransaccion = 1
                ROLLBACK
            RAISERROR('Error: Product quantity cannot be negative.', 16, 1)
        END
        ELSE
        BEGIN
            IF @InicieTransaccion = 1
                COMMIT
        END
    END TRY
    BEGIN CATCH
        SET @ErrorNumber = ERROR_NUMBER()
        SET @ErrorSeverity = ERROR_SEVERITY()
        SET @ErrorState = ERROR_STATE()
        SET @Message = ERROR_MESSAGE()

        IF @InicieTransaccion = 1
            ROLLBACK

        RAISERROR('%s - Error Number: %i',
            @ErrorSeverity, @ErrorState, @Message, @CustomError)
    END CATCH
END
Return 0
Go

DECLARE @misVentas AS VentasTVP;

-- Rellenar la variable de tabla con los datos de venta
INSERT INTO @misVentas (producto_id, cantidad, precioUnitario, fecha, moneda_id, tipo_cambio_id)
VALUES
    (4, 1, 510.12, GETDATE(), 1, 1);

-- Llamar al stored procedure para insertar las ventas
EXEC InsertarVentas @ventasTVP = @misVentas;

/*select * from ventas
DBCC CHECKIDENT ('ventas', RESEED, 0);
DELETE from ventas where venta_id>0;*/

