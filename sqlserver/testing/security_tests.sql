-- =============================================
-- Matricula Cloud 360 Enterprise
-- testing/security_tests.sql | Casos de prueba de seguridad
-- =============================================
-- Descripcion (Sprint 3): Valida en vivo que cada perfil SOLO puede
-- ejecutar las operaciones autorizadas para su rol:
--
--   S01 MC_Admin puede leer todo (incl. Matriculas y Auditoria)
--   S02 MC_Coordinador SI puede leer reportes academicos
--   S03 MC_Coordinador NO puede leer comisiones (DENY schema sales)
--   S04 MC_Coordinador SI puede ejecutar usp_RegistrarMatricula
--   S05 MC_Promotor SI puede ejecutar usp_RegistrarEstudiante
--   S06 MC_Promotor NO puede ejecutar usp_RegistrarMatricula (DENY)
--   S07 MC_Promotor NO puede leer security.Usuarios (DENY)
--   S08 MC_Promotor SI puede leer la vista de comisiones
--   S09 MC_Coord NO puede leer audit.AuditLog (DENY)
--   S10 Los perfiles son miembros de sus roles
--
-- Tecnica: EXECUTE AS USER (suplantacion de identidad) dentro de
-- TRY/CATCH; REVERT siempre al finalizar. No modifica datos.
-- =============================================

USE MatriculaCloud360DB;
GO

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
GO

PRINT '============================================';
PRINT 'testing/security_tests.sql - Seguridad RN-06';
PRINT '============================================';
GO

DECLARE @Resultados TABLE (
    Numero  INT,
    Caso    VARCHAR(150),
    Esperado VARCHAR(50),
    Obtenido VARCHAR(50),
    Estado  VARCHAR(10)
);
DECLARE @i INT = 0;
DECLARE @Exito BIT;
DECLARE @Obtenido VARCHAR(50);
DECLARE @TryingImp BIT;

-- =============================================
-- S01. ADMIN: acceso total (matriculas + auditoria)
-- =============================================
SET @i = @i + 1;
SET @Exito = 0;
SET @Obtenido = '';

SET @TryingImp = 0;
BEGIN TRY
    EXECUTE AS USER = 'MC_Admin';
    SET @TryingImp = 1;
    DECLARE @N1 INT;
    SELECT @N1 = COUNT(*) FROM core.Matriculas;
    SELECT @N1 = COUNT(*) FROM audit.AuditLog;
    IF @N1 >= 0 SET @Exito = 1;
    REVERT;
    SET @TryingImp = 0;
END TRY
BEGIN CATCH
    IF @TryingImp = 1 REVERT;
    SET @Obtenido = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR);
END CATCH
SET @Obtenido = CASE WHEN @Exito = 1 THEN 'Acceso total OK' ELSE ISNULL(@Obtenido, 'denegado') END;
INSERT INTO @Resultados VALUES (@i, 'S01 MC_Admin lee Matriculas y Auditoria', 'Leer', @Obtenido, CASE WHEN @Exito = 1 THEN '[OK]' ELSE '[ERR]' END);

-- =============================================
-- S02. COORDINADOR: SI lee reportes academicos
-- =============================================
SET @i = @i + 1;
SET @Exito = 0;
SET @Obtenido = '';

SET @TryingImp = 0;
BEGIN TRY
    EXECUTE AS USER = 'MC_Coordinador';
    SET @TryingImp = 1;
    DECLARE @N2 INT;
    SELECT @N2 = COUNT(*) FROM academic.vw_MallaCurricular;
    IF @N2 > 0 SET @Exito = 1;
    REVERT;
    SET @TryingImp = 0;
END TRY
BEGIN CATCH
    IF @TryingImp = 1 REVERT;
    SET @Obtenido = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR);
END CATCH
SET @Obtenido = CASE WHEN @Exito = 1 THEN 'Malla leida (filas=' + CAST(@N2 AS VARCHAR) + ')' ELSE ISNULL(@Obtenido, 'sin resultado') END;
INSERT INTO @Resultados VALUES (@i, 'S02 Coordinador lee vw_MallaCurricular', 'Leer', @Obtenido, CASE WHEN @Exito = 1 THEN '[OK]' ELSE '[ERR]' END);

-- =============================================
-- S03. COORDINADOR: NO puede leer comisiones (DENY)
-- =============================================
SET @i = @i + 1;
SET @Exito = 0;
SET @Obtenido = '';

SET @TryingImp = 0;
BEGIN TRY
    EXECUTE AS USER = 'MC_Coordinador';
    SET @TryingImp = 1;
    SELECT TOP (1) 1 FROM sales.vw_ComisionesDetalle;
    REVERT;
    SET @TryingImp = 0;
END TRY
BEGIN CATCH
    IF @TryingImp = 1 REVERT;
    IF ERROR_NUMBER() = 229
    BEGIN
        SET @Exito = 1;
        SET @Obtenido = 'ERROR 229 (denegado)';
    END
    ELSE
        SET @Obtenido = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR);
