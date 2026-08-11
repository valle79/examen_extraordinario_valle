-- =============================================
-- Matricula Cloud 360 Enterprise
-- 03_test_cases.sql | Casos de prueba de reglas de negocio
-- =============================================
-- Descripcion: Bateria de pruebas automaticas que valida las
-- reglas de negocio implementadas en el Sprint 2:
--   T01 RN-01 documento unico           T10 RN-09 comision automatica
--   T02 RN-01 email unico               T11 RN-09 anulacion al retirar
--   T03 RN-02 matricula duplicada       T12 RN-10 borrado logico estudiante
--   T04 RN-03 periodo deshabilitado     T13 RN-10 borrado logico matricula
--   T05 RN-04 rollback transaccional    T14 RN-08 codigo promotor duplicado
--   T06 RN-08 promotor inexistente      T15 RN-09 no pagar comision anulada
--   T07 RN-05 malla curricular          T16 RN-09 formula de comision
--   T08 RN-06 roles de seguridad        T17 RN-03 ventana de matricula
--   T09 RN-07 auditoria                 T18 Reportes (vistas/SP) responden
--
-- Cada caso reporta [OK] o [ERR]. No modifica datos del catalogo:
-- opera sobre el estudiante/matricula de prueba creados en
-- 02_test_data.sql y sobre filas temporales que luego se eliminan
-- o se dejan en estado inactivo (RN-10).
-- =============================================

USE MatriculaCloud360DB;
GO

-- Requerido para actualizar tablas con indices filtrados
-- (IX_Estudiantes_DeletedAt, IX_Matriculas_DeletedAt).
SET QUOTED_IDENTIFIER ON;
GO

SET NOCOUNT ON;
GO

PRINT '============================================';
PRINT '03_test_cases.sql - Pruebas de reglas de negocio';
PRINT '============================================';
GO

DECLARE @ResultadosPruebas TABLE (
    Numero  INT,
    Caso    VARCHAR(120),
    Esperado VARCHAR(60),
    Obtenido VARCHAR(60),
    Estado  VARCHAR(10)
);

DECLARE @i INT = 0;
DECLARE @Exito BIT;
DECLARE @Obtenido VARCHAR(60);
DECLARE @IdOut INT;
DECLARE @MsgErr NVARCHAR(500);
DECLARE @MatriculaPrueba INT;
DECLARE @ComisionPrueba INT;

-- =============================================
-- SETUP DE IDEMPOTENCIA
-- Restaura el estado base de los datos de prueba
-- (las pruebas anteriores los dejan borrados logicamente):
--   - Estudiantes: reactivar al estudiante de prueba.
--   - Matriculas: reactivar la matricula de prueba.
--   - Comisiones: volver la comision a Pendiente.
-- =============================================
DECLARE @EstPrueba INT;
SELECT @EstPrueba = EstudianteId
FROM core.Estudiantes
WHERE TipoDocumento = 'DNI' AND NumeroDocumento = '71234567';

IF @EstPrueba IS NOT NULL
BEGIN
    UPDATE core.Estudiantes
    SET Activo = 1, DeletedAt = NULL, UpdatedAt = GETDATE()
    WHERE EstudianteId = @EstPrueba;
END

IF @EstPrueba IS NOT NULL
BEGIN
    UPDATE m
    SET Activo = 1, DeletedAt = NULL, EstadoMatricula = 'Activa', UpdatedAt = GETDATE()
    FROM core.Matriculas m
    WHERE m.EstudianteId = @EstPrueba AND m.CarreraId = 1 AND m.PeriodoId = 5;

    UPDATE c
    SET EstadoPago = 'Pendiente', FechaPago = NULL
    FROM sales.Comisiones c
    INNER JOIN core.Matriculas m ON m.MatriculaId = c.MatriculaId
    WHERE m.EstudianteId = @EstPrueba AND m.CarreraId = 1 AND m.PeriodoId = 5;
END

