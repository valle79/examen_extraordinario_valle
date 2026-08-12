-- =============================================
-- Matricula Cloud 360 Enterprise
-- utils/backup_restore.sql
-- =============================================
-- Descripcion: Mecanismo de respaldo y restauracion documentado.
--
-- La base de datos usa RECOVERY FULL, por lo que admite:
--   1) Respaldos completos  (BACKUP DATABASE)
--   2) Respaldos de log     (BACKUP LOG) para restauracion
--      a un punto especifico del tiempo.
--
-- Los archivos se escriben en /var/opt/mssql/backup, carpeta que
-- en Docker se encuentra en docker/volumes/backup del proyecto.
--
-- IMPORTANTE: con RECOVERY FULL, el log crece hasta que se ejecuta
-- un BACKUP LOG. Se recomienda programar respaldos periodicos
-- (tarea de SQL Agent en el Sprint 3 de administracion).
-- =============================================

USE master;
GO

-- ==========================================================
-- RESPALDO COMPLETO (nombre de archivo con fecha y hora)
-- ==========================================================
DECLARE @FechaBackup VARCHAR(30) = CONVERT(VARCHAR, GETDATE(), 112) + '_' + REPLACE(CONVERT(VARCHAR, GETDATE(), 108), ':', '');
DECLARE @RutaBackup NVARCHAR(200) = '/var/opt/mssql/backup/MatriculaCloud360DB_' + @FechaBackup + '.bak';

PRINT 'Iniciando respaldo completo de MatriculaCloud360DB...';
PRINT 'Destino: ' + @RutaBackup;
PRINT '';

BACKUP DATABASE MatriculaCloud360DB
TO DISK = @RutaBackup
WITH INIT,
     NAME = N'MatriculaCloud360DB - Respaldo completo',
     DESCRIPTION = N'Respaldo de seguridad del proyecto Matricula Cloud 360 Enterprise',
     STATS = 10;
GO

-- ==========================================================
-- RESPALDO DE LOG (truncamiento del log de transacciones)
-- Ejecutar periodicamente mientras la BD este en FULL recovery.
-- ==========================================================
-- DECLARE @FechaLog VARCHAR(30) = CONVERT(VARCHAR, GETDATE(), 112) + '_' + REPLACE(CONVERT(VARCHAR, GETDATE(), 108), ':', '');
-- DECLARE @RutaLog NVARCHAR(200) = '/var/opt/mssql/backup/MatriculaCloud360DB_log_' + @FechaLog + '.trn';
--
-- BACKUP LOG MatriculaCloud360DB
-- TO DISK = @RutaLog
-- WITH INIT, NAME = N'Respaldo de log de transacciones';
-- GO

-- ==========================================================
-- RESTAURACION
-- ==========================================================
-- Para restaurar la base de datos desde el ultimo respaldo completo:
--
-- RESTORE DATABASE MatriculaCloud360DB
-- FROM DISK = '/var/opt/mssql/backup/MatriculaCloud360DB_AAAAMMDD_HHMMSS.bak'
-- WITH REPLACE,
--      MOVE 'MatriculaCloud360DB_Data' TO '/var/opt/mssql/data/MatriculaCloud360DB.mdf',
--      MOVE 'MatriculaCloud360DB_Log'  TO '/var/opt/mssql/data/MatriculaCloud360DB_log.ldf';
-- GO
--
-- Para restaurar respaldo completo + respaldos de log (punto en el tiempo):
--
-- RESTORE DATABASE MatriculaCloud360DB FROM DISK = '...backup' WITH NORECOVERY, REPLACE, MOVE ...;
-- RESTORE LOG MatriculaCloud360DB FROM DISK = '...trn' WITH RECOVERY;
-- GO

-- ==========================================================
-- VERIFICACION: estado de los ultimos respaldos
-- ==========================================================
PRINT '';
PRINT 'Ultimos respaldos registrados:';
PRINT '==============================';
GO

SELECT TOP 10
    bs.database_name AS BaseDeDatos,
    bs.type AS Tipo,
    bs.backup_finish_date AS FechaFin,
    CAST(bs.backup_size / 1048576.0 AS DECIMAL(10,2)) AS TamanoMB,
    bmf.physical_device_name AS Archivo
FROM msdb.dbo.backupset bs
INNER JOIN msdb.dbo.backupmediafamily bmf ON bs.media_set_id = bmf.media_set_id
WHERE bs.database_name = 'MatriculaCloud360DB'
ORDER BY bs.backup_finish_date DESC;
GO
