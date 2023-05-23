--a) Encriptado

ALTER PROCEDURE InsertarVentas
    @ventasTVP AS VentasTVP READONLY
	WITH ENCRYPTION
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

SELECT O.name, M.definition, O.type_desc, O.type 
FROM sys.sql_modules M 
INNER JOIN sys.objects O ON M.object_id=O.object_id 
WHERE O.type IN ('P');
GO

sp_HelpText InsertarVentas;

Go

--b) Schemahowbinding

IF OBJECT_ID('dbo.VistaContratoProceso', 'V') IS NOT NULL
    DROP VIEW dbo.VistaContratoProceso;
GO

CREATE VIEW VistaContratoProceso 
WITH SCHEMABINDING 
AS
SELECT dbo.contrato.descripcion, dbo.proceso.proceso_id, dbo.proceso.clasificacion, dbo.desecho_movimientos.posttime, dbo.desecho_movimientos.responsible_name, dbo.desecho_movimientos.reci_desecho_cantidad, 
                  dbo.ubicaciones.descripcion AS Expr1, dbo.paises.nombre, dbo.productores_residuos.nombre AS Expr2, dbo.productores_residuos.porcentaje_carbon, dbo.productores_residuos.balance
FROM     dbo.contrato INNER JOIN
                  dbo.proceso ON dbo.contrato.contrato_id = dbo.proceso.contrato_id INNER JOIN
                  dbo.desecho_movimientos ON dbo.proceso.proceso_id = dbo.desecho_movimientos.proceso_id INNER JOIN
                  dbo.ubicaciones ON dbo.contrato.ubicacion_id = dbo.ubicaciones.ubicacion_id AND dbo.desecho_movimientos.ubicacion_id = dbo.ubicaciones.ubicacion_id INNER JOIN
                  dbo.paises ON dbo.ubicaciones.pais_id = dbo.paises.pais_id INNER JOIN
                  dbo.productores_residuos ON dbo.desecho_movimientos.productor_id = dbo.productores_residuos.productor_id AND dbo.ubicaciones.ubicacion_id = dbo.productores_residuos.ubicaicon_id
				  Where dbo.contrato.contrato_id < 12
GO


--EXEC sp_rename 'contrato.descripcion', 'nombres', 'COLUMN';
--select * from contrato


-- select * from VistaContratoProceso;

--EXEC sp_rename 'contrato.nombres', 'descripcion', 'COLUMN';

/*
ALTER TABLE contrato
ALTER COLUMN descripcion NCHAR(10);

ALTER TABLE contrato
ALTER COLUMN descripcion VARCHAR(200);

update contrato set descripcion = 'Contrato entre KFC y esencial verde where contrato_id' = 10;
update contrato set descripcion = 'Contrato entre TacoBell y esencial verde' where contrato_id = 11;
update contrato set descripcion = 'Contrato entre Barcelo y esencial verde' where contrato_id = 12;
*/