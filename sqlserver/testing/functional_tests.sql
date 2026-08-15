-- =============================================
-- Matricula Cloud 360 Enterprise
-- testing/functional_tests.sql | Pruebas integrales Sprint 3
-- =============================================
-- Descripcion: Bateria de pruebas que demuestra el funcionamiento
-- conjunto de auditoria, borrado logico, consultas analiticas e
-- indices. Cada caso reporta [OK] o [ERR].
--
--   F01 Audit INSERT (trigger AFTER)
--   F02 Audit UPDATE (trigger AFTER)
--   F03 Borrado logico: DELETE fisico -> soft delete (INSTEAD OF)
--   F04 El registro "eliminado" persiste con DeletedAt
--   F05 Las vistas operativas excluyen los borrados logicos
--   F06 Consultas analiticas (CTE/ventanas) responden
--   F07 Indices del Sprint 3 existentes y habilitados
--   F08 Integracion total: registrar -> matricular -> comision ->
--       auditoria (transaccion reversible)
--
-- SEGURO: todas las escrituras corren en una transaccion que se
-- revierte al final; la base queda intacta.
-- =============================================

USE MatriculaCloud360DB;
GO

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
GO

PRINT '============================================';
PRINT 'testing/functional_tests.sql - Sprint 3';
PRINT '============================================';
GO

DECLARE @Resultados TABLE (
    Numero  INT,
    Caso    VARCHAR(150),
    Esperado VARCHAR(60),
    Obtenido VARCHAR(60),
    Estado  VARCHAR(10)
);
DECLARE @i INT = 0;
DECLARE @Exito BIT;
DECLARE @Obtenido VARCHAR(60);

DECLARE @AuditAntes INT, @AuditDespues INT;

BEGIN TRAN;   -- prueba reversible

BEGIN TRY

-- =============================================
-- F01. AUDITORIA: INSERT genera registro en audit.AuditLog
-- =============================================
SET @i = @i + 1;
SET @Exito = 0;
SET @Obtenido = '';

SELECT @AuditAntes = COUNT(*) FROM audit.AuditLog WHERE TableName = 'core.Estudiantes' AND Operation = 'INSERT';

INSERT INTO core.Estudiantes (TipoDocumento, NumeroDocumento, Nombres, Apellidos, Email, Celular, FechaNacimiento, Genero)
VALUES ('DNI', '99998888', 'Auditor', 'InsertTest', 'f01.audit@gmail.com', '999111999', '2004-01-01', 'M');

SELECT @AuditDespues = COUNT(*) FROM audit.AuditLog WHERE TableName = 'core.Estudiantes' AND Operation = 'INSERT';
IF @AuditDespues > @AuditAntes SET @Exito = 1;
SET @Obtenido = 'audit INSERT=' + CAST(@AuditDespues - @AuditAntes AS VARCHAR);
INSERT INTO @Resultados VALUES (@i, 'F01 Audit INSERT', 'audit > antes', @Obtenido, CASE WHEN @Exito = 1 THEN '[OK]' ELSE '[ERR]' END);

-- =============================================
-- F02. AUDITORIA: UPDATE genera registro en audit.AuditLog
-- =============================================
SET @i = @i + 1;
SET @Exito = 0;
SET @Obtenido = '';

SELECT @AuditAntes = COUNT(*) FROM audit.AuditLog WHERE TableName = 'core.Estudiantes' AND Operation = 'UPDATE';

UPDATE core.Estudiantes
SET Apellidos = 'UpdatedTest'
WHERE NumeroDocumento = '99998888';

SELECT @AuditDespues = COUNT(*) FROM audit.AuditLog WHERE TableName = 'core.Estudiantes' AND Operation = 'UPDATE';
IF @AuditDespues > @AuditAntes SET @Exito = 1;
SET @Obtenido = 'audit UPDATE=' + CAST(@AuditDespues - @AuditAntes AS VARCHAR);
INSERT INTO @Resultados VALUES (@i, 'F02 Audit UPDATE', 'audit > antes', @Obtenido, CASE WHEN @Exito = 1 THEN '[OK]' ELSE '[ERR]' END);

-- =============================================
-- F03/F04. BORRADO LOGICO: DELETE no elimina fisicamente
-- =============================================
SET @i = @i + 1;
SET @Exito = 0;
SET @Obtenido = '';

DELETE FROM core.Estudiantes WHERE NumeroDocumento = '99998888';

DECLARE @ExisteAlgo INT;
SELECT @ExisteAlgo = COUNT(*) FROM core.Estudiantes WHERE NumeroDocumento = '99998888' AND DeletedAt IS NOT NULL;
IF @ExisteAlgo = 1 SET @Exito = 1;
SET @Obtenido = 'filas con DeletedAt=' + CAST(@ExisteAlgo AS VARCHAR);
INSERT INTO @Resultados VALUES (@i, 'F03 Soft delete: DELETE = UPDATE DeletedAt', '1', @Obtenido, CASE WHEN @Exito = 1 THEN '[OK]' ELSE '[ERR]' END);

SET @i = @i + 1;
SET @Exito = 0;
SET @Obtenido = '';

DECLARE @TotalFisico INT;
SELECT @TotalFisico = COUNT(*) FROM core.Estudiantes WHERE NumeroDocumento = '99998888';
IF @TotalFisico = 1 SET @Exito = 1;
SET @Obtenido = 'registros fisicos=' + CAST(@TotalFisico AS VARCHAR);
INSERT INTO @Resultados VALUES (@i, 'F04 El registro persiste (no se elimino)', '1', @Obtenido, CASE WHEN @Exito = 1 THEN '[OK]' ELSE '[ERR]' END);

