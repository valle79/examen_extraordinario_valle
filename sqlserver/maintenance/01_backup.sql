-- =============================================
-- Matricula Cloud 360 Enterprise
-- maintenance/01_backup.sql | Estrategia de respaldo
-- =============================================
-- Descripcion (Sprint 3): Estrategia de respaldo y recuperacion
-- basada en el Recovery Model FULL de la base de datos:
--
--   TIPO DE RESPALDO        FRECUENCIA               PERMITE
--   ------------------------------------------------------------------
--   FULL (completo)         Diario (02:00)           Base completa
--   DIFFERENTIAL (diferenc.) Cada 6 horas            Solo cambios desde
--                                                     el ultimo FULL
--   LOG (transacciones)     Cada 30 minutos           Recuperacion a un
--                                                     punto exacto en el
--                                                     tiempo (PITR)
--
-- Este script ejecuta:
--   1. Un respaldo COMPLETO ahora mismo (con fecha/hora en el nombre).
--   2. Devuelve el historial de respaldos registrados en msdb.
--
-- Los archivos se guardan en /var/opt/mssql/backup (volumen Docker
-- matricula_cloud_backup); para extraerlos al host:
--   docker cp sqlserver_matricula_cloud:/var/opt/mssql/backup/<archivo>.bak ./docker/volumes/backup/
--
-- IDEMPOTENTE y SEGURO: solo escribe archivos nuevos de respaldo.
-- =============================================

USE master;
GO

PRINT '============================================';
PRINT 'maintenance/01_backup.sql - Respaldo completo';
PRINT '============================================';
GO

-- =============================================
-- 1. RESPALDO COMPLETO (FULL)
-- =============================================
DECLARE @Fecha VARCHAR(30) = CONVERT(VARCHAR, GETDATE(), 112) + '_' + REPLACE(CONVERT(VARCHAR, GETDATE(), 108), ':', '');
DECLARE @Ruta NVARCHAR(200) = '/var/opt/mssql/backup/MatriculaCloud360DB_FULL_' + @Fecha + '.bak';

PRINT 'Iniciando respaldo COMPLETO...';
PRINT '  Destino: ' + @Ruta;

BACKUP DATABASE MatriculaCloud360DB
TO DISK = @Ruta
WITH INIT,
     NAME = N'MatriculaCloud360DB - Respaldo completo',
     DESCRIPTION = N'Respaldo FULL del proyecto Matricula Cloud 360 Enterprise (Sprint 3)',
     COMPRESSION,
     STATS = 10;
GO

-- =============================================
-- 2. RESPALDO DIFERENCIAL (ejemplo; se ejecuta bajo demanda o por
--    SQL Agent en maintenance/03_maintenance.sql)
-- =============================================
-- DECLARE @FechaD VARCHAR(30) = CONVERT(VARCHAR, GETDATE(), 112) + '_' + REPLACE(CONVERT(VARCHAR, GETDATE(), 108), ':', '');
-- DECLARE @RutaD NVARCHAR(200) = '/var/opt/mssql/backup/MatriculaCloud360DB_DIFF_' + @FechaD + '.bak';
-- BACKUP DATABASE MatriculaCloud360DB TO DISK = @RutaD WITH DIFFERENTIAL, COMPRESSION, STATS = 10;
-- GO

-- =============================================
-- 3. RESPALDO DE LOG (ejemplo; truncamiento del log)
-- =============================================
-- DECLARE @FechaL VARCHAR(30) = CONVERT(VARCHAR, GETDATE(), 112) + '_' + REPLACE(CONVERT(VARCHAR, GETDATE(), 108), ':', '');
-- DECLARE @RutaL NVARCHAR(200) = '/var/opt/mssql/backup/MatriculaCloud360DB_LOG_' + @FechaL + '.trn';
-- BACKUP LOG MatriculaCloud360DB TO DISK = @RutaL WITH COMPRESSION, STATS = 10;
-- GO

-- =============================================
-- 4. HISTORIAL DE RESPALDOS
-- =============================================
PRINT '';
PRINT '============================================';
PRINT 'Historial de respaldos de MatriculaCloud360DB:';
PRINT '============================================';
PRINT '  Tipo: D=FULL  I=DIFFERENTIAL  L=LOG';
PRINT '--------------------------------------------';
GO

SELECT TOP 10
    bs.database_name              AS BaseDeDatos,
    bs.type                       AS Tipo,
    bs.backup_finish_date         AS FechaFin,
    CAST(bs.backup_size / 1048576.0 AS DECIMAL(10,2)) AS TamanoMB,
    bs.compressed_backup_size / 1048576.0 AS ComprimidoMB,
    bmf.physical_device_name      AS Archivo
FROM msdb.dbo.backupset bs
INNER JOIN msdb.dbo.backupmediafamily bmf ON bs.media_set_id = bmf.media_set_id
WHERE bs.database_name = 'MatriculaCloud360DB'
ORDER BY bs.backup_finish_date DESC;
GO

PRINT '============================================';
PRINT 'maintenance/01_backup.sql finalizado.';
PRINT '============================================';
GO