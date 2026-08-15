-- =============================================
-- Matricula Cloud 360 Enterprise
-- utils/demo_profesor.sql | DEMO COMPLETA PARA EL PROFESOR
-- =============================================
-- Muestra en vivo que FUNCIONAN:
--   1. VISTAS        (7 vistas devuelven datos)
--   2. FUNCIONES     (6 funciones devuelven valores correctos)
--   3. PROCEDURES    (registro, consulta y validaciones de negocio)
--   4. TRIGGERS      (auditoria RN-07 y comision automatica RN-09)
--
-- SEGURO: todas las escrituras de prueba corren dentro de una
-- transaccion que se revierte (ROLLBACK). Al terminar, la base
-- queda EXACTAMENTE igual que al inicio. No se pierde nada.
--
-- IMPORTANTE: todo es UN SOLO LOTE (sin GO), porque las variables
-- declaradas se pierden entre lotes.
--
-- Uso: abrir en SSMS (conexion a MatriculaCloud360DB) y ejecutar.
-- Ver la pestana "Mensajes" para los resultados [OK]/[NO OK].
-- =============================================

USE MatriculaCloud360DB;
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;

DECLARE @Errores INT = 0;
DECLARE @IdOut INT, @MsgErr NVARCHAR(500);
DECLARE @NuevoEstudiante INT, @NuevaMatricula INT;
DECLARE @AuditAntes INT, @AuditDespues INT;

PRINT '==========================================================';
PRINT '  DEMO: VISTAS + FUNCIONES + PROCEDURES + TRIGGERS';
PRINT '==========================================================';
PRINT '';

-- ==========================================================
-- 1. VISTAS: se consultan con SELECT y deben devolver filas
-- ==========================================================
PRINT '1) VISTAS';
PRINT '   ----------------------------------------------';

PRINT '   >> core.vw_EstudiantesDetalle (3 primeros)';
SELECT TOP (3) * FROM core.vw_EstudiantesDetalle;

PRINT '   >> core.vw_MatriculasDetalle (3 primeros)';
SELECT TOP (3) * FROM core.vw_MatriculasDetalle;

PRINT '   >> core.vw_ComisionesDetalle (3 primeros)';
SELECT TOP (3) * FROM core.vw_ComisionesDetalle;

PRINT '   >> core.vw_ProfesoresDetalle (3 primeros)';
SELECT TOP (3) * FROM core.vw_ProfesoresDetalle;

PRINT '   >> sales.vw_DesempenoPromotores (3 primeros)';
SELECT TOP (3) * FROM sales.vw_DesempenoPromotores;

PRINT '   >> academic.vw_MallaCurricular (3 primeros)';
SELECT TOP (3) * FROM academic.vw_MallaCurricular;

PRINT '   >> core.vw_ReporteMatriculasPeriodo (3 primeros)';
SELECT TOP (3) * FROM core.vw_ReporteMatriculasPeriodo;

PRINT '   >> Resumen: filas que devuelve cada vista:';
SELECT 'core.vw_EstudiantesDetalle' AS Vista, COUNT(*) AS Filas FROM core.vw_EstudiantesDetalle
UNION ALL SELECT 'core.vw_MatriculasDetalle', COUNT(*) FROM core.vw_MatriculasDetalle
UNION ALL SELECT 'core.vw_ComisionesDetalle', COUNT(*) FROM core.vw_ComisionesDetalle
UNION ALL SELECT 'core.vw_ProfesoresDetalle', COUNT(*) FROM core.vw_ProfesoresDetalle
UNION ALL SELECT 'sales.vw_DesempenoPromotores', COUNT(*) FROM sales.vw_DesempenoPromotores
UNION ALL SELECT 'academic.vw_MallaCurricular', COUNT(*) FROM academic.vw_MallaCurricular
UNION ALL SELECT 'core.vw_ReporteMatriculasPeriodo', COUNT(*) FROM core.vw_ReporteMatriculasPeriodo;

PRINT '';
GO

USE MatriculaCloud360DB;
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;

-- ==========================================================
-- 2. FUNCIONES: se prueban con SELECT y un valor esperado
-- ==========================================================
PRINT '2) FUNCIONES';
PRINT '   ----------------------------------------------';

SELECT
    core.fn_EdadEstudiante(1)                                                AS 'fn_EdadEstudiante(1)',
    core.fn_ExisteEstudianteConDocumento('DNI', '70123456', 0)              AS 'fn_ExisteDocumento(70123456)',
    core.fn_TotalMatriculadosCarrera(1, 5)                                  AS 'fn_MatriculadosCarrera(1,5)',
    core.fn_PeriodoMatriculaHabilitado(5, GETDATE())                        AS 'fn_PeriodoHabilitado(5,hoy)',
    sales.fn_CalcularComision(1, 3, 250.00)                                 AS 'fn_Comision(250x12%)',
    sales.fn_CalcularBonoPromotor(1, 3)                                     AS 'fn_BonoPromotor(1,3)';

