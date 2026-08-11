-- =============================================
-- Matricula Cloud 360 Enterprise
-- programmability/functions/fn_EdadEstudiante.sql
-- =============================================
-- Devuelve la edad exacta (en anios) del estudiante.
--
-- IDEMPOTENTE: se crea con CREATE OR ALTER / guardian de existencia.
-- =============================================

USE MatriculaCloud360DB;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'core.fn_EdadEstudiante', N'FN') IS NULL
    EXEC('CREATE FUNCTION core.fn_EdadEstudiante(@EstudianteId INT) RETURNS INT AS BEGIN RETURN 0 END');
GO

ALTER FUNCTION core.fn_EdadEstudiante(@EstudianteId INT)
RETURNS INT
AS
BEGIN
    DECLARE @Edad INT = NULL;

    SELECT @Edad = DATEDIFF(YEAR, FechaNacimiento, GETDATE())
                   - CASE WHEN DATEADD(YEAR, DATEDIFF(YEAR, FechaNacimiento, GETDATE()), FechaNacimiento) > GETDATE()
                          THEN 1 ELSE 0 END
    FROM core.Estudiantes
    WHERE EstudianteId = @EstudianteId;

    RETURN @Edad;
END
GO

PRINT 'OK: core.fn_EdadEstudiante.';
GO
