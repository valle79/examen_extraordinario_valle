-- =============================================
-- Matricula Cloud 360 Enterprise
-- maintenance/03_maintenance.sql | Automatizacion
-- =============================================
-- Descripcion (Sprint 3): Automatiza las tareas de respaldo y
-- mantenimiento mediante SQL Server Agent (jobs programados):
--
--   JOB                            FRECUENCIA      OPERACION
--   ------------------------------------------------------------------
--   MC360_BackupCompleto           Diario 02:00    BACKUP DATABASE (FULL)
--   MC360_BackupDiferencial        Cada 6 horas    BACKUP DATABASE (DIFF)
--   MC360_BackupLog                Cada 30 min     BACKUP LOG
--   MC360_MantenimientoIndices     Semanal (dom)   Reorganizar/defragmentar
--                                                  indices + UPDATE STATS
--   MC360_VerificacionIntegridad   Semanal (dom)   DBCC CHECKDB
--
-- Tambien ejecuta de inmediato una verificación de fragmentacion
-- para demostrar la consulta de mantenimiento.
--
-- REQUISITO: SQL Server Agent activo en el contenedor
-- (MSSQL_AGENT_ENABLED=true en docker-compose.yml).
-- IDEMPOTENTE: los jobs se eliminan y recrean sin errores.
-- =============================================

USE master;
GO

PRINT '============================================';
PRINT 'maintenance/03_maintenance.sql - SQL Agent';
PRINT '============================================';
GO

-- =============================================
-- 1. Verificar que SQL Agent este disponible
-- =============================================
PRINT 'Verificando SQL Server Agent...';

IF EXISTS (SELECT 1 FROM sys.dm_server_services WHERE servicename LIKE 'SQL Server Agent%' AND status_desc = 'Running')
    PRINT 'OK: SQL Server Agent ACTIVO (MSSQL_AGENT_ENABLED=true).';
ELSE
    PRINT 'AVISO: SQL Server Agent no detectado activo (verificar MSSQL_AGENT_ENABLED=true en docker-compose).';
GO

-- =============================================
-- 2. Crear los JOBS (idempotente: se borran y recrean)
-- =============================================
DECLARE @JobId UNIQUEIDENTIFIER;

-- ----------------------------------------------
-- JOB 1: MC360_BackupCompleto (diario 02:00)
-- ----------------------------------------------
IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = 'MC360_BackupCompleto')
    EXEC msdb.dbo.sp_delete_job @job_name = N'MC360_BackupCompleto', @delete_unused_schedule = 1;

EXEC msdb.dbo.sp_add_job
    @job_name = N'MC360_BackupCompleto',
    @enabled = 1,
    @description = N'MC360: Respaldo completo diario de MatriculaCloud360DB (Sprint 3)',
    @owner_login_name = N'sa',
    @job_id = @JobId OUTPUT;

EXEC msdb.dbo.sp_add_jobstep
    @job_id = @JobId,
    @step_name = N'Backup FULL',
    @subsystem = N'TSQL',
    @command = N'
