-- =============================================
-- Matricula Cloud 360 Enterprise
-- security/03_permissions.sql | GRANT, DENY y REVOKE
-- =============================================
-- Descripcion (Sprint 3): Gestiona los permisos de cada perfil
-- (RN-06) usando los tres verbos de seguridad T-SQL:
--
--   GRANT  -> otorga un permiso a un rol
--   DENY   -> prohibe explicitamente una operacion (prevalece sobre GRANT)
--   REVOKE -> elimina un permiso previamente otorgado o denegado
--
-- Matriz de permisos:
--   ROL                    PUEDE (GRANT)                          NO PUEDE (DENY)
--   ---------------------------------------------------------------------------
--   rol_Administrador      Todo (db_owner asignado en 02_roles)    -
--   rol_Coordinador        Vistas academicas/core, analytics,      Comisiones,
--     _Academico           registrar/retirar matriculas,           seguridad,
--                          actualizar estudiantes                  auditoria
--   rol_Promotor           Registrar/consultar estudiantes,        Matriculas,
--                          ver sus comisiones y desempeno          comisiones,
--                                                                  seguridad,
--                                                                  auditoria
--
-- Control de acceso: la mayoria de permisos se otorgan sobre objetos
-- (vistas y procedimientos), de modo que los usuarios acceden a los
-- datos SOLO a traves de ellos (encadenamiento de propiedad: todos
-- los objetos pertenecen a dbo). Las tablas base quedan sin acceso
-- directo para los roles de coordinador y promotor (menor privilegio).
--
-- IDEMPOTENTE: GRANT/DENY/REVOKE pueden reejecutarse sin errores.
-- =============================================

USE MatriculaCloud360DB;
GO

PRINT '============================================';
PRINT 'security/03_permissions.sql - Permisos por rol';
PRINT '============================================';
GO

-- ============================================================
-- 1. LIMPIEZA PREVIA: REVOKE
--    Quita permisos que pudieron quedar de ejecuciones previas o
--    de asignaciones directas en el Sprint 2 (ahora todo se
--    centraliza en roles). REVOKE elimina GRANT/DENY previos.
-- ============================================================
PRINT '>> REVOKE: limpiando permisos directos heredados del Sprint 2...';
REVOKE SELECT ON OBJECT::core.vw_EstudiantesDetalle       FROM [MC_Coordinador], [MC_Promotor];
REVOKE SELECT ON OBJECT::core.vw_MatriculasDetalle        FROM [MC_Coordinador];
REVOKE SELECT ON OBJECT::sales.vw_ComisionesDetalle       FROM [MC_Promotor];
REVOKE EXECUTE ON OBJECT::core.usp_RegistrarEstudiante    FROM [MC_Coordinador], [MC_Promotor];
REVOKE EXECUTE ON OBJECT::core.usp_ActualizarEstudiante   FROM [MC_Coordinador], [MC_Promotor];
REVOKE EXECUTE ON OBJECT::core.usp_EliminarEstudianteLogico FROM [MC_Coordinador], [MC_Promotor];
REVOKE EXECUTE ON OBJECT::core.usp_RegistrarMatricula     FROM [MC_Coordinador];
REVOKE EXECUTE ON OBJECT::core.usp_RetirarMatricula       FROM [MC_Coordinador];
REVOKE EXECUTE ON OBJECT::core.usp_ConsultarMatriculas    FROM [MC_Coordinador], [MC_Promotor];
REVOKE SELECT ON SCHEMA::sales   FROM [MC_Coordinador];
REVOKE SELECT ON SCHEMA::security FROM [MC_Coordinador];
REVOKE SELECT ON SCHEMA::audit   FROM [MC_Coordinador];
REVOKE UPDATE, DELETE ON SCHEMA::core FROM [MC_Coordinador];
REVOKE SELECT, INSERT, UPDATE, DELETE ON SCHEMA::security FROM [MC_Promotor];
REVOKE SELECT, INSERT, UPDATE, DELETE ON SCHEMA::audit FROM [MC_Promotor];
PRINT '>> Permisos directos eliminados (REVOKE OK).';
GO

