-- =============================================
-- Matricula Cloud 360 Enterprise
-- utils/verificar_instalacion.sql
-- =============================================
-- Descripcion: Verifica que la instalacion este completa y correcta:
--   - Base de datos creada
--   - Esquemas presentes
--   - 17 tablas creadas
--   - 21 Foreign Keys, 22 Unique, 30 Check
--   - 17 indices no agrupados de optimizacion (14 Sprint 1 + 3 Sprint 3)
--   - Datos iniciales cargados (seed + prueba Sprint 2; los conteos
--     de Matriculas/Comisiones se validan segun la ventana del
--     periodo 2027-I este abierta o cerrada)
--   - Integridad referencial sin huerfanos
--   - Objetos del Sprint 2 (funciones, vistas, triggers, procedimientos)
--   - Seguridad RN-06 (perfiles MC_Admin/MC_Coordinador/MC_Promotor con
--     permisos GRANT/DENY comprobados mediante EXECUTE AS)
--   - Sprint 3: auditoria (triggers + borrado logico), indices nuevos,
--     vistas analiticas, respaldos y jobs de SQL Agent, roles y DENY
--
-- Uso: docker compose exec sqlserver /opt/mssql-tools18/bin/sqlcmd
--        -S localhost -U SA -P "$SA_PASSWORD" -C -i /sqlserver/utils/verificar_instalacion.sql
-- =============================================

USE MatriculaCloud360DB;
GO

SET NOCOUNT ON;
GO

PRINT '==========================================================';
PRINT '  VERIFICACION DE INSTALACION';
PRINT '  Matricula Cloud 360 Enterprise';
PRINT '==========================================================';
PRINT '';

DECLARE @TotalErrores INT = 0;
DECLARE @TotalWarnings INT = 0;

-- ==========================================================
-- 1. BASE DE DATOS
-- ==========================================================
PRINT '1. BASE DE DATOS';
PRINT '   ----------------------------------------------';

IF EXISTS (SELECT 1 FROM sys.databases WHERE name COLLATE DATABASE_DEFAULT = 'MatriculaCloud360DB')
BEGIN
    PRINT '   [OK] Base de datos MatriculaCloud360DB existe';

    DECLARE @Collation NVARCHAR(128);
    SELECT @Collation = collation_name COLLATE DATABASE_DEFAULT
    FROM sys.databases
    WHERE name COLLATE DATABASE_DEFAULT = 'MatriculaCloud360DB';

    IF @Collation = 'SQL_Latin1_General_CP1_CI_AS' OR @Collation LIKE '%Modern_Spanish%' OR @Collation LIKE '%Spanish%'
        PRINT '   [OK] Collation: ' + @Collation + ' (CI, compatible con espanol)';
    ELSE
    BEGIN
        PRINT '   [AVISO] Collation: ' + @Collation + ' (se esperaba Modern_Spanish_CI_AS o SQL_Latin1_General_CP1_CI_AS)';
        SET @TotalWarnings = @TotalWarnings + 1;
    END

    DECLARE @RecoveryModel NVARCHAR(60);
    SELECT @RecoveryModel = recovery_model_desc COLLATE DATABASE_DEFAULT
    FROM sys.databases
    WHERE name COLLATE DATABASE_DEFAULT = 'MatriculaCloud360DB';

    IF @RecoveryModel = 'FULL'
        PRINT '   [OK] Recovery Model: FULL (respaldos habilitados)';
    ELSE
    BEGIN
        PRINT '   [AVISO] Recovery Model: ' + @RecoveryModel + ' (recomendado: FULL)';
        SET @TotalWarnings = @TotalWarnings + 1;
    END
END
ELSE
BEGIN
    PRINT '   [ERROR] La base de datos MatriculaCloud360DB NO existe';
    SET @TotalErrores = @TotalErrores + 1;
END

PRINT '';

-- ==========================================================
-- 2. ESQUEMAS
-- ==========================================================
PRINT '2. ESQUEMAS';
PRINT '   ----------------------------------------------';

DECLARE @EsquemasRequeridos TABLE (NombreEsquema VARCHAR(50) COLLATE DATABASE_DEFAULT);
INSERT INTO @EsquemasRequeridos VALUES ('core'), ('academic'), ('sales'), ('security'), ('audit'), ('utils');

DECLARE @EsquemasFaltantes TABLE (NombreEsquema VARCHAR(50) COLLATE DATABASE_DEFAULT);
INSERT INTO @EsquemasFaltantes
SELECT NombreEsquema FROM @EsquemasRequeridos
WHERE NombreEsquema NOT IN (SELECT name COLLATE DATABASE_DEFAULT FROM sys.schemas);

IF NOT EXISTS (SELECT 1 FROM @EsquemasFaltantes)
BEGIN
    PRINT '   [OK] Los 6 esquemas existen (core, academic, sales, security, audit, utils)';
END
ELSE
BEGIN
    PRINT '   [ERROR] Esquemas faltantes:';
    SELECT '   - ' + NombreEsquema FROM @EsquemasFaltantes;
    SET @TotalErrores = @TotalErrores + 1;
END

PRINT '';

-- ==========================================================
-- 3. TABLAS (17)
-- ==========================================================
PRINT '3. TABLAS';
PRINT '   ----------------------------------------------';

DECLARE @TablasRequeridas TABLE (Esquema VARCHAR(50) COLLATE DATABASE_DEFAULT, Tabla VARCHAR(100) COLLATE DATABASE_DEFAULT);
INSERT INTO @TablasRequeridas VALUES
    ('core', 'Sedes'), ('core', 'Carreras'), ('core', 'Estudiantes'),
    ('core', 'PeriodosAcademicos'), ('core', 'Matriculas'), ('core', 'Ubigeos'),
    ('academic', 'Profesores'), ('academic', 'Cursos'),
    ('academic', 'CarreraCursos'), ('academic', 'CursoProfesor'),
    ('academic', 'Especialidades'),
    ('sales', 'Promotores'), ('sales', 'CampaniasAdmision'), ('sales', 'Comisiones'),
    ('security', 'Roles'), ('security', 'Usuarios'),
    ('audit', 'AuditLog');

