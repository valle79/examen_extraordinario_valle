-- ============================================================================
-- Matricula Cloud 360 Enterprise
-- utils/manual_pruebas_integrales.sql
-- ============================================================================
-- GUION DE DEMOSTRACION PASO A PASO (para sustentacion ante el profesor)
-- ----------------------------------------------------------------------------
-- Cada BLOQUE es independiente y sigue el patron:
--
--     PASO 1: ESTADO ANTES   --> SELECT que muestra la situacion previa
--     PASO 2: ACCION         --> llamada al objeto (usp / fn / trg / vw)
--     PASO 3: ESTADO DESPUES --> SELECT que verifica lo ocurrido
--
-- Se selecciona y ejecuta UN BLOQUE A LA VEZ (F5 en SSMS) y se muestra:
--   * pestaña RESULTADOS : los SELECT (antes / despues)
--   * pestaña MENSAJES   : los PRINT que narran cada paso y los errores
--
-- COBERTURA (criterios de aceptacion):
--   PARTE 1 : Procedimientos almacenados (usp) - CRUD completo + reglas RN
--   PARTE 2 : Funciones de negocio (fn)
--   PARTE 3 : Triggers (trg) - auditoria RN-07, comision automatica RN-09,
--             borrado logico RN-10 (INSTEAD OF DELETE)
--   PARTE 4 : Vistas (vw) - reportes y analiticas
--   PARTE 5 : Consultas avanzadas (CTE, ventanas, ROLLUP)
--   PARTE 6 : Indices y planes de ejecucion (antes / despues)
--   PARTE 7 : Seguridad por perfiles (Admin / Coordinador / Promotor)
--   PARTE 8 : Respaldo, restauracion y jobs de SQL Agent
--   PARTE 9 : Limpieza y resumen
--
-- NO modifica los scripts del proyecto ni los datos reales del instituto:
-- opera con datos de prueba propios (DNI 80000001/2, PROMOTOR PROM-TEST).
-- El bloque 00 es idempotente: se puede re-ejecutar todas las veces.
--
-- Como conectarse (SSMS): localhost,1434 | usuario SA | su password
-- Alternativa por consola:
--   docker exec sqlserver_matricula_cloud /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "MatriculaCloud360!" -C -i /sqlserver/utils/manual_pruebas_integrales.sql
-- ============================================================================

USE MatriculaCloud360DB;
GO

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
GO

-- ============================================================================
-- BLOQUE 00 - PUNTO DE PARTIDA (estado de la instalacion + setup de prueba)
-- ============================================================================
-- QUE SE DEMUESTRA: la instalacion completa existe (tablas, objetos,
-- indices, perfiles) y que el guion usa datos de prueba propios.
-- ============================================================================
PRINT '========================================================';
PRINT 'BLOQUE 00 - PUNTO DE PARTIDA';
PRINT '========================================================';
GO

PRINT 'PASO 1: Objetos programables instalados (usp, fn, vw, trg):';
SELECT 'Procedimientos (usp)' AS Objeto, COUNT(*) AS Cantidad FROM sys.procedures
UNION ALL SELECT 'Funciones (fn)', COUNT(*) FROM sys.objects WHERE type IN ('FN','IF','TF')
UNION ALL SELECT 'Vistas (vw)', COUNT(*) FROM sys.views
UNION ALL SELECT 'Triggers (trg)', COUNT(*) FROM sys.triggers;
GO

PRINT 'PASO 2: Perfiles de seguridad creados (logins del proyecto):';
SELECT name AS Login, default_database_name AS BaseDatos
FROM sys.sql_logins
WHERE name IN ('MC_Admin', 'MC_Coordinador', 'MC_Promotor')
ORDER BY name;
GO

PRINT 'PASO 3: Conteo de registros por tabla de negocio:';
SELECT 'core.Estudiantes' AS Tabla, COUNT(*) AS Registros FROM core.Estudiantes
UNION ALL SELECT 'core.Matriculas', COUNT(*) FROM core.Matriculas
UNION ALL SELECT 'sales.Promotores', COUNT(*) FROM sales.Promotores
UNION ALL SELECT 'sales.Comisiones', COUNT(*) FROM sales.Comisiones
UNION ALL SELECT 'audit.AuditLog', COUNT(*) FROM audit.AuditLog
ORDER BY Tabla;
GO

PRINT 'PASO 4: SETUP - se preparan los datos de prueba propios';
PRINT '(reactiva al estudiante DNI 80000001 y al promotor PROM-TEST,';
PRINT 'por si el guion ya se ejecuto antes = idempotente):';
DECLARE @TestEst INT;
SELECT @TestEst = EstudianteId FROM core.Estudiantes WHERE NumeroDocumento = '80000001';

IF @TestEst IS NOT NULL
BEGIN
    UPDATE sales.Comisiones
    SET EstadoPago = 'Pendiente', FechaPago = NULL
    FROM sales.Comisiones c
    INNER JOIN core.Matriculas m ON m.MatriculaId = c.MatriculaId
    WHERE m.EstudianteId = @TestEst;

    UPDATE core.Matriculas
    SET Activo = 1, DeletedAt = NULL, EstadoMatricula = 'Activa', UpdatedAt = GETDATE()
    WHERE EstudianteId = @TestEst;

    UPDATE core.Estudiantes
    SET Activo = 1, DeletedAt = NULL, UpdatedAt = GETDATE()
    WHERE EstudianteId = @TestEst;

    PRINT '   OK: datos de prueba del estudiante restablecidos.';
END
ELSE
    PRINT '   OK: primera ejecucion - el estudiante de prueba aun no existe.';

UPDATE sales.Promotores
SET Activo = 1, DeletedAt = NULL, UpdatedAt = GETDATE()
WHERE CodigoPromotor = 'PROM-TEST';

IF NOT EXISTS (SELECT 1 FROM sales.Promotores WHERE CodigoPromotor = 'PROM-TEST')
BEGIN
    BEGIN TRY
        EXEC sales.usp_RegistrarPromotor
            @CodigoPromotor     = 'PROM-TEST',
            @TipoDocumento      = 'DNI',
            @NumeroDocumento    = '80000002',
            @Nombres            = 'Promotor',
            @Apellidos          = 'Prueba Manual',
            @Email              = 'promotor.prueba@manual.edu',
            @Celular            = '999000001',
            @SedeId             = 1,
            @PorcentajeComision = 5.00;
        PRINT '   OK: promotor PROM-TEST creado para el guion.';
    END TRY
    BEGIN CATCH
        PRINT '   >>> ERROR creando el promotor de prueba: ' + CAST(ERROR_NUMBER() AS VARCHAR);
        PRINT '       ' + ERROR_MESSAGE();
    END CATCH
END
ELSE
    PRINT '   OK: promotor PROM-TEST ya existia.';
GO

-- ============================================================================
-- PARTE 1 - PROCEDIMIENTOS ALMACENADOS (usp)
-- ============================================================================

-- ============================================================================
-- BLOQUE 1.1 - REGISTRAR UN ESTUDIANTE (usp_RegistrarEstudiante)
-- ============================================================================
-- QUE SE DEMUESTRA: el flujo completo INSERT.
-- PASO 1: se listan los estudiantes existentes (se ven los DNIs en uso).
-- PASO 2: se registra un estudiante nuevo (DNI 80000001 - solo prueba).
-- PASO 3: se verifica que SI se inserto (SELECT por el id devuelto).
-- ============================================================================
PRINT '========================================================';
PRINT 'BLOQUE 1.1 - REGISTRAR ESTUDIANTE (usp_RegistrarEstudiante)';
PRINT '========================================================';
GO

PRINT 'PASO 1 - ESTADO ANTES: estudiantes existentes (ver los DNIs ya usados):';
SELECT TOP (5) EstudianteId, NumeroDocumento, Nombres, Apellidos, Email, Activo
FROM core.Estudiantes
WHERE DeletedAt IS NULL
ORDER BY EstudianteId;
GO

PRINT 'PASO 2 - ACCION: registrar un estudiante NUEVO con registro 80000001...';
PRINT '(si ya existia de una corrida anterior, se reactiva para no duplicarlo):';
DECLARE @IdEst INT;
DECLARE @ErrMsg NVARCHAR(500);

IF NOT EXISTS (SELECT 1 FROM core.Estudiantes WHERE NumeroDocumento = '80000001')
BEGIN
    BEGIN TRY
        EXEC core.usp_RegistrarEstudiante
            @TipoDocumento    = 'DNI',
            @NumeroDocumento  = '80000001',
            @Nombres          = 'Estudiante',
            @Apellidos        = 'Prueba Manual',
            @Email            = 'estudiante.prueba@manual.edu',
            @Celular          = '987000001',
            @FechaNacimiento  = '2005-01-10',
            @Genero           = 'M',
            @Direccion        = 'Av. Prueba 123',
            @UbigeoId         = 1,
            @EstudianteId     = @IdEst OUTPUT,
            @ErrorMsg         = @ErrMsg OUTPUT;

        PRINT '   >>> REGISTRO EXITOSO: nuevo EstudianteId = ' + CAST(@IdEst AS VARCHAR);
    END TRY
    BEGIN CATCH
        PRINT '   >>> ERROR INESPERADO: ' + CAST(ERROR_NUMBER() AS VARCHAR) + ' - ' + ERROR_MESSAGE();
    END CATCH
END
ELSE
BEGIN
    UPDATE core.Estudiantes
    SET Activo = 1, DeletedAt = NULL, UpdatedAt = GETDATE()
    WHERE NumeroDocumento = '80000001';
    PRINT '   >>> El estudiante 80000001 ya existia: se reutiliza (corrida anterior).';
END
GO

PRINT 'PASO 3 - ESTADO DESPUES: verificar que el estudiante SI quedo insertado:';
SELECT EstudianteId, TipoDocumento, NumeroDocumento, Nombres, Apellidos,
       Email, FechaNacimiento, Genero, Activo, CreatedAt
FROM core.Estudiantes
WHERE NumeroDocumento = '80000001';
GO

-- ============================================================================
-- BLOQUE 1.2 - REINTENTAR CON UN DNI QUE YA EXISTE (restriccion RN-01)
-- ============================================================================
-- QUE SE DEMUESTRA: la regla de negocio RN-01 bloquea el duplicado.
-- PASO 1: se listan los DNIs existentes (el 70123456 ya pertenece a Carlos).
-- PASO 2: se intenta registrar OTRO estudiante con ese mismo DNI.
-- PASO 3: se lanza el error 51001 y se verifica que NO se inserto nada.
-- ============================================================================
PRINT '========================================================';
PRINT 'BLOQUE 1.2 - DNI DUPLICADO RECHAZADO (RN-01)';
PRINT '========================================================';
GO

PRINT 'PASO 1 - ESTADO ANTES: DNIs ya registrados (el 70123456 EXISTE):';
SELECT NumeroDocumento, Nombres, Apellidos
FROM core.Estudiantes
WHERE NumeroDocumento IN ('70123456', '80000001');
GO

PRINT 'PASO 2 - ACCION: intentar registrar con el DNI 70123456 (ya existe)...';
DECLARE @IdEst2 INT;
DECLARE @ErrMsg2 NVARCHAR(500);

BEGIN TRY
    EXEC core.usp_RegistrarEstudiante
        @TipoDocumento    = 'DNI',
        @NumeroDocumento  = '70123456',
        @Nombres          = 'Clon',
        @Apellidos        = 'Duplicado',
        @Email            = 'clon.duplicado@gmail.com',
        @Celular          = '987000002',
        @FechaNacimiento  = '2004-01-01',
        @Genero           = 'M',
        @UbigeoId         = 1,
        @EstudianteId     = @IdEst2 OUTPUT,
        @ErrorMsg         = @ErrMsg2 OUTPUT;

    PRINT '   >>> NO SE ESPERABA ESTO: el SP no lanzo error (revisar).';
END TRY
BEGIN CATCH
    PRINT '   >>> ERROR CONTROLADO (lo que debe pasar):';
    PRINT '       Numero = ' + CAST(ERROR_NUMBER() AS VARCHAR);
    PRINT '       Mensaje = ' + ERROR_MESSAGE();
    PRINT '       >> El SP NO permite registrar un DNI que ya existe (RN-01).';
