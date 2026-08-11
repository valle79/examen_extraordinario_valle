-- =============================================
-- Matricula Cloud 360 Enterprise
-- 01_seed_data.sql | Datos iniciales (seed)
-- =============================================
-- Descripcion: Carga los datos iniciales del catalogo del cliente.
--
-- IDEMPOTENTE: cada bloque inserta solo si la tabla esta vacia
-- (verificado por su primer registro). Puede ejecutarse varias veces.
-- =============================================

USE MatriculaCloud360DB;
GO

PRINT '============================================';
PRINT '01_seed_data.sql - Carga de datos iniciales';
PRINT '============================================';
GO

-- =============================================
-- 1. UBIGEOS (11)
-- Tabla de ayuda: codigos oficiales RENIEC.
-- =============================================
IF NOT EXISTS (SELECT 1 FROM core.Ubigeos WHERE CodigoUbigeo = '150101')
BEGIN
    SET IDENTITY_INSERT core.Ubigeos ON;
    INSERT INTO core.Ubigeos (UbigeoId, CodigoUbigeo, Departamento, Provincia, Distrito)
    VALUES
        (1,  '150101', 'Lima',        'Lima',        'Lima'),
        (2,  '150103', 'Lima',        'Lima',        'Ate'),
        (3,  '150115', 'Lima',        'Lima',        'La Victoria'),
        (4,  '150117', 'Lima',        'Lima',        'Los Olivos'),
        (5,  '150131', 'Lima',        'Lima',        'San Juan de Lurigancho'),
        (6,  '150141', 'Lima',        'Lima',        'Villa El Salvador'),
        (7,  '040101', 'Arequipa',    'Arequipa',    'Arequipa'),
        (8,  '080101', 'Cusco',       'Cusco',       'Cusco'),
        (9,  '130101', 'La Libertad', 'Trujillo',    'Trujillo'),
        (10, '140101', 'Lambayeque',  'Chiclayo',    'Chiclayo'),
        (11, '160101', 'Loreto',      'Maynas',      'Iquitos');
    SET IDENTITY_INSERT core.Ubigeos OFF;
    PRINT 'OK: 11 ubigeos insertados.';
END
ELSE
    PRINT 'OK: Ubigeos ya cargados (se omite).';
GO

-- =============================================
-- 2. SEDES (5)
-- =============================================
IF NOT EXISTS (SELECT 1 FROM core.Sedes WHERE CodigoSede = 'SEDE-LIM')
BEGIN
    SET IDENTITY_INSERT core.Sedes ON;
    INSERT INTO core.Sedes (SedeId, CodigoSede, NombreSede, Direccion, UbigeoId, Telefono, Email)
    VALUES
        (1, 'SEDE-LIM', 'Sede Lima Centro', 'Av. Arequipa 1234', 1, '014567890', 'lima@edufuturo.edu.pe'),
        (2, 'SEDE-ATE', 'Sede Ate Vitarte', 'Av. Separadora Industrial 2345', 2, '013456789', 'ate@edufuturo.edu.pe'),
        (3, 'SEDE-CUS', 'Sede Cusco', 'Av. El Sol 456', 8, '084234567', 'cusco@edufuturo.edu.pe'),
        (4, 'SEDE-ARQ', 'Sede Arequipa', 'Calle Mercaderes 789', 7, '054345678', 'arequipa@edufuturo.edu.pe'),
        (5, 'SEDE-TRU', 'Sede Trujillo', 'Av. Espana 321', 9, '044456789', 'trujillo@edufuturo.edu.pe');
    SET IDENTITY_INSERT core.Sedes OFF;
    PRINT 'OK: 5 sedes insertadas.';
END
ELSE
    PRINT 'OK: Sedes ya cargadas (se omite).';
GO

