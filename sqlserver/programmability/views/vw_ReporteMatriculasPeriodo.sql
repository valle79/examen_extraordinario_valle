-- =============================================
-- Matricula Cloud 360 Enterprise
-- programmability/views/vw_ReporteMatriculasPeriodo.sql
-- =============================================
-- Resumen de matriculas por periodo, sede y carrera
-- (conteo y monto total) para la toma de decisiones.
--
-- IDEMPOTENTE: CREATE OR ALTER VIEW.
-- =============================================

USE MatriculaCloud360DB;
GO

SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER VIEW core.vw_ReporteMatriculasPeriodo
AS
SELECT
    p.CodigoPeriodo,
    p.NombrePeriodo,
    s.NombreSede,
    c.NombreCarrera,
    COUNT(m.MatriculaId) AS TotalMatriculas,
    ISNULL(SUM(m.MontoMatricula), 0) AS MontoTotal,
    SUM(CASE WHEN m.EstadoMatricula = 'Activa' THEN 1 ELSE 0 END) AS Activas,
    SUM(CASE WHEN m.EstadoMatricula = 'Retirada' THEN 1 ELSE 0 END) AS Retiradas
FROM core.PeriodosAcademicos p
CROSS JOIN core.Sedes s
CROSS JOIN core.Carreras c
LEFT JOIN core.Matriculas m
       ON m.PeriodoId = p.PeriodoId
      AND m.SedeId = s.SedeId
      AND m.CarreraId = c.CarreraId
      AND m.DeletedAt IS NULL
GROUP BY p.CodigoPeriodo, p.NombrePeriodo, s.NombreSede, c.NombreCarrera;
GO

PRINT 'OK: core.vw_ReporteMatriculasPeriodo.';
GO
