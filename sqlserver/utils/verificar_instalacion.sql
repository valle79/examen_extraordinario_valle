-- =============================================
-- Matricula Cloud 360 Enterprise
-- utils/verificar_instalacion.sql
-- =============================================
-- Descripcion: Verifica que la instalacion este completa y correcta:
--   - Base de datos creada
--   - Esquemas presentes
--   - 15 tablas creadas
--   - 18 Foreign Keys, 20 Unique, 26 Check
--   - 14 indices no agrupados de optimizacion
--   - Datos iniciales cargados (112 registros)
--   - Integridad referencial sin huerfanos
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

IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'MatriculaCloud360DB')
BEGIN
    PRINT '   [OK] Base de datos MatriculaCloud360DB existe';

    DECLARE @Collation NVARCHAR(128);
    SELECT @Collation = collation_name
    FROM sys.databases
    WHERE name = 'MatriculaCloud360DB';

    IF @Collation LIKE '%Modern_Spanish%' OR @Collation LIKE '%Spanish%'
        PRINT '   [OK] Collation: ' + @Collation;
    ELSE
    BEGIN
        PRINT '   [AVISO] Collation: ' + @Collation + ' (se esperaba Modern_Spanish_CI_AS)';
        SET @TotalWarnings = @TotalWarnings + 1;
    END

    DECLARE @RecoveryModel NVARCHAR(60);
    SELECT @RecoveryModel = recovery_model_desc
    FROM sys.databases
    WHERE name = 'MatriculaCloud360DB';

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

DECLARE @EsquemasRequeridos TABLE (NombreEsquema VARCHAR(50));
INSERT INTO @EsquemasRequeridos VALUES ('core'), ('academic'), ('sales'), ('security'), ('audit'), ('utils');

DECLARE @EsquemasFaltantes TABLE (NombreEsquema VARCHAR(50));
INSERT INTO @EsquemasFaltantes
SELECT NombreEsquema FROM @EsquemasRequeridos
WHERE NombreEsquema NOT IN (SELECT name FROM sys.schemas);

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
-- 3. TABLAS (15)
-- ==========================================================
PRINT '3. TABLAS';
PRINT '   ----------------------------------------------';

DECLARE @TablasRequeridas TABLE (Esquema VARCHAR(50), Tabla VARCHAR(100));
INSERT INTO @TablasRequeridas VALUES
    ('core', 'Sedes'), ('core', 'Carreras'), ('core', 'Estudiantes'),
    ('core', 'PeriodosAcademicos'), ('core', 'Matriculas'),
    ('academic', 'Profesores'), ('academic', 'Cursos'),
    ('academic', 'CarreraCursos'), ('academic', 'CursoProfesor'),
    ('sales', 'Promotores'), ('sales', 'CampaniasAdmision'), ('sales', 'Comisiones'),
    ('security', 'Roles'), ('security', 'Usuarios'),
    ('audit', 'AuditLog');

DECLARE @TablasFaltantes TABLE (Esquema VARCHAR(50), Tabla VARCHAR(100));
INSERT INTO @TablasFaltantes
SELECT r.Esquema, r.Tabla
FROM @TablasRequeridas r
WHERE NOT EXISTS (
    SELECT 1
    FROM sys.tables t
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = r.Esquema AND t.name = r.Tabla
);

IF NOT EXISTS (SELECT 1 FROM @TablasFaltantes)
    PRINT '   [OK] Las 15 tablas existen';
ELSE
BEGIN
    PRINT '   [ERROR] Tablas faltantes:';
    SELECT '   - ' + Esquema + '.' + Tabla FROM @TablasFaltantes;
    SET @TotalErrores = @TotalErrores + 1;
END

PRINT '';

-- ==========================================================
-- 4. FOREIGN KEYS (18)
-- ==========================================================
PRINT '4. FOREIGN KEYS';
PRINT '   ----------------------------------------------';

DECLARE @TotalFKs INT;
SELECT @TotalFKs = COUNT(*)
FROM sys.foreign_keys fk
INNER JOIN sys.tables t ON fk.parent_object_id = t.object_id
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE s.name IN ('core', 'academic', 'sales', 'security', 'audit');

IF @TotalFKs = 18
    PRINT '   [OK] Foreign Keys: ' + CAST(@TotalFKs AS VARCHAR) + ' (esperado: 18)';
ELSE
BEGIN
    PRINT '   [ERROR] Foreign Keys: ' + CAST(@TotalFKs AS VARCHAR) + ' (esperado: 18)';
    SET @TotalErrores = @TotalErrores + 1;
END

PRINT '';

-- ==========================================================
-- 5. UNIQUE CONSTRAINTS (20)
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

IF @TotalUKs = 20
    PRINT '   [OK] Unique Constraints: ' + CAST(@TotalUKs AS VARCHAR) + ' (esperado: 20)';
ELSE
BEGIN
    PRINT '   [AVISO] Unique Constraints: ' + CAST(@TotalUKs AS VARCHAR) + ' (esperado: 20)';
    SET @TotalWarnings = @TotalWarnings + 1;
END

PRINT '';