DECLARE @Ruta NVARCHAR(200) = N''/var/opt/mssql/backup/MatriculaCloud360DB_FULL_'' +
    CONVERT(VARCHAR, GETDATE(), 112) + ''_'' + REPLACE(CONVERT(VARCHAR, GETDATE(), 108), '':'', '''') + ''.bak'';
BACKUP DATABASE MatriculaCloud360DB TO DISK = @Ruta WITH COMPRESSION, INIT;',
    @database_name = N'master',
    @on_success_action = 1;

EXEC msdb.dbo.sp_add_jobschedule
    @job_id = @JobId,
    @name = N'Diario 02:00',
    @freq_type = 4,            -- diario
    @freq_interval = 1,
    @active_start_time = 020000;

EXEC msdb.dbo.sp_add_jobserver @job_id = @JobId;
PRINT 'OK: Job MC360_BackupCompleto creado (diario 02:00).';
GO

-- ----------------------------------------------
-- JOB 2: MC360_BackupDiferencial (cada 6 horas)
-- ----------------------------------------------
DECLARE @JobId UNIQUEIDENTIFIER;
IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = 'MC360_BackupDiferencial')
    EXEC msdb.dbo.sp_delete_job @job_name = N'MC360_BackupDiferencial', @delete_unused_schedule = 1;

EXEC msdb.dbo.sp_add_job
    @job_name = N'MC360_BackupDiferencial',
    @enabled = 1,
    @description = N'MC360: Respaldo diferencial cada 6 horas',
    @owner_login_name = N'sa',
    @job_id = @JobId OUTPUT;

EXEC msdb.dbo.sp_add_jobstep
    @job_id = @JobId,
    @step_name = N'Backup DIFFERENTIAL',
    @subsystem = N'TSQL',
    @command = N'
DECLARE @Ruta NVARCHAR(200) = N''/var/opt/mssql/backup/MatriculaCloud360DB_DIFF_'' +
    CONVERT(VARCHAR, GETDATE(), 112) + ''_'' + REPLACE(CONVERT(VARCHAR, GETDATE(), 108), '':'', '''') + ''.bak'';
BACKUP DATABASE MatriculaCloud360DB TO DISK = @Ruta WITH DIFFERENTIAL, COMPRESSION, INIT;',
    @database_name = N'master';

EXEC msdb.dbo.sp_add_jobschedule
    @job_id = @JobId,
    @name = N'Cada 6 horas',
    @freq_type = 4,
    @freq_interval = 1,
    @freq_subday_type = 4,     -- cada N horas
    @freq_subday_interval = 6,
    @active_start_time = 020000;

EXEC msdb.dbo.sp_add_jobserver @job_id = @JobId;
PRINT 'OK: Job MC360_BackupDiferencial creado (cada 6 horas).';
GO

-- ----------------------------------------------
-- JOB 3: MC360_BackupLog (cada 30 minutos)
-- ----------------------------------------------
DECLARE @JobId UNIQUEIDENTIFIER;
IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = 'MC360_BackupLog')
    EXEC msdb.dbo.sp_delete_job @job_name = N'MC360_BackupLog', @delete_unused_schedule = 1;

EXEC msdb.dbo.sp_add_job
    @job_name = N'MC360_BackupLog',
    @enabled = 1,
    @description = N'MC360: Respaldo del log de transacciones cada 30 min',
    @owner_login_name = N'sa',
    @job_id = @JobId OUTPUT;

EXEC msdb.dbo.sp_add_jobstep
    @job_id = @JobId,
    @step_name = N'Backup LOG',
    @subsystem = N'TSQL',
    @command = N'
DECLARE @Ruta NVARCHAR(200) = N''/var/opt/mssql/backup/MatriculaCloud360DB_LOG_'' +
    CONVERT(VARCHAR, GETDATE(), 112) + ''_'' + REPLACE(CONVERT(VARCHAR, GETDATE(), 108), '':'', '''') + ''.trn'';
BACKUP LOG MatriculaCloud360DB TO DISK = @Ruta WITH COMPRESSION, INIT;',
    @database_name = N'master';

EXEC msdb.dbo.sp_add_jobschedule
    @job_id = @JobId,
    @name = N'Cada 30 minutos',
    @freq_type = 4,
    @freq_interval = 1,
    @freq_subday_type = 8,     -- cada N minutos
    @freq_subday_interval = 30,
    @active_start_time = 000000;

EXEC msdb.dbo.sp_add_jobserver @job_id = @JobId;
PRINT 'OK: Job MC360_BackupLog creado (cada 30 minutos).';
GO

-- ----------------------------------------------
-- JOB 4: MC360_MantenimientoIndices (semanal)
-- ----------------------------------------------
DECLARE @JobId UNIQUEIDENTIFIER;
IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = 'MC360_MantenimientoIndices')
    EXEC msdb.dbo.sp_delete_job @job_name = N'MC360_MantenimientoIndices', @delete_unused_schedule = 1;

EXEC msdb.dbo.sp_add_job
    @job_name = N'MC360_MantenimientoIndices',
    @enabled = 1,
    @description = N'MC360: Reorganizar indices fragmentados y actualizar estadisticas',
    @owner_login_name = N'sa',
    @job_id = @JobId OUTPUT;

EXEC msdb.dbo.sp_add_jobstep
    @job_id = @JobId,
    @step_name = N'Defragmentar indices + UPDATE STATISTICS',
    @subsystem = N'TSQL',
    @command = N'
DECLARE @cmd NVARCHAR(MAX) = N'''';
SELECT @cmd += N''ALTER INDEX '' + QUOTENAME(i.name) + N'' ON '' + QUOTENAME(SCHEMA_NAME(t.schema_id)) + N''.'' + QUOTENAME(t.name)
              + CASE WHEN ps.avg_fragmentation_in_percent > 30 THEN N'' REBUILD;''
                     ELSE N'' REORGANIZE;'' END + CHAR(10)
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, N''LIMITED'') ps
INNER JOIN sys.tables t ON t.object_id = ps.object_id
INNER JOIN sys.indexes i ON i.object_id = ps.object_id AND i.index_id = ps.index_id
WHERE ps.avg_fragmentation_in_percent > 10 AND ps.index_id > 0
  AND SCHEMA_NAME(t.schema_id) IN (''core'', ''academic'', ''sales'', ''security'', ''audit'');
