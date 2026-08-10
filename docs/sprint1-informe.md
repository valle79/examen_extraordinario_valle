# Informe Tecnico Sprint 1
## Matricula Cloud 360 Enterprise

**Base de datos:** `MatriculaCloud360DB`
**Motor:** SQL Server 2025 (Developer) v17.0 en Docker
**Contenedor:** `sqlserver_matricula_cloud`
**Fecha de generacion:** 2026-08-07

---

## 1. Resumen ejecutivo

Se implemento y verifico de forma **automatica e idempotente** la base de datos del sistema de gestion de matriculas en un contenedor de SQL Server 2025. Con una unica instruccion:

```
docker compose up -d
```

el contenedor arranca, el motor se inicializa y `wait-for-sql.sh` ejecuta `init.sql`, que crea la base de datos, sus objetos, restricciones e indices, y la puebla con datos iniciales de ejemplo (112 registros). La verificacion integral concluye con **INSTALACION PERFECTA**.

Este informe corresponde a la reconstruccion del proyecto desde cero: la version previa tenia 3 fallos criticos (no creaba la base automaticamente, healthcheck inutilizable y verificador con errores de sintaxis), que fueron corregidos y validados con pruebas reales en contenedor.

---

## 2. Alcance del Sprint 1

| Entregable | Ubicacion | Estado |
|---|---|---|
| Docker Compose con arranque automatico | `docker/docker-compose.yml` | Completo |
| DDL de base, esquemas, tablas, restricciones e indices | `sqlserver/ddl/` | Completo |
| Datos iniciales (tablas base y de negocio) | `sqlserver/dml/01_seed_data.sql` | Completo (112 registros) |
| Utilidades (verificacion, diccionario, respaldo) | `sqlserver/utils/` | Completo |
| Verificacion integral | `sqlserver/utils/verificar_instalacion.sql` | **APROBADO** |
| Catalogo de datos (Excel) | `datasets/CatalogoDatos.xlsx` | Completo |
| Diccionario de datos (PDF) | `datasets/DiccionarioDatos.pdf` | Completo |
| Modelo logico | `docs/modelo-logico.png` | Completo |
| Modelo fisico | `docs/modelo-fisico.png` | Completo |

---

## 2. Requisitos del entorno

- Docker Desktop (motor 25.0.3 o superior) con contenedores Linux.
- Puerto TCP **1433** libre en el host (configurable via `docker/.env`).
- Sin requisitos de licencia: la imagen `mcr.microsoft.com/mssql/server:2025-latest` (Developer Edition) es gratuita para uso de desarrollo.

### Credenciales por defecto (modificar en `docker/.env`)

| Variable | Valor |
|---|---|
| `SA_PASSWORD` | `MatriculaCloud360!` |
| `MSSQL_PID` | `Developer` |
| `MSSQL_COLLATION` | `Modern_Spanish_CI_AS` |
| `SQL_SERVER_PORT` | `1433` |

---

## 3. Como ejecutar (clon en frio)

```bash
# 1) Clonar / copiar la carpeta del proyecto
# 2) Entrar a la carpeta docker
cd docker

# 3) (opcional) ajustar credenciales
Copy-Item .env.example .env   # o editar docker/.env

# 4) Levantar TODO automaticamente
docker compose up -d

# 5) Confirmar
docker compose ps
docker compose logs sqlserver
```

En el log debe aparecer:

```
[init] OK: Inicializacion completada correctamente.
```

La base de datos se crea **solo en el primer arranque**; en arranques posteriores los scripts son idempotentes y **no se borra nada** (validado).

---

## 4. Arquitectura de despliegue

El contenedor sustituye el entrypoint oficial por `docker/init/wait-for-sql.sh` (la imagen de SQL Server NO ejecuta scripts `/docker-entrypoint-initdb.d` como MySQL/Postgres):

```
docker compose up -d
    -> entrypoint: wait-for-sql.sh
       1. inicia sqlservr en segundo plano
       2. espera a que el motor este listo
          (master/model/msdb ONLINE; Msg 904/18456 en arranque)
       3. ejecuta init.sql (orquestador DDL + DML)
       4. mantiene el proceso vivo (wait $SQL_PID)
    -> healthcheck sqlcmd -Q "SELECT 1" (cada 10 s)
```

Detalles de la imagen 2025 resueltos:

| Dato | Solucion aplicada |
|---|---|
| Herramientas en `/opt/mssql-tools18` (no `/opt/mssql-tools`) | `SQLCMD` apuntando a la ruta correcta |
| Certificado autofirmado obligado 2022+ | flag `-C` en sqlcmd |
| Indices filtrados requieren QUOTED_IDENTIFIER ON | flag `-I` en sqlcmd |
| Bind-mounts a carpetas de Windows fallan (OS error 31) | **volumenes nombrados** `matricula_cloud_data/_log/_backup` |
| `command:` multilinea de compose en versiones viejas se parsea mal | toda la logica en `wait-for-sql.sh`, entrypoint explicito |

### Copia de respaldo

Los respaldos quedan en `matricula_cloud_backup`. Para copiar un `.bak` al host:

```bash
docker cp sqlserver_matricula_cloud:/var/opt/mssql/backup/archivo.bak ./docker/volumes/backup/
```

