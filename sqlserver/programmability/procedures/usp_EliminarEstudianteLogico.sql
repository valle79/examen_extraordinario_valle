-- =============================================
-- Matricula Cloud 360 Enterprise
-- programmability/procedures/usp_EliminarEstudianteLogico.sql
-- =============================================
-- Borrado logico (RN-10): no elimina la fila; marca Activo=0 y
-- registra la fecha y hora exacta en DeletedAt.
--
-- IDEMPOTENTE: CREATE OR ALTER PROCEDURE.
-- =============================================

USE MatriculaCloud360DB;
GO

SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE core.usp_EliminarEstudianteLogico
    @EstudianteId INT,
    @ErrorMsg NVARCHAR(500) = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM core.Estudiantes WHERE EstudianteId = @EstudianteId AND DeletedAt IS NULL)
            THROW 51005, 'El estudiante indicado no existe o ya fue eliminado.', 1;

        UPDATE core.Estudiantes
        SET Activo = 0,
            DeletedAt = GETDATE(),
            UpdatedAt = GETDATE()
        WHERE EstudianteId = @EstudianteId;

        SET @ErrorMsg = NULL;
    END TRY
    BEGIN CATCH
        SET @ErrorMsg = ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

PRINT 'OK: core.usp_EliminarEstudianteLogico.';
GO
