-- =============================================
-- Matricula Cloud 360 Enterprise
-- 03_tables.sql | Creacion de tablas e indices
-- =============================================
-- Descripcion: Define las 15 entidades del sistema organizadas
-- por esquema, con sus restricciones (PK, FK, UK, CK), campos de
-- auditoria (CreatedAt/UpdatedAt/DeletedAt) e indices de rendimiento.
--
-- IDEMPOTENTE: cada objeto se crea solo si no existe.
-- Puede ejecutarse multiples veces sin errores.
-- =============================================

USE MatriculaCloud360DB;
GO

-- Los indices filtrados requieren QUOTED_IDENTIFIER ON.
-- sqlcmd lo desactiva por defecto, por lo que se fuerza aqui.
SET QUOTED_IDENTIFIER ON;
GO

PRINT '============================================';
PRINT '03_tables.sql - Creacion de tablas';
PRINT '============================================';
GO

-- =============================================
-- ESQUEMA: core
-- =============================================

-- Tabla: core.Sedes
-- Sedes fisicas del instituto
IF OBJECT_ID(N'core.Sedes', N'U') IS NULL
BEGIN
    CREATE TABLE core.Sedes (
        SedeId INT IDENTITY(1,1) NOT NULL,
        CodigoSede VARCHAR(10) NOT NULL,
        NombreSede NVARCHAR(100) NOT NULL,
        Direccion NVARCHAR(200) NOT NULL,
        Ciudad NVARCHAR(50) NOT NULL,
        Departamento NVARCHAR(50) NOT NULL,
        Telefono VARCHAR(15) NULL,
        Email VARCHAR(100) NULL,
        Activo BIT NOT NULL DEFAULT 1,
        CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
        UpdatedAt DATETIME NULL,
        DeletedAt DATETIME NULL,
        CONSTRAINT PK_Sedes PRIMARY KEY (SedeId),
        CONSTRAINT UK_Sedes_Codigo UNIQUE (CodigoSede),
        CONSTRAINT CK_Sedes_Email CHECK (Email LIKE '%@%')
    );
    PRINT 'OK: Tabla core.Sedes creada.';
END
ELSE
    PRINT 'OK: core.Sedes ya existe.';
GO

-- Tabla: core.Carreras
-- Carreras profesionales ofrecidas por el instituto
IF OBJECT_ID(N'core.Carreras', N'U') IS NULL
BEGIN
    CREATE TABLE core.Carreras (
        CarreraId INT IDENTITY(1,1) NOT NULL,
        CodigoCarrera VARCHAR(10) NOT NULL,
        NombreCarrera NVARCHAR(150) NOT NULL,
        Descripcion NVARCHAR(500) NULL,
        DuracionSemestres INT NOT NULL,
        CostoMatricula DECIMAL(10,2) NOT NULL,
        CostoPensionMensual DECIMAL(10,2) NOT NULL,
        Activo BIT NOT NULL DEFAULT 1,
        CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
        UpdatedAt DATETIME NULL,
        DeletedAt DATETIME NULL,
        CONSTRAINT PK_Carreras PRIMARY KEY (CarreraId),
        CONSTRAINT UK_Carreras_Codigo UNIQUE (CodigoCarrera),
        CONSTRAINT CK_Carreras_Duracion CHECK (DuracionSemestres > 0),
        CONSTRAINT CK_Carreras_Costos CHECK (CostoMatricula >= 0 AND CostoPensionMensual >= 0)
    );
    PRINT 'OK: Tabla core.Carreras creada.';
END
ELSE
    PRINT 'OK: core.Carreras ya existe.';
GO

