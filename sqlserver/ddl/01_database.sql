-- =============================================
-- Matricula Cloud 360 Enterprise
-- 01_database.sql | Creacion de la base de datos
-- =============================================
-- Descripcion: Crea la base de datos MatriculaCloud360DB
-- con opciones orientadas a disponibilidad y rendimiento.
--
-- IMPORTANTE: Este script es IDEMPOTENTE.
-- Si la base de datos ya existe, NO la recrea (preserva los datos).
-- Puede ejecutarse multiples veces sin errores.
-- =============================================

USE master;
GO

PRINT '============================================';
PRINT '01_database.sql - Creacion de base de datos';
PRINT CONVERT(VARCHAR(30), GETDATE(), 120);
PRINT '============================================';
GO

-- =============================================
-- Crear la base de datos solo si no existe
-- =============================================
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'MatriculaCloud360DB')
BEGIN
    PRINT 'La base de datos no existe. Creando...';

    CREATE DATABASE MatriculaCloud360DB
    ON PRIMARY
    (
        NAME = MatriculaCloud360DB_Data,
        FILENAME = '/var/opt/mssql/data/MatriculaCloud360DB.mdf',
        SIZE = 32MB,
        MAXSIZE = UNLIMITED,
        FILEGROWTH = 32MB
    )
    LOG ON
    (
        NAME = MatriculaCloud360DB_Log,
        FILENAME = '/var/opt/mssql/data/MatriculaCloud360DB_log.ldf',
        SIZE = 16MB,
        MAXSIZE = 500MB,
        FILEGROWTH = 16MB
    );

    -- NOTA: la base hereda la collation del servidor
    -- (SQL_Latin1_General_CP1_CI_AS). Es CI (case insensitive) y
    -- compatible con caracteres espanoles (acentos y enie).

    -- Opciones de la base de datos
    ALTER DATABASE MatriculaCloud360DB
        SET RECOVERY FULL,          -- Permite respaldos de log (punto de restauracion)
            PAGE_VERIFY CHECKSUM,   -- Detecta corrupcion de paginas
            AUTO_CLOSE OFF,         -- Evita cierres frecuentes
            AUTO_SHRINK OFF,        -- Evita fragmentacion por auto-encogido
            AUTO_CREATE_STATISTICS ON,
            AUTO_UPDATE_STATISTICS ON;

    PRINT 'OK: Base de datos MatriculaCloud360DB creada.';
    PRINT '    - Recovery FULL (soporta respaldo y recuperacion)';
    PRINT '    - Data: 32MB (auto-crecimiento 32MB, sin limite)';
    PRINT '    - Log: 16MB (maximo 500MB, auto-crecimiento 16MB)';
END
ELSE
BEGIN
    PRINT 'OK: La base de datos MatriculaCloud360DB ya existe (no se recrea).';
END
GO

-- =============================================
-- Control de versiones de la base de datos
-- =============================================
USE MatriculaCloud360DB;
GO

IF OBJECT_ID('dbo.DatabaseVersion', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.DatabaseVersion
    (
        VersionId INT IDENTITY(1,1) NOT NULL,
        VersionNumber VARCHAR(20) NOT NULL,
        Description NVARCHAR(500) NOT NULL,
        AppliedBy VARCHAR(100) NOT NULL DEFAULT SYSTEM_USER,
        AppliedDate DATETIME NOT NULL DEFAULT GETDATE(),
        CONSTRAINT PK_DatabaseVersion PRIMARY KEY (VersionId),
        CONSTRAINT UK_DatabaseVersion_Numero UNIQUE (VersionNumber)
    );
    PRINT 'OK: Tabla dbo.DatabaseVersion creada.';
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.DatabaseVersion WHERE VersionNumber = '1.0.0')
BEGIN
    INSERT INTO dbo.DatabaseVersion (VersionNumber, Description)
    VALUES ('1.0.0', 'Sprint 1 - Creacion de la base de datos y objetos');
    PRINT 'OK: Version 1.0.0 registrada.';
END
ELSE
BEGIN
    PRINT 'OK: Version 1.0.0 ya registrada.';
END
GO

PRINT '============================================';
PRINT '01_database.sql finalizado.';
PRINT '============================================';
GO
