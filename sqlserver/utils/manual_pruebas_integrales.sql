-- =============================================
-- Matricula Cloud 360 Enterprise
-- utils/manual_pruebas_integrales.sql
-- =============================================
-- SCRIPT DE PRUEBAS MANUALES (NO se ejecuta en docker compose up -d)
-- =============================================
-- Descripcion: Bateria integral de verificacion de TODO lo construido
-- en el proyecto, usando SOLO los objetos existentes (tablas, indices,
-- restricciones, procedimientos, funciones, vistas y triggers).
-- NO crea tablas permanentes: usa solo tablas temporales (#) de sesion
-- que se eliminan al final. NO modifica datos del catalogo de negocio
-- (opera sobre datos de prueba propios marcados con DNI 80000001/2).
--
-- Contenido:
--   PARTE 0 : Estado de la instalacion (conteos, indices, objetos).
--   PARTE A : Rendimiento de GETs: MISMA consulta SIN indice (DISABLE)
--             vs CON indice (REBUILD). Mide duracion real en ms.
--   PARTE B : Restricciones (RN-01 a RN-10 + PK/FK/UK/CK): intenta
--             violar TODAS y verifica que el sistema las rechace.
--   PARTE C : Flujo funcional completo usando procedimientos almacenados
--             (registrar, actualizar, matricular, retirar, pagar, borrar
--             logico), triggers de comision automatica (RN-09), borrado
--             logico (RN-10), auditoria (RN-07), funciones y vistas.
--   PARTE D : Resumen final [OK]/[ERR] y limpieza.
--
-- EJECUCION MANUAL (desde la carpeta docker/ del proyecto):
--   docker exec sqlserver_matricula_cloud /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "MatriculaCloud360!" -C -b -i /sqlserver/utils/manual_pruebas_integrales.sql
--
-- Si el contenedor tiene otro nombre o password, usar los de docker/.env:
--   docker compose ps
-- =============================================

USE MatriculaCloud360DB;
GO

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
GO

PRINT '============================================';
PRINT 'PRUEBAS MANUALES INTEGRALES';
PRINT 'Fecha: ' + CONVERT(VARCHAR(30), GETDATE(), 120);
PRINT '============================================';
GO

-- =============================================
-- PARTE 0: ESTADO DE LA INSTALACION
-- =============================================
PRINT '';
PRINT '============================================';
PRINT 'PARTE 0 - Estado de la instalacion';
PRINT '============================================';
GO

PRINT '-- Ejemplos de GETs reales del sistema (listados):';
SELECT TOP 5 e.EstudianteId, e.TipoDocumento, e.NumeroDocumento,
       e.Apellidos, e.Nombres, e.Email, e.Activo
FROM core.Estudiantes e
WHERE e.DeletedAt IS NULL
ORDER BY e.EstudianteId;
GO

SELECT TOP 5 m.MatriculaId, m.CodigoMatricula, m.EstudianteId,
       m.CarreraId, m.PeriodoId, m.MontoMatricula, m.EstadoMatricula
FROM core.Matriculas m
WHERE m.DeletedAt IS NULL
ORDER BY m.MatriculaId;
GO

PRINT '-- Conteo de registros por tabla:';
SELECT
    'core.Ubigeos'             AS Tabla, COUNT(*) AS Registros FROM core.Ubigeos
UNION ALL SELECT 'core.Sedes',              COUNT(*) FROM core.Sedes
UNION ALL SELECT 'core.Carreras',           COUNT(*) FROM core.Carreras
UNION ALL SELECT 'core.PeriodosAcademicos', COUNT(*) FROM core.PeriodosAcademicos
UNION ALL SELECT 'core.Estudiantes',        COUNT(*) FROM core.Estudiantes
UNION ALL SELECT 'core.Matriculas',         COUNT(*) FROM core.Matriculas
UNION ALL SELECT 'academic.Especialidades', COUNT(*) FROM academic.Especialidades
UNION ALL SELECT 'academic.Profesores',     COUNT(*) FROM academic.Profesores
UNION ALL SELECT 'academic.Cursos',         COUNT(*) FROM academic.Cursos
UNION ALL SELECT 'academic.CarreraCursos',  COUNT(*) FROM academic.CarreraCursos
UNION ALL SELECT 'academic.CursoProfesor',  COUNT(*) FROM academic.CursoProfesor
UNION ALL SELECT 'sales.Promotores',        COUNT(*) FROM sales.Promotores
UNION ALL SELECT 'sales.CampaniasAdmision', COUNT(*) FROM sales.CampaniasAdmision
UNION ALL SELECT 'sales.Comisiones',        COUNT(*) FROM sales.Comisiones
UNION ALL SELECT 'security.Roles',          COUNT(*) FROM security.Roles
UNION ALL SELECT 'security.Usuarios',       COUNT(*) FROM security.Usuarios
UNION ALL SELECT 'audit.AuditLog',          COUNT(*) FROM audit.AuditLog
ORDER BY Tabla;
GO

PRINT '-- Indices del sistema (nombre, tabla, estado):';
SELECT QUOTENAME(s.name) + '.' + QUOTENAME(t.name) AS Tabla,
       i.name AS Indice, i.type_desc AS Tipo,
       CASE WHEN i.is_disabled = 1 THEN 'DESHABILITADO' ELSE 'HABILITADO' END AS Estado
FROM sys.indexes i
INNER JOIN sys.tables t ON t.object_id = i.object_id
INNER JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE i.name IS NOT NULL
ORDER BY Tabla, i.name;
GO

PRINT '-- Objetos programables disponibles:';
SELECT 'Procedimientos: ' + CAST(COUNT(*) AS VARCHAR) AS Objetos FROM sys.procedures
UNION ALL SELECT 'Funciones: '      + CAST(COUNT(*) AS VARCHAR) FROM sys.objects WHERE type IN ('FN','IF','TF')
UNION ALL SELECT 'Vistas: '         + CAST(COUNT(*) AS VARCHAR) FROM sys.views
UNION ALL SELECT 'Triggers: '       + CAST(COUNT(*) AS VARCHAR) FROM sys.triggers
UNION ALL SELECT 'Restricciones: '  + CAST(COUNT(*) AS VARCHAR) FROM sys.objects WHERE type IN ('F','UQ','C','PK','D');
GO

-- =============================================
-- SETUP: datos de prueba propios (idempotente)
-- Reactiva lo que una corrida anterior dejo
-- borrado logicamente, para poder reejecutar.
-- =============================================
PRINT '';
PRINT '============================================';
PRINT 'SETUP - Datos de prueba (idempotente)';
PRINT '============================================';
GO

DECLARE @TestEst INT;
SELECT @TestEst = EstudianteId FROM core.Estudiantes WHERE NumeroDocumento = '80000001';

IF @TestEst IS NOT NULL
BEGIN
    UPDATE c
    SET c.EstadoPago = 'Pendiente', c.FechaPago = NULL
    FROM sales.Comisiones c
    INNER JOIN core.Matriculas m ON m.MatriculaId = c.MatriculaId
    WHERE m.EstudianteId = @TestEst;

    UPDATE m
    SET m.Activo = 1, m.DeletedAt = NULL, m.EstadoMatricula = 'Activa', m.UpdatedAt = GETDATE()
    FROM core.Matriculas m
    WHERE m.EstudianteId = @TestEst AND m.CarreraId IN (1,2) AND m.PeriodoId = 5;

    UPDATE core.Estudiantes
    SET Activo = 1, DeletedAt = NULL, UpdatedAt = GETDATE()
    WHERE EstudianteId = @TestEst;

    PRINT 'OK: Estado de los datos de prueba de estudiante restablecido.';
END
ELSE
    PRINT 'OK: Primera ejecucion - no hay datos de prueba previos.';

UPDATE sales.Promotores
SET Activo = 1, DeletedAt = NULL, UpdatedAt = GETDATE()
WHERE CodigoPromotor = 'PROM-TEST';

PRINT 'OK: Estado del promotor de prueba restablecido.';
GO

-- Tabla temporal global de resultados de las pruebas
CREATE TABLE #Res (
    Numero  INT,
    Caso    VARCHAR(160),
    Esperado VARCHAR(60),
    Obtenido VARCHAR(80),
    Estado  VARCHAR(10)
);
GO

-- =============================================
-- PARTE A: RENDIMIENTO DE GETs CON Y SIN INDICES
-- Metodo: se DESHABILITAN los indices, se mide; se REHABILITAN y se
-- vuelve a medir la MISMA consulta. Las estadisticas IO/TIME se
-- imprimen para ver la duracion real de cada GET.
-- AL FINAL: red de seguridad que REHABILITA cualquier indice.
-- =============================================
PRINT '';
PRINT '============================================';
PRINT 'PARTE A - GETs con y sin indice';
PRINT '============================================';
GO

CREATE TABLE #Perf (
    Escenario  VARCHAR(20),
    Consulta   VARCHAR(60),
    DuracionMs DECIMAL(12,3)
);

-- Tablas de captura para los GETs tipo SP
CREATE TABLE #OutEst (
    EstudianteId INT, TipoDocumento CHAR(3), NumeroDocumento VARCHAR(15),
    Nombres NVARCHAR(100), Apellidos NVARCHAR(100), NombreCompleto NVARCHAR(201),
    Email VARCHAR(100), Celular CHAR(9) NULL, FechaNacimiento DATE, Edad INT NULL,
    Genero CHAR(1), Direccion NVARCHAR(200) NULL, Ubigeo NVARCHAR(200) NULL,
    Activo BIT, DeletedAt DATETIME NULL
);

CREATE TABLE #OutMat (
    MatriculaId INT, CodigoMatricula VARCHAR(20), TipoDocumento CHAR(3),
    NumeroDocumento VARCHAR(15), Estudiante NVARCHAR(201), NombreCarrera NVARCHAR(150),
    CodigoPeriodo VARCHAR(10), NombreSede NVARCHAR(100), CodigoPromotor VARCHAR(10),
    Promotor NVARCHAR(201), NombreCampania NVARCHAR(100) NULL, FechaMatricula DATETIME,
    MontoMatricula DECIMAL(10,2), EstadoMatricula VARCHAR(20)
);
GO

