-- =============================================
-- Matricula Cloud 360 Enterprise
-- audit/01_audit_tables.sql | Tablas de auditoria
-- =============================================
-- Descripcion (Sprint 3):
--   Asegura la infraestructura de auditoria del sistema:
--   - audit.AuditLog: registro central de operaciones INSERT/UPDATE/DELETE
--     (creada en Sprint 1 - 03_tables.sql; este script garantiza que
--     exista y que cuente con sus indices de consulta, aunque la tabla
--     haya sido creada por otro script).
--   - Indices de rendimiento para las consultas de trazabilidad
--     (por entidad, por usuario y por fecha).
--
-- IDEMPOTENTE: puede ejecutarse multiples veces sin errores.
-- =============================================

USE MatriculaCloud360DB;
GO

SET QUOTED_IDENTIFIER ON;
GO

PRINT '============================================';
PRINT 'audit/01_audit_tables.sql - Tablas de auditoria';
PRINT '============================================';
GO

-- =============================================
-- 1. audit.AuditLog (garantizar existencia)
-- =============================================
IF OBJECT_ID(N'audit.AuditLog', N'U') IS NULL
BEGIN
    CREATE TABLE audit.AuditLog (
        AuditId BIGINT IDENTITY(1,1) NOT NULL,
        TableName VARCHAR(100) NOT NULL,
        Operation VARCHAR(10) NOT NULL,
        RecordId INT NOT NULL,
        Usuario VARCHAR(100) NOT NULL,
        FechaOperacion DATETIME NOT NULL DEFAULT GETDATE(),
        ValoresAnteriores NVARCHAR(MAX) NULL,
        ValoresNuevos NVARCHAR(MAX) NULL,
        DireccionIP VARCHAR(45) NULL
    );

    IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'PK_AuditLog')
        ALTER TABLE audit.AuditLog ADD CONSTRAINT PK_AuditLog PRIMARY KEY (AuditId);

    IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'CK_AuditLog_Operation')
        ALTER TABLE audit.AuditLog ADD CONSTRAINT CK_AuditLog_Operation
            CHECK (Operation IN ('INSERT','UPDATE','DELETE'));

    PRINT 'OK: audit.AuditLog creada (no existia).';
END
ELSE
    PRINT 'OK: audit.AuditLog ya existe.';
GO

-- =============================================
-- 2. Indices de auditoria (consultas de trazabilidad)
-- =============================================
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_AuditLog_TableName' AND object_id = OBJECT_ID('audit.AuditLog'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_AuditLog_TableName
        ON audit.AuditLog(TableName, FechaOperacion DESC);
    PRINT 'OK: IX_AuditLog_TableName.';
END
ELSE
    PRINT 'OK: IX_AuditLog_TableName ya existe.';
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_AuditLog_Usuario' AND object_id = OBJECT_ID('audit.AuditLog'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_AuditLog_Usuario
        ON audit.AuditLog(Usuario, FechaOperacion DESC);
    PRINT 'OK: IX_AuditLog_Usuario.';
END
ELSE
    PRINT 'OK: IX_AuditLog_Usuario ya existe.';
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_AuditLog_FechaOperacion' AND object_id = OBJECT_ID('audit.AuditLog'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_AuditLog_FechaOperacion
        ON audit.AuditLog(FechaOperacion DESC);
    PRINT 'OK: IX_AuditLog_FechaOperacion.';
END
ELSE
    PRINT 'OK: IX_AuditLog_FechaOperacion ya existe.';
GO

-- =============================================
-- 3. VISTA DE TRACE DE AUDITORIA (consultas frecuentes)
--    Muestra el historial con formato legible.
-- =============================================
CREATE OR ALTER VIEW audit.vw_TrazaAuditoria
AS
SELECT
    a.AuditId,
    a.TableName,
    a.Operation,
    a.RecordId,
    a.Usuario,
    a.FechaOperacion,
    a.ValoresAnteriores,
    a.ValoresNuevos,
    a.DireccionIP
FROM audit.AuditLog a;
GO

PRINT 'OK: audit.vw_TrazaAuditoria.';
GO

PRINT '';
PRINT '============================================';
PRINT 'audit/01_audit_tables.sql finalizado.';
PRINT '============================================';
GO