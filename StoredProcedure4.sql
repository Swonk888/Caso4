USE caso3;
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'ProducirProductos')
    DROP PROCEDURE ProducirProductos;
GO

CREATE PROCEDURE ProducirProductos
    @cantidad INT,
    @posttime DATETIME,
    @user_id SMALLINT,
    @producto_id SMALLINT,
    @contrato_id SMALLINT
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
        SET @CustomError = 2001;
        SELECT @CantAct = cantidad from productos_producidos where producto_id = @producto_id and contrato_id = @contrato_id;
        WAITFOR DELAY '00:00:05'
        UPDATE productos_producidos
        SET cantidad = @CantAct + @cantidad
        WHERE producto_id = @producto_id and contrato_id = @contrato_id;

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
DECLARE @cantidad INT = 5;
DECLARE @posttime DATETIME = '2023-05-20';
DECLARE @user_id SMALLINT = 2;
DECLARE @producto_id SMALLINT = 2;
DECLARE @contrato_id SMALLINT = 10;

EXEC ProducirProductos @cantidad, @posttime, @user_id, @producto_id, @contrato_id;

--select * from productos_producidos;
--select * from ventas;
--delete from ventas where venta_id>0;
--DBCC CHECKIDENT(ventas, RESEED, 0);
--update productos_producidos set cantidad = 30 where producto_id = 2;
