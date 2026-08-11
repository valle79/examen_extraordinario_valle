-- =============================================
-- Matricula Cloud 360 Enterprise
-- programmability/functions/fn_PeriodoMatriculaHabilitado.sql
-- =============================================
-- Devuelve 1 si el periodo existe, esta activo y la fecha cae dentro
-- de la ventana de matriculas (FechaInicioMatriculas..FechaFinMatriculas).
-- RN-03: la matricula solo se realiza sobre un periodo habilitado.
--
-- IDEMPOTENTE: se crea con CREATE OR ALTER / guardian de existencia.
-- =============================================

USE MatriculaCloud360DB;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'core.fn_PeriodoMatriculaHabilitado', N'FN') IS NULL
    EXEC('CREATE FUNCTION core.fn_PeriodoMatriculaHabilitado(@PeriodoId INT, @Fecha DATETIME) RETURNS BIT AS BEGIN RETURN 0 END');
GO

ALTER FUNCTION core.fn_PeriodoMatriculaHabilitado(@PeriodoId INT, @Fecha DATETIME)
RETURNS BIT
AS
BEGIN
    DECLARE @Habilitado BIT = 0;

    IF EXISTS (SELECT 1 FROM core.PeriodosAcademicos
               WHERE PeriodoId = @PeriodoId
                 AND Activo = 1
                 AND @Fecha >= FechaInicioMatriculas
                 AND @Fecha <= FechaFinMatriculas)
        SET @Habilitado = 1;

    RETURN @Habilitado;
END
GO

PRINT 'OK: core.fn_PeriodoMatriculaHabilitado.';
GO