-- =============================================
-- 3. CARRERAS (7)
-- =============================================
IF NOT EXISTS (SELECT 1 FROM core.Carreras WHERE CodigoCarrera = 'ING-SIS')
BEGIN
    SET IDENTITY_INSERT core.Carreras ON;
    INSERT INTO core.Carreras (CarreraId, CodigoCarrera, NombreCarrera, Descripcion, DuracionSemestres, CostoMatricula, CostoPensionMensual)
    VALUES
        (1, 'ING-SIS', 'Ingenieria de Sistemas', 'Desarrollo de software y gestion de tecnologias de informacion', 10, 250.00, 450.00),
        (2, 'ING-IND', 'Ingenieria Industrial', 'Optimizacion de procesos productivos y gestion empresarial', 10, 250.00, 420.00),
        (3, 'ADM-EMP', 'Administracion de Empresas', 'Gestion y direccion de organizaciones empresariales', 10, 220.00, 380.00),
        (4, 'CONT-FIN', 'Contabilidad y Finanzas', 'Gestion contable, financiera y tributaria', 10, 220.00, 360.00),
        (5, 'MKT-DIG', 'Marketing Digital', 'Estrategias de marketing en entornos digitales', 8, 200.00, 340.00),
        (6, 'ENF-TEC', 'Enfermeria Tecnica', 'Cuidado de la salud y atencion al paciente', 6, 280.00, 420.00),
        (7, 'GAS-TUR', 'Gastronomia y Turismo', 'Arte culinario y gestion turistica', 6, 300.00, 480.00);
    SET IDENTITY_INSERT core.Carreras OFF;
    PRINT 'OK: 7 carreras insertadas.';
END
ELSE
    PRINT 'OK: Carreras ya cargadas (se omite).';
GO

-- =============================================
-- 4. PERIODOS ACADEMICOS (5)
-- El periodo 2027-I mantiene su ventana de matriculas VIGENTE
-- (2026-08-01 a 2026-10-15) para que el sistema tenga un periodo
-- habilitado en el que se puedan registrar matriculas via
-- core.usp_RegistrarMatricula (RN-03).
-- =============================================
IF NOT EXISTS (SELECT 1 FROM core.PeriodosAcademicos WHERE CodigoPeriodo = '2025-1')
BEGIN
    SET IDENTITY_INSERT core.PeriodosAcademicos ON;
    INSERT INTO core.PeriodosAcademicos (PeriodoId, CodigoPeriodo, NombrePeriodo, Anio, Semestre, FechaInicio, FechaFin, FechaInicioMatriculas, FechaFinMatriculas)
    VALUES
        (1, '2025-1', 'Periodo 2025-I', 2025, 1, '2025-03-01', '2025-07-31', '2025-01-15', '2025-02-28'),
        (2, '2025-2', 'Periodo 2025-II', 2025, 2, '2025-08-01', '2025-12-20', '2025-06-15', '2025-07-31'),
        (3, '2026-1', 'Periodo 2026-I', 2026, 1, '2026-03-01', '2026-07-31', '2026-01-15', '2026-02-28'),
        (4, '2026-2', 'Periodo 2026-II', 2026, 2, '2026-08-01', '2026-12-20', '2026-06-15', '2026-07-31'),
        (5, '2027-1', 'Periodo 2027-I', 2027, 1, '2027-03-01', '2027-07-31', '2026-08-01', '2026-10-15');
    SET IDENTITY_INSERT core.PeriodosAcademicos OFF;
    PRINT 'OK: 5 periodos academicos insertados.';
END
ELSE
    PRINT 'OK: Periodos ya cargados (se omite).';
GO

-- =============================================
-- 5. ESPECIALIDADES (10)
-- =============================================
IF NOT EXISTS (SELECT 1 FROM academic.Especialidades WHERE NombreEspecialidad = 'Ingenieria de Software')
BEGIN
    SET IDENTITY_INSERT academic.Especialidades ON;
    INSERT INTO academic.Especialidades (EspecialidadId, NombreEspecialidad, Descripcion)
    VALUES
        (1,  'Ingenieria de Software', 'Diseno y desarrollo de sistemas de software'),
        (2,  'Base de Datos', 'Modelado, administracion y optimizacion de bases de datos'),
        (3,  'Redes y Comunicaciones', 'Infraestructura de redes y telecomunicaciones'),
        (4,  'Gestion Empresarial', 'Administracion y gestion de organizaciones'),
        (5,  'Matematica Aplicada', 'Matematicas aplicadas a la ingenieria'),
        (6,  'Contabilidad', 'Contabilidad financiera y costos'),
        (7,  'Marketing', 'Estrategias de marketing y ventas'),
        (8,  'Enfermeria', 'Cuidado de la salud y atencion al paciente'),
        (9,  'Gastronomia', 'Arte culinario y gestion de cocina'),
        (10, 'Gestion de Proyectos', 'Planificacion y direccion de proyectos');
    SET IDENTITY_INSERT academic.Especialidades OFF;
    PRINT 'OK: 10 especialidades insertadas.';
