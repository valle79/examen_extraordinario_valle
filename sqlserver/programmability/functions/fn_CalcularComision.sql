-- =============================================
-- Matricula Cloud 360 Enterprise
-- programmability/functions/fn_CalcularComision.sql
-- =============================================
-- Calcula la comision de un promotor por una matricula (RN-09):
--   MontoComision = MontoBase x PorcentajeComisionBase(campana) / 100
-- Si la campana no existe o esta inactiva, devuelve 0.
--
-- IDEMPOTENTE: se crea con CREATE OR ALTER / guardian de existencia.
-- =============================================

USE MatriculaCloud360DB;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'sales.fn_CalcularComision', N'FN') IS NULL
    EXEC('CREATE FUNCTION sales.fn_CalcularComision(@PromotorId INT, @CampaniaId INT, @MontoBase DECIMAL(10,2)) RETURNS DECIMAL(10,2) AS BEGIN RETURN 0 END');
GO

ALTER FUNCTION sales.fn_CalcularComision(@PromotorId INT, @CampaniaId INT, @MontoBase DECIMAL(10,2))
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @Comision DECIMAL(10,2) = 0;

    SELECT @Comision = ROUND(@MontoBase * (PorcentajeComisionBase / 100.0), 2)
    FROM sales.CampaniasAdmision
    WHERE CampaniaId = @CampaniaId
      AND Activo = 1;

    RETURN ISNULL(@Comision, 0);
END
GO

PRINT 'OK: sales.fn_CalcularComision.';
GO
