-- =============================================
-- Matricula Cloud 360 Enterprise
-- programmability/procedures/usp_ConsultarMatriculas.sql
-- =============================================
-- Consulta de matriculas con filtros opcionales (periodo, sede,
-- promotor y estado). Complementa a core.vw_MatriculasDetalle.
--
-- IDEMPOTENTE: CREATE OR ALTER PROCEDURE.
-- =============================================

USE MatriculaCloud360DB;
GO

SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE core.usp_ConsultarMatriculas
    @PeriodoId INT = NULL,
    @SedeId INT = NULL,
    @PromotorId INT = NULL,
    @EstadoMatricula VARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        m.MatriculaId,
        m.CodigoMatricula,
        e.TipoDocumento,
        e.NumeroDocumento,
        e.Nombres + ' ' + e.Apellidos AS Estudiante,
        c.NombreCarrera,
        p.CodigoPeriodo,
        s.NombreSede,
        pr.CodigoPromotor,
        pr.Nombres + ' ' + pr.Apellidos AS Promotor,
        ca.NombreCampania,
        m.FechaMatricula,
        m.MontoMatricula,
        m.EstadoMatricula
    FROM core.Matriculas m
    INNER JOIN core.Estudiantes e       ON e.EstudianteId = m.EstudianteId
    INNER JOIN core.Carreras c          ON c.CarreraId = m.CarreraId
    INNER JOIN core.PeriodosAcademicos p ON p.PeriodoId = m.PeriodoId
    INNER JOIN core.Sedes s             ON s.SedeId = m.SedeId
    INNER JOIN sales.Promotores pr      ON pr.PromotorId = m.PromotorId
    LEFT JOIN sales.CampaniasAdmision ca ON ca.CampaniaId = m.CampaniaId
    WHERE m.DeletedAt IS NULL
      AND (@PeriodoId IS NULL OR m.PeriodoId = @PeriodoId)
      AND (@SedeId IS NULL OR m.SedeId = @SedeId)
      AND (@PromotorId IS NULL OR m.PromotorId = @PromotorId)
      AND (@EstadoMatricula IS NULL OR m.EstadoMatricula = @EstadoMatricula)
    ORDER BY m.FechaMatricula DESC;
END
GO

PRINT 'OK: core.usp_ConsultarMatriculas.';
GO
