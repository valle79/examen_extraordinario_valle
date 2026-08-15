-- =============================================
-- Matricula Cloud 360 Enterprise
-- audit/02_audit_triggers.sql | Triggers de auditoria
-- =============================================
-- Descripcion (Sprint 3):
--   Amplia la auditoria (RN-07) a TODAS las entidades criticas del
--   sistema. El Sprint 2 cubrio Estudiantes, Matriculas, Promotores
--   y Comisiones; este script agrega:
--     - core.Sedes
--     - core.Carreras
--     - core.PeriodosAcademicos
--     - academic.Profesores
--     - academic.Cursos
--     - sales.CampaniasAdmision
--     - security.Usuarios
--   Cada trigger registra INSERT/UPDATE/DELETE en audit.AuditLog con
--   usuario (SUSER_SNAME()), fecha/hora, operacion, valores anteriores
--   y nuevos (JSON) y direccion IP del cliente.
--
-- NOTA: Las tablas con borrado logico (DeletedAt) reciben en el
-- script 03_soft_delete.sql triggers INSTEAD OF DELETE que convierten
-- el DELETE fisico en un UPDATE de DeletedAt. Como no se ejecuta un
-- DELETE real, el trigger AFTER DELETE de este script se dispara al
-- ejecutar el UPDATE interno (registrado como UPDATE con el cambio
-- de DeletedAt), mientras que el trigger INSTEAD OF DELETE registra
-- explicitamente la operacion DELETE logica en auditoria.
--
-- IDEMPOTENTE: cada trigger se crea solo si no existe.
-- =============================================

USE MatriculaCloud360DB;
GO

SET QUOTED_IDENTIFIER ON;
GO

PRINT '============================================';
PRINT 'audit/02_audit_triggers.sql - Auditoria ampliada';
PRINT '============================================';
GO

-- =============================================
-- 1. Trigger de auditoria generico (creado via EXEC)
--    Se aplica a cada entidad con su clave primaria.
-- =============================================

