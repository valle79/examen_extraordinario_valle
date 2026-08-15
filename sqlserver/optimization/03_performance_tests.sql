-- =============================================
-- Matricula Cloud 360 Enterprise
-- optimization/03_performance_tests.sql | Pruebas comparativas
-- =============================================
-- Descripcion (Sprint 3): Pruebas ANTES / DESPUES de la estrategia
-- de indexacion sobre las consultas criticas del sistema:
--
--   PARTE A - Consultas criticas reales (dashboard y reporteria):
--     Q1: Matriculas por periodo y estado (dashboard)
--     Q2: Ranking de promotores por periodo (ventana)
--     Q3: Comisiones por campana y estado (plan de pagos)
--     Metodo: se DESHABILITAN los indices del Sprint 3
--     (ALTER INDEX ... DISABLE), se mide; luego se REHABILITAN
--     (REBUILD) y se mide de nuevo. Se compara duracion y se
--     muestran las estadisticas de E/S (SET STATISTICS IO/TIME).
--
--   PARTE B - Prueba de escala con volumen (1000000 filas):
--     Tabla sintetica (dbo.PerfMatriculas) para demostrar la
--     diferencia real de un indice compuesto + filtrado ante
--     volumen empresarial. La tabla se elimina al final.
--     Se capturan los PLANES DE EJECUCION (SET SHOWPLAN_XML) antes
--     y despues del indice (Table Scan vs Index Seek) como evidencia
--     del analisis de rendimiento, ademas de STATISTICS TIME/IO.
--
-- AL FINAL: los indices quedan HABILITADOS (estado correcto) y se
-- genera un NUEVO respaldo FULL para restablecer la cadena de
-- respaldos LOG (la conmutacion SIMPLE->FULL la interrumpe).
-- IDEMPOTENTE y SEGURO: la tabla sintetica se elimina al terminar.
-- =============================================

USE MatriculaCloud360DB;
GO

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
GO

PRINT '============================================';
PRINT 'optimization/03_performance_tests.sql';
PRINT 'Pruebas comparativas ANTES/DESPUES de indices';
PRINT '============================================';
GO

-- ============================================================
-- 0. ASEGURAR LOS INDICES DEL SPRINT 3 (si el script se ejecuta
--    de forma aislada, sin pasar antes por 01_indexes.sql)
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Matriculas_PeriodoEstado' AND object_id = OBJECT_ID('core.Matriculas'))
    CREATE NONCLUSTERED INDEX IX_Matriculas_PeriodoEstado
        ON core.Matriculas(PeriodoId, EstadoMatricula)
        INCLUDE (MontoMatricula, PromotorId, SedeId, CampaniaId)
        WHERE DeletedAt IS NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Matriculas_PromotorPeriodo' AND object_id = OBJECT_ID('core.Matriculas'))
    CREATE NONCLUSTERED INDEX IX_Matriculas_PromotorPeriodo
        ON core.Matriculas(PromotorId, PeriodoId)
        INCLUDE (MontoMatricula, EstadoMatricula, FechaMatricula, EstudianteId, SedeId)
        WHERE DeletedAt IS NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Comisiones_Campania' AND object_id = OBJECT_ID('sales.Comisiones'))
    CREATE NONCLUSTERED INDEX IX_Comisiones_Campania
        ON sales.Comisiones(CampaniaId, EstadoPago)
        INCLUDE (MontoTotal, PromotorId, FechaPago);
GO

PRINT 'OK: Indices del Sprint 3 asegurados.';
GO

-- ============================================================
-- PARTE A: CONSULTAS CRITICAS REALES (antes vs despues)
-- ============================================================
PRINT '';
PRINT '============================================';
PRINT 'PARTE A - Consultas criticas reales';
PRINT '============================================';
GO

CREATE TABLE #ResultadosParteA (
    Escenario  VARCHAR(20),
    Consulta   VARCHAR(60),
    DuracionMs DECIMAL(12,3)
);
GO