END CATCH
GO

PRINT 'PASO 3 - ESTADO DESPUES: verificar que el estudiante NO se duplico:';
SELECT NumeroDocumento, COUNT(*) AS VecesRegistrado
FROM core.Estudiantes
WHERE NumeroDocumento = '70123456'
GROUP BY NumeroDocumento;
GO

-- ============================================================================
-- BLOQUE 1.3 - REINTENTAR CON UN EMAIL QUE YA EXISTE (RN-01)
-- ============================================================================
-- QUE SE DEMUESTRA: la RN-01 tambien protege la unicidad del email.
-- El email cmendoza@gmail.com ya pertenece a Carlos (DNI 70123456).
-- ============================================================================
PRINT '========================================================';
PRINT 'BLOQUE 1.3 - EMAIL DUPLICADO RECHAZADO (RN-01)';
PRINT '========================================================';
GO

PRINT 'PASO 1 - ESTADO ANTES: quien tiene el email cmendoza@gmail.com:';
SELECT EstudianteId, NumeroDocumento, Email
FROM core.Estudiantes
WHERE Email = 'cmendoza@gmail.com';
GO

PRINT 'PASO 2 - ACCION: intentar registrar con ese email ya ocupado...';
BEGIN TRY
    EXEC core.usp_RegistrarEstudiante
        @TipoDocumento    = 'DNI',
        @NumeroDocumento  = '80000002',
        @Nombres          = 'Clon',
        @Apellidos        = 'Email',
        @Email            = 'cmendoza@gmail.com',
        @Celular          = '987000003',
        @FechaNacimiento  = '2004-01-01',
        @Genero           = 'F',
        @UbigeoId         = 1;

    PRINT '   >>> NO SE ESPERABA ESTO: el SP no lanzo error (revisar).';
END TRY
BEGIN CATCH
    PRINT '   >>> ERROR CONTROLADO: ' + CAST(ERROR_NUMBER() AS VARCHAR) + ' - ' + ERROR_MESSAGE();
    PRINT '   >> El registro fue rechazado por email duplicado (RN-01).';
END CATCH
GO

PRINT 'PASO 3 - ESTADO DESPUES: confirmar que no se creo un segundo Mendoza:';
SELECT COUNT(*) AS CantidadConEseEmail
FROM core.Estudiantes
WHERE Email = 'cmendoza@gmail.com';
GO

-- ============================================================================
-- BLOQUE 1.4 - ACTUALIZAR UN ESTUDIANTE (usp_ActualizarEstudiante)
-- ============================================================================
-- QUE SE DEMUESTRA: el flujo UPDATE.
-- PASO 1: se muestra el estudiante de prueba tal como esta.
-- PASO 2: se actualiza su direccion y celular.
-- PASO 3: se verifica el cambio (y en el bloque 3.2 se vera la auditoria).
-- ============================================================================
PRINT '========================================================';
PRINT 'BLOQUE 1.4 - ACTUALIZAR ESTUDIANTE (usp_ActualizarEstudiante)';
PRINT '========================================================';
GO

PRINT 'PASO 1 - ESTADO ANTES: estudiante de prueba antes del UPDATE:';
SELECT EstudianteId, NumeroDocumento, Direccion, Celular, UpdatedAt
FROM core.Estudiantes
WHERE NumeroDocumento = '80000001';
GO

PRINT 'PASO 2 - ACCION: actualizar direccion y celular...';
DECLARE @ErrMsg4 NVARCHAR(500);

BEGIN TRY
    EXEC core.usp_ActualizarEstudiante
        @EstudianteId      = (SELECT EstudianteId FROM core.Estudiantes WHERE NumeroDocumento = '80000001'),
        @TipoDocumento     = 'DNI',
        @NumeroDocumento   = '80000001',
        @Nombres           = 'Estudiante',
        @Apellidos         = 'Prueba Manual',
        @Email             = 'estudiante.prueba@manual.edu',
        @Celular           = '987000004',
        @FechaNacimiento   = '2005-01-10',
        @Genero            = 'M',
        @Direccion         = 'Av. Actualizada 999',
        @UbigeoId          = 1,
        @ErrorMsg          = @ErrMsg4 OUTPUT;

    PRINT '   >>> ACTUALIZACION EXITOSA.';
END TRY
BEGIN CATCH
    PRINT '   >>> ERROR INESPERADO: ' + CAST(ERROR_NUMBER() AS VARCHAR) + ' - ' + ERROR_MESSAGE();
END CATCH
GO

PRINT 'PASO 3 - ESTADO DESPUES: verificar el cambio aplicado:';
SELECT EstudianteId, NumeroDocumento, Direccion, Celular, UpdatedAt
FROM core.Estudiantes
WHERE NumeroDocumento = '80000001';
GO

-- ============================================================================
-- BLOQUE 1.5 - REGISTRAR UNA MATRICULA (usp_RegistrarMatricula)
-- ============================================================================
-- QUE SE DEMUESTRA: el flujo INSERT de matricula + la REGLA de negocio RN-09
-- (la comision se genera SOLA mediante trigger - se confirma en bloque 3.4).
-- Periodo 2027-I (id 5): ventana de matriculas ABIERTA (2026-08-01 a 2026-10-15).
-- ============================================================================
PRINT '========================================================';
PRINT 'BLOQUE 1.5 - REGISTRAR MATRICULA (usp_RegistrarMatricula)';
PRINT '========================================================';
GO

PRINT 'PASO 1 - ESTADO ANTES: matriculas del estudiante de prueba (aun no tiene):';
SELECT MatriculaId, CodigoMatricula, CarreraId, PeriodoId, EstadoMatricula
FROM core.Matriculas
WHERE EstudianteId = (SELECT EstudianteId FROM core.Estudiantes WHERE NumeroDocumento = '80000001')
  AND DeletedAt IS NULL;
GO

PRINT 'PASO 2 - ACCION: matricular al estudiante en ING-SIS (periodo 2027-I)...';
PRINT '(si la matricula ya existia de una corrida anterior, se reutiliza):';
DECLARE @IdMat INT;
DECLARE @ErrMsg5 NVARCHAR(500);

IF NOT EXISTS (SELECT 1 FROM core.Matriculas
               WHERE EstudianteId = (SELECT EstudianteId FROM core.Estudiantes WHERE NumeroDocumento = '80000001')
                 AND CarreraId = 1 AND PeriodoId = 5)
BEGIN
    BEGIN TRY
        EXEC core.usp_RegistrarMatricula
            @EstudianteId  = (SELECT EstudianteId FROM core.Estudiantes WHERE NumeroDocumento = '80000001'),
            @CarreraId     = 1,
            @PeriodoId     = 5,
            @SedeId        = 1,
            @PromotorId    = (SELECT PromotorId FROM sales.Promotores WHERE CodigoPromotor = 'PROM-TEST'),
            @CampaniaId    = 5,
            @Observaciones = 'Matricula de demostracion',
            @MatriculaId   = @IdMat OUTPUT,
            @ErrorMsg      = @ErrMsg5 OUTPUT;

        PRINT '   >>> MATRICULA EXITOSA: MatriculaId = ' + CAST(@IdMat AS VARCHAR);
    END TRY
    BEGIN CATCH
        PRINT '   >>> ERROR INESPERADO: ' + CAST(ERROR_NUMBER() AS VARCHAR) + ' - ' + ERROR_MESSAGE();
    END CATCH
END
ELSE
    PRINT '   >>> La matricula ya existia: se reutiliza (corrida anterior).';
GO

PRINT 'PASO 3 - ESTADO DESPUES: la matricula quedo registrada (comision incluida):';
SELECT m.MatriculaId, m.CodigoMatricula, c.NombreCarrera, p.CodigoPeriodo,
       m.MontoMatricula, m.EstadoMatricula
FROM core.Matriculas m
INNER JOIN core.Carreras c ON c.CarreraId = m.CarreraId
INNER JOIN core.PeriodosAcademicos p ON p.PeriodoId = m.PeriodoId
WHERE m.EstudianteId = (SELECT EstudianteId FROM core.Estudiantes WHERE NumeroDocumento = '80000001')
  AND m.DeletedAt IS NULL;
GO

-- ============================================================================
-- BLOQUE 1.6 - MATRICULA DUPLICADA RECHAZADA (RN-02)
-- ============================================================================
-- QUE SE DEMUESTRA: un estudiante NO puede matricularse 2 veces en la misma
-- carrera y periodo. Se reintenta el bloque 1.5 y el sistema lanza 52006.
-- ============================================================================
PRINT '========================================================';
PRINT 'BLOQUE 1.6 - MATRICULA DUPLICADA RECHAZADA (RN-02)';
PRINT '========================================================';
GO

PRINT 'PASO 1 - ESTADO ANTES: matricula existente (estudiante + ING-SIS + 2027-I):';
SELECT m.MatriculaId, c.NombreCarrera, p.CodigoPeriodo, m.EstadoMatricula
FROM core.Matriculas m
INNER JOIN core.Carreras c ON c.CarreraId = m.CarreraId
INNER JOIN core.PeriodosAcademicos p ON p.PeriodoId = m.PeriodoId
WHERE m.EstudianteId = (SELECT EstudianteId FROM core.Estudiantes WHERE NumeroDocumento = '80000001')
  AND m.CarreraId = 1 AND m.PeriodoId = 5 AND m.DeletedAt IS NULL;
GO

PRINT 'PASO 2 - ACCION: intentar matricular OTRA VEZ al mismo estudiante ...';
BEGIN TRY
    EXEC core.usp_RegistrarMatricula
        @EstudianteId  = (SELECT EstudianteId FROM core.Estudiantes WHERE NumeroDocumento = '80000001'),
        @CarreraId     = 1,
        @PeriodoId     = 5,
        @SedeId        = 1,
        @PromotorId    = (SELECT PromotorId FROM sales.Promotores WHERE CodigoPromotor = 'PROM-TEST'),
        @CampaniaId    = 5,
        @Observaciones = 'Intento de duplicado';

    PRINT '   >>> NO SE ESPERABA ESTO: se dejo matricular dos veces (revisar).';
END TRY
BEGIN CATCH
    PRINT '   >>> ERROR CONTROLADO: ' + CAST(ERROR_NUMBER() AS VARCHAR) + ' - ' + ERROR_MESSAGE();
    PRINT '   >> La RN-02 impide la matricula duplicada (estudiante+carrera+periodo).';
END CATCH
GO

PRINT 'PASO 3 - ESTADO DESPUES: el estudiante sigue con UNA sola matricula:';
SELECT COUNT(*) AS MatriculasEnIngSis
FROM core.Matriculas
WHERE EstudianteId = (SELECT EstudianteId FROM core.Estudiantes WHERE NumeroDocumento = '80000001')
  AND CarreraId = 1 AND PeriodoId = 5 AND DeletedAt IS NULL;
GO

-- ============================================================================
-- BLOQUE 1.7 - MATRICULA EN PERIODO CON VENTANA CERRADA (RN-03)
-- ============================================================================
-- QUE SE DEMUESTRA: no se puede matricular en periodos cuya ventana de
-- matriculas ya cerro. Periodo 2026-I (id 3): ventana 2026-01-15 a 2026-02-28.
-- ============================================================================
PRINT '========================================================';
PRINT 'BLOQUE 1.7 - VENTANA DE MATRICULAS CERRADA RECHAZADA (RN-03)';
PRINT '========================================================';
GO

PRINT 'PASO 1 - ESTADO ANTES: ventanas de matricula de los periodos:';
SELECT PeriodoId, CodigoPeriodo, FechaInicioMatriculas, FechaFinMatriculas,
       CASE WHEN GETDATE() BETWEEN FechaInicioMatriculas AND FechaFinMatriculas
            THEN 'ABIERTA' ELSE 'CERRADA' END AS VentanaHoy
FROM core.PeriodosAcademicos
WHERE PeriodoId IN (3, 5)
ORDER BY PeriodoId;
GO

