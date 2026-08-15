-- =============================================
-- Matricula Cloud 360 Enterprise
-- programmability/procedures/usp_ConsultarEstudiantes.sql
-- =============================================
-- Consulta de estudiantes con filtros opcionales (busqueda por
-- nombre/apellido/documento, tipo de documento y solo activos).
-- Complementa a core.vw_EstudiantesDetalle. No incluye estudiantes
-- con borrado logico (DeletedAt) salvo que se solicite explicitamente.
--
-- IDEMPOTENTE: CREATE OR ALTER PROCEDURE.
-- =============================================

USE MatriculaCloud360DB;
GO

SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE core.usp_ConsultarEstudiantes
    @Busqueda NVARCHAR(100) = NULL,
    @TipoDocumento CHAR(3) = NULL,
    @IncluirInactivos BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

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
        u.Departamento + ' / ' + u.Provincia + ' / ' + u.Distrito AS Ubigeo,
        e.Activo,
        e.DeletedAt
    FROM core.Estudiantes e
    LEFT JOIN core.Ubigeos u ON u.UbigeoId = e.UbigeoId
    WHERE (@IncluirInactivos = 1 OR e.DeletedAt IS NULL)
      AND (@TipoDocumento IS NULL OR e.TipoDocumento = @TipoDocumento)
      AND (@Busqueda IS NULL
           OR e.Nombres LIKE '%' + @Busqueda + '%'
           OR e.Apellidos LIKE '%' + @Busqueda + '%'
           OR e.NumeroDocumento LIKE '%' + @Busqueda + '%'
           OR e.Email LIKE '%' + @Busqueda + '%')
    ORDER BY e.Apellidos, e.Nombres;
END
GO

PRINT 'OK: core.usp_ConsultarEstudiantes.';
GO
