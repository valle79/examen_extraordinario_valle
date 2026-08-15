-- =============================================
-- Matricula Cloud 360 Enterprise
-- programmability/views/vw_RankingPromotores.sql
-- =============================================
-- INDICADOR (Sprint 3): ranking de promotores por periodo usando
-- funciones de ventana (RANK, DENSE_RANK, ROW_NUMBER) y LAG para
-- comparar el desempeno respecto al periodo anterior.
--
-- IDEMPOTENTE: CREATE OR ALTER VIEW.
-- =============================================

USE MatriculaCloud360DB;
GO

SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER VIEW sales.vw_RankingPromotores
AS
WITH DesempenoPromotor AS
(
    SELECT
        p.PeriodoId,
        p.CodigoPeriodo,
        pr.PromotorId,
        pr.CodigoPromotor,
        pr.Nombres + ' ' + pr.Apellidos AS NombrePromotor,
        s.NombreSede,
        COUNT(m.MatriculaId)                            AS MatriculasCaptadas,
        SUM(m.MontoMatricula)                           AS MontoGenerado,
        SUM(co.MontoTotal)                              AS ComisionTotal
    FROM core.Matriculas m
    INNER JOIN core.PeriodosAcademicos p ON p.PeriodoId = m.PeriodoId
    INNER JOIN sales.Promotores pr       ON pr.PromotorId = m.PromotorId
    INNER JOIN core.Sedes s              ON s.SedeId = m.SedeId
    LEFT JOIN sales.Comisiones co        ON co.MatriculaId = m.MatriculaId
    WHERE m.DeletedAt IS NULL
      AND (co.EstadoPago IS NULL OR co.EstadoPago <> 'Anulada')
    GROUP BY p.PeriodoId, p.CodigoPeriodo, pr.PromotorId, pr.CodigoPromotor,
             pr.Nombres, pr.Apellidos, s.NombreSede
)
SELECT
    PeriodoId,
    CodigoPeriodo,
    PromotorId,
    CodigoPromotor,
    NombrePromotor,
    NombreSede,
    MatriculasCaptadas,
    MontoGenerado,
    ComisionTotal,
    ROW_NUMBER() OVER (PARTITION BY PeriodoId ORDER BY ComisionTotal DESC, MatriculasCaptadas DESC) AS Posicion,
    RANK()       OVER (PARTITION BY PeriodoId ORDER BY ComisionTotal DESC)                          AS Ranking,
    DENSE_RANK() OVER (PARTITION BY PeriodoId ORDER BY ComisionTotal DESC)                         AS RankingDenso,
    LAG(ComisionTotal) OVER (PARTITION BY PromotorId ORDER BY PeriodoId)                           AS ComisionPeriodoAnterior,
    CASE
        WHEN LAG(ComisionTotal) OVER (PARTITION BY PromotorId ORDER BY PeriodoId) > 0
        THEN (ComisionTotal - LAG(ComisionTotal) OVER (PARTITION BY PromotorId ORDER BY PeriodoId)) * 100.0
             / LAG(ComisionTotal) OVER (PARTITION BY PromotorId ORDER BY PeriodoId)
        ELSE NULL
    END AS VariacionComisionPct
FROM DesempenoPromotor;
GO

PRINT 'OK: sales.vw_RankingPromotores.';
GO