-- =============================================
-- Matricula Cloud 360 Enterprise
-- init.sql | Inicializacion automatica de la base de datos
-- =============================================
-- Descripcion: Script maestro que orquesta la creacion completa
-- de la infraestructura de datos. Es invocado automaticamente por
-- wait-for-sql.sh cuando el contenedor inicia.
--
-- Todos los scripts incluidos son IDEMPOTENTES, por lo que este
-- maestro puede ejecutarse tantas veces como se requiera sin
-- provocar errores ni perder datos.
-- =============================================

USE master;
GO

PRINT '============================================';
PRINT 'MATRICULA CLOUD 360 ENTERPRISE';
PRINT 'Inicializacion automatica de la base de datos';
PRINT 'Fecha: ' + CONVERT(VARCHAR(30), GETDATE(), 120);
PRINT '============================================';
GO

PRINT '==> Paso 1/4: 01_database.sql (creacion de la base de datos)';
:r /sqlserver/ddl/01_database.sql
GO

PRINT '==> Paso 2/4: 02_schemas.sql (esquemas logicos)';
:r /sqlserver/ddl/02_schemas.sql
GO

PRINT '==> Paso 3/4: 03_tables.sql (tablas, restricciones e indices)';
:r /sqlserver/ddl/03_tables.sql
GO

PRINT '==> Paso 4/4: 01_seed_data.sql (datos iniciales del catalogo)';
:r /sqlserver/dml/01_seed_data.sql
GO

PRINT '============================================';
PRINT 'Inicializacion completada.';
PRINT 'Base de datos: MatriculaCloud360DB';
PRINT 'Estado: lista para usar.';
PRINT '============================================';
GO
