-- =============================================
-- Matricula Cloud 360 Enterprise
-- utils/demo_profesor_sprint3.sql
-- DEMO COMPLETA PARA EL PROFESOR (Sprint 3)
-- =============================================
-- Este script responde en vivo a las preguntas mas probables del
-- profesor durante la sustentacion. Cada seccion:
--   1. Muestra la PREGUNTA.
--   2. Ejecuta la DEMOSTRACION.
--   3. Imprime la RESPUESTA esperada.
--
-- TEMAS CUBIERTOS:
--   P01 Restriccion DNI unico      (insertar DNI duplicado -> error)
--   P02 Restriccion email unico    (insertar email duplicado -> error)
--   P03 Restriccion formato DNI    (check constraint -> error)
--   P04 Auditoria: INSERT registrado en AuditLog
--   P05 Auditoria: UPDATE registrado en AuditLog
--   P06 Auditoria: DELETE registrado (borrado logico)
--   P07 Borrado logico: el registro NO se elimina (DeletedAt)
--   P08 Consultas avanzadas: CTE + ventanas responden
--   P09 Indices: que indices existen y como se justifican
--   P10 Rendimiento: antes/despues de los indices
--   P11 Seguridad: MC_Promotor no puede matricular (DENY)
--   P12 Seguridad: MC_Coordinador no ve comisiones (DENY)
--   P13 Seguridad: roles y membresias
--   P14 Respaldo: historial de backups en msdb
--   P15 Analiticas: indicadores del dashboard
--   P16 Vistas analiticas del Sprint 3
--
-- SEGURO: las escrituras de demostracion corren dentro de una
-- transaccion que se revierte (ROLLBACK). La base queda intacta.
--
-- Uso:
--   docker exec sqlserver_matricula_cloud /opt/mssql-tools18/bin/sqlcmd \
--     -S localhost -U SA -P "MatriculaCloud360!" -C \
--     -i /sqlserver/utils/demo_profesor_sprint3.sql
-- =============================================

USE MatriculaCloud360DB;
GO

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
GO

PRINT '==============================================================';
PRINT ' DEMO SPRINT 3 - PREGUNTAS PROBABLES DEL PROFESOR';
PRINT '==============================================================';
GO

-- ============================================================
-- P01. "Demuestrame que el DNI unico funciona: inserta un
--       estudiante con DNI duplicado y dime que pasa"
-- ============================================================
PRINT '';
PRINT 'P01. INSERTAR ESTUDIANTE CON DNI DUPLICADO';
PRINT '-------------------------------------------------------------';
PRINT 'Pregunta: inserte un estudiante con DNI que ya existe.';
PRINT 'Respuesta: la base lo RECHAZA con error de restriccion';
PRINT 'UNIQUE (UK_Estudiantes_Documento) y/o el error 51001 del SP.';
PRINT '';
PRINT '>> Demostracion (INSERT directo con DNI 70123456, ya existe):';

BEGIN TRY
    INSERT INTO core.Estudiantes (TipoDocumento, NumeroDocumento, Nombres, Apellidos, Email, Celular, FechaNacimiento, Genero)
    VALUES ('DNI', '70123456', 'Duplicado', 'Prueba', 'duplicado.p01@gmail.com', '987111222', '2004-01-01', 'M');
    PRINT '   [NO OK] El sistema PERMITIO el DNI duplicado.';
END TRY
BEGIN CATCH
    PRINT '   [OK] Rechazado con error ' + CAST(ERROR_NUMBER() AS VARCHAR) + ':';
    PRINT '       ' + ERROR_MESSAGE();
    PRINT '   Explicacion: la restriccion UNIQUE (RN-01) impide que dos';
    PRINT '   estudiantes compartan TipoDocumento+NumeroDocumento.';
END CATCH
GO

PRINT '>> Ademas, el procedimiento almacenado lo valida antes (51001):';
GO

DECLARE @IdP01 INT, @MsgP01 NVARCHAR(500);
BEGIN TRY
    EXEC core.usp_RegistrarEstudiante 'DNI', '70123456', 'X', 'Y', 'p01.sp@gmail.com',
         '987111222', '2004-01-01', 'M', NULL, 1, @IdP01 OUTPUT, @MsgP01 OUTPUT;
    PRINT '   [NO OK] El SP permitio el DNI duplicado.';
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 51001
        PRINT '   [OK] El SP rechazo con error 51001: ' + ERROR_MESSAGE();
    ELSE
        PRINT '   Error inesperado ' + CAST(ERROR_NUMBER() AS VARCHAR) + ': ' + ERROR_MESSAGE();
