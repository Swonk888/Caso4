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
    DECLARE @Contrato_id SMALLINT
    DECLARE @Recolector_id SMALLINT

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

        -- Actualizar cantidad
        UPDATE pp
        SET cantidad = pp.cantidad - v.cantidad
        FROM productos_producidos pp
        INNER JOIN @ventasTVP v ON pp.producto_id = v.producto_id;

        WAITFOR DELAY '00:00:06'

		SELECT @Contrato_id = pp.contrato_id
        FROM productos_producidos pp
        INNER JOIN @ventasTVP v ON pp.producto_id = v.producto_id;

        SELECT @Recolector_id = c.recolector_id
        FROM contrato c WHERE c.contrato_id = @Contrato_id

		-- Actualizar balance en la tabla recolectores
        UPDATE recolectores
        SET balance = balance + ((v.cantidad * v.precioUnitario * tc.tipo_Cambio - proceso.costo) * contrato.porcentaje)
        FROM recolectores r
        INNER JOIN contrato ON contrato.recolector_id = r.recolector_id
        INNER JOIN productos_producidos pp ON pp.contrato_id = contrato.contrato_id
        INNER JOIN @ventasTVP v ON v.producto_id = pp.producto_id
        INNER JOIN tipo_cambio tc ON tc.tipo_cambio_id = v.tipo_cambio_id AND tc.moneda_id = v.moneda_id
        INNER JOIN proceso ON proceso.contrato_id = contrato.contrato_id
        WHERE r.recolector_id = @Recolector_id;

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


DECLARE @misVentas AS VentasTVP;

-- Rellenar la variable de tabla con los datos de venta
INSERT INTO @misVentas (producto_id, cantidad, precioUnitario, fecha, moneda_id, tipo_cambio_id)
VALUES
    (2, 10, 510.12, GETDATE(), 1, 1);

-- Llamar al stored procedure para insertar las ventas
EXEC InsertarVentas @ventasTVP = @misVentas;



/*
select * from ventas
DBCC CHECKIDENT ('ventas', RESEED, 0);
DELETE from ventas where venta_id>0;
ROLLBACK;
*/

