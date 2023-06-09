--Backups

--Full
BACKUP DATABASE caso3
TO DISK = 'C:\Users\KEVIN CHANG\Desktop\TEC\Base de Datos I\Entregas\Caso #4\Caso4\Preliminar #2\Backup\full.bak'
WITH INIT;

insert into local_ev (telefono, ubicacion_id) values (12345, 1);
select * from local_ev;

--Incremental
BACKUP DATABASE caso3
TO DISK = 'C:\Users\KEVIN CHANG\Desktop\TEC\Base de Datos I\Entregas\Caso #4\Caso4\Preliminar #2\Backup\incremental.bak'
WITH DIFFERENTIAL;

select * from local_ev
