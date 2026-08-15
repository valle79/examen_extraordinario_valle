-- =============================================
-- Matricula Cloud 360 Enterprise
-- security/01_usuarios_permisos.sql (ORQUESTADOR)
-- =============================================
-- Descripcion (Sprint 3): La seguridad RN-06 esta dividida en tres
-- scripts especializados:
--
--   01_logins_users.sql  -> logins y usuarios
--   02_roles.sql         -> roles de base de datos
--   03_permissions.sql   -> GRANT / DENY / REVOKE por rol
--
-- Este archivo es un ORQUESTADOR que incluye los tres scripts para
-- mantener la compatibilidad con el proceso de inicializacion
-- (docker/init/init.sql) que invoca security/01_usuarios_permisos.sql.
--
-- Uso: ejecutar con sqlcmd (compatibilidad total con :r).
-- =============================================

USE master;
GO

PRINT '============================================';
PRINT '01_usuarios_permisos.sql (orquestador)';
PRINT '============================================';
GO

:r /sqlserver/security/01_logins_users.sql
GO

:r /sqlserver/security/02_roles.sql
GO

:r /sqlserver/security/03_permissions.sql
GO

PRINT '============================================';
PRINT '01_usuarios_permisos.sql finalizado.';
PRINT '============================================';
GO