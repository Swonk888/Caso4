use caso3;
GO
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'RealizarPagos')
    DROP PROCEDURE RealizarPagos;
GO

CREATE PROCEDURE RealizarPagos
    @Contrato_id SMALLINT
AS
BEGIN
    SET NOCOUNT ON -- do not return metadata

    DECLARE @ErrorNumber INT, @ErrorSeverity INT, @ErrorState INT, @CustomError INT
    DECLARE @Message VARCHAR(200)
    DECLARE @InicieTransaccion BIT
    DECLARE @Recolector_id SMALLINT
    DECLARE @Actor_id SMALLINT;

    SET @InicieTransaccion = 0
    IF @@TRANCOUNT = 0 BEGIN
        SET @InicieTransaccion = 1
        SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
        BEGIN TRANSACTION
    END

    BEGIN TRY
        SET @CustomError = 2001

        DECLARE actores_cursor CURSOR FOR
        SELECT ac.actor_id
        FROM actores_x_contrato ac
        INNER JOIN actores a ON ac.actor_id = a.actor_id
        WHERE ac.contrato_id = @Contrato_id;

        OPEN actores_cursor;
        FETCH NEXT FROM actores_cursor INTO @Actor_id;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Actualizar el balance de cada actor
            UPDATE actores
            SET balance = 0.0
            WHERE actor_id = @Actor_id;

            FETCH NEXT FROM actores_cursor INTO @Actor_id;
        END;

        CLOSE actores_cursor;
        DEALLOCATE actores_cursor;

        WAITFOR DELAY '00:00:05'


        SELECT @Recolector_id = c.recolector_id
        FROM contrato c WHERE c.contrato_id = @Contrato_id

        UPDATE recolectores 
        SET balance = 0.0
        WHERE recolector_id = @Recolector_id
        WAITFOR DELAY '00:00:05'
        
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
GO

EXEC RealizarPagos 10;

-- select * from recolectores
-- select * from actores

/*
Deadlock puede ocurrir cuando el SP de realizar pagos a los actores
Hace un lock a la tabla de actores_x_contrato y el de insertar ventas 
bloquea la tabla de recolectores. Asimismo el SP de pagos quiere usar
la tabla de recolectores pero esta está bloqueada por ventas. Ventas 
siguientemente quiere usar la tabla de actores_x_contrato pero 
tambien esta bloqueada. Ambos sp estan esperando a que el otro suelte
el lock pero esto nunca va a pasar. Esto ocurre cuando ambas SP
corren simultaneamente.
*/

/*Nueva Version

El deadlock se puede arreglar 


IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'RealizarPagos')
    DROP PROCEDURE RealizarPagos;
GO

CREATE PROCEDURE RealizarPagos
    @Contrato_id SMALLINT
AS
BEGIN
    SET NOCOUNT ON -- do not return metadata

    DECLARE @ErrorNumber INT, @ErrorSeverity INT, @ErrorState INT, @CustomError INT
    DECLARE @Message VARCHAR(200)
    DECLARE @InicieTransaccion BIT
    DECLARE @Recolector_id SMALLINT
    DECLARE @Actor_id SMALLINT;

    SET @InicieTransaccion = 0
    IF @@TRANCOUNT = 0 BEGIN
        SET @InicieTransaccion = 1
        SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
        BEGIN TRANSACTION
    END

    DECLARE @RetryCount INT
    SET @RetryCount = 0

    DECLARE @RetryLimit INT
    SET @RetryLimit = 5 -- Set the maximum number of retries

    DECLARE @RetryDelaySeconds INT
    SET @RetryDelaySeconds = 1 -- Set the delay between retries in seconds

    DECLARE @DeadlockErrorNumber INT
    SET @DeadlockErrorNumber = 1205

    RETRY:
    BEGIN TRY
        SET @CustomError = 2001

        DECLARE actores_cursor CURSOR FOR
        SELECT ac.actor_id
        FROM actores_x_contrato ac
        INNER JOIN actores a ON ac.actor_id = a.actor_id
        WHERE ac.contrato_id = @Contrato_id;

        OPEN actores_cursor;
        FETCH NEXT FROM actores_cursor INTO @Actor_id;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Actualizar el balance de cada actor
            UPDATE actores
            SET balance = 0.0
            WHERE actor_id = @Actor_id;

            FETCH NEXT FROM actores_cursor INTO @Actor_id;
        END;

        CLOSE actores_cursor;
        DEALLOCATE actores_cursor;

        WAITFOR DELAY '00:00:05'

        SELECT @Recolector_id = c.recolector_id
        FROM contrato c WHERE c.contrato_id = @Contrato_id

        UPDATE recolectores 
        SET balance = 0.0
        WHERE recolector_id = @Recolector_id

        WAITFOR DELAY '00:00:05'

        IF @InicieTransaccion = 1
            COMMIT
    END TRY
    BEGIN CATCH
        SET @ErrorNumber = ERROR_NUMBER()
        SET @ErrorSeverity = ERROR_SEVERITY()
        SET @ErrorState = ERROR_STATE()
        SET @Message = ERROR_MESSAGE()

        IF @InicieTransaccion = 1
            ROLLBACK

        -- Retry only if the error is a deadlock
        IF @ErrorNumber = @DeadlockErrorNumber AND @RetryCount < @RetryLimit
        BEGIN
            SET @RetryCount = @RetryCount + 1
            WAITFOR DELAY '00:00:00' + RIGHT('00' + CAST(@RetryDelaySeconds AS VARCHAR(2)), 2)
            GOTO RETRY
        END

        RAISERROR('%s - Error Number: %i',
            @ErrorSeverity, @ErrorState, @Message, @CustomError)
    END CATCH
END
GO
*/


