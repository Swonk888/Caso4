
select * from monedas;
select * from tipo_cambio;

SELECT m.tipo_cambio_actual, tc.tipo_cambio_id
FROM monedas m 
INNER JOIN tipo_cambio tc ON m.moneda_id = tc.moneda_id

insert into transacciones(tipotran_id, descripcion, monto, fecha, tipo_cambio, nombre, venta_id) values (1, 'x', 23, GETDATE(), 1.0, 'Hola', 4)