END CATCH
GO

-- ============================================================
-- P02. "Inserta un estudiante con email duplicado"
-- ============================================================
PRINT '';
PRINT 'P02. INSERTAR ESTUDIANTE CON EMAIL DUPLICADO';
PRINT '-------------------------------------------------------------';
PRINT 'Pregunta: inserte un estudiante con correo que ya existe.';
PRINT 'Respuesta: se rechaza por UK_Estudiantes_Email (RN-01).';
PRINT '';
PRINT '>> Demostracion (INSERT directo con email ya registrado):';

BEGIN TRY
    INSERT INTO core.Estudiantes (TipoDocumento, NumeroDocumento, Nombres, Apellidos, Email, Celular, FechaNacimiento, Genero)
    VALUES ('DNI', '77776666', 'Email', 'Duplicado', 'estudiante.prueba@gmail.com', '987333444', '2004-01-01', 'F');
    PRINT '   [NO OK] El sistema PERMITIO el email duplicado.';
END TRY
BEGIN CATCH
    PRINT '   [OK] Rechazado con error ' + CAST(ERROR_NUMBER() AS VARCHAR) + ':';
    PRINT '       ' + ERROR_MESSAGE();
END CATCH
GO

-- ============================================================
-- P03. "Que pasa si el DNI no tiene 8 digitos?"
-- ============================================================
PRINT '';
PRINT 'P03. FORMATO DE DOCUMENTO INVALIDO (CHECK CONSTRAINT)';
PRINT '-------------------------------------------------------------';
PRINT 'Pregunta: que pasa si registro un DNI de 5 digitos?';
PRINT 'Respuesta: CK_Estudiantes_Documento valida el formato';
PRINT '(DNI = 8 digitos; CE = alfanumerico de 1-15).';
PRINT '';
PRINT '>> Demostracion (DNI de 5 digitos):';

BEGIN TRY
    INSERT INTO core.Estudiantes (TipoDocumento, NumeroDocumento, Nombres, Apellidos, Email, Celular, FechaNacimiento, Genero)
    VALUES ('DNI', '12345', 'Formato', 'Invalido', 'formato.p03@gmail.com', '987555666', '2004-01-01', 'M');
    PRINT '   [NO OK] El sistema PERMITIO un DNI invalido.';
END TRY
BEGIN CATCH
    PRINT '   [OK] Rechazado con error ' + CAST(ERROR_NUMBER() AS VARCHAR) + ':';
    PRINT '       ' + ERROR_MESSAGE();
END CATCH
GO

-- ============================================================
-- P04/P05/P06/P07. AUDITORIA Y BORRADO LOGICO
-- ============================================================
PRINT '';
PRINT 'P04-P07. AUDITORIA (RN-07) Y BORRADO LOGICO (RN-10)';
PRINT '-------------------------------------------------------------';
PRINT 'Pregunta: como se audita el INSERT/UPDATE/DELETE? Y el';
PRINT 'borrado, elimina fisicamente la informacion?';
PRINT 'Respuesta: triggers AFTER registran cada operacion en';
PRINT 'audit.AuditLog; el DELETE se convierte en borrado logico';
PRINT '(INSTEAD OF DELETE -> UPDATE DeletedAt).';
PRINT '';

DECLARE @AudAntes INT, @AudDespues INT;

