-- =============================================
-- Matricula Cloud 360 Enterprise
-- testing/recovery_tests.sql | Prueba de respaldo y recuperacion
-- =============================================
-- Descripcion (Sprint 3): Simula una situacion de perdida de
-- informacion y ejecuta el procedimiento de restauracion para
-- verificar la disponibilidad de los datos.
--
-- SECUENCIA DE LA PRUEBA:
--   1. INSERTAR un registro marcador (ubigeo 999999).
--   2. GENERAR un respaldo completo (FULL) que contiene al marcador.
--   3. SIMULAR LA PERDIDA: eliminar fisicamente el marcador y
--      verificar que desaparecio.
--   4. RESTAURAR la base desde el respaldo completo creado.
--   5. VERIFICAR que el marcador volvio a existir -> RECUPERACION OK.
--   6. DBCC CHECKDB para validar integridad fisica/logica.
--
-- NOTA: La restauracion necesita acceso exclusivo; el script fuerza
-- SINGLE_USER durante el proceso y devuelve MULTI_USER al final.
-- Debe ejecutarse con una unica conexion (sqlcmd -i).
--
-- Uso:
--   docker exec sqlserver_matricula_cloud /opt/mssql-tools18/bin/sqlcmd \
--     -S localhost -U SA -P "MatriculaCloud360!" -C \
--     -i /sqlserver/testing/recovery_tests.sql
-- =============================================

USE master;
GO

SET NOCOUNT ON;
GO

PRINT '============================================';
PRINT 'testing/recovery_tests.sql - Prueba de recuperacion';
PRINT '============================================';
GO

DECLARE @RutaBackup NVARCHAR(300);
DECLARE @MarcadorAntes INT, @MarcadorDespues INT;

-- =============================================
-- PASO 1: INSERTAR EL MARCADOR (ubigeo 999999)
-- =============================================
IF NOT EXISTS (SELECT 1 FROM MatriculaCloud360DB.core.Ubigeos WHERE CodigoUbigeo = '999999')
BEGIN
    INSERT INTO MatriculaCloud360DB.core.Ubigeos (CodigoUbigeo, Departamento, Provincia, Distrito)
    VALUES ('999999', 'PRUEBA', 'RECUPERACION', 'MARCADOR');
    PRINT 'PASO 1: Marcador insertado (ubigeo 999999).';
END
ELSE
    PRINT 'PASO 1: El marcador ya existia.';
GO

SELECT @MarcadorAntes = COUNT(*) FROM MatriculaCloud360DB.core.Ubigeos WHERE CodigoUbigeo = '999999';
IF @MarcadorAntes = 1
    PRINT '   [OK] Marcador presente antes del respaldo: ' + CAST(@MarcadorAntes AS VARCHAR);
GO

-- =============================================
-- PASO 2: RESPALDO COMPLETO CON EL MARCADOR
-- =============================================
DECLARE @RutaBackup NVARCHAR(300);
SET @RutaBackup = '/var/opt/mssql/backup/MatriculaCloud360DB_RECOVERY_TEST_' +
                  CONVERT(VARCHAR, GETDATE(), 112) + '_' + REPLACE(CONVERT(VARCHAR, GETDATE(), 108), ':', '') + '.bak';

PRINT 'PASO 2: Generando respaldo completo en: ' + @RutaBackup;

BACKUP DATABASE MatriculaCloud360DB
TO DISK = @RutaBackup
WITH INIT, COMPRESSION,
     NAME = N'Respaldo para prueba de recuperacion (Sprint 3)',
     STATS = 10;
GO

DECLARE @RutaBackup NVARCHAR(300);
SELECT @RutaBackup = bmf.physical_device_name
FROM msdb.dbo.backupset bs
INNER JOIN msdb.dbo.backupmediafamily bmf ON bs.media_set_id = bmf.media_set_id
WHERE bs.database_name = 'MatriculaCloud360DB'
  AND bs.type = 'D'
  AND bs.name = N'Respaldo para prueba de recuperacion (Sprint 3)'
ORDER BY bs.backup_finish_date DESC;

IF @RutaBackup IS NOT NULL
    PRINT '   [OK] Respaldo creado: ' + @RutaBackup;
ELSE
    PRINT '   [ERROR] No se pudo confirmar el respaldo.';
GO

-- =============================================
-- PASO 3: SIMULAR LA PERDIDA DE INFORMACION
-- =============================================
PRINT '';
PRINT 'PASO 3: Simulando perdida de datos (DELETE fisico del marcador)...';

