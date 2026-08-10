-- =============================================
-- Matricula Cloud 360 Enterprise
-- 02_schemas.sql | Creacion de esquemas
-- =============================================
-- Descripcion: Organiza los objetos de la base de datos
-- en esquemas logicos por dominio de negocio.
--
-- IDEMPOTENTE: crea cada esquema solo si no existe.
-- =============================================

USE MatriculaCloud360DB;
GO

PRINT '============================================';
PRINT '02_schemas.sql - Creacion de esquemas';
PRINT '============================================';
GO

-- =============================================
-- ESQUEMA: core
-- Entidades principales del negocio:
-- Sedes, Carreras, Estudiantes, Periodos, Matriculas
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'core')
BEGIN
    EXEC('CREATE SCHEMA core AUTHORIZATION dbo');
    PRINT 'OK: Esquema [core] creado.';
END
ELSE
    PRINT 'OK: Esquema [core] ya existe.';
GO

-- =============================================
-- ESQUEMA: academic
-- Gestion academica:
-- Profesores, Cursos, mallas (CarreraCursos), asignaciones (CursoProfesor)
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'academic')
BEGIN
    EXEC('CREATE SCHEMA academic AUTHORIZATION dbo');
    PRINT 'OK: Esquema [academic] creado.';
END
ELSE
    PRINT 'OK: Esquema [academic] ya existe.';
GO

-- =============================================
-- ESQUEMA: sales
-- Gestion comercial:
-- Promotores, CampaniasAdmision, Comisiones
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'sales')
BEGIN
    EXEC('CREATE SCHEMA sales AUTHORIZATION dbo');
    PRINT 'OK: Esquema [sales] creado.';
END
ELSE
    PRINT 'OK: Esquema [sales] ya existe.';
GO

-- =============================================
-- ESQUEMA: security
-- Seguridad y control de acceso:
-- Roles, Usuarios
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'security')
BEGIN
    EXEC('CREATE SCHEMA security AUTHORIZATION dbo');
    PRINT 'OK: Esquema [security] creado.';
END
ELSE
    PRINT 'OK: Esquema [security] ya existe.';
GO

-- =============================================
-- ESQUEMA: audit
-- Auditoria de operaciones criticas (INSERT/UPDATE/DELETE)
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'audit')
BEGIN
    EXEC('CREATE SCHEMA audit AUTHORIZATION dbo');
    PRINT 'OK: Esquema [audit] creado.';
END
ELSE
    PRINT 'OK: Esquema [audit] ya existe.';
GO

-- =============================================
-- ESQUEMA: utils
-- Objetos utilitarios (funciones, procedimientos de soporte)
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'utils')
BEGIN
    EXEC('CREATE SCHEMA utils AUTHORIZATION dbo');
    PRINT 'OK: Esquema [utils] creado.';
END
ELSE
    PRINT 'OK: Esquema [utils] ya existe.';
GO

PRINT '';
PRINT 'Resumen de esquemas:';
PRINT '  [core]     - Entidades principales del negocio';
PRINT '  [academic] - Gestion academica';
PRINT '  [sales]    - Promotores, campanas y comisiones';
PRINT '  [security] - Roles y usuarios';
PRINT '  [audit]    - Registro de auditoria';
PRINT '  [utils]    - Utilidades';
PRINT '============================================';
GO
