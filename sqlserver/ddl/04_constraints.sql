-- =============================================
-- Matricula Cloud 360 Enterprise
-- 04_constraints.sql | Restricciones de integridad
-- =============================================
-- Descripcion: Aplica las restricciones de integridad del modelo
-- fisico sobre las tablas creadas en 03_tables.sql:
--   - Claves primarias (PK)          : 17
--   - Claves foraneas (FK)           : 21
--   - Restricciones unicas (UK)      : 22
--   - Restricciones de verificacion  : 30 (CK)
--
-- Reglas de negocio cubiertas:
--   RN-01: UK_Estudiantes_Documento y UK_Estudiantes_Email
--   RN-02: UK_Matriculas_EstudiantePeriodoCarrera
--   RN-05: FK de la malla curricular y asignacion curso-profesor
--   RN-08: FK/ NOT NULL de Promotor y Sede en Matriculas
--
-- IDEMPOTENTE: cada restriccion se crea solo si no existe.
-- =============================================

USE MatriculaCloud360DB;
GO

SET QUOTED_IDENTIFIER ON;
GO

PRINT '============================================';
PRINT '04_constraints.sql - Restricciones de integridad';
PRINT '============================================';
GO

-- =============================================
-- 1. core.Ubigeos
-- =============================================
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'PK_Ubigeos')
    ALTER TABLE core.Ubigeos ADD CONSTRAINT PK_Ubigeos PRIMARY KEY (UbigeoId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'UK_Ubigeos_Codigo')
    ALTER TABLE core.Ubigeos ADD CONSTRAINT UK_Ubigeos_Codigo UNIQUE (CodigoUbigeo);
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'CK_Ubigeos_Codigo')
    ALTER TABLE core.Ubigeos ADD CONSTRAINT CK_Ubigeos_Codigo
        CHECK (LEN(CodigoUbigeo) = 6 AND CodigoUbigeo NOT LIKE '%[^0-9]%');
GO

-- =============================================
-- 2. core.Sedes
-- =============================================
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'PK_Sedes')
    ALTER TABLE core.Sedes ADD CONSTRAINT PK_Sedes PRIMARY KEY (SedeId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'FK_Sedes_Ubigeo')
    ALTER TABLE core.Sedes ADD CONSTRAINT FK_Sedes_Ubigeo
        FOREIGN KEY (UbigeoId) REFERENCES core.Ubigeos(UbigeoId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'UK_Sedes_Codigo')
    ALTER TABLE core.Sedes ADD CONSTRAINT UK_Sedes_Codigo UNIQUE (CodigoSede);
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'CK_Sedes_Email')
    ALTER TABLE core.Sedes ADD CONSTRAINT CK_Sedes_Email CHECK (Email LIKE '%@%');
GO

-- =============================================
-- 3. core.Carreras
-- =============================================
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'PK_Carreras')
    ALTER TABLE core.Carreras ADD CONSTRAINT PK_Carreras PRIMARY KEY (CarreraId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'UK_Carreras_Codigo')
    ALTER TABLE core.Carreras ADD CONSTRAINT UK_Carreras_Codigo UNIQUE (CodigoCarrera);
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'CK_Carreras_Duracion')
    ALTER TABLE core.Carreras ADD CONSTRAINT CK_Carreras_Duracion CHECK (DuracionSemestres > 0);
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'CK_Carreras_Costos')
    ALTER TABLE core.Carreras ADD CONSTRAINT CK_Carreras_Costos
        CHECK (CostoMatricula >= 0 AND CostoPensionMensual >= 0);
GO