-- Vuelve a denegar lo que la politica exige DENY (se reaplica abajo
-- a nivel rol para simplificar el mantenimiento).
-- ============================================================
-- 2. GRANT: PERMISOS DEL COORDINADOR ACADEMICO
--    Reportes academicos y core, indicadores analiticos, y
--    procedimientos autorizados.
-- ============================================================
PRINT '>> GRANT a rol_Coordinador_Academico...';

-- Vistas de reporte (core y academic)
GRANT SELECT ON OBJECT::core.vw_EstudiantesDetalle         TO [rol_Coordinador_Academico];
GRANT SELECT ON OBJECT::core.vw_MatriculasDetalle          TO [rol_Coordinador_Academico];
GRANT SELECT ON OBJECT::core.vw_ReporteMatriculasPeriodo   TO [rol_Coordinador_Academico];
GRANT SELECT ON OBJECT::academic.vw_MallaCurricular        TO [rol_Coordinador_Academico];
GRANT SELECT ON OBJECT::academic.vw_ProfesoresDetalle      TO [rol_Coordinador_Academico];

-- Vistas analiticas del Sprint 3 (dashboard institucional)
GRANT SELECT ON OBJECT::core.vw_IndicadoresMatricula       TO [rol_Coordinador_Academico];
GRANT SELECT ON OBJECT::sales.vw_RankingPromotores         TO [rol_Coordinador_Academico];
GRANT SELECT ON OBJECT::core.vw_TendenciaMatriculas        TO [rol_Coordinador_Academico];

-- Vistas de auditoria (solo lectura del registro central)
GRANT SELECT ON OBJECT::audit.vw_TrazaAuditoria            TO [rol_Coordinador_Academico];

-- Funciones de negocio
GRANT EXECUTE ON OBJECT::core.fn_PeriodoMatriculaHabilitado TO [rol_Coordinador_Academico];
GRANT EXECUTE ON OBJECT::core.fn_ExisteEstudianteConDocumento TO [rol_Coordinador_Academico];
GRANT EXECUTE ON OBJECT::core.fn_TotalMatriculadosCarrera   TO [rol_Coordinador_Academico];

-- Procedimientos autorizados
GRANT EXECUTE ON OBJECT::core.usp_RegistrarEstudiante      TO [rol_Coordinador_Academico];
GRANT EXECUTE ON OBJECT::core.usp_ActualizarEstudiante     TO [rol_Coordinador_Academico];
GRANT EXECUTE ON OBJECT::core.usp_EliminarEstudianteLogico TO [rol_Coordinador_Academico];
GRANT EXECUTE ON OBJECT::core.usp_RegistrarMatricula       TO [rol_Coordinador_Academico];
GRANT EXECUTE ON OBJECT::core.usp_RetirarMatricula         TO [rol_Coordinador_Academico];
GRANT EXECUTE ON OBJECT::core.usp_EliminarMatriculaLogico  TO [rol_Coordinador_Academico];
GRANT EXECUTE ON OBJECT::core.usp_ConsultarMatriculas      TO [rol_Coordinador_Academico];
GRANT EXECUTE ON OBJECT::core.usp_ConsultarEstudiantes     TO [rol_Coordinador_Academico];
GO

-- ============================================================
-- 3. GRANT: PERMISOS DEL PROMOTOR
--    Registra estudiantes y consulta sus comisiones/desempeno.
-- ============================================================
PRINT '>> GRANT a rol_Promotor...';

GRANT SELECT ON OBJECT::core.vw_EstudiantesDetalle         TO [rol_Promotor];
GRANT SELECT ON OBJECT::sales.vw_ComisionesDetalle         TO [rol_Promotor];
GRANT SELECT ON OBJECT::sales.vw_DesempenoPromotores       TO [rol_Promotor];
GRANT EXECUTE ON OBJECT::core.usp_RegistrarEstudiante      TO [rol_Promotor];
GRANT EXECUTE ON OBJECT::core.usp_ActualizarEstudiante     TO [rol_Promotor];
GRANT EXECUTE ON OBJECT::core.usp_EliminarEstudianteLogico TO [rol_Promotor];
GRANT EXECUTE ON OBJECT::core.usp_ConsultarMatriculas      TO [rol_Promotor];
GRANT EXECUTE ON OBJECT::core.usp_ConsultarEstudiantes     TO [rol_Promotor];
GO

