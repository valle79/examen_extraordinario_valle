# Informe Técnico — Sprint 2 (Programación de Objetos de Base de Datos)

**Proyecto**: Matrícula Cloud 360 Enterprise
**Cliente**: Instituto Superior EduFuturo
**Fecha**: 10 de agosto de 2026
**Estado**: COMPLETADO

---

## 1. Objetivo del Sprint

Programar los objetos de base de datos (funciones, vistas, triggers y procedimientos almacenados) que automatizan el proceso de matrícula, implementan las reglas de negocio del cliente y generan información para la toma de decisiones, todo dentro de una arquitectura transaccional y auditable.

## 2. Reglas de Negocio Implementadas (RN-01 a RN-10)

| Regla | Descripción | Implementación |
|---|---|---|
| RN-01 | DNI/CE y correo de estudiantes únicos | `usp_RegistrarEstudiante`, `usp_ActualizarEstudiante` + UK |
| RN-02 | Sin matrículas duplicadas (estudiante + carrera + período) | `usp_RegistrarMatricula` + UK |
| RN-03 | La matrícula exige datos previos y período con ventana abierta | `fn_PeriodoMatriculaHabilitado` |
| RN-04 | Matrícula transaccional (se revierte todo ante error) | `BEGIN/COMMIT/ROLLBACK` + `TRY...CATCH` |
| RN-05 | Malla curricular N:M carreras-cursos | Tabla `CarreraCursos` + `vw_MallaCurricular` |
| RN-06 | Perfiles de seguridad (Administrador, Coordinador, Promotor) | `security.Roles` + logins SQL `MC_Admin`/`MC_Coordinador`/`MC_Promotor` con permisos `GRANT`/`DENY` |
| RN-07 | Auditoría de operaciones críticas | 4 triggers → `audit.AuditLog` (usuario, fecha, valores, IP) |
| RN-08 | Promotor y sede obligatorios en la matrícula | FKs NOT NULL + validación en SP |
| RN-09 | Comisión automática por campaña + bono por meta; anulación al retirar | `TRG_Comision_Automatica` + funciones |
| RN-10 | Borrado lógico con `DeletedAt` | `usp_EliminarEstudianteLogico`, `usp_EliminarMatriculaLogico` |

## 3. Objetos Creados (27)

### 3.1 Funciones (6) — `programmability/functions/*`

| Función | Propósito |
|---|---|
| `core.fn_PeriodoMatriculaHabilitado` | ¿El período está activo y en ventana de matrícula? (RN-03) |
| `core.fn_ExisteEstudianteConDocumento` | ¿Existe estudiante con ese documento? (RN-01) |
| `core.fn_EdadEstudiante` | Edad exacta del estudiante |
| `core.fn_TotalMatriculadosCarrera` | Demanda de una carrera en un período |
| `sales.fn_CalcularComision` | Monto × % base de la campaña (RN-09) |
| `sales.fn_CalcularBonoPromotor` | Bono si alcanza la meta de la campaña (RN-09) |

### 3.2 Vistas (7) — `programmability/views/*`

| Vista | Propósito |
|---|---|
| `core.vw_EstudiantesDetalle` | Estudiantes con edad, ubigeo y sede |
| `core.vw_MatriculasDetalle` | Matrículas con todos los datos del negocio |
| `sales.vw_ComisionesDetalle` | Comisiones con promotor, campaña y estado |
| `sales.vw_DesempenoPromotores` | Desempeño: total matriculado, meta y bono |
| `academic.vw_MallaCurricular` | Malla por carrera con cursos y semestres |
| `academic.vw_ProfesoresDetalle` | Profesores con especialidad y sede |
| `core.vw_ReporteMatriculasPeriodo` | Reporte consolidado por período/sede/carrera |

### 3.3 Triggers (5) — `programmability/triggers/*`