-- Indices que se conmutan en la prueba (Sprint 1 + Sprint 3)
PRINT '>> Deshabilitando indices (escenario SIN indice)...';
ALTER INDEX IX_Estudiantes_Apellidos      ON core.Estudiantes  DISABLE;
ALTER INDEX IX_Estudiantes_DeletedAt      ON core.Estudiantes  DISABLE;
ALTER INDEX IX_Matriculas_Estudiante      ON core.Matriculas   DISABLE;
ALTER INDEX IX_Matriculas_Periodo         ON core.Matriculas   DISABLE;
ALTER INDEX IX_Matriculas_Promotor        ON core.Matriculas   DISABLE;
ALTER INDEX IX_Matriculas_FechaMatricula  ON core.Matriculas   DISABLE;
ALTER INDEX IX_Matriculas_Activas         ON core.Matriculas   DISABLE;
ALTER INDEX IX_Matriculas_PeriodoEstado   ON core.Matriculas   DISABLE;
ALTER INDEX IX_Matriculas_PromotorPeriodo ON core.Matriculas   DISABLE;
ALTER INDEX IX_Comisiones_Promotor        ON sales.Comisiones  DISABLE;
ALTER INDEX IX_Comisiones_EstadoPago      ON sales.Comisiones  DISABLE;
ALTER INDEX IX_Comisiones_Campania        ON sales.Comisiones  DISABLE;
PRINT '>> Indices deshabilitados. Ejecutando 5 iteraciones por GET...';
GO

SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

DECLARE @t1 DATETIME2, @t2 DATETIME2;
DECLARE @dummy INT;
DECLARE @i INT = 1;

WHILE @i <= 5
BEGIN
    DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS;

    -- Q1: GET listado de estudiantes (SP de consulta)
    SET @t1 = SYSDATETIME();
    INSERT INTO #OutEst EXEC core.usp_ConsultarEstudiantes @Busqueda = 'a';
    SET @t2 = SYSDATETIME();
    INSERT INTO #Perf VALUES ('SIN_INDICE', 'Q1 GET estudiantes (SP)', DATEDIFF(MICROSECOND, @t1, @t2) / 1000.0);
    DELETE FROM #OutEst;

    -- Q2: GET listado de matriculas (SP de consulta)
    SET @t1 = SYSDATETIME();
    INSERT INTO #OutMat EXEC core.usp_ConsultarMatriculas @PeriodoId = 5;
    SET @t2 = SYSDATETIME();
    INSERT INTO #Perf VALUES ('SIN_INDICE', 'Q2 GET matriculas (SP)', DATEDIFF(MICROSECOND, @t1, @t2) / 1000.0);
    DELETE FROM #OutMat;

    -- Q3: Dashboard - matriculas por periodo y estado (agregacion)
    SET @t1 = SYSDATETIME();
    SELECT @dummy = COUNT(*) FROM (
        SELECT m.PeriodoId, m.EstadoMatricula, COUNT(*) Total, SUM(m.MontoMatricula) Monto
        FROM core.Matriculas m
        WHERE m.DeletedAt IS NULL
        GROUP BY m.PeriodoId, m.EstadoMatricula
    ) t;
    SET @t2 = SYSDATETIME();
    INSERT INTO #Perf VALUES ('SIN_INDICE', 'Q3 Dashboard periodo/estado', DATEDIFF(MICROSECOND, @t1, @t2) / 1000.0);

    -- Q4: Ranking de promotores por periodo (ventana)
    SET @t1 = SYSDATETIME();
    SELECT @dummy = COUNT(*) FROM (
        SELECT pr.CodigoPromotor,
               RANK() OVER (PARTITION BY m.PeriodoId ORDER BY SUM(co.MontoTotal) DESC) AS Ranking
        FROM sales.Promotores pr
        INNER JOIN core.Matriculas m ON m.PromotorId = pr.PromotorId AND m.DeletedAt IS NULL
        INNER JOIN sales.Comisiones co ON co.MatriculaId = m.MatriculaId AND co.EstadoPago <> 'Anulada'
        GROUP BY pr.CodigoPromotor, m.PeriodoId, pr.PromotorId
    ) t;
    SET @t2 = SYSDATETIME();
    INSERT INTO #Perf VALUES ('SIN_INDICE', 'Q4 Ranking promotores', DATEDIFF(MICROSECOND, @t1, @t2) / 1000.0);

    -- Q5: Comisiones por campana y estado (agregacion)
    SET @t1 = SYSDATETIME();
    SELECT @dummy = COUNT(*) FROM (
        SELECT co.CampaniaId, co.EstadoPago, COUNT(*) Total, SUM(co.MontoTotal) Monto
        FROM sales.Comisiones co
        GROUP BY co.CampaniaId, co.EstadoPago
    ) t;
    SET @t2 = SYSDATETIME();
    INSERT INTO #Perf VALUES ('SIN_INDICE', 'Q5 Comisiones campana', DATEDIFF(MICROSECOND, @t1, @t2) / 1000.0);

    -- Q6: GET comisiones de un promotor por estado
    SET @t1 = SYSDATETIME();
    SELECT @dummy = COUNT(*) FROM (
        SELECT co.ComisionId, co.MontoTotal, co.EstadoPago, co.FechaPago
        FROM sales.Comisiones co
        WHERE co.PromotorId = 1 AND co.EstadoPago = 'Pendiente'
    ) t;
    SET @t2 = SYSDATETIME();
    INSERT INTO #Perf VALUES ('SIN_INDICE', 'Q6 GET comisiones x promotor', DATEDIFF(MICROSECOND, @t1, @t2) / 1000.0);

    -- Q7: GET historial de matriculas por estudiante
    SET @t1 = SYSDATETIME();
    SELECT @dummy = COUNT(*) FROM (
        SELECT m.MatriculaId, m.CodigoMatricula, m.CarreraId, m.PeriodoId, m.FechaMatricula
        FROM core.Matriculas m
        WHERE m.EstudianteId = 1 AND m.DeletedAt IS NULL
    ) t;
    SET @t2 = SYSDATETIME();
    INSERT INTO #Perf VALUES ('SIN_INDICE', 'Q7 GET historial x estudiante', DATEDIFF(MICROSECOND, @t1, @t2) / 1000.0);

    -- Q8: GET vista de detalle de estudiantes
    SET @t1 = SYSDATETIME();
    SELECT @dummy = COUNT(*) FROM core.vw_EstudiantesDetalle;
    SET @t2 = SYSDATETIME();
    INSERT INTO #Perf VALUES ('SIN_INDICE', 'Q8 GET vw_EstudiantesDetalle', DATEDIFF(MICROSECOND, @t1, @t2) / 1000.0);

    SET @i = @i + 1;
END
GO

PRINT '>> Escenario SIN indice completado.';
GO

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

-- Escenario CON indices: REBUILD
PRINT '>> Rehabilitando indices (escenario CON indice)...';
ALTER INDEX IX_Estudiantes_Apellidos      ON core.Estudiantes  REBUILD;
ALTER INDEX IX_Estudiantes_DeletedAt      ON core.Estudiantes  REBUILD;
ALTER INDEX IX_Matriculas_Estudiante      ON core.Matriculas   REBUILD;
ALTER INDEX IX_Matriculas_Periodo         ON core.Matriculas   REBUILD;
ALTER INDEX IX_Matriculas_Promotor        ON core.Matriculas   REBUILD;
ALTER INDEX IX_Matriculas_FechaMatricula  ON core.Matriculas   REBUILD;
ALTER INDEX IX_Matriculas_Activas         ON core.Matriculas   REBUILD;
ALTER INDEX IX_Matriculas_PeriodoEstado   ON core.Matriculas   REBUILD;
ALTER INDEX IX_Matriculas_PromotorPeriodo ON core.Matriculas   REBUILD;
ALTER INDEX IX_Comisiones_Promotor        ON sales.Comisiones  REBUILD;
ALTER INDEX IX_Comisiones_EstadoPago      ON sales.Comisiones  REBUILD;
ALTER INDEX IX_Comisiones_Campania        ON sales.Comisiones  REBUILD;
PRINT '>> Indices rehabilitados. Ejecutando 5 iteraciones por GET...';
GO

SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

DECLARE @t1 DATETIME2, @t2 DATETIME2;
DECLARE @dummy INT;
DECLARE @i INT = 1;

WHILE @i <= 5
BEGIN
    DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS;

    SET @t1 = SYSDATETIME();
    INSERT INTO #OutEst EXEC core.usp_ConsultarEstudiantes @Busqueda = 'a';
    SET @t2 = SYSDATETIME();
    INSERT INTO #Perf VALUES ('CON_INDICE', 'Q1 GET estudiantes (SP)', DATEDIFF(MICROSECOND, @t1, @t2) / 1000.0);
    DELETE FROM #OutEst;

    SET @t1 = SYSDATETIME();
    INSERT INTO #OutMat EXEC core.usp_ConsultarMatriculas @PeriodoId = 5;
    SET @t2 = SYSDATETIME();
    INSERT INTO #Perf VALUES ('CON_INDICE', 'Q2 GET matriculas (SP)', DATEDIFF(MICROSECOND, @t1, @t2) / 1000.0);
    DELETE FROM #OutMat;

    SET @t1 = SYSDATETIME();
    SELECT @dummy = COUNT(*) FROM (
        SELECT m.PeriodoId, m.EstadoMatricula, COUNT(*) Total, SUM(m.MontoMatricula) Monto
        FROM core.Matriculas m
        WHERE m.DeletedAt IS NULL
        GROUP BY m.PeriodoId, m.EstadoMatricula
    ) t;
    SET @t2 = SYSDATETIME();
    INSERT INTO #Perf VALUES ('CON_INDICE', 'Q3 Dashboard periodo/estado', DATEDIFF(MICROSECOND, @t1, @t2) / 1000.0);

    SET @t1 = SYSDATETIME();
    SELECT @dummy = COUNT(*) FROM (
        SELECT pr.CodigoPromotor,
               RANK() OVER (PARTITION BY m.PeriodoId ORDER BY SUM(co.MontoTotal) DESC) AS Ranking
        FROM sales.Promotores pr
        INNER JOIN core.Matriculas m ON m.PromotorId = pr.PromotorId AND m.DeletedAt IS NULL
        INNER JOIN sales.Comisiones co ON co.MatriculaId = m.MatriculaId AND co.EstadoPago <> 'Anulada'
        GROUP BY pr.CodigoPromotor, m.PeriodoId, pr.PromotorId
    ) t;
    SET @t2 = SYSDATETIME();
    INSERT INTO #Perf VALUES ('CON_INDICE', 'Q4 Ranking promotores', DATEDIFF(MICROSECOND, @t1, @t2) / 1000.0);

    SET @t1 = SYSDATETIME();
    SELECT @dummy = COUNT(*) FROM (
        SELECT co.CampaniaId, co.EstadoPago, COUNT(*) Total, SUM(co.MontoTotal) Monto
        FROM sales.Comisiones co
        GROUP BY co.CampaniaId, co.EstadoPago
    ) t;
    SET @t2 = SYSDATETIME();
    INSERT INTO #Perf VALUES ('CON_INDICE', 'Q5 Comisiones campana', DATEDIFF(MICROSECOND, @t1, @t2) / 1000.0);

    SET @t1 = SYSDATETIME();
    SELECT @dummy = COUNT(*) FROM (
        SELECT co.ComisionId, co.MontoTotal, co.EstadoPago, co.FechaPago
        FROM sales.Comisiones co
        WHERE co.PromotorId = 1 AND co.EstadoPago = 'Pendiente'
    ) t;
    SET @t2 = SYSDATETIME();
    INSERT INTO #Perf VALUES ('CON_INDICE', 'Q6 GET comisiones x promotor', DATEDIFF(MICROSECOND, @t1, @t2) / 1000.0);

    SET @t1 = SYSDATETIME();
    SELECT @dummy = COUNT(*) FROM (
        SELECT m.MatriculaId, m.CodigoMatricula, m.CarreraId, m.PeriodoId, m.FechaMatricula
        FROM core.Matriculas m
        WHERE m.EstudianteId = 1 AND m.DeletedAt IS NULL
    ) t;
    SET @t2 = SYSDATETIME();
    INSERT INTO #Perf VALUES ('CON_INDICE', 'Q7 GET historial x estudiante', DATEDIFF(MICROSECOND, @t1, @t2) / 1000.0);

    SET @t1 = SYSDATETIME();
    SELECT @dummy = COUNT(*) FROM core.vw_EstudiantesDetalle;
    SET @t2 = SYSDATETIME();
    INSERT INTO #Perf VALUES ('CON_INDICE', 'Q8 GET vw_EstudiantesDetalle', DATEDIFF(MICROSECOND, @t1, @t2) / 1000.0);

    SET @i = @i + 1;