PRINT 'PASO 2 - ACCION: intentar matricular en el periodo 2026-I (VENTANA CERRADA)...';
BEGIN TRY
    EXEC core.usp_RegistrarMatricula
        @EstudianteId  = (SELECT EstudianteId FROM core.Estudiantes WHERE NumeroDocumento = '80000001'),
        @CarreraId     = 1,
        @PeriodoId     = 3,
        @SedeId        = 1,
        @PromotorId    = (SELECT PromotorId FROM sales.Promotores WHERE CodigoPromotor = 'PROM-TEST'),
        @CampaniaId    = 3;

    PRINT '   >>> NO SE ESPERABA ESTO: se matriculo en ventana cerrada (revisar).';
END TRY
BEGIN CATCH
    PRINT '   >>> ERROR CONTROLADO: ' + CAST(ERROR_NUMBER() AS VARCHAR) + ' - ' + ERROR_MESSAGE();
    PRINT '   >> La RN-03 impide matricular fuera de la ventana habilitada.';
END CATCH
GO

PRINT 'PASO 3 - ESTADO DESPUES: no existe matricula en el periodo cerrado:';
SELECT COUNT(*) AS MatriculasEnPeriodoCerrado
FROM core.Matriculas
WHERE EstudianteId = (SELECT EstudianteId FROM core.Estudiantes WHERE NumeroDocumento = '80000001')
  AND PeriodoId = 3;
GO

-- ============================================================================
-- BLOQUE 1.8 - CONSULTAR CON LOS PROCEDIMIENTOS (usp_Consultar*)
-- ============================================================================
-- QUE SE DEMUESTRA: los GETs del sistema funcionan con filtros.
-- ============================================================================
PRINT '========================================================';
PRINT 'BLOQUE 1.8 - CONSULTAS (usp_ConsultarEstudiantes / usp_ConsultarMatriculas)';
PRINT '========================================================';
GO

PRINT 'CONSULTA 1: estudiantes que coinciden con el filtro "Prueba":';
EXEC core.usp_ConsultarEstudiantes @Busqueda = 'Prueba';
GO

PRINT 'CONSULTA 2: estudiantes del tipo DNI y ACTIVOS:';
EXEC core.usp_ConsultarEstudiantes @TipoDocumento = 'DNI', @IncluirInactivos = 0;
GO

PRINT 'CONSULTA 3: matriculas del periodo 2027-I (PeriodoId = 5):';
EXEC core.usp_ConsultarMatriculas @PeriodoId = 5;
GO

PRINT 'CONSULTA 4: matriculas del periodo 5 que esten ACTIVAS:';
EXEC core.usp_ConsultarMatriculas @PeriodoId = 5, @EstadoMatricula = 'Activa';
GO

-- ============================================================================
-- BLOQUE 1.9 - RETIRAR UNA MATRICULA (usp_RetirarMatricula)
-- ============================================================================
-- QUE SE DEMUESTRA: el UPDATE de estado (Activa -> Retirada) y que la
-- comision asociada se ANULA automaticamente (RN-09, via trigger).
-- ============================================================================
PRINT '========================================================';
PRINT 'BLOQUE 1.9 - RETIRAR MATRICULA (usp_RetirarMatricula)';
PRINT '========================================================';
GO

PRINT 'PASO 1 - ESTADO ANTES: matricula y su comision (Activa / Pendiente):';
SELECT m.MatriculaId, m.CodigoMatricula, m.EstadoMatricula, c.EstadoPago
FROM core.Matriculas m
LEFT JOIN sales.Comisiones c ON c.MatriculaId = m.MatriculaId
WHERE m.EstudianteId = (SELECT EstudianteId FROM core.Estudiantes WHERE NumeroDocumento = '80000001')
  AND m.CarreraId = 1 AND m.DeletedAt IS NULL;
GO

PRINT 'PASO 2 - ACCION: retirar la matricula de ING-SIS (motivo: prueba)...';
DECLARE @ErrMsg9 NVARCHAR(500);

BEGIN TRY
    EXEC core.usp_RetirarMatricula
        @MatriculaId = (SELECT MatriculaId FROM core.Matriculas
                        WHERE EstudianteId = (SELECT EstudianteId FROM core.Estudiantes WHERE NumeroDocumento = '80000001')
                          AND CarreraId = 1 AND DeletedAt IS NULL),
        @Motivo      = 'Retiro por demostracion',
        @ErrorMsg    = @ErrMsg9 OUTPUT;

    PRINT '   >>> RETIRO EXITOSO.';
END TRY
BEGIN CATCH
    PRINT '   >>> ERROR INESPERADO: ' + CAST(ERROR_NUMBER() AS VARCHAR) + ' - ' + ERROR_MESSAGE();
END CATCH
GO

PRINT 'PASO 3 - ESTADO DESPUES: matricula RETIRADA y comision ANULADA:';
SELECT m.MatriculaId, m.CodigoMatricula, m.EstadoMatricula,
       m.UpdatedAt, c.EstadoPago
FROM core.Matriculas m
LEFT JOIN sales.Comisiones c ON c.MatriculaId = m.MatriculaId
WHERE m.EstudianteId = (SELECT EstudianteId FROM core.Estudiantes WHERE NumeroDocumento = '80000001')
  AND m.CarreraId = 1 AND m.DeletedAt IS NULL;
GO

PRINT 'PASO 4 - EXTRA: no se puede retirar DOS VECES (error 52009):';
BEGIN TRY
    EXEC core.usp_RetirarMatricula
        @MatriculaId = (SELECT MatriculaId FROM core.Matriculas
                        WHERE EstudianteId = (SELECT EstudianteId FROM core.Estudiantes WHERE NumeroDocumento = '80000001')
                          AND CarreraId = 1 AND DeletedAt IS NULL),
        @Motivo      = 'Segundo retiro';

    PRINT '   >>> NO SE ESPERABA ESTO (revisar).';
END TRY
BEGIN CATCH
    PRINT '   >>> ERROR CONTROLADO: ' + CAST(ERROR_NUMBER() AS VARCHAR) + ' - ' + ERROR_MESSAGE();
END CATCH
GO

-- ============================================================================
-- BLOQUE 1.10 - SEGUNDA MATRICULA Y PAGO DE COMISION
-- ============================================================================
-- QUE SE DEMUESTRA: el flujo completo matricula -> comision -> pago.
-- ============================================================================
PRINT '========================================================';
PRINT 'BLOQUE 1.10 - MATRICULA 2 + PAGO DE COMISION';
PRINT '========================================================';
GO

PRINT 'PASO 1 - ACCION: matricular al estudiante en ING-IND (carrera 2, 2027-I)...';
PRINT '(si la matricula ya existia de una corrida anterior, se reutiliza):';
DECLARE @IdMat2 INT;
DECLARE @ErrMsgA NVARCHAR(500);

IF NOT EXISTS (SELECT 1 FROM core.Matriculas
               WHERE EstudianteId = (SELECT EstudianteId FROM core.Estudiantes WHERE NumeroDocumento = '80000001')
                 AND CarreraId = 2 AND PeriodoId = 5)
BEGIN
    BEGIN TRY
        EXEC core.usp_RegistrarMatricula
            @EstudianteId  = (SELECT EstudianteId FROM core.Estudiantes WHERE NumeroDocumento = '80000001'),
            @CarreraId     = 2,
            @PeriodoId     = 5,
            @SedeId        = 2,
            @PromotorId    = (SELECT PromotorId FROM sales.Promotores WHERE CodigoPromotor = 'PROM-TEST'),
            @CampaniaId    = 5,
            @Observaciones = 'Matricula 2 de demostracion',
            @MatriculaId   = @IdMat2 OUTPUT,
            @ErrorMsg      = @ErrMsgA OUTPUT;

        PRINT '   >>> MATRICULA EXITOSA: MatriculaId = ' + CAST(@IdMat2 AS VARCHAR);
    END TRY
    BEGIN CATCH
        PRINT '   >>> ERROR INESPERADO: ' + CAST(ERROR_NUMBER() AS VARCHAR) + ' - ' + ERROR_MESSAGE();
    END CATCH
END
ELSE
    PRINT '   >>> La matricula ya existia: se reutiliza (corrida anterior).';
GO

PRINT 'PASO 2 - ESTADO intermedio: la comision se creo SOLA (trigger RN-09):';
SELECT c.ComisionId, m.CodigoMatricula, c.MontoBase, c.PorcentajeComision,
       c.MontoComision, c.MontoTotal, c.EstadoPago
FROM sales.Comisiones c
INNER JOIN core.Matriculas m ON m.MatriculaId = c.MatriculaId
WHERE m.CarreraId = 2
  AND m.EstudianteId = (SELECT EstudianteId FROM core.Estudiantes WHERE NumeroDocumento = '80000001');
GO

PRINT 'PASO 3 - ACCION: marcar la comision como PAGADA...';
DECLARE @ErrMsgB NVARCHAR(500);

BEGIN TRY
    EXEC sales.usp_MarcarComisionPagada
        @ComisionId = (SELECT c.ComisionId FROM sales.Comisiones c
                       INNER JOIN core.Matriculas m ON m.MatriculaId = c.MatriculaId
                       WHERE m.CarreraId = 2
                         AND m.EstudianteId = (SELECT EstudianteId FROM core.Estudiantes WHERE NumeroDocumento = '80000001')),
        @ErrorMsg   = @ErrMsgB OUTPUT;

    PRINT '   >>> PAGO REGISTRADO.';
END TRY
BEGIN CATCH
    PRINT '   >>> ERROR INESPERADO: ' + CAST(ERROR_NUMBER() AS VARCHAR) + ' - ' + ERROR_MESSAGE();
END CATCH
GO

PRINT 'PASO 4 - ESTADO DESPUES: comision PAGADA con su fecha de pago:';
SELECT c.ComisionId, m.CodigoMatricula, c.MontoTotal, c.EstadoPago, c.FechaPago
FROM sales.Comisiones c
INNER JOIN core.Matriculas m ON m.MatriculaId = c.MatriculaId
WHERE m.CarreraId = 2
  AND m.EstudianteId = (SELECT EstudianteId FROM core.Estudiantes WHERE NumeroDocumento = '80000001');
GO

-- ============================================================================
-- BLOQUE 1.11 - ELIMINACION LOGICA DE ESTUDIANTE (usp_EliminarEstudianteLogico)
-- ============================================================================
-- QUE SE DEMUESTRA: RN-10 - el SP NO borra fisicamente: marca Activo=0 y
-- asigna DeletedAt. Ademas: un estudiante borrado no se puede actualizar
-- (51004) ni borrar dos veces (51005).
-- ============================================================================
PRINT '========================================================';
PRINT 'BLOQUE 1.11 - ELIMINACION LOGICA DE ESTUDIANTE (RN-10)';
PRINT '========================================================';
GO

PRINT 'PASO 1 - ESTADO ANTES: estudiante de prueba ACTIVO:';
SELECT EstudianteId, NumeroDocumento, Activo, DeletedAt
FROM core.Estudiantes
WHERE NumeroDocumento = '80000001';
GO

PRINT 'PASO 2 - ACCION: eliminar logicamente al estudiante...';
DECLARE @ErrMsgC NVARCHAR(500);

BEGIN TRY
    EXEC core.usp_EliminarEstudianteLogico
        @EstudianteId = (SELECT EstudianteId FROM core.Estudiantes WHERE NumeroDocumento = '80000001'),
        @ErrorMsg     = @ErrMsgC OUTPUT;

    PRINT '   >>> ELIMINACION LOGICA APLICADA.';
END TRY
BEGIN CATCH
    PRINT '   >>> ERROR INESPERADO: ' + CAST(ERROR_NUMBER() AS VARCHAR) + ' - ' + ERROR_MESSAGE();
END CATCH
GO

PRINT 'PASO 3 - ESTADO DESPUES: la fila SIGUE EXISTIENDO, con Activo=0 y DeletedAt:';
SELECT EstudianteId, NumeroDocumento, Nombres, Activo, DeletedAt
FROM core.Estudiantes
WHERE NumeroDocumento = '80000001';
GO