-- =============================================
-- F05. VISTAS OPERATIVAS: excluyen borrados logicos
-- =============================================
SET @i = @i + 1;
SET @Exito = 0;
SET @Obtenido = '';

DECLARE @Visible INT;
SELECT @Visible = COUNT(*) FROM core.vw_EstudiantesDetalle WHERE NumeroDocumento = '99998888';
IF @Visible = 0 SET @Exito = 1;
SET @Obtenido = 'visible en vista=' + CAST(@Visible AS VARCHAR);
INSERT INTO @Resultados VALUES (@i, 'F05 La vista excluye el borrado logico', '0', @Obtenido, CASE WHEN @Exito = 1 THEN '[OK]' ELSE '[ERR]' END);

-- =============================================
-- F06. CONSULTAS ANALITICAS: CTE + ventanas responden
-- =============================================
SET @i = @i + 1;
SET @Exito = 0;
SET @Obtenido = '';

DECLARE @Analitico INT;
WITH Ranking AS
(
    SELECT pr.PromotorId,
           RANK() OVER (ORDER BY SUM(co.MontoTotal) DESC) AS R
    FROM sales.Promotores pr
    INNER JOIN core.Matriculas m ON m.PromotorId = pr.PromotorId AND m.DeletedAt IS NULL
    INNER JOIN sales.Comisiones co ON co.MatriculaId = m.MatriculaId
    GROUP BY pr.PromotorId
)
SELECT @Analitico = COUNT(*) FROM Ranking;

IF @Analitico > 0 SET @Exito = 1;
SET @Obtenido = 'ranking filas=' + CAST(@Analitico AS VARCHAR);
INSERT INTO @Resultados VALUES (@i, 'F06 Consultas CTE/ventana responden', '> 0', @Obtenido, CASE WHEN @Exito = 1 THEN '[OK]' ELSE '[ERR]' END);

-- =============================================
-- F07. INDICES DEL SPRINT 3: existentes y habilitados
-- =============================================
SET @i = @i + 1;
SET @Exito = 0;
SET @Obtenido = '';

DECLARE @IndicesOK INT;
SELECT @IndicesOK = COUNT(*) FROM sys.indexes
WHERE name IN ('IX_Matriculas_PeriodoEstado', 'IX_Matriculas_PromotorPeriodo', 'IX_Comisiones_Campania')
  AND is_disabled = 0;

IF @IndicesOK = 3 SET @Exito = 1;
SET @Obtenido = 'indices habilitados=' + CAST(@IndicesOK AS VARCHAR);
INSERT INTO @Resultados VALUES (@i, 'F07 Indices Sprint 3 habilitados', '3', @Obtenido, CASE WHEN @Exito = 1 THEN '[OK]' ELSE '[ERR]' END);

END TRY
BEGIN CATCH
    PRINT '   [ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR) + '] ' + ERROR_MESSAGE();
END CATCH

ROLLBACK;   -- deshace todo (el registro F01/F02/F03 no permanece)

-- =============================================
-- F08. INTEGRACION TOTAL (via SP, transaccion reversible)
-- =============================================
SET @i = @i + 1;
SET @Exito = 0;
SET @Obtenido = '';

DECLARE @IdEst INT, @IdMat INT, @Msg NVARCHAR(500);

BEGIN TRAN;
BEGIN TRY
    EXEC core.usp_RegistrarEstudiante 'DNI', '88887777', 'Integral', 'Sprint3',
         'f08.integral@gmail.com', '988877777', '2003-05-05', 'F', NULL, 1,
         @IdEst OUTPUT, @Msg OUTPUT;

    EXEC core.usp_RegistrarMatricula @IdEst, 2, 5, 2, 2, 5, 'Prueba integral Sprint 3',
         @IdMat OUTPUT, @Msg OUTPUT;

    IF @IdEst IS NOT NULL AND @IdMat IS NOT NULL
    BEGIN
        DECLARE @ComisionVar INT;
        SELECT @ComisionVar = COUNT(*) FROM sales.Comisiones WHERE MatriculaId = @IdMat;
        DECLARE @AuditVar INT;
        SELECT @AuditVar = COUNT(*) FROM audit.AuditLog
        WHERE RecordId = @IdEst AND TableName = 'core.Estudiantes';

        IF @ComisionVar > 0 AND @AuditVar > 0 SET @Exito = 1;
        SET @Obtenido = 'comision=' + CAST(@ComisionVar AS VARCHAR) + ' auditoria=' + CAST(@AuditVar AS VARCHAR);
    END
    ELSE
        SET @Obtenido = 'SP fallaron: ' + ISNULL(@Msg, '');
END TRY
BEGIN CATCH
    SET @Obtenido = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR) + ' ' + ERROR_MESSAGE();
END CATCH

IF @@TRANCOUNT > 0 ROLLBACK;

INSERT INTO @Resultados VALUES (@i, 'F08 Integracion SP+trigger+audit', 'comision>0 audit>0', ISNULL(@Obtenido, ''), CASE WHEN @Exito = 1 THEN '[OK]' ELSE '[ERR]' END);

-- =============================================
-- RESULTADOS
-- =============================================
PRINT '';
PRINT '============================================';
PRINT 'RESULTADOS DE PRUEBAS FUNCIONALES SPRINT 3:';
PRINT '============================================';
SELECT * FROM @Resultados ORDER BY Numero;

DECLARE @Errores INT;
SELECT @Errores = COUNT(*) FROM @Resultados WHERE Estado = '[ERR]';

IF @Errores = 0
    PRINT '>>> TODAS LAS PRUEBAS FUNCIONALES SUPERADAS <<<';
ELSE
    PRINT '>>> HAY ' + CAST(@Errores AS VARCHAR) + ' PRUEBAS FALLIDAS <<<';
PRINT '============================================';
GO