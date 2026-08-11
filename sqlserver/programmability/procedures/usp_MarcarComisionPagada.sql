-- =============================================
-- Matricula Cloud 360 Enterprise
-- programmability/procedures/usp_MarcarComisionPagada.sql
-- =============================================
-- Marca una comision como Pagada registrando la fecha de pago.
--
-- IDEMPOTENTE: CREATE OR ALTER PROCEDURE.
-- =============================================

USE MatriculaCloud360DB;
GO

SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE sales.usp_MarcarComisionPagada
    @ComisionId INT,
    @ErrorMsg NVARCHAR(500) = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM sales.Comisiones WHERE ComisionId = @ComisionId)
            THROW 53001, 'La comision indicada no existe.', 1;

        IF EXISTS (SELECT 1 FROM sales.Comisiones
                   WHERE ComisionId = @ComisionId AND EstadoPago = 'Anulada')
            THROW 53002, 'No se puede pagar una comision anulada.', 1;

        UPDATE sales.Comisiones
        SET EstadoPago = 'Pagada',
            FechaPago = GETDATE()
        WHERE ComisionId = @ComisionId;

        SET @ErrorMsg = NULL;
    END TRY
    BEGIN CATCH
        SET @ErrorMsg = ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

PRINT 'OK: sales.usp_MarcarComisionPagada.';
GO
