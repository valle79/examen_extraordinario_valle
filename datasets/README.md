# Datasets — Matrícula Cloud 360 Enterprise

## 📂 Contenido

| Archivo | Descripción |
|---|---|
| `modelo_logico_EABD-2026-08-10_15-14.png` | Diagrama del **modelo lógico** (entidades, atributos y relaciones) |
| `modelo_fisico_EABD-2026-08-10_15-14.png` | Diagrama del **modelo físico** (esquemas, PK/FK, tipos de datos) |
| `catalogo_datos_logico.docx` | **Catálogo de datos** del modelo lógico: entidades, atributos, tipo de dato, descripción, clave y obligatoriedad |
| `diccionario_datos_fisico.docx` | **Diccionario de datos** del modelo físico: tablas, columnas, tipo SQL, nulos, restricciones y comentarios |

## 🗄️ Contenido técnico de los modelos

- **Esquemas**: `core`, `academic`, `sales`, `security`, `audit`, `utils`
- **Tablas (17)**: Sedes, Carreras, Estudiantes, Períodos Académicos, Matrículas, Ubigeos, Profesores, Cursos, CarreraCursos (malla), CursoProfesor, Especialidades, Promotores, Campañas de Admisión, Comisiones, Roles, Usuarios, AuditLog
- **Restricciones**: 21 Foreign Keys, 22 Unique Constraints, 30 Check Constraints, 14 índices de optimización
- **Reglas de negocio**: RN-01 a RN-10 (documentos únicos, matrícula única, periodo habilitado, transacciones, malla curricular, perfiles, auditoría, promotor obligatorio, comisión automática, borrado lógico)

## 🛠️ ¿Cómo se generó el diccionario físico?

El diccionario físico se genera con el script:

```
sqlserver/utils/generate_diccionario.sql
```

que consulta el catálogo del sistema (`sys.tables`, `sys.columns`, `sys.foreign_keys`, `sys.check_constraints`, etc.) de `MatriculaCloud360DB`.

## 🔄 Mantenimiento

Si el modelo de datos cambia (nueva tabla, columna o restricción):

1. Actualizar `sqlserver/ddl/03_tables.sql`.
2. Recrear el contenedor (`docker compose down -v && docker compose up -d` en `docker/`).
3. Regenerar el diccionario con `generate_diccionario.sql` y exportar el `.docx`.
4. Actualizar los diagramas desde SQL Server Management Studio (Diagramas de base de datos).
