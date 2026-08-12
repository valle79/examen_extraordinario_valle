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
--
-- ORDEN DE EJECUCION (Sprint 2):
--   01_database -> 02_schemas -> 03_tables -> 04_constraints ->
--   programmability/functions -> programmability/triggers ->
--   programmability/views -> programmability/procedures ->
--   security -> seed -> test data -> test cases.
--   Los triggers de comision dependen de las funciones
--   (sales.fn_CalcularComision) y el seed depende de los triggers
--   (las comisiones se generan automaticamente al matricular).
--   La seguridad (RN-06) se aplica despues de crear los objetos,
--   para poder otorgar GRANT/DENY sobre los mismos.
-- =============================================

USE master;
GO

PRINT '============================================';
PRINT 'MATRICULA CLOUD 360 ENTERPRISE';
PRINT 'Inicializacion automatica de la base de datos';
PRINT 'Fecha: ' + CONVERT(VARCHAR(30), GETDATE(), 120);
PRINT '============================================';
GO

PRINT '==> Paso 1/35: 01_database.sql (creacion de la base de datos)';
:r /sqlserver/ddl/01_database.sql
GO

PRINT '==> Paso 2/35: 02_schemas.sql (esquemas logicos)';
:r /sqlserver/ddl/02_schemas.sql
GO

PRINT '==> Paso 3/35: 03_tables.sql (tablas e indices)';
:r /sqlserver/ddl/03_tables.sql
GO

PRINT '==> Paso 4/35: 04_constraints.sql (PK, FK, UK, CK)';
:r /sqlserver/ddl/04_constraints.sql
GO

PRINT '==> Paso 5/35: functions/fn_PeriodoMatriculaHabilitado.sql';
:r /sqlserver/programmability/functions/fn_PeriodoMatriculaHabilitado.sql
GO

PRINT '==> Paso 6/35: functions/fn_ExisteEstudianteConDocumento.sql';
:r /sqlserver/programmability/functions/fn_ExisteEstudianteConDocumento.sql
GO

PRINT '==> Paso 7/35: functions/fn_EdadEstudiante.sql';
:r /sqlserver/programmability/functions/fn_EdadEstudiante.sql
GO

PRINT '==> Paso 8/35: functions/fn_TotalMatriculadosCarrera.sql';
:r /sqlserver/programmability/functions/fn_TotalMatriculadosCarrera.sql
GO

PRINT '==> Paso 9/35: functions/fn_CalcularComision.sql';
:r /sqlserver/programmability/functions/fn_CalcularComision.sql
GO

PRINT '==> Paso 10/35: functions/fn_CalcularBonoPromotor.sql';
:r /sqlserver/programmability/functions/fn_CalcularBonoPromotor.sql
GO

PRINT '==> Paso 11/35: triggers/trg_Audit_Estudiantes.sql';
:r /sqlserver/programmability/triggers/trg_Audit_Estudiantes.sql
GO

PRINT '==> Paso 12/35: triggers/trg_Audit_Matriculas.sql';
:r /sqlserver/programmability/triggers/trg_Audit_Matriculas.sql
GO

PRINT '==> Paso 13/35: triggers/trg_Audit_Promotores.sql';
:r /sqlserver/programmability/triggers/trg_Audit_Promotores.sql
GO

PRINT '==> Paso 14/35: triggers/trg_Audit_Comisiones.sql';
:r /sqlserver/programmability/triggers/trg_Audit_Comisiones.sql
GO

PRINT '==> Paso 15/35: triggers/trg_Comision_Automatica.sql';
:r /sqlserver/programmability/triggers/trg_Comision_Automatica.sql
GO

PRINT '==> Paso 16/35: views/vw_EstudiantesDetalle.sql';
:r /sqlserver/programmability/views/vw_EstudiantesDetalle.sql
GO

PRINT '==> Paso 17/35: views/vw_MatriculasDetalle.sql';
:r /sqlserver/programmability/views/vw_MatriculasDetalle.sql
GO

PRINT '==> Paso 18/35: views/vw_ComisionesDetalle.sql';
:r /sqlserver/programmability/views/vw_ComisionesDetalle.sql
GO

PRINT '==> Paso 19/35: views/vw_DesempenoPromotores.sql';
:r /sqlserver/programmability/views/vw_DesempenoPromotores.sql
GO

PRINT '==> Paso 20/35: views/vw_MallaCurricular.sql';
:r /sqlserver/programmability/views/vw_MallaCurricular.sql
GO

PRINT '==> Paso 21/35: views/vw_ProfesoresDetalle.sql';
:r /sqlserver/programmability/views/vw_ProfesoresDetalle.sql
GO

PRINT '==> Paso 22/35: views/vw_ReporteMatriculasPeriodo.sql';
:r /sqlserver/programmability/views/vw_ReporteMatriculasPeriodo.sql
GO

PRINT '==> Paso 23/35: procedures/usp_RegistrarEstudiante.sql';
:r /sqlserver/programmability/procedures/usp_RegistrarEstudiante.sql
GO

PRINT '==> Paso 24/35: procedures/usp_ActualizarEstudiante.sql';
:r /sqlserver/programmability/procedures/usp_ActualizarEstudiante.sql
GO

PRINT '==> Paso 25/35: procedures/usp_EliminarEstudianteLogico.sql';
:r /sqlserver/programmability/procedures/usp_EliminarEstudianteLogico.sql
GO

PRINT '==> Paso 26/35: procedures/usp_RegistrarPromotor.sql';
:r /sqlserver/programmability/procedures/usp_RegistrarPromotor.sql
GO

PRINT '==> Paso 27/35: procedures/usp_RegistrarMatricula.sql';
:r /sqlserver/programmability/procedures/usp_RegistrarMatricula.sql
GO

PRINT '==> Paso 28/35: procedures/usp_RetirarMatricula.sql';
:r /sqlserver/programmability/procedures/usp_RetirarMatricula.sql
GO

PRINT '==> Paso 29/35: procedures/usp_EliminarMatriculaLogico.sql';
:r /sqlserver/programmability/procedures/usp_EliminarMatriculaLogico.sql
GO

PRINT '==> Paso 30/35: procedures/usp_MarcarComisionPagada.sql';
:r /sqlserver/programmability/procedures/usp_MarcarComisionPagada.sql
GO

PRINT '==> Paso 31/35: procedures/usp_ConsultarMatriculas.sql';
:r /sqlserver/programmability/procedures/usp_ConsultarMatriculas.sql
GO

PRINT '==> Paso 32/35: security/01_usuarios_permisos.sql (perfiles y permisos RN-06)';
:r /sqlserver/security/01_usuarios_permisos.sql
GO

PRINT '==> Paso 33/35: 01_seed_data.sql (datos iniciales del catalogo)';
:r /sqlserver/dml/01_seed_data.sql
GO

PRINT '==> Paso 34/35: 02_test_data.sql (datos de prueba)';
:r /sqlserver/dml/02_test_data.sql
GO

PRINT '==> Paso 35/35: 03_test_cases.sql (casos de prueba de reglas de negocio)';
:r /sqlserver/dml/03_test_cases.sql
GO

PRINT '============================================';
PRINT 'Inicializacion completada.';
PRINT 'Base de datos: MatriculaCloud360DB';
PRINT 'Estado: lista para usar.';
PRINT '============================================';
GO