END
ELSE
    PRINT 'OK: Especialidades ya cargadas (se omite).';
GO

-- =============================================
-- 6. PROFESORES (10)
-- =============================================
IF NOT EXISTS (SELECT 1 FROM academic.Profesores WHERE NumeroDocumento = '12345678')
BEGIN
    SET IDENTITY_INSERT academic.Profesores ON;
    INSERT INTO academic.Profesores (ProfesorId, TipoDocumento, NumeroDocumento, Nombres, Apellidos, Email, Celular, EspecialidadId, GradoAcademico)
    VALUES
        (1, 'DNI', '12345678', 'Carlos Alberto', 'Rodriguez Sanchez', 'carlos.rodriguez@edufuturo.edu.pe', '987654321', 1, 'Magister'),
        (2, 'DNI', '23456789', 'Maria Fernanda', 'Garcia Lopez', 'maria.garcia@edufuturo.edu.pe', '987654322', 2, 'Magister'),
        (3, 'DNI', '34567890', 'Jose Luis', 'Martinez Torres', 'jose.martinez@edufuturo.edu.pe', '987654323', 3, 'Doctor'),
        (4, 'DNI', '45678901', 'Ana Patricia', 'Flores Vega', 'ana.flores@edufuturo.edu.pe', '987654324', 4, 'Magister'),
        (5, 'DNI', '56789012', 'Roberto Carlos', 'Diaz Mendoza', 'roberto.diaz@edufuturo.edu.pe', '987654325', 5, 'Magister'),
        (6, 'DNI', '67890123', 'Carmen Rosa', 'Huaman Quispe', 'carmen.huaman@edufuturo.edu.pe', '987654326', 6, 'Licenciado'),
        (7, 'DNI', '78901234', 'Fernando Miguel', 'Castro Rojas', 'fernando.castro@edufuturo.edu.pe', '987654327', 7, 'Magister'),
        (8, 'DNI', '89012345', 'Lucia Beatriz', 'Paredes Silva', 'lucia.paredes@edufuturo.edu.pe', '987654328', 8, 'Licenciado'),
        (9, 'DNI', '90123456', 'Diego Alejandro', 'Vargas Leon', 'diego.vargas@edufuturo.edu.pe', '987654329', 9, 'Licenciado'),
        (10, 'CE', '0123456789012', 'Patricia Elena', 'Ramos Cruz', 'patricia.ramos@edufuturo.edu.pe', '987654330', 10, 'Doctor');
    SET IDENTITY_INSERT academic.Profesores OFF;
    PRINT 'OK: 10 profesores insertados.';
END
ELSE
    PRINT 'OK: Profesores ya cargados (se omite).';
GO

-- =============================================
-- 7. CURSOS (10)
-- =============================================
IF NOT EXISTS (SELECT 1 FROM academic.Cursos WHERE CodigoCurso = 'MAT-101')
BEGIN
    SET IDENTITY_INSERT academic.Cursos ON;
    INSERT INTO academic.Cursos (CursoId, CodigoCurso, NombreCurso, Descripcion, Creditos, HorasTeoria, HorasPractica)
    VALUES
        (1, 'MAT-101', 'Matematica Basica', 'Fundamentos de matematica para ingenieria', 4, 3, 2),
        (2, 'PRO-101', 'Fundamentos de Programacion', 'Introduccion a la programacion estructurada', 5, 3, 4),
        (3, 'BDD-201', 'Base de Datos I', 'Diseno y modelado de bases de datos relacionales', 4, 2, 4),
        (4, 'BDD-202', 'Base de Datos II', 'Administracion y optimizacion de bases de datos', 4, 2, 4),
        (5, 'WEB-301', 'Desarrollo Web', 'Desarrollo de aplicaciones web modernas', 5, 2, 6),
        (6, 'ADM-101', 'Administracion General', 'Principios basicos de administracion', 3, 3, 0),
        (7, 'CON-101', 'Contabilidad General', 'Fundamentos de contabilidad financiera', 4, 3, 2),
        (8, 'MKT-101', 'Marketing Fundamental', 'Conceptos basicos de marketing', 3, 3, 0),
        (9, 'ENF-101', 'Anatomia y Fisiologia', 'Estudio del cuerpo humano', 4, 4, 2),
        (10, 'GAS-101', 'Tecnicas Culinarias Basicas', 'Fundamentos de cocina', 4, 2, 4);
    SET IDENTITY_INSERT academic.Cursos OFF;
    PRINT 'OK: 10 cursos insertados.';
