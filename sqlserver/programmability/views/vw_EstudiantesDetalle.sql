-- =============================================
-- Matricula Cloud 360 Enterprise
-- programmability/views/vw_EstudiantesDetalle.sql
-- =============================================
-- Estudiantes con documento completo y ubicacion (ubigeo).
--
-- IDEMPOTENTE: CREATE OR ALTER VIEW.
-- =============================================

USE MatriculaCloud360DB;
GO

SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER VIEW core.vw_EstudiantesDetalle
AS
SELECT
    e.EstudianteId,
    e.TipoDocumento,
    e.NumeroDocumento,
    e.Nombres,
    e.Apellidos,
    e.Nombres + ' ' + e.Apellidos AS NombreCompleto,
    e.Email,
    e.Celular,
    e.FechaNacimiento,
    core.fn_EdadEstudiante(e.EstudianteId) AS Edad,
    e.Genero,
    e.Direccion,
    u.CodigoUbigeo,
    u.Departamento,
    u.Provincia,
    u.Distrito,
    e.Activo,
    e.CreatedAt,
    e.UpdatedAt,
    e.DeletedAt
FROM core.Estudiantes e
LEFT JOIN core.Ubigeos u ON u.UbigeoId = e.UbigeoId;
GO

PRINT 'OK: core.vw_EstudiantesDetalle.';
GO
