# Matrícula Cloud 360 Enterprise

## 📋 Descripción del Proyecto

Sistema de gestión integral de matrícula para el Instituto Superior EduFuturo. Esta solución empresarial garantiza integridad, rendimiento, seguridad, disponibilidad y escalabilidad mediante SQL Server 2025 Developer en contenedores Docker.

## 🎯 Objetivos

- ✅ Integridad de los datos
- ✅ Rendimiento de las consultas
- ✅ Seguridad de acceso
- ✅ Disponibilidad de la información
- ✅ Automatización de la instalación
- ✅ Respaldo y recuperación
- ✅ Documentación técnica
- ✅ Generación de información para la toma de decisiones

## 🏗️ Arquitectura

La solución está construida sobre:
- **SQL Server 2025 Developer Edition (Preview)**
- **Docker & Docker Compose**
- **Persistencia de datos mediante volúmenes nombrados**
- **Inicialización automática de la base de datos** (init.sql → 49 pasos, Sprint 1 + 2 + 3)

## 📁 Estructura del Proyecto

```
MatriculaCloud360Enterprise/
│
├── docker/                          # Configuración de contenedores
│   ├── docker-compose.yml          # Orquestación de servicios
│   ├── .env                        # Variables de entorno
│   ├── .env.example                # Plantilla de variables
│   ├── init/                       # Scripts de inicialización
│   │   ├── init.sql               # Script maestro (49 pasos, Sprint 1 + 2 + 3)
│   │   └── wait-for-sql.sh        # Entrypoint: espera el servidor y ejecuta init
│   └── volumes/                    # Persistencia local (solo .gitkeep versionados)
│       ├── data/                   # Datos (los datos reales viven en volúmenes nombrados)
│       ├── log/                    # Logs de SQL Server
│       └── backup/                 # Respaldos .bak extraídos al host
│
├── sqlserver/                       # Scripts SQL organizados
│   ├── ddl/                        # Data Definition Language
│   │   ├── 01_database.sql        # Creación de la base de datos
│   │   ├── 02_schemas.sql         # Creación de esquemas
│   │   ├── 03_tables.sql          # Tablas e índices
│   │   └── 04_constraints.sql     # Restricciones PK, FK, UK, CK
│   ├── dml/                        # Data Manipulation Language
│   │   ├── 01_seed_data.sql       # Datos iniciales (seed)
│   │   ├── 02_test_data.sql       # Datos de prueba (Sprint 2)
│   │   └── 03_test_cases.sql      # 18 casos de prueba de reglas de negocio
│   ├── programmability/            # Objetos programables (Sprint 2)
│   │   ├── functions/             # 6 funciones de negocio (fn_*.sql)
│   │   ├── triggers/              # 5 triggers de auditoría y comisiones (trg_*.sql)
│   │   ├── views/                 # 10 vistas de reporte y analíticas (vw_*.sql)
│   │   └── procedures/            # 10 procedimientos almacenados (usp_*.sql)
│   ├── audit/                      # Auditoría y borrado lógico (Sprint 3)
│   │   ├── 01_audit_tables.sql    # Tabla de auditoría + índices + vista de traza
│   │   ├── 02_audit_triggers.sql  # 7 triggers AFTER de auditoría (entidades críticas)
│   │   └── 03_soft_delete.sql     # 7 triggers INSTEAD OF DELETE (borrado lógico DeletedAt)
│   ├── optimization/               # Optimización (Sprint 3)
│   │   ├── 01_indexes.sql         # 3 índices compuestos/filtrados/covering
│   │   ├── 02_advanced_queries.sql# 10 consultas avanzadas (CTE, ventanas, ROLLUP)
│   │   └── 03_performance_tests.sql# Pruebas antes/después + 1,000,000 filas + planes de ejecución
│   ├── security/                   # Seguridad (Sprint 2 + 3)
│   │   ├── 01_usuarios_permisos.sql # Orquestador de los 3 scripts siguientes
│   │   ├── 01_logins_users.sql    # Logins y usuarios (MC_Admin, MC_Coordinador, MC_Promotor)
│   │   ├── 02_roles.sql           # Roles de base de datos (3 roles + membresías)
│   │   └── 03_permissions.sql     # Matriz GRANT/DENY/REVOKE por rol
│   ├── maintenance/                # Respaldo y automatización (Sprint 3)
│   │   ├── 01_backup.sql          # Respaldo FULL + historial en msdb
│   │   ├── 02_restore.sql         # Guía de restauración y point-in-time
│   │   └── 03_maintenance.sql     # 5 jobs de SQL Agent (backup, índices, integridad)
│   ├── testing/                    # Pruebas integradas (Sprint 3)
│   │   ├── functional_tests.sql   # F01-F08: auditoría, soft delete, consultas, índices
│   │   ├── security_tests.sql     # S01-S10: matriz de permisos con EXECUTE AS
│   │   └── recovery_tests.sql     # Respaldo → pérdida → restauración → verificación
│   └── utils/                      # Utilidades
│       ├── verificar_instalacion.sql  # Auditoría completa de instalación
│       ├── demo_profesor_sprint3.sql  # Demo de preguntas probables del profesor (Sprint 3)
│       ├── backup_restore.sql         # Plantilla de respaldo/restauración
│       └── generate_diccionario.sql   # Genera el diccionario de datos
│
├── dashboard/                      # Consultas analíticas e indicadores (Sprint 3)
│   ├── generar_indicadores.sql   # Genera dashboard/indicadores.html (matrículas, carreras, sedes, campañas, promotores)
│   └── indicadores.html          # Dashboard generado (autocontenido)
├── datasets/                        # Modelos y diccionarios del Sprint 1
│   ├── MODELO_LOGICO_V2.png        # Modelo lógico
│   ├── MODELO_FISICO_V2.png        # Modelo físico
│   ├── catalogo_datos.xlsx         # Catálogo de datos (información inicial del cliente)
│   └── diccionario_datos.pdf       # Diccionario de datos (17 tablas)
│
├── docs/                           # Informes técnicos
│   ├── sprint1-informe.md         # Informe técnico del Sprint 1
│   ├── sprint2-informe.md         # Informe técnico del Sprint 2
│   └── sprint3-informe.md         # Informe técnico del Sprint 3
│
├── .gitignore                      # Archivos ignorados por Git
└── README.md                       # Este archivo
```