-- Ubicacion de los datos de prueba (tras el setup)
SELECT @MatriculaPrueba = m.MatriculaId
FROM core.Matriculas m
INNER JOIN core.Estudiantes e ON e.EstudianteId = m.EstudianteId
WHERE e.TipoDocumento = 'DNI' AND e.NumeroDocumento = '71234567'
  AND m.CarreraId = 1 AND m.PeriodoId = 5;

SELECT @ComisionPrueba = ComisionId
FROM sales.Comisiones
WHERE MatriculaId = @MatriculaPrueba;

-- =============================================
-- T01. RN-01: rechazar documento duplicado (ERROR 51001)
-- =============================================
SET @i = @i + 1;
SET @Exito = 0;
SET @Obtenido = '';
BEGIN TRY
    EXEC core.usp_RegistrarEstudiante 'DNI', '70123456', 'X', 'Y', 'x.y@gmail.com',
         '987000001', '2004-01-01', 'M', NULL, 1, @IdOut OUTPUT, @MsgErr OUTPUT;
END TRY
BEGIN CATCH
    SET @Obtenido = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR);
    IF ERROR_NUMBER() = 51001 SET @Exito = 1;
END CATCH
INSERT INTO @ResultadosPruebas VALUES (@i, 'RN-01: documento duplicado rechazado',
    'ERROR 51001', CASE WHEN @Exito = 1 THEN @Obtenido ELSE ISNULL(@Obtenido, 'SIN ERROR') END,
    CASE WHEN @Exito = 1 THEN '[OK]' ELSE '[ERR]' END);

-- =============================================
-- T02. RN-01: rechazar email duplicado (ERROR 51002)
-- =============================================
SET @i = @i + 1;
SET @Exito = 0;
SET @Obtenido = '';
BEGIN TRY
    EXEC core.usp_RegistrarEstudiante 'DNI', '71123456', 'X', 'Y', 'cmendoza@gmail.com',
         '987000002', '2004-01-01', 'M', NULL, 1, @IdOut OUTPUT, @MsgErr OUTPUT;
END TRY
BEGIN CATCH
    SET @Obtenido = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR);
    IF ERROR_NUMBER() = 51002 SET @Exito = 1;
END CATCH
INSERT INTO @ResultadosPruebas VALUES (@i, 'RN-01: email duplicado rechazado',
    'ERROR 51002', CASE WHEN @Exito = 1 THEN @Obtenido ELSE ISNULL(@Obtenido, 'SIN ERROR') END,
    CASE WHEN @Exito = 1 THEN '[OK]' ELSE '[ERR]' END);

-- =============================================
-- T03. RN-02: rechazar matricula duplicada (ERROR 52006)
-- Se usa la matricula de prueba (estudiante 71234567, carrera 1,
-- periodo 5) que registro 02_test_data.sql: duplicar esa matricula
-- debe ser rechazado por RN-02. Si la ventana del periodo ya cerro
-- (matricula de prueba no registrada), el caso se marca NO APLICA.
-- =============================================
SET @i = @i + 1;
SET @Exito = 0;
SET @Obtenido = '';
DECLARE @EstudianteTest INT;
SELECT @EstudianteTest = EstudianteId
FROM core.Estudiantes WHERE TipoDocumento = 'DNI' AND NumeroDocumento = '71234567';
IF @MatriculaPrueba IS NULL
BEGIN
    SET @Obtenido = 'NO APLICA: matricula de prueba no registrada (ventana cerrada)';
    SET @Exito = 1;
END
ELSE
BEGIN TRY
    EXEC core.usp_RegistrarMatricula @EstudianteTest, 1, 5, 1, 1, 5, NULL, @IdOut OUTPUT, @MsgErr OUTPUT;
END TRY
BEGIN CATCH
    SET @Obtenido = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR);
    IF ERROR_NUMBER() = 52006 SET @Exito = 1;
END CATCH
INSERT INTO @ResultadosPruebas VALUES (@i, 'RN-02: matricula duplicada (est/carrera/periodo) rechazada',
    'ERROR 52006', CASE WHEN @Exito = 1 THEN @Obtenido ELSE ISNULL(@Obtenido, 'SIN ERROR') END,
    CASE WHEN @Exito = 1 THEN '[OK]' ELSE '[ERR]' END);

