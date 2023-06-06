DELETE FROM transacciones where transaccion_id>=0;
DBCC CHECKIDENT(transacciones, RESEED, 0);
insert into tipo_transacciones (descripcion) VALUES ('Modificación de balance')