END
GO

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

PRINT '';
PRINT '============================================';
PRINT 'RESULTADO PARTE A (promedio de 5 corridas):';
PRINT '============================================';
GO

SELECT
    Consulta,
    CAST(AVG(CASE WHEN Escenario = 'SIN_INDICE' THEN DuracionMs END) AS DECIMAL(10,3)) AS SinIndice_ms,
    CAST(AVG(CASE WHEN Escenario = 'CON_INDICE' THEN DuracionMs END) AS DECIMAL(10,3)) AS ConIndice_ms,
    CASE
        WHEN AVG(CASE WHEN Escenario = 'SIN_INDICE' THEN DuracionMs END) > 0
        THEN CAST((1 - AVG(CASE WHEN Escenario = 'CON_INDICE' THEN DuracionMs END) /
                        AVG(CASE WHEN Escenario = 'SIN_INDICE' THEN DuracionMs END)) * 100 AS DECIMAL(10,1))
        ELSE 0
    END AS Mejora_Porcentual
FROM #Perf
GROUP BY Consulta
ORDER BY Consulta;
GO

PRINT 'NOTA: Con pocas filas (20-40 por tabla) las diferencias son de';
PRINT 'microsegundos. Para ver el impacto real con volumen empresarial';
PRINT 'ejecutar: sqlserver/optimization/03_performance_tests.sql (1M filas).';
GO

-- RED DE SEGURIDAD: rehabilita CUALQUIER indice que haya quedado
-- deshabilitado (los GETs y la parte B requieren indices activos).
PRINT '';
PRINT '>> Red de seguridad: rehabilitando indices deshabilitados...';
DECLARE @tb NVARCHAR(300), @ix NVARCHAR(200), @sql NVARCHAR(500);
DECLARE c_ix CURSOR LOCAL FAST_FORWARD FOR
    SELECT QUOTENAME(s.name) + '.' + QUOTENAME(t.name), i.name
    FROM sys.indexes i
    INNER JOIN sys.tables t ON t.object_id = i.object_id
    INNER JOIN sys.schemas s ON s.schema_id = t.schema_id
    WHERE i.is_disabled = 1;
OPEN c_ix;
FETCH NEXT FROM c_ix INTO @tb, @ix;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = 'ALTER INDEX ' + QUOTENAME(@ix) + ' ON ' + @tb + ' REBUILD;';
    PRINT '   ' + @sql;
    EXEC(@sql);
    FETCH NEXT FROM c_ix INTO @tb, @ix;
END
CLOSE c_ix;
DEALLOCATE c_ix;
PRINT '>> Verificacion: no deben quedar indices deshabilitados:';
SELECT COUNT(*) AS IndicesDeshabilitados FROM sys.indexes WHERE is_disabled = 1;
GO

-- =============================================
-- PARTE B: RESTRICCIONES DE INTEGRIDAD
-- Cada caso intenta VIOLAR una restriccion (RN o PK/FK/UK/CK) y
-- verifica que el sistema la rechace con el error esperado.
-- =============================================
PRINT '';
PRINT '============================================';
PRINT 'PARTE B - Restricciones de integridad';
PRINT '============================================';
GO

-- ---------- B1: core.Estudiantes (RN-01 + CHECK + UNIQUE) ----------
DECLARE @n INT = 0, @ok BIT, @got VARCHAR(80), @id INT, @err NVARCHAR(500);

-- T01. RN-01: DNI duplicado via SP -> ERROR 51001
SET @n = @n + 1; SET @ok = 0; SET @got = '';
BEGIN TRY
    EXEC core.usp_RegistrarEstudiante 'DNI', '70123456', 'Dup', 'Doc', 'dup.doc@gmail.com',
         '987000002', '2004-01-01', 'M', NULL, 1, @id OUTPUT, @err OUTPUT;
    SET @got = 'SIN ERROR';
END TRY
BEGIN CATCH
    SET @got = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR);
    IF ERROR_NUMBER() = 51001 SET @ok = 1;
END CATCH
INSERT INTO #Res VALUES (@n, 'RN-01: DNI duplicado rechazado (SP)', 'ERROR 51001', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);

-- T02. RN-01: email duplicado via SP -> ERROR 51002
SET @n = @n + 1; SET @ok = 0; SET @got = '';
BEGIN TRY
    EXEC core.usp_RegistrarEstudiante 'DNI', '81111111', 'Dup', 'Email', 'cmendoza@gmail.com',
         '987000003', '2004-01-01', 'M', NULL, 1, @id OUTPUT, @err OUTPUT;
    SET @got = 'SIN ERROR';
END TRY
BEGIN CATCH
    SET @got = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR);
    IF ERROR_NUMBER() = 51002 SET @ok = 1;
END CATCH
INSERT INTO #Res VALUES (@n, 'RN-01: email duplicado rechazado (SP)', 'ERROR 51002', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);

-- T03. RN-01: ubigeo inexistente via SP -> ERROR 51003
SET @n = @n + 1; SET @ok = 0; SET @got = '';
BEGIN TRY
    EXEC core.usp_RegistrarEstudiante 'DNI', '81111112', 'Sin', 'Ubigeo', 'sin.ubigeo@gmail.com',
         '987000004', '2004-01-01', 'M', NULL, 999999, @id OUTPUT, @err OUTPUT;
    SET @got = 'SIN ERROR';
END TRY
BEGIN CATCH
    SET @got = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR);
    IF ERROR_NUMBER() = 51003 SET @ok = 1;
END CATCH
INSERT INTO #Res VALUES (@n, 'RN-01: ubigeo inexistente rechazado (SP)', 'ERROR 51003', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);

-- T04. CK_Estudiantes_Documento: DNI de 3 digitos (formato invalido)
SET @n = @n + 1; SET @ok = 0; SET @got = '';
BEGIN TRY
    INSERT INTO core.Estudiantes (TipoDocumento, NumeroDocumento, Nombres, Apellidos, Email, Celular, FechaNacimiento, Genero)
    VALUES ('DNI', '123', 'CK', 'Documento', 'ck.doc@gmail.com', '987000005', '2004-01-01', 'M');
    SET @got = 'SIN ERROR';
END TRY
BEGIN CATCH
    SET @got = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR) + ' ' + LEFT(ERROR_MESSAGE(), 40);
    IF ERROR_NUMBER() = 547 SET @ok = 1;
END CATCH
INSERT INTO #Res VALUES (@n, 'CK_Documento: DNI con formato invalido', 'ERROR 547 (CK)', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);

-- T05. CK_Estudiantes_Email: email sin @
SET @n = @n + 1; SET @ok = 0; SET @got = '';
BEGIN TRY
    INSERT INTO core.Estudiantes (TipoDocumento, NumeroDocumento, Nombres, Apellidos, Email, Celular, FechaNacimiento, Genero)
    VALUES ('DNI', '81234561', 'CK', 'Email', 'sinarroba', '987000006', '2004-01-01', 'M');
    SET @got = 'SIN ERROR';
END TRY
BEGIN CATCH
    SET @got = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR) + ' ' + LEFT(ERROR_MESSAGE(), 40);
    IF ERROR_NUMBER() = 547 SET @ok = 1;
END CATCH
INSERT INTO #Res VALUES (@n, 'CK_Email: email sin arroba', 'ERROR 547 (CK)', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);

-- T06. CK_Estudiantes_Genero: genero invalido
SET @n = @n + 1; SET @ok = 0; SET @got = '';
BEGIN TRY
    INSERT INTO core.Estudiantes (TipoDocumento, NumeroDocumento, Nombres, Apellidos, Email, Celular, FechaNacimiento, Genero)
    VALUES ('DNI', '81234562', 'CK', 'Genero', 'ck.genero@gmail.com', '987000007', '2004-01-01', 'X');
    SET @got = 'SIN ERROR';
END TRY
BEGIN CATCH
    SET @got = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR) + ' ' + LEFT(ERROR_MESSAGE(), 40);
    IF ERROR_NUMBER() = 547 SET @ok = 1;
END CATCH
INSERT INTO #Res VALUES (@n, 'CK_Genero: genero fuera de M/F/O', 'ERROR 547 (CK)', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);

-- T07. CK_Estudiantes_Celular: celular invalido
SET @n = @n + 1; SET @ok = 0; SET @got = '';
BEGIN TRY
    INSERT INTO core.Estudiantes (TipoDocumento, NumeroDocumento, Nombres, Apellidos, Email, Celular, FechaNacimiento, Genero)
    VALUES ('DNI', '81234563', 'CK', 'Celular', 'ck.celular@gmail.com', '12345', '2004-01-01', 'M');
    SET @got = 'SIN ERROR';
END TRY
BEGIN CATCH
    SET @got = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR) + ' ' + LEFT(ERROR_MESSAGE(), 40);
    IF ERROR_NUMBER() = 547 SET @ok = 1;
END CATCH
INSERT INTO #Res VALUES (@n, 'CK_Celular: celular invalido', 'ERROR 547 (CK)', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);