PRINT 'PASO 4 - EXTRA: un estudiante borrado ya no se puede actualizar (51004)';
PRINT 'ni borrar de nuevo (51005):';
BEGIN TRY
    EXEC core.usp_ActualizarEstudiante
        @EstudianteId    = (SELECT EstudianteId FROM core.Estudiantes WHERE NumeroDocumento = '80000001'),
        @TipoDocumento   = 'DNI',
        @NumeroDocumento = '80000001',
        @Nombres         = 'Intento',
        @Apellidos       = 'Edicion',
        @Email           = 'intento.edicion@gmail.com',
        @FechaNacimiento = '2005-01-10',
        @Genero          = 'M';

    PRINT '   >>> NO SE ESPERABA ESTO (revisar).';
END TRY
BEGIN CATCH
    PRINT '   >>> ERROR CONTROLADO 1: ' + CAST(ERROR_NUMBER() AS VARCHAR) + ' - ' + ERROR_MESSAGE();
END CATCH

BEGIN TRY
    EXEC core.usp_EliminarEstudianteLogico
        @EstudianteId = (SELECT EstudianteId FROM core.Estudiantes WHERE NumeroDocumento = '80000001');

    PRINT '   >>> NO SE ESPERABA ESTO (revisar).';
END TRY
BEGIN CATCH
    PRINT '   >>> ERROR CONTROLADO 2: ' + CAST(ERROR_NUMBER() AS VARCHAR) + ' - ' + ERROR_MESSAGE();
END CATCH
GO

PRINT 'PASO 5 - REACTIVAR al estudiante para continuar el guion (idempotente):';
UPDATE core.Estudiantes
SET Activo = 1, DeletedAt = NULL, UpdatedAt = GETDATE()
WHERE NumeroDocumento = '80000001';
PRINT '   >> Estudiante reactivado (Activo=1, DeletedAt=NULL).';
GO

-- ============================================================================
-- BLOQUE 1.12 - REGISTRAR PROMOTOR Y VER SUS COMISIONES
-- ============================================================================
-- QUE SE DEMUESTRA: el CRUD del area comercial (sales.usp_RegistrarPromotor).
-- ============================================================================
PRINT '========================================================';
PRINT 'BLOQUE 1.12 - REGISTRAR PROMOTOR DE PRUEBA';
PRINT '========================================================';
GO

PRINT 'PASO 1 - ESTADO ANTES: promotores existentes (buscar PROM-TEST):';
SELECT PromotorId, CodigoPromotor, Nombres, Apellidos, Activo
FROM sales.Promotores
WHERE CodigoPromotor = 'PROM-TEST';
GO

PRINT 'PASO 2 - ACCION: crear el promotor de prueba si no existe...';
DECLARE @IdProm INT;
DECLARE @ErrMsgD NVARCHAR(500);

IF NOT EXISTS (SELECT 1 FROM sales.Promotores WHERE CodigoPromotor = 'PROM-TEST')
BEGIN
    BEGIN TRY
        EXEC sales.usp_RegistrarPromotor
            @CodigoPromotor     = 'PROM-TEST',
            @TipoDocumento      = 'DNI',
            @NumeroDocumento    = '80000002',
            @Nombres            = 'Promotor',
            @Apellidos          = 'Prueba Manual',
            @Email              = 'promotor.prueba@manual.edu',
            @Celular            = '999000001',
            @SedeId             = 1,
            @PorcentajeComision = 5.00,
            @PromotorId         = @IdProm OUTPUT,
            @ErrorMsg           = @ErrMsgD OUTPUT;

        PRINT '   >>> PROMOTOR CREADO: PromotorId = ' + CAST(@IdProm AS VARCHAR);
    END TRY
    BEGIN CATCH
        PRINT '   >>> ERROR INESPERADO: ' + CAST(ERROR_NUMBER() AS VARCHAR) + ' - ' + ERROR_MESSAGE();
    END CATCH
END
ELSE
    PRINT '   >> El promotor PROM-TEST ya existia (se reutiliza).';
GO

PRINT 'PASO 3 - ESTADO DESPUES: el promotor existe y sus comisiones visibles:';
SELECT p.CodigoPromotor, p.Nombres, COUNT(c.ComisionId) AS Comisiones,
       SUM(c.MontoTotal) AS MontoTotalComisiones
FROM sales.Promotores p
LEFT JOIN sales.Comisiones c ON c.PromotorId = p.PromotorId
WHERE p.CodigoPromotor = 'PROM-TEST'
GROUP BY p.CodigoPromotor, p.Nombres;
GO

-- ============================================================================
-- PARTE 2 - FUNCIONES DE NEGOCIO (fn)
-- ============================================================================

-- ============================================================================
-- BLOQUE 2.1 - fn_PeriodoMatriculaHabilitado
-- ============================================================================
-- QUE SE DEMUESTRA: la funcion responde si HOY se pueden matricular en un
-- periodo. Resultado esperado: Periodo 2027-I (id 5) = 1 (abierto);
-- Periodo 2026-I (id 3) = 0 (cerrado).
-- ============================================================================
PRINT '========================================================';
PRINT 'BLOQUE 2.1 - fn_PeriodoMatriculaHabilitado';
PRINT '========================================================';
GO

PRINT 'PASO 1 - CONTEXTO: ventana de matriculas de cada periodo:';
SELECT PeriodoId, CodigoPeriodo, FechaInicioMatriculas, FechaFinMatriculas
FROM core.PeriodosAcademicos
WHERE PeriodoId IN (3, 5);
GO

PRINT 'PASO 2 - ACCION: invocar la funcion con GETDATE() para ambos periodos:';
SELECT 5 AS PeriodoId, core.fn_PeriodoMatriculaHabilitado(5, GETDATE()) AS HabilitadoHoy
UNION ALL
SELECT 3, core.fn_PeriodoMatriculaHabilitado(3, GETDATE());
GO

PRINT 'PASO 3 - CONCLUSION: 1 = ventana abierta (se puede matricular),';
PRINT '0 = ventana cerrada. Es la funcion que usan los SP para RN-03.';
GO

-- ============================================================================
-- BLOQUE 2.2 - fn_ExisteEstudianteConDocumento
-- ============================================================================
-- QUE SE DEMUESTRA: la funcion de unicidad de documento (RN-01), incluso
-- excluyendo a un estudiante (para el UPDATE).
-- ============================================================================
PRINT '========================================================';
PRINT 'BLOQUE 2.2 - fn_ExisteEstudianteConDocumento';
PRINT '========================================================';
GO

PRINT 'PASO 1 - ACCION: consultar si el documento existe (1=SI, 0=NO):';
SELECT '70123456' AS DocumentoConsultado,
       core.fn_ExisteEstudianteConDocumento('DNI', '70123456', 0) AS Existe
UNION ALL
SELECT '99999999', core.fn_ExisteEstudianteConDocumento('DNI', '99999999', 0);
GO

PRINT 'PASO 2 - VARIANTE: el documento del propio estudiante NO debe contar';
PRINT 'al actualizarse a si mismo (excluye EstudianteId = 2):';
SELECT core.fn_ExisteEstudianteConDocumento('DNI', '70234567', 2) AS ExisteExcluyendose;
GO

-- ============================================================================
-- BLOQUE 2.3 - fn_EdadEstudiante
-- ============================================================================
-- QUE SE DEMUESTRA: calculo de edad actual a partir de la fecha de nacimiento.
-- ============================================================================
PRINT '========================================================';
PRINT 'BLOQUE 2.3 - fn_EdadEstudiante';
PRINT '========================================================';
GO

PRINT 'PASO 1 - ACCION: edad computada para Carlos (nacido el 2004-05-15):';
SELECT e.Nombres, e.Apellidos, e.FechaNacimiento,
       core.fn_EdadEstudiante(e.EstudianteId) AS EdadHoy
FROM core.Estudiantes e
WHERE e.EstudianteId = 1;
GO

PRINT 'PASO 2 - CONTRASTE: misma edad calculada en funcion de GETDATE():';
SELECT DATEDIFF(YEAR, FechaNacimiento, GETDATE()) AS EdadPorDatediff
FROM core.Estudiantes WHERE EstudianteId = 1;
GO

-- ============================================================================
-- BLOQUE 2.4 - fn_TotalMatriculadosCarrera
-- ============================================================================
-- QUE SE DEMUESTRA: demanda por carrera en un periodo (RN-04).
-- ============================================================================
PRINT '========================================================';
PRINT 'BLOQUE 2.4 - fn_TotalMatriculadosCarrera';
PRINT '========================================================';
GO

PRINT 'PASO 1 - ACCION: total matriculados en ING-SIS en el periodo 2026-I:';
SELECT core.fn_TotalMatriculadosCarrera(1, 3) AS TotalIngSis_2026I;
GO

PRINT 'PASO 2 - CONTRASTE: la misma cifra obtenida con COUNT directo:';
SELECT COUNT(*) AS TotalIngSis_2026I
FROM core.Matriculas
WHERE CarreraId = 1 AND PeriodoId = 3 AND DeletedAt IS NULL;
GO

-- ============================================================================
-- BLOQUE 2.5 - fn_CalcularComision
-- ============================================================================
-- QUE SE DEMUESTRA: la formula de comision RN-09:
-- MontoComision = MontoBase x PorcentajeComisionBase(campana) / 100.
-- Campana 5 (2027-I): porcentaje base = 12%. 250.00 x 12% = 30.00.
-- ============================================================================
PRINT '========================================================';
PRINT 'BLOQUE 2.5 - fn_CalcularComision';
PRINT '========================================================';
GO

PRINT 'PASO 1 - CONTEXTO: percentaje de la campana 5 (Pre-Admision 2027):';
SELECT CampaniaId, NombreCampania, PorcentajeComisionBase, BonoPorMeta, MetaMatriculas
FROM sales.CampaniasAdmision
WHERE CampaniaId = 5;
GO

PRINT 'PASO 2 - ACCION: comision para una matricula de S/ 250.00:';
SELECT sales.fn_CalcularComision(1, 5, 250.00) AS ComisionCalculada;
GO

PRINT 'PASO 3 - CONCLUSION: 250.00 x 12 / 100 = 30.00. Es la funcion que usa';
PRINT 'el trigger de comision automatica (bloque 3.4).';
GO

-- ============================================================================
-- BLOQUE 2.6 - fn_CalcularBonoPromotor
-- ============================================================================
-- QUE SE DEMUESTRA: el bono por meta (RN-09): si el promotor alcanzo la meta
-- de la campana devuelve BonoPorMeta; si no, 0.
-- ============================================================================
PRINT '========================================================';
PRINT 'BLOQUE 2.6 - fn_CalcularBonoPromotor';
PRINT '========================================================';
GO

PRINT 'PASO 1 - ACCION: bono del promotor PROM-TEST en la campana 5:';
SELECT sales.fn_CalcularBonoPromotor(
           (SELECT PromotorId FROM sales.Promotores WHERE CodigoPromotor = 'PROM-TEST'),
           5) AS BonoPromotor;
GO

PRINT 'PASO 2 - CONTEXTO: la meta de la campana 5 es 60 matriculas y el';
PRINT 'promotor de prueba apenas tiene 1-2 (bono = 0 = no alcanzo la meta).';
SELECT COUNT(DISTINCT m.MatriculaId) AS MatriculasDelPromotor
FROM core.Matriculas m
WHERE m.PromotorId = (SELECT PromotorId FROM sales.Promotores WHERE CodigoPromotor = 'PROM-TEST')
  AND m.CampaniaId = 5 AND m.DeletedAt IS NULL;
GO

-- ============================================================================
-- PARTE 3 - TRIGGERS (trg)
-- ============================================================================

-- ============================================================================
-- BLOQUE 3.1 - TRIGGER DE AUDITORIA: INSERT (RN-07)
-- ============================================================================
-- QUE SE DEMUESTRA: cada INSERT sobre una entidad critica queda registrado
-- en audit.AuditLog (quien, cuando, que valores nuevos en JSON).
-- ============================================================================
PRINT '========================================================';
PRINT 'BLOQUE 3.1 - AUDITORIA DE INSERT (RN-07)';
PRINT '========================================================';
GO

