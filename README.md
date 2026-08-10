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
- **Persistencia de datos mediante volúmenes**
- **Inicialización automática de la base de datos**

## 📁 Estructura del Proyecto

```
MatriculaCloud360Enterprise/
│
├── docker/                          # Configuración de contenedores
│   ├── docker-compose.yml          # Orquestación de servicios
│   ├── .env                        # Variables de entorno (no versionado)
│   ├── README.md                   # Documentación de Docker
│   ├── init/                       # Scripts de inicialización
│   │   ├── init.sql               # Script maestro de inicialización
│   │   └── wait-for-sql.sh        # Script de espera del servidor
│   └── volumes/                    # Volúmenes persistentes
│
├── sqlserver/                       # Scripts SQL organizados
│   ├── ddl/                        # Data Definition Language
│   │   ├── 01_database.sql        # Creación de la base de datos
│   │   ├── 02_schemas.sql         # Creación de esquemas
│   │   └── 03_tables.sql          # Creación de tablas
│   ├── dml/                        # Data Manipulation Language
│   │   └── 01_seed_data.sql       # Datos iniciales (seed)
│
├── datasets/                        # Catálogos y datos proporcionados
│   ├── CatalogoDatos.xlsx         # Catálogo original del cliente
│   ├── DiccionarioDatos.pdf       # Diccionario de datos generado
│   └── README.md                  # Documentación de datasets
│
├── docs/                           # Documentación adicional
│   ├── modelo-logico.png          # Diagrama del modelo lógico
│   ├── modelo-fisico.png          # Diagrama del modelo físico
│   └── sprint1-informe.md         # Informe técnico del Sprint 1
│
├── .gitignore                      # Archivos ignorados por Git
└── README.md                       # Este archivo
```

## 🚀 Instalación y Uso

### Prerrequisitos

- Docker Desktop instalado y en ejecución
- Docker Compose v2.0 o superior
- Mínimo 4GB de RAM disponible para el contenedor
- Puerto 1433 disponible

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

4. **Verificar el estado:**
   ```bash
   docker compose ps
   docker compose logs -f sqlserver
   ```

5. **Conectarse a la base de datos:**
   - **Host:** localhost
   - **Puerto:** 1433
   - **Usuario:** SA
   - **Password:** (definida en .env)
   - **Base de datos:** MatriculaCloud360DB

### Comandos Útiles

```bash
# Detener los servicios
docker compose down

# Detener y eliminar volúmenes (resetear todo)
docker compose down -v

# Ver logs en tiempo real
docker compose logs -f sqlserver

# Acceder al contenedor SQL Server
docker compose exec sqlserver /bin/bash

# Ejecutar consultas desde la línea de comandos
docker compose exec sqlserver /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P 'TuPassword' -d MatriculaCloud360DB -Q "SELECT * FROM core.Estudiantes"
```

## 🗄️ Modelo de Datos

### Esquemas Principales

- **`core`**: Entidades principales del negocio (Estudiantes, Carreras, Cursos, Matrículas)
- **`academic`**: Gestión académica (Profesores, Horarios, Evaluaciones)
- **`sales`**: Gestión de ventas (Promotores, Comisiones, Campañas)
- **`security`**: Seguridad y usuarios (Usuarios, Roles, Permisos)
- **`audit`**: Auditoría de operaciones (Logs de cambios)

### Entidades Principales

- Estudiantes
- Carreras
- Cursos
- Sedes
- Promotores
- Matrículas
- Períodos Académicos
- Profesores
- Campañas de Admisión
- Usuarios del Sistema

## 🔒 Seguridad

El sistema implementa tres perfiles de seguridad:

1. **Administrador**: Acceso completo al sistema
2. **Coordinador Académico**: Gestión académica y reportes
3. **Promotor**: Registro de estudiantes y consulta de comisiones

## 📊 Características Implementadas

### Sprint 1 (Completado)

- ✅ Modelo lógico y físico de la base de datos
- ✅ Diccionario de datos completo
- ✅ Infraestructura Docker automatizada
- ✅ Scripts de inicialización automática
- ✅ Persistencia de datos
- ✅ Documentación técnica

### Próximos Sprints

- 🔄 Sprint 2: Programación de objetos de base de datos (procedimientos, funciones, triggers)
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

- La base de datos es **idempotente**: al reiniciar el contenedor no se borra nada.
- Los datos persisten en volumenes nombrados de Docker (`matricula_cloud_data/_log/_backup`).
- Credenciales por defecto: `sa` / `MatriculaCloud360!` (cambiar en `docker/.env`).
