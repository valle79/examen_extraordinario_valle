-- =============================================
-- Matricula Cloud 360 Enterprise
-- programmability/triggers/trg_Audit_Promotores.sql
-- =============================================
-- Auditoria (RN-07): registra cada INSERT/UPDATE/DELETE sobre
-- sales.Promotores en audit.AuditLog con usuario, fecha, hora,
-- operacion, valores anteriores/nuevos (JSON) e IP.
--
-- IDEMPOTENTE: se crea solo si no existe.
-- =============================================

USE MatriculaCloud360DB;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'sales.TRG_Audit_Promotores', N'TR') IS NULL
BEGIN
    EXEC('
    CREATE TRIGGER sales.TRG_Audit_Promotores
    ON sales.Promotores
    AFTER INSERT, UPDATE, DELETE
    AS
    BEGIN
        SET NOCOUNT ON;
        DECLARE @Operation CHAR(6);

        IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
            SET @Operation = ''UPDATE'';
        ELSE IF EXISTS (SELECT 1 FROM inserted)
            SET @Operation = ''INSERT'';
        ELSE
            SET @Operation = ''DELETE'';

        IF @Operation IN (''INSERT'', ''UPDATE'')
        BEGIN
            INSERT INTO audit.AuditLog (TableName, Operation, RecordId, Usuario, FechaOperacion, ValoresAnteriores, ValoresNuevos, DireccionIP)
            SELECT ''sales.Promotores'', @Operation, i.PromotorId, SUSER_SNAME(), GETDATE(),
                   CASE WHEN @Operation = ''UPDATE''
                        THEN (SELECT d.* FROM deleted d WHERE d.PromotorId = i.PromotorId
                              FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
                        ELSE NULL END,
                   (SELECT x.* FROM inserted x WHERE x.PromotorId = i.PromotorId
                    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
                   CONVERT(VARCHAR(45), CONNECTIONPROPERTY(''client_net_address''))
            FROM inserted i;
        END

        IF @Operation = ''DELETE''
        BEGIN
            INSERT INTO audit.AuditLog (TableName, Operation, RecordId, Usuario, FechaOperacion, ValoresAnteriores, ValoresNuevos, DireccionIP)
            SELECT ''sales.Promotores'', @Operation, d.PromotorId, SUSER_SNAME(), GETDATE(),
                   (SELECT x.* FROM deleted x WHERE x.PromotorId = d.PromotorId
                    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
                   NULL,
                   CONVERT(VARCHAR(45), CONNECTIONPROPERTY(''client_net_address''))
            FROM deleted d;
        END
    END');
    PRINT 'OK: Trigger sales.TRG_Audit_Promotores creado.';
END
ELSE
    PRINT 'OK: sales.TRG_Audit_Promotores ya existe.';
GO
