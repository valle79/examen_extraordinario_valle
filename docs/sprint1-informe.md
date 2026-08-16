# Matricula Cloud 360 Enterprise - Informe Tecnico Sprint 1

**Proyecto:** Matricula Cloud 360 Enterprise (SQL Server 2025 Developer en Docker)
**Alcance:** Modelado de datos (logico y fisico), infraestructura Docker automatizada, scripts de inicializacion idempotentes, respaldo y verificacion de instalacion.
**Base de datos:** `MatriculaCloud360DB`

---

## 1. Modelado de datos

**Archivos:** `datasets/MODELO_LOGICO_V2.png`, `datasets/MODELO_FISICO_V2.png`, `datasets/catalogo_datos.xlsx`, `datasets/diccionario_datos.pdf`

- **Modelo logico**: entidades, atributos y relaciones del negocio educativo (sedes, carreras, estudiantes, matriculas, malla curricular, promotores, comisiones, campanas).
- **Modelo fisico**: traducido a 17 tablas distribuidas en **6 esquemas** con tipos de datos, claves y restricciones.
- **Diccionario de datos** (`diccionario_datos.pdf`): documenta columnas, tipos SQL, claves, restricciones y descripciones de cada tabla; se genera con `sqlserver/utils/generate_diccionario.sql` (consulta al catalogo del sistema).
- **Catalogo de datos** (`catalogo_datos.xlsx`): datos base proporcionados por el cliente (sedes, carreras, cursos, docentes, promotores, estudiantes, matriculas, malla).

## 2. DDL: base de datos, esquemas y tablas

**Archivos:** `sqlserver/ddl/01_database.sql`, `02_schemas.sql`, `03_tables.sql`, `04_constraints.sql`

### Esquemas (6)

| Esquema | Proposito |
|---|---|
| `core` | Entidades centrales del negocio: Ubigeos, Sedes, Carreras, Estudiantes, PeriodosAcademicos, Matriculas |
| `academic` | Gestion academica: Especialidades, Profesores, Cursos, CarreraCursos (malla), CursoProfesor |
| `sales` | Captacion y comisiones: Promotores, CampaniasAdmision, Comisiones |
| `security` | Roles y Usuarios de aplicacion |
| `audit` | Trazabilidad: AuditLog |
| `utils` | Utilidades y soporte |

### Tablas (17)

| Esquema | Tablas |
|---|---|
| `core` | Ubigeos, Sedes, Carreras, Estudiantes, PeriodosAcademicos, Matriculas |
| `academic` | Especialidades, Profesores, Cursos, CarreraCursos, CursoProfesor |
| `sales` | Promotores, CampaniasAdmision, Comisiones |
| `security` | Roles, Usuarios |
| `audit` | AuditLog |

### Restricciones (en `04_constraints.sql`)

| Tipo | Cantidad | Detalle |
|---|---|---|
| Primary Key | 17 | Una por tabla |
| Foreign Key | 21 | Integridad referencial entre esquemas |
| Unique | 22 | Unicidad de documentos, codigos, emails y malla |
| Check | 30 | Reglas de dominio (RN-01 a RN-09): estados, porcentajes, edades, fechas |

## 3. Infraestructura Docker automatizada

**Archivos:** `docker/docker-compose.yml`, `docker/init/init.sql`, `docker/init/wait-for-sql.sh`, `docker/.env`

- Imagen oficial `mcr.microsoft.com/mssql/server:2025-latest` (SQL Server 2025 Developer Edition), puerto host `1434` para no conflictuar con una instancia local.
- `MSSQL_AGENT_ENABLED=true`: habilita SQL Agent (necesario para los jobs del Sprint 3).
- **Volumenes nombrados**: `matricula_cloud_data` (datos), `matricula_cloud_backup` (respaldos); un montaje bind para el codigo SQL (`/sqlserver`).
- **Healthcheck**: el contenedor solo se considera sano cuando SQL Server responde a las consultas.
- **`init.sql` automatico e idempotente**: al primer arranque (`wait-for-sql.sh` espera que SQL este listo) ejecuta los 49 pasos que crean la BD, los objetos y los datos; se puede re-ejecutar las veces que se quiera sin errores.
- **Variables de entorno** en `.env` (password del SA, `MSSQL_PID=Developer`, codificacion). La contrasena se documenta para la sustentacion academica.

## 4. Respaldo y recuperacion

**Archivo:** `sqlserver/maintenance/` (Sprint 1: `backup_restore.sql`) y `docker/init/init.sql` paso 46

- Modelo de recuperacion **FULL** desde la creacion de la base (CHECKSUM habilitado).
- Respaldo FULL inicial y rutina documentada de restauracion (el Sprint 3 agrega la estrategia completa FULL + DIFERENCIAL + LOG con jobs de SQL Agent).
- Historial consultable en `msdb.dbo.backupset`.

## 5. Verificacion de instalacion

**Archivo:** `sqlserver/utils/verificar_instalacion.sql`

Script integral que valida el resultado del Sprint 1 (y se extiende en los sprints siguientes):
tablas (17), esquemas, restricciones (21 FK, 22 UK, 30 CK), datos semilla, objetos programables, roles, permisos y estado general de la base.

## 6. Resultados y cumplimiento

| Criterio | Estado |
|---|---|
| Modelo logico y fisico entregados | Cumple |
| 17 tablas con 6 esquemas | Cumple |
| 21 FK / 22 UK / 30 CK | Cumple |
| Infraestructura Docker reproducible | Cumple |
| Scripts idempotentes | Cumple |
| Respaldo FULL + recuperacion | Cumple |
| Verificador de instalacion | Cumple |