| Trigger | Regla | Descripción |
|---|---|---|
| `core.TRG_Audit_Estudiantes` | RN-07 | Registra INSERT/UPDATE/DELETE de estudiantes |
| `core.TRG_Audit_Matriculas` | RN-07 | Registra operaciones sobre matrículas |
| `sales.TRG_Audit_Promotores` | RN-07 | Registra operaciones sobre promotores |
| `sales.TRG_Audit_Comisiones` | RN-07 | Registra operaciones sobre comisiones |
| `core.TRG_Comision_Automatica` | RN-09 | Crea la comisión al matricular; recalcula al cambiar monto/estado; la anula si la matrícula se retira |

### 3.4 Procedimientos almacenados (9) — `programmability/procedures/*`

| Procedimiento | Regla | Descripción |
|---|---|---|
| `core.usp_RegistrarEstudiante` | RN-01 | Alta con validación de documento/correo (51001-51003) |
| `core.usp_ActualizarEstudiante` | RN-01 | Actualización manteniendo unicidad (51004) |
| `core.usp_EliminarEstudianteLogico` | RN-10 | Borrado lógico con `DeletedAt` (51005) |
| `sales.usp_RegistrarPromotor` | RN-08 | Alta de promotor vinculado a sede (52010-52013) |
| `core.usp_RegistrarMatricula` | RN-02/03/04/08/09 | Matrícula transaccional; genera código `MAT-AAAA-NNNNNN` (52001-52007) |
| `core.usp_RetirarMatricula` | RN-09 | Retira la matrícula; el trigger anula la comisión (52008) |
| `core.usp_EliminarMatriculaLogico` | RN-10 | Borrado lógico de matrícula (52009) |
| `sales.usp_MarcarComisionPagada` | RN-09 | Marca comisión pagada; rechaza comisiones anuladas (53001-53002) |
| `core.usp_ConsultarMatriculas` | — | Consulta con filtros por período, sede, promotor y estado |

Todas las operaciones que modifican datos corren en **transacciones con `TRY...CATCH`** (RN-04): ante cualquier error se ejecuta `ROLLBACK` y se propaga el error con `THROW` y un código propio.

## 4. Datos de Prueba y Casos de Prueba

- `dml/02_test_data.sql` registra un estudiante, un promotor y una matrícula en el período **2027-I** (ventana de matrícula vigente) usando los procedimientos del sistema.
- `dml/03_test_cases.sql` ejecuta **18 casos de prueba** automáticos que verifican RN-01 a RN-10, incluyendo el **rollback total** de la transacción de matrícula y la **anulación de la comisión** al retirar una matrícula.
- Resultado: **18/18 superados — Estado: APROBADO**.

### Evidencia de ejecución

```
T01 RN-01 documento duplicado      → ERROR 51001  [OK]
T02 RN-01 email duplicado          → ERROR 51002  [OK]
T03 RN-02 matrícula duplicada      → ERROR 52006  [OK]
T04 RN-03 ventana cerrada          → ERROR 52005  [OK]
T05 RN-04 rollback sin residuos    → 11/11 filas, 0 trans abiertas [OK]
T06 RN-08 promotor inexistente     → ERROR 52004  [OK]
T07 RN-05 malla completa           → 0 carreras sin cursos [OK]
T08 RN-06 perfiles                 → 5 roles [OK]
T09 RN-07 auditoría                → 11 registros [OK]
T10 RN-09 comisión 250×12%=30.00   → MontoTotal=30.00, Pendiente [OK]
T11 RN-09 retiro anula comisión    → Anulada [OK]
T12 RN-10 borrado lógico estudiante→ DeletedAt OK [OK]
T13 RN-10 borrado lógico matrícula → DeletedAt OK [OK]
T14 RN-08 código promotor duplicado→ ERROR 52011  [OK]
T15 RN-09 comisión anulada impaga  → ERROR 53002  [OK]
T16 RN-09 fórmula fn_CalcularComision = 30.00 [OK]
T17 RN-03 fn ventana consistente   → fn=1 ventana=1 [OK]
T18 Reportes vw_* con datos        → todos > 0 [OK]
```