## 🚀 Instalación y Uso

### Prerrequisitos

- Docker Desktop instalado y en ejecución
- Docker Compose v2.0 o superior
- Mínimo 4GB de RAM disponible para el contenedor
- Puerto `1434` disponible en el equipo (el `1433` suele estar ocupado por un SQL Server local; configurable en `.env`)

### Instalación Rápida

1. **Clonar el repositorio:**
   ```bash
   git clone <url-del-repositorio>
   cd MatriculaCloud360Enterprise
   ```

2. **Configurar variables de entorno:**
   ```bash
   cd docker
   cp .env.example .env
   # Editar .env con tus credenciales
   ```

3. **Levantar la infraestructura:**
   ```bash
   docker compose up -d
   ```
   El contenedor queda `healthy` en ~30-60 segundos tras ejecutar los 49 pasos de inicialización (base, esquemas, tablas, constraints, funciones, triggers, vistas, procedimientos, perfiles de seguridad, seed, datos de prueba, casos de prueba, auditoría, borrado lógico, índices, consultas avanzadas, respaldo inicial y jobs de SQL Agent).

4. **Verificar el estado:**
   ```bash
   docker compose ps
   docker compose logs -f sqlserver
   ```

5. **Conectarse a la base de datos:**
   - **Host:** localhost
   - **Puerto:** 1434 (o el definido en `.env` como `SQL_SERVER_PORT`)
   - **Usuario:** SA
   - **Password:** MatriculaCloud360! (definida en `.env`)
   - **Base de datos:** MatriculaCloud360DB