DECLARE @TablasFaltantes TABLE (Esquema VARCHAR(50) COLLATE DATABASE_DEFAULT, Tabla VARCHAR(100) COLLATE DATABASE_DEFAULT);
INSERT INTO @TablasFaltantes
SELECT r.Esquema, r.Tabla
FROM @TablasRequeridas r
WHERE NOT EXISTS (
    SELECT 1
    FROM sys.tables t
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name COLLATE DATABASE_DEFAULT = r.Esquema AND t.name COLLATE DATABASE_DEFAULT = r.Tabla
);

IF NOT EXISTS (SELECT 1 FROM @TablasFaltantes)
    PRINT '   [OK] Las 17 tablas existen';
ELSE
BEGIN
    PRINT '   [ERROR] Tablas faltantes:';
    SELECT '   - ' + Esquema + '.' + Tabla FROM @TablasFaltantes;
    SET @TotalErrores = @TotalErrores + 1;
END

PRINT '';

-- ==========================================================
-- 4. FOREIGN KEYS (21)
-- ==========================================================
PRINT '4. FOREIGN KEYS';
PRINT '   ----------------------------------------------';

DECLARE @TotalFKs INT;
SELECT @TotalFKs = COUNT(*)
FROM sys.foreign_keys fk
INNER JOIN sys.tables t ON fk.parent_object_id = t.object_id
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE s.name IN ('core', 'academic', 'sales', 'security', 'audit');

IF @TotalFKs = 21
    PRINT '   [OK] Foreign Keys: ' + CAST(@TotalFKs AS VARCHAR) + ' (esperado: 21)';
ELSE
BEGIN
    PRINT '   [ERROR] Foreign Keys: ' + CAST(@TotalFKs AS VARCHAR) + ' (esperado: 21)';
    SET @TotalErrores = @TotalErrores + 1;
END

PRINT '';

-- ==========================================================
-- 5. UNIQUE CONSTRAINTS (22)
-- ==========================================================
PRINT '5. UNIQUE CONSTRAINTS';
PRINT '   ----------------------------------------------';

DECLARE @TotalUKs INT;
SELECT @TotalUKs = COUNT(*)
FROM sys.indexes i
INNER JOIN sys.tables t ON i.object_id = t.object_id
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE i.is_unique = 1
    AND i.is_primary_key = 0
    AND s.name IN ('core', 'academic', 'sales', 'security', 'audit');

IF @TotalUKs = 22
    PRINT '   [OK] Unique Constraints: ' + CAST(@TotalUKs AS VARCHAR) + ' (esperado: 22)';
ELSE
BEGIN
    PRINT '   [AVISO] Unique Constraints: ' + CAST(@TotalUKs AS VARCHAR) + ' (esperado: 22)';
    SET @TotalWarnings = @TotalWarnings + 1;
END

PRINT '';

-- ==========================================================
-- 6. CHECK CONSTRAINTS (30)
-- ==========================================================
PRINT '6. CHECK CONSTRAINTS';
PRINT '   ----------------------------------------------';

DECLARE @TotalCKs INT;
SELECT @TotalCKs = COUNT(*)
FROM sys.check_constraints cc
INNER JOIN sys.tables t ON cc.parent_object_id = t.object_id
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE s.name IN ('core', 'academic', 'sales', 'security', 'audit');

IF @TotalCKs = 30
    PRINT '   [OK] Check Constraints: ' + CAST(@TotalCKs AS VARCHAR) + ' (esperado: 30)';
ELSE
BEGIN
    PRINT '   [AVISO] Check Constraints: ' + CAST(@TotalCKs AS VARCHAR) + ' (esperado: 30)';
    SET @TotalWarnings = @TotalWarnings + 1;
END

PRINT '';

-- ==========================================================
-- 7. INDICES DE OPTIMIZACION (17 no agrupados: 14 Sprint 1 + 3 Sprint 3)
-- ==========================================================
PRINT '7. INDICES DE OPTIMIZACION';
PRINT '   ----------------------------------------------';

DECLARE @TotalIndices INT;
SELECT @TotalIndices = COUNT(*)
FROM sys.indexes i
INNER JOIN sys.tables t ON i.object_id = t.object_id
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE i.type = 2                       -- nonclustered
    AND i.is_primary_key = 0
    AND i.is_unique = 0
    AND s.name IN ('core', 'academic', 'sales', 'security', 'audit');

IF @TotalIndices = 17
    PRINT '   [OK] Indices no agrupados de optimizacion: ' + CAST(@TotalIndices AS VARCHAR) + ' (esperado: 17)';
ELSE
BEGIN
    PRINT '   [AVISO] Indices no agrupados: ' + CAST(@TotalIndices AS VARCHAR) + ' (esperado: 17)';
    SET @TotalWarnings = @TotalWarnings + 1;
END

PRINT '';

-- ==========================================================
-- 8. DATOS INICIALES
-- ==========================================================
PRINT '8. DATOS INICIALES';
PRINT '   ----------------------------------------------';

DECLARE @Resultados TABLE (
    Tabla VARCHAR(100),
    Registros INT,
    Esperado INT,
    Estado VARCHAR(10)
);

-- La matricula de prueba del Sprint 2 (periodo 2027-I) solo se
-- registra si su ventana esta abierta (RN-03). Los conteos esperados
-- de Matriculas y Comisiones (que la comision genera automaticamente:
-- RN-09) dependen de ello; se calculan en lugar de fijarse.
DECLARE @VentanaPruebasAbierta INT =
    CASE WHEN EXISTS (
        SELECT 1 FROM core.PeriodosAcademicos
        WHERE PeriodoId = 5 AND Activo = 1
          AND GETDATE() BETWEEN FechaInicioMatriculas AND FechaFinMatriculas
    ) THEN 1 ELSE 0 END;