## 5. Verificación Integral de la Instalación

`utils/verificar_instalacion.sql` valida 13 secciones:

1. Base de datos (collation y recovery FULL)
2. Esquemas (6)
3. Tablas (17)
4. Foreign Keys (21)
5. Unique Constraints (22)
6. Check Constraints (30)
7. Índices de optimización (14)
8. Datos iniciales (143 registros: seed + prueba)
9. Integridad referencial (sin huérfanos)
10. Reglas de negocio (sin duplicados)
11. Control de versiones (1.0.0)
12. **Objetos Sprint 2 (6 funciones, 7 vistas, 5 triggers, 9 procedimientos)**
13. **Seguridad RN-06**: perfiles SQL existentes, `MC_Admin` en `db_owner`, y pruebas en vivo de permisos con `EXECUTE AS` (promotor denegado en seguridad/auditoría, coordinador denegado en comisiones, ambos permitidos en sus áreas)

Resultado: **INSTALACIÓN PERFECTA — ESTADO: APROBADO**.

## 6. Seguridad y Auditoría

- **RN-06 ampliada**: además de los 5 roles de catálogo (`security.Roles`), se implementaron **permisos reales de SQL Server** en `sqlserver/security/01_usuarios_permisos.sql`: logins `MC_Admin`, `MC_Coordinador` y `MC_Promotor` con `GRANT`/`DENY` específicos por perfil.
  - `MC_Admin` → `db_owner` (acceso completo).
  - `MC_Coordinador` → vistas académicas/core, registra/retira matrículas, actualiza estudiantes; **denegado** el acceso a comisiones, seguridad y auditoría.
  - `MC_Promotor` → registro de estudiantes vía SP y consulta de sus comisiones; **denegado** el acceso a matrículas, seguridad y auditoría.
  - El acceso a datos se otorga solo vía vistas/SP (encadenamiento de propiedad, todo es `dbo`), aplicando el principio de menor privilegio.
- Contraseñas con **hash SHA2-256** (`HASHBYTES`) en el seed.
- Auditoría completa (RN-07): usuario (`SUSER_SNAME()`, ahora el login real que opera: `MC_Admin`, `MC_Coordinador`, `MC_Promotor`...), fecha/hora, operación, valores anteriores/nuevos (JSON) e IP del cliente para estudiantes, matrículas, promotores y comisiones.
- Códigos de error propios (51000-53999) por dominio para diagnóstico en la aplicación.

## 7. Consideraciones de Operación

- **Idempotencia**: todos los scripts pueden reejecutarse; los casos de prueba restauran su estado base.
- **Período vigente**: el período 2027-I mantiene su ventana de matrícula abierta (2026-08-01 a 2026-10-15) para poder demostrar matrículas en vivo; al cerrarse, las pruebas se marcan "NO APLICA" en lugar de fallar.
- **Recreación limpia**: `docker compose down -v && docker compose up -d` reconstruye todo el escenario (Sprint 1 + Sprint 2 + pruebas) automáticamente.

## 8. Entregables

- `sqlserver/ddl/04_constraints.sql` (17 PK, 21 FK, 22 UK, 30 CK)
- `sqlserver/security/01_usuarios_permisos.sql` (perfiles RN-06: logins, usuarios, GRANT/DENY)
- `sqlserver/programmability/` (6 `fn_*.sql`, 5 `trg_*.sql`, 7 `vw_*.sql`, 9 `usp_*.sql`)
- `sqlserver/dml/02_test_data.sql`, `03_test_cases.sql`
- `docker/init/init.sql` (35 pasos)
- Verificación ampliada en `utils/verificar_instalacion.sql`
- Documentación actualizada (README raíz, `docker/README.md`, `datasets/README.md`)
