-- =============================================
-- Matricula Cloud 360 Enterprise
-- programmability/triggers/trg_Comision_Automatica.sql
-- =============================================
-- Comision automatica (RN-09):
--   - Al INSERTAR una matricula genera automaticamente la comision
--     del promotor usando la campana vigente (% + bono por meta).
--   - Al ACTUALIZAR el monto o el estado recalcula la comision; si
--     la matricula se retira, la comision pasa a estado Anulada.
--
-- IDEMPOTENTE: se crea solo si no existe.
-- =============================================

USE MatriculaCloud360DB;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'core.TRG_Comision_Automatica', N'TR') IS NULL
BEGIN
    EXEC('
    CREATE TRIGGER core.TRG_Comision_Automatica
    ON core.Matriculas
    AFTER INSERT, UPDATE
    AS
    BEGIN
        SET NOCOUNT ON;

        -- 1) Matriculas nuevas: crear la comision automaticamente.
        INSERT INTO sales.Comisiones
            (PromotorId, MatriculaId, CampaniaId, MontoBase, PorcentajeComision,
             MontoComision, Bonificacion, MontoTotal, EstadoPago)
        SELECT
            m.PromotorId,
            m.MatriculaId,
            m.CampaniaId,
            m.MontoMatricula,
            COALESCE(c.PorcentajeComisionBase, 0),
            sales.fn_CalcularComision(m.PromotorId, m.CampaniaId, m.MontoMatricula),
            sales.fn_CalcularBonoPromotor(m.PromotorId, m.CampaniaId),
            sales.fn_CalcularComision(m.PromotorId, m.CampaniaId, m.MontoMatricula)
                + sales.fn_CalcularBonoPromotor(m.PromotorId, m.CampaniaId),
            ''Pendiente''
        FROM inserted m
        LEFT JOIN sales.CampaniasAdmision c ON c.CampaniaId = m.CampaniaId
        WHERE NOT EXISTS (SELECT 1 FROM sales.Comisiones x WHERE x.MatriculaId = m.MatriculaId);

        -- 2) Actualizaciones: recalcular si cambio el monto o el estado.
        IF UPDATE(MontoMatricula) OR UPDATE(EstadoMatricula)
        BEGIN
            UPDATE co
            SET co.MontoBase        = m.MontoMatricula,
                co.PorcentajeComision = COALESCE(c.PorcentajeComisionBase, co.PorcentajeComision),
                co.MontoComision    = sales.fn_CalcularComision(m.PromotorId, m.CampaniaId, m.MontoMatricula),
                co.Bonificacion     = sales.fn_CalcularBonoPromotor(m.PromotorId, m.CampaniaId),
                co.MontoTotal       = sales.fn_CalcularComision(m.PromotorId, m.CampaniaId, m.MontoMatricula)
                                      + sales.fn_CalcularBonoPromotor(m.PromotorId, m.CampaniaId),
                co.EstadoPago       = CASE WHEN m.EstadoMatricula = ''Retirada'' THEN ''Anulada''
                                           ELSE co.EstadoPago END,
                co.FechaPago        = CASE WHEN m.EstadoMatricula = ''Retirada'' AND co.EstadoPago <> ''Pagada'' THEN NULL
                                           ELSE co.FechaPago END
            FROM sales.Comisiones co
            INNER JOIN inserted m ON m.MatriculaId = co.MatriculaId
            LEFT JOIN sales.CampaniasAdmision c ON c.CampaniaId = m.CampaniaId;
        END
    END');
    PRINT 'OK: Trigger core.TRG_Comision_Automatica creado.';
END
ELSE
    PRINT 'OK: core.TRG_Comision_Automatica ya existe.';
GO