-- 1.1 core.Sedes (PK: SedeId)
IF OBJECT_ID(N'core.TRG_Audit_Sedes', N'TR') IS NULL
BEGIN
    EXEC('
    CREATE TRIGGER core.TRG_Audit_Sedes
    ON core.Sedes
    AFTER INSERT, UPDATE, DELETE
    AS
    BEGIN
        SET NOCOUNT ON;
        DECLARE @Operation CHAR(6);
        IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
            SET @Operation = ''UPDATE'';
        ELSE IF EXISTS (SELECT 1 FROM inserted)
            SET @Operation = ''INSERT'';
        ELSE
            SET @Operation = ''DELETE'';

        IF @Operation IN (''INSERT'', ''UPDATE'')
        BEGIN
            INSERT INTO audit.AuditLog (TableName, Operation, RecordId, Usuario, FechaOperacion, ValoresAnteriores, ValoresNuevos, DireccionIP)
            SELECT ''core.Sedes'', @Operation, i.SedeId, SUSER_SNAME(), GETDATE(),
                   CASE WHEN @Operation = ''UPDATE''
                        THEN (SELECT d.* FROM deleted d WHERE d.SedeId = i.SedeId FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
                        ELSE NULL END,
                   (SELECT x.* FROM inserted x WHERE x.SedeId = i.SedeId FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
                   CONVERT(VARCHAR(45), CONNECTIONPROPERTY(''client_net_address''))
            FROM inserted i;
        END
        ELSE
        BEGIN
            INSERT INTO audit.AuditLog (TableName, Operation, RecordId, Usuario, FechaOperacion, ValoresAnteriores, ValoresNuevos, DireccionIP)
            SELECT ''core.Sedes'', @Operation, d.SedeId, SUSER_SNAME(), GETDATE(),
                   (SELECT x.* FROM deleted x WHERE x.SedeId = d.SedeId FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
                   NULL,
                   CONVERT(VARCHAR(45), CONNECTIONPROPERTY(''client_net_address''))
            FROM deleted d;
        END
    END');
    PRINT 'OK: Trigger core.TRG_Audit_Sedes creado.';
END
ELSE
    PRINT 'OK: core.TRG_Audit_Sedes ya existe.';
GO

-- 1.2 core.Carreras (PK: CarreraId)
IF OBJECT_ID(N'core.TRG_Audit_Carreras', N'TR') IS NULL
BEGIN
    EXEC('
    CREATE TRIGGER core.TRG_Audit_Carreras
    ON core.Carreras
    AFTER INSERT, UPDATE, DELETE
    AS
    BEGIN
        SET NOCOUNT ON;
        DECLARE @Operation CHAR(6);
        IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
            SET @Operation = ''UPDATE'';
        ELSE IF EXISTS (SELECT 1 FROM inserted)
            SET @Operation = ''INSERT'';
        ELSE
            SET @Operation = ''DELETE'';

        IF @Operation IN (''INSERT'', ''UPDATE'')
        BEGIN
            INSERT INTO audit.AuditLog (TableName, Operation, RecordId, Usuario, FechaOperacion, ValoresAnteriores, ValoresNuevos, DireccionIP)
            SELECT ''core.Carreras'', @Operation, i.CarreraId, SUSER_SNAME(), GETDATE(),
                   CASE WHEN @Operation = ''UPDATE''
                        THEN (SELECT d.* FROM deleted d WHERE d.CarreraId = i.CarreraId FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
                        ELSE NULL END,
                   (SELECT x.* FROM inserted x WHERE x.CarreraId = i.CarreraId FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
                   CONVERT(VARCHAR(45), CONNECTIONPROPERTY(''client_net_address''))
            FROM inserted i;
        END
        ELSE
        BEGIN
            INSERT INTO audit.AuditLog (TableName, Operation, RecordId, Usuario, FechaOperacion, ValoresAnteriores, ValoresNuevos, DireccionIP)
            SELECT ''core.Carreras'', @Operation, d.CarreraId, SUSER_SNAME(), GETDATE(),
                   (SELECT x.* FROM deleted x WHERE x.CarreraId = d.CarreraId FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
                   NULL,
                   CONVERT(VARCHAR(45), CONNECTIONPROPERTY(''client_net_address''))
            FROM deleted d;
        END
    END');
    PRINT 'OK: Trigger core.TRG_Audit_Carreras creado.';
END
ELSE
    PRINT 'OK: core.TRG_Audit_Carreras ya existe.';
GO

-- 1.3 core.PeriodosAcademicos (PK: PeriodoId)
IF OBJECT_ID(N'core.TRG_Audit_Periodos', N'TR') IS NULL
BEGIN
    EXEC('
    CREATE TRIGGER core.TRG_Audit_Periodos
    ON core.PeriodosAcademicos
    AFTER INSERT, UPDATE, DELETE
    AS
    BEGIN
        SET NOCOUNT ON;
        DECLARE @Operation CHAR(6);
        IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
            SET @Operation = ''UPDATE'';
        ELSE IF EXISTS (SELECT 1 FROM inserted)
            SET @Operation = ''INSERT'';
        ELSE
            SET @Operation = ''DELETE'';

        IF @Operation IN (''INSERT'', ''UPDATE'')
        BEGIN
            INSERT INTO audit.AuditLog (TableName, Operation, RecordId, Usuario, FechaOperacion, ValoresAnteriores, ValoresNuevos, DireccionIP)
            SELECT ''core.PeriodosAcademicos'', @Operation, i.PeriodoId, SUSER_SNAME(), GETDATE(),
                   CASE WHEN @Operation = ''UPDATE''
                        THEN (SELECT d.* FROM deleted d WHERE d.PeriodoId = i.PeriodoId FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
                        ELSE NULL END,
                   (SELECT x.* FROM inserted x WHERE x.PeriodoId = i.PeriodoId FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
                   CONVERT(VARCHAR(45), CONNECTIONPROPERTY(''client_net_address''))
            FROM inserted i;
        END
        ELSE
        BEGIN
            INSERT INTO audit.AuditLog (TableName, Operation, RecordId, Usuario, FechaOperacion, ValoresAnteriores, ValoresNuevos, DireccionIP)
            SELECT ''core.PeriodosAcademicos'', @Operation, d.PeriodoId, SUSER_SNAME(), GETDATE(),
                   (SELECT x.* FROM deleted x WHERE x.PeriodoId = d.PeriodoId FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
                   NULL,
                   CONVERT(VARCHAR(45), CONNECTIONPROPERTY(''client_net_address''))
            FROM deleted d;
        END
    END');
    PRINT 'OK: Trigger core.TRG_Audit_Periodos creado.';
END
ELSE
    PRINT 'OK: core.TRG_Audit_Periodos ya existe.';
GO

-- 1.4 academic.Profesores (PK: ProfesorId)
IF OBJECT_ID(N'academic.TRG_Audit_Profesores', N'TR') IS NULL
BEGIN
    EXEC('
    CREATE TRIGGER academic.TRG_Audit_Profesores
    ON academic.Profesores
    AFTER INSERT, UPDATE, DELETE
    AS
    BEGIN
        SET NOCOUNT ON;
        DECLARE @Operation CHAR(6);
        IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
            SET @Operation = ''UPDATE'';
        ELSE IF EXISTS (SELECT 1 FROM inserted)
            SET @Operation = ''INSERT'';
        ELSE
            SET @Operation = ''DELETE'';

        IF @Operation IN (''INSERT'', ''UPDATE'')
        BEGIN
            INSERT INTO audit.AuditLog (TableName, Operation, RecordId, Usuario, FechaOperacion, ValoresAnteriores, ValoresNuevos, DireccionIP)
            SELECT ''academic.Profesores'', @Operation, i.ProfesorId, SUSER_SNAME(), GETDATE(),
                   CASE WHEN @Operation = ''UPDATE''
                        THEN (SELECT d.* FROM deleted d WHERE d.ProfesorId = i.ProfesorId FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
                        ELSE NULL END,
                   (SELECT x.* FROM inserted x WHERE x.ProfesorId = i.ProfesorId FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
                   CONVERT(VARCHAR(45), CONNECTIONPROPERTY(''client_net_address''))
            FROM inserted i;
        END
        ELSE
        BEGIN
            INSERT INTO audit.AuditLog (TableName, Operation, RecordId, Usuario, FechaOperacion, ValoresAnteriores, ValoresNuevos, DireccionIP)
            SELECT ''academic.Profesores'', @Operation, d.ProfesorId, SUSER_SNAME(), GETDATE(),
                   (SELECT x.* FROM deleted x WHERE x.ProfesorId = d.ProfesorId FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
                   NULL,
                   CONVERT(VARCHAR(45), CONNECTIONPROPERTY(''client_net_address''))
            FROM deleted d;
        END
    END');
    PRINT 'OK: Trigger academic.TRG_Audit_Profesores creado.';
END
ELSE
    PRINT 'OK: academic.TRG_Audit_Profesores ya existe.';
GO

-- 1.5 academic.Cursos (PK: CursoId)
IF OBJECT_ID(N'academic.TRG_Audit_Cursos', N'TR') IS NULL
BEGIN
    EXEC('
    CREATE TRIGGER academic.TRG_Audit_Cursos
    ON academic.Cursos
    AFTER INSERT, UPDATE, DELETE
    AS
    BEGIN
        SET NOCOUNT ON;
        DECLARE @Operation CHAR(6);
        IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
            SET @Operation = ''UPDATE'';
        ELSE IF EXISTS (SELECT 1 FROM inserted)
            SET @Operation = ''INSERT'';
        ELSE
            SET @Operation = ''DELETE'';

        IF @Operation IN (''INSERT'', ''UPDATE'')
        BEGIN
            INSERT INTO audit.AuditLog (TableName, Operation, RecordId, Usuario, FechaOperacion, ValoresAnteriores, ValoresNuevos, DireccionIP)
            SELECT ''academic.Cursos'', @Operation, i.CursoId, SUSER_SNAME(), GETDATE(),
                   CASE WHEN @Operation = ''UPDATE''
                        THEN (SELECT d.* FROM deleted d WHERE d.CursoId = i.CursoId FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
                        ELSE NULL END,
                   (SELECT x.* FROM inserted x WHERE x.CursoId = i.CursoId FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
                   CONVERT(VARCHAR(45), CONNECTIONPROPERTY(''client_net_address''))
            FROM inserted i;
        END
        ELSE
        BEGIN
            INSERT INTO audit.AuditLog (TableName, Operation, RecordId, Usuario, FechaOperacion, ValoresAnteriores, ValoresNuevos, DireccionIP)
            SELECT ''academic.Cursos'', @Operation, d.CursoId, SUSER_SNAME(), GETDATE(),
                   (SELECT x.* FROM deleted x WHERE x.CursoId = d.CursoId FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
                   NULL,
                   CONVERT(VARCHAR(45), CONNECTIONPROPERTY(''client_net_address''))
            FROM deleted d;
        END
    END');
    PRINT 'OK: Trigger academic.TRG_Audit_Cursos creado.';
END
ELSE
    PRINT 'OK: academic.TRG_Audit_Cursos ya existe.';
GO

-- 1.6 sales.CampaniasAdmision (PK: CampaniaId)
IF OBJECT_ID(N'sales.TRG_Audit_Campanias', N'TR') IS NULL
BEGIN
    EXEC('
    CREATE TRIGGER sales.TRG_Audit_Campanias
    ON sales.CampaniasAdmision
    AFTER INSERT, UPDATE, DELETE
    AS
    BEGIN
        SET NOCOUNT ON;
        DECLARE @Operation CHAR(6);
        IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
            SET @Operation = ''UPDATE'';
        ELSE IF EXISTS (SELECT 1 FROM inserted)
            SET @Operation = ''INSERT'';
        ELSE
            SET @Operation = ''DELETE'';

        IF @Operation IN (''INSERT'', ''UPDATE'')
        BEGIN
            INSERT INTO audit.AuditLog (TableName, Operation, RecordId, Usuario, FechaOperacion, ValoresAnteriores, ValoresNuevos, DireccionIP)
            SELECT ''sales.CampaniasAdmision'', @Operation, i.CampaniaId, SUSER_SNAME(), GETDATE(),
                   CASE WHEN @Operation = ''UPDATE''
                        THEN (SELECT d.* FROM deleted d WHERE d.CampaniaId = i.CampaniaId FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
                        ELSE NULL END,
                   (SELECT x.* FROM inserted x WHERE x.CampaniaId = i.CampaniaId FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
                   CONVERT(VARCHAR(45), CONNECTIONPROPERTY(''client_net_address''))
            FROM inserted i;
        END
        ELSE
        BEGIN
            INSERT INTO audit.AuditLog (TableName, Operation, RecordId, Usuario, FechaOperacion, ValoresAnteriores, ValoresNuevos, DireccionIP)
            SELECT ''sales.CampaniasAdmision'', @Operation, d.CampaniaId, SUSER_SNAME(), GETDATE(),
                   (SELECT x.* FROM deleted x WHERE x.CampaniaId = d.CampaniaId FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
                   NULL,
                   CONVERT(VARCHAR(45), CONNECTIONPROPERTY(''client_net_address''))
            FROM deleted d;
        END
    END');
    PRINT 'OK: Trigger sales.TRG_Audit_Campanias creado.';
END
ELSE
    PRINT 'OK: sales.TRG_Audit_Campanias ya existe.';
GO

-- 1.7 security.Usuarios (PK: UsuarioId)
IF OBJECT_ID(N'security.TRG_Audit_Usuarios', N'TR') IS NULL
BEGIN
    EXEC('
    CREATE TRIGGER security.TRG_Audit_Usuarios
    ON security.Usuarios
    AFTER INSERT, UPDATE, DELETE
    AS
    BEGIN
        SET NOCOUNT ON;
        DECLARE @Operation CHAR(6);
        IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
            SET @Operation = ''UPDATE'';
        ELSE IF EXISTS (SELECT 1 FROM inserted)
            SET @Operation = ''INSERT'';
        ELSE
            SET @Operation = ''DELETE'';

        IF @Operation IN (''INSERT'', ''UPDATE'')
        BEGIN
            INSERT INTO audit.AuditLog (TableName, Operation, RecordId, Usuario, FechaOperacion, ValoresAnteriores, ValoresNuevos, DireccionIP)
            SELECT ''security.Usuarios'', @Operation, i.UsuarioId, SUSER_SNAME(), GETDATE(),
                   CASE WHEN @Operation = ''UPDATE''
                        THEN (SELECT d.* FROM deleted d WHERE d.UsuarioId = i.UsuarioId FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
                        ELSE NULL END,
                   (SELECT x.* FROM inserted x WHERE x.UsuarioId = i.UsuarioId FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
                   CONVERT(VARCHAR(45), CONNECTIONPROPERTY(''client_net_address''))
            FROM inserted i;
        END
        ELSE
        BEGIN
            INSERT INTO audit.AuditLog (TableName, Operation, RecordId, Usuario, FechaOperacion, ValoresAnteriores, ValoresNuevos, DireccionIP)
            SELECT ''security.Usuarios'', @Operation, d.UsuarioId, SUSER_SNAME(), GETDATE(),
                   (SELECT x.* FROM deleted x WHERE x.UsuarioId = d.UsuarioId FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
                   NULL,
                   CONVERT(VARCHAR(45), CONNECTIONPROPERTY(''client_net_address''))
            FROM deleted d;
        END
    END');
    PRINT 'OK: Trigger security.TRG_Audit_Usuarios creado.';
END
ELSE
    PRINT 'OK: security.TRG_Audit_Usuarios ya existe.';
GO

PRINT '';
PRINT '============================================';
PRINT 'RESUMEN DE AUDITORIA (RN-07) - 11 triggers:';
PRINT '  Sprint 2: Estudiantes, Matriculas,';
PRINT '            Promotores, Comisiones';
PRINT '  Sprint 3: Sedes, Carreras, Periodos,';
PRINT '            Profesores, Cursos, Campanias,';
PRINT '            Usuarios';
PRINT '============================================';
GO