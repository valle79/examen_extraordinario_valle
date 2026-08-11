-- =============================================
-- Matricula Cloud 360 Enterprise
-- programmability/triggers/trg_Audit_Matriculas.sql
-- =============================================
-- Auditoria (RN-07): registra cada INSERT/UPDATE/DELETE sobre
-- core.Matriculas en audit.AuditLog con usuario, fecha, hora,
-- operacion, valores anteriores/nuevos (JSON) e IP.
--
-- IDEMPOTENTE: se crea solo si no existe.
-- =============================================

USE MatriculaCloud360DB;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'core.TRG_Audit_Matriculas', N'TR') IS NULL
BEGIN
    EXEC('
    CREATE TRIGGER core.TRG_Audit_Matriculas
    ON core.Matriculas
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
            SELECT ''core.Matriculas'', @Operation, i.MatriculaId, SUSER_SNAME(), GETDATE(),
                   CASE WHEN @Operation = ''UPDATE''
                        THEN (SELECT d.* FROM deleted d WHERE d.MatriculaId = i.MatriculaId
                              FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
                        ELSE NULL END,
                   (SELECT x.* FROM inserted x WHERE x.MatriculaId = i.MatriculaId
                    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
                   CONVERT(VARCHAR(45), CONNECTIONPROPERTY(''client_net_address''))
            FROM inserted i;
        END

        IF @Operation = ''DELETE''
        BEGIN
            INSERT INTO audit.AuditLog (TableName, Operation, RecordId, Usuario, FechaOperacion, ValoresAnteriores, ValoresNuevos, DireccionIP)
            SELECT ''core.Matriculas'', @Operation, d.MatriculaId, SUSER_SNAME(), GETDATE(),
                   (SELECT x.* FROM deleted x WHERE x.MatriculaId = d.MatriculaId
                    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
                   NULL,
                   CONVERT(VARCHAR(45), CONNECTIONPROPERTY(''client_net_address''))
            FROM deleted d;
        END
    END');
    PRINT 'OK: Trigger core.TRG_Audit_Matriculas creado.';
END
ELSE
    PRINT 'OK: core.TRG_Audit_Matriculas ya existe.';
GO