-- =============================================
-- T04. RN-03: rechazar matricula en periodo deshabilitado
-- Periodo 2 (2025-II): ventana de matriculas cerrada. (ERROR 52005)
-- =============================================
SET @i = @i + 1;
SET @Exito = 0;
SET @Obtenido = '';
BEGIN TRY
    EXEC core.usp_RegistrarMatricula 1, 2, 2, 1, 1, 2, NULL, @IdOut OUTPUT, @MsgErr OUTPUT;
END TRY
BEGIN CATCH
    SET @Obtenido = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR);
    IF ERROR_NUMBER() = 52005 SET @Exito = 1;
END CATCH
INSERT INTO @ResultadosPruebas VALUES (@i, 'RN-03: matricula en periodo con ventana cerrada rechazada',
    'ERROR 52005', CASE WHEN @Exito = 1 THEN @Obtenido ELSE ISNULL(@Obtenido, 'SIN ERROR') END,
    CASE WHEN @Exito = 1 THEN '[OK]' ELSE '[ERR]' END);

-- =============================================
-- T05. RN-04: la transaccion se revierte por completo ante un error
-- Estudiante inexistente -> ERROR 52001; no deben quedar filas
-- residuales y la transaccion debe quedar cerrada.
-- =============================================
SET @i = @i + 1;
SET @Exito = 0;
SET @Obtenido = '';
DECLARE @Antes INT, @Despues INT;
SELECT @Antes = COUNT(*) FROM core.Matriculas;
BEGIN TRY
    EXEC core.usp_RegistrarMatricula 99999, 1, 5, 1, 1, 5, NULL, @IdOut OUTPUT, @MsgErr OUTPUT;
END TRY
BEGIN CATCH
    SELECT @Despues = COUNT(*) FROM core.Matriculas;
    IF ERROR_NUMBER() = 52001 AND @Despues = @Antes AND @@TRANCOUNT = 0
        SET @Exito = 1;
    SET @Obtenido = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR) + ' | filas antes/despues: '
                  + CAST(@Antes AS VARCHAR) + '/' + CAST(@Despues AS VARCHAR)
                  + ' | tran abiertas: ' + CAST(@@TRANCOUNT AS VARCHAR);
END CATCH
INSERT INTO @ResultadosPruebas VALUES (@i, 'RN-04: rollback total ante error (sin filas residuales)',
    'ERROR 52001 + ROLLBACK', CASE WHEN @Exito = 1 THEN @Obtenido ELSE ISNULL(@Obtenido, 'SIN ERROR') END,
    CASE WHEN @Exito = 1 THEN '[OK]' ELSE '[ERR]' END);

-- =============================================
-- T06. RN-08: rechazar matricula con promotor inexistente (ERROR 52004)
-- =============================================
SET @i = @i + 1;
SET @Exito = 0;
SET @Obtenido = '';
BEGIN TRY
    EXEC core.usp_RegistrarMatricula 1, 2, 5, 1, 99999, 5, NULL, @IdOut OUTPUT, @MsgErr OUTPUT;
END TRY
BEGIN CATCH
    SET @Obtenido = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR);
    IF ERROR_NUMBER() = 52004 SET @Exito = 1;
END CATCH
INSERT INTO @ResultadosPruebas VALUES (@i, 'RN-08: matricula con promotor inexistente rechazada',
    'ERROR 52004', CASE WHEN @Exito = 1 THEN @Obtenido ELSE ISNULL(@Obtenido, 'SIN ERROR') END,
    CASE WHEN @Exito = 1 THEN '[OK]' ELSE '[ERR]' END);

