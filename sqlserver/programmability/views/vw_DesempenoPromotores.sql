-- =============================================
-- Matricula Cloud 360 Enterprise
-- programmability/views/vw_DesempenoPromotores.sql
-- =============================================
-- Resumen del desempeno de cada promotor por campana:
-- matriculas captadas, monto facturado, comisiones y estado.
-- Indicador clave para la toma de decisiones (RN-08).
--
-- IDEMPOTENTE: CREATE OR ALTER VIEW.
-- =============================================

USE MatriculaCloud360DB;
GO

SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER VIEW sales.vw_DesempenoPromotores
AS
SELECT
    pr.PromotorId,
    pr.CodigoPromotor,
    pr.Nombres + ' ' + pr.Apellidos AS Promotor,
    p.CodigoPeriodo,
    p.NombrePeriodo,
    ca.CampaniaId,
    ca.NombreCampania,
    ca.MetaMatriculas,
    COUNT(m.MatriculaId) AS TotalMatriculas,
    SUM(CASE WHEN m.EstadoMatricula = 'Activa' THEN 1 ELSE 0 END) AS MatriculasActivas,
    ISNULL(SUM(m.MontoMatricula), 0) AS MontoFacturado,
    ISNULL(SUM(CASE WHEN co.EstadoPago = 'Pagada' THEN co.MontoTotal ELSE 0 END), 0) AS ComisionesPagadas,
    ISNULL(SUM(CASE WHEN co.EstadoPago = 'Pendiente' THEN co.MontoTotal ELSE 0 END), 0) AS ComisionesPendientes
FROM sales.Promotores pr
LEFT JOIN core.Matriculas m       ON m.PromotorId = pr.PromotorId AND m.DeletedAt IS NULL
LEFT JOIN core.PeriodosAcademicos p ON p.PeriodoId = m.PeriodoId
LEFT JOIN sales.CampaniasAdmision ca ON ca.CampaniaId = m.CampaniaId
LEFT JOIN sales.Comisiones co     ON co.MatriculaId = m.MatriculaId
WHERE pr.DeletedAt IS NULL
GROUP BY pr.PromotorId, pr.CodigoPromotor, pr.Nombres, pr.Apellidos,
         p.CodigoPeriodo, p.NombrePeriodo, ca.CampaniaId, ca.NombreCampania, ca.MetaMatriculas;
GO

PRINT 'OK: sales.vw_DesempenoPromotores.';
GO
