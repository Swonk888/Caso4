-- c) Jobs

--Recompilar SP
DECLARE @sql NVARCHAR(MAX);

SET @sql = '';

SELECT @sql = @sql + 'EXEC sp_recompile ''' + QUOTENAME(SCHEMA_NAME(schema_id)) + '.' + QUOTENAME(name) + ''';' + CHAR(13)
FROM sys.procedures
WHERE OBJECTPROPERTY(OBJECT_ID, 'IsMSShipped') = 0;

EXEC sp_executesql @sql;

-- Respaldo de Logs con Linked Servers
-- Copiar Datos
DECLARE @ID INT;

SELECT @ID = ISNULL(MAX(tipo_evento_id),0) from [caso4].[dbo].[tipo_evento];

INSERT INTO [caso4].[dbo].[tipo_evento]
SELECT nombre
FROM [KEVIN-CC].[caso3].[dbo].[tipo_evento]
WHERE tipo_evento_id >= @ID;

SELECT @ID = ISNULL(MAX(fuete_id),0) from [caso4].[dbo].[fuentes];

INSERT INTO [caso4].[dbo].[fuentes]
SELECT nombre
FROM [KEVIN-CC].[caso3].[dbo].[fuentes]
WHERE fuete_id >= @ID;

SELECT @ID = ISNULL(MAX(nivel_id),0) from [caso4].[dbo].[nivel];

INSERT INTO [caso4].[dbo].[nivel]
SELECT nombre
FROM [KEVIN-CC].[caso3].[dbo].[nivel]
WHERE nivel_id >= @ID;

SELECT @ID = ISNULL(MAX(tipo_objeto_id),0) from [caso4].[dbo].[tipo_objeto];

INSERT INTO [caso4].[dbo].[tipo_objeto]
SELECT nombre
FROM [KEVIN-CC].[caso3].[dbo].[tipo_objeto]
WHERE tipo_objeto_id >= @ID;

SELECT @ID = ISNULL(MAX(evento_id),0) from [caso4].[dbo].[evento_log];

INSERT INTO [caso4].[dbo].[evento_log]
SELECT descripcion, id_referencia1, id_referencia2, valor1, valor2, creado, computer, usuario, checksum, fuente_id, tipo_evento_id, nivel_id, tipo_objeto_id
FROM [KEVIN-CC].[caso3].[dbo].[evento_log]
WHERE evento_id >= @ID;

--Borrar Datos
DELETE FROM [KEVIN-CC].[caso3].[dbo].[evento_log]
WHERE evento_id >= 0;

DELETE FROM [KEVIN-CC].[caso3].[dbo].[tipo_evento]
WHERE tipo_evento_id >= 0;

DELETE FROM [KEVIN-CC].[caso3].[dbo].[fuentes]
WHERE fuete_id >= 0;

DELETE FROM [KEVIN-CC].[caso3].[dbo].[nivel]
WHERE nivel_id >= 0;

DELETE FROM [KEVIN-CC].[caso3].[dbo].[tipo_objeto]
WHERE tipo_objeto_id >= 0;

/*
select * from [KEVIN-CC].[caso3].[dbo].[evento_log]
select * from [caso4].[dbo].[evento_log]
*/
