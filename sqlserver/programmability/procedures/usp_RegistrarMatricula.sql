-- =============================================
-- Matricula Cloud 360 Enterprise
-- programmability/procedures/usp_RegistrarMatricula.sql
-- =============================================
-- Opera las reglas de negocio del proceso de matricula:
--   RN-03: exige datos previos de estudiante, carrera, sede,
--          promotor y periodo habilitado.
--   RN-08: promotor y sede obligatorios.
--   RN-02: un estudiante no puede matricularse dos veces en la
--          misma carrera y periodo.
--   RN-04: toda la operacion corre en una transaccion; ante
--          cualquier error se revierte (ROLLBACK).
--   RN-09: la comision se genera automaticamente (trigger).
--
-- IDEMPOTENTE: CREATE OR ALTER PROCEDURE.
-- =============================================

USE MatriculaCloud360DB;
GO

SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE core.usp_RegistrarMatricula
    @EstudianteId INT,
    @CarreraId INT,
    @PeriodoId INT,
    @SedeId INT,
    @PromotorId INT,
    @CampaniaId INT = NULL,
    @Observaciones NVARCHAR(500) = NULL,
    @MatriculaId INT = NULL OUTPUT,
    @ErrorMsg NVARCHAR(500) = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;  -- RN-04

        -- RN-03: el estudiante debe existir y estar activo
        IF NOT EXISTS (SELECT 1 FROM core.Estudiantes
                       WHERE EstudianteId = @EstudianteId AND Activo = 1 AND DeletedAt IS NULL)
            THROW 52001, 'La matricula no procede: el estudiante no existe o esta inactivo.', 1;

        -- RN-03: la carrera debe existir y estar activa
        IF NOT EXISTS (SELECT 1 FROM core.Carreras
                       WHERE CarreraId = @CarreraId AND Activo = 1 AND DeletedAt IS NULL)
            THROW 52002, 'La matricula no procede: la carrera no existe o esta inactiva.', 1;

        -- RN-03 y RN-08: la sede debe existir y estar activa
        IF NOT EXISTS (SELECT 1 FROM core.Sedes
                       WHERE SedeId = @SedeId AND Activo = 1 AND DeletedAt IS NULL)
            THROW 52003, 'La matricula no procede: la sede no existe o esta inactiva.', 1;

        -- RN-03 y RN-08: el promotor debe existir y estar activo
        IF NOT EXISTS (SELECT 1 FROM sales.Promotores
                       WHERE PromotorId = @PromotorId AND Activo = 1 AND DeletedAt IS NULL)
            THROW 52004, 'La matricula no procede: el promotor no existe o esta inactivo.', 1;

        -- RN-03: el periodo debe estar habilitado (activo y en ventana de matricula)
        IF core.fn_PeriodoMatriculaHabilitado(@PeriodoId, GETDATE()) = 0
            THROW 52005, 'La matricula no procede: el periodo no existe, no esta activo o su ventana de matriculas esta cerrada.', 1;

        -- RN-02: no duplicar matricula (estudiante + carrera + periodo)
        IF EXISTS (SELECT 1 FROM core.Matriculas
                   WHERE EstudianteId = @EstudianteId
                     AND CarreraId = @CarreraId
                     AND PeriodoId = @PeriodoId
                     AND DeletedAt IS NULL)
            THROW 52006, 'El estudiante ya se encuentra matriculado en esa carrera para el periodo indicado.', 1;

        -- La campana (opcional) debe existir y pertenecer al periodo
        IF @CampaniaId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM sales.CampaniasAdmision
                                                   WHERE CampaniaId = @CampaniaId AND PeriodoId = @PeriodoId)
            THROW 52007, 'La campana indicada no existe o no pertenece al periodo.', 1;

        -- Monto de matricula por defecto: costo de matricula de la carrera
        DECLARE @Monto DECIMAL(10,2);
        SELECT @Monto = CostoMatricula FROM core.Carreras WHERE CarreraId = @CarreraId;

        -- Insertar la matricula (la comision la genera el trigger RN-09)
        INSERT INTO core.Matriculas
            (CodigoMatricula, EstudianteId, CarreraId, PeriodoId, SedeId,
             PromotorId, CampaniaId, FechaMatricula, MontoMatricula,
             EstadoMatricula, Observaciones)
        VALUES
            ('PENDIENTE', @EstudianteId, @CarreraId, @PeriodoId, @SedeId,
             @PromotorId, @CampaniaId, GETDATE(), @Monto, 'Activa', @Observaciones);

        SET @MatriculaId = SCOPE_IDENTITY();

        -- Codigo de matricula: MAT-AAAA-NNNNNN (legible para el negocio)
        UPDATE core.Matriculas
        SET CodigoMatricula = 'MAT-' + CONVERT(VARCHAR(4), YEAR(GETDATE()))
                              + '-' + RIGHT('000000' + CONVERT(VARCHAR(6), @MatriculaId), 6)
        WHERE MatriculaId = @MatriculaId;

        COMMIT TRANSACTION;  -- RN-04
        SET @ErrorMsg = NULL;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;  -- RN-04: revertir TODO ante cualquier error
        SET @MatriculaId = NULL;
        SET @ErrorMsg = ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

PRINT 'OK: core.usp_RegistrarMatricula.';
GO