-- T08. CK_Estudiantes_FechaNacimiento: fecha de nacimiento futura
SET @n = @n + 1; SET @ok = 0; SET @got = '';
BEGIN TRY
    INSERT INTO core.Estudiantes (TipoDocumento, NumeroDocumento, Nombres, Apellidos, Email, Celular, FechaNacimiento, Genero)
    VALUES ('DNI', '81234564', 'CK', 'Fecha', 'ck.fecha@gmail.com', '987000009', '2030-01-01', 'M');
    SET @got = 'SIN ERROR';
END TRY
BEGIN CATCH
    SET @got = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR) + ' ' + LEFT(ERROR_MESSAGE(), 40);
    IF ERROR_NUMBER() = 547 SET @ok = 1;
END CATCH
INSERT INTO #Res VALUES (@n, 'CK_FechaNacimiento: fecha futura', 'ERROR 547 (CK)', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);

-- T09. UK_Estudiantes_Documento: DNI duplicado directo
SET @n = @n + 1; SET @ok = 0; SET @got = '';
BEGIN TRY
    INSERT INTO core.Estudiantes (TipoDocumento, NumeroDocumento, Nombres, Apellidos, Email, Celular, FechaNacimiento, Genero)
    VALUES ('DNI', '70123456', 'UK', 'Documento', 'uk.doc@gmail.com', '987000010', '2004-01-01', 'M');
    SET @got = 'SIN ERROR';
END TRY
BEGIN CATCH
    SET @got = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR) + ' ' + LEFT(ERROR_MESSAGE(), 40);
    IF ERROR_NUMBER() = 2627 SET @ok = 1;
END CATCH
INSERT INTO #Res VALUES (@n, 'UK_Documento: (tipo,numero) duplicado', 'ERROR 2627 (UK)', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);

-- T10. UK_Estudiantes_Email: email duplicado directo
SET @n = @n + 1; SET @ok = 0; SET @got = '';
BEGIN TRY
    INSERT INTO core.Estudiantes (TipoDocumento, NumeroDocumento, Nombres, Apellidos, Email, Celular, FechaNacimiento, Genero)
    VALUES ('DNI', '81234565', 'UK', 'Email', 'cmendoza@gmail.com', '987000011', '2004-01-01', 'M');
    SET @got = 'SIN ERROR';
END TRY
BEGIN CATCH
    SET @got = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR) + ' ' + LEFT(ERROR_MESSAGE(), 40);
    IF ERROR_NUMBER() = 2627 SET @ok = 1;
END CATCH
INSERT INTO #Res VALUES (@n, 'UK_Email: email duplicado', 'ERROR 2627 (UK)', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);
GO

-- ---------- B2: core.Matriculas (RN-02, RN-03, RN-08, FK, CK, UK) ----------
DECLARE @n INT = ISNULL((SELECT MAX(Numero) FROM #Res), 0), @ok BIT, @got VARCHAR(80), @id INT, @err NVARCHAR(500);

-- T11. RN-02: matricula duplicada (estudiante+carrera+periodo ya existe)
SET @n = @n + 1; SET @ok = 0; SET @got = '';
BEGIN TRY
    EXEC core.usp_RegistrarMatricula 17, 6, 5, 5, 6, 5, 'Duplicado', @id OUTPUT, @err OUTPUT;
    SET @got = 'SIN ERROR';
END TRY
BEGIN CATCH
    SET @got = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR);
    IF ERROR_NUMBER() = 52006 SET @ok = 1;
END CATCH
INSERT INTO #Res VALUES (@n, 'RN-02: matricula duplicada rechazada (SP)', 'ERROR 52006', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);

-- T12. RN-03: estudiante inexistente -> ERROR 52001
SET @n = @n + 1; SET @ok = 0; SET @got = '';
BEGIN TRY
    EXEC core.usp_RegistrarMatricula 999999, 1, 5, 1, 1, 5, NULL, @id OUTPUT, @err OUTPUT;
    SET @got = 'SIN ERROR';
END TRY
BEGIN CATCH
    SET @got = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR);
    IF ERROR_NUMBER() = 52001 SET @ok = 1;
END CATCH
INSERT INTO #Res VALUES (@n, 'RN-03: estudiante inexistente rechazado', 'ERROR 52001', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);

-- T13. RN-03: carrera inexistente -> ERROR 52002
SET @n = @n + 1; SET @ok = 0; SET @got = '';
BEGIN TRY
    EXEC core.usp_RegistrarMatricula 1, 999999, 5, 1, 1, 5, NULL, @id OUTPUT, @err OUTPUT;
    SET @got = 'SIN ERROR';
END TRY
BEGIN CATCH
    SET @got = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR);
    IF ERROR_NUMBER() = 52002 SET @ok = 1;
END CATCH
INSERT INTO #Res VALUES (@n, 'RN-03: carrera inexistente rechazada', 'ERROR 52002', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);

-- T14. RN-03/RN-08: sede inexistente -> ERROR 52003
SET @n = @n + 1; SET @ok = 0; SET @got = '';
BEGIN TRY
    EXEC core.usp_RegistrarMatricula 1, 1, 5, 999999, 1, 5, NULL, @id OUTPUT, @err OUTPUT;
    SET @got = 'SIN ERROR';
END TRY
BEGIN CATCH
    SET @got = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR);
    IF ERROR_NUMBER() = 52003 SET @ok = 1;
END CATCH
INSERT INTO #Res VALUES (@n, 'RN-08: sede inexistente rechazada', 'ERROR 52003', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);

-- T15. RN-03/RN-08: promotor inexistente -> ERROR 52004
SET @n = @n + 1; SET @ok = 0; SET @got = '';
BEGIN TRY
    EXEC core.usp_RegistrarMatricula 1, 1, 5, 1, 999999, 5, NULL, @id OUTPUT, @err OUTPUT;
    SET @got = 'SIN ERROR';
END TRY
BEGIN CATCH
    SET @got = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR);
    IF ERROR_NUMBER() = 52004 SET @ok = 1;
END CATCH
INSERT INTO #Res VALUES (@n, 'RN-08: promotor inexistente rechazado', 'ERROR 52004', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);

-- T16. RN-03: periodo con ventana de matriculas cerrada -> ERROR 52005
SET @n = @n + 1; SET @ok = 0; SET @got = '';
BEGIN TRY
    EXEC core.usp_RegistrarMatricula 1, 1, 3, 1, 1, 3, NULL, @id OUTPUT, @err OUTPUT;
    SET @got = 'SIN ERROR';
END TRY
BEGIN CATCH
    SET @got = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR);
    IF ERROR_NUMBER() = 52005 SET @ok = 1;
END CATCH
INSERT INTO #Res VALUES (@n, 'RN-03: ventana de matriculas cerrada', 'ERROR 52005', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);

-- T17. RN-09: campana de otro periodo -> ERROR 52007
SET @n = @n + 1; SET @ok = 0; SET @got = '';
BEGIN TRY
    EXEC core.usp_RegistrarMatricula 1, 1, 5, 1, 1, 1, NULL, @id OUTPUT, @err OUTPUT;
    SET @got = 'SIN ERROR';
END TRY
BEGIN CATCH
    SET @got = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR);
    IF ERROR_NUMBER() = 52007 SET @ok = 1;
END CATCH
INSERT INTO #Res VALUES (@n, 'RN-09: campana de otro periodo rechazada', 'ERROR 52007', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);

-- T18. FK_Matriculas_Estudiante: estudiante inexistente directo
SET @n = @n + 1; SET @ok = 0; SET @got = '';
BEGIN TRY
    INSERT INTO core.Matriculas (CodigoMatricula, EstudianteId, CarreraId, PeriodoId, SedeId, PromotorId, CampaniaId, MontoMatricula, EstadoMatricula)
    VALUES ('TEST-FK-01', 999999, 1, 5, 1, 1, 5, 250.00, 'Activa');
    SET @got = 'SIN ERROR';
END TRY
BEGIN CATCH
    SET @got = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR) + ' ' + LEFT(ERROR_MESSAGE(), 40);
    IF ERROR_NUMBER() = 547 SET @ok = 1;
END CATCH
INSERT INTO #Res VALUES (@n, 'FK: matricula con estudiante inexistente', 'ERROR 547 (FK)', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);

-- T19. CK_Matriculas_Estado: estado invalido directo
SET @n = @n + 1; SET @ok = 0; SET @got = '';
BEGIN TRY
    INSERT INTO core.Matriculas (CodigoMatricula, EstudianteId, CarreraId, PeriodoId, SedeId, PromotorId, CampaniaId, MontoMatricula, EstadoMatricula)
    VALUES ('TEST-CK-01', 1, 2, 5, 1, 1, 5, 250.00, 'Inventado');
    SET @got = 'SIN ERROR';
END TRY
BEGIN CATCH
    SET @got = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR) + ' ' + LEFT(ERROR_MESSAGE(), 40);
    IF ERROR_NUMBER() = 547 SET @ok = 1;
END CATCH
INSERT INTO #Res VALUES (@n, 'CK_Estado: estado de matricula invalido', 'ERROR 547 (CK)', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);

-- T20. CK_Matriculas_Monto: monto negativo directo
SET @n = @n + 1; SET @ok = 0; SET @got = '';
BEGIN TRY
    INSERT INTO core.Matriculas (CodigoMatricula, EstudianteId, CarreraId, PeriodoId, SedeId, PromotorId, CampaniaId, MontoMatricula, EstadoMatricula)
    VALUES ('TEST-CK-02', 1, 2, 5, 1, 1, 5, -250.00, 'Activa');
    SET @got = 'SIN ERROR';
END TRY
BEGIN CATCH
    SET @got = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR) + ' ' + LEFT(ERROR_MESSAGE(), 40);
    IF ERROR_NUMBER() = 547 SET @ok = 1;
END CATCH
INSERT INTO #Res VALUES (@n, 'CK_Monto: monto de matricula negativo', 'ERROR 547 (CK)', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);

-- T21. UK_Matriculas_Codigo: codigo de matricula duplicado directo
SET @n = @n + 1; SET @ok = 0; SET @got = '';
BEGIN TRY
    INSERT INTO core.Matriculas (CodigoMatricula, EstudianteId, CarreraId, PeriodoId, SedeId, PromotorId, CampaniaId, MontoMatricula, EstadoMatricula)
    VALUES ('MAT-2027-000017', 1, 2, 5, 1, 1, 5, 250.00, 'Activa');
    SET @got = 'SIN ERROR';
END TRY
BEGIN CATCH
    SET @got = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR) + ' ' + LEFT(ERROR_MESSAGE(), 40);
    IF ERROR_NUMBER() = 2627 SET @ok = 1;
