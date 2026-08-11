-- =============================================
-- Matricula Cloud 360 Enterprise
-- programmability/views/vw_MallaCurricular.sql
-- =============================================
-- Malla curricular: cursos por carrera y semestre (RN-05).
--
-- IDEMPOTENTE: CREATE OR ALTER VIEW.
-- =============================================

USE MatriculaCloud360DB;
GO

SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER VIEW academic.vw_MallaCurricular
AS
SELECT
    cc.CarreraCursoId,
    cc.Semestre,
    c.CarreraId,
    c.CodigoCarrera,
    c.NombreCarrera,
    cu.CursoId,
    cu.CodigoCurso,
    cu.NombreCurso,
    cu.Creditos,
    cu.HorasTeoria,
    cu.HorasPractica
FROM academic.CarreraCursos cc
INNER JOIN core.Carreras c   ON c.CarreraId = cc.CarreraId
INNER JOIN academic.Cursos cu ON cu.CursoId = cc.CursoId;
GO

PRINT 'OK: academic.vw_MallaCurricular.';
GO
