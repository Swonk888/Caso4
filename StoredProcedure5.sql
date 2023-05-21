USE caso3;
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'CancelarProd')
    DROP PROCEDURE CancelarProd;
GO

CREATE PROCEDURE CancelarProd
    @recolectorID SMALLINT,
	@prodID SMALLINT
AS
BEGIN
    SET NOCOUNT ON; -- do not return metadata

    DECLARE @ErrorNumber INT, @ErrorSeverity INT, @ErrorState INT, @CustomError INT;
    DECLARE @Message VARCHAR(200);
    DECLARE @InicieTransaccion BIT;
    DECLARE @CantAct INT;

    SET @InicieTransaccion = 0;
    IF @@TRANCOUNT = 0 BEGIN
        SET @InicieTransaccion = 1;
        SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
        BEGIN TRANSACTION;
    END;

    BEGIN TRY
        
		UPDATE recolectores set balance = balance-100 WHERE recolector_id = @recolectorID;

		WAITFOR DELAY '00:00:06'

		UPDATE productos_producidos set cantidad = cantidad-1 WHERE producto_id = @prodID;

        IF @InicieTransaccion = 1 BEGIN
            COMMIT;
        END;
    END TRY
    BEGIN CATCH
        SET @ErrorNumber = ERROR_NUMBER();
        SET @ErrorSeverity = ERROR_SEVERITY();
        SET @ErrorState = ERROR_STATE();
        SET @Message = ERROR_MESSAGE();

        IF @InicieTransaccion = 1 BEGIN
            ROLLBACK;
        END;
        RAISERROR('%s - Error Number: %i',
            @ErrorSeverity, @ErrorState, @Message, @CustomError);
    END CATCH;
END;
GO

-- Call the stored procedure to insert the data
DECLARE @recolectorID SMALLINT = 5;
DECLARE @prodID SMALLINT = 2;

EXEC CancelarProd @recolectorID, @prodID;

--select * from productos_producidos;
--select * from recolectores;
--delete from ventas where venta_id>0;
--DBCC CHECKIDENT(ventas, RESEED, 0);
--update productos_producidos set cantidad = 200 where producto_id = 2;
--ROLLBACK;

/* En este caso, corriendo este transaction simultaneamente con insertar ventas (sp1)
cuando en insertar ventas ocurre un rollback por cualquier error, la transaccion 
de agregar productos lee y utiliza los datos antes de que el rollback ocurra causando un 
dirty read, donde no se toma en cuenta que insertar ventas realmente no ocurrió
*/