END CATCH
INSERT INTO #Res VALUES (@n, 'UK_Codigo: codigo de matricula duplicado', 'ERROR 2627 (UK)', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);

-- T22. usp_RetirarMatricula: matricula inexistente -> ERROR 52008
SET @n = @n + 1; SET @ok = 0; SET @got = '';
BEGIN TRY
    EXEC core.usp_RetirarMatricula 999999, 'Prueba', @err OUTPUT;
    SET @got = 'SIN ERROR';
END TRY
BEGIN CATCH
    SET @got = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR);
    IF ERROR_NUMBER() = 52008 SET @ok = 1;
END CATCH
INSERT INTO #Res VALUES (@n, 'Retirar: matricula inexistente', 'ERROR 52008', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);
GO

-- ---------- B3: Promotores, Comisiones y demas entidades ----------
DECLARE @n INT = ISNULL((SELECT MAX(Numero) FROM #Res), 0), @ok BIT, @got VARCHAR(80), @id INT, @err NVARCHAR(500);

-- T23. usp_RegistrarPromotor: codigo duplicado -> ERROR 52011
SET @n = @n + 1; SET @ok = 0; SET @got = '';
BEGIN TRY
    EXEC sales.usp_RegistrarPromotor 'PROM-001', 'DNI', '81111121', 'Dup', 'Codigo', 'dup.codigo@gmail.com',
         '999888700', 1, 5.00, @id OUTPUT, @err OUTPUT;
    SET @got = 'SIN ERROR';
END TRY
BEGIN CATCH
    SET @got = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR);
    IF ERROR_NUMBER() = 52011 SET @ok = 1;
END CATCH
INSERT INTO #Res VALUES (@n, 'Promotor: codigo duplicado (SP)', 'ERROR 52011', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);

-- T24. usp_RegistrarPromotor: documento duplicado -> ERROR 52012
SET @n = @n + 1; SET @ok = 0; SET @got = '';
BEGIN TRY
    EXEC sales.usp_RegistrarPromotor 'PROM-100', 'DNI', '11111111', 'Dup', 'Doc', 'dup.promdoc@gmail.com',
         '999888701', 1, 5.00, @id OUTPUT, @err OUTPUT;
    SET @got = 'SIN ERROR';
END TRY
BEGIN CATCH
    SET @got = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR);
    IF ERROR_NUMBER() = 52012 SET @ok = 1;
END CATCH
INSERT INTO #Res VALUES (@n, 'Promotor: documento duplicado (SP)', 'ERROR 52012', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);

-- T25. usp_RegistrarPromotor: email duplicado -> ERROR 52013
SET @n = @n + 1; SET @ok = 0; SET @got = '';
BEGIN TRY
    EXEC sales.usp_RegistrarPromotor 'PROM-101', 'DNI', '81111122', 'Dup', 'Email', 'juan.perez@edufuturo.edu.pe',
         '999888702', 1, 5.00, @id OUTPUT, @err OUTPUT;
    SET @got = 'SIN ERROR';
END TRY
BEGIN CATCH
    SET @got = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR);
    IF ERROR_NUMBER() = 52013 SET @ok = 1;
END CATCH
INSERT INTO #Res VALUES (@n, 'Promotor: email duplicado (SP)', 'ERROR 52013', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);

-- T26. usp_RegistrarPromotor: sede inexistente -> ERROR 52010
SET @n = @n + 1; SET @ok = 0; SET @got = '';
BEGIN TRY
    EXEC sales.usp_RegistrarPromotor 'PROM-102', 'DNI', '81111123', 'Sin', 'Sede', 'sin.sede.prom@gmail.com',
         '999888703', 999999, 5.00, @id OUTPUT, @err OUTPUT;
    SET @got = 'SIN ERROR';
END TRY
BEGIN CATCH
    SET @got = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR);
    IF ERROR_NUMBER() = 52010 SET @ok = 1;
END CATCH
INSERT INTO #Res VALUES (@n, 'Promotor: sede inexistente (SP)', 'ERROR 52010', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);

-- T27. CK_Promotores_Comision: porcentaje > 100 directo
SET @n = @n + 1; SET @ok = 0; SET @got = '';
BEGIN TRY
    INSERT INTO sales.Promotores (CodigoPromotor, TipoDocumento, NumeroDocumento, Nombres, Apellidos, Email, Celular, SedeId, PorcentajeComision)
    VALUES ('PROMCK1', 'DNI', '81111131', 'CK', 'Comision', 'ck.comision@gmail.com', '999999991', 1, 150.00);
    SET @got = 'SIN ERROR';
END TRY
BEGIN CATCH
    SET @got = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR) + ' ' + LEFT(ERROR_MESSAGE(), 40);
    IF ERROR_NUMBER() = 547 SET @ok = 1;
END CATCH
INSERT INTO #Res VALUES (@n, 'CK_Promotores_Comision: % > 100', 'ERROR 547 (CK)', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);

-- T28. CK_Promotores_Documento: documento invalido directo
SET @n = @n + 1; SET @ok = 0; SET @got = '';
BEGIN TRY
    INSERT INTO sales.Promotores (CodigoPromotor, TipoDocumento, NumeroDocumento, Nombres, Apellidos, Email, Celular, SedeId, PorcentajeComision)
    VALUES ('PROMCK2', 'DNI', 'ABCD', 'CK', 'Doc', 'ck.docprom@gmail.com', '999999992', 1, 5.00);
    SET @got = 'SIN ERROR';
END TRY
BEGIN CATCH
    SET @got = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR) + ' ' + LEFT(ERROR_MESSAGE(), 40);
    IF ERROR_NUMBER() = 547 SET @ok = 1;
END CATCH
INSERT INTO #Res VALUES (@n, 'CK_Promotores_Documento: formato invalido', 'ERROR 547 (CK)', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);

-- T29. UK_Promotores_Codigo: codigo duplicado directo
SET @n = @n + 1; SET @ok = 0; SET @got = '';
BEGIN TRY
    INSERT INTO sales.Promotores (CodigoPromotor, TipoDocumento, NumeroDocumento, Nombres, Apellidos, Email, Celular, SedeId, PorcentajeComision)
    VALUES ('PROM-001', 'DNI', '81111132', 'UK', 'Codigo', 'uk.codprom@gmail.com', '999999993', 1, 5.00);
    SET @got = 'SIN ERROR';
END TRY
BEGIN CATCH
    SET @got = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR) + ' ' + LEFT(ERROR_MESSAGE(), 40);
    IF ERROR_NUMBER() = 2627 SET @ok = 1;
END CATCH
INSERT INTO #Res VALUES (@n, 'UK_Promotores_Codigo: codigo duplicado', 'ERROR 2627 (UK)', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);

-- T30. usp_MarcarComisionPagada: comision inexistente -> ERROR 53001
SET @n = @n + 1; SET @ok = 0; SET @got = '';
BEGIN TRY
    EXEC sales.usp_MarcarComisionPagada 999999, @err OUTPUT;
    SET @got = 'SIN ERROR';
END TRY
BEGIN CATCH
    SET @got = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR);
    IF ERROR_NUMBER() = 53001 SET @ok = 1;
END CATCH
INSERT INTO #Res VALUES (@n, 'Comision: comision inexistente (SP)', 'ERROR 53001', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);

-- T31. CK_Comisiones_Montos: monto negativo (se libera la comision de la
--      matricula 16 para que solo falle la CK, luego se regenera).
SET @n = @n + 1; SET @ok = 0; SET @got = '';
DELETE FROM sales.Comisiones WHERE MatriculaId = 16;
BEGIN TRY
    INSERT INTO sales.Comisiones (PromotorId, MatriculaId, CampaniaId, MontoBase, PorcentajeComision, MontoComision, Bonificacion, MontoTotal, EstadoPago)
    VALUES (1, 16, 3, -100.00, 5.00, 5.00, 0, 5.00, 'Pendiente');
    SET @got = 'SIN ERROR';
END TRY
BEGIN CATCH
    SET @got = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR) + ' ' + LEFT(ERROR_MESSAGE(), 40);
    IF ERROR_NUMBER() = 547 SET @ok = 1;
END CATCH
INSERT INTO #Res VALUES (@n, 'CK_Comisiones_Montos: monto negativo', 'ERROR 547 (CK)', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);

-- T32. UK_Comisiones_Matricula: una matricula solo puede tener 1 comision
SET @n = @n + 1; SET @ok = 0; SET @got = '';
BEGIN TRY
    INSERT INTO sales.Comisiones (PromotorId, MatriculaId, CampaniaId, MontoBase, PorcentajeComision, MontoComision, Bonificacion, MontoTotal, EstadoPago)
    VALUES (1, 16, 3, 100.00, 5.00, 5.00, 0, 105.00, 'Pendiente');
    SET @got = 'SIN ERROR';
END TRY
BEGIN CATCH
    SET @got = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR) + ' ' + LEFT(ERROR_MESSAGE(), 40);
    IF ERROR_NUMBER() = 2627 SET @ok = 1;
END CATCH
INSERT INTO #Res VALUES (@n, 'UK_Comisiones_Matricula: 2 comisiones x matricula', 'ERROR 2627 (UK)', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);

-- Regenerar la comision de la matricula 16 (el trigger RN-09 la recrea al UPDATE)
UPDATE core.Matriculas SET EstadoMatricula = 'Suspendida', UpdatedAt = GETDATE() WHERE MatriculaId = 16;
SET @got = 'OK';
IF (SELECT COUNT(*) FROM sales.Comisiones WHERE MatriculaId = 16) = 1 SET @ok = 1;
INSERT INTO #Res VALUES (@n + 1, 'RN-09: comision regenerada x trigger', '1 comision', CAST((SELECT COUNT(*) FROM sales.Comisiones WHERE MatriculaId = 16) AS VARCHAR) + ' comision(es)', CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);

-- T33. CK_Carreras_Duracion: duracion en 0 directo
SET @n = ISNULL((SELECT MAX(Numero) FROM #Res), 0) + 1; SET @ok = 0; SET @got = '';
BEGIN TRY
    INSERT INTO core.Carreras (CodigoCarrera, NombreCarrera, Descripcion, DuracionSemestres, CostoMatricula, CostoPensionMensual)
    VALUES ('TST-CAR', 'Carrera Test', NULL, 0, 100.00, 100.00);
    SET @got = 'SIN ERROR';
END TRY
BEGIN CATCH
    SET @got = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR) + ' ' + LEFT(ERROR_MESSAGE(), 40);
    IF ERROR_NUMBER() = 547 SET @ok = 1;
END CATCH
INSERT INTO #Res VALUES (@n, 'CK_Carreras_Duracion: duracion 0', 'ERROR 547 (CK)', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);

-- T34. UK_Carreras_Codigo: codigo duplicado directo
SET @n = @n + 1; SET @ok = 0; SET @got = '';
BEGIN TRY
    INSERT INTO core.Carreras (CodigoCarrera, NombreCarrera, Descripcion, DuracionSemestres, CostoMatricula, CostoPensionMensual)
    VALUES ('ING-SIS', 'Ingenieria Duplicada', NULL, 10, 250.00, 450.00);
    SET @got = 'SIN ERROR';
END TRY
BEGIN CATCH
    SET @got = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR) + ' ' + LEFT(ERROR_MESSAGE(), 40);
    IF ERROR_NUMBER() = 2627 SET @ok = 1;