### Comandos Útiles

```bash
# Detener los servicios
docker compose down

# Detener y eliminar volúmenes (resetear todo, se vuelve a crear todo)
docker compose down -v

# Ver logs en tiempo real
docker compose logs -f sqlserver

# Ejecutar la verificación completa de la instalación
docker exec sqlserver_matricula_cloud /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "MatriculaCloud360!" -C -i /sqlserver/utils/verificar_instalacion.sql

# Ejecutar consultas desde la línea de comandos
docker exec sqlserver_matricula_cloud /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "MatriculaCloud360!" -C -d MatriculaCloud360DB -Q "SELECT * FROM core.Estudiantes"

# Demo para la sustentación (preguntas probables del profesor, Sprint 3)
docker exec sqlserver_matricula_cloud /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "MatriculaCloud360!" -C -i /sqlserver/utils/demo_profesor_sprint3.sql

# Generar el dashboard de indicadores (dashboard/indicadores.html)
docker exec sqlserver_matricula_cloud /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "MatriculaCloud360!" -C -i /dashboard/generar_indicadores.sql
```

## 🗄️ Modelo de Datos

### Esquemas Principales

- **`core`**: Entidades principales del negocio (Estudiantes, Carreras, Períodos, Matrículas, Sedes, Ubigeos)
- **`academic`**: Gestión académica (Profesores, Cursos, Especialidades, Malla curricular)
- **`sales`**: Gestión comercial (Promotores, Comisiones, Campañas de Admisión)
- **`security`**: Seguridad y usuarios (Roles, Usuarios)
- **`audit`**: Auditoría de operaciones (AuditLog)
- **`utils`**: Utilidades (control de versiones)

### Entidades Principales (17 tablas)

Estudiantes, Carreras, Cursos, Sedes, Promotores, Matrículas, Períodos Académicos, Profesores, Especialidades, Campañas de Admisión, Comisiones, Ubigeos, Usuarios, Roles, Malla Curricular, Asignaciones Curso-Profesor y Auditoría.

## 🔒 Seguridad

El sistema implementa perfiles de seguridad (RN-06) con **permisos reales de SQL Server** (logins, usuarios y `GRANT`/`DENY`) aplicados automáticamente por `sqlserver/security/01_usuarios_permisos.sql`:

| Perfil | Login SQL | Credencial (dev) | Permisos |
|---|---|---|---|
| **Administrador** | `MC_Admin` | `MCAdmin#2026` | Acceso completo (`db_owner`) |
| **Coordinador Académico** | `MC_Coordinador` | `MCCoord#2026` | Reportes académicos, registra/retira matrículas, actualiza estudiantes. Sin acceso a comisiones, seguridad ni auditoría |
| **Promotor** | `MC_Promotor` | `MCPromo#2026` | Registro de estudiantes (vía SP) y consulta de sus comisiones. Sin matrículas, seguridad ni auditoría |

Principio de **menor privilegio**: el acceso a los datos se otorga solo a través de vistas y procedimientos (encadenamiento de propiedad), con `DENY` explícito sobre las áreas sensibles (matrículas, comisiones, seguridad y auditoría). El `verificador de instalación` ejecuta pruebas de cumplimiento que comprueban las denegaciones y permisos en vivo.

Las contraseñas de la tabla `security.Usuarios` (usuarios de aplicación) se almacenan con hash SHA2-256 y todas las operaciones críticas quedan registradas en `audit.AuditLog` (RN-07) con usuario, fecha, operación, valores y dirección IP.

## 📊 Características Implementadas

### Sprint 1 (Completado)

- ✅ Modelo lógico y físico de la base de datos (17 tablas, 21 FK, 22 UK, 30 CK)
- ✅ Diccionario de datos y catálogo de datos
- ✅ Infraestructura Docker automatizada (volúmenes nombrados, healthcheck)
- ✅ Scripts de inicialización automática e idempotentes
- ✅ Respaldo y recuperación (recovery model FULL + backup_restore.sql)
- ✅ Verificación de instalación automatizada