Consulta/referencia: `sqlserver/utils/backup_restore.sql`.

---

## 5. Modelo de datos

### 5.1 Esquemas logicos

| Esquema | Dominio | Tablas |
|---|---|---|
| `core` | Nucleo de matricula | Sedes, Carreras, Estudiantes, PeriodosAcademicos, Matriculas |
| `academic` | Academico | Profesores, Cursos, CarreraCursos, CursoProfesor |
| `sales` | Ventas y comisiones | Promotores, CampaniasAdmision, Comisiones |
| `security` | Acceso | Roles, Usuarios |
| `audit` | Auditoria | AuditLog |

### 5.2 Numeros del modelo (verificados en vivo)

| Metrica | Cantidad |
|---|---|
| Tablas | 15 |
| Llaves primarias | 15 |
| Llaves foraneas | 18 |
| Restricciones UNIQUE | 20 |
| Restricciones CHECK | 26 |
| Indices no agrupados de optimizacion | 14 (2 filtrados) |
| Registros iniciales | 112 |

### 5.3 Reglas de negocio implementadas y probadas

Probadas ejecutando SQL destructivo en el contenedor y confirmando el rechazo:

| Regla | Comportamiento validado |
|---|---|
| Matricula duplicada (estudiante/carrera/periodo) | Rechazada (2627, UK_Matriculas_Unica) |
| Estudiante DNI duplicado | Rechazada (2627) |
| Email repetido en sedes/promotores/estudiantes | Rechazada (2627) |
| Promotor inexistente en una matricula | Rechazada por FK (547) |
| Borrado logico (soft delete) | `DeletedAt` se aplica; la fila se restaura sin recrear |

### 5.4 Diagramas

- Modelo logico: `docs/modelo-logico.png`
- Modelo fisico: `docs/modelo-fisico.png`

(fuentes SVG/HTML: `docs/modelo-logico.html`, `docs/modelo-fisico.html`, regenerables con `tools/generate_diagrams.py`)

---

## 6. Verificacion de la instalacion

El script `sqlserver/utils/verificar_instalacion.sql` valida 11 areas. Salida resumida en el contenedor:

```
>>> INSTALACION PERFECTA <<<
   [OK] Collation: Modern_Spanish_CI_AS
   [OK] Recovery Model: FULL
   [OK] 6 esquemas, 15 tablas
   [OK] FK: 18/18  |  UNIQUE: 20/20  |  CHECK: 26/26  |  Indices NC: 14/14
   [OK] 112 registros en 14 tablas
   [OK] Sin huerfanos; sin duplicados; version 1.0.0
```

Cómo ejecutarlo manualmente:

```bash
docker exec sqlserver_matricula_cloud /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "SuPassword" -C -b -I \
  -i /sqlserver/utils/verificar_instalacion.sql
```

---

## 7. Dataset y diccionario

- `datasets/CatalogoDatos.xlsx`: 7 hojas (Tablas, Columnas, Relaciones, Unicas, Checks, Indices, Estadisticas) extraidas de los metadatos reales.
- `datasets/DiccionarioDatos.pdf`: diccionario de datos impreso.
- Regenerables: `tools/generate_deliverables.py`.

---

## 8. Estructura de entregables (nueva carpeta)

```
MatriculaCloud360Enterprise/
|-- docker/
|   |-- docker-compose.yml
|   |-- .env / .env.example
|   |-- init/          # wait-for-sql.sh, init.sql
|   |-- volumes/       # (documenta broker/backup del host)
|-- sqlserver/
|   |-- ddl/            # 01_database.sql, 02_schemas.sql, 03_tablas.sql
|   |-- dml/            # 01_seed_data.sql
|   |-- utils/          # verificar, diccionario, backup
|-- datasets/          # CatalogoDatos.xlsx, DiccionarioDatos.pdf, README
|-- docs/              # informe, diagramas (png + html)
|-- tools/             # generadores (python)
|-- README.md
```

El restante del proyecto original (**raiz `C:\Users\luisv\examenextraordinariobd\`**) se mantiene intacto; solo esta carpeta constituye la entrega del Sprint 1.

---

## 9. Evidencias de la reconstruccion

1. `docker compose up -d` desde volumenes frescos -> `[init] OK: Inicializacion completada correctamente`.
2. `verificar_instalacion.sql` -> **INSTALACION PERFECTA / APROBADO** (sin observaciones).
3. Reinicio del contenedor -> la base NO se recrea, los datos persisten (10 estudiantes, 10 matriculas, 10 comisiones).
4. Pruebas de reglas de negocio online (ver 5.3).

---

## 10. Notas tecnicas / aprendizaje

- Los volumenes nombrados son obligatorios para SQL Server sobre Docker Desktop en Windows (los bind mounts a rutas NTFS provocan error de dispositivo sobre tempdb/creacion de archivos).
- sqlcmd delimita `QUOTED_IDENTIFIER` en `OFF` por defecto: los DDL con indices filtrados exigen `-I`.
- La collation `Modern_Spanish_CI_AS` debe declararse en el `CREATE DATABASE` **despues** de los file-groups (`COLLATE` va al final de la sentencia en T-SQL).