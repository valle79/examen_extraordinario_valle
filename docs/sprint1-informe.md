# Informe Técnico — Sprint 1 (Infraestructura y Diseño)

**Proyecto**: Matrícula Cloud 360 Enterprise
**Cliente**: Instituto Superior EduFuturo
**Fecha**: 10 de agosto de 2026
**Estado**: COMPLETADO

---

## 1. Objetivo del Sprint

Diseñar, modelar y automatizar la infraestructura de datos del sistema de matrícula, garantizando integridad, rendimiento, seguridad, disponibilidad y escalabilidad sobre **SQL Server 2025 Developer Edition** ejecutado en **Docker**.

## 2. Alcance Entregado

| Entregable | Detalle |
|---|---|
| Infraestructura Docker | `docker/docker-compose.yml`, `.env`, `init/`, volúmenes nombrados, healthcheck |
| Base de datos | `MatriculaCloud360DB` con recovery model FULL y verificación CHECKSUM |
| Modelo lógico | Diagrama en `datasets/modelo_logico_*.png` y `datasets/catalogo_datos_logico.docx` |
| Modelo físico | Diagrama en `datasets/modelo_fisico_*.png` y `datasets/diccionario_datos_fisico.docx` |
| Scripts DDL | `01_database.sql`, `02_schemas.sql`, `03_tables.sql`, `04_constraints.sql` (idempotentes) |
| Datos iniciales | `dml/01_seed_data.sql` con datos de catálogo |
| Utilidades | `utils/verificar_instalacion.sql`, `utils/backup_restore.sql`, `utils/generate_diccionario.sql` |

## 3. Arquitectura

- **SQL Server 2025 Developer Edition** en contenedor `sqlserver_matricula_cloud`.
- **Inicialización automática**: el entrypoint `wait-for-sql.sh` inicia `sqlservr`, espera a que responda y ejecuta `init.sql`.
- **Persistencia**: volúmenes nombrados `matricula_cloud_data`, `matricula_cloud_log`, `matricula_cloud_backup` (SQL Server no es fiable con bind mounts en Docker Desktop — error 31).
- **Puerto**: `1434` en el host (el 1433 está ocupado por el SQL Server local de Windows); configurable en `.env`.

## 4. Modelo de Datos

### 4.1 Esquemas

| Esquema | Descripción |
|---|---|
| `core` | Entidades principales: Sedes, Carreras, Estudiantes, Períodos Académicos, Matrículas, Ubigeos |
| `academic` | Gestión académica: Profesores, Cursos, Especialidades, CarreraCursos (malla), CursoProfesor |
| `sales` | Gestión comercial: Promotores, Campañas de Admisión, Comisiones |
| `security` | Seguridad: Roles, Usuarios |
| `audit` | Auditoría: AuditLog |
| `utils` | Utilidades: control de versiones (DatabaseVersion) |

### 4.2 Métricas del modelo físico

| Indicador | Cantidad |
|---|---|
| Tablas | 17 |
| Foreign Keys | 21 |
| Unique Constraints | 22 |
| Check Constraints | 30 |
| Índices no agrupados de optimización | 14 |
| Esquemas | 6 |

### 4.3 Decisiones de diseño destacadas

- **Identificación de personas por tipo de documento** (`TipoDocumento` DNI/CE + `NumeroDocumento`, con constraints CHECK), solicitada por el cliente, en lugar de DNI único.
- **Solo celular** (`CHAR(9)`, debe empezar con 9) como medio de contacto móvil; se eliminó el teléfono fijo.
- **`academic.Especialidades`** como tabla de catálogo independiente, vinculada a Profesores.
- **`core.Ubigeos`** (código de 6 dígitos) para normalizar departamento, provincia y distrito de las sedes.
- **Columna `EsObligatorio` eliminada** de la malla curricular (`CarreraCursos`), según observación del profesor.
- **Borrado lógico** (`Activo`, `DeletedAt`, `UpdatedAt`) en todas las entidades de negocio para conservar trazabilidad.
- **Malla curricular N:M** entre Carreras y Cursos, con asignación de profesores por período y sede (`CursoProfesor`).
- La base **hereda la collation del servidor** (`SQL_Latin1_General_CP1_CI_AS`), compatible con español, evitando conflictos de collation (Msg 468).

## 5. Instalación y Verificación

```bash
cd docker
docker compose up -d
```

El contenedor queda `healthy` y la verificación automática reporta:

- 17 tablas / 21 FK / 22 UK / 30 CK / 14 índices
- Los 6 esquemas
- Datos iniciales cargados
- Integridad referencial sin huérfanos
- Reglas de unicidad (RN-01, RN-02)

Comando de verificación:

```bash
docker exec sqlserver_matricula_cloud /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "MatriculaCloud360!" -C -i /sqlserver/utils/verificar_instalacion.sql
```

## 6. Seguridad de la Infraestructura

- Contraseña SA fuerte (`MatriculaCloud360!`) gestionada vía variables de entorno.
- `.env` no versionado (`.gitignore`).
- Conexiones cifradas obligatorias en SQL Server 2022+ (`-C` confía en el certificado autofirmado del contenedor).
- Respaldos con `CHECKSUM` y `RECOVERY FULL` para recuperación a un punto en el tiempo.

## 7. Entregables

- Código fuente: `sqlserver/`, `docker/`, `datasets/`, `docs/`
- Video demostrativo: pendiente de grabación por el equipo
