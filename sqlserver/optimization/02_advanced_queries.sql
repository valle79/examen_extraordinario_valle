-- =============================================
-- Matricula Cloud 360 Enterprise
-- optimization/02_advanced_queries.sql | Consultas avanzadas
-- =============================================
-- Descripcion (Sprint 3): Consultas analiticas avanzadas que
-- transforman los datos operativos en INFORMACION PARA LA TOMA DE
-- DECISIONES, utilizando:
--   - CTE (Common Table Expressions) y CTE recursivas
--   - Funciones de ventana (ROW_NUMBER, RANK, DENSE_RANK, LAG,
--     SUM/COUNT OVER) para rankings, comparaciones y acumulados
--   - Funciones agregadas con GROUP BY y ROLLUP
--   - Funciones de fecha, texto y condicionales
--
-- Este script ES SOLO DE LECTURA: no modifica datos.
-- =============================================

USE MatriculaCloud360DB;
GO

SET NOCOUNT ON;
GO

PRINT '============================================';
PRINT 'optimization/02_advanced_queries.sql';
PRINT 'Consultas analiticas avanzadas';
PRINT '============================================';
GO

-- ============================================================
-- Q1. INDICADOR: MATRICULAS POR PERIODO, CARRERA Y SEDE (CTE + GROUP BY ROLLUP)
-- Muestra el total de matriculas activas y el monto recaudado con
-- subtotales por periodo (ROLLUP) y el total general. GROUPING()
-- identifica las filas de subtotal/total para rotularlas.
-- ============================================================
PRINT '';
PRINT 'Q1. Matriculas por periodo/carrera/sede (CTE + ROLLUP):';
PRINT '-------------------------------------------------------';
GO

WITH MatriculasResumen AS
(
    SELECT
        CASE WHEN GROUPING(p.CodigoPeriodo) = 1 THEN '** TOTAL GENERAL **' ELSE p.CodigoPeriodo END AS CodigoPeriodo,
        CASE WHEN GROUPING(c.NombreCarrera) = 1 THEN '** SUBTOTAL **' ELSE c.NombreCarrera END     AS NombreCarrera,
        CASE WHEN GROUPING(s.NombreSede)   = 1 THEN '** TODAS LAS SEDES **' ELSE s.NombreSede END  AS NombreSede,
        GROUPING(p.CodigoPeriodo) AS EsTotal,
        COUNT(*)                                  AS TotalMatriculas,
        SUM(m.MontoMatricula)                     AS MontoRecaudado,
        AVG(m.MontoMatricula)                     AS PromedioMonto
    FROM core.Matriculas m
    INNER JOIN core.PeriodosAcademicos p ON p.PeriodoId = m.PeriodoId
    INNER JOIN core.Carreras c           ON c.CarreraId = m.CarreraId
    INNER JOIN core.Sedes s              ON s.SedeId = m.SedeId
    WHERE m.DeletedAt IS NULL
    GROUP BY ROLLUP (p.CodigoPeriodo, c.NombreCarrera, s.NombreSede)
)
SELECT
    CodigoPeriodo,
    NombreCarrera,
    NombreSede,
    TotalMatriculas,
    MontoRecaudado,
    PromedioMonto
FROM MatriculasResumen
ORDER BY EsTotal, CodigoPeriodo, TotalMatriculas DESC;
GO

-- ============================================================
-- Q2. INDICADOR: RANKING DE PROMOTORES POR PERIODO (CTE + RANK/DENSE_RANK)
-- Clasifica a los promotores segun el monto comisionado en cada
-- periodo, usando funciones de ventana.
-- ============================================================
PRINT '';
PRINT 'Q2. Ranking de promotores por periodo (RANK / DENSE_RANK):';
PRINT '---------------------------------------------------------';
GO

