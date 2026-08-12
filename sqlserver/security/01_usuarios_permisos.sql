-- =============================================
-- Matricula Cloud 360 Enterprise
-- security/01_usuarios_permisos.sql
-- =============================================
-- Descripcion: Implementa la RN-06 (perfiles de seguridad) a nivel
-- de SQL Server: crea los tres perfiles como LOGINS y USUARIOS de
-- base de datos con permisos DIFERENTES mediante GRANT y DENY:
--
--   1. MC_Admin        (Administrador)        -> acceso completo (db_owner)
--   2. MC_Coordinador  (Coordinador Academico)-> gestion academica y reportes
--   3. MC_Promotor     (Promotor)             -> registro de estudiantes y
--                                                consulta de sus comisiones
--
-- Principio aplicado: "menor privilegio". El acceso a los datos se
-- otorga SOLO a traves de vistas y procedimientos almacenados
-- (seguridad por encadenamiento de propiedad: todo pertenece a dbo),
-- y se DENIEGA explicitamente el acceso directo a las entidades
-- sensibles (Matriculas, Comisiones, seguridad y auditoria).
--
-- La auditoria (RN-07) registrara el LOGIN que ejecuta la operacion
-- (SUSER_SNAME()): si opera MC_Promotor, quedara registrado en
-- audit.AuditLog el responsable real de la accion.
--
-- IDEMPOTENTE: los logins/usuarios se crean solo si no existen y
-- GRANT/DENY pueden reejecutarse sin errores.
-- =============================================

USE master;
GO

PRINT '============================================';
PRINT '01_usuarios_permisos.sql - Perfiles de seguridad (RN-06)';
PRINT '============================================';
GO

-- =============================================
-- 1. LOGINS a nivel de servidor
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
-- 2. USUARIOS de la base de datos
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

-- =============================================
-- 3. PERMISOS DEL ADMINISTRADOR (acceso completo)
-- =============================================
IF IS_ROLEMEMBER('db_owner', 'MC_Admin') = 0
BEGIN
    ALTER ROLE [db_owner] ADD MEMBER [MC_Admin];
    PRINT 'OK: MC_Admin incorporado a db_owner (acceso completo).';
END
ELSE
    PRINT 'OK: MC_Admin ya es miembro de db_owner.';
GO

-- =============================================
-- 4. PERMISOS DEL COORDINADOR ACADEMICO
--    Gestion academica y reportes: consulta de vistas academicas/core,
--    registra y retira matriculas, actualiza datos de estudiantes.
--    NO ve comisiones, ni seguridad, ni auditoria.
-- =============================================
PRINT 'Otorgando permisos a MC_Coordinador...';
GO

-- Reportes y consulta (vistas, por encadenamiento de propiedad)
GRANT SELECT ON OBJECT::core.vw_EstudiantesDetalle        TO [MC_Coordinador];
GRANT SELECT ON OBJECT::core.vw_MatriculasDetalle         TO [MC_Coordinador];
GRANT SELECT ON OBJECT::core.vw_ReporteMatriculasPeriodo  TO [MC_Coordinador];
GRANT SELECT ON OBJECT::academic.vw_MallaCurricular       TO [MC_Coordinador];
GRANT SELECT ON OBJECT::academic.vw_ProfesoresDetalle     TO [MC_Coordinador];

-- Funciones de negocio reutilizables
GRANT EXECUTE ON OBJECT::core.fn_PeriodoMatriculaHabilitado  TO [MC_Coordinador];
GRANT EXECUTE ON OBJECT::core.fn_ExisteEstudianteConDocumento TO [MC_Coordinador];
GRANT EXECUTE ON OBJECT::core.fn_TotalMatriculadosCarrera     TO [MC_Coordinador];

-- Procedimientos de su competencia (la validacion de negocio corre dentro del SP)
GRANT EXECUTE ON OBJECT::core.usp_RegistrarEstudiante     TO [MC_Coordinador];
GRANT EXECUTE ON OBJECT::core.usp_ActualizarEstudiante    TO [MC_Coordinador];
GRANT EXECUTE ON OBJECT::core.usp_EliminarEstudianteLogico TO [MC_Coordinador];
GRANT EXECUTE ON OBJECT::core.usp_RegistrarMatricula      TO [MC_Coordinador];
GRANT EXECUTE ON OBJECT::core.usp_RetirarMatricula        TO [MC_Coordinador];
GRANT EXECUTE ON OBJECT::core.usp_ConsultarMatriculas     TO [MC_Coordinador];

