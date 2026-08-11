# Docker — Matrícula Cloud 360 Enterprise

## 🐳 Descripción

Este directorio contiene la infraestructura de contenedores que levanta **SQL Server 2025 Developer Edition** y crea **automáticamente** la base de datos `MatriculaCloud360DB` con toda la estructura (Sprint 1) y la programación (Sprint 2).

## 📁 Archivos

| Archivo | Propósito |
|---|---|
| `docker-compose.yml` | Orquestación del contenedor `sqlserver_matricula_cloud` |
| `.env` / `.env.example` | Credenciales y configuración (puerto, contraseña, TZ) |
| `init/init.sql` | Script maestro: ejecuta los 34 pasos de inicialización |
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

# Verificar que quedó healthy y ver los 34 pasos del init
docker compose ps
docker compose logs sqlserver

# Verificación técnica completa (17 tablas, restricciones, datos, Sprint 2)
docker exec sqlserver_matricula_cloud /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "$SA_PASSWORD" -C -i /sqlserver/utils/verificar_instalacion.sql

# Resetear todo (elimina volúmenes; la BD se recrea desde cero)
docker compose down -v
docker compose up -d
```

## 📋 Los 34 pasos de `init.sql`

| Paso | Script | Contenido |
|---|---|---|
| 1/34 | `ddl/01_database.sql` | Creación de la base de datos (FULL, CHECKSUM) |
| 2/34 | `ddl/02_schemas.sql` | Esquemas core, academic, sales, security, audit, utils |
| 3/34 | `ddl/03_tables.sql` | 17 tablas e índices |
| 4/34 | `ddl/04_constraints.sql` | Restricciones 17 PK, 21 FK, 22 UK, 30 CK |
| 5-10/34 | `programmability/functions/*` | 6 funciones de negocio (fn_*.sql) |
| 11-15/34 | `programmability/triggers/*` | 5 triggers: auditoría + comisión automática (trg_*.sql) |
| 16-22/34 | `programmability/views/*` | 7 vistas de reporte (vw_*.sql) |
| 23-31/34 | `programmability/procedures/*` | 9 procedimientos almacenados (usp_*.sql) |
| 32/34 | `dml/01_seed_data.sql` | Datos iniciales (seed) |
| 33/34 | `dml/02_test_data.sql` | Datos de prueba vía los procedimientos |
| 34/34 | `dml/03_test_cases.sql` | 18 casos de prueba de reglas de negocio |

> **Orden crítico**: los triggers dependen de las funciones (la comisión usa `sales.fn_CalcularComision`), y el seed depende de los triggers porque las comisiones se generan automáticamente al matricular (RN-09).

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
