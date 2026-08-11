-- =============================================
-- Matricula Cloud 360 Enterprise
-- programmability/procedures/usp_RegistrarPromotor.sql
-- =============================================
-- Registra un promotor vinculado a una sede (RN-08).
--
-- IDEMPOTENTE: CREATE OR ALTER PROCEDURE.
-- =============================================

USE MatriculaCloud360DB;
GO

SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE sales.usp_RegistrarPromotor
    @CodigoPromotor VARCHAR(10),
    @TipoDocumento CHAR(3),
    @NumeroDocumento VARCHAR(15),
    @Nombres NVARCHAR(100),
    @Apellidos NVARCHAR(100),
    @Email VARCHAR(100),
    @Celular CHAR(9) = NULL,
    @SedeId INT,
    @PorcentajeComision DECIMAL(5,2) = 5.00,
    @PromotorId INT = NULL OUTPUT,
    @ErrorMsg NVARCHAR(500) = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM core.Sedes WHERE SedeId = @SedeId AND Activo = 1 AND DeletedAt IS NULL)
            THROW 52010, 'La sede indicada no existe o esta inactiva.', 1;

        IF EXISTS (SELECT 1 FROM sales.Promotores WHERE CodigoPromotor = @CodigoPromotor)
            THROW 52011, 'Ya existe un promotor con ese codigo.', 1;

        IF EXISTS (SELECT 1 FROM sales.Promotores WHERE TipoDocumento = @TipoDocumento AND NumeroDocumento = @NumeroDocumento)
            THROW 52012, 'Ya existe un promotor con ese documento.', 1;

        IF EXISTS (SELECT 1 FROM sales.Promotores WHERE Email = @Email)
            THROW 52013, 'Ya existe un promotor con ese correo electronico.', 1;

        INSERT INTO sales.Promotores
            (CodigoPromotor, TipoDocumento, NumeroDocumento, Nombres, Apellidos,
             Email, Celular, SedeId, PorcentajeComision)
        VALUES
            (@CodigoPromotor, @TipoDocumento, @NumeroDocumento, @Nombres, @Apellidos,
             @Email, @Celular, @SedeId, @PorcentajeComision);

        SET @PromotorId = SCOPE_IDENTITY();
        SET @ErrorMsg = NULL;
    END TRY
    BEGIN CATCH
        SET @PromotorId = NULL;
        SET @ErrorMsg = ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

PRINT 'OK: sales.usp_RegistrarPromotor.';
GO
