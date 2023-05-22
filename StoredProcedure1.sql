use caso3;
GO
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
    DECLARE @Actor_id SMALLINT;

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
            SET balance = balance + ((v.cantidad * v.precioUnitario * tc.tipo_Cambio - proceso.costo) * axc.porcentaje)
            FROM actores a
            INNER JOIN actores_x_contrato axc ON axc.actor_id = a.actor_id
            INNER JOIN productos_producidos pp ON pp.contrato_id = axc.contrato_id
            INNER JOIN @ventasTVP v ON v.producto_id = pp.producto_id
            INNER JOIN tipo_cambio tc ON tc.tipo_cambio_id = v.tipo_cambio_id AND tc.moneda_id = v.moneda_id
            INNER JOIN proceso ON proceso.contrato_id = axc.contrato_id
            WHERE a.actor_id = @Actor_id;

            FETCH NEXT FROM actores_cursor INTO @Actor_id;
        END;

        CLOSE actores_cursor;
        DEALLOCATE actores_cursor;

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
GO

DECLARE @misVentas AS VentasTVP;

-- Rellenar la variable de tabla con los datos de venta
INSERT INTO @misVentas (producto_id, cantidad, precioUnitario, fecha, moneda_id, tipo_cambio_id)
VALUES
    (2, 1, 510.12, GETDATE(), 1, 1);

-- Llamar al stored procedure para insertar las ventas
EXEC InsertarVentas @ventasTVP = @misVentas;



/*select * from ventas
select * from productos_producidos
select* from recolectores;
select* from actores_x_contrato;
select* from actores;

DBCC CHECKIDENT ('ventas', RESEED, 0);
DELETE from ventas where venta_id>=0;
UPDATE productos_producidos set cantidad =  50 where producto_id=2;
*/

