USE caso3;
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'VentasRango')
    DROP PROCEDURE VentasRango;
GO

CREATE PROCEDURE VentasRango
    @RangoInicial DATETIME,
    @RangoFinal DATETIME
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
        SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
        BEGIN TRANSACTION;
    END;

    BEGIN TRY
        SET @CustomError = 2001;
        SELECT *
        FROM ventas 
        WHERE fecha >= @RangoInicial and fecha <= @RangoFinal
		SELECT @Total = sum(monto) from ventas;
		PRINT Cast(@Total as varchar(10));
        WAITFOR DELAY '00:00:06'
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
DECLARE @RangoInicial DATETIME = '2023-05-01';
DECLARE @RangoFinal DATETIME = '2023-05-31';

EXEC VentasRango @RangoInicial, @RangoFinal;
WAITFOR DELAY '00:00:03'
EXEC VentasRango @RangoInicial, @RangoFinal;

--select * from productos_producidos;
--select * from ventas;
--delete from ventas where venta_id>0;
--DBCC CHECKIDENT(ventas, RESEED, 0);
--update productos_producidos set cantidad = 30 where producto_id = 2;

/*Aqui ocurre un phantom read. Esto es porque la transaccion VentaRango
lee las ventas y devuelve todas las ventas que ocurrieron en un mes dado, tambien
sumando el monto ganado en dicho mes. Al mismo tiempo la transaccion de ventas inserta 
una venta nueva que cumple con el rango de fechas, cambiando el resultado que 
retorna VentaRango. La segunda vez que se corre VentaRango, se lee la nueva venta 
creando un 'Phantom' en la segunda lectura.