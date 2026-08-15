-- =============================================
-- Matricula Cloud 360 Enterprise
-- audit/03_soft_delete.sql | Borrado logico (deleted_at)
-- =============================================
-- Descripcion (Sprint 3):
--   Convierte la ELIMINACION FISICA en BORRADO LOGICO (RN-10):
--   cada tabla con columna DeletedAt recibe un trigger INSTEAD OF
--   DELETE que, ante un DELETE, en lugar de eliminar la fila:
--     1) Actualiza DeletedAt = GETDATE(), Activo = 0 y UpdatedAt.
--     2) Registra en audit.AuditLog la operacion DELETE logica con
--        los valores anteriores (JSON) y la fecha de desactivacion.
--
--   Resultado: el registro permanece fisicamente en la base (auditoria
--   historica, facturacion, reportes) pero deja de aparecer en las
--   consultas operativas (todas filtran WHERE DeletedAt IS NULL).
--
--   NOTA DE DISENO (comportamiento de triggers en SQL Server):
--   Cuando existe un trigger INSTEAD OF DELETE, el trigger AFTER
--   DELETE de la tabla NO se dispara (verificado experimentalmente).
--   Por eso el INSTEAD OF DELETE registra la auditoria DELETE por
--   cuenta propia. El UPDATE interno dispara el AFTER UPDATE de
--   auditoria, que registra la modificacion fisica (UPDATE con la
--   fecha de desactivacion). Ambos registros coexisten: uno describe
--   la operacion solicitada (DELETE logica) y otro el cambio fisico
--   (UPDATE de DeletedAt).
--
-- IDEMPOTENTE: cada trigger se crea solo si no existe.
-- =============================================

USE MatriculaCloud360DB;
GO

SET QUOTED_IDENTIFIER ON;
GO

PRINT '============================================';
PRINT 'audit/03_soft_delete.sql - Borrado logico';
PRINT '============================================';
GO