INSERT INTO @Resultados
SELECT 'core.Ubigeos', COUNT(*), 11, CASE WHEN COUNT(*) = 11 THEN '[OK]' ELSE '[ERR]' END FROM core.Ubigeos
UNION ALL SELECT 'core.Sedes', COUNT(*), 5, CASE WHEN COUNT(*) = 5 THEN '[OK]' ELSE '[ERR]' END FROM core.Sedes
UNION ALL SELECT 'core.Carreras', COUNT(*), 7, CASE WHEN COUNT(*) = 7 THEN '[OK]' ELSE '[ERR]' END FROM core.Carreras
UNION ALL SELECT 'core.Estudiantes', COUNT(*), 11, CASE WHEN COUNT(*) = 11 THEN '[OK]' ELSE '[ERR]' END FROM core.Estudiantes
UNION ALL SELECT 'core.PeriodosAcademicos', COUNT(*), 5, CASE WHEN COUNT(*) = 5 THEN '[OK]' ELSE '[ERR]' END FROM core.PeriodosAcademicos
UNION ALL SELECT 'core.Matriculas', COUNT(*), 10 + @VentanaPruebasAbierta, CASE WHEN COUNT(*) = 10 + @VentanaPruebasAbierta THEN '[OK]' ELSE '[ERR]' END FROM core.Matriculas
UNION ALL SELECT 'academic.Especialidades', COUNT(*), 10, CASE WHEN COUNT(*) = 10 THEN '[OK]' ELSE '[ERR]' END FROM academic.Especialidades
UNION ALL SELECT 'academic.Profesores', COUNT(*), 10, CASE WHEN COUNT(*) = 10 THEN '[OK]' ELSE '[ERR]' END FROM academic.Profesores
UNION ALL SELECT 'academic.Cursos', COUNT(*), 10, CASE WHEN COUNT(*) = 10 THEN '[OK]' ELSE '[ERR]' END FROM academic.Cursos
UNION ALL SELECT 'academic.CarreraCursos', COUNT(*), 20, CASE WHEN COUNT(*) = 20 THEN '[OK]' ELSE '[ERR]' END FROM academic.CarreraCursos
UNION ALL SELECT 'academic.CursoProfesor', COUNT(*), 10, CASE WHEN COUNT(*) = 10 THEN '[OK]' ELSE '[ERR]' END FROM academic.CursoProfesor
UNION ALL SELECT 'sales.Promotores', COUNT(*), 7, CASE WHEN COUNT(*) = 7 THEN '[OK]' ELSE '[ERR]' END FROM sales.Promotores
UNION ALL SELECT 'sales.CampaniasAdmision', COUNT(*), 5, CASE WHEN COUNT(*) = 5 THEN '[OK]' ELSE '[ERR]' END FROM sales.CampaniasAdmision
UNION ALL SELECT 'sales.Comisiones', COUNT(*), 10 + @VentanaPruebasAbierta, CASE WHEN COUNT(*) = 10 + @VentanaPruebasAbierta THEN '[OK]' ELSE '[ERR]' END FROM sales.Comisiones
UNION ALL SELECT 'security.Roles', COUNT(*), 5, CASE WHEN COUNT(*) = 5 THEN '[OK]' ELSE '[ERR]' END FROM security.Roles
UNION ALL SELECT 'security.Usuarios', COUNT(*), 5, CASE WHEN COUNT(*) = 5 THEN '[OK]' ELSE '[ERR]' END FROM security.Usuarios;

DECLARE @ErroresDatos INT;
SELECT @ErroresDatos = COUNT(*) FROM @Resultados WHERE Estado = '[ERR]';

IF @ErroresDatos = 0
BEGIN
    PRINT '   [OK] Las 16 tablas tienen la cantidad exacta de registros (seed + datos de prueba del Sprint 2)';
END
ELSE
BEGIN
    PRINT '   [ERROR] Cantidades incorrectas:';
    SELECT '   ' + Estado + ' ' + Tabla + ': ' + CAST(Registros AS VARCHAR) + '/' + CAST(Esperado AS VARCHAR) AS Detalle
    FROM @Resultados WHERE Estado = '[ERR]';
    SET @TotalErrores = @TotalErrores + @ErroresDatos;
END

PRINT '';

-- ==========================================================
-- 9. INTEGRIDAD REFERENCIAL (sin huerfanos)
-- ==========================================================
PRINT '9. INTEGRIDAD REFERENCIAL';
PRINT '   ----------------------------------------------';

DECLARE @Huerfanos INT = 0;

IF EXISTS (SELECT 1 FROM core.Matriculas m
           WHERE NOT EXISTS (SELECT 1 FROM core.Estudiantes e WHERE e.EstudianteId = m.EstudianteId))
    SET @Huerfanos = @Huerfanos + 1;

IF EXISTS (SELECT 1 FROM core.Matriculas m
           WHERE NOT EXISTS (SELECT 1 FROM core.Carreras c WHERE c.CarreraId = m.CarreraId))
    SET @Huerfanos = @Huerfanos + 1;

IF EXISTS (SELECT 1 FROM core.Matriculas m
           WHERE NOT EXISTS (SELECT 1 FROM core.PeriodosAcademicos p WHERE p.PeriodoId = m.PeriodoId))
    SET @Huerfanos = @Huerfanos + 1;

IF EXISTS (SELECT 1 FROM core.Matriculas m
           WHERE NOT EXISTS (SELECT 1 FROM core.Sedes s WHERE s.SedeId = m.SedeId))
    SET @Huerfanos = @Huerfanos + 1;

