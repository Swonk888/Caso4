USE caso3;
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'cambioTipoCambio')
    DROP PROCEDURE cambioTipoCambio;
GO

CREATE PROCEDURE cambioTipoCambio
    @RangoInicial DATETIME,
    @RangoFinal DATETIME,
    @Moneda_id SMALLINT,
    @Nuevo DECIMAL (10,2)
AS
BEGIN
    SET NOCOUNT ON; -- do not return metadata

    DECLARE @ErrorNumber INT, @ErrorSeverity INT, @ErrorState INT, @CustomError INT;
    DECLARE @Message VARCHAR(200);
    DECLARE @InicieTransaccion BIT;
	Declare @Total INT;

    SET @InicieTransaccion = 0;
    IF @@TRANCOUNT = 0 BEGIN
        SET @InicieTransaccion = 1;
        BEGIN TRANSACTION;
    END;

    BEGIN TRY
        SET @CustomError = 2001;
        INSERT INTO tipo_cambio (fecha_inicio,fecha_final, moneda_id, [default], tipo_cambio, username, computer) values (@RangoInicial, @RangoFinal, @Moneda_id, 1, @nuevo, 'root', 'localhost');
        UPDATE monedas 
        SET tipo_cambio_actual = @Nuevo
        WHERE monedas.moneda_id = @Moneda_id
		WAITFOR DELAY '00:00:03'
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
DECLARE @RangoInicial DATETIME = GETDATE();
DECLARE @RangoFinal DATETIME = '2023-05-31';
DECLARE @Moneda_id SMALLINT = 1;
DECLARE @Nuevo DECIMAL (10,2) = 1.5;

EXEC cambioTipoCambio @RangoInicial, @RangoFinal, @Moneda_id, @Nuevo;

--select * from tipo_cambio;
--select * from ventas;
/*
delete from  tipo_cambio where tipo_cambio_id>1;
UPDATE monedas set tipo_cambio_actual = 1 where moneda_id = 1
DBCC CHECKIDENT(tipo_cambio, RESEED, 1);
*/
--update productos_producidos set cantidad = 30 where producto_id = 2;

/*Aqui ocurre un phantom read. La solucion está en el sp1 */