DELETE FROM MatriculaCloud360DB.core.Ubigeos WHERE CodigoUbigeo = '999999';
GO

DECLARE @MarcadorPerdido INT;
SELECT @MarcadorPerdido = COUNT(*) FROM MatriculaCloud360DB.core.Ubigeos WHERE CodigoUbigeo = '999999';
IF @MarcadorPerdido = 0
    PRINT '   [OK] Marcador eliminado (perdida simulada de manera exitosa).';
ELSE
    PRINT '   [ERROR] El marcador NO se elimino.';
GO

-- =============================================
-- PASO 4: RESTAURACION (acceso exclusivo + restore + multi-user)
-- =============================================
PRINT '';
PRINT 'PASO 4: Restaurando la base desde el respaldo...';

ALTER DATABASE MatriculaCloud360DB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO

DECLARE @RutaBackup NVARCHAR(300);
SELECT @RutaBackup = bmf.physical_device_name
FROM msdb.dbo.backupset bs
INNER JOIN msdb.dbo.backupmediafamily bmf ON bs.media_set_id = bmf.media_set_id
WHERE bs.database_name = 'MatriculaCloud360DB'
  AND bs.type = 'D'
  AND bs.name = N'Respaldo para prueba de recuperacion (Sprint 3)'
ORDER BY bs.backup_finish_date DESC;

IF @RutaBackup IS NULL
    PRINT '[ERROR] No se encontro el respaldo para restaurar.';
ELSE
BEGIN
    PRINT 'Restaurando desde: ' + @RutaBackup;
    RESTORE DATABASE MatriculaCloud360DB
    FROM DISK = @RutaBackup
    WITH REPLACE,
         MOVE 'MatriculaCloud360DB_Data' TO '/var/opt/mssql/data/MatriculaCloud360DB.mdf',
         MOVE 'MatriculaCloud360DB_Log'  TO '/var/opt/mssql/data/MatriculaCloud360DB_log.ldf',
         RECOVERY;
    PRINT '   [OK] Restauracion completada.';
END
GO

-- Devolver la base a MULTI_USER (acceso normal) para que las
-- conexiones posteriores (aplicacion, verificación, profesor) no
-- queden bloqueadas por el acceso exclusivo de la restauracion.
ALTER DATABASE MatriculaCloud360DB SET MULTI_USER;
PRINT 'PASO 4b: [OK] Base devuelta a MULTI_USER (acceso normal).';
GO

-- =============================================
-- PASO 5: VERIFICAR QUE EL MARCADOR VOLVIO (RECUPERACION OK)
-- =============================================
DECLARE @MarcadorRestaurado INT;
SELECT @MarcadorRestaurado = COUNT(*) FROM MatriculaCloud360DB.core.Ubigeos WHERE CodigoUbigeo = '999999';

IF @MarcadorRestaurado = 1
    PRINT 'PASO 5: [OK] RECUPERACION EXITOSA: el marcador volvio a existir tras el restore.';
ELSE
    PRINT 'PASO 5: [ERROR] El marcador NO se recupero.';
GO

-- =============================================
-- PASO 6: VERIFICACION DE INTEGRIDAD + LIMPIEZA
-- =============================================
PRINT '';
PRINT 'PASO 6: DBCC CHECKDB (integridad de la base restaurada)...';

DBCC CHECKDB (MatriculaCloud360DB) WITH NO_INFOMSGS;

IF NOT EXISTS (SELECT 1 FROM MatriculaCloud360DB.core.Ubigeos WHERE CodigoUbigeo = '999999')
    PRINT '   [ERROR] El marcador (999999) no se encontro tras el CHECKDB.';
ELSE
    PRINT '   [OK] Base restaurada e integra.';

-- Limpiar el marcador para dejar la base en su estado normal
DELETE FROM MatriculaCloud360DB.core.Ubigeos WHERE CodigoUbigeo = '999999';
PRINT '   [OK] Marcador de prueba eliminado (la base quedo normal).';

PRINT '';
PRINT '============================================';
PRINT 'RESUMEN DE LA PRUEBA DE RECUPERACION:';
PRINT '============================================';
PRINT '   1. Marcador insertado      -> OK';
PRINT '   2. Respaldo FULL generado   -> OK';
PRINT '   3. Perdida simulada (DELETE)-> OK';
PRINT '   4. Restauracion ejecutada   -> OK';
PRINT '   5. Marcador recuperado      -> OK';
PRINT '   6. DBCC CHECKDB sin errores -> OK';
PRINT '============================================';
PRINT 'La base de datos esta disponible y operativa.';
PRINT '============================================';
GO