# Matricula Cloud 360 Enterprise - Informe Tecnico Sprint 3

**Proyecto:** Matricula Cloud 360 Enterprise (SQL Server 2025 Developer en Docker)
**Alcance:** Auditoría, borrado lógico, consultas avanzadas, optimización con índices, seguridad por roles, respaldo y recuperación, automatización y analíticas.
**Base de datos:** `MatriculaCloud360DB`

---

## 1. Auditoría de entidades críticas (RN-07)

**Archivos:** `sqlserver/audit/01_audit_tables.sql`, `02_audit_triggers.sql`

- Tabla `audit.AuditLog` centraliza la trazabilidad: quién (`Usuario`), qué (`TableName`, `RecordId`), cómo (`Operation`: INSERT/UPDATE/DELETE) y cuándo (`FechaOperacion`), con los valores anteriores/nuevos en formato JSON (`ValoresAnteriores`, `ValoresNuevos`).
- **11 triggers de auditoría**: los 4 del Sprint 2 (`Estudiantes`, `Matriculas`, `Promotores`, `Comisiones`) más 7 nuevos del Sprint 3: `Sedes`, `Carreras`, `PeriodosAcademicos`, `Profesores`, `Cursos`, `CampaniasAdmision` y `Usuarios`.
- Índices de soporte para las consultas de trazabilidad: `IX_AuditLog_TableName`, `IX_AuditLog_Usuario`, `IX_AuditLog_FechaOperacion`.
- Vista `audit.vw_TrazaAuditoria` para el reporte legible de la trazabilidad (es lo único que pueden ver los coordinadores, no la tabla).

## 2. Borrado lógico con DeletedAt (RN-10)

**Archivo:** `sqlserver/audit/03_soft_delete.sql`

- **7 triggers `INSTEAD OF DELETE`** convierten cualquier `DELETE` en un `UPDATE` de las columnas `DeletedAt`, `Activo` y `UpdatedAt`: `Estudiantes`, `Matriculas`, `Sedes`, `Carreras`, `Profesores`, `Cursos`, `Promotores`.
- **Decisión de diseño validada por experimento**: cuando existe un trigger `INSTEAD OF DELETE`, el trigger `AFTER DELETE` NO se dispara. Por eso el trigger INSTEAD OF (a) aplica el borrado lógico vía UPDATE y (b) registra **él mismo** la operación `DELETE` en `audit.AuditLog`. El `UPDATE` interno dispara el trigger `AFTER UPDATE` de auditoría, y el registro cambia a `Activo = 0`.
- Resultado: la información nunca se destruye, la unicidad histórica se conserva y el requisito `deleted_at` queda satisfecho de forma transparente para las aplicaciones.

## 3. Consultas avanzadas

**Archivo:** `sqlserver/optimization/02_advanced_queries.sql` (Q1–Q10) y vistas `vw_IndicadoresMatricula`, `vw_RankingPromotores`, `vw_TendenciaMatriculas`

| Técnica | Uso |
|---|---|
| CTE (WITH) | Q1 dashboard, Q2 ranking, Q5 variación, Q8 campañas, Q9 franjas horarias |
| CTE recursiva | Q9 malla curricular por semestre (créditos acumulados) |
| Funciones de ventana | `ROW_NUMBER` (Q2, Q5), `RANK`/`DENSE_RANK` (Q3), `LAG` (Q5), `SUM OVER` (Q4 acumulado, Q10 tendencia) |
| Agregados extendidos | `ROLLUP` (Q1 matrículas por periodo/carrera/sede con subtotales) |
| Expresiones | `CASE`, conversión de fechas, particionado `PARTITION BY` |

## 4. Optimización con índices

**Archivos:** `sqlserver/optimization/01_indexes.sql`, `03_performance_tests.sql`

**Índices nuevos (3, además de los 14 del Sprint 1 → 17 no agrupados en total):**