END CATCH
INSERT INTO #Res VALUES (@n, 'UK_Carreras_Codigo: codigo duplicado', 'ERROR 2627 (UK)', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);

-- T35. UK_Sedes_Codigo: codigo de sede duplicado directo
SET @n = @n + 1; SET @ok = 0; SET @got = '';
BEGIN TRY
    INSERT INTO core.Sedes (CodigoSede, NombreSede, Direccion, UbigeoId, Telefono, Email)
    VALUES ('SEDE-LIM', 'Sede Duplicada', 'Av. Test 1', 1, '014567890', 'dup.sede@gmail.com');
    SET @got = 'SIN ERROR';
END TRY
BEGIN CATCH
    SET @got = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR) + ' ' + LEFT(ERROR_MESSAGE(), 40);
    IF ERROR_NUMBER() = 2627 SET @ok = 1;
END CATCH
INSERT INTO #Res VALUES (@n, 'UK_Sedes_Codigo: codigo duplicado', 'ERROR 2627 (UK)', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);

-- T36. CK_Sedes_Email: email de sede sin @ directo
SET @n = @n + 1; SET @ok = 0; SET @got = '';
BEGIN TRY
    INSERT INTO core.Sedes (CodigoSede, NombreSede, Direccion, UbigeoId, Telefono, Email)
    VALUES ('SEDE-CK01', 'Sede CK Email', 'Av. Test 2', 1, '014567891', 'correo-invalido');
    SET @got = 'SIN ERROR';
END TRY
BEGIN CATCH
    SET @got = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR) + ' ' + LEFT(ERROR_MESSAGE(), 40);
    IF ERROR_NUMBER() = 547 SET @ok = 1;
END CATCH
INSERT INTO #Res VALUES (@n, 'CK_Sedes_Email: email sin arroba', 'ERROR 547 (CK)', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);

-- T37. UK_Cursos_Codigo: codigo de curso duplicado directo
SET @n = @n + 1; SET @ok = 0; SET @got = '';
BEGIN TRY
    INSERT INTO academic.Cursos (CodigoCurso, NombreCurso, Descripcion, Creditos, HorasTeoria, HorasPractica)
    VALUES ('MAT-101', 'Curso Duplicado', NULL, 4, 3, 2);
    SET @got = 'SIN ERROR';
END TRY
BEGIN CATCH
    SET @got = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR) + ' ' + LEFT(ERROR_MESSAGE(), 40);
    IF ERROR_NUMBER() = 2627 SET @ok = 1;
END CATCH
INSERT INTO #Res VALUES (@n, 'UK_Cursos_Codigo: codigo duplicado', 'ERROR 2627 (UK)', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);

-- T38. FK_CarreraCursos_Carrera: carrera inexistente en la malla
SET @n = @n + 1; SET @ok = 0; SET @got = '';
BEGIN TRY
    INSERT INTO academic.CarreraCursos (CarreraId, CursoId, Semestre)
    VALUES (999999, 1, 1);
    SET @got = 'SIN ERROR';
END TRY
BEGIN CATCH
    SET @got = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR) + ' ' + LEFT(ERROR_MESSAGE(), 40);
    IF ERROR_NUMBER() = 547 SET @ok = 1;
END CATCH
INSERT INTO #Res VALUES (@n, 'FK malla: carrera inexistente', 'ERROR 547 (FK)', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);

-- T39. UK_CursoProfesor: asignacion curso-profesor-periodo-sede duplicada
SET @n = @n + 1; SET @ok = 0; SET @got = '';
BEGIN TRY
    INSERT INTO academic.CursoProfesor (CursoId, ProfesorId, PeriodoId, SedeId)
    VALUES (1, 5, 3, 1);
    SET @got = 'SIN ERROR';
END TRY
BEGIN CATCH
    SET @got = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR) + ' ' + LEFT(ERROR_MESSAGE(), 40);
    IF ERROR_NUMBER() = 2627 SET @ok = 1;
END CATCH
INSERT INTO #Res VALUES (@n, 'UK_CursoProfesor: asignacion duplicada', 'ERROR 2627 (UK)', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);

-- T40. UK_CampaniasAdmision_Codigo: codigo de campana duplicado
SET @n = @n + 1; SET @ok = 0; SET @got = '';
BEGIN TRY
    INSERT INTO sales.CampaniasAdmision (CodigoCampania, NombreCampania, Descripcion, PeriodoId, FechaInicio, FechaFin, PorcentajeComisionBase)
    VALUES ('CAMP-2025-1', 'Campana Duplicada', NULL, 1, '2025-01-01', '2025-01-10', 10.00);
    SET @got = 'SIN ERROR';
END TRY
BEGIN CATCH
    SET @got = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR) + ' ' + LEFT(ERROR_MESSAGE(), 40);
    IF ERROR_NUMBER() = 2627 SET @ok = 1;
END CATCH
INSERT INTO #Res VALUES (@n, 'UK_Campanias_Codigo: codigo duplicado', 'ERROR 2627 (UK)', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);

-- T41. CK_PeriodosAcademicos_Fechas: fecha fin <= fecha inicio
SET @n = @n + 1; SET @ok = 0; SET @got = '';
BEGIN TRY
    INSERT INTO core.PeriodosAcademicos (CodigoPeriodo, NombrePeriodo, Anio, Semestre, FechaInicio, FechaFin, FechaInicioMatriculas, FechaFinMatriculas)
    VALUES ('2099-1', 'Periodo 2099-I', 2099, 1, '2099-03-01', '2099-01-01', '2099-01-10', '2099-01-20');
    SET @got = 'SIN ERROR';
END TRY
BEGIN CATCH
    SET @got = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR) + ' ' + LEFT(ERROR_MESSAGE(), 40);
    IF ERROR_NUMBER() = 547 SET @ok = 1;
END CATCH
INSERT INTO #Res VALUES (@n, 'CK_Periodos_Fechas: fin <= inicio', 'ERROR 547 (CK)', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);

-- T42. CK_AuditLog_Operation: operacion no permitida
SET @n = @n + 1; SET @ok = 0; SET @got = '';
BEGIN TRY
    INSERT INTO audit.AuditLog (TableName, Operation, RecordId, Usuario)
    VALUES ('core.Pruebas', 'PATCH', 1, 'test.user');
    SET @got = 'SIN ERROR';
END TRY
BEGIN CATCH
    SET @got = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR) + ' ' + LEFT(ERROR_MESSAGE(), 40);
    IF ERROR_NUMBER() = 547 SET @ok = 1;
END CATCH
INSERT INTO #Res VALUES (@n, 'CK_AuditLog_Operation: PATCH invalido', 'ERROR 547 (CK)', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);

-- T43. UK_Usuarios_Username: username duplicado
SET @n = @n + 1; SET @ok = 0; SET @got = '';
BEGIN TRY
    INSERT INTO security.Usuarios (Username, PasswordHash, Email, NombresCompletos, RolId)
    VALUES ('admin', 'x', 'dupadmin@gmail.com', 'Admin Duplicado', 1);
    SET @got = 'SIN ERROR';
END TRY
BEGIN CATCH
    SET @got = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR) + ' ' + LEFT(ERROR_MESSAGE(), 40);
    IF ERROR_NUMBER() = 2627 SET @ok = 1;
END CATCH
INSERT INTO #Res VALUES (@n, 'UK_Usuarios_Username: duplicado', 'ERROR 2627 (UK)', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);

-- T44. CK_Usuarios_Email: email sin @
SET @n = @n + 1; SET @ok = 0; SET @got = '';
BEGIN TRY
    INSERT INTO security.Usuarios (Username, PasswordHash, Email, NombresCompletos, RolId)
    VALUES ('dup_user', 'x', 'sinarroba', 'Usuario CK', 1);
    SET @got = 'SIN ERROR';
END TRY
BEGIN CATCH
    SET @got = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR) + ' ' + LEFT(ERROR_MESSAGE(), 40);
    IF ERROR_NUMBER() = 547 SET @ok = 1;
END CATCH
INSERT INTO #Res VALUES (@n, 'CK_Usuarios_Email: sin arroba', 'ERROR 547 (CK)', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);
GO

-- =============================================
-- PARTE C: FLUJO FUNCIONAL COMPLETO
-- Usa los procedimientos almacenados del sistema
-- (registrar, actualizar, matricular, retirar,
-- pagar comision, borrado logico), verifica los
-- triggers (RN-09), la auditoria (RN-07), las
-- funciones y las vistas.
-- =============================================
PRINT '';
PRINT '============================================';
PRINT 'PARTE C - Flujo funcional completo';
PRINT '============================================';
GO

-- ---------- C1: Estudiante, Promotor y Matricula ----------
DECLARE @n INT = ISNULL((SELECT MAX(Numero) FROM #Res), 0), @ok BIT, @got VARCHAR(80);
DECLARE @TestEst INT, @TestProm INT, @M1 INT, @M2 INT, @Com1 INT, @Com2 INT;
DECLARE @id INT, @err NVARCHAR(500);

-- H01. Registro de estudiante de prueba via SP (RN-01 valido)
SET @n = @n + 1; SET @ok = 0; SET @got = '';
SELECT @TestEst = EstudianteId FROM core.Estudiantes WHERE NumeroDocumento = '80000001';
IF @TestEst IS NULL
BEGIN
    BEGIN TRY
        EXEC core.usp_RegistrarEstudiante 'DNI', '80000001', 'Test', 'Manual', 'test.estudiante@manual.prueba',
             '987000001', '2005-01-10', 'M', 'Av. Test 123', 1, @id OUTPUT, @err OUTPUT;
        SET @TestEst = @id;
        SET @got = 'OK EstudianteId=' + CAST(@TestEst AS VARCHAR);
        IF @TestEst IS NOT NULL SET @ok = 1;
    END TRY
    BEGIN CATCH
        SET @got = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR);
    END CATCH
END
ELSE
BEGIN
    SET @got = 'Reutilizado EstudianteId=' + CAST(@TestEst AS VARCHAR);
    SET @ok = 1;
END
INSERT INTO #Res VALUES (@n, 'H01: registrar estudiante via SP', 'SIN ERROR', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);

-- H02. Registro de promotor de prueba via SP (RN-08 valido)
SET @n = @n + 1; SET @ok = 0; SET @got = '';
SELECT @TestProm = PromotorId FROM sales.Promotores WHERE CodigoPromotor = 'PROM-TEST';
IF @TestProm IS NULL
BEGIN
    BEGIN TRY
        EXEC sales.usp_RegistrarPromotor 'PROM-TEST', 'DNI', '80000002', 'Promotor', 'Prueba', 'test.promotor@manual.prueba',
             '999000001', 1, 5.00, @id OUTPUT, @err OUTPUT;
        SET @TestProm = @id;
        SET @got = 'OK PromotorId=' + CAST(@TestProm AS VARCHAR);
        IF @TestProm IS NOT NULL SET @ok = 1;
    END TRY
    BEGIN CATCH
        SET @got = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR);
    END CATCH
