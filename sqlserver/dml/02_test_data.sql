-- =============================================
-- Matricula Cloud 360 Enterprise
-- 02_test_data.sql | Datos de prueba del Sprint 2
-- =============================================
-- Descripcion: Registra datos de prueba utilizando los
-- procedimientos almacenados del Sprint 2 (demostrando su uso):
--   - Estudiante de prueba        -> core.usp_RegistrarEstudiante
--   - Matricula de prueba (2027-I) -> core.usp_RegistrarMatricula
--     (la comision se genera automaticamente: RN-09)
--   - Promotor de prueba          -> sales.usp_RegistrarPromotor
--
-- IDEMPOTENTE: verifica la existencia previa de cada registro.
-- La matricula de prueba solo procede si el periodo 2027-I esta
-- dentro de su ventana de matriculas (RN-03); si la ventana ya
-- cerro (por ejemplo, al recrear el contenedor meses despues),
-- solo se emite una advertencia y se continua.
-- =============================================

USE MatriculaCloud360DB;
GO

SET NOCOUNT ON;
GO

PRINT '============================================';
PRINT '02_test_data.sql - Datos de prueba Sprint 2';
PRINT '============================================';
GO

DECLARE @IdNuevo INT;
DECLARE @MsgError NVARCHAR(500);
DECLARE @Periodo2027I INT = 5;
DECLARE @Campania2027I INT = 5;

-- =============================================
-- 1. ESTUDIANTE DE PRUEBA
-- =============================================
IF NOT EXISTS (SELECT 1 FROM core.Estudiantes
               WHERE TipoDocumento = 'DNI' AND NumeroDocumento = '71234567')
BEGIN
    BEGIN TRY
        EXEC core.usp_RegistrarEstudiante
            @TipoDocumento = 'DNI',
            @NumeroDocumento = '71234567',
            @Nombres = 'Luis Angel',
            @Apellidos = 'Prueba Tapia',
            @Email = 'estudiante.prueba@gmail.com',
            @Celular = '987123456',
            @FechaNacimiento = '2005-01-15',
            @Genero = 'M',
            @Direccion = 'Av. Prueba 123',
            @UbigeoId = 1,
            @EstudianteId = @IdNuevo OUTPUT,
            @ErrorMsg = @MsgError OUTPUT;
        PRINT 'OK: Estudiante de prueba registrado (EstudianteId=' + CAST(@IdNuevo AS VARCHAR) + ').';
    END TRY
    BEGIN CATCH
        PRINT '[AVISO] No se pudo registrar el estudiante de prueba: ' + ERROR_MESSAGE();
    END CATCH
END
ELSE
    PRINT 'OK: Estudiante de prueba ya existe (se omite).';
GO

-- =============================================
-- 2. PROMOTOR DE PRUEBA
-- NOTA: las variables no persisten entre lotes GO; se redeclaran aqui.
-- =============================================
DECLARE @IdNuevo INT;
DECLARE @MsgError NVARCHAR(500);
IF NOT EXISTS (SELECT 1 FROM sales.Promotores WHERE CodigoPromotor = 'PROM-901')
BEGIN
    BEGIN TRY
        EXEC sales.usp_RegistrarPromotor
            @CodigoPromotor = 'PROM-901',
            @TipoDocumento = 'DNI',
            @NumeroDocumento = '90123456',
            @Nombres = 'Carmen Rosa',
            @Apellidos = 'Promotora Prueba',
            @Email = 'promotor.prueba@edufuturo.edu.pe',
            @Celular = '987654321',
            @SedeId = 1,
            @PorcentajeComision = 5.00,
            @PromotorId = @IdNuevo OUTPUT,
            @ErrorMsg = @MsgError OUTPUT;
        PRINT 'OK: Promotor de prueba registrado (PromotorId=' + CAST(@IdNuevo AS VARCHAR) + ').';
    END TRY
    BEGIN CATCH
        PRINT '[AVISO] No se pudo registrar el promotor de prueba: ' + ERROR_MESSAGE();
    END CATCH
END
ELSE
    PRINT 'OK: Promotor de prueba ya existe (se omite).';
GO

-- =============================================
-- 3. MATRICULA DE PRUEBA (periodo 2027-I, campana CAMP-2027-1)
--    Demuestra: RN-03 (periodo habilitado), RN-02 (sin duplicados),
--    RN-04 (transaccion) y RN-09 (comision automatica).
-- =============================================
DECLARE @IdNuevo INT;
DECLARE @MsgError NVARCHAR(500);
DECLARE @Periodo2027I INT = 5;
DECLARE @Campania2027I INT = 5;
DECLARE @EstudiantePrueba INT;
SELECT @EstudiantePrueba = EstudianteId
FROM core.Estudiantes
WHERE TipoDocumento = 'DNI' AND NumeroDocumento = '71234567';

IF @EstudiantePrueba IS NULL
BEGIN
    PRINT '[AVISO] No existe el estudiante de prueba; no se registra matricula.';
END
ELSE IF EXISTS (SELECT 1 FROM core.Matriculas
                WHERE EstudianteId = @EstudiantePrueba
                  AND CarreraId = 1
                  AND PeriodoId = @Periodo2027I)
BEGIN
    PRINT 'OK: Matricula de prueba ya existe (se omite).';
END
ELSE
BEGIN
    BEGIN TRY
        EXEC core.usp_RegistrarMatricula
            @EstudianteId = @EstudiantePrueba,
            @CarreraId = 1,
            @PeriodoId = @Periodo2027I,
            @SedeId = 1,
            @PromotorId = 1,
            @CampaniaId = @Campania2027I,
            @Observaciones = 'Matricula de prueba del Sprint 2',
            @MatriculaId = @IdNuevo OUTPUT,
            @ErrorMsg = @MsgError OUTPUT;
        PRINT 'OK: Matricula de prueba registrada (MatriculaId=' + CAST(@IdNuevo AS VARCHAR) + ').';
    END TRY
    BEGIN CATCH
        PRINT '[AVISO] No se pudo registrar la matricula de prueba (posiblemente la ventana del periodo 2027-I ya cerro): ' + ERROR_MESSAGE();
    END CATCH
END
GO

PRINT '';
PRINT '============================================';
PRINT 'Datos de prueba listos.';
PRINT '============================================';
GO