| Índice | Tabla | Tipo | Para qué consulta |
|---|---|---|---|
| `IX_Matriculas_PeriodoEstado` | `core.Matriculas` | Compuesto + filtrado + covering | Q1 dashboard (matrículas por periodo/sede, solo activas) |
| `IX_Matriculas_PromotorPeriodo` | `core.Matriculas` | Compuesto | Q2/Q3 ranking de promotores |
| `IX_Comisiones_Campania` | `sales.Comisiones` | Compuesto | Q4/Q8 comisiones y campañas |

Junto a los 14 del Sprint 1 suman **17 índices no agrupados** sobre las tablas de negocio.

### Pruebas comparativas antes/después

`03_performance_tests.sql` ejecuta dos pruebas:

- **Parte A (entorno real):** los 3 índices se deshabilitan (`ALTER INDEX ... DISABLE`), se ejecutan las consultas críticas Q1/Q2/Q3 con `SET STATISTICS IO, TIME`, luego se reconstruyen (`REBUILD`) y se vuelve a medir. Resultados acumulados en la tabla temp `#ResultadosParteA`.
- **Parte B (volumen masivo):** se crea `dbo.PerfMatriculas` con **1,000,000 de filas** simulando matrículas reales; una consulta de agregación por periodo se ejecuta **sin índice** (recorrido completo o *scan*) y **con índice** (`IX_Perf_PeriodoEstado`, *seek*). Se capturan los **planes de ejecución** con `SET SHOWPLAN_XML` en ambos escenarios (Table Scan vs Index Seek) como evidencia del análisis. Tras la prueba se genera un nuevo respaldo FULL para restablecer la cadena de respaldos LOG (la conmutación SIMPLE → FULL la interrumpe). La tabla se elimina al final, sin dejar residuos.

Resultado esperado: reducción de lecturas lógicas (logical reads) y de tiempo de CPU del orden de decenas a cientos de veces en la Parte B al pasar de *scan* a *seek*.

## 5. Seguridad: perfiles, roles y permisos (RN-06)

**Archivos:** `sqlserver/security/01_logins_users.sql`, `02_roles.sql`, `03_permissions.sql`

| Perfil | Login | Rol | Permisos clave |
|---|---|---|---|
| Administrador | `MC_Admin` | `rol_Administrador` + `db_owner` | Acceso total (todas las tablas, SP, vistas, respaldo) |
| Coordinador académico | `MC_Coordinador` | `rol_Coordinador_Academico` | Lectura de reportes académicos (`vw_MallaCurricular`, `vw_ProfesoresDetalle`, vistas analíticas `vw_IndicadoresMatricula`, `vw_TendenciaMatriculas`, `vw_RankingPromotores`), trazabilidad vía `vw_TrazaAuditoria`; **DENY** sobre las tablas de `sales` (Comisiones, Promotores, Campañas), `audit.AuditLog`, `security`, y UPDATE/DELETE sobre `core` |
| Promotor | `MC_Promotor` | `rol_Promotor` | Registrar estudiantes (`usp_RegistrarEstudiante`), ver sus comisiones (`vw_ComisionesDetalle`); **DENY** sobre matrículas (`usp_RegistrarMatricula`), comisiones, campañas, `security` y `audit` |

- Técnica: `REVOKE` previo (limpieza de permisos directos heredados del Sprint 2), luego `GRANT` y `DENY` explícitos. El DENY prevalece siempre, incluso si el usuario pertenece a varios roles.
- Nota de diseño: el DENY al coordinador se aplica a `audit.AuditLog` (objeto), **no** al esquema `audit`, para no anular el GRANT de `vw_TrazaAuditoria`.
- **Validado por pruebas** (`testing/security_tests.sql`, S01–S10): operaciones denegadas producen error 229/297 y se comprueban con `EXECUTE AS USER` + `REVERT`.

## 6. Respaldo y recuperación