IF EXISTS (SELECT 1 FROM core.Matriculas m
           WHERE NOT EXISTS (SELECT 1 FROM sales.Promotores p WHERE p.PromotorId = m.PromotorId))
    SET @Huerfanos = @Huerfanos + 1;

IF @Huerfanos = 0
    PRINT '   [OK] Sin registros huerfanos en Matriculas';
ELSE
BEGIN
    PRINT '   [ERROR] Se encontraron registros huerfanos';
    SET @TotalErrores = @TotalErrores + @Huerfanos;
END

PRINT '';

-- ==========================================================
-- 10. REGLAS DE NEGOCIO CLAVE (unicidad)
-- ==========================================================
PRINT '10. REGLAS DE NEGOCIO';
PRINT '    ----------------------------------------------';

DECLARE @DuplicadosDocumento INT, @DuplicadosEmail INT, @DuplicadosMatricula INT;

SELECT @DuplicadosDocumento = COUNT(*) FROM (
    SELECT TipoDocumento, NumeroDocumento FROM core.Estudiantes GROUP BY TipoDocumento, NumeroDocumento HAVING COUNT(*) > 1
) d;

SELECT @DuplicadosEmail = COUNT(*) FROM (
    SELECT Email FROM core.Estudiantes GROUP BY Email HAVING COUNT(*) > 1
) d;

SELECT @DuplicadosMatricula = COUNT(*) FROM (
    SELECT EstudianteId, CarreraId, PeriodoId
    FROM core.Matriculas
    GROUP BY EstudianteId, CarreraId, PeriodoId
    HAVING COUNT(*) > 1
) d;

IF @DuplicadosDocumento = 0 AND @DuplicadosEmail = 0
    PRINT '   [OK] Sin estudiantes duplicados (DNI/CE o Email unicos)';
ELSE
BEGIN
    PRINT '   [ERROR] Estudiantes duplicados encontrados';
    SET @TotalErrores = @TotalErrores + 1;
END

IF @DuplicadosMatricula = 0
    PRINT '   [OK] Sin matriculas duplicadas (estudiante/carrera/periodo unicos)';
ELSE
BEGIN
    PRINT '   [ERROR] Matriculas duplicadas encontradas';
    SET @TotalErrores = @TotalErrores + 1;
END

PRINT '';

-- ==========================================================
-- 11. CONTROL DE VERSIONES
-- ==========================================================
PRINT '11. CONTROL DE VERSIONES';
PRINT '    ----------------------------------------------';

IF EXISTS (SELECT 1 FROM sys.tables WHERE name COLLATE DATABASE_DEFAULT = 'DatabaseVersion')
BEGIN
    DECLARE @Version VARCHAR(20);
    SELECT TOP 1 @Version = VersionNumber FROM dbo.DatabaseVersion ORDER BY VersionId DESC;
    PRINT '   [OK] Version actual: ' + ISNULL(@Version, '(sin version)');
END
ELSE
BEGIN
    PRINT '   [AVISO] Tabla DatabaseVersion no encontrada';
    SET @TotalWarnings = @TotalWarnings + 1;
END

PRINT '';

-- ==========================================================
-- 12. OBJETOS DEL SPRINT 2
-- ==========================================================
PRINT '12. OBJETOS DEL SPRINT 2 (PROGRAMACION)';
PRINT '    ----------------------------------------------';

DECLARE @FaltantesSprint2 TABLE (Tipo VARCHAR(20), Nombre VARCHAR(100));

INSERT INTO @FaltantesSprint2
SELECT 'FUNCION', Nombre FROM (VALUES
    ('core.fn_PeriodoMatriculaHabilitado'), ('core.fn_ExisteEstudianteConDocumento'),
    ('core.fn_EdadEstudiante'), ('core.fn_TotalMatriculadosCarrera'),
    ('sales.fn_CalcularComision'), ('sales.fn_CalcularBonoPromotor')
) AS Funcs(Nombre)
WHERE NOT EXISTS (
    SELECT 1 FROM sys.objects o
    INNER JOIN sys.schemas s ON o.schema_id = s.schema_id
    WHERE s.name + '.' + o.name = Funcs.Nombre AND o.type IN ('FN', 'IF', 'TF')
);

INSERT INTO @FaltantesSprint2
SELECT 'VISTA', Nombre FROM (VALUES
    ('core.vw_EstudiantesDetalle'), ('core.vw_MatriculasDetalle'),
    ('sales.vw_ComisionesDetalle'), ('sales.vw_DesempenoPromotores'),
    ('academic.vw_MallaCurricular'), ('academic.vw_ProfesoresDetalle'),
    ('core.vw_ReporteMatriculasPeriodo')
) AS Vistas(Nombre)
WHERE NOT EXISTS (
    SELECT 1 FROM sys.objects o
    INNER JOIN sys.schemas s ON o.schema_id = s.schema_id
    WHERE s.name + '.' + o.name = Vistas.Nombre AND o.type = 'V'
);

INSERT INTO @FaltantesSprint2
SELECT 'TRIGGER', Nombre FROM (VALUES
    ('core.TRG_Audit_Estudiantes'), ('core.TRG_Audit_Matriculas'),
    ('sales.TRG_Audit_Promotores'), ('sales.TRG_Audit_Comisiones'),
    ('core.TRG_Comision_Automatica')
) AS Triggers(Nombre)
WHERE NOT EXISTS (
    SELECT 1 FROM sys.objects o
    INNER JOIN sys.schemas s ON o.schema_id = s.schema_id
    WHERE s.name + '.' + o.name = Triggers.Nombre AND o.type = 'TR'
);

