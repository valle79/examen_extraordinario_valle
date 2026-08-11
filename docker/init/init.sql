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
--   seed -> test data -> test cases.
--   Los triggers de comision dependen de las funciones
--   (sales.fn_CalcularComision) y el seed depende de los triggers
--   (las comisiones se generan automaticamente al matricular).
-- =============================================

USE master;
GO

PRINT '============================================';
PRINT 'MATRICULA CLOUD 360 ENTERPRISE';
PRINT 'Inicializacion automatica de la base de datos';
PRINT 'Fecha: ' + CONVERT(VARCHAR(30), GETDATE(), 120);
PRINT '============================================';
GO

PRINT '==> Paso 1/34: 01_database.sql (creacion de la base de datos)';
:r /sqlserver/ddl/01_database.sql
GO

PRINT '==> Paso 2/34: 02_schemas.sql (esquemas logicos)';
:r /sqlserver/ddl/02_schemas.sql
GO

PRINT '==> Paso 3/34: 03_tables.sql (tablas e indices)';
:r /sqlserver/ddl/03_tables.sql
GO

PRINT '==> Paso 4/34: 04_constraints.sql (PK, FK, UK, CK)';
:r /sqlserver/ddl/04_constraints.sql
GO

PRINT '==> Paso 5/34: functions/fn_PeriodoMatriculaHabilitado.sql';
:r /sqlserver/programmability/functions/fn_PeriodoMatriculaHabilitado.sql
GO

PRINT '==> Paso 6/34: functions/fn_ExisteEstudianteConDocumento.sql';
:r /sqlserver/programmability/functions/fn_ExisteEstudianteConDocumento.sql
GO

PRINT '==> Paso 7/34: functions/fn_EdadEstudiante.sql';
:r /sqlserver/programmability/functions/fn_EdadEstudiante.sql
GO

PRINT '==> Paso 8/34: functions/fn_TotalMatriculadosCarrera.sql';
:r /sqlserver/programmability/functions/fn_TotalMatriculadosCarrera.sql
GO

PRINT '==> Paso 9/34: functions/fn_CalcularComision.sql';
:r /sqlserver/programmability/functions/fn_CalcularComision.sql
GO

PRINT '==> Paso 10/34: functions/fn_CalcularBonoPromotor.sql';
:r /sqlserver/programmability/functions/fn_CalcularBonoPromotor.sql
GO

PRINT '==> Paso 11/34: triggers/trg_Audit_Estudiantes.sql';
:r /sqlserver/programmability/triggers/trg_Audit_Estudiantes.sql
GO

PRINT '==> Paso 12/34: triggers/trg_Audit_Matriculas.sql';
:r /sqlserver/programmability/triggers/trg_Audit_Matriculas.sql
GO

PRINT '==> Paso 13/34: triggers/trg_Audit_Promotores.sql';
:r /sqlserver/programmability/triggers/trg_Audit_Promotores.sql
GO

PRINT '==> Paso 14/34: triggers/trg_Audit_Comisiones.sql';
:r /sqlserver/programmability/triggers/trg_Audit_Comisiones.sql
GO

PRINT '==> Paso 15/34: triggers/trg_Comision_Automatica.sql';
:r /sqlserver/programmability/triggers/trg_Comision_Automatica.sql
GO

PRINT '==> Paso 16/34: views/vw_EstudiantesDetalle.sql';
:r /sqlserver/programmability/views/vw_EstudiantesDetalle.sql
GO

PRINT '==> Paso 17/34: views/vw_MatriculasDetalle.sql';
:r /sqlserver/programmability/views/vw_MatriculasDetalle.sql
GO

PRINT '==> Paso 18/34: views/vw_ComisionesDetalle.sql';
:r /sqlserver/programmability/views/vw_ComisionesDetalle.sql
GO

PRINT '==> Paso 19/34: views/vw_DesempenoPromotores.sql';
:r /sqlserver/programmability/views/vw_DesempenoPromotores.sql
GO

PRINT '==> Paso 20/34: views/vw_MallaCurricular.sql';
:r /sqlserver/programmability/views/vw_MallaCurricular.sql
GO

PRINT '==> Paso 21/34: views/vw_ProfesoresDetalle.sql';
:r /sqlserver/programmability/views/vw_ProfesoresDetalle.sql
GO

PRINT '==> Paso 22/34: views/vw_ReporteMatriculasPeriodo.sql';
:r /sqlserver/programmability/views/vw_ReporteMatriculasPeriodo.sql
GO

PRINT '==> Paso 23/34: procedures/usp_RegistrarEstudiante.sql';
:r /sqlserver/programmability/procedures/usp_RegistrarEstudiante.sql
GO

PRINT '==> Paso 24/34: procedures/usp_ActualizarEstudiante.sql';
:r /sqlserver/programmability/procedures/usp_ActualizarEstudiante.sql
GO

PRINT '==> Paso 25/34: procedures/usp_EliminarEstudianteLogico.sql';
:r /sqlserver/programmability/procedures/usp_EliminarEstudianteLogico.sql
GO

PRINT '==> Paso 26/34: procedures/usp_RegistrarPromotor.sql';
:r /sqlserver/programmability/procedures/usp_RegistrarPromotor.sql
GO

PRINT '==> Paso 27/34: procedures/usp_RegistrarMatricula.sql';
:r /sqlserver/programmability/procedures/usp_RegistrarMatricula.sql
GO

PRINT '==> Paso 28/34: procedures/usp_RetirarMatricula.sql';
:r /sqlserver/programmability/procedures/usp_RetirarMatricula.sql
GO

PRINT '==> Paso 29/34: procedures/usp_EliminarMatriculaLogico.sql';
:r /sqlserver/programmability/procedures/usp_EliminarMatriculaLogico.sql
GO

PRINT '==> Paso 30/34: procedures/usp_MarcarComisionPagada.sql';
:r /sqlserver/programmability/procedures/usp_MarcarComisionPagada.sql
GO

PRINT '==> Paso 31/34: procedures/usp_ConsultarMatriculas.sql';
:r /sqlserver/programmability/procedures/usp_ConsultarMatriculas.sql
GO

PRINT '==> Paso 32/34: 01_seed_data.sql (datos iniciales del catalogo)';
:r /sqlserver/dml/01_seed_data.sql
GO

PRINT '==> Paso 33/34: 02_test_data.sql (datos de prueba)';
:r /sqlserver/dml/02_test_data.sql
GO

PRINT '==> Paso 34/34: 03_test_cases.sql (casos de prueba de reglas de negocio)';
:r /sqlserver/dml/03_test_cases.sql
GO

PRINT '============================================';
PRINT 'Inicializacion completada.';
PRINT 'Base de datos: MatriculaCloud360DB';
PRINT 'Estado: lista para usar.';
PRINT '============================================';
GO