-- Tabla: core.Estudiantes
-- Estudiantes registrados. DNI y Email unicos (RN-01).
-- Soporta borrado logico con DeletedAt (RN-10).
IF OBJECT_ID(N'core.Estudiantes', N'U') IS NULL
BEGIN
    CREATE TABLE core.Estudiantes (
        EstudianteId INT IDENTITY(1,1) NOT NULL,
        DNI VARCHAR(8) NOT NULL,
        Nombres NVARCHAR(100) NOT NULL,
        Apellidos NVARCHAR(100) NOT NULL,
        Email VARCHAR(100) NOT NULL,
        Telefono VARCHAR(15) NULL,
        Celular VARCHAR(15) NULL,
        FechaNacimiento DATE NOT NULL,
        Genero CHAR(1) NOT NULL,
        Direccion NVARCHAR(200) NULL,
        Distrito NVARCHAR(50) NULL,
        Provincia NVARCHAR(50) NULL,
        Departamento NVARCHAR(50) NULL,
        Activo BIT NOT NULL DEFAULT 1,
        CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
        UpdatedAt DATETIME NULL,
        DeletedAt DATETIME NULL,
        CONSTRAINT PK_Estudiantes PRIMARY KEY (EstudianteId),
        CONSTRAINT UK_Estudiantes_DNI UNIQUE (DNI),
        CONSTRAINT UK_Estudiantes_Email UNIQUE (Email),
        CONSTRAINT CK_Estudiantes_DNI CHECK (LEN(DNI) = 8 AND DNI NOT LIKE '%[^0-9]%'),
        CONSTRAINT CK_Estudiantes_Email CHECK (Email LIKE '%@%'),
        CONSTRAINT CK_Estudiantes_Genero CHECK (Genero IN ('M','F','O')),
        CONSTRAINT CK_Estudiantes_FechaNacimiento CHECK (FechaNacimiento < GETDATE())
    );
    PRINT 'OK: Tabla core.Estudiantes creada.';
END
ELSE
    PRINT 'OK: core.Estudiantes ya existe.';
GO

-- Tabla: core.PeriodosAcademicos
-- Periodos (ciclos) academicos con ventana de matricula
IF OBJECT_ID(N'core.PeriodosAcademicos', N'U') IS NULL
BEGIN
    CREATE TABLE core.PeriodosAcademicos (
        PeriodoId INT IDENTITY(1,1) NOT NULL,
        CodigoPeriodo VARCHAR(10) NOT NULL,
        NombrePeriodo NVARCHAR(50) NOT NULL,
        Anio INT NOT NULL,
        Semestre INT NOT NULL,
        FechaInicio DATE NOT NULL,
        FechaFin DATE NOT NULL,
        FechaInicioMatriculas DATE NOT NULL,
        FechaFinMatriculas DATE NOT NULL,
        Activo BIT NOT NULL DEFAULT 1,
        CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
        UpdatedAt DATETIME NULL,
        CONSTRAINT PK_PeriodosAcademicos PRIMARY KEY (PeriodoId),
        CONSTRAINT UK_PeriodosAcademicos_Codigo UNIQUE (CodigoPeriodo),
        CONSTRAINT CK_PeriodosAcademicos_Semestre CHECK (Semestre IN (1,2)),
        CONSTRAINT CK_PeriodosAcademicos_Fechas CHECK (FechaFin > FechaInicio),
        CONSTRAINT CK_PeriodosAcademicos_FechasMatricula CHECK (FechaFinMatriculas > FechaInicioMatriculas)
    );
    PRINT 'OK: Tabla core.PeriodosAcademicos creada.';
END
ELSE
    PRINT 'OK: core.PeriodosAcademicos ya existe.';
GO

-- =============================================
-- ESQUEMA: academic
-- =============================================

-- Tabla: academic.Profesores
-- Docentes del instituto
IF OBJECT_ID(N'academic.Profesores', N'U') IS NULL
BEGIN
    CREATE TABLE academic.Profesores (
        ProfesorId INT IDENTITY(1,1) NOT NULL,
        DNI VARCHAR(8) NOT NULL,
        Nombres NVARCHAR(100) NOT NULL,
        Apellidos NVARCHAR(100) NOT NULL,
        Email VARCHAR(100) NOT NULL,
        Telefono VARCHAR(15) NULL,
        Celular VARCHAR(15) NULL,
        Especialidad NVARCHAR(100) NULL,
        GradoAcademico NVARCHAR(50) NULL,
        Activo BIT NOT NULL DEFAULT 1,
        CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
        UpdatedAt DATETIME NULL,
        DeletedAt DATETIME NULL,
        CONSTRAINT PK_Profesores PRIMARY KEY (ProfesorId),
        CONSTRAINT UK_Profesores_DNI UNIQUE (DNI),
        CONSTRAINT UK_Profesores_Email UNIQUE (Email),
        CONSTRAINT CK_Profesores_DNI CHECK (LEN(DNI) = 8 AND DNI NOT LIKE '%[^0-9]%'),
        CONSTRAINT CK_Profesores_Email CHECK (Email LIKE '%@%')
    );
    PRINT 'OK: Tabla academic.Profesores creada.';
