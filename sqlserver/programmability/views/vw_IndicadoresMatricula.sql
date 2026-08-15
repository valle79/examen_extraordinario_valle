-- =============================================
-- Matricula Cloud 360 Enterprise
-- programmability/views/vw_IndicadoresMatricula.sql
-- =============================================
-- INDICADORES INSTITUCIONALES (Sprint 3): matriculas, carreras,
-- sedes y campanas. Funciones agregadas + ventana para calcular
-- participacion porcentual dentro de cada periodo.
--
-- IDEMPOTENTE: CREATE OR ALTER VIEW.
-- =============================================

USE MatriculaCloud360DB;
GO

SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER VIEW core.vw_IndicadoresMatricula
AS
SELECT
    p.CodigoPeriodo,
    c.NombreCarrera,
    s.NombreSede,
    ca.NombreCampania,
    COUNT(*)                                          AS TotalMatriculas,
    SUM(m.MontoMatricula)                             AS MontoRecaudado,
    AVG(m.MontoMatricula)                             AS MontoPromedio,
    COUNT(DISTINCT e.UbigeoId)                        AS DistritosAtendidos,
    -- Participacion de la carrera dentro del periodo (ventana)
    100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (PARTITION BY m.PeriodoId), 0) AS ParticipacionCarreraPct,
    -- Participacion de la sede dentro del periodo (ventana)
    100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (PARTITION BY m.PeriodoId), 0) AS ParticipacionSedePct
FROM core.Matriculas m
INNER JOIN core.PeriodosAcademicos p  ON p.PeriodoId = m.PeriodoId
INNER JOIN core.Carreras c            ON c.CarreraId = m.CarreraId
INNER JOIN core.Sedes s               ON s.SedeId = m.SedeId
INNER JOIN core.Estudiantes e         ON e.EstudianteId = m.EstudianteId
LEFT JOIN sales.CampaniasAdmision ca  ON ca.CampaniaId = m.CampaniaId
WHERE m.DeletedAt IS NULL
GROUP BY p.CodigoPeriodo, c.NombreCarrera, s.NombreSede, ca.NombreCampania, m.PeriodoId;
GO

PRINT 'OK: core.vw_IndicadoresMatricula.';
GO