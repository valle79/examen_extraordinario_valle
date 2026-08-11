-- =============================================
-- Matricula Cloud 360 Enterprise
-- programmability/functions/fn_TotalMatriculadosCarrera.sql
-- =============================================
-- Devuelve el total de matriculas ACTIVAS de una carrera en un periodo.
-- Indicador para la toma de decisiones (oferta/demanda academica).
--
-- IDEMPOTENTE: se crea con CREATE OR ALTER / guardian de existencia.
-- =============================================

USE MatriculaCloud360DB;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'core.fn_TotalMatriculadosCarrera', N'FN') IS NULL
    EXEC('CREATE FUNCTION core.fn_TotalMatriculadosCarrera(@CarreraId INT, @PeriodoId INT) RETURNS INT AS BEGIN RETURN 0 END');
GO

ALTER FUNCTION core.fn_TotalMatriculadosCarrera(@CarreraId INT, @PeriodoId INT)
RETURNS INT
AS
BEGIN
    DECLARE @Total INT = 0;

    SELECT @Total = COUNT(*)
    FROM core.Matriculas
    WHERE CarreraId = @CarreraId
      AND PeriodoId = @PeriodoId
      AND DeletedAt IS NULL
      AND EstadoMatricula = 'Activa';

    RETURN @Total;
END
GO

PRINT 'OK: core.fn_TotalMatriculadosCarrera.';
GO