END
ELSE
    PRINT 'OK: academic.Profesores ya existe.';
GO

-- Tabla: academic.Cursos
-- Cursos/asignaturas. Un curso puede pertenecer a varias carreras.
IF OBJECT_ID(N'academic.Cursos', N'U') IS NULL
BEGIN
    CREATE TABLE academic.Cursos (
        CursoId INT IDENTITY(1,1) NOT NULL,
        CodigoCurso VARCHAR(10) NOT NULL,
        NombreCurso NVARCHAR(100) NOT NULL,
        Descripcion NVARCHAR(500) NULL,
        Creditos INT NOT NULL,
        HorasTeoria INT NOT NULL DEFAULT 0,
        HorasPractica INT NOT NULL DEFAULT 0,
        Activo BIT NOT NULL DEFAULT 1,
        CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
        UpdatedAt DATETIME NULL,
        DeletedAt DATETIME NULL,
        CONSTRAINT PK_Cursos PRIMARY KEY (CursoId),
        CONSTRAINT UK_Cursos_Codigo UNIQUE (CodigoCurso),
        CONSTRAINT CK_Cursos_Creditos CHECK (Creditos > 0),
        CONSTRAINT CK_Cursos_Horas CHECK (HorasTeoria >= 0 AND HorasPractica >= 0)
    );
    PRINT 'OK: Tabla academic.Cursos creada.';
END
ELSE
    PRINT 'OK: academic.Cursos ya existe.';
GO

-- Tabla: academic.CarreraCursos
-- Malla curricular: relacion N:M entre carreras y cursos.
-- Un curso puede estar en varias carreras y viceversa.
IF OBJECT_ID(N'academic.CarreraCursos', N'U') IS NULL
BEGIN
    CREATE TABLE academic.CarreraCursos (
        CarreraCursoId INT IDENTITY(1,1) NOT NULL,
        CarreraId INT NOT NULL,
        CursoId INT NOT NULL,
        Semestre INT NOT NULL,
        EsObligatorio BIT NOT NULL DEFAULT 1,
        CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
        CONSTRAINT PK_CarreraCursos PRIMARY KEY (CarreraCursoId),
        CONSTRAINT FK_CarreraCursos_Carrera FOREIGN KEY (CarreraId)
            REFERENCES core.Carreras(CarreraId),
        CONSTRAINT FK_CarreraCursos_Curso FOREIGN KEY (CursoId)
            REFERENCES academic.Cursos(CursoId),
        CONSTRAINT UK_CarreraCursos UNIQUE (CarreraId, CursoId, Semestre),
        CONSTRAINT CK_CarreraCursos_Semestre CHECK (Semestre > 0)
    );
    PRINT 'OK: Tabla academic.CarreraCursos creada.';
END
ELSE
    PRINT 'OK: academic.CarreraCursos ya existe.';
GO

-- =============================================
-- ESQUEMA: sales
-- =============================================