WITH RankingPromotores AS
(
    SELECT
        p.CodigoPeriodo,
        pr.CodigoPromotor,
        pr.Nombres + ' ' + pr.Apellidos AS Promotor,
        COUNT(m.MatriculaId)             AS MatriculasCaptadas,
        SUM(co.MontoTotal)               AS ComisionTotal,
        RANK()       OVER (PARTITION BY p.PeriodoId ORDER BY SUM(co.MontoTotal) DESC) AS Ranking,
        DENSE_RANK() OVER (PARTITION BY p.PeriodoId ORDER BY SUM(co.MontoTotal) DESC) AS RankingDenso
    FROM sales.Promotores pr
    INNER JOIN core.Matriculas m ON m.PromotorId = pr.PromotorId AND m.DeletedAt IS NULL
    INNER JOIN sales.Comisiones co ON co.MatriculaId = m.MatriculaId
    INNER JOIN core.PeriodosAcademicos p ON p.PeriodoId = m.PeriodoId
    WHERE co.EstadoPago <> 'Anulada'
    GROUP BY p.PeriodoId, p.CodigoPeriodo, pr.PromotorId, pr.CodigoPromotor, pr.Nombres, pr.Apellidos
)
SELECT
    CodigoPeriodo,
    Promotor,
    MatriculasCaptadas,
    ComisionTotal,
    Ranking,
    RankingDenso
FROM RankingPromotores
ORDER BY CodigoPeriodo, Ranking;
GO

-- ============================================================
-- Q3. INDICADOR: CRECIMIENTO INTERPERIODO DE MATRICULAS (CTE + LAG)
-- Compara las matriculas de cada periodo con el periodo anterior
-- usando LAG() y calcula la variacion porcentual.
-- ============================================================
PRINT '';
PRINT 'Q3. Crecimiento interperiodo de matriculas (LAG):';
PRINT '-------------------------------------------------';
GO

WITH MatriculasPorPeriodo AS
(
    SELECT
        p.PeriodoId,
        p.CodigoPeriodo,
        COUNT(*) AS TotalMatriculas,
        SUM(m.MontoMatricula) AS MontoRecaudado
    FROM core.Matriculas m
    INNER JOIN core.PeriodosAcademicos p ON p.PeriodoId = m.PeriodoId
    WHERE m.DeletedAt IS NULL
    GROUP BY p.PeriodoId, p.CodigoPeriodo
)
SELECT
    CodigoPeriodo,
    TotalMatriculas,
    MontoRecaudado,
    LAG(TotalMatriculas) OVER (ORDER BY PeriodoId) AS MatriculasPeriodoAnterior,
    CASE
        WHEN LAG(TotalMatriculas) OVER (ORDER BY PeriodoId) IS NULL THEN NULL
        ELSE (TotalMatriculas - LAG(TotalMatriculas) OVER (ORDER BY PeriodoId)) * 100.0
             / LAG(TotalMatriculas) OVER (ORDER BY PeriodoId)
    END AS VariacionPorcentual
FROM MatriculasPorPeriodo
ORDER BY PeriodoId;
GO

-- ============================================================
-- Q4. INDICADOR: ACUMULADO DE MATRICULAS EN EL TIEMPO (SUM OVER)
-- Muestra el acumulado (running total) de matriculas y montos
-- ordenado por fecha de matricula, util para ver el avance de la
-- campana de admision.
-- ============================================================
PRINT '';
PRINT 'Q4. Acumulado de matriculas en el tiempo (SUM OVER):';
PRINT '----------------------------------------------------';
GO

SELECT
    m.FechaMatricula,
    m.CodigoMatricula,
    m.MontoMatricula,
    SUM(1)            OVER (ORDER BY m.FechaMatricula, m.MatriculaId)  AS AcumuladoMatriculas,
    SUM(m.MontoMatricula) OVER (ORDER BY m.FechaMatricula, m.MatriculaId) AS AcumuladoMonto
FROM core.Matriculas m
WHERE m.DeletedAt IS NULL
ORDER BY m.FechaMatricula, m.MatriculaId;
GO

-- ============================================================
-- Q5. INDICADOR: TOP 3 CARRERAS POR PERIODO (CTE + ROW_NUMBER)
-- Muestra las 3 carreras con mas matriculas por periodo.
-- ============================================================
PRINT '';
PRINT 'Q5. Top 3 carreras por periodo (ROW_NUMBER):';
PRINT '--------------------------------------------';
GO