DECLARE @t1 DATETIME2, @t2 DATETIME2;
DECLARE @dummy INT;
DECLARE @iteracion INT = 1;

-- ---------------- ESCENARIO 1: SIN INDICES (DISABLE) ----------------
PRINT '';
PRINT '>> Escenario SIN indices: deshabilitando indices del Sprint 3...';
ALTER INDEX IX_Matriculas_PeriodoEstado  ON core.Matriculas  DISABLE;
ALTER INDEX IX_Matriculas_PromotorPeriodo ON core.Matriculas  DISABLE;
ALTER INDEX IX_Comisiones_Campania       ON sales.Comisiones DISABLE;
PRINT '>> Indices deshabilitados.';
PRINT '>> Ejecutando 3 iteraciones con SET STATISTICS IO/TIME ON (ver mensajes)...';
GO

SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

DECLARE @t1 DATETIME2, @t2 DATETIME2;
DECLARE @dummy INT;
DECLARE @iteracion INT = 1;

WHILE @iteracion <= 3
BEGIN
    DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS;

    -- Q1: dashboard - matriculas por periodo y estado
    SET @t1 = SYSDATETIME();
    SELECT @dummy = COUNT(*) FROM (
        SELECT m.PeriodoId, m.EstadoMatricula, COUNT(*) Total, SUM(m.MontoMatricula) Monto
        FROM core.Matriculas m
        WHERE m.DeletedAt IS NULL
        GROUP BY m.PeriodoId, m.EstadoMatricula
    ) t1;
    SET @t2 = SYSDATETIME();
    INSERT INTO #ResultadosParteA VALUES ('SIN_INDICE', 'Q1 Dashboard periodo/estado', DATEDIFF(MICROSECOND, @t1, @t2) / 1000.0);

    -- Q2: ranking de promotores por periodo (ventana)
    SET @t1 = SYSDATETIME();
    SELECT @dummy = COUNT(*) FROM (
        SELECT pr.CodigoPromotor, RANK() OVER (PARTITION BY m.PeriodoId ORDER BY SUM(co.MontoTotal) DESC) R
        FROM sales.Promotores pr
        INNER JOIN core.Matriculas m ON m.PromotorId = pr.PromotorId AND m.DeletedAt IS NULL
        INNER JOIN sales.Comisiones co ON co.MatriculaId = m.MatriculaId AND co.EstadoPago <> 'Anulada'
        GROUP BY pr.CodigoPromotor, m.PeriodoId, pr.PromotorId
    ) t2;
    SET @t2 = SYSDATETIME();
    INSERT INTO #ResultadosParteA VALUES ('SIN_INDICE', 'Q2 Ranking promotores', DATEDIFF(MICROSECOND, @t1, @t2) / 1000.0);

    -- Q3: comisiones por campana y estado
    SET @t1 = SYSDATETIME();
    SELECT @dummy = COUNT(*) FROM (
        SELECT co.CampaniaId, co.EstadoPago, COUNT(*) Total, SUM(co.MontoTotal) Monto
        FROM sales.Comisiones co
        GROUP BY co.CampaniaId, co.EstadoPago
    ) t3;
    SET @t2 = SYSDATETIME();
    INSERT INTO #ResultadosParteA VALUES ('SIN_INDICE', 'Q3 Comisiones campana', DATEDIFF(MICROSECOND, @t1, @t2) / 1000.0);

    SET @iteracion = @iteracion + 1;
END
GO

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

-- ---------------- ESCENARIO 2: CON INDICES (REBUILD) ----------------
PRINT '';
PRINT '>> Escenario CON indices: rehabilitando indices del Sprint 3...';
ALTER INDEX IX_Matriculas_PeriodoEstado   ON core.Matriculas  REBUILD;
ALTER INDEX IX_Matriculas_PromotorPeriodo ON core.Matriculas  REBUILD;
ALTER INDEX IX_Comisiones_Campania        ON sales.Comisiones REBUILD;
PRINT '>> Indices rehabilitados.';
PRINT '>> Ejecutando 3 iteraciones con SET STATISTICS IO/TIME ON (ver mensajes)...';
GO

SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

DECLARE @t1 DATETIME2, @t2 DATETIME2;
DECLARE @dummy INT;
DECLARE @iteracion INT = 1;

WHILE @iteracion <= 3
BEGIN
    DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS;

    -- Q1
    SET @t1 = SYSDATETIME();
    SELECT @dummy = COUNT(*) FROM (
        SELECT m.PeriodoId, m.EstadoMatricula, COUNT(*) Total, SUM(m.MontoMatricula) Monto
        FROM core.Matriculas m
        WHERE m.DeletedAt IS NULL
        GROUP BY m.PeriodoId, m.EstadoMatricula
    ) t1;
    SET @t2 = SYSDATETIME();
    INSERT INTO #ResultadosParteA VALUES ('CON_INDICE', 'Q1 Dashboard periodo/estado', DATEDIFF(MICROSECOND, @t1, @t2) / 1000.0);

    -- Q2
    SET @t1 = SYSDATETIME();
    SELECT @dummy = COUNT(*) FROM (
        SELECT pr.CodigoPromotor, RANK() OVER (PARTITION BY m.PeriodoId ORDER BY SUM(co.MontoTotal) DESC) R
        FROM sales.Promotores pr
        INNER JOIN core.Matriculas m ON m.PromotorId = pr.PromotorId AND m.DeletedAt IS NULL
        INNER JOIN sales.Comisiones co ON co.MatriculaId = m.MatriculaId AND co.EstadoPago <> 'Anulada'
        GROUP BY pr.CodigoPromotor, m.PeriodoId, pr.PromotorId
    ) t2;
    SET @t2 = SYSDATETIME();
    INSERT INTO #ResultadosParteA VALUES ('CON_INDICE', 'Q2 Ranking promotores', DATEDIFF(MICROSECOND, @t1, @t2) / 1000.0);

    -- Q3
    SET @t1 = SYSDATETIME();
    SELECT @dummy = COUNT(*) FROM (
        SELECT co.CampaniaId, co.EstadoPago, COUNT(*) Total, SUM(co.MontoTotal) Monto
        FROM sales.Comisiones co
        GROUP BY co.CampaniaId, co.EstadoPago
    ) t3;
    SET @t2 = SYSDATETIME();
    INSERT INTO #ResultadosParteA VALUES ('CON_INDICE', 'Q3 Comisiones campana', DATEDIFF(MICROSECOND, @t1, @t2) / 1000.0);

    SET @iteracion = @iteracion + 1;
END
GO

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

-- ---------------- TABLA COMPARATIVA PARTE A ----------------
PRINT '';
PRINT '============================================';
PRINT 'RESULTADO PARTE A (promedio de 3 corridas):';
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
FROM #ResultadosParteA
GROUP BY Consulta
ORDER BY Consulta;
GO

DROP TABLE #ResultadosParteA;
GO

-- ============================================================
-- PARTE B: PRUEBA DE ESCALA CON VOLUMEN (1,000,000 filas)
-- ============================================================
PRINT '';
PRINT '============================================';
PRINT 'PARTE B - Prueba de escala (1,000,000 filas)';
PRINT '============================================';
GO

IF OBJECT_ID('dbo.PerfMatriculas') IS NOT NULL
    DROP TABLE dbo.PerfMatriculas;
GO

-- Tabla sintetica que replica la estructura de core.Matriculas
-- (solo las columnas usadas por las consultas criticas)
CREATE TABLE dbo.PerfMatriculas (
    MatriculaId     INT IDENTITY(1,1) NOT NULL,
    PeriodoId       INT NOT NULL,
    PromotorId      INT NOT NULL,
    EstadoMatricula VARCHAR(20) NOT NULL,
    MontoMatricula  DECIMAL(10,2) NOT NULL,
    CampaniaId      INT NULL,
    DeletedAt       DATETIME NULL,
    CONSTRAINT PK_PerfMatriculas PRIMARY KEY (MatriculaId)
);
GO