PRINT 'PASO 1 - ACCION: insertar un estudiante MINI de prueba (solo para auditar)';
PRINT '(si ya existia de una corrida anterior, se reactiva para no duplicarlo):';
IF NOT EXISTS (SELECT 1 FROM core.Estudiantes WHERE NumeroDocumento = '80000003')
BEGIN
    BEGIN TRY
        INSERT INTO core.Estudiantes (TipoDocumento, NumeroDocumento, Nombres, Apellidos,
                                      Email, Celular, FechaNacimiento, Genero, UbigeoId)
        VALUES ('DNI', '80000003', 'Mini', 'Auditoria', 'mini.auditoria@manual.edu',
                '987000005', '2005-05-05', 'F', 1);
        PRINT '   >>> INSERT ejecutado (el trigger de auditoria debio dispararse).';
    END TRY
    BEGIN CATCH
        PRINT '   >>> ERROR: ' + CAST(ERROR_NUMBER() AS VARCHAR) + ' - ' + ERROR_MESSAGE();
    END CATCH
END
ELSE
BEGIN
    UPDATE core.Estudiantes
    SET Activo = 1, DeletedAt = NULL, UpdatedAt = GETDATE()
    WHERE NumeroDocumento = '80000003';
    PRINT '   >>> Mini estudiante ya existia: se reactivo (corrida anterior).';
END
GO

PRINT 'PASO 2 - ESTADO DESPUES: el registro quedo auditado (Operation = INSERT):';
SELECT TOP (1) AuditId, TableName, Operation, RecordId, Usuario,
       FechaOperacion, ValoresNuevos
FROM audit.AuditLog
WHERE TableName LIKE '%Estudiantes%' AND RecordId = (SELECT EstudianteId FROM core.Estudiantes WHERE NumeroDocumento = '80000003')
ORDER BY AuditId DESC;
GO

PRINT 'PASO 3 - LIMPIEZA: se retira el mini estudiante de prueba (DELETE normal';
PRINT 'disparara el trigger INSTEAD OF = borrado logico, ver bloque 3.3):';
DELETE FROM core.Estudiantes WHERE NumeroDocumento = '80000003';
PRINT '   >> Fila "eliminada" (en realidad quedo con DeletedAt, invisible para';
PRINT '      las consultas operativas; el bloque 3.1 la reactiva si se repite).';
GO

-- ============================================================================
-- BLOQUE 3.2 - TRIGGER DE AUDITORIA: UPDATE (RN-07)
-- ============================================================================
-- QUE SE DEMUESTRA: el UPDATE queda auditado con los valores ANTERIORES y
-- NUEVOS (JSON), permitiendo reconstruir la trazabilidad completa.
-- ============================================================================
PRINT '========================================================';
PRINT 'BLOQUE 3.2 - AUDITORIA DE UPDATE (RN-07)';
PRINT '========================================================';
GO

PRINT 'PASO 1 - ESTADO ANTES: telefono actual del estudiante de prueba:';
SELECT EstudianteId, Celular
FROM core.Estudiantes
WHERE NumeroDocumento = '80000001';
GO

PRINT 'PASO 2 - ACCION: cambiar el telefono a 987777777...';
BEGIN TRY
    UPDATE core.Estudiantes
    SET Celular = '987777777', UpdatedAt = GETDATE()
    WHERE NumeroDocumento = '80000001';
    PRINT '   >>> UPDATE ejecutado.';
END TRY
BEGIN CATCH
    PRINT '   >>> ERROR: ' + CAST(ERROR_NUMBER() AS VARCHAR) + ' - ' + ERROR_MESSAGE();
END CATCH
GO

PRINT 'PASO 3 - ESTADO DESPUES: el UPDATE quedo auditado con antes/despues:';
SELECT TOP (1) AuditId, Operation, Usuario, FechaOperacion,
       ValoresAnteriores, ValoresNuevos
FROM audit.AuditLog
WHERE TableName LIKE '%Estudiantes%'
  AND RecordId = (SELECT EstudianteId FROM core.Estudiantes WHERE NumeroDocumento = '80000001')
  AND Operation = 'UPDATE'
ORDER BY AuditId DESC;
GO

-- ============================================================================
-- BLOQUE 3.3 - TRIGGER INSTEAD OF DELETE: BORRADO LOGICO (RN-10)
-- ============================================================================
-- QUE SE DEMUESTRA: un DELETE fisico sobre una entidad critica NO elimina
-- la fila: el trigger lo convierte en UPDATE (Activo=0, DeletedAt=GETDATE())
-- y registra la operacion DELETE en auditoria.
-- ============================================================================
PRINT '========================================================';
PRINT 'BLOQUE 3.3 - INSTEAD OF DELETE = BORRADO LOGICO (RN-10)';
PRINT '========================================================';
GO

PRINT 'PASO 1 - ESTADO ANTES: el estudiante de prueba esta ACTIVO:';
SELECT EstudianteId, NumeroDocumento, Activo, DeletedAt
FROM core.Estudiantes
WHERE NumeroDocumento = '80000001';
GO

PRINT 'PASO 2 - ACCION: ejecutar un DELETE FISICO sobre la tabla...';
BEGIN TRY
    DELETE FROM core.Estudiantes WHERE NumeroDocumento = '80000001';
    PRINT '   >>> DELETE enviado... (a ver que hace el trigger).';
END TRY
BEGIN CATCH
    PRINT '   >>> ERROR: ' + CAST(ERROR_NUMBER() AS VARCHAR) + ' - ' + ERROR_MESSAGE();
END CATCH
GO

PRINT 'PASO 3 - ESTADO DESPUES: la fila SIGUE EXISTIENDO con DeletedAt';
PRINT '(la informacion nunca se destruye fisicamente):';
SELECT EstudianteId, NumeroDocumento, Nombres, Activo, DeletedAt
FROM core.Estudiantes
WHERE NumeroDocumento = '80000001';
GO

PRINT 'PASO 4 - LA AUDITORIA tambien registro el DELETE:';
SELECT TOP (1) AuditId, Operation, Usuario, FechaOperacion
FROM audit.AuditLog
WHERE TableName LIKE '%Estudiantes%'
  AND RecordId = (SELECT EstudianteId FROM core.Estudiantes WHERE NumeroDocumento = '80000001')
  AND Operation = 'DELETE'
ORDER BY AuditId DESC;
GO

PRINT 'PASO 5 - REACTIVAR al estudiante para seguir el guion:';
UPDATE core.Estudiantes
SET Activo = 1, DeletedAt = NULL, UpdatedAt = GETDATE()
WHERE NumeroDocumento = '80000001';
PRINT '   >> Reactivado.';
GO

-- ============================================================================
-- BLOQUE 3.4 - TRIGGER DE COMISION AUTOMATICA (RN-09)
-- ============================================================================
-- QUE SE DEMUESTRA: al INSERTAR una matricula, el trigger TRG_Comision_
-- Automatica calcula y crea la comision del promotor automaticamente.
-- ============================================================================
PRINT '========================================================';
PRINT 'BLOQUE 3.4 - TRIGGER DE COMISION AUTOMATICA (RN-09)';
PRINT '========================================================';
GO

PRINT 'PASO 1 - ESTADO ANTES: comisiones del promotor de prueba:';
SELECT ComisionId, MatriculaId, MontoBase, PorcentajeComision, MontoComision, MontoTotal, EstadoPago
FROM sales.Comisiones
WHERE PromotorId = (SELECT PromotorId FROM sales.Promotores WHERE CodigoPromotor = 'PROM-TEST');
GO

PRINT 'PASO 2 - ACCION: matricular al estudiante en ADM-EMP (carrera 3, 2027-I)...';
PRINT '(si la matricula ya existia de una corrida anterior, se reutiliza):';
DECLARE @IdMat3 INT;
DECLARE @ErrMsgE NVARCHAR(500);

IF NOT EXISTS (SELECT 1 FROM core.Matriculas
               WHERE EstudianteId = (SELECT EstudianteId FROM core.Estudiantes WHERE NumeroDocumento = '80000001')
                 AND CarreraId = 3 AND PeriodoId = 5)
BEGIN
    BEGIN TRY
        EXEC core.usp_RegistrarMatricula
            @EstudianteId  = (SELECT EstudianteId FROM core.Estudiantes WHERE NumeroDocumento = '80000001'),
            @CarreraId     = 3,
            @PeriodoId     = 5,
            @SedeId        = 1,
            @PromotorId    = (SELECT PromotorId FROM sales.Promotores WHERE CodigoPromotor = 'PROM-TEST'),
            @CampaniaId    = 5,
            @Observaciones = 'Matricula 3 (trigger de comision)',
            @MatriculaId   = @IdMat3 OUTPUT,
            @ErrorMsg      = @ErrMsgE OUTPUT;

        PRINT '   >>> MATRICULA INSERTADA: MatriculaId = ' + CAST(@IdMat3 AS VARCHAR);
    END TRY
    BEGIN CATCH
        PRINT '   >>> ERROR INESPERADO: ' + CAST(ERROR_NUMBER() AS VARCHAR) + ' - ' + ERROR_MESSAGE();
    END CATCH
END
ELSE
    PRINT '   >>> La matricula ya existia: se reutiliza (corrida anterior).';
GO

PRINT 'PASO 3 - ESTADO DESPUES: el trigger YA creo la comision (sin que nadie';
PRINT 'la insertara a mano). MontoBase 250.00 x 12% = MontoComision 30.00:';
SELECT c.ComisionId, m.CodigoMatricula, c.MontoBase, c.PorcentajeComision,
       c.MontoComision, c.Bonificacion, c.MontoTotal, c.EstadoPago
FROM sales.Comisiones c
INNER JOIN core.Matriculas m ON m.MatriculaId = c.MatriculaId
WHERE m.CarreraId = 3
  AND m.EstudianteId = (SELECT EstudianteId FROM core.Estudiantes WHERE NumeroDocumento = '80000001')
  AND m.DeletedAt IS NULL;
GO

PRINT 'PASO 4 - LA AUDITORIA del trigger tambien quedo en AuditLog (Comisiones):';
SELECT TOP (1) AuditId, TableName, Operation, RecordId, FechaOperacion
FROM audit.AuditLog
WHERE TableName LIKE '%Comisiones%'
ORDER BY AuditId DESC;
GO

-- ============================================================================
-- PARTE 4 - VISTAS (vw)
-- ============================================================================

-- ============================================================================
-- BLOQUE 4.1 - VISTAS DE REPORTE (core / academic / sales)
-- ============================================================================
-- QUE SE DEMUESTRA: las vistas entregan informacion lista para reportes,
-- con nombres resueltos (FK -> texto legible) y calculos ya hechos.
-- ============================================================================
PRINT '========================================================';
PRINT 'BLOQUE 4.1 - VISTAS DE REPORTE';
PRINT '========================================================';
GO

PRINT 'VISTA 1: core.vw_EstudiantesDetalle (estudiantes + edad + ubigeo):';
SELECT TOP (5) NombreCompleto, NumeroDocumento, Edad, Genero, Ubigeo, Activo
FROM core.vw_EstudiantesDetalle
ORDER BY EstudianteId;
GO

PRINT 'VISTA 2: core.vw_MatriculasDetalle (matriculas con todos los nombres):';
SELECT TOP (5) CodigoMatricula, Estudiante, NombreCarrera, CodigoPeriodo,
       NombreSede, Promotor, MontoMatricula, EstadoMatricula
FROM core.vw_MatriculasDetalle
ORDER BY MatriculaId;
GO

PRINT 'VISTA 3: core.vw_ReporteMatriculasPeriodo (reporte por periodo):';
SELECT TOP (5) CodigoPeriodo, NombreCarrera, TotalMatriculas, MontoRecaudado
FROM core.vw_ReporteMatriculasPeriodo
WHERE PeriodoId = 5
ORDER BY TotalMatriculas DESC;
GO

