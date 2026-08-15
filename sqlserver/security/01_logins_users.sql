-- =============================================
-- Matricula Cloud 360 Enterprise
-- security/01_logins_users.sql | Logins y usuarios
-- =============================================
-- Descripcion (Sprint 3): Crea a nivel de servidor los LOGINS de los
-- tres perfiles de seguridad (RN-06) y a nivel de base de datos los
-- USUARIOS correspondientes:
--   1. MC_Admin        -> Administrador
--   2. MC_Coordinador  -> Coordinador Academico
--   3. MC_Promotor     -> Promotor
--
-- Los permisos se otorgan en 02_roles.sql y 03_permissions.sql.
--
-- IDEMPOTENTE: logins y usuarios se crean solo si no existen.
-- =============================================

USE master;
GO

PRINT '============================================';
PRINT 'security/01_logins_users.sql - Logins y usuarios';
PRINT '============================================';
GO

-- =============================================
-- 1. LOGINS (nivel servidor)
-- =============================================
IF NOT EXISTS (SELECT 1 FROM sys.sql_logins WHERE name = 'MC_Admin')
BEGIN
    CREATE LOGIN [MC_Admin] WITH PASSWORD = 'MCAdmin#2026',
        DEFAULT_DATABASE = [MatriculaCloud360DB],
        CHECK_POLICY = ON,
        CHECK_EXPIRATION = OFF;
    PRINT 'OK: Login MC_Admin creado.';
END
ELSE
    PRINT 'OK: Login MC_Admin ya existe.';
GO

IF NOT EXISTS (SELECT 1 FROM sys.sql_logins WHERE name = 'MC_Coordinador')
BEGIN
    CREATE LOGIN [MC_Coordinador] WITH PASSWORD = 'MCCoord#2026',
        DEFAULT_DATABASE = [MatriculaCloud360DB],
        CHECK_POLICY = ON,
        CHECK_EXPIRATION = OFF;
    PRINT 'OK: Login MC_Coordinador creado.';
END
ELSE
    PRINT 'OK: Login MC_Coordinador ya existe.';
GO

IF NOT EXISTS (SELECT 1 FROM sys.sql_logins WHERE name = 'MC_Promotor')
BEGIN
    CREATE LOGIN [MC_Promotor] WITH PASSWORD = 'MCPromo#2026',
        DEFAULT_DATABASE = [MatriculaCloud360DB],
        CHECK_POLICY = ON,
        CHECK_EXPIRATION = OFF;
    PRINT 'OK: Login MC_Promotor creado.';
END
ELSE
    PRINT 'OK: Login MC_Promotor ya existe.';
GO

-- =============================================
-- 2. USUARIOS (nivel base de datos)
-- =============================================
USE MatriculaCloud360DB;
GO

IF DATABASE_PRINCIPAL_ID('MC_Admin') IS NULL
BEGIN
    CREATE USER [MC_Admin] FOR LOGIN [MC_Admin] WITH DEFAULT_SCHEMA = dbo;
    PRINT 'OK: Usuario MC_Admin creado.';
END
ELSE
    PRINT 'OK: Usuario MC_Admin ya existe.';
GO

IF DATABASE_PRINCIPAL_ID('MC_Coordinador') IS NULL
BEGIN
    CREATE USER [MC_Coordinador] FOR LOGIN [MC_Coordinador] WITH DEFAULT_SCHEMA = dbo;
    PRINT 'OK: Usuario MC_Coordinador creado.';
END
ELSE
    PRINT 'OK: Usuario MC_Coordinador ya existe.';
GO

IF DATABASE_PRINCIPAL_ID('MC_Promotor') IS NULL
BEGIN
    CREATE USER [MC_Promotor] FOR LOGIN [MC_Promotor] WITH DEFAULT_SCHEMA = dbo;
    PRINT 'OK: Usuario MC_Promotor creado.';
END
ELSE
    PRINT 'OK: Usuario MC_Promotor ya existe.';
GO

PRINT '============================================';
PRINT '01_logins_users.sql finalizado.';
PRINT '============================================';
GO