EXEC(@cmd);
EXEC sp_updatestats;',
    @database_name = N'MatriculaCloud360DB';

EXEC msdb.dbo.sp_add_jobschedule
    @job_id = @JobId,
    @name = N'Semanal domingo 04:00',
    @freq_type = 8,            -- semanal
    @freq_interval = 1,        -- domingo
    @freq_recurrence_factor = 1,
    @active_start_time = 040000;

EXEC msdb.dbo.sp_add_jobserver @job_id = @JobId;
PRINT 'OK: Job MC360_MantenimientoIndices creado (semanal).';
GO

-- ----------------------------------------------
-- JOB 5: MC360_VerificacionIntegridad (semanal)
-- ----------------------------------------------
DECLARE @JobId UNIQUEIDENTIFIER;
IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = 'MC360_VerificacionIntegridad')
    EXEC msdb.dbo.sp_delete_job @job_name = N'MC360_VerificacionIntegridad', @delete_unused_schedule = 1;

EXEC msdb.dbo.sp_add_job
    @job_name = N'MC360_VerificacionIntegridad',
    @enabled = 1,
    @description = N'MC360: Verificacion de integridad fisica y logica (DBCC CHECKDB)',
    @owner_login_name = N'sa',
    @job_id = @JobId OUTPUT;

EXEC msdb.dbo.sp_add_jobstep
    @job_id = @JobId,
    @step_name = N'DBCC CHECKDB',
    @subsystem = N'TSQL',
    @command = N'DBCC CHECKDB (MatriculaCloud360DB) WITH NO_INFOMSGS;',
    @database_name = N'master';

EXEC msdb.dbo.sp_add_jobschedule
    @job_id = @JobId,
    @name = N'Semanal domingo 05:00',
    @freq_type = 8,
    @freq_interval = 1,
    @freq_recurrence_factor = 1,
    @active_start_time = 050000;

EXEC msdb.dbo.sp_add_jobserver @job_id = @JobId;
PRINT 'OK: Job MC360_VerificacionIntegridad creado (semanal).';
GO

-- =============================================
-- 3. DEMOSTRACION: FRAGMENTACION ACTUAL DE INDICES
-- =============================================
PRINT '';
PRINT '============================================';
PRINT 'Fragmentacion actual de los indices (mantenimiento):';
PRINT '============================================';
GO

SELECT TOP 10
    QUOTENAME(SCHEMA_NAME(t.schema_id)) + '.' + QUOTENAME(t.name) AS Tabla,
    i.name                                     AS Indice,
    ps.index_type_desc                         AS Tipo,
    CAST(ps.avg_fragmentation_in_percent AS DECIMAL(5,1)) AS FragmentacionPct,
    ps.page_count                              AS Paginas
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, N'LIMITED') ps
INNER JOIN sys.tables t ON t.object_id = ps.object_id
INNER JOIN sys.indexes i ON i.object_id = ps.object_id AND i.index_id = ps.index_id
WHERE ps.index_id > 0
  AND SCHEMA_NAME(t.schema_id) IN ('core', 'academic', 'sales', 'security', 'audit')
ORDER BY ps.avg_fragmentation_in_percent DESC;
GO

PRINT '============================================';
PRINT 'Resumen de jobs programados en SQL Agent:';
PRINT '============================================';
GO

SELECT name AS Job, enabled AS Habilitado, description AS Descripcion
FROM msdb.dbo.sysjobs
WHERE name LIKE 'MC360_%'
ORDER BY name;
GO

PRINT '============================================';
PRINT 'maintenance/03_maintenance.sql finalizado.';
PRINT '============================================';
GO