-- ============================================================
-- 4. DENY: PROHIBICIONES EXPLICITAS
--    El DENY prevalece sobre cualquier GRANT (directo o por rol).
-- ============================================================
PRINT '>> DENY a los roles...';

-- Coordinador: NO ve comisiones, ni seguridad, ni la tabla de
-- auditoria directa (solo la vista de trazabilidad autorizada).
-- NOTA: el DENY se aplica a las TABLAS del esquema sales (no al
-- esquema completo) para que los GRANT sobre las vistas analiticas
-- del esquema (sales.vw_RankingPromotores) sigan funcionando:
-- con cadena de propiedad intacta (todo es de dbo) el DENY sobre la
-- tabla base NO se evalua al acceder via la vista, mientras que un
-- DENY SELECT ON SCHEMA::sales bloquearia la vista completa (error
-- 229), dejando muerto el GRANT. El acceso directo a las tablas de
-- ventas queda denegado explicitamente.
DENY SELECT ON OBJECT::sales.Comisiones        TO [rol_Coordinador_Academico];
DENY SELECT ON OBJECT::sales.Promotores        TO [rol_Coordinador_Academico];
DENY SELECT ON OBJECT::sales.CampaniasAdmision TO [rol_Coordinador_Academico];
DENY SELECT ON SCHEMA::security TO [rol_Coordinador_Academico];
DENY SELECT ON OBJECT::audit.AuditLog TO [rol_Coordinador_Academico];
DENY UPDATE, DELETE ON SCHEMA::core TO [rol_Coordinador_Academico];

-- Promotor: NO registra matriculas ni toca areas sensibles
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::core.Matriculas        TO [rol_Promotor];
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::sales.Comisiones       TO [rol_Promotor];
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::sales.CampaniasAdmision TO [rol_Promotor];
DENY SELECT, INSERT, UPDATE, DELETE ON SCHEMA::security               TO [rol_Promotor];
DENY SELECT, INSERT, UPDATE, DELETE ON SCHEMA::audit                  TO [rol_Promotor];
DENY EXECUTE ON OBJECT::core.usp_RegistrarMatricula   TO [rol_Promotor];
DENY EXECUTE ON OBJECT::core.usp_RetirarMatricula     TO [rol_Promotor];
DENY EXECUTE ON OBJECT::core.usp_EliminarMatriculaLogico TO [rol_Promotor];
GO

-- ============================================================
-- 5. REVOKE ADICIONAL: demostrar el efecto de REVOKE
--    El promotor NO tiene GRANT sobre la vista de matricula
--    detalle; si existiera un GRANT previo, estas 2 sentencias lo
--    eliminarfian. (Idempotente: si no hay permiso, no hace nada).
-- ============================================================
REVOKE SELECT ON OBJECT::core.vw_MatriculasDetalle FROM [rol_Promotor];
REVOKE SELECT ON OBJECT::sales.vw_DesempenoPromotores FROM [MC_Promotor];
GO

-- ============================================================
-- 6. RESUMEN DE SEGURIDAD
-- ============================================================
PRINT '';
PRINT '============================================';
PRINT 'RESUMEN DE PERFILES DE SEGURIDAD (RN-06):';
PRINT '============================================';
PRINT '  rol_Administrador   : db_owner (todo)';
PRINT '  rol_Coordinador     : GRANT vistas/reportes/analiticas + ';
PRINT '                        SP academicos; DENY comisiones, ';
PRINT '                        seguridad y auditoria directa';
PRINT '  rol_Promotor        : GRANT registro/consulta estudiantes ';
PRINT '                        + sus comisiones; DENY matriculas, ';
PRINT '                        seguridad y auditoria';
PRINT '';
PRINT '  Conectar como (host, puerto 1434):';
PRINT '    sqlcmd -S localhost,1434 -U MC_Admin       -P "MCAdmin#2026"';
PRINT '    sqlcmd -S localhost,1434 -U MC_Coordinador -P "MCCoord#2026"';
PRINT '    sqlcmd -S localhost,1434 -U MC_Promotor    -P "MCPromo#2026"';
PRINT '============================================';
GO