**Archivos:** `sqlserver/maintenance/01_backup.sql`, `02_restore.sql`, `03_maintenance.sql`, `sqlserver/testing/recovery_tests.sql`

- **Estrategia** (modelo de recuperación FULL):
  - Respaldo **FULL** diario (02:00) → job `MC360_BackupCompleto`.
  - Respaldo **DIFERENCIAL** cada 6 horas → job `MC360_BackupDiferencial`.
  - Respaldo de **LOG** cada 30 minutos → job `MC360_BackupLog` (permite recuperación point-in-time).
  - Mantenimiento semanal de índices (`MC360_MantenimientoIndices`) y verificación de integridad (`MC360_VerificacionIntegridad`).
- Los respaldos se escriben en `/var/opt/mssql/backup` (volumen Docker `matricula_cloud_backup`) y su historial queda en `msdb.dbo.backupset`.
- **Prueba de recuperación** (`recovery_tests.sql`): inserta un marcador → respaldo FULL → simula la pérdida (DELETE físico) → restaura la base → verifica que el marcador volvió y corre `DBCC CHECKDB`. Todo el flujo termina con la base operativa.
- **Requisito de infraestructura**: `MSSQL_AGENT_ENABLED=true` en `docker-compose.yml`.

## 7. Automatización (SQL Agent)

`maintenance/03_maintenance.sql` crea 5 jobs idempotentes (se eliminan y recrean) con horarios definidos, y demuestra además la consulta de fragmentación (`sys.dm_db_index_physical_stats`) que alimenta el reindexado.

## 8. Analíticas e indicadores institucionales

**Dashboard:** `dashboard/generar_indicadores.sql` → genera `dashboard/indicadores.html` (autocontenido, sin dependencias externas).

Indicadores por: **matrículas** (totales, por periodo, tendencia diaria con acumulado y crecimiento), **carreras** (participación %), **sedes** (distribución), **campañas** (captación y monto), **promotores** (ranking con RANK + LAG de variación vs. periodo anterior). Incluye KPIs, últimas operaciones de auditoría y estado de respaldo/jobs.

## 9. Pruebas integradas (Sprint 3)

| Archivo | Cobertura |
|---|---|
| `testing/functional_tests.sql` | F01–F08: auditoría de INSERT/UPDATE/DELETE, borrado lógico, vistas analíticas, índices habilitados e integración de SP (todo reversible con ROLLBACK) |
| `testing/security_tests.sql` | S01–S10: matriz GRANT/DENY de los 3 perfiles con error esperado 229 |
| `testing/recovery_tests.sql` | Respaldo → pérdida simulada → restauración → verificación + CHECKDB, devolviendo la BD a MULTI_USER |
| `utils/verificar_instalacion.sql` | Verificación integral (17 tablas, 21 FK, 22 UK, 30 CK, 17 índices, datos por ventana, objetos, roles y permisos) |

## 10. Guía rápida de ejecución

```bash
# 1. Levantar el entorno (recrea la BD con los 49 pasos de init.sql)
docker compose -f docker/docker-compose.yml up -d

# 2. Verificación integral
docker compose -f docker/docker-compose.yml exec sqlserver /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "$SA_PASSWORD" -C -i /sqlserver/utils/verificar_instalacion.sql

# 3. Demo para la sustentación (preguntas probables del profesor)
docker compose -f docker/docker-compose.yml exec sqlserver /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "$SA_PASSWORD" -C -i /sqlserver/utils/demo_profesor_sprint3.sql

# 4. Dashboard de indicadores (genera dashboard/indicadores.html)
docker compose -f docker/docker-compose.yml exec sqlserver /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "$SA_PASSWORD" -C -i /dashboard/generar_indicadores.sql
```

> **Nota:** tanto `init.sql` como cada script individual son **idempotentes**: se pueden ejecutar cuantas veces se quiera sin errores ni pérdida de datos.