-- =============================================
-- Matricula Cloud 360 Enterprise
-- programmability/views/vw_ComisionesDetalle.sql
-- =============================================
-- Comisiones con promotor, campana y matricula relacionadas.
--
-- IDEMPOTENTE: CREATE OR ALTER VIEW.
-- =============================================



USE MatriculaCloud360DB;
GO

SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER VIEW sales.vw_ComisionesDetalle
AS
SELECT
    co.ComisionId,
    co.MontoBase,
    co.PorcentajeComision,
    co.MontoComision,
    co.Bonificacion,
    co.MontoTotal,
    co.EstadoPago,
    co.FechaPago,
    pr.PromotorId,
    pr.Nombres + ' ' + pr.Apellidos AS Promotor,
    ca.CampaniaId,
    ca.NombreCampania,
    m.MatriculaId,
    m.CodigoMatricula,
    e.Nombres + ' ' + e.Apellidos AS Estudiante
FROM sales.Comisiones co
INNER JOIN sales.Promotores pr    ON pr.PromotorId = co.PromotorId
INNER JOIN core.Matriculas m      ON m.MatriculaId = co.MatriculaId
INNER JOIN core.Estudiantes e     ON e.EstudianteId = m.EstudianteId
LEFT JOIN sales.CampaniasAdmision ca ON ca.CampaniaId = co.CampaniaId;
GO

PRINT 'OK: sales.vw_ComisionesDetalle.';
GO