-- Tabla: sales.Promotores
-- Vendedores/promotores que captan estudiantes (RN-08).
IF OBJECT_ID(N'sales.Promotores', N'U') IS NULL
BEGIN
    CREATE TABLE sales.Promotores (
        PromotorId INT IDENTITY(1,1) NOT NULL,
        CodigoPromotor VARCHAR(10) NOT NULL,
        DNI VARCHAR(8) NOT NULL,
        Nombres NVARCHAR(100) NOT NULL,
        Apellidos NVARCHAR(100) NOT NULL,
        Email VARCHAR(100) NOT NULL,
        Telefono VARCHAR(15) NULL,
        Celular VARCHAR(15) NULL,
        SedeId INT NOT NULL,
        PorcentajeComision DECIMAL(5,2) NOT NULL DEFAULT 5.00,
        Activo BIT NOT NULL DEFAULT 1,
        CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
        UpdatedAt DATETIME NULL,
        DeletedAt DATETIME NULL,
        CONSTRAINT PK_Promotores PRIMARY KEY (PromotorId),
        CONSTRAINT FK_Promotores_Sede FOREIGN KEY (SedeId)
            REFERENCES core.Sedes(SedeId),
        CONSTRAINT UK_Promotores_Codigo UNIQUE (CodigoPromotor),
        CONSTRAINT UK_Promotores_DNI UNIQUE (DNI),
        CONSTRAINT UK_Promotores_Email UNIQUE (Email),
        CONSTRAINT CK_Promotores_DNI CHECK (LEN(DNI) = 8 AND DNI NOT LIKE '%[^0-9]%'),
        CONSTRAINT CK_Promotores_Email CHECK (Email LIKE '%@%'),
        CONSTRAINT CK_Promotores_Comision CHECK (PorcentajeComision >= 0 AND PorcentajeComision <= 100)
    );
    PRINT 'OK: Tabla sales.Promotores creada.';
END
ELSE
    PRINT 'OK: sales.Promotores ya existe.';
GO

-- Tabla: sales.CampaniasAdmision
-- Campanas de admision vinculadas a un periodo academico.
-- La comision vigente de cada matricula depende de la campana (RN-09).
IF OBJECT_ID(N'sales.CampaniasAdmision', N'U') IS NULL
BEGIN
    CREATE TABLE sales.CampaniasAdmision (
        CampaniaId INT IDENTITY(1,1) NOT NULL,
        CodigoCampania VARCHAR(20) NOT NULL,
        NombreCampania NVARCHAR(100) NOT NULL,
        Descripcion NVARCHAR(500) NULL,
        PeriodoId INT NOT NULL,
        FechaInicio DATE NOT NULL,
        FechaFin DATE NOT NULL,
        PorcentajeComisionBase DECIMAL(5,2) NOT NULL,
        BonoPorMeta DECIMAL(10,2) NULL,
        MetaMatriculas INT NULL,
        Activo BIT NOT NULL DEFAULT 1,
        CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
        UpdatedAt DATETIME NULL,
        CONSTRAINT PK_CampaniasAdmision PRIMARY KEY (CampaniaId),
        CONSTRAINT FK_CampaniasAdmision_Periodo FOREIGN KEY (PeriodoId)
            REFERENCES core.PeriodosAcademicos(PeriodoId),
        CONSTRAINT UK_CampaniasAdmision_Codigo UNIQUE (CodigoCampania),
        CONSTRAINT CK_CampaniasAdmision_Fechas CHECK (FechaFin > FechaInicio),
        CONSTRAINT CK_CampaniasAdmision_Comision CHECK (PorcentajeComisionBase >= 0 AND PorcentajeComisionBase <= 100)
    );
    PRINT 'OK: Tabla sales.CampaniasAdmision creada.';
END
ELSE
    PRINT 'OK: sales.CampaniasAdmision ya existe.';
GO

-- =============================================
-- ESQUEMA: core (tabla principal)
-- =============================================