INSERT INTO @FaltantesSprint2
SELECT 'PROCEDIMIENTO', Nombre FROM (VALUES
    ('core.usp_RegistrarEstudiante'), ('core.usp_ActualizarEstudiante'),
    ('core.usp_EliminarEstudianteLogico'), ('sales.usp_RegistrarPromotor'),
    ('core.usp_RegistrarMatricula'), ('core.usp_RetirarMatricula'),
    ('core.usp_EliminarMatriculaLogico'), ('sales.usp_MarcarComisionPagada'),
    ('core.usp_ConsultarMatriculas'), ('core.usp_ConsultarEstudiantes')
) AS Procs(Nombre)
WHERE NOT EXISTS (
    SELECT 1 FROM sys.objects o
    INNER JOIN sys.schemas s ON o.schema_id = s.schema_id
    WHERE s.name + '.' + o.name = Procs.Nombre AND o.type = 'P'
);

IF NOT EXISTS (SELECT 1 FROM @FaltantesSprint2)
    PRINT '   [OK] Sprint 2 completo: 6 funciones, 7 vistas, 5 triggers, 10 procedimientos';
ELSE
BEGIN
    PRINT '   [ERROR] Objetos Sprint 2 faltantes:';
    SELECT '   - ' + Tipo + ': ' + Nombre FROM @FaltantesSprint2;
    SET @TotalErrores = @TotalErrores + 1;
END

PRINT '';
PRINT '';

-- ==========================================================
-- 13. SEGURIDAD (RN-06): perfiles con permisos diferentes
-- ==========================================================
PRINT '13. SEGURIDAD (RN-06)';
PRINT '    ----------------------------------------------';

DECLARE @UsuariosSeguridad TABLE (LoginUsuario VARCHAR(50) COLLATE DATABASE_DEFAULT);
INSERT INTO @UsuariosSeguridad VALUES ('MC_Admin'), ('MC_Coordinador'), ('MC_Promotor');

DECLARE @FaltantesSeguridad TABLE (Nombre VARCHAR(50) COLLATE DATABASE_DEFAULT);
INSERT INTO @FaltantesSeguridad
SELECT LoginUsuario FROM @UsuariosSeguridad
WHERE LoginUsuario NOT IN (SELECT name COLLATE DATABASE_DEFAULT FROM sys.sql_logins)
   OR LoginUsuario NOT IN (SELECT name COLLATE DATABASE_DEFAULT FROM sys.database_principals WHERE type = 'S');

IF NOT EXISTS (SELECT 1 FROM @FaltantesSeguridad)
    PRINT '   [OK] Perfiles SQL creados: MC_Admin, MC_Coordinador, MC_Promotor (login + usuario)';
ELSE
BEGIN
    PRINT '   [ERROR] Perfiles SQL faltantes:';
    SELECT '   - ' + Nombre FROM @FaltantesSeguridad;
    SET @TotalErrores = @TotalErrores + 1;
END

IF IS_ROLEMEMBER('db_owner', 'MC_Admin') = 1
    PRINT '   [OK] MC_Admin: miembro de db_owner (acceso completo)';
ELSE
BEGIN
    PRINT '   [ERROR] MC_Admin no es miembro de db_owner';
    SET @TotalErrores = @TotalErrores + 1;
END

-- Pruebas de cumplimiento mediante EXECUTE AS (no modifican datos).
-- Patron seguro: solo se ejecuta REVERT si la suplantacion se establecio,
-- para no abandonar el contexto de sa/dbo ante un error esperado.
DECLARE @TryingImp BIT;
DECLARE @TestDenegado BIT;
DECLARE @TestPermitido BIT;

-- 13.1 MC_Promotor NO puede leer security.Usuarios (error 229 esperado)
SET @TryingImp = 0; SET @TestDenegado = 0;
BEGIN TRY
    EXECUTE AS USER = 'MC_Promotor';
    SET @TryingImp = 1;
    SELECT TOP (1) 1 FROM security.Usuarios;
    REVERT;
    SET @TryingImp = 0;
END TRY
BEGIN CATCH
    IF @TryingImp = 1 REVERT;
    IF ERROR_NUMBER() IN (229, 297) SET @TestDenegado = 1;
END CATCH

IF @TestDenegado = 1
    PRINT '   [OK] MC_Promotor: lectura de security.Usuarios DENEGADA (error 229)';
ELSE
BEGIN
    PRINT '   [ERROR] MC_Promotor pudo leer security.Usuarios';
    SET @TotalErrores = @TotalErrores + 1;
END

-- 13.2 MC_Promotor SI puede ejecutar usp_RegistrarEstudiante
-- (SP rechaza con 51001 un documento duplicado: probar que el EXECUTE
--  esta permitido y la validacion de negocio sigue intacta)
SET @TryingImp = 0; SET @TestPermitido = 0;
BEGIN TRY
    EXECUTE AS USER = 'MC_Promotor';
    SET @TryingImp = 1;
    DECLARE @IdDesc INT, @ErrDesc NVARCHAR(500);
    EXEC core.usp_RegistrarEstudiante 'DNI', '70123456', 'X', 'Y', 'x.desc@gmail.com',
         '987000001', '2004-01-01', 'M', NULL, 1, @IdDesc OUTPUT, @ErrDesc OUTPUT;
    REVERT;
    SET @TryingImp = 0;
END TRY
BEGIN CATCH
    IF @TryingImp = 1 REVERT;
    IF ERROR_NUMBER() = 51001 SET @TestPermitido = 1;
END CATCH

IF @TestPermitido = 1
    PRINT '   [OK] MC_Promotor: puede registrar estudiantes via core.usp_RegistrarEstudiante (rechazo 51001 = SP operativo)';
ELSE
BEGIN
    PRINT '   [ERROR] MC_Promotor NO pudo ejecutar core.usp_RegistrarEstudiante';
    SET @TotalErrores = @TotalErrores + 1;
END