END CATCH
INSERT INTO @Resultados VALUES (@i, 'S03 Coordinador NO lee comisiones', 'ERROR 229', ISNULL(@Obtenido, 'acceso permitido'), CASE WHEN @Exito = 1 THEN '[OK]' ELSE '[ERR]' END);

-- =============================================
-- S04. COORDINADOR: SI puede ejecutar usp_RegistrarMatricula
--      (se espera error 51004 por duplicado = prueba que el EXECUTE
--       fue permitido y la regla de negocio sigue activa)
-- =============================================
SET @i = @i + 1;
SET @Exito = 0;
SET @Obtenido = '';

SET @TryingImp = 0;
BEGIN TRY
    EXECUTE AS USER = 'MC_Coordinador';
    SET @TryingImp = 1;
    DECLARE @IdX INT, @MsgX NVARCHAR(500);
    EXEC core.usp_RegistrarMatricula 1, 1, 5, 1, 1, 3, 'SPRINT3 TEST', @IdX OUTPUT, @MsgX OUTPUT;
    REVERT;
    SET @TryingImp = 0;
END TRY
BEGIN CATCH
    IF @TryingImp = 1 REVERT;
    -- Reglas de negocio RN (duplicado, campana o periodo invalido):
    -- si llega aqui, el EXECUTE estaba permitido y el SP valido.
    -- 51004 = estudiante inexistente; 52005 = ventana de matricula
    -- cerrada (puede ocurrir si se ejecuta tras la fecha de cierre
    -- del periodo 2027-I); 52006 = matricula duplicada; 52007 =
    -- campana fuera de periodo; 53001/53002 = comisiones.
    IF ERROR_NUMBER() IN (51004, 52005, 52006, 52007, 53001, 53002)
    BEGIN
        SET @Exito = 1;
        SET @Obtenido = 'EXEC permitido (error ' + CAST(ERROR_NUMBER() AS VARCHAR) + ' negocio)';
    END
    ELSE IF ERROR_NUMBER() IN (229, 297)
        SET @Obtenido = 'ERROR 229 (denegado)';
    ELSE
        SET @Obtenido = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR);
END CATCH
INSERT INTO @Resultados VALUES (@i, 'S04 Coordinador ejecuta usp_RegistrarMatricula', 'EXEC permitido', ISNULL(@Obtenido, 'se inserto'), CASE WHEN @Exito = 1 THEN '[OK]' ELSE '[ERR]' END);

-- =============================================
-- S05. PROMOTOR: SI puede ejecutar usp_RegistrarEstudiante
--      (error 51001 por DNI duplicado = EXECUTE permitido)
-- =============================================
SET @i = @i + 1;
SET @Exito = 0;
SET @Obtenido = '';

SET @TryingImp = 0;
BEGIN TRY
    EXECUTE AS USER = 'MC_Promotor';
    SET @TryingImp = 1;
    DECLARE @IdY INT, @MsgY NVARCHAR(500);
    EXEC core.usp_RegistrarEstudiante 'DNI', '70123456', 'X', 'Y', 'x.y@gmail.com',
         '987000001', '2004-01-01', 'M', NULL, 1, @IdY OUTPUT, @MsgY OUTPUT;
    REVERT;
    SET @TryingImp = 0;
END TRY
BEGIN CATCH
    IF @TryingImp = 1 REVERT;
    IF ERROR_NUMBER() = 51001
    BEGIN
        SET @Exito = 1;
        SET @Obtenido = 'EXEC permitido (error 51001 negocio)';
    END
    ELSE IF ERROR_NUMBER() IN (229, 297)
        SET @Obtenido = 'ERROR 229 (denegado)';
    ELSE
        SET @Obtenido = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR);
END CATCH
INSERT INTO @Resultados VALUES (@i, 'S05 Promotor ejecuta usp_RegistrarEstudiante', 'EXEC permitido', ISNULL(@Obtenido, 'se inserto'), CASE WHEN @Exito = 1 THEN '[OK]' ELSE '[ERR]' END);

-- =============================================
-- S06. PROMOTOR: NO puede ejecutar usp_RegistrarMatricula (DENY)
-- =============================================
SET @i = @i + 1;
SET @Exito = 0;
SET @Obtenido = '';

SET @TryingImp = 0;
BEGIN TRY
    EXECUTE AS USER = 'MC_Promotor';
    SET @TryingImp = 1;
    DECLARE @IdZ INT, @MsgZ NVARCHAR(500);
    EXEC core.usp_RegistrarMatricula 1, 1, 5, 1, 1, 3, 'SPRINT3 TEST', @IdZ OUTPUT, @MsgZ OUTPUT;
    REVERT;
    SET @TryingImp = 0;
END TRY
BEGIN CATCH
    IF @TryingImp = 1 REVERT;
    IF ERROR_NUMBER() IN (229, 297)
    BEGIN
        SET @Exito = 1;
        SET @Obtenido = 'ERROR 229 (denegado)';
    END
    ELSE
        SET @Obtenido = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR);
END CATCH
INSERT INTO @Resultados VALUES (@i, 'S06 Promotor NO ejecuta usp_RegistrarMatricula', 'ERROR 229', ISNULL(@Obtenido, 'se inserto'), CASE WHEN @Exito = 1 THEN '[OK]' ELSE '[ERR]' END);