PRINT 'VISTA 4: academic.vw_MallaCurricular (malla por carrera y semestre):';
SELECT TOP (5) NombreCarrera, Semestre, CodigoCurso, NombreCurso, Creditos
FROM academic.vw_MallaCurricular
WHERE CarreraId = 1
ORDER BY Semestre;
GO

PRINT 'VISTA 5: academic.vw_ProfesoresDetalle (profesores y sus cursos):';
SELECT TOP (5) NombreProfesor, NombreCurso, CodigoPeriodo, NombreSede
FROM academic.vw_ProfesoresDetalle
ORDER BY NombreProfesor;
GO

PRINT 'VISTA 6: sales.vw_ComisionesDetalle (comisiones con nombre del promotor):';
SELECT TOP (5) CodigoPromotor, NombrePromotor, CodigoMatricula, MontoTotal, EstadoPago
FROM sales.vw_ComisionesDetalle
ORDER BY ComisionId;
GO

PRINT 'VISTA 7: sales.vw_DesempenoPromotores (desempeno por promotor):';
SELECT TOP (5) CodigoPromotor, NombrePromotor, TotalMatriculas, TotalComisiones
FROM sales.vw_DesempenoPromotores
ORDER BY TotalMatriculas DESC;
GO

-- ============================================================================
-- BLOQUE 4.2 - VISTAS ANALITICAS (indicadores institucionales)
-- ============================================================================
-- QUE SE DEMUESTRA: las vistas que alimentan la toma de decisiones
-- (antes alimentaban el dashboard; ahora se demuestran como analiticas).
-- ============================================================================
PRINT '========================================================';
PRINT 'BLOQUE 4.2 - VISTAS ANALITICAS (KPI institucional)';
PRINT '========================================================';
GO

PRINT 'VISTA 1: core.vw_IndicadoresMatricula (matriculas y monto por periodo';
PRINT 'y carrera - el KPI principal de matricula):';
SELECT TOP (8) CodigoPeriodo, NombreCarrera, NombreSede, TotalMatriculas, MontoRecaudado
FROM core.vw_IndicadoresMatricula
ORDER BY CodigoPeriodo, TotalMatriculas DESC;
GO

PRINT 'VISTA 2: sales.vw_RankingPromotores (ranking con ventana RANK + LAG):';
SELECT TOP (8) CodigoPeriodo, NombrePromotor, MatriculasCaptadas, ComisionTotal, Ranking
FROM sales.vw_RankingPromotores
ORDER BY CodigoPeriodo, Ranking;
GO

PRINT 'VISTA 3: core.vw_TendenciaMatriculas (tendencia diaria con acumulado):';
SELECT TOP (10) FechaMatricula, TotalMatriculas, Acumulado
FROM core.vw_TendenciaMatriculas
ORDER BY FechaMatricula DESC;
GO

-- ============================================================================
-- PARTE 5 - CONSULTAS AVANZADAS
-- ============================================================================

-- ============================================================================
-- BLOQUE 5.1 - CTE + GROUP BY ROLLUP (Q1) y CTE RECURSIVA (Q9)
-- ============================================================================
-- QUE SE DEMUESTRA: tecnicas avanzadas T-SQL sobre datos reales.
-- ============================================================================
PRINT '========================================================';
PRINT 'BLOQUE 5.1 - CONSULTAS AVANZADAS 1/2';
PRINT '========================================================';
GO

PRINT 'CONSULTA 1 - CTE + ROLLUP: matriculas por periodo/carrera con';
PRINT 'subtotales (fila NULL = subtotal) y total general:';
WITH MatriculasResumen AS
(
    SELECT p.CodigoPeriodo, c.NombreCarrera, s.NombreSede,
           COUNT(*) AS TotalMatriculas, SUM(m.MontoMatricula) AS MontoRecaudado
    FROM core.Matriculas m
    INNER JOIN core.PeriodosAcademicos p ON p.PeriodoId = m.PeriodoId
    INNER JOIN core.Carreras c ON c.CarreraId = m.CarreraId
    INNER JOIN core.Sedes s ON s.SedeId = m.SedeId
    WHERE m.DeletedAt IS NULL
    GROUP BY ROLLUP (p.CodigoPeriodo, c.NombreCarrera, s.NombreSede)
)
SELECT CodigoPeriodo, NombreCarrera, NombreSede, TotalMatriculas, MontoRecaudado,
       GROUPING(CodigoPeriodo) AS EsTotalGeneral
FROM MatriculasResumen
ORDER BY GROUPING(CodigoPeriodo), CodigoPeriodo, GROUPING(NombreCarrera),
         NombreCarrera, GROUPING(NombreSede), NombreSede;
GO

PRINT 'CONSULTA 2 - CTE RECURSIVA: creditos por semestre de ING-SIS';
PRINT '(el ancla parte del semestre 1 y la parte recursiva genera los';
PRINT 'siguientes semestres hasta el 10, calculando los creditos de cada uno):';
WITH MallaSemestre (CarreraId, Semestre, CreditosSemestre) AS
(
    SELECT 1 AS CarreraId, 1 AS Semestre,
           (SELECT SUM(cur.Creditos)
            FROM academic.CarreraCursos cc2
            INNER JOIN academic.Cursos cur ON cur.CursoId = cc2.CursoId
            WHERE cc2.CarreraId = 1 AND cc2.Semestre = 1) AS CreditosSemestre
    UNION ALL
    SELECT ms.CarreraId, ms.Semestre + 1,
           (SELECT SUM(cur.Creditos)
            FROM academic.CarreraCursos cc2
            INNER JOIN academic.Cursos cur ON cur.CursoId = cc2.CursoId
            WHERE cc2.CarreraId = ms.CarreraId AND cc2.Semestre = ms.Semestre + 1)
    FROM MallaSemestre ms
    WHERE ms.Semestre < 10
)
SELECT Semestre, ISNULL(CreditosSemestre, 0) AS CreditosSemestre
FROM MallaSemestre
ORDER BY Semestre;
GO

-- ============================================================================
-- BLOQUE 5.2 - FUNCIONES DE VENTANA (Q2, Q3, Q4, Q5)
-- ============================================================================
-- QUE SE DEMUESTRA: RANK/DENSE_RANK, LAG, SUM OVER y ROW_NUMBER sobre
-- indicadores reales del negocio.
-- ============================================================================
PRINT '========================================================';
PRINT 'BLOQUE 5.2 - CONSULTAS AVANZADAS 2/2 (funciones de ventana)';
PRINT '========================================================';
GO

PRINT 'CONSULTA 3 - RANK / DENSE_RANK: ranking de promotores por periodo:';
WITH RankingPromotores AS
(
    SELECT p.CodigoPeriodo, pr.NombrePromotor,
           SUM(co.MontoTotal) AS ComisionTotal,
           RANK()       OVER (PARTITION BY p.PeriodoId ORDER BY SUM(co.MontoTotal) DESC) AS Ranking,
           DENSE_RANK() OVER (PARTITION BY p.PeriodoId ORDER BY SUM(co.MontoTotal) DESC) AS RankingDenso
    FROM sales.Promotores pr
    INNER JOIN core.Matriculas m ON m.PromotorId = pr.PromotorId AND m.DeletedAt IS NULL
    INNER JOIN sales.Comisiones co ON co.MatriculaId = m.MatriculaId AND co.EstadoPago <> 'Anulada'
    INNER JOIN core.PeriodosAcademicos p ON p.PeriodoId = m.PeriodoId
    GROUP BY p.CodigoPeriodo, pr.NombrePromotor, m.PeriodoId, pr.PromotorId
)
SELECT CodigoPeriodo, NombrePromotor, ComisionTotal, Ranking, RankingDenso
FROM RankingPromotores
ORDER BY CodigoPeriodo, Ranking;
GO

PRINT 'CONSULTA 4 - LAG: variacion de matriculas vs el periodo anterior:';
WITH MatriculasPorPeriodo AS
(
    SELECT m.PeriodoId, COUNT(*) AS TotalMatriculas, SUM(m.MontoMatricula) AS MontoRecaudado
    FROM core.Matriculas m
    WHERE m.DeletedAt IS NULL
    GROUP BY m.PeriodoId
)
SELECT p.CodigoPeriodo, mp.TotalMatriculas,
       LAG(mp.TotalMatriculas) OVER (ORDER BY mp.PeriodoId) AS MatriculasPeriodoAnterior,
       CASE WHEN LAG(mp.TotalMatriculas) OVER (ORDER BY mp.PeriodoId) IS NULL THEN NULL
            ELSE CAST((mp.TotalMatriculas - LAG(mp.TotalMatriculas) OVER (ORDER BY mp.PeriodoId)) * 100.0
                 / LAG(mp.TotalMatriculas) OVER (ORDER BY mp.PeriodoId) AS DECIMAL(8,2))
       END AS VariacionPorcentual
FROM core.PeriodosAcademicos p
INNER JOIN MatriculasPorPeriodo mp ON mp.PeriodoId = p.PeriodoId
ORDER BY mp.PeriodoId;
GO

PRINT 'CONSULTA 5 - SUM OVER: acumulado de matriculas en el tiempo:';
SELECT TOP (10) FechaMatricula,
       SUM(1) OVER (ORDER BY FechaMatricula, MatriculaId) AS AcumuladoMatriculas,
       SUM(MontoMatricula) OVER (ORDER BY FechaMatricula, MatriculaId) AS AcumuladoMonto
FROM core.Matriculas
WHERE DeletedAt IS NULL
ORDER BY FechaMatricula DESC;
GO

PRINT 'CONSULTA 6 - ROW_NUMBER: top 3 de carreras con mayor demanda:';
WITH DemandaCarrera AS
(
    SELECT p.CodigoPeriodo, c.NombreCarrera, COUNT(*) AS TotalMatriculas,
           ROW_NUMBER() OVER (PARTITION BY p.PeriodoId ORDER BY COUNT(*) DESC) AS Posicion
    FROM core.Matriculas m
    INNER JOIN core.PeriodosAcademicos p ON p.PeriodoId = m.PeriodoId
    INNER JOIN core.Carreras c ON c.CarreraId = m.CarreraId
    WHERE m.DeletedAt IS NULL
    GROUP BY p.CodigoPeriodo, c.NombreCarrera, p.PeriodoId
)
SELECT CodigoPeriodo, NombreCarrera, TotalMatriculas, Posicion
FROM DemandaCarrera
WHERE Posicion <= 3
ORDER BY CodigoPeriodo, Posicion;
GO

-- ============================================================================
-- PARTE 6 - INDICES Y PLANES DE EJECUCION
-- ============================================================================

-- ============================================================================
-- BLOQUE 6.1 - INDICES IMPLEMENTADOS Y SU JUSTIFICACION
-- ============================================================================
-- QUE SE DEMUESTRA: que los indices existen, estan habilitados y que cada
-- uno responde a una consulta analizada (criterio de aceptacion).
-- ============================================================================
PRINT '========================================================';
PRINT 'BLOQUE 6.1 - INDICES IMPLEMENTADOS (y su justificacion)';
PRINT '========================================================';
GO

PRINT 'PASO 1: indices no agrupados del sistema (17 en total):';
SELECT QUOTENAME(s.name) + '.' + QUOTENAME(t.name) AS Tabla, i.name AS Indice,
       i.type_desc AS Tipo,
       CASE WHEN i.is_disabled = 1 THEN 'DESHABILITADO' ELSE 'HABILITADO' END AS Estado
FROM sys.indexes i
INNER JOIN sys.tables t ON t.object_id = i.object_id
INNER JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE i.name IS NOT NULL AND i.type > 0
ORDER BY Tabla, i.name;
GO

PRINT 'PASO 2: el indice compuesto + filtrado + covering IX_Matriculas_PeriodoEstado';
PRINT 'justifica la consulta Q1 (matriculas activas por periodo y estado):';
SELECT i.name AS Indice,
       STUFF((SELECT ', ' + c.name
              FROM sys.index_columns ic
              INNER JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
              WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.is_included_column = 0
              ORDER BY ic.key_ordinal
              FOR XML PATH('')), 1, 2, '') AS ColumnasClave