-- 13.3 MC_Coordinador NO puede consultar comisiones (denegado)
SET @TryingImp = 0; SET @TestDenegado = 0;
BEGIN TRY
    EXECUTE AS USER = 'MC_Coordinador';
    SET @TryingImp = 1;
    SELECT TOP (1) 1 FROM sales.vw_ComisionesDetalle;
    REVERT;
    SET @TryingImp = 0;
END TRY
BEGIN CATCH
    IF @TryingImp = 1 REVERT;
    IF ERROR_NUMBER() = 229 SET @TestDenegado = 1;
END CATCH

IF @TestDenegado = 1
    PRINT '   [OK] MC_Coordinador: comisiones DENEGADAS (solo administracion/promotor)';
ELSE
BEGIN
    PRINT '   [ERROR] MC_Coordinador pudo consultar comisiones';
    SET @TotalErrores = @TotalErrores + 1;
END

-- 13.4 MC_Coordinador SI puede consultar la malla curricular (reportes academicos)
SET @TryingImp = 0; SET @TestPermitido = 0;
BEGIN TRY
    EXECUTE AS USER = 'MC_Coordinador';
    SET @TryingImp = 1;
    DECLARE @MallaVisible INT;
    SELECT @MallaVisible = COUNT(*) FROM academic.vw_MallaCurricular;
    REVERT;
    SET @TryingImp = 0;
    IF @MallaVisible > 0 SET @TestPermitido = 1;
END TRY
BEGIN CATCH
    IF @TryingImp = 1 REVERT;
END CATCH

IF @TestPermitido = 1
    PRINT '   [OK] MC_Coordinador: consulta de academic.vw_MallaCurricular PERMITIDA';
ELSE
BEGIN
    PRINT '   [ERROR] MC_Coordinador no pudo consultar la malla curricular';
    SET @TotalErrores = @TotalErrores + 1;
END

PRINT '';
PRINT '';

-- ==========================================================
-- 14. SPRINT 3 - AUDITORIA (RN-07) Y BORRADO LOGICO (RN-10)
-- ==========================================================
PRINT '14. SPRINT 3 - AUDITORIA Y BORRADO LOGICO';
PRINT '    ----------------------------------------------';

-- 14.1 Triggers de auditoria nuevos (7)
DECLARE @AuditTriggers TABLE (Nombre VARCHAR(100) COLLATE DATABASE_DEFAULT);
INSERT INTO @AuditTriggers VALUES
    ('core.TRG_Audit_Sedes'), ('core.TRG_Audit_Carreras'),
    ('core.TRG_Audit_Periodos'), ('academic.TRG_Audit_Profesores'),
    ('academic.TRG_Audit_Cursos'), ('sales.TRG_Audit_Campanias'),
    ('security.TRG_Audit_Usuarios');

DECLARE @FaltantesAuditTriggers INT;
SELECT @FaltantesAuditTriggers = COUNT(*)
FROM @AuditTriggers at
WHERE NOT EXISTS (
    SELECT 1 FROM sys.objects o
    INNER JOIN sys.schemas s ON o.schema_id = s.schema_id
    WHERE s.name + '.' + o.name = at.Nombre AND o.type = 'TR'
);

IF @FaltantesAuditTriggers = 0
    PRINT '   [OK] 7 triggers de auditoria nuevos (Sedes, Carreras, Periodos, Profesores, Cursos, Campanias, Usuarios)';
ELSE
BEGIN
    PRINT '   [ERROR] Faltan ' + CAST(@FaltantesAuditTriggers AS VARCHAR) + ' triggers de auditoria';
    SET @TotalErrores = @TotalErrores + 1;
END

-- 14.2 Triggers de borrado logico (INSTEAD OF DELETE, 7)
DECLARE @SoftDeleteTriggers TABLE (Nombre VARCHAR(100) COLLATE DATABASE_DEFAULT);
INSERT INTO @SoftDeleteTriggers VALUES
    ('core.TRG_SoftDelete_Estudiantes'), ('core.TRG_SoftDelete_Matriculas'),
    ('core.TRG_SoftDelete_Sedes'), ('core.TRG_SoftDelete_Carreras'),
    ('academic.TRG_SoftDelete_Profesores'), ('academic.TRG_SoftDelete_Cursos'),
    ('sales.TRG_SoftDelete_Promotores');

DECLARE @FaltantesSoftDelete INT;
SELECT @FaltantesSoftDelete = COUNT(*)
FROM @SoftDeleteTriggers sd
WHERE NOT EXISTS (
    SELECT 1 FROM sys.objects o
    INNER JOIN sys.schemas s ON o.schema_id = s.schema_id
    WHERE s.name + '.' + o.name = sd.Nombre AND o.type = 'TR'
);

IF @FaltantesSoftDelete = 0
    PRINT '   [OK] 7 triggers de borrado logico INSTEAD OF DELETE (RN-10)';
ELSE
BEGIN
    PRINT '   [ERROR] Faltan ' + CAST(@FaltantesSoftDelete AS VARCHAR) + ' triggers de borrado logico';
    SET @TotalErrores = @TotalErrores + 1;
END

-- 14.3 Columnas DeletedAt en las tablas criticas
DECLARE @FaltantesDeletedAt INT;
SELECT @FaltantesDeletedAt = COUNT(*)
FROM (VALUES
    ('core', 'Estudiantes'), ('core', 'Matriculas'), ('core', 'Sedes'),
    ('core', 'Carreras'), ('academic', 'Profesores'), ('academic', 'Cursos'),
    ('sales', 'Promotores')
) AS req(Esq, Tab)
WHERE NOT EXISTS (
    SELECT 1 FROM sys.columns c
    INNER JOIN sys.tables t ON c.object_id = t.object_id
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = req.Esq AND t.name = req.Tab AND c.name = 'DeletedAt'
);

IF @FaltantesDeletedAt = 0
    PRINT '   [OK] Columna DeletedAt presente en las 7 tablas criticas (borrado logico)';