PRINT 'Insertando 1,000,000 filas sinteticas...';
-- La carga masiva en RECOVERY FULL llenaria el log de transacciones
-- (cap 500MB) sin truncarlo. Se conmuta temporalmente a SIMPLE solo
-- durante la carga (los checkpoints truncaran el log). Tras la carga
-- se restaura FULL y se genera un NUEVO respaldo completo: conmutar
-- de SIMPLE a FULL rompe la cadena de respaldos LOG, por lo que el
-- primer backup posterior a la conmutacion DEBE ser FULL (de lo
-- contrario el job MC360_BackupLog fallaria hasta un nuevo FULL).
ALTER DATABASE MatriculaCloud360DB SET RECOVERY SIMPLE;
GO

;WITH E1(N) AS (SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1
                UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1),
     E2(N) AS (SELECT 1 FROM E1 a CROSS JOIN E1 b),
     E4(N) AS (SELECT 1 FROM E2 a CROSS JOIN E2 b),
     E6(N) AS (SELECT 1 FROM E4 a CROSS JOIN E2 b),
     Num(N) AS (SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) FROM E6)
INSERT INTO dbo.PerfMatriculas (PeriodoId, PromotorId, EstadoMatricula, MontoMatricula, CampaniaId, DeletedAt)
SELECT
    (N % 5) + 1,
    (N % 7) + 1,
    CASE N % 4 WHEN 0 THEN 'Retirada' WHEN 1 THEN 'Suspendida' ELSE 'Activa' END,
    150.00 + (N % 200),
    (N % 5) + 1,
    CASE WHEN N % 20 = 0 THEN GETDATE() ELSE NULL END
FROM Num;
GO

PRINT 'OK: Tabla con 1,000,000 filas creada.';
-- Restaura el modelo de recuperacion FULL (estrategia de respaldo)
ALTER DATABASE MatriculaCloud360DB SET RECOVERY FULL;
GO

PRINT 'Restableciendo la cadena de respaldos: nuevo backup FULL...';
DECLARE @BackupChainPath NVARCHAR(500) =
    '/var/opt/mssql/backup/MatriculaCloud360DB_FULL_Chain_'
    + REPLACE(CONVERT(VARCHAR, GETDATE(), 120), ':', '') + '.bak';
BACKUP DATABASE MatriculaCloud360DB
TO DISK = @BackupChainPath
WITH INIT, COMPRESSION, CHECKSUM;
PRINT 'OK: Nueva cadena de respaldos FULL iniciada.';
GO

-- Tabla temporal de resultados de la Parte B (persiste entre lotes)
CREATE TABLE #ResultadosParteB (
    Escenario  VARCHAR(20),
    DuracionMs DECIMAL(12,3)
);
GO

-- ---------------- CONSULTA SIN INDICE ----------------
PRINT '';
PRINT '>> Consulta SIN indice (scan de toda la tabla):';
PRINT '>> Plan de ejecucion XML (SHOWPLAN) y estadisticas IO/TIME:';
GO

-- Captura el plan de ejecucion estimado (XML) SIN ejecutar la consulta
-- para documentar el analisis: operador esperado = Table Scan (scan
-- completo sobre el clustered index / heap de dbo.PerfMatriculas).
SET SHOWPLAN_XML ON;
GO

SELECT PeriodoId, EstadoMatricula, COUNT(*) AS Total, SUM(MontoMatricula) AS Monto
FROM dbo.PerfMatriculas
WHERE DeletedAt IS NULL
GROUP BY PeriodoId, EstadoMatricula;
GO

SET SHOWPLAN_XML OFF;
GO

SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