-- =============================================
-- 4. core.Estudiantes (RN-01)
-- =============================================
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'PK_Estudiantes')
    ALTER TABLE core.Estudiantes ADD CONSTRAINT PK_Estudiantes PRIMARY KEY (EstudianteId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'FK_Estudiantes_Ubigeo')
    ALTER TABLE core.Estudiantes ADD CONSTRAINT FK_Estudiantes_Ubigeo
        FOREIGN KEY (UbigeoId) REFERENCES core.Ubigeos(UbigeoId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'UK_Estudiantes_Documento')
    ALTER TABLE core.Estudiantes ADD CONSTRAINT UK_Estudiantes_Documento UNIQUE (TipoDocumento, NumeroDocumento);
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'UK_Estudiantes_Email')
    ALTER TABLE core.Estudiantes ADD CONSTRAINT UK_Estudiantes_Email UNIQUE (Email);
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'CK_Estudiantes_Documento')
    ALTER TABLE core.Estudiantes ADD CONSTRAINT CK_Estudiantes_Documento CHECK (
        (TipoDocumento = 'DNI' AND LEN(NumeroDocumento) = 8 AND NumeroDocumento NOT LIKE '%[^0-9]%')
        OR
        (TipoDocumento = 'CE' AND LEN(NumeroDocumento) BETWEEN 1 AND 15 AND NumeroDocumento NOT LIKE '%[^0-9A-Za-z]%')
    );
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'CK_Estudiantes_Email')
    ALTER TABLE core.Estudiantes ADD CONSTRAINT CK_Estudiantes_Email CHECK (Email LIKE '%@%');
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'CK_Estudiantes_Genero')
    ALTER TABLE core.Estudiantes ADD CONSTRAINT CK_Estudiantes_Genero CHECK (Genero IN ('M','F','O'));
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'CK_Estudiantes_Celular')
    ALTER TABLE core.Estudiantes ADD CONSTRAINT CK_Estudiantes_Celular
        CHECK (Celular IS NULL OR Celular LIKE '9[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]');
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'CK_Estudiantes_FechaNacimiento')
    ALTER TABLE core.Estudiantes ADD CONSTRAINT CK_Estudiantes_FechaNacimiento CHECK (FechaNacimiento < GETDATE());
GO

-- =============================================
-- 5. core.PeriodosAcademicos
-- =============================================
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'PK_PeriodosAcademicos')
    ALTER TABLE core.PeriodosAcademicos ADD CONSTRAINT PK_PeriodosAcademicos PRIMARY KEY (PeriodoId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'UK_PeriodosAcademicos_Codigo')
    ALTER TABLE core.PeriodosAcademicos ADD CONSTRAINT UK_PeriodosAcademicos_Codigo UNIQUE (CodigoPeriodo);
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'CK_PeriodosAcademicos_Semestre')
    ALTER TABLE core.PeriodosAcademicos ADD CONSTRAINT CK_PeriodosAcademicos_Semestre CHECK (Semestre IN (1,2));
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'CK_PeriodosAcademicos_Fechas')
    ALTER TABLE core.PeriodosAcademicos ADD CONSTRAINT CK_PeriodosAcademicos_Fechas CHECK (FechaFin > FechaInicio);
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'CK_PeriodosAcademicos_FechasMatricula')
    ALTER TABLE core.PeriodosAcademicos ADD CONSTRAINT CK_PeriodosAcademicos_FechasMatricula
        CHECK (FechaFinMatriculas > FechaInicioMatriculas);
GO

-- =============================================
-- 6. academic.Especialidades
-- =============================================
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'PK_Especialidades')
    ALTER TABLE academic.Especialidades ADD CONSTRAINT PK_Especialidades PRIMARY KEY (EspecialidadId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'UK_Especialidades_Nombre')
    ALTER TABLE academic.Especialidades ADD CONSTRAINT UK_Especialidades_Nombre UNIQUE (NombreEspecialidad);
GO

-- =============================================
-- 7. academic.Profesores
-- =============================================
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'PK_Profesores')
    ALTER TABLE academic.Profesores ADD CONSTRAINT PK_Profesores PRIMARY KEY (ProfesorId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'FK_Profesores_Especialidad')
    ALTER TABLE academic.Profesores ADD CONSTRAINT FK_Profesores_Especialidad
        FOREIGN KEY (EspecialidadId) REFERENCES academic.Especialidades(EspecialidadId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'UK_Profesores_Documento')
    ALTER TABLE academic.Profesores ADD CONSTRAINT UK_Profesores_Documento UNIQUE (TipoDocumento, NumeroDocumento);
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'UK_Profesores_Email')
    ALTER TABLE academic.Profesores ADD CONSTRAINT UK_Profesores_Email UNIQUE (Email);
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'CK_Profesores_Documento')
    ALTER TABLE academic.Profesores ADD CONSTRAINT CK_Profesores_Documento CHECK (
        (TipoDocumento = 'DNI' AND LEN(NumeroDocumento) = 8 AND NumeroDocumento NOT LIKE '%[^0-9]%')
        OR
        (TipoDocumento = 'CE' AND LEN(NumeroDocumento) BETWEEN 1 AND 15 AND NumeroDocumento NOT LIKE '%[^0-9A-Za-z]%')
    );
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'CK_Profesores_Email')
    ALTER TABLE academic.Profesores ADD CONSTRAINT CK_Profesores_Email CHECK (Email LIKE '%@%');
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'CK_Profesores_Celular')
    ALTER TABLE academic.Profesores ADD CONSTRAINT CK_Profesores_Celular
        CHECK (Celular IS NULL OR Celular LIKE '9[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]');