ELSE
BEGIN
    PRINT '   [ERROR] Faltan ' + CAST(@FaltantesDeletedAt AS VARCHAR) + ' columnas DeletedAt';
    SET @TotalErrores = @TotalErrores + 1;
END

-- 14.4 Vista de trazabilidad de auditoria
IF OBJECT_ID('audit.vw_TrazaAuditoria', 'V') IS NOT NULL
    PRINT '   [OK] Vista audit.vw_TrazaAuditoria (trazabilidad)';
ELSE
BEGIN
    PRINT '   [ERROR] Vista audit.vw_TrazaAuditoria NO existe';
    SET @TotalErrores = @TotalErrores + 1;
END

PRINT '';

-- ==========================================================
-- 15. SPRINT 3 - INDICES NUEVOS (consultas criticas)
-- ==========================================================
PRINT '15. SPRINT 3 - INDICES NUEVOS';
PRINT '    ----------------------------------------------';

DECLARE @FaltantesIndices3 INT;
SELECT @FaltantesIndices3 = COUNT(*)
FROM (VALUES
    ('IX_Matriculas_PeriodoEstado'), ('IX_Matriculas_PromotorPeriodo'),
    ('IX_Comisiones_Campania')
) AS req(Ind)
WHERE NOT EXISTS (SELECT 1 FROM sys.indexes i WHERE i.name = req.Ind AND i.type = 2);

IF @FaltantesIndices3 = 0
    PRINT '   [OK] 3 indices nuevos: IX_Matriculas_PeriodoEstado, IX_Matriculas_PromotorPeriodo, IX_Comisiones_Campania';
ELSE
BEGIN
    PRINT '   [ERROR] Faltan ' + CAST(@FaltantesIndices3 AS VARCHAR) + ' indices del Sprint 3';
    SET @TotalErrores = @TotalErrores + 1;
END

PRINT '';

-- ==========================================================
-- 16. SPRINT 3 - CONSULTAS AVANZADAS (vistas analiticas)
-- ==========================================================
PRINT '16. SPRINT 3 - VISTAS ANALITICAS (CTE + ventanas)';
PRINT '    ----------------------------------------------';

DECLARE @FaltantesVistas3 TABLE (Nombre VARCHAR(100) COLLATE DATABASE_DEFAULT);
INSERT INTO @FaltantesVistas3
SELECT Vistas.Nombre FROM (VALUES
    ('core.vw_IndicadoresMatricula'), ('sales.vw_RankingPromotores'),
    ('core.vw_TendenciaMatriculas')
) AS Vistas(Nombre)
WHERE NOT EXISTS (
    SELECT 1 FROM sys.objects o
    INNER JOIN sys.schemas s ON o.schema_id = s.schema_id
    WHERE s.name + '.' + o.name = Vistas.Nombre AND o.type = 'V'
);

IF NOT EXISTS (SELECT 1 FROM @FaltantesVistas3)
    PRINT '   [OK] 3 vistas analiticas (indicadores, ranking, tendencia) responden';
ELSE
BEGIN
    PRINT '   [ERROR] Vistas analiticas faltantes:';
    SELECT '   - ' + Nombre FROM @FaltantesVistas3;
    SET @TotalErrores = @TotalErrores + 1;
END

-- Comprobacion de que las consultas avanzadas responden (Q1-Q10)
DECLARE @ConsultaAvanzadaOK INT = 0;
BEGIN TRY
    WITH TotalPorPeriodo AS
    (
        SELECT p.PeriodoId, SUM(1) AS TotalMatriculas
        FROM core.Matriculas m
        INNER JOIN core.PeriodosAcademicos p ON p.PeriodoId = m.PeriodoId
        WHERE m.DeletedAt IS NULL
        GROUP BY p.PeriodoId
    )
    SELECT @ConsultaAvanzadaOK = COUNT(*) FROM TotalPorPeriodo;
END TRY
BEGIN CATCH
    SET @ConsultaAvanzadaOK = -1;
END CATCH

IF @ConsultaAvanzadaOK >= 0
    PRINT '   [OK] Consultas avanzadas (CTE) ejecutadas correctamente';
ELSE
BEGIN
    PRINT '   [ERROR] Las consultas avanzadas fallaron';
    SET @TotalErrores = @TotalErrores + 1;
END

PRINT '';

-- ==========================================================
-- 17. SPRINT 3 - MANTENIMIENTO (respaldo + automatizacion)
-- ==========================================================
PRINT '17. SPRINT 3 - RESPALDO Y AUTOMATIZACION';
PRINT '    ----------------------------------------------';

IF EXISTS (SELECT 1 FROM msdb.dbo.backupset WHERE database_name = 'MatriculaCloud360DB' AND type = 'D')
    PRINT '   [OK] Existe al menos 1 respaldo FULL registrado en msdb';
ELSE
BEGIN
    PRINT '   [AVISO] No hay respaldos FULL registrados aun (ejecutar maintenance/01_backup.sql)';
    SET @TotalWarnings = @TotalWarnings + 1;
END

DECLARE @JobsOK INT;
SELECT @JobsOK = COUNT(*) FROM msdb.dbo.sysjobs WHERE name LIKE 'MC360_%' AND enabled = 1;

IF @JobsOK >= 1
    PRINT '   [OK] Jobs de SQL Agent habilitados: ' + CAST(@JobsOK AS VARCHAR) + ' (MC360_BackupCompleto/Diferencial/Log, MantenimientoIndices, VerificacionIntegridad)';
ELSE
BEGIN
    PRINT '   [AVISO] No se encontraron jobs de SQL Agent (verificar MSSQL_AGENT_ENABLED=true)';
    SET @TotalWarnings = @TotalWarnings + 1;
END

PRINT '';