END
ELSE
    PRINT 'OK: Cursos ya cargados (se omite).';
GO

-- =============================================
-- 8. MALLA CURRICULAR: CARRERA-CURSOS (20)
-- =============================================
IF NOT EXISTS (SELECT 1 FROM academic.CarreraCursos WHERE CarreraCursoId = 1)
BEGIN
    SET IDENTITY_INSERT academic.CarreraCursos ON;
    INSERT INTO academic.CarreraCursos (CarreraCursoId, CarreraId, CursoId, Semestre)
    VALUES
        -- Ingenieria de Sistemas
        (1, 1, 1, 1),
        (2, 1, 2, 1),
        (3, 1, 3, 3),
        (4, 1, 4, 4),
        (5, 1, 5, 5),
        -- Ingenieria Industrial
        (17, 2, 1, 1),
        (18, 2, 6, 1),
        (19, 2, 7, 2),
        (20, 2, 8, 3),
        -- Administracion de Empresas (comparte Matematica con Sistemas)
        (6, 3, 1, 1),
        (7, 3, 6, 1),
        (8, 3, 7, 2),
        (9, 3, 8, 3),
        -- Contabilidad y Finanzas
        (10, 4, 1, 1),
        (11, 4, 7, 1),
        (12, 4, 6, 2),
        -- Marketing Digital
        (13, 5, 8, 1),
        (14, 5, 5, 2),
        -- Enfermeria Tecnica
        (15, 6, 9, 1),
        -- Gastronomia y Turismo
        (16, 7, 10, 1);
    SET IDENTITY_INSERT academic.CarreraCursos OFF;
    PRINT 'OK: 20 relaciones carrera-curso insertadas.';
END
ELSE
    PRINT 'OK: CarreraCursos ya cargados (se omite).';
GO

-- =============================================
-- 9. PROMOTORES (6)
-- =============================================
IF NOT EXISTS (SELECT 1 FROM sales.Promotores WHERE CodigoPromotor = 'PROM-001')
BEGIN
    SET IDENTITY_INSERT sales.Promotores ON;
    INSERT INTO sales.Promotores (PromotorId, CodigoPromotor, TipoDocumento, NumeroDocumento, Nombres, Apellidos, Email, Celular, SedeId, PorcentajeComision)
    VALUES
        (1, 'PROM-001', 'DNI', '11111111', 'Juan Carlos', 'Perez Gutierrez', 'juan.perez@edufuturo.edu.pe', '999888777', 1, 8.00),
        (2, 'PROM-002', 'DNI', '22222222', 'Maria Isabel', 'Lopez Ramirez', 'maria.lopez@edufuturo.edu.pe', '999888778', 1, 7.50),
        (3, 'PROM-003', 'DNI', '33333333', 'Pedro Antonio', 'Gonzalez Silva', 'pedro.gonzalez@edufuturo.edu.pe', '999888779', 2, 7.00),
        (4, 'PROM-004', 'DNI', '44444444', 'Sofia Alejandra', 'Torres Medina', 'sofia.torres@edufuturo.edu.pe', '999888780', 3, 8.50),
        (5, 'PROM-005', 'DNI', '55555555', 'Luis Fernando', 'Sanchez Vega', 'luis.sanchez@edufuturo.edu.pe', '999888781', 4, 7.50),
        (6, 'PROM-006', 'CE', '777777777777', 'Andrea Gabriela', 'Morales Castro', 'andrea.morales@edufuturo.edu.pe', '999888782', 5, 8.00);
    SET IDENTITY_INSERT sales.Promotores OFF;
    PRINT 'OK: 6 promotores insertados.';
END
ELSE
    PRINT 'OK: Promotores ya cargados (se omite).';
GO