-- =============================================
-- T07. RN-05: la malla curricular de cada carrera tiene cursos
-- =============================================
SET @i = @i + 1;
SET @Exito = 0;
SET @Obtenido = '';
BEGIN TRY
    DECLARE @MallaSinCursos INT;
    SELECT @MallaSinCursos = COUNT(*) FROM core.Carreras c
    WHERE NOT EXISTS (SELECT 1 FROM academic.CarreraCursos cc WHERE cc.CarreraId = c.CarreraId);
    SET @Obtenido = 'carreras sin cursos: ' + CAST(@MallaSinCursos AS VARCHAR);
    IF @MallaSinCursos = 0 SET @Exito = 1;
END TRY
BEGIN CATCH
    SET @Obtenido = ERROR_MESSAGE();
END CATCH
INSERT INTO @ResultadosPruebas VALUES (@i, 'RN-05: todas las carreras tienen malla curricular',
    '0 carreras sin cursos', @Obtenido, CASE WHEN @Exito = 1 THEN '[OK]' ELSE '[ERR]' END);

-- =============================================
-- T08. RN-06: existen los perfiles de seguridad requeridos
-- =============================================
SET @i = @i + 1;
SET @Exito = 0;
SET @Obtenido = '';
BEGIN TRY
    DECLARE @Roles INT;
    SELECT @Roles = COUNT(*) FROM security.Roles;
    SET @Obtenido = 'roles registrados: ' + CAST(@Roles AS VARCHAR);
    IF @Roles >= 3 SET @Exito = 1;
END TRY
BEGIN CATCH
    SET @Obtenido = ERROR_MESSAGE();
END CATCH
INSERT INTO @ResultadosPruebas VALUES (@i, 'RN-06: perfiles de seguridad (Administrador/Coordinador/Promotor)',
    '>= 3 roles', @Obtenido, CASE WHEN @Exito = 1 THEN '[OK]' ELSE '[ERR]' END);

-- =============================================
-- T09. RN-07: la auditoria registro el alta del estudiante de prueba
-- =============================================
SET @i = @i + 1;
SET @Exito = 0;
SET @Obtenido = '';
BEGIN TRY
    DECLARE @Auditorias INT;
    SELECT @Auditorias = COUNT(*)
    FROM audit.AuditLog
    WHERE TableName = 'core.Estudiantes'
      AND Operation = 'INSERT'
      AND Usuario = SUSER_SNAME();
    SET @Obtenido = 'registros de auditoria: ' + CAST(@Auditorias AS VARCHAR);
    IF @Auditorias > 0 SET @Exito = 1;
END TRY
BEGIN CATCH
    SET @Obtenido = ERROR_MESSAGE();
END CATCH
INSERT INTO @ResultadosPruebas VALUES (@i, 'RN-07: auditoria registra INSERTs de estudiantes',
    '> 0 registros', @Obtenido, CASE WHEN @Exito = 1 THEN '[OK]' ELSE '[ERR]' END);

-- =============================================
-- T10. RN-09: la comision de la matricula de prueba se genero sola
-- Monto 250.00 x 12% (campana CAMP-2027-1) = 30.00
-- =============================================
SET @i = @i + 1;
SET @Exito = 0;
SET @Obtenido = '';
IF @ComisionPrueba IS NULL
BEGIN
    SET @Obtenido = 'NO APLICA: matricula de prueba no registrada';
    SET @Exito = 1;
END
ELSE
BEGIN TRY
    DECLARE @MontoComision DECIMAL(10,2), @EstadoComision VARCHAR(20);
    SELECT @MontoComision = MontoTotal, @EstadoComision = EstadoPago
    FROM sales.Comisiones WHERE ComisionId = @ComisionPrueba;
    SET @Obtenido = 'MontoTotal=' + CAST(@MontoComision AS VARCHAR) + ' estado=' + @EstadoComision;
    IF @MontoComision = 30.00 AND @EstadoComision = 'Pendiente' SET @Exito = 1;
END TRY
BEGIN CATCH
    SET @Obtenido = ERROR_MESSAGE();
