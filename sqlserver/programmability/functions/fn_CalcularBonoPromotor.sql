-- =============================================
-- Matricula Cloud 360 Enterprise
-- programmability/functions/fn_CalcularBonoPromotor.sql
-- =============================================
-- Calcula el bono del promotor si alcanzo la meta de la campana
-- (RN-09): si el numero de matriculas activas del promotor en la
-- campana es >= MetaMatriculas, devuelve BonoPorMeta; si no, 0.
--
-- IDEMPOTENTE: se crea con CREATE OR ALTER / guardian de existencia.
-- =============================================

USE MatriculaCloud360DB;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'sales.fn_CalcularBonoPromotor', N'FN') IS NULL
    EXEC('CREATE FUNCTION sales.fn_CalcularBonoPromotor(@PromotorId INT, @CampaniaId INT) RETURNS DECIMAL(10,2) AS BEGIN RETURN 0 END');
GO

ALTER FUNCTION sales.fn_CalcularBonoPromotor(@PromotorId INT, @CampaniaId INT)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @Bono DECIMAL(10,2) = 0;

    SELECT @Bono = CASE
        WHEN MetaMatriculas IS NOT NULL AND BonoPorMeta IS NOT NULL
             AND (SELECT COUNT(*) FROM core.Matriculas m
                  WHERE m.PromotorId = @PromotorId
                    AND m.CampaniaId = @CampaniaId
                    AND m.DeletedAt IS NULL
                    AND m.EstadoMatricula = 'Activa') >= MetaMatriculas
        THEN BonoPorMeta
        ELSE 0 END
    FROM sales.CampaniasAdmision
    WHERE CampaniaId = @CampaniaId
      AND Activo = 1;

    RETURN ISNULL(@Bono, 0);
END
GO

PRINT 'OK: sales.fn_CalcularBonoPromotor.';
GO