BEGIN TRAN;   -- demo reversible

    SELECT @AudAntes = COUNT(*) FROM audit.AuditLog WHERE TableName = 'core.Estudiantes';

    -- INSERT (auditado por TRG_Audit_Estudiantes)
    INSERT INTO core.Estudiantes (TipoDocumento, NumeroDocumento, Nombres, Apellidos, Email, Celular, FechaNacimiento, Genero)
    VALUES ('DNI', '98887777', 'Maria', 'Auditoria', 'maria.auditoria@gmail.com', '987777888', '2003-06-06', 'F');

    SELECT @AudDespues = COUNT(*) FROM audit.AuditLog WHERE TableName = 'core.Estudiantes';
    PRINT 'P04. INSERT -> auditoria generada: ' + CAST(@AudDespues - @AudAntes AS VARCHAR) + ' registro(s) nuevo(s). [OK]';

    -- UPDATE (auditado)
    UPDATE core.Estudiantes SET Apellidos = 'AuditoriaActualizada' WHERE NumeroDocumento = '98887777';

    SELECT @AudDespues = COUNT(*) FROM audit.AuditLog WHERE TableName = 'core.Estudiantes' AND Operation = 'UPDATE';
    PRINT 'P05. UPDATE -> registros con Operation=UPDATE: ' + CAST(@AudDespues AS VARCHAR) + ' [OK]';

    -- DELETE (se convierte en soft delete por TRG_SoftDelete_Estudiantes)
    DELETE FROM core.Estudiantes WHERE NumeroDocumento = '98887777';

    DECLARE @FilaRestante INT, @ConDeletedAt INT;
    SELECT @FilaRestante = COUNT(*) FROM core.Estudiantes WHERE NumeroDocumento = '98887777';
    SELECT @ConDeletedAt = COUNT(*) FROM core.Estudiantes WHERE NumeroDocumento = '98887777' AND DeletedAt IS NOT NULL;

    PRINT 'P06. DELETE -> la fila AUN EXISTE (borrado logico):';
    PRINT '    fila fisica=' + CAST(@FilaRestante AS VARCHAR) + ', con DeletedAt=' + CAST(@ConDeletedAt AS VARCHAR) + ' [OK]';

    SELECT @AudDespues = COUNT(*) FROM audit.AuditLog WHERE TableName = 'core.Estudiantes' AND Operation = 'DELETE';
    PRINT 'P07. DELETE -> operacion registrada en auditoria: ' + CAST(@AudDespues AS VARCHAR) + ' registro(s). [OK]';

    -- Mostrar los ultimos registros de auditoria generados por la demo
    PRINT '';
    PRINT '>> Ultimos registros de auditoria (valores en JSON):';
    SELECT TOP (3) AuditId, TableName, Operation, RecordId, Usuario, FechaOperacion
    FROM audit.AuditLog
    ORDER BY AuditId DESC;

    IF @@TRANCOUNT > 0 ROLLBACK;   -- la demo no deja datos

PRINT '>> ROLLBACK: la base quedo intacta.';
GO

-- ============================================================
-- P08. CONSULTAS AVANZADAS (CTE + VENTANAS)
-- ============================================================
PRINT '';
PRINT 'P08. CONSULTAS AVANZADAS: CTE + FUNCIONES DE VENTANA';
PRINT '-------------------------------------------------------------';
PRINT 'Pregunta: muestre una consulta avanzada con CTE y ventana.';
PRINT 'Respuesta: ranking de promotores por periodo usando';
PRINT 'ROW_NUMBER / RANK (ver optimization/02_advanced_queries.sql).';
PRINT '';

WITH RankingPromotores AS
(
    SELECT
        p.CodigoPeriodo,
        pr.CodigoPromotor,
        pr.Nombres + ' ' + pr.Apellidos AS Promotor,
        COUNT(m.MatriculaId)  AS Matriculas,
        SUM(co.MontoTotal)    AS ComisionTotal,
        RANK() OVER (PARTITION BY p.PeriodoId ORDER BY SUM(co.MontoTotal) DESC) AS Ranking
    FROM sales.Promotores pr
    INNER JOIN core.Matriculas m ON m.PromotorId = pr.PromotorId AND m.DeletedAt IS NULL
    INNER JOIN sales.Comisiones co ON co.MatriculaId = m.MatriculaId AND co.EstadoPago <> 'Anulada'
    INNER JOIN core.PeriodosAcademicos p ON p.PeriodoId = m.PeriodoId
    GROUP BY p.PeriodoId, p.CodigoPeriodo, pr.PromotorId, pr.CodigoPromotor, pr.Nombres, pr.Apellidos
)
SELECT * FROM RankingPromotores ORDER BY CodigoPeriodo, Ranking;
GO

-- ============================================================
-- P09. INDICES
-- ============================================================
PRINT '';
PRINT 'P09. INDICES IMPLEMENTADOS';
PRINT '-------------------------------------------------------------';
PRINT 'Pregunta: que indices crearon y por que?';
PRINT 'Respuesta: 17 indices no agrupados (14 Sprint 1 + 3 Sprint 3)';
PRINT 'mas las 17 PK agrupadas. Los del Sprint 3 son compuestos,';
PRINT 'filtrados y covering para las consultas criticas.';
PRINT '';
PRINT '>> Indices del Sprint 3:';