-- Tabla: core.Matriculas
-- Registro de matricula. Reglas de negocio:
--  - Un estudiante no puede matricularse 2 veces en la misma
--    carrera y periodo (UK_Matriculas_EstudiantePeriodoCarrera - RN-02).
--  - Promotor y sede obligatorios (RN-08).
--  - Borrado logico con DeletedAt (RN-10).
IF OBJECT_ID(N'core.Matriculas', N'U') IS NULL
BEGIN
    CREATE TABLE core.Matriculas (
        MatriculaId INT IDENTITY(1,1) NOT NULL,
        CodigoMatricula VARCHAR(20) NOT NULL,
        EstudianteId INT NOT NULL,
        CarreraId INT NOT NULL,
        PeriodoId INT NOT NULL,
        SedeId INT NOT NULL,
        PromotorId INT NOT NULL,
        CampaniaId INT NULL,
        FechaMatricula DATETIME NOT NULL DEFAULT GETDATE(),
        MontoMatricula DECIMAL(10,2) NOT NULL,
        EstadoMatricula VARCHAR(20) NOT NULL DEFAULT 'Activa',
        Observaciones NVARCHAR(500) NULL,
        Activo BIT NOT NULL DEFAULT 1,
        CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
        UpdatedAt DATETIME NULL,
        DeletedAt DATETIME NULL,
        CONSTRAINT PK_Matriculas PRIMARY KEY (MatriculaId),
        CONSTRAINT FK_Matriculas_Estudiante FOREIGN KEY (EstudianteId)
            REFERENCES core.Estudiantes(EstudianteId),
        CONSTRAINT FK_Matriculas_Carrera FOREIGN KEY (CarreraId)
            REFERENCES core.Carreras(CarreraId),
        CONSTRAINT FK_Matriculas_Periodo FOREIGN KEY (PeriodoId)
            REFERENCES core.PeriodosAcademicos(PeriodoId),
        CONSTRAINT FK_Matriculas_Sede FOREIGN KEY (SedeId)
            REFERENCES core.Sedes(SedeId),
        CONSTRAINT FK_Matriculas_Promotor FOREIGN KEY (PromotorId)
            REFERENCES sales.Promotores(PromotorId),
        CONSTRAINT FK_Matriculas_Campania FOREIGN KEY (CampaniaId)
            REFERENCES sales.CampaniasAdmision(CampaniaId),
        CONSTRAINT UK_Matriculas_Codigo UNIQUE (CodigoMatricula),
        CONSTRAINT UK_Matriculas_EstudiantePeriodoCarrera UNIQUE (EstudianteId, CarreraId, PeriodoId),
        CONSTRAINT CK_Matriculas_Monto CHECK (MontoMatricula >= 0),
        CONSTRAINT CK_Matriculas_Estado CHECK (EstadoMatricula IN ('Activa','Retirada','Suspendida','Culminada'))
    );
    PRINT 'OK: Tabla core.Matriculas creada.';
END
ELSE
    PRINT 'OK: core.Matriculas ya existe.';
GO

-- Tabla: sales.Comisiones
-- Comision generada por cada matricula, calculada segun la
-- campana vigente (RN-09). Una matricula genera una sola comision.
IF OBJECT_ID(N'sales.Comisiones', N'U') IS NULL
BEGIN
    CREATE TABLE sales.Comisiones (
        ComisionId INT IDENTITY(1,1) NOT NULL,
        PromotorId INT NOT NULL,
        MatriculaId INT NOT NULL,
        CampaniaId INT NULL,
        MontoBase DECIMAL(10,2) NOT NULL,
        PorcentajeComision DECIMAL(5,2) NOT NULL,
        MontoComision DECIMAL(10,2) NOT NULL,
        Bonificacion DECIMAL(10,2) NULL DEFAULT 0,
        MontoTotal DECIMAL(10,2) NOT NULL,
        EstadoPago VARCHAR(20) NOT NULL DEFAULT 'Pendiente',
        FechaPago DATE NULL,
        Observaciones NVARCHAR(500) NULL,
        CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
        CONSTRAINT PK_Comisiones PRIMARY KEY (ComisionId),
        CONSTRAINT FK_Comisiones_Promotor FOREIGN KEY (PromotorId)
            REFERENCES sales.Promotores(PromotorId),
        CONSTRAINT FK_Comisiones_Matricula FOREIGN KEY (MatriculaId)
            REFERENCES core.Matriculas(MatriculaId),
        CONSTRAINT FK_Comisiones_Campania FOREIGN KEY (CampaniaId)
            REFERENCES sales.CampaniasAdmision(CampaniaId),
        CONSTRAINT UK_Comisiones_Matricula UNIQUE (MatriculaId),
        CONSTRAINT CK_Comisiones_Montos CHECK (MontoBase >= 0 AND MontoComision >= 0 AND MontoTotal >= 0),
        CONSTRAINT CK_Comisiones_Estado CHECK (EstadoPago IN ('Pendiente','Pagada','Anulada'))
    );
    PRINT 'OK: Tabla sales.Comisiones creada.';
