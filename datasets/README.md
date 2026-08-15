# Datasets — Matrícula Cloud 360 Enterprise

## 📂 Contenido

| Archivo | Descripción |
|---|---|
| `MODELO_LOGICO_V2.png` | Diagrama del **modelo lógico** (entidades, atributos y relaciones) |
| `MODELO_FISICO_V2.png` | Diagrama del **modelo físico** (esquemas, PK/FK, tipos de datos) |
| `catalogo_datos.xlsx` | **Catálogo de datos** proporcionado por el cliente (sedes, carreras, cursos, docentes, promotores, estudiantes, matrículas, malla) |
| `diccionario_datos.pdf` | **Diccionario de datos** del modelo físico: 17 tablas, columnas, tipos SQL, claves, restricciones y descripciones |

## 🗄️ Contenido técnico de los modelos

- **Esquemas**: `core`, `academic`, `sales`, `security`, `audit`, `utils`
- **Tablas (17)**: Sedes, Carreras, Estudiantes, Períodos Académicos, Matrículas, Ubigeos, Profesores, Cursos, CarreraCursos (malla), CursoProfesor, Especialidades, Promotores, Campañas de Admisión, Comisiones, Roles, Usuarios, AuditLog
- **Restricciones**: 21 Foreign Keys, 22 Unique Constraints, 30 Check Constraints, 17 índices no agrupados de optimización (14 Sprint 1 + 3 Sprint 3)
- **Reglas de negocio**: RN-01 a RN-10 (documentos únicos, matrícula única, periodo habilitado, transacciones, malla curricular, perfiles, auditoría, promotor obligatorio, comisión automática, borrado lógico)

## 🛠️ ¿Cómo se generó el diccionario físico?

El diccionario físico se genera con el script:

```
sqlserver/utils/generate_diccionario.sql
```

que consulta el catálogo del sistema (`sys.tables`, `sys.columns`, `sys.foreign_keys`, `sys.check_constraints`, etc.) de `MatriculaCloud360DB`, y luego se exporta a PDF (Redgate Data Modeler).

## 🔄 Mantenimiento

Si el modelo de datos cambia (nueva tabla, columna o restricción):

1. Actualizar `sqlserver/ddl/03_tables.sql`.
2. Recrear el contenedor (`docker compose down -v && docker compose up -d` en `docker/`).
3. Regenerar el diccionario con `generate_diccionario.sql` y exportar el PDF.
4. Actualizar los diagramas desde SQL Server Management Studio (Diagramas de base de datos).