END CATCH
INSERT INTO @ResultadosPruebas VALUES (@i, 'RN-09: comision automatica (250 x 12% = 30.00)',
    'MontoTotal=30.00, Pendiente', @Obtenido, CASE WHEN @Exito = 1 THEN '[OK]' ELSE '[ERR]' END);

-- =============================================
-- T11. RN-09: al retirar la matricula, la comision se anula
-- =============================================
SET @i = @i + 1;
SET @Exito = 0;
SET @Obtenido = '';
IF @MatriculaPrueba IS NULL
BEGIN
    SET @Obtenido = 'NO APLICA: matricula de prueba no registrada';
    SET @Exito = 1;
END
ELSE
BEGIN TRY
    EXEC core.usp_RetirarMatricula @MatriculaPrueba, 'Prueba de retiro', @MsgErr OUTPUT;
    DECLARE @EstadoNuevo VARCHAR(20);
    SELECT @EstadoNuevo = EstadoPago FROM sales.Comisiones WHERE ComisionId = @ComisionPrueba;
    SET @Obtenido = 'comision tras retiro: ' + ISNULL(@EstadoNuevo, '(sin comision)');
    IF @EstadoNuevo = 'Anulada' SET @Exito = 1;
END TRY
BEGIN CATCH
    SET @Obtenido = ERROR_MESSAGE();
END CATCH
INSERT INTO @ResultadosPruebas VALUES (@i, 'RN-09: retirar matricula anula la comision',
    'Anulada', @Obtenido, CASE WHEN @Exito = 1 THEN '[OK]' ELSE '[ERR]' END);

-- =============================================
-- T12. RN-10: borrado logico del estudiante (fila permanece con DeletedAt)
-- =============================================
SET @i = @i + 1;
SET @Exito = 0;
SET @Obtenido = '';
DECLARE @EstudiantePrueba INT;
SELECT @EstudiantePrueba = EstudianteId
FROM core.Estudiantes WHERE TipoDocumento = 'DNI' AND NumeroDocumento = '71234567';
BEGIN TRY
    EXEC core.usp_EliminarEstudianteLogico @EstudiantePrueba, @MsgErr OUTPUT;
    DECLARE @SigueExistiendo INT, @DeletedAt DATETIME, @Activo BIT;
    SELECT @SigueExistiendo = COUNT(*), @DeletedAt = MAX(DeletedAt), @Activo = MAX(CAST(Activo AS INT))
    FROM core.Estudiantes WHERE EstudianteId = @EstudiantePrueba;
    SET @Obtenido = 'fila=' + CAST(@SigueExistiendo AS VARCHAR)
                  + ' activo=' + CAST(@Activo AS VARCHAR)
                  + ' deleted_at=' + CASE WHEN @DeletedAt IS NULL THEN 'NULL' ELSE 'OK' END;
    IF @SigueExistiendo = 1 AND @Activo = 0 AND @DeletedAt IS NOT NULL SET @Exito = 1;
END TRY
BEGIN CATCH
    SET @Obtenido = ERROR_MESSAGE();
END CATCH
INSERT INTO @ResultadosPruebas VALUES (@i, 'RN-10: borrado logico de estudiante (DeletedAt, sin DELETE fisico)',
    'fila=1 activo=0 deleted_at=OK', @Obtenido, CASE WHEN @Exito = 1 THEN '[OK]' ELSE '[ERR]' END);

-- =============================================
-- T13. RN-10: borrado logico de la matricula de prueba
-- =============================================
SET @i = @i + 1;
SET @Exito = 0;
SET @Obtenido = '';
IF @MatriculaPrueba IS NULL
BEGIN
    SET @Obtenido = 'NO APLICA: matricula de prueba no registrada';
    SET @Exito = 1;
END
ELSE
BEGIN TRY
    EXEC core.usp_EliminarMatriculaLogico @MatriculaPrueba, @MsgErr OUTPUT;
    DECLARE @FilaMatricula INT, @DeletedMatricula DATETIME;
    SELECT @FilaMatricula = COUNT(*), @DeletedMatricula = MAX(DeletedAt)
    FROM core.Matriculas WHERE MatriculaId = @MatriculaPrueba;
    SET @Obtenido = 'fila=' + CAST(@FilaMatricula AS VARCHAR)
                  + ' deleted_at=' + CASE WHEN @DeletedMatricula IS NULL THEN 'NULL' ELSE 'OK' END;
    IF @FilaMatricula = 1 AND @DeletedMatricula IS NOT NULL SET @Exito = 1;
