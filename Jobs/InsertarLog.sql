use caso3;

insert into fuentes (nombre) values ('windows');
insert into fuentes (nombre) values ('cartel mexicano');

insert into nivel (nombre) values ('primero');
insert into nivel (nombre) values ('segundo');

insert into tipo_evento (nombre) values ('pagos');
insert into tipo_evento (nombre) values ('ventas');

insert into tipo_objeto (nombre) values ('procesos');
insert into tipo_objeto (nombre) values ('transporte');

insert into evento_log (descripcion, id_referencia1, id_referencia2, valor1, valor2, creado, computer, usuario, fuente_id, tipo_evento_id, tipo_objeto_id, nivel_id)
values ('evento 1', 1, 1, 'valor', 'valor2', GETDATE(), 'localhost', 'root', 1, 2, 1, 2)

insert into evento_log (descripcion, id_referencia1, id_referencia2, valor1, valor2, creado, computer, usuario, fuente_id, tipo_evento_id, tipo_objeto_id, nivel_id)
values ('evento 2', 2, 1, 'california', 'senegal', GETDATE(), 'localhost', 'root', 1, 1, 1, 1)

insert into evento_log (descripcion, id_referencia1, id_referencia2, valor1, valor2, creado, computer, usuario, fuente_id, tipo_evento_id, tipo_objeto_id, nivel_id)
values ('evento 3', 1, 2, 'valor1', 'moneda', GETDATE(), 'localhost', 'root', 2, 2, 2, 2)