WITH DemandaCarrera AS
(
    SELECT
        p.CodigoPeriodo,
        c.NombreCarrera,
        COUNT(*) AS TotalMatriculas,
        ROW_NUMBER() OVER (PARTITION BY p.PeriodoId ORDER BY COUNT(*) DESC) AS Posicion
    FROM core.Matriculas m
    INNER JOIN core.PeriodosAcademicos p ON p.PeriodoId = m.PeriodoId
    INNER JOIN core.Carreras c           ON c.CarreraId = m.CarreraId
    WHERE m.DeletedAt IS NULL
    GROUP BY p.PeriodoId, p.CodigoPeriodo, c.CarreraId, c.NombreCarrera
)
SELECT CodigoPeriodo, NombreCarrera, TotalMatriculas, Posicion
FROM DemandaCarrera
WHERE Posicion <= 3
ORDER BY CodigoPeriodo, Posicion;
GO

-- ============================================================
-- Q6. INDICADOR: DESEMPEÑO DE CAMPANAS (CTE + agregados + % participacion)
-- Analisis de conversion de las campanas de admision: matriculas
-- logradas vs meta, porcentaje de avance y monto comisionado.
-- ============================================================
PRINT '';
PRINT 'Q6. Desempeno de campanas (meta vs logrado):';
PRINT '---------------------------------------------';
GO

WITH ResumenCampanias AS
(
    SELECT
        ca.CampaniaId,
        ca.NombreCampania,
        ca.MetaMatriculas,
        ca.BonoPorMeta,
        COUNT(m.MatriculaId) AS MatriculasLogradas,
        SUM(m.MontoMatricula) AS MontoGenerado,
        SUM(co.MontoTotal)    AS ComisionGenerada
    FROM sales.CampaniasAdmision ca
    INNER JOIN core.Matriculas m  ON m.CampaniaId = ca.CampaniaId AND m.DeletedAt IS NULL
    INNER JOIN sales.Comisiones co ON co.MatriculaId = m.MatriculaId AND co.EstadoPago <> 'Anulada'
    GROUP BY ca.CampaniaId, ca.NombreCampania, ca.MetaMatriculas, ca.BonoPorMeta
)
SELECT
    NombreCampania,
    MetaMatriculas,
    MatriculasLogradas,
    CASE
        WHEN MetaMatriculas > 0 THEN CAST(MatriculasLogradas * 100.0 / MetaMatriculas AS DECIMAL(5,1))
        ELSE 0
    END AS PorcentajeAvance,
    MontoGenerado,
    ComisionGenerada,
    CASE WHEN MatriculasLogradas >= MetaMatriculas AND MetaMatriculas > 0 THEN 'META CUMPLIDA' ELSE 'EN PROCESO' END AS EstadoMeta
FROM ResumenCampanias
ORDER BY PorcentajeAvance DESC;
GO

-- ============================================================
-- Q7. INDICADOR: PERFIL DEL ESTUDIANTE (edad, genero, procedencia)
-- Funciones agregadas + CASE para construir el perfil demografico.
-- ============================================================
PRINT '';
PRINT 'Q7. Perfil demografico de los estudiantes:';
PRINT '-----------------------------------------';
GO

SELECT
    CASE core.fn_EdadEstudiante(e.EstudianteId)
        WHEN 0 THEN 'Menor de 1 anio'
        ELSE CASE
            WHEN core.fn_EdadEstudiante(e.EstudianteId) BETWEEN 16 AND 20 THEN '16-20 anios'
            WHEN core.fn_EdadEstudiante(e.EstudianteId) BETWEEN 21 AND 25 THEN '21-25 anios'
            WHEN core.fn_EdadEstudiante(e.EstudianteId) BETWEEN 26 AND 30 THEN '26-30 anios'
            ELSE 'Mas de 30 anios'
        END
    END AS RangoEdad,
    e.Genero,
    COUNT(*) AS TotalEstudiantes
FROM core.Estudiantes e
WHERE e.DeletedAt IS NULL
GROUP BY core.fn_EdadEstudiante(e.EstudianteId), e.Genero
ORDER BY RangoEdad, e.Genero;
GO

-- ============================================================
-- Q8. INDICADOR: EFICIENCIA DE COMISIONES (CTE + ventanas + agregados)
-- Promedio movil del monto comisionado y comisiones pendientes de
-- pago por promotor (decision de caja).
-- ============================================================
PRINT '';
PRINT 'Q8. Comisiones pendientes y promedio por promotor:';
PRINT '--------------------------------------------------';
GO

