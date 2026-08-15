# Docker — Matrícula Cloud 360 Enterprise

## 🐳 Descripción

Este directorio contiene la infraestructura de contenedores que levanta **SQL Server 2025 Developer Edition** y crea **automáticamente** la base de datos `MatriculaCloud360DB` con toda la estructura (Sprint 1), la programación (Sprint 2) y la administración (Sprint 3: auditoría, índices, seguridad, respaldo y automatización).

## 📁 Archivos

| Archivo | Propósito |
|---|---|
| `docker-compose.yml` | Orquestación del contenedor `sqlserver_matricula_cloud` |
| `.env` / `.env.example` | Credenciales y configuración (puerto, contraseña, TZ) |
| `init/init.sql` | Script maestro: ejecuta los 49 pasos de inicialización (Sprint 1 + 2 + 3) |
| `init/wait-for-sql.sh` | Entrypoint: inicia `sqlservr`, espera a que responda y ejecuta `init.sql` |
| `volumes/` | Persistencia local (data/log/backup, solo `.gitkeep` versionados) |

> El bind mount `../sqlserver:/sqlserver` monta los scripts DDL/DML del proyecto dentro del contenedor.

## ⚙️ Configuración (`.env`)

| Variable | Valor por defecto | Descripción |
|---|---|---|
| `SQL_SERVER_PORT` | `1434` | Puerto del host (1433 suele estar ocupado por un SQL Server local) |
| `SA_PASSWORD` | `MatriculaCloud360!` | Contraseña del usuario SA |
| `MSSQL_PID` | `Developer` | Edición de SQL Server |
| `TZ` | `America/Lima` | Zona horaria del contenedor |
| `CONTAINER_NAME` | `sqlserver_matricula_cloud` | Nombre del contenedor |

## 🚀 Uso

```bash
# Levantar la infraestructura (crea la BD automáticamente)
docker compose up -d

# Verificar que quedó healthy y ver los 49 pasos del init
docker compose ps
docker compose logs sqlserver

# Verificación técnica completa (17 tablas, restricciones, datos, Sprint 2 + 3)
docker exec sqlserver_matricula_cloud /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "$SA_PASSWORD" -C -i /sqlserver/utils/verificar_instalacion.sql

# Demo para la sustentación (Sprint 3)
docker exec sqlserver_matricula_cloud /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "$SA_PASSWORD" -C -i /sqlserver/utils/demo_profesor_sprint3.sql

# Resetear todo (elimina volúmenes; la BD se recrea desde cero)
docker compose down -v
docker compose up -d
```

## 📋 Los 49 pasos de `init.sql`

| Pasos | Script | Contenido |
|---|---|---|
| 1/49 | `ddl/01_database.sql` | Creación de la base de datos (FULL, CHECKSUM) |
| 2/49 | `ddl/02_schemas.sql` | Esquemas core, academic, sales, security, audit, utils |
| 3/49 | `ddl/03_tables.sql` | 17 tablas e índices |
| 4/49 | `ddl/04_constraints.sql` | Restricciones 17 PK, 21 FK, 22 UK, 30 CK |
| 5-10/49 | `programmability/functions/*` | 6 funciones de negocio (fn_*.sql) |
| 11-15/49 | `programmability/triggers/*` | 5 triggers: auditoría + comisión automática (trg_*.sql) |
| 16-22/49 | `programmability/views/*` | 7 vistas de reporte (vw_*.sql) |
| 23-32/49 | `programmability/procedures/*` | 10 procedimientos almacenados (usp_*.sql) |
| 33/49 | `audit/01_audit_tables.sql` | Tabla de auditoría + índices + vista de traza |
| 34-36/49 | `programmability/views/vw_Indicadores, Ranking, Tendencia` | 3 vistas analíticas (ventanas) |
| 37/49 | `security/01_usuarios_permisos.sql` | Perfiles RN-06: logins, usuarios y permisos GRANT/DENY |
| 38/49 | `dml/01_seed_data.sql` | Datos iniciales (seed) |
| 39/49 | `dml/02_test_data.sql` | Datos de prueba vía los procedimientos |
| 40/49 | `dml/03_test_cases.sql` | 18 casos de prueba de reglas de negocio |
| 41/49 | `audit/02_audit_triggers.sql` | 7 triggers AFTER de auditoría (entidades críticas) |
| 42/49 | `audit/03_soft_delete.sql` | 7 triggers INSTEAD OF DELETE (borrado lógico DeletedAt) |
| 43/49 | `optimization/01_indexes.sql` | 3 índices compuestos/filtrados/covering |
| 44/49 | `optimization/02_advanced_queries.sql` | 10 consultas avanzadas (CTE, ventanas, ROLLUP) |
| 45/49 | `optimization/03_performance_tests.sql` | Pruebas antes/después + 1,000,000 filas + planes SHOWPLAN_XML |
| 46/49 | `maintenance/01_backup.sql` | Primer respaldo FULL + historial en msdb |
| 47/49 | `maintenance/03_maintenance.sql` | 5 jobs de SQL Agent (backup, índices, integridad) |
| 48/49 | `testing/functional_tests.sql` | Pruebas funcionales F01–F08 |
| 49/49 | `testing/security_tests.sql` | Pruebas de seguridad S01–S10 |

> **Orden crítico**: los triggers dependen de las funciones (la comisión usa `sales.fn_CalcularComision`), el seed depende de los triggers porque las comisiones se generan automáticamente al matricular (RN-09), y los permisos (RN-06) se aplican al final porque los `GRANT`/`DENY` exigen que los objetos existan.

## 💾 Persistencia y respaldos

- Los datos viven en volúmenes **nombrados**: `matricula_cloud_data`, `matricula_cloud_log`, `matricula_cloud_backup`.
- `docker compose down` conserva los datos; `docker compose down -v` los elimina.
- Para respaldar manualmente:
  ```bash
  # Desde dentro del contenedor (ver utils/backup_restore.sql)
  docker exec sqlserver_matricula_cloud /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "$SA_PASSWORD" -C -d MatriculaCloud360DB -Q "BACKUP DATABASE MatriculaCloud360DB TO DISK = '/var/opt/mssql/backup/MatriculaCloud360DB.bak' WITH INIT, CHECKSUM;"
  # Extraer el respaldo al host
  docker cp sqlserver_matricula_cloud:/var/opt/mssql/backup/MatriculaCloud360DB.bak .
  ```

## 🩺 Solución de problemas

| Problema | Causa probable | Solución |
|---|---|---|
| El contenedor no queda `healthy` | Puerto 1433/1434 ocupado | Cambiar `SQL_SERVER_PORT` en `.env` |
| `Msg 468` de collation | Base creada con collation distinta al servidor | `docker compose down -v && up -d` (la base hereda la collation del servidor) |
| `Error: 31` con bind mounts a carpetas Windows | SQL Server no soporta volúmenes bind en Docker Desktop | Usar volúmenes nombrados (ya configurado) |
