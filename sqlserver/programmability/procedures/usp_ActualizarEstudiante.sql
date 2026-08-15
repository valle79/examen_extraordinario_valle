-- =============================================
-- Matricula Cloud 360 Enterprise
-- programmability/procedures/usp_ActualizarEstudiante.sql
-- =============================================
-- Actualiza los datos de un estudiante existente manteniendo la
-- unicidad del documento y el email (RN-01).
--
-- IDEMPOTENTE: CREATE OR ALTER PROCEDURE.
-- =============================================

USE MatriculaCloud360DB;
GO

SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE core.usp_ActualizarEstudiante
    @EstudianteId INT,
    @TipoDocumento CHAR(3),
    @NumeroDocumento VARCHAR(15),
    @Nombres NVARCHAR(100),
    @Apellidos NVARCHAR(100),
    @Email VARCHAR(100),
    @Celular CHAR(9) = NULL,
    @FechaNacimiento DATE,
    @Genero CHAR(1),
    @Direccion NVARCHAR(200) = NULL,
    @UbigeoId INT = NULL,
    @ErrorMsg NVARCHAR(500) = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- RN-10: un estudiante con borrado logico no puede editarse
        IF NOT EXISTS (SELECT 1 FROM core.Estudiantes
                       WHERE EstudianteId = @EstudianteId AND DeletedAt IS NULL)
            THROW 51004, 'El estudiante indicado no existe o esta inactivo (borrado logico).', 1;

        -- RN-01: documento y email unicos (excluyendo al propio estudiante)
        IF core.fn_ExisteEstudianteConDocumento(@TipoDocumento, @NumeroDocumento, @EstudianteId) = 1
            THROW 51001, 'Ya existe un estudiante registrado con ese documento (DNI/CE).', 1;

        IF EXISTS (SELECT 1 FROM core.Estudiantes WHERE Email = @Email AND EstudianteId <> @EstudianteId)
            THROW 51002, 'Ya existe un estudiante registrado con ese correo electronico.', 1;

        IF @UbigeoId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM core.Ubigeos WHERE UbigeoId = @UbigeoId)
            THROW 51003, 'El Ubigeo indicado no existe.', 1;

        UPDATE core.Estudiantes
        SET TipoDocumento    = @TipoDocumento,
            NumeroDocumento  = @NumeroDocumento,
            Nombres          = @Nombres,
            Apellidos        = @Apellidos,
            Email            = @Email,
            Celular          = @Celular,
            FechaNacimiento  = @FechaNacimiento,
            Genero           = @Genero,
            Direccion        = @Direccion,
            UbigeoId         = @UbigeoId,
            UpdatedAt        = GETDATE()
        WHERE EstudianteId = @EstudianteId;

        SET @ErrorMsg = NULL;
    END TRY
    BEGIN CATCH
        SET @ErrorMsg = ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

PRINT 'OK: core.usp_ActualizarEstudiante.';
GO