-- =============================================
-- 10. CAMPANAS DE ADMISION (5)
-- Cada campana esta vinculada a su periodo academico (RN-09).
-- =============================================
IF NOT EXISTS (SELECT 1 FROM sales.CampaniasAdmision WHERE CodigoCampania = 'CAMP-2025-1')
BEGIN
    SET IDENTITY_INSERT sales.CampaniasAdmision ON;
    INSERT INTO sales.CampaniasAdmision (CampaniaId, CodigoCampania, NombreCampania, Descripcion, PeriodoId, FechaInicio, FechaFin, PorcentajeComisionBase, BonoPorMeta, MetaMatriculas)
    VALUES
        (1, 'CAMP-2025-1', 'Campana Verano 2025', 'Campana de admision periodo 2025-I', 1, '2025-01-01', '2025-02-28', 10.00, 500.00, 50),
        (2, 'CAMP-2025-2', 'Campana Invierno 2025', 'Campana de admision periodo 2025-II', 2, '2025-06-01', '2025-07-31', 10.00, 500.00, 50),
        (3, 'CAMP-2026-1', 'Campana Verano 2026', 'Campana de admision periodo 2026-I', 3, '2026-01-01', '2026-02-28', 12.00, 600.00, 60),
        (4, 'CAMP-2026-2', 'Campana Invierno 2026', 'Campana de admision periodo 2026-II', 4, '2026-06-01', '2026-07-31', 12.00, 600.00, 60),
        (5, 'CAMP-2027-1', 'Campana Pre-Admision 2027', 'Campana de admision anticipada periodo 2027-I', 5, '2026-08-01', '2026-10-15', 12.00, 600.00, 60);
    SET IDENTITY_INSERT sales.CampaniasAdmision OFF;
    PRINT 'OK: 5 campanas de admision insertadas.';
END
ELSE
    PRINT 'OK: Campanias ya cargadas (se omite).';
GO

-- =============================================
-- 11. ESTUDIANTES (10)
-- =============================================
IF NOT EXISTS (SELECT 1 FROM core.Estudiantes WHERE NumeroDocumento = '70123456')
BEGIN
    SET IDENTITY_INSERT core.Estudiantes ON;
    INSERT INTO core.Estudiantes (EstudianteId, TipoDocumento, NumeroDocumento, Nombres, Apellidos, Email, Celular, FechaNacimiento, Genero, Direccion, UbigeoId)
    VALUES
        (1, 'DNI', '70123456', 'Carlos Andres', 'Mendoza Rios', 'cmendoza@gmail.com', '987111222', '2004-05-15', 'M', 'Jr. Las Flores 123', 5),
        (2, 'DNI', '70234567', 'Ana Lucia', 'Fernandez Cruz', 'afernandez@gmail.com', '987111223', '2003-08-22', 'F', 'Av. Los Alamos 456', 4),
        (3, 'DNI', '70345678', 'Miguel Angel', 'Vargas Salazar', 'mvargas@gmail.com', '987111224', '2004-11-10', 'M', 'Calle Los Pinos 789', 6),
        (4, 'DNI', '70456789', 'Gabriela Maria', 'Rojas Flores', 'grojas@gmail.com', '987111225', '2003-03-18', 'F', 'Av. Industrial 321', 2),
        (5, 'DNI', '70567890', 'Jose Luis', 'Castro Paredes', 'jcastro@gmail.com', '987111226', '2004-07-25', 'M', 'Jr. Comercio 654', 3),
        (6, 'DNI', '70678901', 'Daniela Sofia', 'Huaman Leon', 'dhuaman@gmail.com', '987111227', '2003-12-05', 'F', 'Av. Principal 987', 8),
        (7, 'DNI', '70789012', 'Fernando Jesus', 'Quispe Mamani', 'fquispe@gmail.com', '987111228', '2004-02-14', 'M', 'Calle Real 147', 7),
        (8, 'DNI', '70890123', 'Valeria Cristina', 'Diaz Soto', 'vdiaz@gmail.com', '987111229', '2003-09-30', 'F', 'Jr. Union 258', 9),
        (9, 'DNI', '70901234', 'Ricardo Manuel', 'Silva Ramirez', 'rsilva@gmail.com', '987111230', '2004-06-12', 'M', 'Av. Grau 369', 10),
        (10, 'CE', '601234567890', 'Isabella Nicole', 'Torres Vega', 'itorres@gmail.com', '987111231', '2003-04-08', 'F', 'Calle Lima 741', 11);
    SET IDENTITY_INSERT core.Estudiantes OFF;
    PRINT 'OK: 10 estudiantes insertados.';
END
ELSE
    PRINT 'OK: Estudiantes ya cargados (se omite).';
GO