GO

-- =============================================
-- 8. academic.Cursos
-- =============================================
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'PK_Cursos')
    ALTER TABLE academic.Cursos ADD CONSTRAINT PK_Cursos PRIMARY KEY (CursoId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'UK_Cursos_Codigo')
    ALTER TABLE academic.Cursos ADD CONSTRAINT UK_Cursos_Codigo UNIQUE (CodigoCurso);
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'CK_Cursos_Creditos')
    ALTER TABLE academic.Cursos ADD CONSTRAINT CK_Cursos_Creditos CHECK (Creditos > 0);
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'CK_Cursos_Horas')
    ALTER TABLE academic.Cursos ADD CONSTRAINT CK_Cursos_Horas CHECK (HorasTeoria >= 0 AND HorasPractica >= 0);
GO

-- =============================================
-- 9. academic.CarreraCursos (RN-05: malla N:M)
-- =============================================
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'PK_CarreraCursos')
    ALTER TABLE academic.CarreraCursos ADD CONSTRAINT PK_CarreraCursos PRIMARY KEY (CarreraCursoId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'FK_CarreraCursos_Carrera')
    ALTER TABLE academic.CarreraCursos ADD CONSTRAINT FK_CarreraCursos_Carrera
        FOREIGN KEY (CarreraId) REFERENCES core.Carreras(CarreraId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'FK_CarreraCursos_Curso')
    ALTER TABLE academic.CarreraCursos ADD CONSTRAINT FK_CarreraCursos_Curso
        FOREIGN KEY (CursoId) REFERENCES academic.Cursos(CursoId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'UK_CarreraCursos')
    ALTER TABLE academic.CarreraCursos ADD CONSTRAINT UK_CarreraCursos UNIQUE (CarreraId, CursoId, Semestre);
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'CK_CarreraCursos_Semestre')
    ALTER TABLE academic.CarreraCursos ADD CONSTRAINT CK_CarreraCursos_Semestre CHECK (Semestre > 0);
GO

-- =============================================
-- 10. sales.Promotores
-- =============================================
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'PK_Promotores')
    ALTER TABLE sales.Promotores ADD CONSTRAINT PK_Promotores PRIMARY KEY (PromotorId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'FK_Promotores_Sede')
    ALTER TABLE sales.Promotores ADD CONSTRAINT FK_Promotores_Sede
        FOREIGN KEY (SedeId) REFERENCES core.Sedes(SedeId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'UK_Promotores_Codigo')
    ALTER TABLE sales.Promotores ADD CONSTRAINT UK_Promotores_Codigo UNIQUE (CodigoPromotor);
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'UK_Promotores_Documento')
    ALTER TABLE sales.Promotores ADD CONSTRAINT UK_Promotores_Documento UNIQUE (TipoDocumento, NumeroDocumento);
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'UK_Promotores_Email')
    ALTER TABLE sales.Promotores ADD CONSTRAINT UK_Promotores_Email UNIQUE (Email);
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'CK_Promotores_Documento')
    ALTER TABLE sales.Promotores ADD CONSTRAINT CK_Promotores_Documento CHECK (
        (TipoDocumento = 'DNI' AND LEN(NumeroDocumento) = 8 AND NumeroDocumento NOT LIKE '%[^0-9]%')
        OR
        (TipoDocumento = 'CE' AND LEN(NumeroDocumento) BETWEEN 1 AND 15 AND NumeroDocumento NOT LIKE '%[^0-9A-Za-z]%')
    );
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'CK_Promotores_Email')
    ALTER TABLE sales.Promotores ADD CONSTRAINT CK_Promotores_Email CHECK (Email LIKE '%@%');
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'CK_Promotores_Celular')
    ALTER TABLE sales.Promotores ADD CONSTRAINT CK_Promotores_Celular
        CHECK (Celular IS NULL OR Celular LIKE '9[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]');
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'CK_Promotores_Comision')
    ALTER TABLE sales.Promotores ADD CONSTRAINT CK_Promotores_Comision
        CHECK (PorcentajeComision >= 0 AND PorcentajeComision <= 100);
GO

