-- =============================================
-- Matricula Cloud 360 Enterprise
-- programmability/views/vw_MatriculasDetalle.sql
-- =============================================
-- Matriculas con toda la informacion relacionada
-- (estudiante, carrera, periodo, sede, promotor, campana).
--
-- IDEMPOTENTE: CREATE OR ALTER VIEW.
-- =============================================

USE MatriculaCloud360DB;
GO

SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER VIEW core.vw_MatriculasDetalle
AS
SELECT
    m.MatriculaId,
    m.CodigoMatricula,
    m.FechaMatricula,
    m.MontoMatricula,
    m.EstadoMatricula,
    m.Observaciones,
    e.EstudianteId,
    e.TipoDocumento,
    e.NumeroDocumento,
    e.Nombres + ' ' + e.Apellidos AS Estudiante,
    c.CarreraId,
    c.NombreCarrera,
    p.PeriodoId,
    p.CodigoPeriodo,
    p.NombrePeriodo,
    s.SedeId,
    s.NombreSede,
    pr.PromotorId,
    pr.Nombres + ' ' + pr.Apellidos AS Promotor,
    ca.CampaniaId,
    ca.NombreCampania,
    ca.PorcentajeComisionBase
FROM core.Matriculas m
INNER JOIN core.Estudiantes e   ON e.EstudianteId = m.EstudianteId
INNER JOIN core.Carreras c      ON c.CarreraId = m.CarreraId
INNER JOIN core.PeriodosAcademicos p ON p.PeriodoId = m.PeriodoId
INNER JOIN core.Sedes s         ON s.SedeId = m.SedeId
INNER JOIN sales.Promotores pr  ON pr.PromotorId = m.PromotorId
LEFT JOIN sales.CampaniasAdmision ca ON ca.CampaniaId = m.CampaniaId
WHERE m.DeletedAt IS NULL;
GO

PRINT 'OK: core.vw_MatriculasDetalle.';
GO