-- =============================================
-- S07. PROMOTOR: NO puede leer security.Usuarios (DENY)
-- =============================================
SET @i = @i + 1;
SET @Exito = 0;
SET @Obtenido = '';

SET @TryingImp = 0;
BEGIN TRY
    EXECUTE AS USER = 'MC_Promotor';
    SET @TryingImp = 1;
    SELECT TOP (1) 1 FROM security.Usuarios;
    REVERT;
    SET @TryingImp = 0;
END TRY
BEGIN CATCH
    IF @TryingImp = 1 REVERT;
    IF ERROR_NUMBER() IN (229, 297)
    BEGIN
        SET @Exito = 1;
        SET @Obtenido = 'ERROR 229 (denegado)';
    END
    ELSE
        SET @Obtenido = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR);
END CATCH
INSERT INTO @Resultados VALUES (@i, 'S07 Promotor NO lee security.Usuarios', 'ERROR 229', ISNULL(@Obtenido, 'acceso permitido'), CASE WHEN @Exito = 1 THEN '[OK]' ELSE '[ERR]' END);

-- =============================================
-- S08. PROMOTOR: SI puede leer su vista de comisiones
-- =============================================
SET @i = @i + 1;
SET @Exito = 0;
SET @Obtenido = '';

SET @TryingImp = 0;
BEGIN TRY
    EXECUTE AS USER = 'MC_Promotor';
    SET @TryingImp = 1;
    DECLARE @N8 INT;
    SELECT @N8 = COUNT(*) FROM sales.vw_ComisionesDetalle;
    IF @N8 > 0 SET @Exito = 1;
    REVERT;
    SET @TryingImp = 0;
END TRY
BEGIN CATCH
    IF @TryingImp = 1 REVERT;
    SET @Obtenido = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR);
END CATCH
SET @Obtenido = CASE WHEN @Exito = 1 THEN 'Comisiones leidas (filas=' + CAST(@N8 AS VARCHAR) + ')' ELSE ISNULL(@Obtenido, 'sin resultado') END;
INSERT INTO @Resultados VALUES (@i, 'S08 Promotor lee vw_ComisionesDetalle', 'Leer', @Obtenido, CASE WHEN @Exito = 1 THEN '[OK]' ELSE '[ERR]' END);

-- =============================================
-- S09. COORDINADOR: NO puede leer audit.AuditLog (DENY objeto)
-- =============================================
SET @i = @i + 1;
SET @Exito = 0;
SET @Obtenido = '';

SET @TryingImp = 0;
BEGIN TRY
    EXECUTE AS USER = 'MC_Coordinador';
    SET @TryingImp = 1;
    SELECT TOP (1) 1 FROM audit.AuditLog;
    REVERT;
    SET @TryingImp = 0;
END TRY
BEGIN CATCH
    IF @TryingImp = 1 REVERT;
    IF ERROR_NUMBER() IN (229, 297)
    BEGIN
        SET @Exito = 1;
        SET @Obtenido = 'ERROR 229 (denegado)';
    END
    ELSE
        SET @Obtenido = 'ERROR ' + CAST(ERROR_NUMBER() AS VARCHAR);
END CATCH
INSERT INTO @Resultados VALUES (@i, 'S09 Coordinador NO lee audit.AuditLog', 'ERROR 229', ISNULL(@Obtenido, 'acceso permitido'), CASE WHEN @Exito = 1 THEN '[OK]' ELSE '[ERR]' END);

-- =============================================
-- S10. MIEMBROS DE ROLES
-- =============================================
SET @i = @i + 1;
SET @Exito = 0;
SET @Obtenido = '';

IF IS_ROLEMEMBER('rol_Administrador', 'MC_Admin') = 1
   AND IS_ROLEMEMBER('rol_Coordinador_Academico', 'MC_Coordinador') = 1
   AND IS_ROLEMEMBER('rol_Promotor', 'MC_Promotor') = 1
    SET @Exito = 1;
SET @Obtenido = CASE WHEN @Exito = 1 THEN '3 roles OK' ELSE 'falta membresia' END;
INSERT INTO @Resultados VALUES (@i, 'S10 Membresia de roles correcta', '3/3', @Obtenido, CASE WHEN @Exito = 1 THEN '[OK]' ELSE '[ERR]' END);

-- =============================================
-- RESULTADOS
-- =============================================
PRINT '';
PRINT '============================================';
PRINT 'RESULTADOS DE PRUEBAS DE SEGURIDAD:';
PRINT '============================================';
SELECT * FROM @Resultados ORDER BY Numero;

DECLARE @Errores INT;
SELECT @Errores = COUNT(*) FROM @Resultados WHERE Estado = '[ERR]';

IF @Errores = 0
    PRINT '>>> TODAS LAS PRUEBAS DE SEGURIDAD SUPERADAS (0/10) <<<';
ELSE
    PRINT '>>> HAY ' + CAST(@Errores AS VARCHAR) + ' PRUEBAS DE SEGURIDAD FALLIDAS <<<';
PRINT '============================================';
GO