-- =============================================
-- 11. sales.CampaniasAdmision
-- =============================================
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'PK_CampaniasAdmision')
    ALTER TABLE sales.CampaniasAdmision ADD CONSTRAINT PK_CampaniasAdmision PRIMARY KEY (CampaniaId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'FK_CampaniasAdmision_Periodo')
    ALTER TABLE sales.CampaniasAdmision ADD CONSTRAINT FK_CampaniasAdmision_Periodo
        FOREIGN KEY (PeriodoId) REFERENCES core.PeriodosAcademicos(PeriodoId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'UK_CampaniasAdmision_Codigo')
    ALTER TABLE sales.CampaniasAdmision ADD CONSTRAINT UK_CampaniasAdmision_Codigo UNIQUE (CodigoCampania);
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'CK_CampaniasAdmision_Fechas')
    ALTER TABLE sales.CampaniasAdmision ADD CONSTRAINT CK_CampaniasAdmision_Fechas CHECK (FechaFin > FechaInicio);
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'CK_CampaniasAdmision_Comision')
    ALTER TABLE sales.CampaniasAdmision ADD CONSTRAINT CK_CampaniasAdmision_Comision
        CHECK (PorcentajeComisionBase >= 0 AND PorcentajeComisionBase <= 100);
GO

-- =============================================
-- 12. core.Matriculas (RN-02, RN-08)
-- =============================================
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'PK_Matriculas')
    ALTER TABLE core.Matriculas ADD CONSTRAINT PK_Matriculas PRIMARY KEY (MatriculaId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'FK_Matriculas_Estudiante')
    ALTER TABLE core.Matriculas ADD CONSTRAINT FK_Matriculas_Estudiante
        FOREIGN KEY (EstudianteId) REFERENCES core.Estudiantes(EstudianteId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'FK_Matriculas_Carrera')
    ALTER TABLE core.Matriculas ADD CONSTRAINT FK_Matriculas_Carrera
        FOREIGN KEY (CarreraId) REFERENCES core.Carreras(CarreraId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'FK_Matriculas_Periodo')
    ALTER TABLE core.Matriculas ADD CONSTRAINT FK_Matriculas_Periodo
        FOREIGN KEY (PeriodoId) REFERENCES core.PeriodosAcademicos(PeriodoId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'FK_Matriculas_Sede')
    ALTER TABLE core.Matriculas ADD CONSTRAINT FK_Matriculas_Sede
        FOREIGN KEY (SedeId) REFERENCES core.Sedes(SedeId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'FK_Matriculas_Promotor')
    ALTER TABLE core.Matriculas ADD CONSTRAINT FK_Matriculas_Promotor
        FOREIGN KEY (PromotorId) REFERENCES sales.Promotores(PromotorId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'FK_Matriculas_Campania')
    ALTER TABLE core.Matriculas ADD CONSTRAINT FK_Matriculas_Campania
        FOREIGN KEY (CampaniaId) REFERENCES sales.CampaniasAdmision(CampaniaId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'UK_Matriculas_Codigo')
    ALTER TABLE core.Matriculas ADD CONSTRAINT UK_Matriculas_Codigo UNIQUE (CodigoMatricula);
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'UK_Matriculas_EstudiantePeriodoCarrera')
    ALTER TABLE core.Matriculas ADD CONSTRAINT UK_Matriculas_EstudiantePeriodoCarrera
        UNIQUE (EstudianteId, CarreraId, PeriodoId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'CK_Matriculas_Monto')
    ALTER TABLE core.Matriculas ADD CONSTRAINT CK_Matriculas_Monto CHECK (MontoMatricula >= 0);
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'CK_Matriculas_Estado')
    ALTER TABLE core.Matriculas ADD CONSTRAINT CK_Matriculas_Estado
        CHECK (EstadoMatricula IN ('Activa','Retirada','Suspendida','Culminada'));
GO

-- =============================================
-- 13. sales.Comisiones
-- =============================================
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'PK_Comisiones')
    ALTER TABLE sales.Comisiones ADD CONSTRAINT PK_Comisiones PRIMARY KEY (ComisionId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'FK_Comisiones_Promotor')
    ALTER TABLE sales.Comisiones ADD CONSTRAINT FK_Comisiones_Promotor
        FOREIGN KEY (PromotorId) REFERENCES sales.Promotores(PromotorId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'FK_Comisiones_Matricula')
    ALTER TABLE sales.Comisiones ADD CONSTRAINT FK_Comisiones_Matricula
        FOREIGN KEY (MatriculaId) REFERENCES core.Matriculas(MatriculaId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'FK_Comisiones_Campania')
    ALTER TABLE sales.Comisiones ADD CONSTRAINT FK_Comisiones_Campania
        FOREIGN KEY (CampaniaId) REFERENCES sales.CampaniasAdmision(CampaniaId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'UK_Comisiones_Matricula')
    ALTER TABLE sales.Comisiones ADD CONSTRAINT UK_Comisiones_Matricula UNIQUE (MatriculaId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'CK_Comisiones_Montos')
    ALTER TABLE sales.Comisiones ADD CONSTRAINT CK_Comisiones_Montos
        CHECK (MontoBase >= 0 AND MontoComision >= 0 AND MontoTotal >= 0);
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'CK_Comisiones_Estado')
    ALTER TABLE sales.Comisiones ADD CONSTRAINT CK_Comisiones_Estado
        CHECK (EstadoPago IN ('Pendiente','Pagada','Anulada'));