-- =============================================
-- 1. core.Estudiantes (RN-10)
-- =============================================
IF OBJECT_ID(N'core.TRG_SoftDelete_Estudiantes', N'TR') IS NULL
BEGIN
    EXEC('
    CREATE TRIGGER core.TRG_SoftDelete_Estudiantes
    ON core.Estudiantes
    INSTEAD OF DELETE
    AS
    BEGIN
        SET NOCOUNT ON;

        UPDATE e
        SET e.Activo = 0,
            e.DeletedAt = GETDATE(),
            e.UpdatedAt = GETDATE()
        FROM core.Estudiantes e
        INNER JOIN deleted d ON d.EstudianteId = e.EstudianteId;

        INSERT INTO audit.AuditLog (TableName, Operation, RecordId, Usuario, FechaOperacion, ValoresAnteriores, ValoresNuevos, DireccionIP)
        SELECT ''core.Estudiantes'', ''DELETE'', d.EstudianteId, SUSER_SNAME(), GETDATE(),
               (SELECT x.* FROM deleted x WHERE x.EstudianteId = d.EstudianteId FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
               JSON_MODIFY((SELECT x.* FROM core.Estudiantes x WHERE x.EstudianteId = d.EstudianteId FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
                           ''$.Operacion'', ''Borrado logico (deleted_at)''),
               CONVERT(VARCHAR(45), CONNECTIONPROPERTY(''client_net_address''))
        FROM deleted d;
    END');
    PRINT 'OK: Trigger core.TRG_SoftDelete_Estudiantes creado.';
END
ELSE
    PRINT 'OK: core.TRG_SoftDelete_Estudiantes ya existe.';
GO

-- =============================================
-- 2. core.Matriculas (RN-10)
-- =============================================
IF OBJECT_ID(N'core.TRG_SoftDelete_Matriculas', N'TR') IS NULL
BEGIN
    EXEC('
    CREATE TRIGGER core.TRG_SoftDelete_Matriculas
    ON core.Matriculas
    INSTEAD OF DELETE
    AS
    BEGIN
        SET NOCOUNT ON;

        UPDATE m
        SET m.Activo = 0,
            m.DeletedAt = GETDATE(),
            m.UpdatedAt = GETDATE()
        FROM core.Matriculas m
        INNER JOIN deleted d ON d.MatriculaId = m.MatriculaId;

        INSERT INTO audit.AuditLog (TableName, Operation, RecordId, Usuario, FechaOperacion, ValoresAnteriores, ValoresNuevos, DireccionIP)
        SELECT ''core.Matriculas'', ''DELETE'', d.MatriculaId, SUSER_SNAME(), GETDATE(),
               (SELECT x.* FROM deleted x WHERE x.MatriculaId = d.MatriculaId FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
               JSON_MODIFY((SELECT x.* FROM core.Matriculas x WHERE x.MatriculaId = d.MatriculaId FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
                           ''$.Operacion'', ''Borrado logico (deleted_at)''),
               CONVERT(VARCHAR(45), CONNECTIONPROPERTY(''client_net_address''))
        FROM deleted d;
    END');
    PRINT 'OK: Trigger core.TRG_SoftDelete_Matriculas creado.';
END
ELSE
    PRINT 'OK: core.TRG_SoftDelete_Matriculas ya existe.';
GO

-- =============================================
-- 3. core.Sedes
-- =============================================
IF OBJECT_ID(N'core.TRG_SoftDelete_Sedes', N'TR') IS NULL
BEGIN
    EXEC('
    CREATE TRIGGER core.TRG_SoftDelete_Sedes
    ON core.Sedes
    INSTEAD OF DELETE
    AS
    BEGIN
        SET NOCOUNT ON;

        UPDATE s
        SET s.Activo = 0,
            s.DeletedAt = GETDATE(),
            s.UpdatedAt = GETDATE()
        FROM core.Sedes s
        INNER JOIN deleted d ON d.SedeId = s.SedeId;

        INSERT INTO audit.AuditLog (TableName, Operation, RecordId, Usuario, FechaOperacion, ValoresAnteriores, ValoresNuevos, DireccionIP)
        SELECT ''core.Sedes'', ''DELETE'', d.SedeId, SUSER_SNAME(), GETDATE(),
               (SELECT x.* FROM deleted x WHERE x.SedeId = d.SedeId FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
               JSON_MODIFY((SELECT x.* FROM core.Sedes x WHERE x.SedeId = d.SedeId FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
                           ''$.Operacion'', ''Borrado logico (deleted_at)''),
               CONVERT(VARCHAR(45), CONNECTIONPROPERTY(''client_net_address''))
        FROM deleted d;
    END');
    PRINT 'OK: Trigger core.TRG_SoftDelete_Sedes creado.';
END
ELSE
    PRINT 'OK: core.TRG_SoftDelete_Sedes ya existe.';
GO

-- =============================================
-- 4. core.Carreras
-- =============================================
IF OBJECT_ID(N'core.TRG_SoftDelete_Carreras', N'TR') IS NULL
BEGIN
    EXEC('
    CREATE TRIGGER core.TRG_SoftDelete_Carreras
    ON core.Carreras
    INSTEAD OF DELETE
    AS
    BEGIN
        SET NOCOUNT ON;

        UPDATE c
        SET c.Activo = 0,
            c.DeletedAt = GETDATE(),
            c.UpdatedAt = GETDATE()
        FROM core.Carreras c
        INNER JOIN deleted d ON d.CarreraId = c.CarreraId;

        INSERT INTO audit.AuditLog (TableName, Operation, RecordId, Usuario, FechaOperacion, ValoresAnteriores, ValoresNuevos, DireccionIP)
        SELECT ''core.Carreras'', ''DELETE'', d.CarreraId, SUSER_SNAME(), GETDATE(),
               (SELECT x.* FROM deleted x WHERE x.CarreraId = d.CarreraId FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
               JSON_MODIFY((SELECT x.* FROM core.Carreras x WHERE x.CarreraId = d.CarreraId FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
                           ''$.Operacion'', ''Borrado logico (deleted_at)''),
               CONVERT(VARCHAR(45), CONNECTIONPROPERTY(''client_net_address''))
        FROM deleted d;
    END');
    PRINT 'OK: Trigger core.TRG_SoftDelete_Carreras creado.';
END
ELSE
    PRINT 'OK: core.TRG_SoftDelete_Carreras ya existe.';
GO

-- =============================================
-- 5. academic.Profesores
-- =============================================
IF OBJECT_ID(N'academic.TRG_SoftDelete_Profesores', N'TR') IS NULL
BEGIN
    EXEC('
    CREATE TRIGGER academic.TRG_SoftDelete_Profesores
    ON academic.Profesores
    INSTEAD OF DELETE
    AS
    BEGIN
        SET NOCOUNT ON;

        UPDATE p
        SET p.Activo = 0,
            p.DeletedAt = GETDATE(),
            p.UpdatedAt = GETDATE()
        FROM academic.Profesores p
        INNER JOIN deleted d ON d.ProfesorId = p.ProfesorId;

        INSERT INTO audit.AuditLog (TableName, Operation, RecordId, Usuario, FechaOperacion, ValoresAnteriores, ValoresNuevos, DireccionIP)
        SELECT ''academic.Profesores'', ''DELETE'', d.ProfesorId, SUSER_SNAME(), GETDATE(),
               (SELECT x.* FROM deleted x WHERE x.ProfesorId = d.ProfesorId FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
               JSON_MODIFY((SELECT x.* FROM academic.Profesores x WHERE x.ProfesorId = d.ProfesorId FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
                           ''$.Operacion'', ''Borrado logico (deleted_at)''),
               CONVERT(VARCHAR(45), CONNECTIONPROPERTY(''client_net_address''))
        FROM deleted d;
    END');
    PRINT 'OK: Trigger academic.TRG_SoftDelete_Profesores creado.';
END
ELSE
    PRINT 'OK: academic.TRG_SoftDelete_Profesores ya existe.';
GO

-- =============================================
-- 6. academic.Cursos
-- =============================================
IF OBJECT_ID(N'academic.TRG_SoftDelete_Cursos', N'TR') IS NULL
BEGIN
    EXEC('
    CREATE TRIGGER academic.TRG_SoftDelete_Cursos
    ON academic.Cursos
    INSTEAD OF DELETE
    AS
    BEGIN
        SET NOCOUNT ON;

        UPDATE c
        SET c.Activo = 0,
            c.DeletedAt = GETDATE(),
            c.UpdatedAt = GETDATE()
        FROM academic.Cursos c
        INNER JOIN deleted d ON d.CursoId = c.CursoId;

        INSERT INTO audit.AuditLog (TableName, Operation, RecordId, Usuario, FechaOperacion, ValoresAnteriores, ValoresNuevos, DireccionIP)
        SELECT ''academic.Cursos'', ''DELETE'', d.CursoId, SUSER_SNAME(), GETDATE(),
               (SELECT x.* FROM deleted x WHERE x.CursoId = d.CursoId FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
               JSON_MODIFY((SELECT x.* FROM academic.Cursos x WHERE x.CursoId = d.CursoId FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
                           ''$.Operacion'', ''Borrado logico (deleted_at)''),
               CONVERT(VARCHAR(45), CONNECTIONPROPERTY(''client_net_address''))
        FROM deleted d;
    END');
    PRINT 'OK: Trigger academic.TRG_SoftDelete_Cursos creado.';
END
ELSE
    PRINT 'OK: academic.TRG_SoftDelete_Cursos ya existe.';
GO

-- =============================================
-- 7. sales.Promotores
-- =============================================
IF OBJECT_ID(N'sales.TRG_SoftDelete_Promotores', N'TR') IS NULL
BEGIN
    EXEC('
    CREATE TRIGGER sales.TRG_SoftDelete_Promotores
    ON sales.Promotores
    INSTEAD OF DELETE
    AS
    BEGIN
        SET NOCOUNT ON;

        UPDATE p
        SET p.Activo = 0,
            p.DeletedAt = GETDATE(),
            p.UpdatedAt = GETDATE()
        FROM sales.Promotores p
        INNER JOIN deleted d ON d.PromotorId = p.PromotorId;

        INSERT INTO audit.AuditLog (TableName, Operation, RecordId, Usuario, FechaOperacion, ValoresAnteriores, ValoresNuevos, DireccionIP)
        SELECT ''sales.Promotores'', ''DELETE'', d.PromotorId, SUSER_SNAME(), GETDATE(),
               (SELECT x.* FROM deleted x WHERE x.PromotorId = d.PromotorId FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
               JSON_MODIFY((SELECT x.* FROM sales.Promotores x WHERE x.PromotorId = d.PromotorId FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
                           ''$.Operacion'', ''Borrado logico (deleted_at)''),
               CONVERT(VARCHAR(45), CONNECTIONPROPERTY(''client_net_address''))
        FROM deleted d;
    END');
    PRINT 'OK: Trigger sales.TRG_SoftDelete_Promotores creado.';
END
ELSE
    PRINT 'OK: sales.TRG_SoftDelete_Promotores ya existe.';
GO

-- =============================================
-- RESUMEN
-- =============================================
PRINT '';
PRINT '============================================';
PRINT 'BORRADO LOGICO (deleted_at) - 7 tablas:';
PRINT '  core.Estudiantes, core.Matriculas,';
PRINT '  core.Sedes, core.Carreras,';
PRINT '  academic.Profesores, academic.Cursos,';
PRINT '  sales.Promotores';
PRINT '';
PRINT 'Comportamiento: DELETE -> UPDATE DeletedAt';
PRINT 'El registro nunca se elimina fisicamente.';
PRINT '============================================';
GO