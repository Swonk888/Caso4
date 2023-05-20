use caso3;
CREATE TYPE VentasTVP AS TABLE
(
    venta_id INT,
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
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Insertar ventas
        INSERT INTO ventas (venta_id, producto_id, monto, fecha, cantidad, moneda_id, tipo_cambio_id)
        SELECT v.venta_id, v.producto_id, (v.cantidad * v.precioUnitario * tc.tipo_Cambio), v.fecha , v.cantidad, v.moneda_id, v.tipo_cambio_id
        FROM @ventasTVP v
        INNER JOIN tipo_cambio tc ON v.tipo_cambio_id = tc.tipo_cambio_id AND v.moneda_id = tc.moneda_id;

        -- Actualizar cantidad
        UPDATE pp
        SET cantidad = pp.cantidad - v.cantidad
        FROM productos_producidos pp
        INNER JOIN @ventasTVP v ON pp.producto_id = v.producto_id;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK;
        THROW;
    END CATCH;
END;

-- Para hacer inserts al TVP
/*
DECLARE @misVentas AS VentasTVP;

-- Rellenar la variable de tabla con los datos de venta
INSERT INTO @misVentas (id, producto_id, cantidad, precioUnitario, fecha, moneda_id, tipo_cambio_id)
VALUES
    (1, 2, 5, precio, '2023-05-20', 1, 1), -- Ejemplo de venta 1
    (2, 3, 3, precio, '2023-05-20', 2, 2); -- Ejemplo de venta 2

-- Llamar al stored procedure para insertar las ventas
EXEC InsertarVentas @misVentas;

*/