-- =============================================
-- 12. MATRICULAS (10)
-- Todas corresponden al periodo 2026-I (PeriodoId=3), campana CAMP-2026-1
-- (CampaniaId=3) y dentro de la ventana de matricula del periodo.
-- =============================================
IF NOT EXISTS (SELECT 1 FROM core.Matriculas WHERE CodigoMatricula = 'MAT-2026-000001')
BEGIN
    SET IDENTITY_INSERT core.Matriculas ON;
    INSERT INTO core.Matriculas (MatriculaId, CodigoMatricula, EstudianteId, CarreraId, PeriodoId, SedeId, PromotorId, CampaniaId, FechaMatricula, MontoMatricula, EstadoMatricula)
    VALUES
        (1, 'MAT-2026-000001', 1, 1, 3, 1, 1, 3, '2026-01-20 10:30:00', 250.00, 'Activa'),
        (2, 'MAT-2026-000002', 2, 1, 3, 1, 1, 3, '2026-01-22 11:15:00', 250.00, 'Activa'),
        (3, 'MAT-2026-000003', 3, 2, 3, 2, 3, 3, '2026-01-25 14:20:00', 250.00, 'Activa'),
        (4, 'MAT-2026-000004', 4, 3, 3, 2, 3, 3, '2026-02-01 09:45:00', 220.00, 'Activa'),
        (5, 'MAT-2026-000005', 5, 4, 3, 1, 2, 3, '2026-02-03 16:00:00', 220.00, 'Activa'),
        (6, 'MAT-2026-000006', 6, 5, 3, 3, 4, 3, '2026-02-05 10:30:00', 200.00, 'Activa'),
        (7, 'MAT-2026-000007', 7, 6, 3, 4, 5, 3, '2026-02-07 13:15:00', 280.00, 'Activa'),
        (8, 'MAT-2026-000008', 8, 7, 3, 5, 6, 3, '2026-02-10 15:45:00', 300.00, 'Activa'),
        (9, 'MAT-2026-000009', 9, 1, 3, 1, 1, 3, '2026-02-12 11:00:00', 250.00, 'Activa'),
        (10, 'MAT-2026-000010', 10, 3, 3, 1, 2, 3, '2026-02-15 14:30:00', 220.00, 'Activa');
    SET IDENTITY_INSERT core.Matriculas OFF;
    PRINT 'OK: 10 matriculas insertadas.';
END
ELSE
    PRINT 'OK: Matriculas ya cargadas (se omite).';
GO

-- =============================================
-- 13. ROLES DE SEGURIDAD (5)
-- =============================================
IF NOT EXISTS (SELECT 1 FROM security.Roles WHERE NombreRol = 'Administrador')
BEGIN
    SET IDENTITY_INSERT security.Roles ON;
    INSERT INTO security.Roles (RolId, NombreRol, Descripcion)
    VALUES
        (1, 'Administrador', 'Acceso completo al sistema'),
        (2, 'Coordinador Academico', 'Gestion academica y reportes'),
        (3, 'Promotor', 'Registro de estudiantes y consulta de comisiones'),
        (4, 'Secretaria', 'Consulta y gestion de matriculas'),
        (5, 'Director', 'Acceso a reportes y dashboards');
    SET IDENTITY_INSERT security.Roles OFF;
    PRINT 'OK: 5 roles de seguridad insertados.';
END
ELSE
    PRINT 'OK: Roles ya cargados (se omite).';
GO

-- =============================================
-- 15. USUARIOS DEL SISTEMA (5)
-- =============================================
-- 14. USUARIOS DEL SISTEMA (5)
-- Las contrasenas se almacenan como hash SHA2-256 de
-- "Clave#2026" (solo para propositos de desarrollo).
-- =============================================
IF NOT EXISTS (SELECT 1 FROM security.Usuarios WHERE Username = 'admin')
BEGIN
    SET IDENTITY_INSERT security.Usuarios ON;
    INSERT INTO security.Usuarios (UsuarioId, Username, PasswordHash, Email, NombresCompletos, RolId)
    VALUES
        (1, 'admin', HASHBYTES('SHA2_256', 'Admin#2026'), 'admin@edufuturo.edu.pe', 'Administrador del Sistema', 1),
        (2, 'coord_acad', HASHBYTES('SHA2_256', 'Coord#2026'), 'coordinador@edufuturo.edu.pe', 'Coordinador Academico Principal', 2),
        (3, 'prom_juan', HASHBYTES('SHA2_256', 'Promo#2026'), 'juan.perez@edufuturo.edu.pe', 'Juan Carlos Perez Gutierrez', 3),
        (4, 'prom_maria', HASHBYTES('SHA2_256', 'Promo#2026'), 'maria.lopez@edufuturo.edu.pe', 'Maria Isabel Lopez Ramirez', 3),
        (5, 'secretaria1', HASHBYTES('SHA2_256', 'Secre#2026'), 'secretaria@edufuturo.edu.pe', 'Rosa Maria Gomez Torres', 4);
    SET IDENTITY_INSERT security.Usuarios OFF;
    PRINT 'OK: 5 usuarios del sistema insertados.';