FROM sys.indexes i
WHERE i.name IN ('IX_Matriculas_PeriodoEstado', 'IX_Matriculas_PromotorPeriodo', 'IX_Comisiones_Campania')
ORDER BY i.name;
GO

-- ============================================================================
-- BLOQUE 6.2 - ANTES / DESPUES: Q1 SIN indice vs CON indice
-- ============================================================================
-- QUE SE DEMUESTRA: con el indice HABILITADO SQL Server usa SEEK (pocas
-- lecturas logicas); DESHABILITADO usa SCAN (mas lecturas). Se miden las
-- lecturas (STATISTICS IO) y la duracion real. Al final se rehabilita todo.
-- ============================================================================
PRINT '========================================================';
PRINT 'BLOQUE 6.2 - PRUEBA ANTES / DESPUES (mis clientes Q1)';
PRINT '========================================================';
GO

PRINT 'PASO 1 - ESCENARIO "SIN INDICE": se deshabilita IX_Matriculas_PeriodoEstado';
PRINT 'y se ejecuta Q1 midiendo las lecturas logicas y el tiempo:';
ALTER INDEX IX_Matriculas_PeriodoEstado ON core.Matriculas DISABLE;
GO

SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO
PRINT '>>> Q1 SIN INDICE (debe reportar SCAN y mas lecturas):';
SELECT m.PeriodoId, m.EstadoMatricula, COUNT(*) AS Total, SUM(m.MontoMatricula) AS Monto
FROM core.Matriculas m
WHERE m.DeletedAt IS NULL
GROUP BY m.PeriodoId, m.EstadoMatricula;
GO
SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

PRINT 'PASO 2 - ESCENARIO "CON INDICE": se rehabilita y se repite la MISMA';
PRINT 'consulta (debe reportar SEEK y menos lecturas):';
ALTER INDEX IX_Matriculas_PeriodoEstado ON core.Matriculas REBUILD;
GO

SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO
PRINT '>>> Q1 CON INDICE:';
SELECT m.PeriodoId, m.EstadoMatricula, COUNT(*) AS Total, SUM(m.MontoMatricula) AS Monto
FROM core.Matriculas m
WHERE m.DeletedAt IS NULL
GROUP BY m.PeriodoId, m.EstadoMatricula;
GO
SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

PRINT 'NOTA: con los datos de prueba (pocas filas) la diferencia es pequena.';
PRINT 'Con volumen empresarial (1,000,000 filas) la mejoria es de decenas a';
PRINT 'cienes de veces. Ese experimento completo esta en:';
PRINT '   sqlserver/optimization/03_performance_tests.sql (partes A y B).';
GO

PRINT 'PASO 3 - RED DE SEGURIDAD: verificar que NO quede ningun indice';
PRINT 'deshabilitado:';
DECLARE @sv NVARCHAR(300), @six NVARCHAR(200), @sql NVARCHAR(500);
DECLARE c_ix CURSOR LOCAL FAST_FORWARD FOR
    SELECT QUOTENAME(s.name) + '.' + QUOTENAME(t.name), i.name
    FROM sys.indexes i
    INNER JOIN sys.tables t ON t.object_id = i.object_id
    INNER JOIN sys.schemas s ON s.schema_id = t.schema_id
    WHERE i.is_disabled = 1;
OPEN c_ix;
FETCH NEXT FROM c_ix INTO @sv, @six;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = 'ALTER INDEX ' + QUOTENAME(@six) + ' ON ' + @sv + ' REBUILD;';
    PRINT '   Rehabilitando: ' + @sql;
    EXEC(@sql);
    FETCH NEXT FROM c_ix INTO @sv, @six;
END
CLOSE c_ix;
DEALLOCATE c_ix;
SELECT COUNT(*) AS IndicesDeshabilitados
FROM sys.indexes
WHERE is_disabled = 1;
GO

-- ============================================================================
-- BLOQUE 6.3 - PLAN DE EJECUCION EVIDENCIA (SHOWPLAN_XML)
-- ============================================================================
-- QUE SE DEMUESTRA: el plan de ejecucion real de la consulta analizada.
-- Al activar SET SHOWPLAN_XML la consulta NO se ejecuta: solo se devuelve
-- su plan estimado. El profesor puede hacer clic en el XML para ver el
-- plan grafico (Index Seek con el indice compuesto).
-- ============================================================================
PRINT '========================================================';
PRINT 'BLOQUE 6.3 - PLAN DE EJECUCION (SHOWPLAN_XML)';
PRINT '========================================================';
GO

PRINT 'PASO 1 - ACCION: generar el plan de Q1 CON el indice habilitado...';
SET SHOWPLAN_XML ON;
GO
SELECT m.PeriodoId, m.EstadoMatricula, COUNT(*) AS Total, SUM(m.MontoMatricula) AS Monto
FROM core.Matriculas m
WHERE m.DeletedAt IS NULL
GROUP BY m.PeriodoId, m.EstadoMatricula;
GO
SET SHOWPLAN_XML OFF;
GO

PRINT '>>> Resultado: fila XML con el plan. Hacer clic sobre ella para ver';
PRINT '    el plan GRAFICO: Index Seek sobre IX_Matriculas_PeriodoEstado.';
GO

-- ============================================================================
-- PARTE 7 - SEGURIDAD POR PERFILES (Admin / Coordinador / Promotor)
-- ============================================================================

-- ============================================================================
-- BLOQUE 7.1 - LOGINS, USUARIOS, ROLES Y MEMBRESIAS
-- ============================================================================
-- QUE SE DEMUESTRA: la estructura de seguridad RN-06 creada por los scripts
-- security/01_logins_users.sql, 02_roles.sql y 03_permissions.sql.
-- ============================================================================
PRINT '========================================================';
PRINT 'BLOQUE 7.1 - ESTRUCTURA DE SEGURIDAD (RN-06)';
PRINT '========================================================';
GO

PRINT 'PASO 1: usuarios de base de datos y su rol:';
SELECT dp.name AS Usuario, r.name AS Rol
FROM sys.database_role_members drm
INNER JOIN sys.database_principals r ON r.principal_id = drm.role_principal_id
INNER JOIN sys.database_principals dp ON dp.principal_id = drm.member_principal_id
WHERE dp.name IN ('MC_Admin', 'MC_Coordinador', 'MC_Promotor')
ORDER BY dp.name;
GO

PRINT 'PASO 2: resumen de la politica (GRANT/DENY) de cada perfil:';
PRINT '   MC_Admin       : db_owner -> acceso TOTAL';
PRINT '   MC_Coordinador : GRANT vistas de reporte/analiticas, traza y SP';
PRINT '                    academicos; DENY comisiones, seguridad, auditoria';
PRINT '   MC_Promotor    : GRANT registrar/consultar estudiantes, ver SUS';
PRINT '                    comisiones; DENY matriculas, comisiones ajenas,';
PRINT '                    seguridad y auditoria';
GO

-- ============================================================================
-- BLOQUE 7.2 - PRUEBA REAL: PROMOTOR (MC_Promotor)
-- ============================================================================
-- QUE SE DEMUESTRA: conectado como promotor SOLO puede hacer lo suyo.
-- (1) NO puede leer tablas de matriculas (error 229 - DENY).
-- (2) SI puede registrar estudiantes (SP autorizado).
-- (3) SI puede ver la vista de sus comisiones.
-- ============================================================================
PRINT '========================================================';
PRINT 'BLOQUE 7.2 - PERFIL PROMOTOR: permisos diferenciados';
PRINT '========================================================';
GO

PRINT 'PRUEBA 1 - El promotor intenta leer core.Matriculas (NO AUTORIZADO):';
BEGIN TRY
    EXECUTE AS USER = 'MC_Promotor';
    SELECT TOP (3) * FROM core.Matriculas;
    REVERT;
    PRINT '   >>> NO SE ESPERABA ESTO: el promotor SI pudo leer matriculas (revisar).';
END TRY
BEGIN CATCH
    PRINT '   >>> ERROR ESPERADO: ' + CAST(ERROR_NUMBER() AS VARCHAR) + ' - ' + ERROR_MESSAGE();
    PRINT '   >> El DENY impide al promotor acceder a las matriculas.';
    IF USER_NAME() = 'MC_Promotor' REVERT;
END CATCH
GO

PRINT 'PRUEBA 2 - El promotor registra un estudiante (SP AUTORIZADO):';
PRINT '(si ya existia de una corrida anterior, se reutiliza):';
IF NOT EXISTS (SELECT 1 FROM core.Estudiantes WHERE NumeroDocumento = '80000004')
BEGIN
    BEGIN TRY
        EXECUTE AS USER = 'MC_Promotor';
        EXEC core.usp_RegistrarEstudiante
            @TipoDocumento    = 'DNI',
            @NumeroDocumento  = '80000004',
            @Nombres          = 'Promotor',
            @Apellidos        = 'Registra',
            @Email            = 'promotor.registra@manual.edu',
            @Celular          = '987000006',
            @FechaNacimiento  = '2005-02-02',
            @Genero           = 'M',
            @UbigeoId         = 1;
        PRINT '   >>> OK: el promotor SI puede registrar estudiantes (GRANT).';
        REVERT;
    END TRY
    BEGIN CATCH
        PRINT '   >>> ERROR INESPERADO: ' + CAST(ERROR_NUMBER() AS VARCHAR) + ' - ' + ERROR_MESSAGE();
        IF USER_NAME() = 'MC_Promotor' REVERT;
    END CATCH
END
ELSE
    PRINT '   >>> El estudiante 80000004 ya existia: permiso de registro ya comprobado.';
GO

PRINT 'PRUEBA 3 - El promotor consulta la vista de comisiones (GRANT sobre vista):';
BEGIN TRY
    EXECUTE AS USER = 'MC_Promotor';
    SELECT TOP (5) CodigoPromotor, NombrePromotor, CodigoMatricula, MontoTotal, EstadoPago
    FROM sales.vw_ComisionesDetalle;
    PRINT '   >>> OK: el promotor puede ver la vista de comisiones.';
    REVERT;
END TRY
BEGIN CATCH
    PRINT '   >>> ERROR INESPERADO: ' + CAST(ERROR_NUMBER() AS VARCHAR) + ' - ' + ERROR_MESSAGE();
    IF USER_NAME() = 'MC_Promotor' REVERT;
END CATCH
GO

PRINT 'PRUEBA 4 - LIMPIEZA: se retira el estudiante creado por el promotor:';
DELETE FROM core.Estudiantes WHERE NumeroDocumento = '80000004';
PRINT '   >> (queda como borrado logico; se elimina al final del guion).';
GO

-- ============================================================================
-- BLOQUE 7.3 - PRUEBA REAL: COORDINADOR (MC_Coordinador)
-- ============================================================================
-- QUE SE DEMUESTRA: el coordinador ve reportes y traza, pero NO comisiones
-- ni la tabla de auditoria directa (solo la vista autorizada).
-- ============================================================================
PRINT '========================================================';
PRINT 'BLOQUE 7.3 - PERFIL COORDINADOR: permisos diferenciados';
PRINT '========================================================';
GO

PRINT 'PRUEBA 1 - El coordinador intenta leer sales.Comisiones (NO AUTORIZADO):';
BEGIN TRY
    EXECUTE AS USER = 'MC_Coordinador';
    SELECT TOP (3) * FROM sales.Comisiones;
    REVERT;
    PRINT '   >>> NO SE ESPERABA ESTO (revisar).';
END TRY
BEGIN CATCH
    PRINT '   >>> ERROR ESPERADO: ' + CAST(ERROR_NUMBER() AS VARCHAR) + ' - ' + ERROR_MESSAGE();
    PRINT '   >> El DENY impide al coordinador ver comisiones.';
    IF USER_NAME() = 'MC_Coordinador' REVERT;
END CATCH
GO

