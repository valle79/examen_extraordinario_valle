-- =============================================
-- Matricula Cloud 360 Enterprise
-- security/02_roles.sql | Roles de base de datos
-- =============================================
-- Descripcion (Sprint 3): Crea los ROLES de base de datos para los
-- tres perfiles funcionales (RN-06) y asigna los usuarios creados en
-- 01_logins_users.sql como miembros:
--
--   ROL                           USUARIO         RESPONSABILIDAD
--   ---------------------------------------------------------------
--   rol_Administrador             MC_Admin        Acceso total
--   rol_Coordinador_Academico     MC_Coordinador  Gestion academica y reportes
--   rol_Promotor                  MC_Promotor     Captacion de estudiantes
--
-- El principio aplicado es el de MENOR PRIVILEGIO: cada rol recibe en
-- 03_permissions.sql unicamente los permisos para las operaciones de
-- su responsabilidad, mediante GRANT, DENY y REVOKE.
--
-- IDEMPOTENTE: roles y membresias se crean solo si no existen.
-- =============================================

USE MatriculaCloud360DB;
GO

PRINT '============================================';
PRINT 'security/02_roles.sql - Roles de base de datos';
PRINT '============================================';
GO

-- =============================================
-- 1. CREAR ROLES
-- =============================================
IF DATABASE_PRINCIPAL_ID('rol_Administrador') IS NULL
BEGIN
    CREATE ROLE [rol_Administrador];
    PRINT 'OK: Rol rol_Administrador creado.';
END
ELSE
    PRINT 'OK: Rol rol_Administrador ya existe.';
GO

IF DATABASE_PRINCIPAL_ID('rol_Coordinador_Academico') IS NULL
BEGIN
    CREATE ROLE [rol_Coordinador_Academico];
    PRINT 'OK: Rol rol_Coordinador_Academico creado.';
END
ELSE
    PRINT 'OK: Rol rol_Coordinador_Academico ya existe.';
GO

IF DATABASE_PRINCIPAL_ID('rol_Promotor') IS NULL
BEGIN
    CREATE ROLE [rol_Promotor];
    PRINT 'OK: Rol rol_Promotor creado.';
END
ELSE
    PRINT 'OK: Rol rol_Promotor ya existe.';
GO

-- =============================================
-- 2. ASIGNAR USUARIOS A ROLES
-- =============================================
IF IS_ROLEMEMBER('rol_Administrador', 'MC_Admin') = 0
BEGIN
    ALTER ROLE [rol_Administrador] ADD MEMBER [MC_Admin];
    PRINT 'OK: MC_Admin asignado a rol_Administrador.';
END
ELSE
    PRINT 'OK: MC_Admin ya pertenece a rol_Administrador.';
GO

IF IS_ROLEMEMBER('rol_Coordinador_Academico', 'MC_Coordinador') = 0
BEGIN
    ALTER ROLE [rol_Coordinador_Academico] ADD MEMBER [MC_Coordinador];
    PRINT 'OK: MC_Coordinador asignado a rol_Coordinador_Academico.';
END
ELSE
    PRINT 'OK: MC_Coordinador ya pertenece a rol_Coordinador_Academico.';
GO

IF IS_ROLEMEMBER('rol_Promotor', 'MC_Promotor') = 0
BEGIN
    ALTER ROLE [rol_Promotor] ADD MEMBER [MC_Promotor];
    PRINT 'OK: MC_Promotor asignado a rol_Promotor.';
END
ELSE
    PRINT 'OK: MC_Promotor ya pertenece a rol_Promotor.';
GO

-- =============================================
-- 3. ROLES FIJOS DE SQL SERVER
--    El administrador requiere acceso total: se le agrega tambien
--    al rol fijo db_owner (es el maximo privilegio a nivel base).
-- =============================================
IF IS_ROLEMEMBER('db_owner', 'MC_Admin') = 0
BEGIN
    ALTER ROLE [db_owner] ADD MEMBER [MC_Admin];
    PRINT 'OK: MC_Admin incorporado a db_owner (acceso completo).';
END
ELSE
    PRINT 'OK: MC_Admin ya es miembro de db_owner.';
GO

PRINT '============================================';
PRINT '02_roles.sql finalizado.';
PRINT '============================================';
GO