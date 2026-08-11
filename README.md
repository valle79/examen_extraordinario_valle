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
- **Inicialización automática de la base de datos** (init.sql → 34 pasos)

## 📁 Estructura del Proyecto

```
MatriculaCloud360Enterprise/
│
├── docker/                          # Configuración de contenedores
│   ├── docker-compose.yml          # Orquestación de servicios
│   ├── .env                        # Variables de entorno (no versionado)
│   ├── .env.example                # Plantilla de variables
│   ├── init/                       # Scripts de inicialización
│   │   ├── init.sql               # Script maestro (34 pasos, Sprint 1 + 2)
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
│   │   ├── views/                 # 7 vistas de reporte (vw_*.sql)
│   │   └── procedures/            # 9 procedimientos almacenados (usp_*.sql)
│   └── utils/                      # Utilidades
│       ├── verificar_instalacion.sql  # Auditoría completa de instalación
│       ├── backup_restore.sql         # Plantilla de respaldo/restauración
│       └── generate_diccionario.sql   # Genera el diccionario de datos
│
├── datasets/                        # Modelos y diccionarios del Sprint 1
│   ├── modelo_logico_EABD-2026-08-10_15-14.png   # Modelo lógico
│   ├── modelo_fisico_EABD-2026-08-10_15-14.png   # Modelo físico
│   ├── catalogo_datos_logico.docx               # Catálogo de datos
│   └── diccionario_datos_fisico.docx            # Diccionario de datos
│
├── docs/                           # Informes técnicos
│   ├── sprint1-informe.md         # Informe técnico del Sprint 1
│   └── sprint2-informe.md         # Informe técnico del Sprint 2
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
   El contenedor queda `healthy` en ~30-60 segundos tras ejecutar los 34 pasos de inicialización (base, esquemas, tablas, constraints, funciones, triggers, vistas, procedimientos, seed, datos de prueba y casos de prueba).

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

El sistema implementa perfiles de seguridad (RN-06):

1. **Administrador**: Acceso completo al sistema
2. **Coordinador Académico**: Gestión académica y reportes
3. **Promotor**: Registro de estudiantes y consulta de comisiones

Las contraseñas se almacenan con hash SHA2-256 y todas las operaciones críticas quedan registradas en `audit.AuditLog` (RN-07) con usuario, fecha, operación, valores y dirección IP.

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
- ✅ 9 procedimientos almacenados con transacciones y TRY…CATCH (RN-04)
- ✅ Reglas de negocio RN-01 a RN-10 implementadas y probadas
- ✅ 18 casos de prueba automáticos (18/18 superados)
- ✅ Datos de prueba registrados mediante los procedimientos del sistema

### Próximos Sprints

- 🔄 Sprint 3: Optimización, seguridad y administración

## 🛠️ Tecnologías

- SQL Server 2025 Developer Edition (Preview)
- Docker & Docker Compose (imagen oficial MCR)
- Transact-SQL (T-SQL)
- Git para control de versiones

## 👥 Equipo

- **Ingeniero de Base de Datos**: [Tu Nombre]
- **Cliente**: Instituto Superior EduFuturo

## 📄 Licencia

Este proyecto es de uso educativo para el Instituto Superior EduFuturo.

## 📞 Soporte

Para consultas o problemas:
- Email: [tu-email]
- Repositorio: [url-del-repositorio]

---

**Desarrollado como parte del proyecto de Transformación Digital del Instituto Superior EduFuturo**

## Notas

- La base de datos es **idempotente**: al reiniciar el contenedor no se borra nada; todos los scripts pueden reejecutarse sin errores.
- Los datos persisten en volúmenes nombrados de Docker (`matricula_cloud_data/_log/_backup`).
- Credenciales por defecto: `sa` / `MatriculaCloud360!` (cambiar en `docker/.env`).
- Para una instalación desde cero: `docker compose down -v && docker compose up -d` (el volcado de datos se pierde, todo se recrea automáticamente).
