# Matricula Cloud 360 Enterprise - Informe Tecnico Sprint 2

**Proyecto:** Matricula Cloud 360 Enterprise (SQL Server 2025 Developer en Docker)
**Alcance:** Reglas de negocio RN-01 a RN-10 implementadas con objetos programables (funciones, triggers, vistas, procedimientos almacenados), seguridad por perfiles y pruebas automatizadas.
**Base de datos:** `MatriculaCloud360DB`

---

## 1. Reglas de negocio implementadas

| Regla | Descripcion | Implementacion |
|---|---|---|
| RN-01 | Documento de identidad unico por estudiante | FK/UK + validacion en `usp_RegistrarEstudiante` (error 51001) |
| RN-02 | Email unico | UK `IX_Estudiantes_Email` + validacion en `usp_RegistrarEstudiante` (51002) |
| RN-03 | Menor de edad requiere apoderado | Check + logicas en `usp_RegistrarEstudiante` |
| RN-04 | Transaccionalidad de operaciones criticas | `BEGIN TRAN` + `TRY…CATCH` + `ROLLBACK` en todos los SP |
| RN-05 | Matricula unica por estudiante y periodo | UK + `usp_RegistrarMatricula` (error 52006) |
| RN-06 | Perfiles y permisos (Administrador, Coordinador, Promotor) | Logins/roles + matriz GRANT/DENY (ver seccion 5) |
| RN-07 | Auditoria de operaciones | 4 triggers AFTER en Estudiantes, Matriculas, Promotores, Comisiones |
| RN-08 | Promotor obligatorio en la matricula | Validacion en `usp_RegistrarMatricula` (error 52007) |
| RN-09 | Comision automatica al matricular | `trg_Comision_Automatica` + `sales.fn_CalcularComision` + bono |
| RN-10 | Borrado logico (`deleted_at`/`DeletedAt`) | Extendido en el Sprint 3 con triggers `INSTEAD OF DELETE` |

## 2. Funciones de negocio (6)

**Directorio:** `sqlserver/programmability/functions/`

| Funcion | Proposito |
|---|---|
| `core.fn_PeriodoMatriculaHabilitado` | Valida que el periodo este dentro de la ventana de matriculas |
| `core.fn_ExisteEstudianteConDocumento` | Detecta duplicados de documento (RN-01) |
| `core.fn_EdadEstudiante` | Calcula la edad a partir de la fecha de nacimiento |
| `core.fn_TotalMatriculadosCarrera` | Demanda real de una carrera |
| `sales.fn_CalcularComision` | Comision de un promotor (por matricula) |
| `sales.fn_CalcularBonoPromotor` | Bono por desempeno en la campana |

## 3. Vistas de reporte (7)

**Directorio:** `sqlserver/programmability/views/`

| Vista | Reporte |
|---|---|
| `vw_EstudiantesDetalle` | Estudiantes con ubigeo, edad y estado |
| `vw_MatriculasDetalle` | Matriculas con estudiante, carrera, sede, periodo y promotor |
| `vw_ComisionesDetalle` | Comisiones por promotor y campana |
| `vw_DesempenoPromotores` | Desempeno comparativo de promotores |
| `vw_MallaCurricular` | Malla por carrera y semestre |
| `vw_ProfesoresDetalle` | Profesores con especialidad y cursos |
| `vw_ReporteMatriculasPeriodo` | Reporte oficial por periodo |

## 4. Triggers (5)

**Directorio:** `sqlserver/programmability/triggers/`

| Trigger | Tipo | Proposito |
|---|---|---|
| `trg_Audit_Estudiantes` | AFTER | Auditoria INSERT/UPDATE/DELETE (RN-07) |
| `trg_Audit_Matriculas` | AFTER | Auditoria de matriculas (RN-07) |
| `trg_Audit_Promotores` | AFTER | Auditoria de promotores (RN-07) |
| `trg_Audit_Comisiones` | AFTER | Auditoria de comisiones (RN-07) |
| `trg_Comision_Automatica` | AFTER | Genera la comision al registrar la matricula (RN-09) |

Trazabilidad registrada en `audit.AuditLog` con usuario, fecha/hora, operacion, valores antiguos/nuevos (JSON) y direccion IP.

## 5. Procedimientos almacenados (10)

**Directorio:** `sqlserver/programmability/procedures/`

| Procedimiento | Operacion |
|---|---|
| `usp_RegistrarEstudiante` | Alta de estudiante con validaciones RN-01/RN-02/RN-03 |
| `usp_ActualizarEstudiante` | Actualizacion de datos (no permite inactivos) |
| `usp_EliminarEstudianteLogico` | Baja logica (triggers del Sprint 3) |
| `sales.usp_RegistrarPromotor` | Alta de promotor |
| `usp_RegistrarMatricula` | Matricula con RN-05/RN-08 + comision RN-09; codigo unico pre-asignado para evitar colisiones |
| `usp_RetirarMatricula` | Retiro con validacion de estado |
| `usp_EliminarMatriculaLogico` | Baja logica de matricula |
| `sales.usp_MarcarComisionPagada` | Actualiza estado de pago de comision |
| `usp_ConsultarMatriculas` | Consulta con filtros (periodo, estado, promotor, fecha) |
| `usp_ConsultarEstudiantes` | Consulta con busqueda por nombre/documento/tipo (agregado para las vistas del Sprint 3) |

Todos usan transacciones + `TRY…CATCH` (RN-04) y errores de negocio tipados (codigos 51001-52009).

## 6. Seguridad RN-06 (Sprint 2)

**Archivo:** `sqlserver/security/01_usuarios_permisos.sql`

| Perfil | Login | Permisos |
|---|---|---|
| Administrador | `MC_Admin` | `db_owner` / acceso total |
| Coordinador academico | `MC_Coordinador` | Lectura de reportes academicos (vistas) |
| Promotor | `MC_Promotor` | Registrar estudiantes, ver sus comisiones |

Contrasenas documentadas en el `README.md` para la sustentacion. El Sprint 3 refina esta matriz con roles y `DENY` explícitos (`security/02_roles.sql`, `03_permissions.sql`).

## 7. Datos y pruebas

**Archivos:** `sqlserver/dml/01_seed_data.sql`, `02_test_data.sql`, `03_test_cases.sql`

- **Seed data**: datos base reales de EduFuturo (sede, carreras, cursos, docentes, promotores, campanas, periodos, ubigeos).
- **Test data**: estudiantes y matriculas registrados **vía los procedimientos almacenados** (ejercita RN y triggers), generando las comisiones automaticamente.
- **18 casos de prueba (T01-T18)**: cubren cada regla de negocio (documento duplicado, email duplicado, matricula duplicada, ventana cerrada, promotor obligatorio, menor con apoderado, etc.); **18/18 superados** en la verificacion de instalacion.

## 8. Resultados y cumplimiento

| Criterio | Estado |
|---|---|
| 6 funciones / 7 vistas / 5 triggers / 10 SP | Cumple |
| Reglas RN-01 a RN-10 | Cumple |
| Seguridad RN-06 con perfiles GRANT/DENY | Cumple |
| Datos de prueba via procedimientos | Cumple |
| 18 de 18 casos de prueba | Cumple |

---

> **Nota:** el Sprint 3 amplia este trabajo con auditoria integral, borrado logico `INSTEAD OF DELETE`, consultas avanzadas, indices, rol-based security, respaldo FULL+DIFERENCIAL+LOG, SQL Agent y dashboard (ver `docs/sprint3-informe.md`).