END
ELSE
    PRINT 'OK: Usuarios ya cargados (se omite).';
GO

-- =============================================
-- 15. ASIGNACIONES CURSO-PROFESOR (10)
-- Periodo 2026-I en las sedes correspondientes.
-- =============================================
IF NOT EXISTS (SELECT 1 FROM academic.CursoProfesor WHERE CursoProfesorId = 1)
BEGIN
    SET IDENTITY_INSERT academic.CursoProfesor ON;
    INSERT INTO academic.CursoProfesor (CursoProfesorId, CursoId, ProfesorId, PeriodoId, SedeId, FechaAsignacion)
    VALUES
        (1, 1, 5, 3, 1, '2026-01-10'),
        (2, 2, 1, 3, 1, '2026-01-10'),
        (3, 3, 2, 3, 1, '2026-01-10'),
        (4, 4, 2, 3, 1, '2026-01-10'),
        (5, 5, 1, 3, 1, '2026-01-10'),
        (6, 6, 4, 3, 1, '2026-01-10'),
        (7, 7, 6, 3, 1, '2026-01-10'),
        (8, 8, 7, 3, 1, '2026-01-10'),
        (9, 9, 8, 3, 3, '2026-01-10'),
        (10, 10, 9, 3, 5, '2026-01-10');
    SET IDENTITY_INSERT academic.CursoProfesor OFF;
    PRINT 'OK: 10 asignaciones curso-profesor insertadas.';
END
ELSE
    PRINT 'OK: CursoProfesor ya cargado (se omite).';
GO

-- =============================================
-- VERIFICACION FINAL DE LA CARGA
-- =============================================
PRINT '';
PRINT '============================================';
PRINT 'RESUMEN DE DATOS CARGADOS:';
PRINT '============================================';
GO

SELECT
    'core.Ubigeos'             AS Tabla, COUNT(*) AS Registros FROM core.Ubigeos
UNION ALL SELECT 'core.Sedes',              COUNT(*) FROM core.Sedes
UNION ALL SELECT 'core.Carreras',           COUNT(*) FROM core.Carreras
UNION ALL SELECT 'core.PeriodosAcademicos', COUNT(*) FROM core.PeriodosAcademicos
UNION ALL SELECT 'core.Estudiantes',        COUNT(*) FROM core.Estudiantes
UNION ALL SELECT 'core.Matriculas',         COUNT(*) FROM core.Matriculas
UNION ALL SELECT 'academic.Especialidades', COUNT(*) FROM academic.Especialidades
UNION ALL SELECT 'academic.Profesores',     COUNT(*) FROM academic.Profesores
UNION ALL SELECT 'academic.Cursos',         COUNT(*) FROM academic.Cursos
UNION ALL SELECT 'academic.CarreraCursos',  COUNT(*) FROM academic.CarreraCursos
UNION ALL SELECT 'academic.CursoProfesor',  COUNT(*) FROM academic.CursoProfesor
UNION ALL SELECT 'sales.Promotores',        COUNT(*) FROM sales.Promotores
UNION ALL SELECT 'sales.CampaniasAdmision', COUNT(*) FROM sales.CampaniasAdmision
UNION ALL SELECT 'sales.Comisiones',        COUNT(*) FROM sales.Comisiones
UNION ALL SELECT 'security.Roles',          COUNT(*) FROM security.Roles
UNION ALL SELECT 'security.Usuarios',       COUNT(*) FROM security.Usuarios
UNION ALL SELECT 'audit.AuditLog',          COUNT(*) FROM audit.AuditLog
ORDER BY Tabla;
GO

PRINT '============================================';
PRINT 'Carga de datos finalizada correctamente.';
PRINT '============================================';
GO