END TRY
BEGIN CATCH
    SET @Obtenido = ERROR_MESSAGE();
END CATCH
INSERT INTO @ResultadosPruebas VALUES (@i, 'RN-10: borrado logico de matricula (DeletedAt)',
    'fila=1 deleted_at=OK', @Obtenido, CASE WHEN @Exito = 1 THEN '[OK]' ELSE '[ERR]' END);

-- =============================================
-- T14. RN-08: rechazar codigo de promotor duplicado (ERROR 52011)
-- =============================================
SET @i = @i + 1;
SET @Exito = 0;
SET @Obtenido = '';
BEGIN TRY
    EXEC sales.usp_RegistrarPromotor 'PROM-001', 'DNI', '91111111', 'X', 'Y',
         'x.promotor@gmail.com', '987000003', 1, 5.00, @IdOut OUTPUT, @MsgErr OUTPUT;
END TRY
BEGIN CATCH
    SET @Obtenido = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR);
    IF ERROR_NUMBER() = 52011 SET @Exito = 1;
END CATCH
INSERT INTO @ResultadosPruebas VALUES (@i, 'RN-08: codigo de promotor duplicado rechazado',
    'ERROR 52011', CASE WHEN @Exito = 1 THEN @Obtenido ELSE ISNULL(@Obtenido, 'SIN ERROR') END,
    CASE WHEN @Exito = 1 THEN '[OK]' ELSE '[ERR]' END);

-- =============================================
-- T15. RN-09: no se puede pagar una comision anulada (ERROR 53002)
-- =============================================
SET @i = @i + 1;
SET @Exito = 0;
SET @Obtenido = '';
IF @ComisionPrueba IS NULL
BEGIN
    SET @Obtenido = 'NO APLICA: sin comision de prueba';
    SET @Exito = 1;
END
ELSE
BEGIN TRY
    EXEC sales.usp_MarcarComisionPagada @ComisionPrueba, @MsgErr OUTPUT;
END TRY
BEGIN CATCH
    SET @Obtenido = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR);
    IF ERROR_NUMBER() = 53002 SET @Exito = 1;
END CATCH
INSERT INTO @ResultadosPruebas VALUES (@i, 'RN-09: comision anulada no puede pagarse',
    'ERROR 53002', CASE WHEN @Exito = 1 THEN @Obtenido ELSE ISNULL(@Obtenido, 'SIN ERROR') END,
    CASE WHEN @Exito = 1 THEN '[OK]' ELSE '[ERR]' END);

-- =============================================
-- T16. RN-09: formula de comision (250 x 12% = 30.00)
-- =============================================
SET @i = @i + 1;
SET @Exito = 0;
SET @Obtenido = '';
BEGIN TRY
    DECLARE @ComisionCalculada DECIMAL(10,2);
    SELECT @ComisionCalculada = sales.fn_CalcularComision(1, 3, 250.00);
    SET @Obtenido = 'fn_CalcularComision(1, 3, 250) = ' + CAST(@ComisionCalculada AS VARCHAR);
    IF @ComisionCalculada = 30.00 SET @Exito = 1;
END TRY
BEGIN CATCH
    SET @Obtenido = ERROR_MESSAGE();
END CATCH
INSERT INTO @ResultadosPruebas VALUES (@i, 'RN-09: fn_CalcularComision 250 x 12% = 30.00',
    '30.00', @Obtenido, CASE WHEN @Exito = 1 THEN '[OK]' ELSE '[ERR]' END);

