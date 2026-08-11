-- =============================================
-- Matricula Cloud 360 Enterprise
-- programmability/procedures/usp_RetirarMatricula.sql
-- =============================================
-- Cambia el estado de una matricula a Retirada. El trigger de
-- comisiones anula automaticamente la comision asociada (RN-09).
--
-- IDEMPOTENTE: CREATE OR ALTER PROCEDURE.
-- =============================================

USE MatriculaCloud360DB;
GO

SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE core.usp_RetirarMatricula
    @MatriculaId INT,
    @Motivo NVARCHAR(500) = NULL,
    @ErrorMsg NVARCHAR(500) = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM core.Matriculas
                       WHERE MatriculaId = @MatriculaId AND DeletedAt IS NULL)
            THROW 52008, 'La matricula indicada no existe.', 1;

        UPDATE core.Matriculas
        SET EstadoMatricula = 'Retirada',
            Observaciones = ISNULL(@Motivo, Observaciones),
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

PRINT 'OK: core.usp_RetirarMatricula.';
GO