### Sprint 2 (Completado)

- ✅ 6 funciones de negocio (periodo habilitado, documento único, edad, demanda, comisión y bono)
- ✅ 7 vistas de reporte (estudiantes, matrículas, comisiones, desempeño de promotores, malla, profesores, reporte por periodo)
- ✅ 5 triggers (4 de auditoría RN-07 + 1 de comisión automática RN-09)
- ✅ 10 procedimientos almacenados con transacciones y TRY…CATCH (RN-04)
- ✅ Reglas de negocio RN-01 a RN-10 implementadas y probadas
- ✅ 18 casos de prueba automáticos (18/18 superados)
- ✅ Datos de prueba registrados mediante los procedimientos del sistema
- ✅ Seguridad RN-06: perfiles SQL (`MC_Admin`, `MC_Coordinador`, `MC_Promotor`) con permisos `GRANT`/`DENY` verificados

### Sprint 3 (Completado)

- ✅ Auditoría integral de entidades críticas (11 triggers: 4 Sprint 2 + 7 nuevos) en `audit.AuditLog` con índices y vista de traza
- ✅ Borrado lógico `deleted_at` en 7 tablas críticas mediante triggers `INSTEAD OF DELETE` (la información nunca se elimina físicamente)
- ✅ 10 consultas avanzadas (CTE, CTE recursiva, ROW_NUMBER/RANK/DENSE_RANK, LAG, SUM OVER, ROLLUP) + 3 vistas analíticas
- ✅ 3 índices nuevos compuestos/filtrados/covering sobre las consultas críticas (17 índices no agrupados en total)
- ✅ Pruebas comparativas de rendimiento antes/después (DISABLE/REBUILD), con captura de planes de ejecución (SHOWPLAN_XML) y tabla de 1,000,000 filas (scan vs seek)
- ✅ Seguridad por roles (`rol_Administrador`, `rol_Coordinador_Academico`, `rol_Promotor`) con matriz GRANT/DENY/REVOKE verificada (S01–S10)
- ✅ Estrategia de respaldo FULL + DIFERENCIAL + LOG automatizada con 5 jobs de SQL Agent
- ✅ Prueba completa de recuperación (respaldo → pérdida simulada → restauración → DBCC CHECKDB → MULTI_USER)
- ✅ Dashboard de indicadores institucionales (matrículas, carreras, sedes, campañas, promotores) → `dashboard/indicadores.html`
- ✅ Pruebas funcionales F01–F08, de seguridad S01–S10 y de recuperación; verificación integral actualizada
- ✅ Informe técnico `docs/sprint3-informe.md`

## 🛠️ Tecnologías

- SQL Server 2025 Developer Edition (Preview)
- Docker & Docker Compose (imagen oficial MCR)
- Transact-SQL (T-SQL)
- Git para control de versiones

## 👥 Equipo

- **Ingeniero de Base de Datos**: Luis Alberto Valle Coronado
- **Cliente**: Instituto Superior EduFuturo

## 📄 Licencia

Este proyecto es de uso educativo para el Instituto Superior EduFuturo.

## 📞 Soporte

Para consultas o problemas:
- Email: luis.valle@vallegrande.edu.pe
- Repositorio: https://github.com/valle79/

---

**Desarrollado como parte del proyecto de Transformación Digital del Instituto Superior EduFuturo**

## Notas

- La base de datos es **idempotente**: al reiniciar el contenedor no se borra nada; todos los scripts pueden reejecutarse sin errores.
- Los datos persisten en volúmenes nombrados de Docker (`matricula_cloud_data/_log/_backup`).
- Credenciales por defecto: `sa` / `MatriculaCloud360!` (cambiar en `docker/.env`).
- Para una instalación desde cero: `docker compose down -v && docker compose up -d` (el volcado de datos se pierde, todo se recrea automáticamente).