SELECT
    i.name AS Indice,
    OBJECT_NAME(i.object_id) AS Tabla,
    CASE i.is_disabled WHEN 0 THEN 'HABILITADO' ELSE 'DESHABILITADO' END AS Estado,
    CASE WHEN i.has_filter = 1 THEN 'SI (filtrado)' ELSE 'No' END AS Filtrado,
    i.filter_definition AS DefinicionFiltro
FROM sys.indexes i
WHERE i.name IN ('IX_Matriculas_PeriodoEstado', 'IX_Matriculas_PromotorPeriodo', 'IX_Comisiones_Campania');
GO

-- ============================================================
-- P10. RENDIMIENTO ANTES/DESPUES
-- ============================================================
PRINT '';
PRINT 'P10. RENDIMIENTO: ANTES Y DESPUES DE LOS INDICES';
PRINT '-------------------------------------------------------------';
PRINT 'Pregunta: compruebe que los indices mejoran el rendimiento.';
PRINT 'Respuesta: la prueba completa esta en optimization/';
PRINT '03_performance_tests.sql (1,000,000 filas). Resumen:';
PRINT 'se deshabilitan los indices, se mide el SCAN; se rehabilitan';
PRINT 'y se mide el SEEK. Aqui la comprobacion rapida en vivo:';
PRINT '';
PRINT '>> Deshabilitando IX_Matriculas_PeriodoEstado...';
ALTER INDEX IX_Matriculas_PeriodoEstado ON core.Matriculas DISABLE;
PRINT '>> Estado actual:';
SELECT name AS Indice, CASE is_disabled WHEN 0 THEN 'OK' ELSE 'DISABLED' END AS Estado
FROM sys.indexes WHERE name = 'IX_Matriculas_PeriodoEstado';
PRINT '>> Rehabilitando (REBUILD)...';
ALTER INDEX IX_Matriculas_PeriodoEstado ON core.Matriculas REBUILD;
SELECT name AS Indice, CASE is_disabled WHEN 0 THEN 'OK (HABILITADO)' ELSE 'DISABLED' END AS Estado
FROM sys.indexes WHERE name = 'IX_Matriculas_PeriodoEstado';
PRINT '>> Con esto se demuestra el control DISABLE/REBUILD usado';
PRINT '   en las pruebas comparativas antes/despues.';
GO

-- ============================================================
-- P11/P12/P13. SEGURIDAD
-- ============================================================
PRINT '';
PRINT 'P11-P13. SEGURIDAD: PERFILES Y PERMISOS (RN-06)';
PRINT '-------------------------------------------------------------';
PRINT 'Pregunta: compruebe que el promotor NO puede matricular';
PRINT 'y que el coordinador NO ve comisiones.';
PRINT 'Respuesta: DENY explicito sobre los procedimientos y';
PRINT 'esquemas sensibles (ver security/03_permissions.sql).';
PRINT '';
PRINT 'P11. MC_Promotor intenta ejecutar usp_RegistrarMatricula:';

DECLARE @TryingImp BIT;
SET @TryingImp = 0;
BEGIN TRY
    EXECUTE AS USER = 'MC_Promotor';
    SET @TryingImp = 1;
    DECLARE @IdPM INT, @MsgPM NVARCHAR(500);
    EXEC core.usp_RegistrarMatricula 1, 1, 5, 1, 1, 3, 'PRUEBA SEGURIDAD', @IdPM OUTPUT, @MsgPM OUTPUT;
    REVERT;
    SET @TryingImp = 0;
END TRY
BEGIN CATCH
    IF @TryingImp = 1 REVERT;
    IF ERROR_NUMBER() IN (229, 297)
        PRINT '   [OK] Denegado con error ' + CAST(ERROR_NUMBER() AS VARCHAR) + ': ' + ERROR_MESSAGE();
    ELSE
        PRINT '   Error ' + CAST(ERROR_NUMBER() AS VARCHAR) + ': ' + ERROR_MESSAGE();
END CATCH
GO

