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
-- ORDEN DE EJECUCION (Sprint 3):
--   Sprint 2 (pasos 1-35):
--   01_database -> 02_schemas -> 03_tables -> 04_constraints ->
--   programmability/functions -> programmability/triggers ->
--   programmability/views -> programmability/procedures ->
--   security -> seed -> test data -> test cases.
--   Los triggers de comision dependen de las funciones
--   (sales.fn_CalcularComision) y el seed depende de los triggers
--   (las comisiones se generan automaticamente al matricular).
--   La seguridad (RN-06) se aplica despues de crear los objetos,
--   para poder otorgar GRANT/DENY sobre los mismos.
--
--   Sprint 3 (pasos 33-49):
--   audit/01 (tabla + indices + vista de traza) ->
--   views analiticas (deben existir antes de los GRANT de seguridad) ->
--   security (perfiles, roles y permisos GRANT/DENY/REVOKE) ->
--   seed -> test data -> test cases ->
--   audit/02 (triggers de auditoria) -> audit/03 (borrado logico) ->
--   optimization (indices, consultas avanzadas y pruebas antes/despues) ->
--   maintenance (primer respaldo FULL e instalacion de jobs SQL Agent) ->
--   testing funcional y de seguridad (Sprint 3).
--   Los jobs SQL Agent requieren MSSQL_AGENT_ENABLED=true (docker-compose).
-- =============================================

USE master;
GO

PRINT '============================================';
PRINT 'MATRICULA CLOUD 360 ENTERPRISE';
PRINT 'Inicializacion automatica de la base de datos';
PRINT 'Fecha: ' + CONVERT(VARCHAR(30), GETDATE(), 120);
PRINT '============================================';
GO

PRINT '==> Paso 1/49: 01_database.sql (creacion de la base de datos)';
:r /sqlserver/ddl/01_database.sql
GO

PRINT '==> Paso 2/49: 02_schemas.sql (esquemas logicos)';
:r /sqlserver/ddl/02_schemas.sql
GO

PRINT '==> Paso 3/49: 03_tables.sql (tablas e indices)';
:r /sqlserver/ddl/03_tables.sql
GO

PRINT '==> Paso 4/49: 04_constraints.sql (PK, FK, UK, CK)';
:r /sqlserver/ddl/04_constraints.sql
GO

PRINT '==> Paso 5/49: functions/fn_PeriodoMatriculaHabilitado.sql';
:r /sqlserver/programmability/functions/fn_PeriodoMatriculaHabilitado.sql
GO

PRINT '==> Paso 6/49: functions/fn_ExisteEstudianteConDocumento.sql';
:r /sqlserver/programmability/functions/fn_ExisteEstudianteConDocumento.sql
GO

PRINT '==> Paso 7/49: functions/fn_EdadEstudiante.sql';
:r /sqlserver/programmability/functions/fn_EdadEstudiante.sql
GO

PRINT '==> Paso 8/49: functions/fn_TotalMatriculadosCarrera.sql';
:r /sqlserver/programmability/functions/fn_TotalMatriculadosCarrera.sql
GO

PRINT '==> Paso 9/49: functions/fn_CalcularComision.sql';
:r /sqlserver/programmability/functions/fn_CalcularComision.sql
GO

PRINT '==> Paso 10/49: functions/fn_CalcularBonoPromotor.sql';
:r /sqlserver/programmability/functions/fn_CalcularBonoPromotor.sql
GO

PRINT '==> Paso 11/49: triggers/trg_Audit_Estudiantes.sql';
:r /sqlserver/programmability/triggers/trg_Audit_Estudiantes.sql
GO

PRINT '==> Paso 12/49: triggers/trg_Audit_Matriculas.sql';
:r /sqlserver/programmability/triggers/trg_Audit_Matriculas.sql
GO

PRINT '==> Paso 13/49: triggers/trg_Audit_Promotores.sql';
:r /sqlserver/programmability/triggers/trg_Audit_Promotores.sql
GO

PRINT '==> Paso 14/49: triggers/trg_Audit_Comisiones.sql';
:r /sqlserver/programmability/triggers/trg_Audit_Comisiones.sql
GO

PRINT '==> Paso 15/49: triggers/trg_Comision_Automatica.sql';
:r /sqlserver/programmability/triggers/trg_Comision_Automatica.sql
GO

PRINT '==> Paso 16/49: views/vw_EstudiantesDetalle.sql';
:r /sqlserver/programmability/views/vw_EstudiantesDetalle.sql
GO

PRINT '==> Paso 17/49: views/vw_MatriculasDetalle.sql';
:r /sqlserver/programmability/views/vw_MatriculasDetalle.sql
GO

PRINT '==> Paso 18/49: views/vw_ComisionesDetalle.sql';
:r /sqlserver/programmability/views/vw_ComisionesDetalle.sql
GO

PRINT '==> Paso 19/49: views/vw_DesempenoPromotores.sql';
:r /sqlserver/programmability/views/vw_DesempenoPromotores.sql
GO

PRINT '==> Paso 20/49: views/vw_MallaCurricular.sql';
:r /sqlserver/programmability/views/vw_MallaCurricular.sql
GO

PRINT '==> Paso 21/49: views/vw_ProfesoresDetalle.sql';
:r /sqlserver/programmability/views/vw_ProfesoresDetalle.sql
GO

