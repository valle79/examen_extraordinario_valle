-- =============================================
-- Matricula Cloud 360 Enterprise
-- programmability/views/vw_TendenciaMatriculas.sql
-- =============================================
-- INDICADOR (Sprint 3): tendencia diaria de matriculas con
-- funciones de ventana: suma acumulada (running total) y LAG de
-- un dia para hallar el crecimiento diario.
--
-- IDEMPOTENTE: CREATE OR ALTER VIEW.
-- =============================================

USE MatriculaCloud360DB;
GO

SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER VIEW core.vw_TendenciaMatriculas
AS
WITH MatriculasDiarias AS
(
    SELECT
        CAST(m.FechaMatricula AS DATE)                    AS Fecha,
        COUNT(*)                                          AS MatriculasDelDia,
        SUM(m.MontoMatricula)                             AS MontoDelDia,
        COUNT(DISTINCT m.CampaniaId)                      AS CampaniasActivas
    FROM core.Matriculas m
    WHERE m.DeletedAt IS NULL
    GROUP BY CAST(m.FechaMatricula AS DATE)
)
SELECT
    Fecha,
    MatriculasDelDia,
    MontoDelDia,
    CampaniasActivas,
    SUM(MatriculasDelDia) OVER (ORDER BY Fecha ROWS UNBOUNDED PRECEDING) AS AcumuladoMatriculas,
    SUM(MontoDelDia)      OVER (ORDER BY Fecha ROWS UNBOUNDED PRECEDING) AS AcumuladoMonto,
    LAG(MatriculasDelDia) OVER (ORDER BY Fecha)                          AS MatriculasDiaAnterior,
    CASE
        WHEN LAG(MatriculasDelDia) OVER (ORDER BY Fecha) > 0
        THEN (MatriculasDelDia - LAG(MatriculasDelDia) OVER (ORDER BY Fecha)) * 100.0
             / LAG(MatriculasDelDia) OVER (ORDER BY Fecha)
        ELSE NULL
    END AS CrecimientoDiarioPct
FROM MatriculasDiarias;
GO

PRINT 'OK: core.vw_TendenciaMatriculas.';
GO