PRINT '   Valores esperados:';
PRINT '   - fn_ExisteDocumento   = 1 (el DNI 70123456 ya existe)';
PRINT '   - fn_Comision(250x12%) = 30.00 (RN-09)';
PRINT '   - fn_EdadEstudiante    = edad de Carlos Andres Mendoza';
PRINT '';
GO

USE MatriculaCloud360DB;
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;

-- ==========================================================
-- 3. PROCEDURES: consulta y registro con validacion de negocio
-- ==========================================================
PRINT '3) PROCEDURES';
PRINT '   ----------------------------------------------';

-- 3.1 usp_ConsultarMatriculas (solo lectura, sin filtros)
PRINT '   >> core.usp_ConsultarMatriculas (todas las activas)';
EXEC core.usp_ConsultarMatriculas;

-- 3.2 usp_RegistrarEstudiante rechaza DNI duplicado (RN-01 -> error 51001)
PRINT '   >> core.usp_RegistrarEstudiante con DNI DUPLICADO (70123456):';
PRINT '      se espera el ERROR 51001 (regla RN-01 funcionando):';
DECLARE @Errores INT = 0;
DECLARE @IdOut INT, @MsgErr NVARCHAR(500);
BEGIN TRY
    EXEC core.usp_RegistrarEstudiante 'DNI', '70123456', 'X', 'Y', 'x.demo@gmail.com',
         '987000001', '2004-01-01', 'M', NULL, 1, @IdOut OUTPUT, @MsgErr OUTPUT;
    PRINT '      [NO OK] El sistema PERMITIO registrar un DNI duplicado.';
    SET @Errores = @Errores + 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 51001
        PRINT '      [OK] Rechazado con error 51001: ' + ERROR_MESSAGE();
    ELSE
    BEGIN
        PRINT '      [NO OK] Error inesperado ' + CAST(ERROR_NUMBER() AS VARCHAR) + ': ' + ERROR_MESSAGE();
        SET @Errores = @Errores + 1;
    END
END CATCH

PRINT '';
GO

USE MatriculaCloud360DB;
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;

-- ==========================================================
-- 4. TRIGGERS + PROCEDURES DE ESCRITURA (transaccion que se revierte)
--    Demuestra: TRG_Audit_Estudiantes (RN-07), TRG_Audit_Matriculas,
--    TRG_Comision_Automatica (RN-09) y los SP usp_RegistrarEstudiante/
--    usp_RegistrarMatricula SIN dejar datos en la base (ROLLBACK).
-- ==========================================================
PRINT '4) TRIGGERS (auditoria y comision automatica)';
PRINT '   ----------------------------------------------';
PRINT '   Todo corre dentro de una transaccion que se revierte al final.';
PRINT '   Las tablas quedan igual que al inicio.';
PRINT '';

DECLARE @NuevoEstudiante INT = NULL, @NuevaMatricula INT = NULL;
DECLARE @AuditAntes INT, @AuditDespues INT, @MsgErr NVARCHAR(500);

BEGIN TRAN;  -- demo reversible
    BEGIN TRY
        SELECT @AuditAntes = COUNT(*) FROM audit.AuditLog;

        -- 4.1 usp_RegistrarEstudiante (SP en accion)
        EXEC core.usp_RegistrarEstudiante 'DNI', '90123456', 'Estudiante', 'Demonstrativo',
             'demo.profesor@gmail.com', '999111222', '2005-03-10', 'M', 'Av. Demostracion 123',
             1, @NuevoEstudiante OUTPUT, @MsgErr OUTPUT;
        PRINT '   >> core.usp_RegistrarEstudiante creo al estudiante ' + CAST(@NuevoEstudiante AS VARCHAR);

        -- Evidencia del trigger TRG_Audit_Estudiantes (RN-07)
        SELECT @AuditDespues = COUNT(*) FROM audit.AuditLog;
        PRINT '   >> TRIGGER TRG_Audit_Estudiantes: audit antes=' + CAST(@AuditAntes AS VARCHAR)
            + ' despues=' + CAST(@AuditDespues AS VARCHAR)
            + ' -> registros nuevos: ' + CAST(@AuditDespues - @AuditAntes AS VARCHAR);
        SELECT TOP (1) AuditId, TableName, Operation, RecordId, Usuario, FechaOperacion, ValoresNuevos
        FROM audit.AuditLog ORDER BY AuditId DESC;

        -- 4.2 usp_RegistrarMatricula (SP en accion, RN-03/RN-08/RN-02)
        EXEC core.usp_RegistrarMatricula @NuevoEstudiante, 1, 5, 1, 1, 3, 'Matricula de demostracion',
             @NuevaMatricula OUTPUT, @MsgErr OUTPUT;
        PRINT '   >> core.usp_RegistrarMatricula creo la matricula ' + CAST(@NuevaMatricula AS VARCHAR);

        -- Evidencia del trigger TRG_Comision_Automatica (RN-09)
        DECLARE @ComisionGenerada DECIMAL(10,2), @EstadoComision VARCHAR(20);
        SELECT @ComisionGenerada = MontoComision, @EstadoComision = EstadoPago
        FROM sales.Comisiones WHERE MatriculaId = @NuevaMatricula;
        PRINT '   >> TRIGGER TRG_Comision_Automatica: comision=' + CAST(@ComisionGenerada AS VARCHAR)
            + ' estado=' + @EstadoComision + ' (esperado: 30.00 / Pendiente)';
        SELECT ComisionId, PromotorId, MatriculaId, MontoBase, PorcentajeComision, MontoComision, MontoTotal, EstadoPago
        FROM sales.Comisiones WHERE MatriculaId = @NuevaMatricula;

        -- Evidencia del trigger TRG_Audit_Matriculas (RN-07)
        SELECT TOP (1) AuditId, TableName, Operation, RecordId, Usuario, FechaOperacion
        FROM audit.AuditLog WHERE TableName = 'core.Matriculas' ORDER BY AuditId DESC;
    END TRY
    BEGIN CATCH
        PRINT '   [ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR) + '] ' + ERROR_MESSAGE();
        PRINT '   La transaccion se reversara por completo.';
    END CATCH

    IF @@TRANCOUNT > 0
        ROLLBACK;  -- se deshace TODO: estudiante, matricula, comision y auditoria de la demo
