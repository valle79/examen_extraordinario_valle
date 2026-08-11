-- =============================================
-- Matricula Cloud 360 Enterprise
-- programmability/functions/fn_ExisteEstudianteConDocumento.sql
-- =============================================
-- Devuelve 1 si ya existe un estudiante con el mismo documento
-- (RN-01). El parametro @ExcluirEstudianteId permite ignorar al
-- propio estudiante al validar una actualizacion.
--
-- IDEMPOTENTE: se crea con CREATE OR ALTER / guardian de existencia.
-- =============================================

USE MatriculaCloud360DB;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'core.fn_ExisteEstudianteConDocumento', N'FN') IS NULL
    EXEC('CREATE FUNCTION core.fn_ExisteEstudianteConDocumento(@TipoDocumento CHAR(3), @NumeroDocumento VARCHAR(15), @ExcluirEstudianteId INT) RETURNS BIT AS BEGIN RETURN 0 END');
GO

ALTER FUNCTION core.fn_ExisteEstudianteConDocumento(@TipoDocumento CHAR(3), @NumeroDocumento VARCHAR(15), @ExcluirEstudianteId INT)
RETURNS BIT
AS
BEGIN
    DECLARE @Existe BIT = 0;

    IF EXISTS (SELECT 1 FROM core.Estudiantes
               WHERE TipoDocumento = @TipoDocumento
                 AND NumeroDocumento = @NumeroDocumento
                 AND EstudianteId <> ISNULL(@ExcluirEstudianteId, -1))
        SET @Existe = 1;

    RETURN @Existe;
END
GO

PRINT 'OK: core.fn_ExisteEstudianteConDocumento.';
GO