-- ==========================================================
-- 6. CHECK CONSTRAINTS (26)
-- ==========================================================
PRINT '6. CHECK CONSTRAINTS';
PRINT '   ----------------------------------------------';

DECLARE @TotalCKs INT;
SELECT @TotalCKs = COUNT(*)
FROM sys.check_constraints cc
INNER JOIN sys.tables t ON cc.parent_object_id = t.object_id
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE s.name IN ('core', 'academic', 'sales', 'security', 'audit');

IF @TotalCKs = 26
    PRINT '   [OK] Check Constraints: ' + CAST(@TotalCKs AS VARCHAR) + ' (esperado: 26)';
ELSE
BEGIN
    PRINT '   [AVISO] Check Constraints: ' + CAST(@TotalCKs AS VARCHAR) + ' (esperado: 26)';
    SET @TotalWarnings = @TotalWarnings + 1;
END

PRINT '';

-- ==========================================================
-- 7. INDICES DE OPTIMIZACION (14 no agrupados, no unicos)
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

IF @TotalIndices = 14
    PRINT '   [OK] Indices no agrupados de optimizacion: ' + CAST(@TotalIndices AS VARCHAR) + ' (esperado: 14)';
ELSE
BEGIN
    PRINT '   [AVISO] Indices no agrupados: ' + CAST(@TotalIndices AS VARCHAR) + ' (esperado: 14)';
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

INSERT INTO @Resultados
SELECT 'core.Sedes', COUNT(*), 5, CASE WHEN COUNT(*) = 5 THEN '[OK]' ELSE '[ERR]' END FROM core.Sedes
UNION ALL SELECT 'core.Carreras', COUNT(*), 7, CASE WHEN COUNT(*) = 7 THEN '[OK]' ELSE '[ERR]' END FROM core.Carreras
UNION ALL SELECT 'core.Estudiantes', COUNT(*), 10, CASE WHEN COUNT(*) = 10 THEN '[OK]' ELSE '[ERR]' END FROM core.Estudiantes
UNION ALL SELECT 'core.PeriodosAcademicos', COUNT(*), 4, CASE WHEN COUNT(*) = 4 THEN '[OK]' ELSE '[ERR]' END FROM core.PeriodosAcademicos
UNION ALL SELECT 'core.Matriculas', COUNT(*), 10, CASE WHEN COUNT(*) = 10 THEN '[OK]' ELSE '[ERR]' END FROM core.Matriculas
UNION ALL SELECT 'academic.Profesores', COUNT(*), 10, CASE WHEN COUNT(*) = 10 THEN '[OK]' ELSE '[ERR]' END FROM academic.Profesores
UNION ALL SELECT 'academic.Cursos', COUNT(*), 10, CASE WHEN COUNT(*) = 10 THEN '[OK]' ELSE '[ERR]' END FROM academic.Cursos
UNION ALL SELECT 'academic.CarreraCursos', COUNT(*), 16, CASE WHEN COUNT(*) = 16 THEN '[OK]' ELSE '[ERR]' END FROM academic.CarreraCursos
UNION ALL SELECT 'academic.CursoProfesor', COUNT(*), 10, CASE WHEN COUNT(*) = 10 THEN '[OK]' ELSE '[ERR]' END FROM academic.CursoProfesor
UNION ALL SELECT 'sales.Promotores', COUNT(*), 6, CASE WHEN COUNT(*) = 6 THEN '[OK]' ELSE '[ERR]' END FROM sales.Promotores
UNION ALL SELECT 'sales.CampaniasAdmision', COUNT(*), 4, CASE WHEN COUNT(*) = 4 THEN '[OK]' ELSE '[ERR]' END FROM sales.CampaniasAdmision
UNION ALL SELECT 'sales.Comisiones', COUNT(*), 10, CASE WHEN COUNT(*) = 10 THEN '[OK]' ELSE '[ERR]' END FROM sales.Comisiones
UNION ALL SELECT 'security.Roles', COUNT(*), 5, CASE WHEN COUNT(*) = 5 THEN '[OK]' ELSE '[ERR]' END FROM security.Roles
UNION ALL SELECT 'security.Usuarios', COUNT(*), 5, CASE WHEN COUNT(*) = 5 THEN '[OK]' ELSE '[ERR]' END FROM security.Usuarios;

DECLARE @ErroresDatos INT;
SELECT @ErroresDatos = COUNT(*) FROM @Resultados WHERE Estado = '[ERR]';

IF @ErroresDatos = 0
BEGIN
    PRINT '   [OK] Las 14 tablas tienen la cantidad exacta de registros (112 total)';
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

DECLARE @DuplicadosDNI INT, @DuplicadosEmail INT, @DuplicadosMatricula INT;

SELECT @DuplicadosDNI = COUNT(*) FROM (
    SELECT DNI FROM core.Estudiantes GROUP BY DNI HAVING COUNT(*) > 1
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

IF @DuplicadosDNI = 0 AND @DuplicadosEmail = 0
    PRINT '   [OK] Sin estudiantes duplicados (DNI o Email unicos)';
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

IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'DatabaseVersion')
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