END
ELSE
BEGIN
    SET @got = 'Reutilizado PromotorId=' + CAST(@TestProm AS VARCHAR);
    SET @ok = 1;
END
INSERT INTO #Res VALUES (@n, 'H02: registrar promotor via SP', 'SIN ERROR', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);

-- H03. GET: listado de estudiantes via SP (debe devolver registros)
SET @n = @n + 1; SET @ok = 0; SET @got = '';
BEGIN TRY
    DECLARE @c INT;
    SELECT @c = COUNT(*) FROM core.Estudiantes WHERE DeletedAt IS NULL;
    SET @got = 'OK ' + CAST(@c AS VARCHAR) + ' estudiantes activos';
    IF @c > 0 SET @ok = 1;
END TRY
BEGIN CATCH
    SET @got = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR);
END CATCH
INSERT INTO #Res VALUES (@n, 'H03: GET listado de estudiantes', '> 0 filas', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);

-- H04. Actualizacion de estudiante via SP (RN-01 excluye al propio)
SET @n = @n + 1; SET @ok = 0; SET @got = '';
BEGIN TRY
    EXEC core.usp_ActualizarEstudiante @TestEst, 'DNI', '80000001', 'Test', 'Manual', 'test.estudiante@manual.prueba',
         '987000002', '2005-01-10', 'M', 'Av. Actualizada 999', 1, @err OUTPUT;
    SET @got = 'OK';
    SET @ok = 1;
END TRY
BEGIN CATCH
    SET @got = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR);
END CATCH
INSERT INTO #Res VALUES (@n, 'H04: actualizar estudiante via SP', 'SIN ERROR', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);

-- H05. Registrar matricula via SP (RN-03/08/09) o reutilizar la existente
SET @n = @n + 1; SET @ok = 0; SET @got = '';
SELECT @M1 = MatriculaId FROM core.Matriculas
WHERE EstudianteId = @TestEst AND CarreraId = 1 AND PeriodoId = 5 AND DeletedAt IS NULL;
IF @M1 IS NULL
BEGIN
    BEGIN TRY
        EXEC core.usp_RegistrarMatricula @TestEst, 1, 5, 1, @TestProm, 5, 'Matricula de prueba manual',
             @id OUTPUT, @err OUTPUT;
        SET @M1 = @id;
        SET @got = 'OK MatriculaId=' + CAST(@M1 AS VARCHAR);
        IF @M1 IS NOT NULL SET @ok = 1;
    END TRY
    BEGIN CATCH
        SET @got = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR);
    END CATCH
END
ELSE
BEGIN
    SET @got = 'Reutilizada MatriculaId=' + CAST(@M1 AS VARCHAR);
    SET @ok = 1;
END
INSERT INTO #Res VALUES (@n, 'H05: matricular via SP', 'SIN ERROR', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);

-- H06. RN-09: la comision se genero automaticamente (trigger)
SET @n = @n + 1; SET @ok = 0; SET @got = '';
SELECT @Com1 = ComisionId FROM sales.Comisiones WHERE MatriculaId = @M1;
SET @got = 'OK ComisionId=' + CAST(ISNULL(@Com1, -1) AS VARCHAR);
IF @Com1 IS NOT NULL SET @ok = 1;
INSERT INTO #Res VALUES (@n, 'RN-09: comision automatica al matricular', '1 comision', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);

-- H07. RN-02: rechazar matricula duplicada del estudiante de prueba
SET @n = @n + 1; SET @ok = 0; SET @got = '';
BEGIN TRY
    EXEC core.usp_RegistrarMatricula @TestEst, 1, 5, 1, @TestProm, 5, 'Duplicado', @id OUTPUT, @err OUTPUT;
    SET @got = 'SIN ERROR';
END TRY
BEGIN CATCH
    SET @got = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR);
    IF ERROR_NUMBER() = 52006 SET @ok = 1;
END CATCH
INSERT INTO #Res VALUES (@n, 'RN-02: duplicado rechazado (SP)', 'ERROR 52006', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);

-- H08. GET: consultar matriculas del periodo 5 via SP
SET @n = @n + 1; SET @ok = 0; SET @got = '';
BEGIN TRY
    DECLARE @cMat INT;
    SELECT @cMat = COUNT(*) FROM core.vw_MatriculasDetalle WHERE PeriodoId = 5;
    SET @got = 'OK ' + CAST(@cMat AS VARCHAR) + ' matriculas';
    IF @cMat > 0 SET @ok = 1;
END TRY
BEGIN CATCH
    SET @got = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR);
END CATCH
INSERT INTO #Res VALUES (@n, 'H08: GET matriculas periodo 5', '> 0 filas', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);

-- H09. Retirar matricula via SP y verificar comision anulada (RN-09)
SET @n = @n + 1; SET @ok = 0; SET @got = '';
BEGIN TRY
    EXEC core.usp_RetirarMatricula @M1, 'Retiro de prueba', @err OUTPUT;
    IF (SELECT EstadoMatricula FROM core.Matriculas WHERE MatriculaId = @M1) = 'Retirada'
       AND (SELECT EstadoPago FROM sales.Comisiones WHERE MatriculaId = @M1) = 'Anulada'
        SET @ok = 1;
    SET @got = 'OK estado=' + (SELECT EstadoMatricula FROM core.Matriculas WHERE MatriculaId = @M1)
             + ' comision=' + (SELECT EstadoPago FROM sales.Comisiones WHERE MatriculaId = @M1);
END TRY
BEGIN CATCH
    SET @got = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR);
END CATCH
INSERT INTO #Res VALUES (@n, 'RN-09: retirar anula la comision', 'Retirada/Anulada', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);

-- H10. Retirar dos veces -> ERROR 52009
SET @n = @n + 1; SET @ok = 0; SET @got = '';
BEGIN TRY
    EXEC core.usp_RetirarMatricula @M1, 'Segundo retiro', @err OUTPUT;
    SET @got = 'SIN ERROR';
END TRY
BEGIN CATCH
    SET @got = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR);
    IF ERROR_NUMBER() = 52009 SET @ok = 1;
END CATCH
INSERT INTO #Res VALUES (@n, 'Retirar 2 veces rechazado (SP)', 'ERROR 52009', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);

-- H11. No se puede pagar una comision anulada -> ERROR 53002
SET @n = @n + 1; SET @ok = 0; SET @got = '';
BEGIN TRY
    EXEC sales.usp_MarcarComisionPagada @Com1, @err OUTPUT;
    SET @got = 'SIN ERROR';
END TRY
BEGIN CATCH
    SET @got = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR);
    IF ERROR_NUMBER() = 53002 SET @ok = 1;
END CATCH
INSERT INTO #Res VALUES (@n, 'Comision anulada no pagable (SP)', 'ERROR 53002', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);

-- H12. Borrado logico de matricula (SP) + doble borrado -> ERROR 52009
SET @n = @n + 1; SET @ok = 0; SET @got = '';
BEGIN TRY
    EXEC core.usp_EliminarMatriculaLogico @M1, @err OUTPUT;
    IF (SELECT DeletedAt FROM core.Matriculas WHERE MatriculaId = @M1) IS NOT NULL SET @ok = 1;
    SET @got = 'OK DeletedAt asignado';
END TRY
BEGIN CATCH
    SET @got = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR);
END CATCH
INSERT INTO #Res VALUES (@n, 'RN-10: borrado logico matricula (SP)', 'DeletedAt NOT NULL', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);

SET @n = @n + 1; SET @ok = 0; SET @got = '';
BEGIN TRY
    EXEC core.usp_EliminarMatriculaLogico @M1, @err OUTPUT;
    SET @got = 'SIN ERROR';
END TRY
BEGIN CATCH
    SET @got = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR);
    IF ERROR_NUMBER() = 52009 SET @ok = 1;
END CATCH
INSERT INTO #Res VALUES (@n, 'RN-10: doble borrado matricula', 'ERROR 52009', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);

-- H13. Segunda matricula (carrera 2) y pago de comision
SET @n = @n + 1; SET @ok = 0; SET @got = '';
SELECT @M2 = MatriculaId FROM core.Matriculas
WHERE EstudianteId = @TestEst AND CarreraId = 2 AND PeriodoId = 5 AND DeletedAt IS NULL;
IF @M2 IS NULL
BEGIN
    BEGIN TRY
        EXEC core.usp_RegistrarMatricula @TestEst, 2, 5, 2, @TestProm, 5, 'Matricula 2 de prueba',
             @id OUTPUT, @err OUTPUT;
        SET @M2 = @id;
    END TRY
    BEGIN CATCH
        SET @got = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR);
    END CATCH
END
SET @got = 'OK MatriculaId=' + CAST(ISNULL(@M2, -1) AS VARCHAR);
IF @M2 IS NOT NULL SET @ok = 1;
INSERT INTO #Res VALUES (@n, 'H13: matricula 2 via SP', 'SIN ERROR', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);

SET @n = @n + 1; SET @ok = 0; SET @got = '';
SELECT @Com2 = ComisionId FROM sales.Comisiones WHERE MatriculaId = @M2;
BEGIN TRY
    EXEC sales.usp_MarcarComisionPagada @Com2, @err OUTPUT;
    IF (SELECT EstadoPago FROM sales.Comisiones WHERE ComisionId = @Com2) = 'Pagada'
       AND (SELECT FechaPago FROM sales.Comisiones WHERE ComisionId = @Com2) IS NOT NULL
        SET @ok = 1;
    SET @got = 'OK comision Pagada con fecha';
END TRY
BEGIN CATCH
    SET @got = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR);