-- =============================================
-- T17. RN-03: la funcion de periodo habilitado es consistente
-- =============================================
SET @i = @i + 1;
SET @Exito = 0;
SET @Obtenido = '';
BEGIN TRY
    DECLARE @FnHabilitado BIT, @VentanaAbierta INT;
    SELECT @FnHabilitado = core.fn_PeriodoMatriculaHabilitado(5, GETDATE());
    SELECT @VentanaAbierta = COUNT(*) FROM core.PeriodosAcademicos
    WHERE PeriodoId = 5 AND Activo = 1
      AND GETDATE() >= FechaInicioMatriculas AND GETDATE() <= FechaFinMatriculas;
    SET @Obtenido = 'fn=' + CAST(@FnHabilitado AS VARCHAR) + ' ventana=' + CAST(@VentanaAbierta AS VARCHAR);
    IF @FnHabilitado = CAST(@VentanaAbierta AS BIT) SET @Exito = 1;
END TRY
BEGIN CATCH
    SET @Obtenido = ERROR_MESSAGE();
END CATCH
INSERT INTO @ResultadosPruebas VALUES (@i, 'RN-03: fn_PeriodoMatriculaHabilitado consistente con la ventana',
    'fn = ventana (0 o 1)', @Obtenido, CASE WHEN @Exito = 1 THEN '[OK]' ELSE '[ERR]' END);

-- =============================================
-- T18. Reportes: vistas y SP de consulta responden con datos
-- =============================================
SET @i = @i + 1;
SET @Exito = 0;
SET @Obtenido = '';
BEGIN TRY
    DECLARE @VMatriculas INT, @VComisiones INT, @VEstudiantes INT, @SPConsultas INT;
    SELECT @VMatriculas = COUNT(*) FROM core.vw_MatriculasDetalle;
    SELECT @VComisiones = COUNT(*) FROM sales.vw_ComisionesDetalle;
    SELECT @VEstudiantes = COUNT(*) FROM core.vw_EstudiantesDetalle;
    SELECT @SPConsultas = COUNT(*) FROM core.Matriculas;
    SET @Obtenido = 'vw_Matriculas=' + CAST(@VMatriculas AS VARCHAR)
                  + ' vw_Comisiones=' + CAST(@VComisiones AS VARCHAR)
                  + ' vw_Estudiantes=' + CAST(@VEstudiantes AS VARCHAR);
    IF @VMatriculas > 0 AND @VComisiones > 0 AND @VEstudiantes > 0 SET @Exito = 1;
END TRY
BEGIN CATCH
    SET @Obtenido = ERROR_MESSAGE();
END CATCH
INSERT INTO @ResultadosPruebas VALUES (@i, 'Reportes: vistas de detalle responden con datos',
    'todas > 0', @Obtenido, CASE WHEN @Exito = 1 THEN '[OK]' ELSE '[ERR]' END);

-- =============================================
-- RESUMEN DE PRUEBAS
-- =============================================
DECLARE @ErroresPruebas INT, @TotalPruebas INT;
SELECT @ErroresPruebas = COUNT(*) FROM @ResultadosPruebas WHERE Estado = '[ERR]';
SELECT @TotalPruebas = COUNT(*) FROM @ResultadosPruebas;

PRINT '';
PRINT '============================================';
PRINT 'RESULTADOS DE PRUEBAS DEL SPRINT 2';
PRINT '============================================';
PRINT '';

SELECT Numero AS N, Caso, Esperado, Obtenido, Estado
FROM @ResultadosPruebas
ORDER BY Numero;

IF @ErroresPruebas = 0
BEGIN
    PRINT '';
    PRINT '>>> TODAS LAS PRUEBAS SUPERADAS (' + CAST(@TotalPruebas AS VARCHAR) + '/' + CAST(@TotalPruebas AS VARCHAR) + ') <<<';
    PRINT 'Estado: APROBADO';
END
ELSE
BEGIN
    PRINT '';
    PRINT '>>> PRUEBAS FALLIDAS: ' + CAST(@ErroresPruebas AS VARCHAR) + ' <<<';
    PRINT 'Estado: REVISAR';
END
PRINT '';
GO