GO

-- =============================================
-- 14. academic.CursoProfesor (RN-05)
-- =============================================
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'PK_CursoProfesor')
    ALTER TABLE academic.CursoProfesor ADD CONSTRAINT PK_CursoProfesor PRIMARY KEY (CursoProfesorId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'FK_CursoProfesor_Curso')
    ALTER TABLE academic.CursoProfesor ADD CONSTRAINT FK_CursoProfesor_Curso
        FOREIGN KEY (CursoId) REFERENCES academic.Cursos(CursoId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'FK_CursoProfesor_Profesor')
    ALTER TABLE academic.CursoProfesor ADD CONSTRAINT FK_CursoProfesor_Profesor
        FOREIGN KEY (ProfesorId) REFERENCES academic.Profesores(ProfesorId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'FK_CursoProfesor_Periodo')
    ALTER TABLE academic.CursoProfesor ADD CONSTRAINT FK_CursoProfesor_Periodo
        FOREIGN KEY (PeriodoId) REFERENCES core.PeriodosAcademicos(PeriodoId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'FK_CursoProfesor_Sede')
    ALTER TABLE academic.CursoProfesor ADD CONSTRAINT FK_CursoProfesor_Sede
        FOREIGN KEY (SedeId) REFERENCES core.Sedes(SedeId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'UK_CursoProfesor')
    ALTER TABLE academic.CursoProfesor ADD CONSTRAINT UK_CursoProfesor
        UNIQUE (CursoId, ProfesorId, PeriodoId, SedeId);
GO

-- =============================================
-- 15. security.Roles (RN-06)
-- =============================================
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'PK_Roles')
    ALTER TABLE security.Roles ADD CONSTRAINT PK_Roles PRIMARY KEY (RolId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'UK_Roles_Nombre')
    ALTER TABLE security.Roles ADD CONSTRAINT UK_Roles_Nombre UNIQUE (NombreRol);
GO

-- =============================================
-- 16. security.Usuarios
-- =============================================
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'PK_Usuarios')
    ALTER TABLE security.Usuarios ADD CONSTRAINT PK_Usuarios PRIMARY KEY (UsuarioId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'FK_Usuarios_Rol')
    ALTER TABLE security.Usuarios ADD CONSTRAINT FK_Usuarios_Rol
        FOREIGN KEY (RolId) REFERENCES security.Roles(RolId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'UK_Usuarios_Username')
    ALTER TABLE security.Usuarios ADD CONSTRAINT UK_Usuarios_Username UNIQUE (Username);
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'UK_Usuarios_Email')
    ALTER TABLE security.Usuarios ADD CONSTRAINT UK_Usuarios_Email UNIQUE (Email);
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'CK_Usuarios_Email')
    ALTER TABLE security.Usuarios ADD CONSTRAINT CK_Usuarios_Email CHECK (Email LIKE '%@%');
GO

-- =============================================
-- 17. audit.AuditLog (RN-07)
-- =============================================
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'PK_AuditLog')
    ALTER TABLE audit.AuditLog ADD CONSTRAINT PK_AuditLog PRIMARY KEY (AuditId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'CK_AuditLog_Operation')
    ALTER TABLE audit.AuditLog ADD CONSTRAINT CK_AuditLog_Operation
        CHECK (Operation IN ('INSERT','UPDATE','DELETE'));
GO

-- =============================================
-- RESUMEN
-- =============================================
PRINT '';
PRINT '============================================';
PRINT 'RESUMEN DE RESTRICCIONES:';
PRINT '============================================';
PRINT '  Primary Keys      : 17';
PRINT '  Foreign Keys      : 21';
PRINT '  Unique Constraints: 22';
PRINT '  Check Constraints : 30';
PRINT '============================================';
GO