PRINT '==> Paso 22/49: views/vw_ReporteMatriculasPeriodo.sql';
:r /sqlserver/programmability/views/vw_ReporteMatriculasPeriodo.sql
GO

PRINT '==> Paso 23/49: procedures/usp_RegistrarEstudiante.sql';
:r /sqlserver/programmability/procedures/usp_RegistrarEstudiante.sql
GO

PRINT '==> Paso 24/49: procedures/usp_ActualizarEstudiante.sql';
:r /sqlserver/programmability/procedures/usp_ActualizarEstudiante.sql
GO

PRINT '==> Paso 25/49: procedures/usp_EliminarEstudianteLogico.sql';
:r /sqlserver/programmability/procedures/usp_EliminarEstudianteLogico.sql
GO

PRINT '==> Paso 26/49: procedures/usp_RegistrarPromotor.sql';
:r /sqlserver/programmability/procedures/usp_RegistrarPromotor.sql
GO

PRINT '==> Paso 27/49: procedures/usp_RegistrarMatricula.sql';
:r /sqlserver/programmability/procedures/usp_RegistrarMatricula.sql
GO

PRINT '==> Paso 28/49: procedures/usp_RetirarMatricula.sql';
:r /sqlserver/programmability/procedures/usp_RetirarMatricula.sql
GO

PRINT '==> Paso 29/49: procedures/usp_EliminarMatriculaLogico.sql';
:r /sqlserver/programmability/procedures/usp_EliminarMatriculaLogico.sql
GO

PRINT '==> Paso 30/49: procedures/usp_MarcarComisionPagada.sql';
:r /sqlserver/programmability/procedures/usp_MarcarComisionPagada.sql
GO

PRINT '==> Paso 31/49: procedures/usp_ConsultarMatriculas.sql';
:r /sqlserver/programmability/procedures/usp_ConsultarMatriculas.sql
GO

PRINT '==> Paso 32/49: procedures/usp_ConsultarEstudiantes.sql';
:r /sqlserver/programmability/procedures/usp_ConsultarEstudiantes.sql
GO

PRINT '==> Paso 33/49: audit/01_audit_tables.sql (tabla de auditoria e indices)';
:r /sqlserver/audit/01_audit_tables.sql
GO

PRINT '==> Paso 34/49: views/vw_IndicadoresMatricula.sql (indicadores por periodo)';
:r /sqlserver/programmability/views/vw_IndicadoresMatricula.sql
GO

PRINT '==> Paso 35/49: views/vw_RankingPromotores.sql (ranking con ventanas)';
:r /sqlserver/programmability/views/vw_RankingPromotores.sql
GO

PRINT '==> Paso 36/49: views/vw_TendenciaMatriculas.sql (tendencia diaria)';
:r /sqlserver/programmability/views/vw_TendenciaMatriculas.sql
GO

PRINT '==> Paso 37/49: security/01_usuarios_permisos.sql (perfiles y permisos RN-06)';
:r /sqlserver/security/01_usuarios_permisos.sql
GO

PRINT '==> Paso 38/49: 01_seed_data.sql (datos iniciales del catalogo)';
:r /sqlserver/dml/01_seed_data.sql
GO

PRINT '==> Paso 39/49: 02_test_data.sql (datos de prueba)';
:r /sqlserver/dml/02_test_data.sql
GO

PRINT '==> Paso 40/49: 03_test_cases.sql (casos de prueba de reglas de negocio)';
:r /sqlserver/dml/03_test_cases.sql
GO

PRINT '==> Paso 41/49: audit/02_audit_triggers.sql (auditoria de operaciones DML)';
:r /sqlserver/audit/02_audit_triggers.sql
GO

PRINT '==> Paso 42/49: audit/03_soft_delete.sql (borrado logico con DeletedAt)';
:r /sqlserver/audit/03_soft_delete.sql
GO

PRINT '==> Paso 43/49: optimization/01_indexes.sql (indices para consultas criticas)';
:r /sqlserver/optimization/01_indexes.sql
GO

PRINT '==> Paso 44/49: optimization/02_advanced_queries.sql (consultas avanzadas)';
:r /sqlserver/optimization/02_advanced_queries.sql
GO

PRINT '==> Paso 45/49: optimization/03_performance_tests.sql (pruebas de rendimiento)';
:r /sqlserver/optimization/03_performance_tests.sql
GO

PRINT '==> Paso 46/49: maintenance/01_backup.sql (primer respaldo FULL)';
:r /sqlserver/maintenance/01_backup.sql
GO

PRINT '==> Paso 47/49: maintenance/03_maintenance.sql (jobs de SQL Agent)';
:r /sqlserver/maintenance/03_maintenance.sql
GO

PRINT '==> Paso 48/49: testing/functional_tests.sql (pruebas funcionales Sprint 3)';
:r /sqlserver/testing/functional_tests.sql
GO

PRINT '==> Paso 49/49: testing/security_tests.sql (pruebas de seguridad Sprint 3)';
:r /sqlserver/testing/security_tests.sql
GO

PRINT '============================================';
PRINT 'Inicializacion completada (Sprint 3).';
PRINT 'Base de datos: MatriculaCloud360DB';
PRINT 'Auditoria, borrado logico, indices, seguridad,';
PRINT 'respaldo y automatizacion: listos para usar.';
PRINT '============================================';
GO
