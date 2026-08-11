-- =============================================
-- Matricula Cloud 360 Enterprise
-- programmability/procedures/usp_RegistrarEstudiante.sql
-- =============================================
-- Registra un nuevo estudiante validando RN-01 (documento y email
-- unicos). El formato del documento y el celular se validan con las
-- restricciones CHECK de la tabla.
--
-- IDEMPOTENTE: CREATE OR ALTER PROCEDURE.
-- =============================================

USE MatriculaCloud360DB;
GO

SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE core.usp_RegistrarEstudiante
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
    @EstudianteId INT = NULL OUTPUT,
    @ErrorMsg NVARCHAR(500) = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- RN-01: documento unico (DNI o CE)
        IF core.fn_ExisteEstudianteConDocumento(@TipoDocumento, @NumeroDocumento, 0) = 1
            THROW 51001, 'Ya existe un estudiante registrado con ese documento (DNI/CE).', 1;

        -- RN-01: email unico
        IF EXISTS (SELECT 1 FROM core.Estudiantes WHERE Email = @Email)
            THROW 51002, 'Ya existe un estudiante registrado con ese correo electronico.', 1;

        -- El ubigeo, si se envia, debe existir
        IF @UbigeoId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM core.Ubigeos WHERE UbigeoId = @UbigeoId)
            THROW 51003, 'El Ubigeo indicado no existe.', 1;

        INSERT INTO core.Estudiantes
            (TipoDocumento, NumeroDocumento, Nombres, Apellidos, Email, Celular,
             FechaNacimiento, Genero, Direccion, UbigeoId)
        VALUES
            (@TipoDocumento, @NumeroDocumento, @Nombres, @Apellidos, @Email, @Celular,
             @FechaNacimiento, @Genero, @Direccion, @UbigeoId);

        SET @EstudianteId = SCOPE_IDENTITY();
        SET @ErrorMsg = NULL;
    END TRY
    BEGIN CATCH
        SET @EstudianteId = NULL;
        SET @ErrorMsg = ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

PRINT 'OK: core.usp_RegistrarEstudiante.';
GO