DECLARE @t1 DATETIME2 = SYSDATETIME();
DECLARE @dummy BIGINT;
SELECT @dummy = COUNT(*) FROM (
    SELECT PeriodoId, EstadoMatricula, COUNT(*) Total, SUM(MontoMatricula) Monto
    FROM dbo.PerfMatriculas
    WHERE DeletedAt IS NULL
    GROUP BY PeriodoId, EstadoMatricula
) t;
INSERT INTO #ResultadosParteB VALUES ('SIN_INDICE', DATEDIFF(MICROSECOND, @t1, SYSDATETIME()) / 1000.0);
PRINT '>> Duracion SIN indice medida (ver SET STATISTICS TIME).';
GO

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

-- ---------------- CREAR EL INDICE ----------------
PRINT '';
PRINT '>> Creando indice compuesto + filtrado (igual al Sprint 3):';
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Perf_PeriodoEstado' AND object_id = OBJECT_ID('dbo.PerfMatriculas'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_Perf_PeriodoEstado
        ON dbo.PerfMatriculas(PeriodoId, EstadoMatricula)
        INCLUDE (MontoMatricula)
        WHERE DeletedAt IS NULL;
    PRINT 'OK: IX_Perf_PeriodoEstado creado (compuesto + filtrado + cover).';
END
GO

-- ---------------- CONSULTA CON INDICE ----------------
PRINT '';
PRINT '>> Consulta CON indice (seek sobre el indice filtrado):';
PRINT '>> Plan de ejecucion XML (SHOWPLAN) y estadisticas IO/TIME:';
GO

-- Captura el plan estimado CON el indice: el operador esperado pasa
-- de Table Scan a Index Seek (IX_Perf_PeriodoEstado) + Stream
-- Aggregate, con la mitad de lecturas logicas.
SET SHOWPLAN_XML ON;
GO

SELECT PeriodoId, EstadoMatricula, COUNT(*) AS Total, SUM(MontoMatricula) AS Monto
FROM dbo.PerfMatriculas
WHERE DeletedAt IS NULL
GROUP BY PeriodoId, EstadoMatricula;
GO

SET SHOWPLAN_XML OFF;
GO

SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

DECLARE @t1 DATETIME2 = SYSDATETIME();
DECLARE @dummy BIGINT;
SELECT @dummy = COUNT(*) FROM (
    SELECT PeriodoId, EstadoMatricula, COUNT(*) Total, SUM(MontoMatricula) Monto
    FROM dbo.PerfMatriculas
    WHERE DeletedAt IS NULL
    GROUP BY PeriodoId, EstadoMatricula
) t;
INSERT INTO #ResultadosParteB VALUES ('CON_INDICE', DATEDIFF(MICROSECOND, @t1, SYSDATETIME()) / 1000.0);
PRINT '>> Duracion CON indice medida (ver SET STATISTICS TIME).';
GO

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

-- ---------------- COMPARACION PARTE B ----------------
PRINT '';
PRINT '============================================';
PRINT 'RESULTADO PARTE B (1,000,000 filas):';
PRINT '============================================';
GO

SELECT
    Escenario,
    CAST(AVG(DuracionMs) AS DECIMAL(10,3)) AS DuracionMs,
    CAST((SELECT AVG(DuracionMs) FROM #ResultadosParteB WHERE Escenario = 'SIN_INDICE') AS DECIMAL(10,3)) AS Referencia
FROM #ResultadosParteB
GROUP BY Escenario;
GO

PRINT '============================================';
PRINT 'LIMPIANDO TABLA SINTETICA (no afecta datos reales)...';
IF OBJECT_ID('dbo.PerfMatriculas') IS NOT NULL
    DROP TABLE dbo.PerfMatriculas;
DROP TABLE #ResultadosParteB;
PRINT 'OK: dbo.PerfMatriculas eliminada.';
PRINT '============================================';
PRINT 'Los indices del Sprint 3 quedaron HABILITADOS.';
PRINT '============================================';
GO