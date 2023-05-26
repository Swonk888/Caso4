use caso3;

insert into fuentes (nombre) values ('windows');
insert into fuentes (nombre) values ('cartel mexicano');

insert into nivel (nombre) values ('primero');
insert into nivel (nombre) values ('segundo');

insert into tipo_evento (nombre) values ('pagos');
insert into tipo_evento (nombre) values ('ventas');

insert into tipo_objeto (nombre) values ('procesos');
insert into tipo_objeto (nombre) values ('transporte');

DECLARE @fuente INT;
DECLARE @nivel INT;
DECLARE @tipoE INT;
DECLARE @tipoO INT;

Select @fuente = MAX(fuete_id) from fuentes;
Select @nivel = MAX(nivel_id) from nivel;
Select @tipoE = MAX(tipo_evento_id) from tipo_evento;
Select @tipoO = MAX(tipo_objeto_id) from tipo_objeto;

insert into evento_log (descripcion, id_referencia1, id_referencia2, valor1, valor2, creado, computer, usuario, fuente_id, tipo_evento_id, tipo_objeto_id, nivel_id)
values ('evento 1', 1, 1, 'valor', 'valor2', GETDATE(), 'localhost', 'root', @fuente, @tipoE, @tipoO, @nivel)

insert into evento_log (descripcion, id_referencia1, id_referencia2, valor1, valor2, creado, computer, usuario, fuente_id, tipo_evento_id, tipo_objeto_id, nivel_id)
values ('evento 2', 2, 1, 'california', 'senegal', GETDATE(), 'localhost', 'root', @fuente, @tipoE, @tipoO, @nivel)

insert into evento_log (descripcion, id_referencia1, id_referencia2, valor1, valor2, creado, computer, usuario, fuente_id, tipo_evento_id, tipo_objeto_id, nivel_id)
values ('evento 3', 1, 2, 'valor1', 'moneda', GETDATE(), 'localhost', 'root', @fuente, @tipoE, @tipoO, @nivel)