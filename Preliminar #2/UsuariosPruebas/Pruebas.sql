--a) Sin acceso a tablas, solo se opera a traves de SP
select * from contrato;
insert into local_ev (telefono, ubicacion_id) values (24097689, 1);
delete from productos_producidos where producto_mat_id >= 0;
update productos_producidos set cantidad = 100 where producto_id = 2

exec showContractData 11;

DECLARE @cantidad INT = 5;
DECLARE @posttime DATETIME = '2023-05-20';
DECLARE @user_id SMALLINT = 2;
DECLARE @producto_id SMALLINT = 2;
DECLARE @contrato_id SMALLINT = 10;

EXEC ProducirProductos @cantidad, @posttime, @user_id, @producto_id, @contrato_id;

DECLARE @RangoInicial DATETIME = GETDATE();
DECLARE @RangoFinal DATETIME = '2023-05-31';
DECLARE @Moneda_id SMALLINT = 1;
DECLARE @Nuevo DECIMAL (10,2) = 2.0;

EXEC cambioTipoCambio @RangoInicial, @RangoFinal, @Moneda_id, @Nuevo;

--b) Restringe visibilidad de columnas
DENY SELECT (porcentaje) on contrato TO UserB;
DENY SELECT (checksum) on evento_log TO UserB;
DENY SELECT (computer) on evento_log TO UserB;

DENY SELECT (monto) on transacciones TO UserB2;
DENY SELECT (fecha) on ventas TO UserB2;
DENY SELECT (computer) on evento_log TO UserB2;

select * from contrato;
select * from ventas;
select * from transacciones;
select * from evento_log;
select * from productores_residuos;

select contrato_id, descripcion, recolector_id, ubicacion_id from contrato;
select evento_id, descripcion, id_referencia1, creado from evento_log;

select transaccion_id, tipotran_id, descripcion, fecha, nombre, venta_id from transacciones;
select venta_id, producto_id, monto, cantidad from ventas;


--c) Crear roles, diferentes usuarios con difetentes roles y diferentes permisos
--ALTER ROLE RolSoloSP DROP MEMBER UserC;
--DROP ROLE RolSoloSP;
CREATE ROLE RolSoloSP;
Grant EXECUTE TO RolSoloSP;
DENY SELECT, INSERT, UPDATE, DELETE ON schema::caso3 TO RolSoloSP;
ALTER ROLE RolSoloSP ADD MEMBER UserC;

select * from contrato;
insert into local_ev (telefono, ubicacion_id) values (24097689, 1);
update productos_producidos set cantidad = 21 where producto_id = 2
exec showContractData 11;

--ALTER ROLE RestriccionContrato DROP MEMBER UserC2;
--DROP ROLE RestriccionContrato;
CREATE ROLE RestriccionContrato;
GRANT SELECT ON ventas TO RestriccionContrato;
GRANT SELECT ON contrato TO RestriccionContrato;
DENY SELECT (descripcion) ON contrato TO RestriccionContrato;
ALTER ROLE RestriccionContrato ADD MEMBER UserC2;

select * from ventas;
select * from recolectores;
select * from contrato;
select contrato_id, recolector_id, ubicacion_id, porcentaje from contrato;

--d) Prioridades de Permisos
--UsuarioD - sysadmin como role de servidor y deny en rol de base de datos
select * from local_ev;

--UsuarioD2
CREATE ROLE DenyAccess;
DENY SELECT ON actores TO DenyAccess;
GRANT SELECT ON local_ev TO DenyAccess;
GRANT SELECT ON recolectores TO DenyAccess;
ALTER ROLE DenyAccess ADD MEMBER UserD2;

select * from local_ev;
select * from actores;
select * from recolectores;