END
ELSE
    PRINT 'OK: sales.Comisiones ya existe.';
GO

-- =============================================
-- ESQUEMA: academic (relacion docente)
-- =============================================

-- Tabla: academic.CursoProfesor
-- Asignacion de profesores a cursos por periodo y sede.
-- Un profesor puede dictar uno o muchos cursos (RN-05).
IF OBJECT_ID(N'academic.CursoProfesor', N'U') IS NULL
BEGIN
    CREATE TABLE academic.CursoProfesor (
        CursoProfesorId INT IDENTITY(1,1) NOT NULL,
        CursoId INT NOT NULL,
        ProfesorId INT NOT NULL,
        PeriodoId INT NOT NULL,
        SedeId INT NOT NULL,
        FechaAsignacion DATE NOT NULL DEFAULT GETDATE(),
        Activo BIT NOT NULL DEFAULT 1,
        CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
        CONSTRAINT PK_CursoProfesor PRIMARY KEY (CursoProfesorId),
        CONSTRAINT FK_CursoProfesor_Curso FOREIGN KEY (CursoId)
            REFERENCES academic.Cursos(CursoId),
        CONSTRAINT FK_CursoProfesor_Profesor FOREIGN KEY (ProfesorId)
            REFERENCES academic.Profesores(ProfesorId),
        CONSTRAINT FK_CursoProfesor_Periodo FOREIGN KEY (PeriodoId)
            REFERENCES core.PeriodosAcademicos(PeriodoId),
        CONSTRAINT FK_CursoProfesor_Sede FOREIGN KEY (SedeId)
            REFERENCES core.Sedes(SedeId),
        CONSTRAINT UK_CursoProfesor UNIQUE (CursoId, ProfesorId, PeriodoId, SedeId)
    );
    PRINT 'OK: Tabla academic.CursoProfesor creada.';
END
ELSE
    PRINT 'OK: academic.CursoProfesor ya existe.';
GO

-- =============================================
-- ESQUEMA: security
-- =============================================

-- Tabla: security.Roles
-- Perfiles de seguridad del sistema (RN-06):
-- Administrador, Coordinador Academico, Promotor y otros.
IF OBJECT_ID(N'security.Roles', N'U') IS NULL
BEGIN
    CREATE TABLE security.Roles (
        RolId INT IDENTITY(1,1) NOT NULL,
        NombreRol VARCHAR(50) NOT NULL,
        Descripcion NVARCHAR(200) NULL,
        Activo BIT NOT NULL DEFAULT 1,
        CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
        CONSTRAINT PK_Roles PRIMARY KEY (RolId),
        CONSTRAINT UK_Roles_Nombre UNIQUE (NombreRol)
    );
    PRINT 'OK: Tabla security.Roles creada.';
END
ELSE
    PRINT 'OK: security.Roles ya existe.';
GO

-- Tabla: security.Usuarios
-- Usuarios del sistema asociados a un rol
IF OBJECT_ID(N'security.Usuarios', N'U') IS NULL
BEGIN
    CREATE TABLE security.Usuarios (
        UsuarioId INT IDENTITY(1,1) NOT NULL,
        Username VARCHAR(50) NOT NULL,
        PasswordHash VARCHAR(255) NOT NULL,
        Email VARCHAR(100) NOT NULL,
        NombresCompletos NVARCHAR(150) NOT NULL,
        RolId INT NOT NULL,
        Activo BIT NOT NULL DEFAULT 1,
        UltimoAcceso DATETIME NULL,
        CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
        UpdatedAt DATETIME NULL,
        CONSTRAINT PK_Usuarios PRIMARY KEY (UsuarioId),
        CONSTRAINT FK_Usuarios_Rol FOREIGN KEY (RolId)
            REFERENCES security.Roles(RolId),
        CONSTRAINT UK_Usuarios_Username UNIQUE (Username),
        CONSTRAINT UK_Usuarios_Email UNIQUE (Email),
        CONSTRAINT CK_Usuarios_Email CHECK (Email LIKE '%@%')
    );
    PRINT 'OK: Tabla security.Usuarios creada.';