-- Denegaciones explicitas: areas fuera de su alcance
DENY SELECT ON SCHEMA::sales   TO [MC_Coordinador];
DENY SELECT ON SCHEMA::security TO [MC_Coordinador];
DENY SELECT ON SCHEMA::audit   TO [MC_Coordinador];
DENY UPDATE, DELETE ON SCHEMA::core TO [MC_Coordinador];
DENY INSERT, UPDATE, DELETE ON SCHEMA::sales TO [MC_Coordinador];

PRINT 'OK: Permisos de MC_Coordinador aplicados.';
GO

-- =============================================
-- 5. PERMISOS DEL PROMOTOR
--    Registro de estudiantes y consulta de sus comisiones.
--    NO registra matriculas, NO ve seguridad, NI auditoria.
-- =============================================
PRINT 'Otorgando permisos a MC_Promotor...';
GO

-- Consulta de estudiantes y de sus comisiones/desempeno
GRANT SELECT ON OBJECT::core.vw_EstudiantesDetalle     TO [MC_Promotor];
GRANT SELECT ON OBJECT::sales.vw_ComisionesDetalle     TO [MC_Promotor];
GRANT SELECT ON OBJECT::sales.vw_DesempenoPromotores   TO [MC_Promotor];

-- Procedimientos de su competencia
GRANT EXECUTE ON OBJECT::core.usp_RegistrarEstudiante     TO [MC_Promotor];
GRANT EXECUTE ON OBJECT::core.usp_ActualizarEstudiante    TO [MC_Promotor];
GRANT EXECUTE ON OBJECT::core.usp_EliminarEstudianteLogico TO [MC_Promotor];
GRANT EXECUTE ON OBJECT::core.usp_ConsultarMatriculas     TO [MC_Promotor];

-- Denegaciones explicitas: el promotor NO matricula ni accede a areas sensibles
DENY EXECUTE ON OBJECT::core.usp_RegistrarMatricula TO [MC_Promotor];
DENY EXECUTE ON OBJECT::core.usp_RetirarMatricula   TO [MC_Promotor];
DENY SELECT, INSERT, UPDATE, DELETE ON SCHEMA::security TO [MC_Promotor];
DENY SELECT, INSERT, UPDATE, DELETE ON SCHEMA::audit    TO [MC_Promotor];
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::core.Matriculas TO [MC_Promotor];
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::sales.Comisiones TO [MC_Promotor];
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::sales.CampaniasAdmision TO [MC_Promotor];

PRINT 'OK: Permisos de MC_Promotor aplicados.';
GO

-- =============================================
-- RESUMEN DE PERFILES (RN-06)
-- =============================================
PRINT '';
PRINT '============================================';
PRINT 'RESUMEN DE PERFILES DE SEGURIDAD (RN-06):';
PRINT '============================================';
PRINT '  MC_Admin       : db_owner (acceso completo a la base)';
PRINT '  MC_Coordinador : vistas academicas/core, registra/retira matricula,';
PRINT '                   actualiza estudiantes. SIN comisiones/seguridad/auditoria.';
PRINT '  MC_Promotor    : registra/actualiza estudiantes y consulta sus';
PRINT '                   comisiones. SIN matriculas/seguridad/auditoria.';
PRINT '';
PRINT '  Conectar como (desde el HOST, puerto 1434; dentro del contenedor usar localhost sin puerto):';
PRINT '    sqlcmd -S localhost,1434 -U MC_Admin       -P "MCAdmin#2026"';
PRINT '    sqlcmd -S localhost,1434 -U MC_Coordinador -P "MCCoord#2026"';
PRINT '    sqlcmd -S localhost,1434 -U MC_Promotor    -P "MCPromo#2026"';
PRINT '============================================';
GO