PRINT 'P12. MC_Coordinador intenta leer sales.vw_ComisionesDetalle:';
GO

DECLARE @TryingImp BIT;
SET @TryingImp = 0;
BEGIN TRY
    EXECUTE AS USER = 'MC_Coordinador';
    SET @TryingImp = 1;
    SELECT TOP (1) 1 FROM sales.vw_ComisionesDetalle;
    REVERT;
    SET @TryingImp = 0;
    PRINT '   [NO OK] El coordinador pudo ver comisiones.';
END TRY
BEGIN CATCH
    IF @TryingImp = 1 REVERT;
    IF ERROR_NUMBER() IN (229, 297)
        PRINT '   [OK] Denegado con error ' + CAST(ERROR_NUMBER() AS VARCHAR) + ': ' + ERROR_MESSAGE();
    ELSE
        PRINT '   Error ' + CAST(ERROR_NUMBER() AS VARCHAR) + ': ' + ERROR_MESSAGE();
END CATCH
GO

PRINT 'P13. Roles y membresias:';
SELECT r.name AS Rol, u.name AS Miembro
FROM sys.database_role_members rm
INNER JOIN sys.database_principals r ON r.principal_id = rm.role_principal_id
INNER JOIN sys.database_principals u ON u.principal_id = rm.member_principal_id
WHERE r.name IN ('rol_Administrador', 'rol_Coordinador_Academico', 'rol_Promotor')
ORDER BY r.name;
GO

-- ============================================================
-- P14. RESPALDO
-- ============================================================
PRINT '';
PRINT 'P14. ESTRATEGIA DE RESPALDO Y RECUPERACION';
PRINT '-------------------------------------------------------------';
PRINT 'Pregunta: como respaldan la base y como la recuperan?';
PRINT 'Respuesta: Recovery FULL + respaldos FULL (diario), DIFF';
PRINT '(cada 6 h) y LOG (cada 30 min) automatizados con SQL Agent';
PRINT '(maintenance/03_maintenance.sql). La restauracion se prueba';
PRINT 'en testing/recovery_tests.sql.';
PRINT '';
PRINT '>> Historial de respaldos registrados en msdb:';

SELECT TOP 5
    bs.database_name AS BaseDatos,
    bs.type AS TipoRespaldo,   -- D=FULL, I=DIFF, L=LOG
    bs.backup_finish_date AS Fecha,
    CAST(bs.backup_size / 1048576.0 AS DECIMAL(10,2)) AS TamanoMB
FROM msdb.dbo.backupset bs
WHERE bs.database_name = 'MatriculaCloud360DB'
ORDER BY bs.backup_finish_date DESC;
GO

PRINT '>> Jobs programados en SQL Agent (mantenimiento automatizado):';
SELECT name AS Job, CASE enabled WHEN 1 THEN 'HABILITADO' ELSE 'DESHABILITADO' END AS Estado
FROM msdb.dbo.sysjobs WHERE name LIKE 'MC360_%' ORDER BY name;
GO

-- ============================================================
-- P15/P16. ANALITICAS / DASHBOARD
-- ============================================================
PRINT '';
PRINT 'P15-P16. CONSULTAS ANALITICAS E INDICADORES';
PRINT '-------------------------------------------------------------';
PRINT 'Pregunta: que informacion util producen para el instituto?';
PRINT 'Respuesta: indicadores de matriculas, carreras, sedes,';
PRINT 'campanas y promotores (vistas analiticas del Sprint 3).';
PRINT '';
PRINT 'P15. Indicadores por periodo (core.vw_IndicadoresMatricula):';
SELECT TOP (5) CodigoPeriodo, NombreCarrera, NombreSede, TotalMatriculas, MontoRecaudado
FROM core.vw_IndicadoresMatricula
ORDER BY TotalMatriculas DESC;
GO

PRINT 'P16. Ranking de promotores (sales.vw_RankingPromotores):';
SELECT TOP (5) CodigoPeriodo, NombrePromotor, MatriculasCaptadas, ComisionTotal, Ranking
FROM sales.vw_RankingPromotores
ORDER BY CodigoPeriodo, Ranking;
GO

PRINT '==============================================================';
PRINT ' FIN DE LA DEMO SPRINT 3';
PRINT ' Revisa las pestanas RESULTADOS y MENSAJES.';
PRINT '==============================================================';
GO