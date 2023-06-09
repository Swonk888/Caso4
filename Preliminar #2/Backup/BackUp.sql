--Backups

--Full
BACKUP DATABASE caso3
TO DISK = 'C:\Users\KEVIN CHANG\Desktop\TEC\Base de Datos I\Entregas\Caso #4\Caso4\Preliminar #2\Backup\full.bak'
WITH INIT;

--Incremental
BACKUP DATABASE caso3
TO DISK = 'C:\Users\KEVIN CHANG\Desktop\TEC\Base de Datos I\Entregas\Caso #4\Caso4\Preliminar #2\Backup\incremental.bak'
WITH DIFFERENTIAL;

--Restore

--Full
RESTORE DATABASE caso3
FROM DISK = 'C:\Users\KEVIN CHANG\Desktop\TEC\Base de Datos I\Entregas\Caso #4\Caso4\Preliminar #2\Backup\full.bak'
WITH REPLACE, NORECOVERY;


--Incremental
RESTORE DATABASE caso3
FROM DISK = 'C:\Users\KEVIN CHANG\Desktop\TEC\Base de Datos I\Entregas\Caso #4\Caso4\Preliminar #2\Backup\incremental.bak'
WITH RECOVERY;