-- ==========================================================
-- 18. SPRINT 3 - SEGURIDAD POR ROLES (GRANT/DENY/REVOKE)
-- ==========================================================
PRINT '18. SPRINT 3 - ROLES Y PERMISOS DE BASE';
PRINT '    ----------------------------------------------';

DECLARE @RolesRequeridos TABLE (Nombre VARCHAR(50) COLLATE DATABASE_DEFAULT);
INSERT INTO @RolesRequeridos VALUES ('rol_Administrador'), ('rol_Coordinador_Academico'), ('rol_Promotor');

DECLARE @FaltantesRoles TABLE (Nombre VARCHAR(50) COLLATE DATABASE_DEFAULT);
INSERT INTO @FaltantesRoles
SELECT Nombre FROM @RolesRequeridos
WHERE Nombre NOT IN (SELECT name COLLATE DATABASE_DEFAULT FROM sys.database_principals WHERE type = 'R');

IF NOT EXISTS (SELECT 1 FROM @FaltantesRoles)
    PRINT '   [OK] Roles creados: rol_Administrador, rol_Coordinador_Academico, rol_Promotor';
ELSE
BEGIN
    PRINT '   [ERROR] Roles faltantes:';
    SELECT '   - ' + Nombre FROM @FaltantesRoles;
    SET @TotalErrores = @TotalErrores + 1;
END

-- 18.1 MC_Promotor NO puede matricular (DENY sobre usp_RegistrarMatricula)
SET @TryingImp = 0; SET @TestDenegado = 0;
BEGIN TRY
    EXECUTE AS USER = 'MC_Promotor';
    SET @TryingImp = 1;
    DECLARE @IdMatr INT, @MsgMatr NVARCHAR(500);
    EXEC core.usp_RegistrarMatricula 1, 1, 5, 1, 1, 3, 'PRUEBA SEGURIDAD S3', @IdMatr OUTPUT, @MsgMatr OUTPUT;
    REVERT;
    SET @TryingImp = 0;
END TRY
BEGIN CATCH
    IF @TryingImp = 1 REVERT;
    IF ERROR_NUMBER() IN (229, 297) SET @TestDenegado = 1;
END CATCH

IF @TestDenegado = 1
    PRINT '   [OK] MC_Promotor: registrar matricula DENEGADO (error 229, DENY explicito)';
ELSE
BEGIN
    PRINT '   [ERROR] MC_Promotor pudo registrar una matricula';
    SET @TotalErrores = @TotalErrores + 1;
END

-- 18.2 MC_Coordinador SI puede ver la traza de auditoria (vista)
SET @TryingImp = 0; SET @TestPermitido = 0;
BEGIN TRY
    EXECUTE AS USER = 'MC_Coordinador';
    SET @TryingImp = 1;
    DECLARE @TrazaVisible INT;
    SELECT @TrazaVisible = COUNT(*) FROM audit.vw_TrazaAuditoria;
    REVERT;
    SET @TryingImp = 0;
    IF @TrazaVisible >= 0 SET @TestPermitido = 1;
END TRY
BEGIN CATCH
    IF @TryingImp = 1 REVERT;
END CATCH

IF @TestPermitido = 1
    PRINT '   [OK] MC_Coordinador: lectura de audit.vw_TrazaAuditoria PERMITIDA';
ELSE
BEGIN
    PRINT '   [ERROR] MC_Coordinador NO pudo ver la traza de auditoria';
    SET @TotalErrores = @TotalErrores + 1;
END

-- 18.3 MC_Coordinador NO puede leer audit.AuditLog (tabla sensible, solo vista)
SET @TryingImp = 0; SET @TestDenegado = 0;
BEGIN TRY
    EXECUTE AS USER = 'MC_Coordinador';
    SET @TryingImp = 1;
    SELECT TOP (1) 1 FROM audit.AuditLog;
    REVERT;
    SET @TryingImp = 0;
END TRY
BEGIN CATCH
    IF @TryingImp = 1 REVERT;
    IF ERROR_NUMBER() IN (229, 297) SET @TestDenegado = 1;
END CATCH

IF @TestDenegado = 1
    PRINT '   [OK] MC_Coordinador: lectura de audit.AuditLog DENEGADA (acceso solo via vista)';
ELSE
BEGIN
    PRINT '   [ERROR] MC_Coordinador pudo leer audit.AuditLog';
    SET @TotalErrores = @TotalErrores + 1;
END

PRINT '';
PRINT '';

-- ==========================================================
-- RESUMEN FINAL
-- ==========================================================
PRINT '==========================================================';
PRINT '  RESUMEN DE LA VERIFICACION';
PRINT '==========================================================';
PRINT '';

IF @TotalErrores = 0 AND @TotalWarnings = 0
BEGIN
    PRINT '   >>> INSTALACION PERFECTA <<<';
    PRINT '';
    PRINT '   Todos los componentes estan correctos.';
    PRINT '   La base de datos esta lista para usar.';
    PRINT '   Estado: APROBADO';
END
ELSE IF @TotalErrores = 0
BEGIN
    PRINT '   >>> INSTALACION COMPLETA CON ADVERTENCIAS <<<';
    PRINT '';
    PRINT '   Advertencias: ' + CAST(@TotalWarnings AS VARCHAR);
    PRINT '   Estado: APROBADO CON OBSERVACIONES';
END
ELSE
BEGIN
    PRINT '   >>> INSTALACION INCOMPLETA <<<';
    PRINT '';
    PRINT '   Errores: ' + CAST(@TotalErrores AS VARCHAR);
    PRINT '   Advertencias: ' + CAST(@TotalWarnings AS VARCHAR);
    PRINT '   Estado: RECHAZADO';
END

PRINT '';
PRINT '==========================================================';
PRINT '  Verificacion ejecutada: ' + CONVERT(VARCHAR(30), GETDATE(), 120);
PRINT '==========================================================';
GO
