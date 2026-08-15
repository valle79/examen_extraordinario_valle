-- =============================================
-- Matricula Cloud 360 Enterprise
-- maintenance/02_restore.sql | Restauracion y recuperacion
-- =============================================
-- Descripcion (Sprint 3): Procedimiento documentado para restaurar
-- la base de datos en caso de perdida o corrupcion de informacion.
-- Demuestra el proceso completo:
--
--   1. RESTORE VERIFYONLY  -> valida la integridad del respaldo.
--   2. RESTORE (COMPLETO)  -> restaura desde el ultimo respaldo FULL.
--   3. RESTORE LOG         -> aplica los respaldos de LOG posteriores
--                             para recuperar hasta el ultimo punto.
--   4. DBCC CHECKDB        -> verifica la integridad fisica/logica.
--
-- PROTOCOLO DE RESTAURACION (punto en el tiempo):
--   a) RESTORE DATABASE ... WITH NORECOVERY  (deja la BD en estado
--      "Restoring" para seguir aplicando respaldos)
--   b) RESTORE LOG ... WITH NORECOVERY       (uno por cada .trn)
--   c) RESTORE LOG ... WITH RECOVERY         (ultimo paso: BD en linea)
--   d) RESTORE DATABASE ... WITH RECOVERY    (si solo hay respaldo FULL)
--
-- El script ejecuta en vivo una RESTAURACION COMPLETA desde el
-- ultimo respaldo FULL disponible (sin recrear la BD): es seguro en
-- un entorno de prueba recreable (docker compose down -v && up).
-- Por defecto se ejecuta el RESTORE VERIFYONLY (lectura) para no
-- interrumpir el entorno; descomentar el RESTORE REAL cuando se
-- requiera simular la recuperacion.
-- =============================================

USE master;
GO

PRINT '============================================';
PRINT 'maintenance/02_restore.sql - Restauracion';
PRINT '============================================';
GO

-- =============================================
-- 1. LOCALIZAR EL ULTIMO RESPALDO FULL
-- =============================================
DECLARE @UltimoBackup NVARCHAR(300);

SELECT TOP 1 @UltimoBackup = bmf.physical_device_name
FROM msdb.dbo.backupset bs
INNER JOIN msdb.dbo.backupmediafamily bmf ON bs.media_set_id = bmf.media_set_id
WHERE bs.database_name = 'MatriculaCloud360DB'
  AND bs.type = 'D'            -- respaldo completo (full)
ORDER BY bs.backup_finish_date DESC;

IF @UltimoBackup IS NULL
BEGIN
    PRINT '[ERROR] No existe un respaldo FULL disponible.';
    PRINT 'Ejecute antes maintenance/01_backup.sql.';
END
ELSE
    PRINT 'Ultimo respaldo FULL encontrado: ' + @UltimoBackup;
GO

-- =============================================
-- 2. RESTORE VERIFYONLY (validar el archivo; NO modifica nada)
-- =============================================
PRINT '';
PRINT '>> RESTORE VERIFYONLY sobre el ultimo respaldo FULL...';
GO

DECLARE @UltimoBackup NVARCHAR(300);
SELECT TOP 1 @UltimoBackup = bmf.physical_device_name
FROM msdb.dbo.backupset bs
INNER JOIN msdb.dbo.backupmediafamily bmf ON bs.media_set_id = bmf.media_set_id
WHERE bs.database_name = 'MatriculaCloud360DB'
  AND bs.type = 'D'
ORDER BY bs.backup_finish_date DESC;

IF @UltimoBackup IS NOT NULL
BEGIN
    RESTORE VERIFYONLY FROM DISK = @UltimoBackup;
    PRINT 'OK: Respaldo verificado correctamente (sin errores de lectura).';
END
GO

-- =============================================
-- 3. RESTAURACION REAL (SIMULACION DE RECUPERACION)
--    NOTA: descomentar SOLO cuando se quiera ejecutar la
--    restauracion en vivo. Requiere conexion exclusiva (se fuerza
--    con SINGLE_USER y se devuelve a MULTI_USER al final).
-- =============================================
-- DECLARE @UltimoBackup NVARCHAR(300);
-- SELECT TOP 1 @UltimoBackup = bmf.physical_device_name
-- FROM msdb.dbo.backupset bs
-- INNER JOIN msdb.dbo.backupmediafamily bmf ON bs.media_set_id = bmf.media_set_id
-- WHERE bs.database_name = 'MatriculaCloud360DB'
--   AND bs.type = 'D'
-- ORDER BY bs.backup_finish_date DESC;
--
-- IF @UltimoBackup IS NOT NULL
-- BEGIN
--     PRINT 'Poniendo la base en modo SINGLE_USER (se corta la conexion actual)...';
--     ALTER DATABASE MatriculaCloud360DB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
--
--     PRINT 'Restaurando desde: ' + @UltimoBackup;
--     RESTORE DATABASE MatriculaCloud360DB
--     FROM DISK = @UltimoBackup
--     WITH REPLACE,
--          MOVE 'MatriculaCloud360DB_Data' TO '/var/opt/mssql/data/MatriculaCloud360DB.mdf',
--          MOVE 'MatriculaCloud360DB_Log'  TO '/var/opt/mssql/data/MatriculaCloud360DB_log.ldf',
--          RECOVERY;
--
--     PRINT 'OK: Base restaurada. Verificando integridad...';
--     DBCC CHECKDB (MatriculaCloud360DB) WITH NO_INFOMSGS;
--     PRINT 'OK: DBCC CHECKDB sin errores.';
-- END
-- GO

-- =============================================
-- 4. GUIAS DE RESTAURACION PUNTO-EN-EL-TIEMPO (documentacion)
-- =============================================
PRINT '';
PRINT '============================================';
PRINT 'GUIA: RESTAURACION PUNTO EN EL TIEMPO (PITR):';
PRINT '============================================';
PRINT '';
PRINT '-- Paso 1: restaurar el FULL sin recuperar (norecovery)';
PRINT 'RESTORE DATABASE MatriculaCloud360DB';
PRINT 'FROM DISK = N''/var/opt/mssql/backup/MatriculaCloud360DB_FULL_AAAAMMDD_HHMMSS.bak''';
PRINT 'WITH REPLACE, NORECOVERY,';
PRINT '     MOVE ''MatriculaCloud360DB_Data'' TO ''/var/opt/mssql/data/MatriculaCloud360DB.mdf'',';
PRINT '     MOVE ''MatriculaCloud360DB_Log''  TO ''/var/opt/mssql/data/MatriculaCloud360DB_log.ldf'';';
PRINT '';
PRINT '-- Paso 2: aplicar los DIFFERENTIAL (si existen)';
PRINT 'RESTORE DATABASE MatriculaCloud360DB FROM DISK = N''..._DIFF_...bak'' WITH NORECOVERY;';
PRINT '';
PRINT '-- Paso 3: aplicar los LOG hasta el punto deseado';
PRINT 'RESTORE LOG MatriculaCloud360DB FROM DISK = N''..._LOG_...trn''';
PRINT 'WITH NORECOVERY, STOPAT = N''2026-08-14T15:30:00'';';
PRINT '';
PRINT '-- Paso 4: activar la base (RECOVERY)';
PRINT 'RESTORE DATABASE MatriculaCloud360DB WITH RECOVERY;';
PRINT '';
PRINT '============================================';
PRINT 'maintenance/02_restore.sql finalizado.';
PRINT '============================================';
GO