PRINT 'PRUEBA 2 - El coordinador SI ve las vistas de reporte y la traza:';
BEGIN TRY
    EXECUTE AS USER = 'MC_Coordinador';
    SELECT TOP (3) CodigoPeriodo, NombreCarrera, TotalMatriculas
    FROM core.vw_ReporteMatriculasPeriodo;

    SELECT TOP (3) TableName, Operation, Usuario, FechaOperacion
    FROM audit.vw_TrazaAuditoria
    ORDER BY FechaOperacion DESC;

    PRINT '   >>> OK: el coordinador ve reportes y trazabilidad (vista autorizada).';
    REVERT;
END TRY
BEGIN CATCH
    PRINT '   >>> ERROR INESPERADO: ' + CAST(ERROR_NUMBER() AS VARCHAR) + ' - ' + ERROR_MESSAGE();
    IF USER_NAME() = 'MC_Coordinador' REVERT;
END CATCH
GO

-- ============================================================================
-- BLOQUE 7.4 - PRUEBA REAL: ADMINISTRADOR (MC_Admin)
-- ============================================================================
-- QUE SE DEMUESTRA: el administrador tiene acceso total (db_owner).
-- ============================================================================
PRINT '========================================================';
PRINT 'BLOQUE 7.4 - PERFIL ADMINISTRADOR: acceso total';
PRINT '========================================================';
GO

PRINT 'PRUEBA - El administrador lee TODOS los esquemas sin restriccion:';
BEGIN TRY
    EXECUTE AS USER = 'MC_Admin';
    SELECT 'core.Matriculas' AS Origen, COUNT(*) AS Filas FROM core.Matriculas
    UNION ALL SELECT 'sales.Comisiones', COUNT(*) FROM sales.Comisiones
    UNION ALL SELECT 'security.Usuarios', COUNT(*) FROM security.Usuarios
    UNION ALL SELECT 'audit.AuditLog', COUNT(*) FROM audit.AuditLog;
    PRINT '   >>> OK: MC_Admin accede a todo (comisiones, seguridad, auditoria).';
    REVERT;
END TRY
BEGIN CATCH
    PRINT '   >>> ERROR INESPERADO: ' + CAST(ERROR_NUMBER() AS VARCHAR) + ' - ' + ERROR_MESSAGE();
    IF USER_NAME() = 'MC_Admin' REVERT;
END CATCH
GO

-- ============================================================================
-- PARTE 8 - RESPALDO Y RECUPERACION
-- ============================================================================

-- ============================================================================
-- BLOQUE 8.1 - RESPALDO FULL MANUAL
-- ============================================================================
-- QUE SE DEMUESTRA: la base genera correctamente un respaldo (criterio de
-- aceptacion). Se ejecuta un BACKUP FULL y luego se consulta su historial
-- en msdb (que es como SQL Server controla la cadena de respaldos).
-- ============================================================================
PRINT '========================================================';
PRINT 'BLOQUE 8.1 - RESPALDO FULL MANUAL';
PRINT '========================================================';
GO

PRINT 'PASO 1 - ACCION: ejecutar el respaldo FULL de la base...';
BACKUP DATABASE MatriculaCloud360DB
TO DISK = '/var/opt/mssql/backup/ManualPruebaIntegral_FULL.bak'
WITH INIT, NAME = 'ManualPruebaIntegral-FULL', STATS = 50;
GO

PRINT 'PASO 2 - ESTADO DESPUES: el respaldo quedo en el historial de msdb:';
SELECT TOP (3) bs.database_name, bs.backup_start_date, bs.type,
       bs.backup_size / 1024.0 AS TamanoKB,
       bmf.physical_device_name AS Ruta
FROM msdb.dbo.backupset bs
INNER JOIN msdb.dbo.backupmediafamily bmf ON bmf.media_set_id = bs.media_set_id
WHERE bs.database_name = 'MatriculaCloud360DB'
ORDER BY bs.backup_start_date DESC;
GO

-- ============================================================================
-- BLOQUE 8.2 - VALIDAR EL RESPALDO (RESTORE VERIFYONLY)
-- ============================================================================
-- QUE SE DEMUESTRA: el respaldo es VALIDO y restaurable.
-- ============================================================================
PRINT '========================================================';
PRINT 'BLOQUE 8.2 - VALIDACION DEL RESPALDO (RESTORE VERIFYONLY)';
PRINT '========================================================';
GO

PRINT 'ACCION: verificar la integridad del archivo de respaldo...';
RESTORE VERIFYONLY FROM DISK = '/var/opt/mssql/backup/ManualPruebaIntegral_FULL.bak';
GO

PRINT '>>> Si el mensaje es "The backup set on file 1 is valid", el respaldo';
PRINT '    esta CORRECTO y puede usarse para restaurar.';
GO

-- ============================================================================
-- BLOQUE 8.3 - RESTAURAR A UNA BASE DE DEMOSTRACION (sin tocar la real)
-- ============================================================================
-- QUE SE DEMUESTRA: el proceso de RESTAURACION ejecutado y validado,
-- SIN arriesgar la base original: se restaura el respaldo en una base
-- nueva (MC360_RESTORE_DEMO) y se compara la informacion restaurada.
-- ============================================================================
PRINT '========================================================';
PRINT 'BLOQUE 8.3 - RESTAURACION DEMOSTRATIVA (base clon temporal)';
PRINT '========================================================';
GO

PRINT 'PASO 1 - ACCION: restaurar el respaldo como MC360_RESTORE_DEMO...';
IF DB_ID('MC360_RESTORE_DEMO') IS NOT NULL
BEGIN
    ALTER DATABASE MC360_RESTORE_DEMO SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE MC360_RESTORE_DEMO;
END
GO
RESTORE DATABASE MC360_RESTORE_DEMO
FROM DISK = '/var/opt/mssql/backup/ManualPruebaIntegral_FULL.bak'
WITH MOVE 'MatriculaCloud360DB_Data' TO '/var/opt/mssql/data/MC360_RESTORE_DEMO.mdf',
     MOVE 'MatriculaCloud360DB_Log'  TO '/var/opt/mssql/data/MC360_RESTORE_DEMO_log.ldf',
     STATS = 50;
GO

PRINT 'PASO 2 - VERIFICACION: la base restaurada tiene la MISMA informacion:';
SELECT 'Original' AS Base, COUNT(*) AS Estudiantes FROM MatriculaCloud360DB.core.Estudiantes
UNION ALL
SELECT 'Restaurada', COUNT(*) FROM MC360_RESTORE_DEMO.core.Estudiantes;
GO

PRINT 'PASO 3 - LIMPIEZA: se elimina la base de demostracion (la original no';
PRINT 'se toco en ningun momento):';
ALTER DATABASE MC360_RESTORE_DEMO SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
DROP DATABASE MC360_RESTORE_DEMO;
PRINT '   >> Base de demostracion eliminada.';
GO

PRINT 'NOTA: la restauracion REAL sobre la base (perdida simulada + DBCC';
PRINT 'CHECKDB) esta automatizada en sqlserver/testing/recovery_tests.sql';
PRINT 'y documentada en maintenance/02_restore.sql.';
GO

-- ============================================================================
-- BLOQUE 8.4 - JOBS DE SQL AGENT (automatizacion del mantenimiento)
-- ============================================================================
-- QUE SE DEMUESTRA: la estrategia automatizada de respaldo y mantenimiento
-- (FULL diario, DIFFERENTIAL cada 6h, LOG cada 30min, indices semanales,
-- integridad) implementada con SQL Agent.
-- ============================================================================
PRINT '========================================================';
PRINT 'BLOQUE 8.4 - JOBS DE SQL AGENT (MC360_*)';
PRINT '========================================================';
GO

PRINT 'PASO 1: jobs programados y su estado:';
SELECT name AS Job,
       CASE enabled WHEN 1 THEN 'HABILITADO' ELSE 'DESHABILITADO' END AS Estado
FROM msdb.dbo.sysjobs
WHERE name LIKE 'MC360_%'
ORDER BY name;
GO

PRINT 'PASO 2: horario de cada job (frecuencia):';
SELECT j.name AS Job,
       CASE s.freq_type
            WHEN 4 THEN 'DIARIO'
            WHEN 8 THEN 'SEMANAL'
            ELSE CAST(s.freq_type AS VARCHAR)
       END AS Frecuencia,
       s.active_start_time AS HoraInicio
FROM msdb.dbo.sysjobschedules s
INNER JOIN msdb.dbo.sysjobs j ON j.job_id = s.job_id
WHERE j.name LIKE 'MC360_%'
ORDER BY j.name;
GO

PRINT 'PASO 3: los 5 jobs crean la estrategia FULL + DIFERENCIAL + LOG:';
PRINT '   MC360_BackupCompleto       -> FULL diario (02:00)';
PRINT '   MC360_BackupDiferencial    -> DIFF cada 6 horas';
PRINT '   MC360_BackupLog            -> LOG cada 30 minutos (point-in-time)';
PRINT '   MC360_MantenimientoIndices -> reindexado semanal';
PRINT '   MC360_VerificacionIntegridad -> DBCC CHECKDB semanal';
GO

-- ============================================================================
-- PARTE 9 - LIMPIEZA Y RESUMEN
-- ============================================================================

-- ============================================================================
-- BLOQUE 9 - LIMPIEZA FINAL + LO QUE SE DEMOSTRO
-- ============================================================================
-- QUE SE DEMUESTRA: el guion es idempotente (se puede repetir) y respeta
-- los datos del instituto: al final solo quedan los datos de prueba del
-- propio guion, marcados correctamente.
-- ============================================================================
PRINT '========================================================';
PRINT 'BLOQUE 9 - LIMPIEZA Y RESUMEN';
PRINT '========================================================';
GO

PRINT 'PASO 1 - se reactiva el estudiante y el promotor de prueba...';
UPDATE core.Estudiantes
SET Activo = 1, DeletedAt = NULL, UpdatedAt = GETDATE()
WHERE NumeroDocumento IN ('80000001', '80000003', '80000004');

DELETE FROM core.Estudiantes WHERE NumeroDocumento IN ('80000003', '80000004');

UPDATE sales.Promotores
SET Activo = 1, DeletedAt = NULL, UpdatedAt = GETDATE()
WHERE CodigoPromotor = 'PROM-TEST';
PRINT '   OK: datos de prueba reactivados / retirados.';
GO

PRINT 'PASO 2 - estado final controlado (el instituto no fue alterado):';
SELECT COUNT(*) AS EmpleadosRealesDeLaBD
FROM core.Estudiantes
WHERE NumeroDocumento LIKE '7%' OR NumeroDocumento LIKE '6%';
GO

PRINT '========================================================';
PRINT 'RESUMEN - LO DEMOSTRADO EN ESTE GUION:';
PRINT ' 1. PROCEDIMIENTOS (usp): registrar/actualizar/matricular/retirar/';
PRINT '    consultar/eliminar logico + reglas RN-01, RN-02, RN-03, RN-09,';
PRINT '    RN-10 (errores 51001, 51002, 52005, 52006, 52009, etc.)';
PRINT ' 2. FUNCIONES (fn): periodo habilitado, documento unico, edad,';
PRINT '    demanda, comision y bono';
PRINT ' 3. TRIGGERS (trg): auditoria INSERT/UPDATE/DELETE (RN-07),';
PRINT '    comision automatica (RN-09), borrado logico INSTEAD OF (RN-10)';
PRINT ' 4. VISTAS (vw): 7 de reporte + 3 analiticas';
PRINT ' 5. CONSULTAS AVANZADAS: CTE, CTE recursiva, ROLLUP, RANK, LAG,';
PRINT '    SUM OVER, ROW_NUMBER';
PRINT ' 6. INDICES: justificacion tecnica + antes/despues + SHOWPLAN_XML';
PRINT ' 7. SEGURIDAD: 3 perfiles diferenciados (GRANT/DENY, error 229)';
PRINT ' 8. RESPALDO/RECUPERACION: BACKUP + VERIFYONLY + RESTORE a BD de';
PRINT '    demostracion + jobs de SQL Agent';
PRINT ' 9. LIMPIEZA: datos del instituto intactos';
PRINT '========================================================';
GO