use caso3;
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'InsertarVentas')
    DROP PROCEDURE InsertarVentas;
GO
CREATE PROCEDURE InsertarVentas
    @producto_id INT,
    @cantidad INT,
    @precioUnitario DECIMAL(10, 2),
    @fecha DATE,
    @moneda_id INT,
    @tipo_cambio_id INT
AS
BEGIN
    SET NOCOUNT ON -- Do not return metadata

    DECLARE @ErrorNumber INT, @ErrorSeverity INT, @ErrorState INT, @CustomError INT
    DECLARE @Message VARCHAR(200)
    DECLARE @InicieTransaccion BIT

    SET @InicieTransaccion = 0
    IF @@TRANCOUNT = 0
    BEGIN
        SET @InicieTransaccion = 1
        SET TRANSACTION ISOLATION LEVEL READ COMMITTED
        BEGIN TRANSACTION
    END

    BEGIN TRY
        SET @CustomError = 2001

        -- Insertar venta
        INSERT INTO ventas (producto_id, monto, fecha, cantidad, moneda_id, tipo_cambio_id)
        SELECT  @producto_id, (@cantidad * @precioUnitario * tc.tipo_Cambio), @fecha, @cantidad, @moneda_id, @tipo_cambio_id
        FROM tipo_cambio tc
        WHERE tc.tipo_cambio_id = @tipo_cambio_id AND tc.moneda_id = @moneda_id;

        -- Actualizar cantidad
        WAITFOR DELAY '00:00:10'
        UPDATE pp
        SET cantidad = pp.cantidad - @cantidad
        FROM productos_producidos pp
        WHERE pp.producto_id = @producto_id;

        IF @InicieTransaccion = 1
        BEGIN
            COMMIT
        END
    END TRY
    BEGIN CATCH
        SET @ErrorNumber = ERROR_NUMBER()
        SET @ErrorSeverity = ERROR_SEVERITY()
        SET @ErrorState = ERROR_STATE()
        SET @Message = ERROR_MESSAGE()

        IF @InicieTransaccion = 1
        BEGIN
            ROLLBACK
        END

        RAISERROR('%s - Error Number: %i',
            @ErrorSeverity, @ErrorState, @Message, @CustomError)
    END CATCH
END

EXEC InsertarVentas 2 ,13, 510.12, '2023-04-09',1,1;