END
ELSE
    PRINT 'OK: security.Usuarios ya existe.';
GO

-- =============================================
-- ESQUEMA: audit
-- =============================================

-- Tabla: audit.AuditLog
-- Registro de auditoria de operaciones criticas (RN-07).
-- Los triggers del Sprint 2 registraran aqui cada INSERT/UPDATE/DELETE
-- con usuario, fecha, hora y operacion realizada.
IF OBJECT_ID(N'audit.AuditLog', N'U') IS NULL
BEGIN
    CREATE TABLE audit.AuditLog (
        AuditId BIGINT IDENTITY(1,1) NOT NULL,
        TableName VARCHAR(100) NOT NULL,
        Operation VARCHAR(10) NOT NULL,
        RecordId INT NOT NULL,
        Usuario VARCHAR(100) NOT NULL,
        FechaOperacion DATETIME NOT NULL DEFAULT GETDATE(),
        ValoresAnteriores NVARCHAR(MAX) NULL,
        ValoresNuevos NVARCHAR(MAX) NULL,
        DireccionIP VARCHAR(45) NULL,
        CONSTRAINT PK_AuditLog PRIMARY KEY (AuditId),
        CONSTRAINT CK_AuditLog_Operation CHECK (Operation IN ('INSERT','UPDATE','DELETE'))
    );
    PRINT 'OK: Tabla audit.AuditLog creada.';
END
ELSE
    PRINT 'OK: audit.AuditLog ya existe.';
GO

-- =============================================
-- INDICES DE RENDIMIENTO
-- =============================================
-- Justificacion: los indices aceleran las consultas mas frecuentes:
-- busqueda de estudiantes por apellido, matricula por estudiante/
-- periodo/promotor, comisiones por promotor y consultas de auditoria.
-- Las pruebas comparativas de rendimiento se documentaran en el
-- Sprint 3 (Optimizacion).

PRINT '';
PRINT 'Creando indices de optimizacion...';
GO

-- Busqueda de estudiantes por nombre (listados y reportes)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Estudiantes_Apellidos' AND object_id = OBJECT_ID('core.Estudiantes'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_Estudiantes_Apellidos
        ON core.Estudiantes(Apellidos, Nombres);
    PRINT 'OK: IX_Estudiantes_Apellidos.';
END
GO

-- Consultas que filtran estudiantes activos (borrado logico)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Estudiantes_DeletedAt' AND object_id = OBJECT_ID('core.Estudiantes'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_Estudiantes_DeletedAt
        ON core.Estudiantes(DeletedAt)
        WHERE DeletedAt IS NULL;
    PRINT 'OK: IX_Estudiantes_DeletedAt (filtrado).';
END
GO

-- Historial de matriculas por estudiante (incluye claves para evitar lookups)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Matriculas_Estudiante' AND object_id = OBJECT_ID('core.Matriculas'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_Matriculas_Estudiante
        ON core.Matriculas(EstudianteId)
        INCLUDE (CarreraId, PeriodoId, FechaMatricula);
    PRINT 'OK: IX_Matriculas_Estudiante.';
END
GO

-- Matriculas por periodo y sede (reporte de campaña)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Matriculas_Periodo' AND object_id = OBJECT_ID('core.Matriculas'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_Matriculas_Periodo
        ON core.Matriculas(PeriodoId, SedeId)
        INCLUDE (EstudianteId, CarreraId);
    PRINT 'OK: IX_Matriculas_Periodo.';
END
GO

-- Desempeno de promotores (matriculas por promotor y fecha)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Matriculas_Promotor' AND object_id = OBJECT_ID('core.Matriculas'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_Matriculas_Promotor
        ON core.Matriculas(PromotorId, FechaMatricula)
        INCLUDE (MontoMatricula, EstadoMatricula);
    PRINT 'OK: IX_Matriculas_Promotor.';
END
GO