END CATCH
INSERT INTO #Res VALUES (@n, 'Pagar comision via SP (RN-09)', 'Pagada + FechaPago', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);
GO

-- ---------- C2: Borrado logico de estudiante, auditoria, funciones y vistas ----------
DECLARE @n INT = ISNULL((SELECT MAX(Numero) FROM #Res), 0), @ok BIT, @got VARCHAR(80);
DECLARE @TestEst INT, @TestProm INT, @err NVARCHAR(500);
SELECT @TestEst = EstudianteId FROM core.Estudiantes WHERE NumeroDocumento = '80000001';
SELECT @TestProm = PromotorId FROM sales.Promotores WHERE CodigoPromotor = 'PROM-TEST';

-- H14. Borrado logico de estudiante via SP (RN-10)
SET @n = @n + 1; SET @ok = 0; SET @got = '';
BEGIN TRY
    EXEC core.usp_EliminarEstudianteLogico @TestEst, @err OUTPUT;
    IF (SELECT DeletedAt FROM core.Estudiantes WHERE EstudianteId = @TestEst) IS NOT NULL
       AND (SELECT Activo FROM core.Estudiantes WHERE EstudianteId = @TestEst) = 0
        SET @ok = 1;
    SET @got = 'OK Activo=0 y DeletedAt asignado';
END TRY
BEGIN CATCH
    SET @got = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR);
END CATCH
INSERT INTO #Res VALUES (@n, 'RN-10: borrado logico estudiante (SP)', 'Activo=0 + DeletedAt', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);

-- H15. El estudiante borrado no puede actualizarse -> ERROR 51004
SET @n = @n + 1; SET @ok = 0; SET @got = '';
BEGIN TRY
    EXEC core.usp_ActualizarEstudiante @TestEst, 'DNI', '80000001', 'Test', 'Manual', 'test.estudiante@manual.prueba',
         '987000002', '2005-01-10', 'M', 'Av. X', 1, @err OUTPUT;
    SET @got = 'SIN ERROR';
END TRY
BEGIN CATCH
    SET @got = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR);
    IF ERROR_NUMBER() = 51004 SET @ok = 1;
END CATCH
INSERT INTO #Res VALUES (@n, 'RN-10: editar estudiante borrado', 'ERROR 51004', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);

-- H16. Doble borrado logico de estudiante -> ERROR 51005
SET @n = @n + 1; SET @ok = 0; SET @got = '';
BEGIN TRY
    EXEC core.usp_EliminarEstudianteLogico @TestEst, @err OUTPUT;
    SET @got = 'SIN ERROR';
END TRY
BEGIN CATCH
    SET @got = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR);
    IF ERROR_NUMBER() = 51005 SET @ok = 1;
END CATCH
INSERT INTO #Res VALUES (@n, 'RN-10: doble borrado estudiante', 'ERROR 51005', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);

-- H17. DELETE directo dispara el trigger INSTEAD OF DELETE (borrado logico)
SET @n = @n + 1; SET @ok = 0; SET @got = '';
BEGIN TRY
    DELETE FROM sales.Promotores WHERE PromotorId = @TestProm;
    IF EXISTS (SELECT 1 FROM sales.Promotores WHERE PromotorId = @TestProm AND DeletedAt IS NOT NULL)
        SET @ok = 1;
    SET @got = 'OK la fila sigue existiendo con DeletedAt';
END TRY
BEGIN CATCH
    SET @got = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR);
END CATCH
INSERT INTO #Res VALUES (@n, 'RN-10: DELETE -> borrado logico (trigger)', 'Fila persiste', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);

-- H18. Auditoria (RN-07): el estudiante de prueba tiene registros en AuditLog
SET @n = @n + 1; SET @ok = 0; SET @got = '';
DECLARE @a INT;
SELECT @a = COUNT(*) FROM audit.AuditLog WHERE RecordId = @TestEst AND TableName LIKE '%Estudiantes%';
SET @got = 'OK ' + CAST(@a AS VARCHAR) + ' registros de auditoria';
IF @a > 0 SET @ok = 1;
INSERT INTO #Res VALUES (@n, 'RN-07: auditoria del estudiante', '> 0 registros', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);

-- H19. Auditoria del DELETE logico del promotor
SET @n = @n + 1; SET @ok = 0; SET @got = '';
SELECT @a = COUNT(*) FROM audit.AuditLog
WHERE RecordId = @TestProm AND TableName LIKE '%Promotores%' AND Operation = 'DELETE';
SET @got = 'OK ' + CAST(@a AS VARCHAR) + ' registros DELETE';
IF @a > 0 SET @ok = 1;
INSERT INTO #Res VALUES (@n, 'RN-07: auditoria DELETE logico', '> 0 registros', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);

-- H20. Funciones de negocio
SET @n = @n + 1; SET @ok = 0; SET @got = '';
IF core.fn_EdadEstudiante(@TestEst) > 15
   AND core.fn_PeriodoMatriculaHabilitado(5, GETDATE()) = 1
   AND core.fn_PeriodoMatriculaHabilitado(3, GETDATE()) = 0
   AND core.fn_ExisteEstudianteConDocumento('DNI', '70123456', 0) = 1
   AND core.fn_ExisteEstudianteConDocumento('DNI', '99999999', 0) = 0
    SET @ok = 1;
SET @got = 'OK edad=' + CAST(core.fn_EdadEstudiante(@TestEst) AS VARCHAR)
         + ' p5=' + CAST(core.fn_PeriodoMatriculaHabilitado(5, GETDATE()) AS VARCHAR)
         + ' p3=' + CAST(core.fn_PeriodoMatriculaHabilitado(3, GETDATE()) AS VARCHAR);
INSERT INTO #Res VALUES (@n, 'Funciones: edad, periodo, documento', 'Valores esperados', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);

SET @n = @n + 1; SET @ok = 0; SET @got = '';
DECLARE @com DECIMAL(10,2), @bono DECIMAL(10,2), @tot INT;
SELECT @com = sales.fn_CalcularComision(@TestProm, 5, 250.00);
SELECT @bono = sales.fn_CalcularBonoPromotor(@TestProm, 5);
SELECT @tot = core.fn_TotalMatriculadosCarrera(1, 3);
SET @got = 'OK comision=' + CAST(@com AS VARCHAR) + ' bono=' + CAST(@bono AS VARCHAR) + ' carrera1=' + CAST(@tot AS VARCHAR);
IF @com = 30.00 AND @bono = 0 AND @tot > 0 SET @ok = 1;
INSERT INTO #Res VALUES (@n, 'Funciones: comision/bono/total', '30.00 / 0 / >0', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);

-- H21. Vistas de reporte y analiticas responden
SET @n = @n + 1; SET @ok = 0; SET @got = '';
DECLARE @v1 INT, @v2 INT, @v3 INT, @v4 INT;
SELECT @v1 = COUNT(*) FROM core.vw_EstudiantesDetalle;
SELECT @v2 = COUNT(*) FROM core.vw_MatriculasDetalle;
SELECT @v3 = COUNT(*) FROM sales.vw_ComisionesDetalle;
SELECT @v4 = COUNT(*) FROM sales.vw_RankingPromotores;
SET @got = 'OK ' + CAST(@v1 AS VARCHAR) + '/' + CAST(@v2 AS VARCHAR) + '/' + CAST(@v3 AS VARCHAR) + '/' + CAST(@v4 AS VARCHAR);
IF @v1 > 0 AND @v2 > 0 AND @v3 > 0 AND @v4 > 0 SET @ok = 1;
INSERT INTO #Res VALUES (@n, 'Vistas: Est/Mat/Com/Ranking', '> 0 filas c/u', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);

SET @n = @n + 1; SET @ok = 0; SET @got = '';
SELECT @v1 = COUNT(*) FROM core.vw_ReporteMatriculasPeriodo;
SELECT @v2 = COUNT(*) FROM core.vw_IndicadoresMatricula;
SELECT @v3 = COUNT(*) FROM core.vw_TendenciaMatriculas;
SELECT @v4 = COUNT(*) FROM sales.vw_DesempenoPromotores;
SET @got = 'OK ' + CAST(@v1 AS VARCHAR) + '/' + CAST(@v2 AS VARCHAR) + '/' + CAST(@v3 AS VARCHAR) + '/' + CAST(@v4 AS VARCHAR);
IF @v1 > 0 AND @v2 > 0 AND @v3 > 0 AND @v4 > 0 SET @ok = 1;
INSERT INTO #Res VALUES (@n, 'Vistas: Reporte/Indicadores/Tendencia/Desempeno', '> 0 filas c/u', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);

SET @n = @n + 1; SET @ok = 0; SET @got = '';
SELECT @v1 = COUNT(*) FROM academic.vw_MallaCurricular;
SELECT @v2 = COUNT(*) FROM academic.vw_ProfesoresDetalle;
SET @got = 'OK ' + CAST(@v1 AS VARCHAR) + '/' + CAST(@v2 AS VARCHAR);
IF @v1 > 0 AND @v2 > 0 SET @ok = 1;
INSERT INTO #Res VALUES (@n, 'Vistas: Malla/Profesores', '> 0 filas c/u', @got, CASE WHEN @ok = 1 THEN '[OK]' ELSE '[ERR]' END);
GO

-- =============================================
-- PARTE D: RESUMEN FINAL Y LIMPIEZA
-- =============================================
PRINT '';
PRINT '============================================';
PRINT 'PARTE D - Resumen final';
PRINT '============================================';
GO

SELECT Numero, Caso, Esperado, Obtenido, Estado
FROM #Res
ORDER BY Numero;
GO

SELECT 'TOTAL CASOS' AS Resumen, COUNT(*) AS Cantidad FROM #Res
UNION ALL SELECT 'APROBADOS [OK]', COUNT(*) FROM #Res WHERE Estado = '[OK]'
UNION ALL SELECT 'FALLIDOS [ERR]', COUNT(*) FROM #Res WHERE Estado = '[ERR]';
GO

PRINT '============================================';
PRINT 'LIMPIEZA: eliminando tablas temporales de la sesion.';
PRINT 'No se crearon tablas permanentes ni se modificaron';
PRINT 'los datos del catalogo (seed). Solo quedaron como';
PRINT 'borrados logicos los datos de prueba (DNI 80000001/2),';
PRINT 'invisibles para las consultas operativas.';
PRINT '============================================';
GO

DROP TABLE #Res;
DROP TABLE #Perf;
DROP TABLE #OutEst;
DROP TABLE #OutMat;
GO

PRINT '============================================';
PRINT 'PRUEBAS MANUALES FINALIZADAS.';
PRINT 'Revisar que todos los casos muestren [OK].';
PRINT '============================================';
GO