PRINT '   >> ROLLBACK ejecutado: la base de datos quedo intacta (nada de la demo permanece).';
PRINT '';
GO

USE MatriculaCloud360DB;
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;

-- ==========================================================
-- 5. TRIGGERS en accion directa (INSERT y UPDATE sobre la tabla)
--    Con ROLLBACK para no dejar cambios.
-- ==========================================================
PRINT '5) TRIGGERS en DML directo (INSERT / UPDATE)';
PRINT '   ----------------------------------------------';

DECLARE @AuditAntes2 INT, @AuditDespues2 INT;
SELECT @AuditAntes2 = COUNT(*) FROM audit.AuditLog;

BEGIN TRAN;
    BEGIN TRY
        INSERT INTO core.Estudiantes (TipoDocumento, NumeroDocumento, Nombres, Apellidos, Email, Celular, FechaNacimiento, Genero)
        VALUES ('DNI', '91234567', 'Alumno', 'PruebaDirecta', 'prueba.directa@gmail.com', '999222333', '2004-01-01', 'M');

        UPDATE core.Estudiantes SET Apellidos = 'PruebaActualizada'
        WHERE NumeroDocumento = '91234567';

        SELECT @AuditDespues2 = COUNT(*) FROM audit.AuditLog;
        PRINT '   >> INSERT + UPDATE directo sobre core.Estudiantes:';
        PRINT '      audit antes=' + CAST(@AuditAntes2 AS VARCHAR)
            + ' despues=' + CAST(@AuditDespues2 AS VARCHAR)
            + ' -> el trigger registró ' + CAST(@AuditDespues2 - @AuditAntes2 AS VARCHAR) + ' operaciones';
        SELECT AuditId, TableName, Operation, RecordId, Usuario, FechaOperacion,
               ValoresAnteriores, ValoresNuevos
        FROM audit.AuditLog ORDER BY AuditId DESC;
    END TRY
    BEGIN CATCH
        PRINT '   [ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR) + '] ' + ERROR_MESSAGE();
    END CATCH

    IF @@TRANCOUNT > 0
        ROLLBACK;
PRINT '   >> ROLLBACK: cambios descartados, auditoria de la prueba eliminada.';
PRINT '';
GO

USE MatriculaCloud360DB;
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;

-- ==========================================================
-- 6. EVIDENCIA ESTRUCTURAL FINAL
-- ==========================================================
PRINT '6) RESUMEN ESTRUCTURAL (que existe y esta habilitado)';
PRINT '   ----------------------------------------------';

SELECT
    (SELECT COUNT(*) FROM sys.objects WHERE type = 'V' AND is_ms_shipped = 0
        AND OBJECT_SCHEMA_NAME(object_id) IN ('core','sales','academic'))      AS Vistas,
    (SELECT COUNT(*) FROM sys.objects WHERE type = 'P' AND is_ms_shipped = 0
        AND OBJECT_SCHEMA_NAME(object_id) IN ('core','sales','academic'))      AS Procedures,
    (SELECT COUNT(*) FROM sys.objects WHERE type IN ('FN','IF','TF')
        AND is_ms_shipped = 0
        AND OBJECT_SCHEMA_NAME(object_id) IN ('core','sales','academic'))      AS Funciones,
    (SELECT COUNT(*) FROM sys.triggers WHERE is_disabled = 0
        AND OBJECT_SCHEMA_NAME(parent_id) IN ('core','sales','academic'))      AS Triggers_habilitados;

DECLARE @Verificar INT;
SELECT @Verificar = COUNT(*) FROM sys.objects WHERE type = 'V'
    AND OBJECT_SCHEMA_NAME(object_id) IN ('core','sales','academic') AND is_ms_shipped = 0;

IF @Verificar > 0
    PRINT '>>> RESULTADO: LOS COMPONENTES FUERON EJECUTADOS, REVISA LAS PESTAÑAS RESULTADOS Y MENSAJES <<<';
PRINT '';
PRINT '==========================================================';
PRINT '  Demo ejecutada: ' + CONVERT(VARCHAR(30), GETDATE(), 120);
PRINT '==========================================================';
GO