-- Matriculas recientes (dashboard)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Matriculas_FechaMatricula' AND object_id = OBJECT_ID('core.Matriculas'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_Matriculas_FechaMatricula
        ON core.Matriculas(FechaMatricula DESC);
    PRINT 'OK: IX_Matriculas_FechaMatricula.';
END
GO

-- Matriculas activas (filtrar borrados logicos en consultas diarias)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Matriculas_Activas' AND object_id = OBJECT_ID('core.Matriculas'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_Matriculas_Activas
        ON core.Matriculas(DeletedAt)
        INCLUDE (EstudianteId, CarreraId, PeriodoId, SedeId, PromotorId)
        WHERE DeletedAt IS NULL;
    PRINT 'OK: IX_Matriculas_Activas (filtrado).';
END
GO

-- Comisiones por promotor y estado de pago (pago de comisiones)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Comisiones_Promotor' AND object_id = OBJECT_ID('sales.Comisiones'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_Comisiones_Promotor
        ON sales.Comisiones(PromotorId, EstadoPago)
        INCLUDE (MontoTotal, FechaPago);
    PRINT 'OK: IX_Comisiones_Promotor.';
END
GO

-- Comisiones pendientes por fecha (plan de pagos)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Comisiones_EstadoPago' AND object_id = OBJECT_ID('sales.Comisiones'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_Comisiones_EstadoPago
        ON sales.Comisiones(EstadoPago, FechaPago);
    PRINT 'OK: IX_Comisiones_EstadoPago.';
END
GO

-- Auditoria por entidad y fecha (RN-07)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_AuditLog_TableName' AND object_id = OBJECT_ID('audit.AuditLog'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_AuditLog_TableName
        ON audit.AuditLog(TableName, FechaOperacion DESC);
    PRINT 'OK: IX_AuditLog_TableName.';
END
GO

-- Auditoria por usuario (quien hizo que)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_AuditLog_Usuario' AND object_id = OBJECT_ID('audit.AuditLog'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_AuditLog_Usuario
        ON audit.AuditLog(Usuario, FechaOperacion DESC);
    PRINT 'OK: IX_AuditLog_Usuario.';
END
GO

-- Auditoria por fecha (consultas de trazabilidad)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_AuditLog_FechaOperacion' AND object_id = OBJECT_ID('audit.AuditLog'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_AuditLog_FechaOperacion
        ON audit.AuditLog(FechaOperacion DESC);
    PRINT 'OK: IX_AuditLog_FechaOperacion.';
END
GO

-- Malla curricular por carrera (reportes academicos)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_CarreraCursos_Carrera' AND object_id = OBJECT_ID('academic.CarreraCursos'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_CarreraCursos_Carrera
        ON academic.CarreraCursos(CarreraId, Semestre);
    PRINT 'OK: IX_CarreraCursos_Carrera.';
END
GO

-- Cursos asignados por profesor y periodo
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_CursoProfesor_Profesor' AND object_id = OBJECT_ID('academic.CursoProfesor'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_CursoProfesor_Profesor
        ON academic.CursoProfesor(ProfesorId, PeriodoId);
    PRINT 'OK: IX_CursoProfesor_Profesor.';
END
GO

-- =============================================
-- RESUMEN
-- =============================================
PRINT '';
PRINT '============================================';
PRINT 'RESUMEN DE OBJETOS CREADOS:';
PRINT '============================================';
PRINT '  Esquema [core]     : Sedes, Carreras, Estudiantes,';
PRINT '                       PeriodosAcademicos, Matriculas';
PRINT '  Esquema [academic] : Profesores, Cursos, CarreraCursos,';
PRINT '                       CursoProfesor';
PRINT '  Esquema [sales]    : Promotores, CampaniasAdmision, Comisiones';
PRINT '  Esquema [security] : Roles, Usuarios';
PRINT '  Esquema [audit]    : AuditLog';
PRINT '--------------------------------------------';
PRINT '  Total tablas      : 15';
PRINT '  Foreign Keys      : 18';
PRINT '  Unique Constraints: 20';
PRINT '  Check Constraints : 26';
PRINT '  Indices no agrup. : 14';
PRINT '============================================';
GO
