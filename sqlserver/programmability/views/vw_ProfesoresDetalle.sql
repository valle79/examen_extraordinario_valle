-- =============================================
-- Matricula Cloud 360 Enterprise
-- programmability/views/vw_ProfesoresDetalle.sql
-- =============================================
-- Profesores con su especialidad (catalogo) y cursos asignados.
--
-- IDEMPOTENTE: CREATE OR ALTER VIEW.
-- =============================================

USE MatriculaCloud360DB;
GO

SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER VIEW academic.vw_ProfesoresDetalle
AS
SELECT
    pr.ProfesorId,
    pr.TipoDocumento,
    pr.NumeroDocumento,
    pr.Nombres + ' ' + pr.Apellidos AS Profesor,
    pr.Email,
    pr.Celular,
    e.NombreEspecialidad,
    pr.GradoAcademico,
    (SELECT COUNT(*) FROM academic.CursoProfesor cp
     WHERE cp.ProfesorId = pr.ProfesorId AND cp.Activo = 1) AS CursosAsignados,
    pr.Activo
FROM academic.Profesores pr
LEFT JOIN academic.Especialidades e ON e.EspecialidadId = pr.EspecialidadId
WHERE pr.DeletedAt IS NULL;
GO

PRINT 'OK: academic.vw_ProfesoresDetalle.';
GO
