-- =============================================
-- Matricula Cloud 360 Enterprise
-- programmability/procedures/usp_EliminarMatriculaLogico.sql
-- =============================================
-- Borrado logico (RN-10): marca la matricula como inactiva con
-- DeletedAt (fecha y hora exacta del suceso).
--
-- IDEMPOTENTE: CREATE OR ALTER PROCEDURE.
-- =============================================

USE MatriculaCloud360DB;
GO

SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE core.usp_EliminarMatriculaLogico
    @MatriculaId INT,
    @ErrorMsg NVARCHAR(500) = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM core.Matriculas
                       WHERE MatriculaId = @MatriculaId AND DeletedAt IS NULL)
            THROW 52009, 'La matricula indicada no existe o ya fue eliminada.', 1;

        UPDATE core.Matriculas
        SET Activo = 0,
            DeletedAt = GETDATE(),
            UpdatedAt = GETDATE()
        WHERE MatriculaId = @MatriculaId;

        SET @ErrorMsg = NULL;
    END TRY
    BEGIN CATCH
        SET @ErrorMsg = ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

PRINT 'OK: core.usp_EliminarMatriculaLogico.';
GO