WITH ComisionesPendientes AS
(
    SELECT
        pr.CodigoPromotor,
        pr.Nombres + ' ' + pr.Apellidos AS Promotor,
        co.EstadoPago,
        co.MontoTotal,
        co.FechaPago
    FROM sales.Comisiones co
    INNER JOIN sales.Promotores pr ON pr.PromotorId = co.PromotorId
    WHERE co.EstadoPago = 'Pendiente'
)
SELECT
    CodigoPromotor,
    Promotor,
    COUNT(*)                              AS ComisionesPendientes,
    SUM(MontoTotal)                       AS MontoPendienteTotal,
    AVG(MontoTotal)                       AS MontoPromedio,
    MAX(MontoTotal)                       AS ComisionMasAlta,
    SUM(SUM(MontoTotal)) OVER (ORDER BY CodigoPromotor ROWS UNBOUNDED PRECEDING) AS AcumuladoGeneral
FROM ComisionesPendientes
GROUP BY CodigoPromotor, Promotor
ORDER BY MontoPendienteTotal DESC;
GO

-- ============================================================
-- Q9. INDICADOR: CTE RECURSIVA - Malla curricular por semestre
-- Recorre los semestres de la malla de una carrera sumando creditos
-- (decision: carga academica por semestre).
-- ============================================================
PRINT '';
PRINT 'Q9. Creditos acumulados por semestre (CTE recursiva):';
PRINT '-----------------------------------------------------';
GO

WITH MallaSemestre(CarreraId, Semestre, CreditosSemestre) AS
(
    -- Ancla: semestre 1 de cada carrera
    SELECT cc.CarreraId, MIN(cc.Semestre), 0
    FROM academic.CarreraCursos cc
    GROUP BY cc.CarreraId

    UNION ALL

    -- Paso recursivo: siguiente semestre
    SELECT cc.CarreraId, cc.Semestre, 0
    FROM academic.CarreraCursos cc
    INNER JOIN MallaSemestre ms ON ms.CarreraId = cc.CarreraId AND cc.Semestre = ms.Semestre + 1
)
SELECT
    c.NombreCarrera,
    ms.Semestre,
    (SELECT SUM(cur.Creditos)
     FROM academic.CarreraCursos cc2
     INNER JOIN academic.Cursos cur ON cur.CursoId = cc2.CursoId
     WHERE cc2.CarreraId = ms.CarreraId AND cc2.Semestre = ms.Semestre) AS CreditosDelSemestre
FROM MallaSemestre ms
INNER JOIN core.Carreras c ON c.CarreraId = ms.CarreraId
ORDER BY c.NombreCarrera, ms.Semestre;
GO

-- ============================================================
-- Q10. INDICADOR: MATRICULAS POR HORARIO DE MATRICULA (funciones de fecha)
-- Agrupa por franja horaria para planificar atencion al publico.
-- ============================================================
PRINT '';
PRINT 'Q10. Matriculas por franja horaria:';
PRINT '-----------------------------------';
GO

SELECT
    CASE
        WHEN CONVERT(TIME, m.FechaMatricula) BETWEEN '08:00' AND '11:59' THEN 'Manana (08-12)'
        WHEN CONVERT(TIME, m.FechaMatricula) BETWEEN '12:00' AND '16:59' THEN 'Tarde (12-17)'
        ELSE 'Noche (17-23)'
    END AS FranjaHoraria,
    COUNT(*) AS TotalMatriculas,
    SUM(m.MontoMatricula) AS MontoRecaudado
FROM core.Matriculas m
WHERE m.DeletedAt IS NULL
GROUP BY CASE
    WHEN CONVERT(TIME, m.FechaMatricula) BETWEEN '08:00' AND '11:59' THEN 'Manana (08-12)'
    WHEN CONVERT(TIME, m.FechaMatricula) BETWEEN '12:00' AND '16:59' THEN 'Tarde (12-17)'
    ELSE 'Noche (17-23)'
END
ORDER BY TotalMatriculas DESC;
GO

PRINT '';
PRINT '============================================';
PRINT '02_advanced_queries.sql finalizado.';
PRINT '============================================';
GO