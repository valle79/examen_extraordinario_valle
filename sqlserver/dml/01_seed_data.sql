-- =============================================
-- Matricula Cloud 360 Enterprise
-- 01_seed_data.sql | Datos iniciales (seed)
-- =============================================
-- Descripcion: Carga los datos iniciales del catalogo del cliente.
-- Cada tabla del modelo de negocio tiene AL MENOS 20 registros
-- (requisito del cliente: "minimo 20 lineas por tabla").
--
-- IDEMPOTENTE: cada fila se inserta solo si no existe
-- (INSERT ... WHERE NOT EXISTS). Puede ejecutarse varias veces.
-- =============================================

USE MatriculaCloud360DB;
GO

PRINT '============================================';
PRINT '01_seed_data.sql - Carga de datos iniciales';
PRINT '============================================';
GO

-- =============================================
-- 1. UBIGEOS (20)
-- Tabla de ayuda: codigos oficiales RENIEC.
-- =============================================
IF (SELECT COUNT(*) FROM core.Ubigeos) < 20
BEGIN
    SET IDENTITY_INSERT core.Ubigeos ON;
    INSERT INTO core.Ubigeos (UbigeoId, CodigoUbigeo, Departamento, Provincia, Distrito)
    SELECT v.UbigeoId, v.CodigoUbigeo, v.Departamento, v.Provincia, v.Distrito
    FROM (VALUES
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
        (11, '160101', 'Loreto',      'Maynas',      'Iquitos'),
        (12, '150104', 'Lima',        'Lima',        'Barranco'),
        (13, '150108', 'Lima',        'Lima',        'Comas'),
        (14, '150132', 'Lima',        'Lima',        'San Miguel'),
        (15, '150140', 'Lima',        'Lima',        'Miraflores'),
        (16, '200101', 'Piura',       'Piura',       'Piura'),
        (17, '110101', 'Ica',         'Ica',         'Ica'),
        (18, '120101', 'Junin',       'Huancayo',    'Huancayo'),
        (19, '230101', 'Tacna',       'Tacna',       'Tacna'),
        (20, '220101', 'San Martin',  'Moyobamba',   'Moyobamba')
    ) v(UbigeoId, CodigoUbigeo, Departamento, Provincia, Distrito)
    WHERE NOT EXISTS (SELECT 1 FROM core.Ubigeos u WHERE u.CodigoUbigeo = v.CodigoUbigeo);
    SET IDENTITY_INSERT core.Ubigeos OFF;
    PRINT 'OK: 20 ubigeos insertados.';
END
ELSE
    PRINT 'OK: Ubigeos ya cargados (20).';
GO

-- =============================================
-- 2. SEDES (20)
-- =============================================
IF (SELECT COUNT(*) FROM core.Sedes) < 20
BEGIN
    SET IDENTITY_INSERT core.Sedes ON;
    INSERT INTO core.Sedes (SedeId, CodigoSede, NombreSede, Direccion, UbigeoId, Telefono, Email)
    SELECT v.SedeId, v.CodigoSede, v.NombreSede, v.Direccion, v.UbigeoId, v.Telefono, v.Email
    FROM (VALUES
        (1, 'SEDE-LIM', 'Sede Lima Centro', 'Av. Arequipa 1234', 1, '014567890', 'lima@edufuturo.edu.pe'),
        (2, 'SEDE-ATE', 'Sede Ate Vitarte', 'Av. Separadora Industrial 2345', 2, '013456789', 'ate@edufuturo.edu.pe'),
        (3, 'SEDE-CUS', 'Sede Cusco', 'Av. El Sol 456', 8, '084234567', 'cusco@edufuturo.edu.pe'),
        (4, 'SEDE-ARQ', 'Sede Arequipa', 'Calle Mercaderes 789', 7, '054345678', 'arequipa@edufuturo.edu.pe'),
        (5, 'SEDE-TRU', 'Sede Trujillo', 'Av. Espana 321', 9, '044456789', 'trujillo@edufuturo.edu.pe'),
        (6, 'SEDE-CHI', 'Sede Chiclayo', 'Av. Balta 890', 10, '074567890', 'chiclayo@edufuturo.edu.pe'),
        (7, 'SEDE-IQU', 'Sede Iquitos', 'Jr. Prospero 123', 11, '065678901', 'iquitos@edufuturo.edu.pe'),
        (8, 'SEDE-BAR', 'Sede Barranco', 'Av. Grau 456', 12, '012345678', 'barranco@edufuturo.edu.pe'),
        (9, 'SEDE-COM', 'Sede Comas', 'Av. Universitaria 789', 13, '013456789', 'comas@edufuturo.edu.pe'),
        (10, 'SEDE-SMG', 'Sede San Miguel', 'Av. La Marina 1011', 14, '012345679', 'sanmiguel@edufuturo.edu.pe'),
        (11, 'SEDE-MIR', 'Sede Miraflores', 'Calle Berlin 234', 15, '012345670', 'miraflores@edufuturo.edu.pe'),
        (12, 'SEDE-PIU', 'Sede Piura', 'Av. Grau 567', 16, '073345678', 'piura@edufuturo.edu.pe'),
        (13, 'SEDE-ICA', 'Sede Ica', 'Calle Bolivar 890', 17, '056345678', 'ica@edufuturo.edu.pe'),
        (14, 'SEDE-HUA', 'Sede Huancayo', 'Av. Giraldez 321', 18, '064345678', 'huancayo@edufuturo.edu.pe'),
        (15, 'SEDE-TAC', 'Sede Tacna', 'Av. San Martin 654', 19, '052345678', 'tacna@edufuturo.edu.pe'),
        (16, 'SEDE-MOY', 'Sede Moyobamba', 'Jr. Amazonas 987', 20, '042345678', 'moyobamba@edufuturo.edu.pe'),
        (17, 'SEDE-SJL', 'Sede SJL', 'Av. Las Flores 111', 5, '013456780', 'sjl@edufuturo.edu.pe'),
        (18, 'SEDE-LOS', 'Sede Los Olivos', 'Av. Carlos Izaguirre 222', 4, '013456781', 'losolivos@edufuturo.edu.pe'),
        (19, 'SEDE-VES', 'Sede Villa El Salvador', 'Av. Maria Elena Moyano 333', 6, '013456782', 'ves@edufuturo.edu.pe'),
        (20, 'SEDE-ARE', 'Sede Arequipa Sur', 'Av. Ejercito 444', 7, '054345679', 'arequipasur@edufuturo.edu.pe')
    ) v(SedeId, CodigoSede, NombreSede, Direccion, UbigeoId, Telefono, Email)
    WHERE NOT EXISTS (SELECT 1 FROM core.Sedes s WHERE s.CodigoSede = v.CodigoSede);
    SET IDENTITY_INSERT core.Sedes OFF;
    PRINT 'OK: 20 sedes insertadas.';
END
ELSE
    PRINT 'OK: Sedes ya cargadas (20).';
GO

-- =============================================
-- 3. CARRERAS (20)
-- =============================================
IF (SELECT COUNT(*) FROM core.Carreras) < 20
BEGIN
    SET IDENTITY_INSERT core.Carreras ON;
    INSERT INTO core.Carreras (CarreraId, CodigoCarrera, NombreCarrera, Descripcion, DuracionSemestres, CostoMatricula, CostoPensionMensual)
    SELECT v.CarreraId, v.CodigoCarrera, v.NombreCarrera, v.Descripcion, v.DuracionSemestres, v.CostoMatricula, v.CostoPensionMensual
    FROM (VALUES
        (1, 'ING-SIS', 'Ingenieria de Sistemas', 'Desarrollo de software y gestion de tecnologias de informacion', 10, 250.00, 450.00),
        (2, 'ING-IND', 'Ingenieria Industrial', 'Optimizacion de procesos productivos y gestion empresarial', 10, 250.00, 420.00),
        (3, 'ADM-EMP', 'Administracion de Empresas', 'Gestion y direccion de organizaciones empresariales', 10, 220.00, 380.00),
        (4, 'CONT-FIN', 'Contabilidad y Finanzas', 'Gestion contable, financiera y tributaria', 10, 220.00, 360.00),
        (5, 'MKT-DIG', 'Marketing Digital', 'Estrategias de marketing en entornos digitales', 8, 200.00, 340.00),
        (6, 'ENF-TEC', 'Enfermeria Tecnica', 'Cuidado de la salud y atencion al paciente', 6, 280.00, 420.00),
        (7, 'GAS-TUR', 'Gastronomia y Turismo', 'Arte culinario y gestion turistica', 6, 300.00, 480.00),
        (8, 'ING-CIV', 'Ingenieria Civil', 'Diseno, construccion y supervision de obras civiles', 10, 250.00, 430.00),
        (9, 'ING-ELC', 'Ingenieria Electronica', 'Sistemas electronicos y automatizacion industrial', 10, 250.00, 430.00),
        (10, 'ARQ-URB', 'Arquitectura y Urbanismo', 'Diseno arquitectonico y planificacion urbana', 10, 260.00, 450.00),
        (11, 'DER-DER', 'Derecho', 'Ciencias juridicas y defensa legal', 10, 240.00, 410.00),
        (12, 'PSI-PSI', 'Psicologia', 'Estudio del comportamiento humano', 10, 230.00, 400.00),
        (13, 'COM-SOC', 'Ciencias de la Comunicacion', 'Periodismo, publicidad y comunicacion corporativa', 8, 210.00, 360.00),
        (14, 'EDU-INI', 'Educacion Inicial', 'Formacion docente para la primera infancia', 8, 200.00, 340.00),
        (15, 'NUT-NUT', 'Nutricion y Dietetica', 'Alimentacion saludable y nutricion clinica', 8, 240.00, 410.00),
        (16, 'FIS-TER', 'Fisioterapia y Rehabilitacion', 'Rehabilitacion fisica y terapia del movimiento', 8, 250.00, 430.00),
        (17, 'TUR-HOS', 'Turismo y Hoteleria', 'Gestion turistica y hotelera', 8, 230.00, 390.00),
        (18, 'LAB-CLI', 'Laboratorio Clinico', 'Analisis clinicos y diagnostico de laboratorio', 8, 250.00, 420.00),
        (19, 'OPT-OPT', 'Optometria', 'Salud visual y correccion optica', 8, 240.00, 400.00),
        (20, 'MED-TEC', 'Medicina Tecnica', 'Asistencia medica y cuidados de salud', 6, 280.00, 460.00)
    ) v(CarreraId, CodigoCarrera, NombreCarrera, Descripcion, DuracionSemestres, CostoMatricula, CostoPensionMensual)
    WHERE NOT EXISTS (SELECT 1 FROM core.Carreras c WHERE c.CodigoCarrera = v.CodigoCarrera);
    SET IDENTITY_INSERT core.Carreras OFF;
    PRINT 'OK: 20 carreras insertadas.';
END
ELSE
    PRINT 'OK: Carreras ya cargadas (20).';
GO

-- =============================================
-- 4. PERIODOS ACADEMICOS (20)
-- El periodo 2027-I (PeriodoId=5) mantiene su ventana de matriculas
-- VIGENTE (2026-08-01 a 2026-10-15) para que el sistema tenga un
-- periodo habilitado (RN-03). Los demas periodos tienen ventanas
-- cerradas (pasadas o futuras), asi que no interfieren.
-- =============================================
IF (SELECT COUNT(*) FROM core.PeriodosAcademicos) < 20
BEGIN
    SET IDENTITY_INSERT core.PeriodosAcademicos ON;
    INSERT INTO core.PeriodosAcademicos (PeriodoId, CodigoPeriodo, NombrePeriodo, Anio, Semestre, FechaInicio, FechaFin, FechaInicioMatriculas, FechaFinMatriculas)
    SELECT v.PeriodoId, v.CodigoPeriodo, v.NombrePeriodo, v.Anio, v.Semestre, v.FechaInicio, v.FechaFin, v.FechaInicioMatriculas, v.FechaFinMatriculas
    FROM (VALUES
        (1, '2025-1', 'Periodo 2025-I', 2025, 1, '2025-03-01', '2025-07-31', '2025-01-15', '2025-02-28'),
        (2, '2025-2', 'Periodo 2025-II', 2025, 2, '2025-08-01', '2025-12-20', '2025-06-15', '2025-07-31'),
        (3, '2026-1', 'Periodo 2026-I', 2026, 1, '2026-03-01', '2026-07-31', '2026-01-15', '2026-02-28'),
        (4, '2026-2', 'Periodo 2026-II', 2026, 2, '2026-08-01', '2026-12-20', '2026-06-15', '2026-07-31'),
        (5, '2027-1', 'Periodo 2027-I', 2027, 1, '2027-03-01', '2027-07-31', '2026-08-01', '2026-10-15'),
        (6, '2023-1', 'Periodo 2023-I', 2023, 1, '2023-03-01', '2023-07-31', '2023-01-15', '2023-02-28'),
        (7, '2023-2', 'Periodo 2023-II', 2023, 2, '2023-08-01', '2023-12-20', '2023-06-15', '2023-07-31'),
        (8, '2024-1', 'Periodo 2024-I', 2024, 1, '2024-03-01', '2024-07-31', '2024-01-15', '2024-02-28'),
        (9, '2024-2', 'Periodo 2024-II', 2024, 2, '2024-08-01', '2024-12-20', '2024-06-15', '2024-07-31'),
        (10, '2027-2', 'Periodo 2027-II', 2027, 2, '2027-08-01', '2027-12-20', '2027-06-15', '2027-07-31'),
        (11, '2028-1', 'Periodo 2028-I', 2028, 1, '2028-03-01', '2028-07-31', '2028-01-15', '2028-02-28'),
        (12, '2028-2', 'Periodo 2028-II', 2028, 2, '2028-08-01', '2028-12-20', '2028-06-15', '2028-07-31'),
        (13, '2029-1', 'Periodo 2029-I', 2029, 1, '2029-03-01', '2029-07-31', '2029-01-15', '2029-02-28'),
        (14, '2029-2', 'Periodo 2029-II', 2029, 2, '2029-08-01', '2029-12-20', '2029-06-15', '2029-07-31'),
        (15, '2030-1', 'Periodo 2030-I', 2030, 1, '2030-03-01', '2030-07-31', '2030-01-15', '2030-02-28'),
        (16, '2030-2', 'Periodo 2030-II', 2030, 2, '2030-08-01', '2030-12-20', '2030-06-15', '2030-07-31'),
        (17, '2031-1', 'Periodo 2031-I', 2031, 1, '2031-03-01', '2031-07-31', '2031-01-15', '2031-02-28'),
        (18, '2031-2', 'Periodo 2031-II', 2031, 2, '2031-08-01', '2031-12-20', '2031-06-15', '2031-07-31'),
        (19, '2032-1', 'Periodo 2032-I', 2032, 1, '2032-03-01', '2032-07-31', '2032-01-15', '2032-02-28'),
        (20, '2032-2', 'Periodo 2032-II', 2032, 2, '2032-08-01', '2032-12-20', '2032-06-15', '2032-07-31')
    ) v(PeriodoId, CodigoPeriodo, NombrePeriodo, Anio, Semestre, FechaInicio, FechaFin, FechaInicioMatriculas, FechaFinMatriculas)
    WHERE NOT EXISTS (SELECT 1 FROM core.PeriodosAcademicos p WHERE p.CodigoPeriodo = v.CodigoPeriodo);
    SET IDENTITY_INSERT core.PeriodosAcademicos OFF;
    PRINT 'OK: 20 periodos academicos insertados.';
END
ELSE
    PRINT 'OK: Periodos ya cargados (20).';
GO

-- =============================================
-- 5. ESPECIALIDADES (20)
-- =============================================
IF (SELECT COUNT(*) FROM academic.Especialidades) < 20
BEGIN
    SET IDENTITY_INSERT academic.Especialidades ON;
    INSERT INTO academic.Especialidades (EspecialidadId, NombreEspecialidad, Descripcion)
    SELECT v.EspecialidadId, v.NombreEspecialidad, v.Descripcion
    FROM (VALUES
        (1,  'Ingenieria de Software', 'Diseno y desarrollo de sistemas de software'),
        (2,  'Base de Datos', 'Modelado, administracion y optimizacion de bases de datos'),
        (3,  'Redes y Comunicaciones', 'Infraestructura de redes y telecomunicaciones'),
        (4,  'Gestion Empresarial', 'Administracion y gestion de organizaciones'),
        (5,  'Matematica Aplicada', 'Matematicas aplicadas a la ingenieria'),
        (6,  'Contabilidad', 'Contabilidad financiera y costos'),
        (7,  'Marketing', 'Estrategias de marketing y ventas'),
        (8,  'Enfermeria', 'Cuidado de la salud y atencion al paciente'),
        (9,  'Gastronomia', 'Arte culinario y gestion de cocina'),
        (10, 'Gestion de Proyectos', 'Planificacion y direccion de proyectos'),
        (11, 'Inteligencia Artificial', 'Sistemas inteligentes y aprendizaje automatico'),
        (12, 'Ciberseguridad', 'Seguridad de la informacion y auditoria'),
        (13, 'Ingenieria Civil', 'Estructuras, construccion y vias'),
        (14, 'Arquitectura', 'Diseno arquitectonico y urbano'),
        (15, 'Derecho', 'Ciencias juridicas'),
        (16, 'Psicologia', 'Comportamiento humano y salud mental'),
        (17, 'Comunicaciones', 'Periodismo y comunicacion corporativa'),
        (18, 'Educacion', 'Formacion docente y pedagogia'),
        (19, 'Nutricion', 'Alimentacion y nutricion clinica'),
        (20, 'Fisioterapia', 'Rehabilitacion fisica y terapia')
    ) v(EspecialidadId, NombreEspecialidad, Descripcion)
    WHERE NOT EXISTS (SELECT 1 FROM academic.Especialidades e WHERE e.NombreEspecialidad = v.NombreEspecialidad);
    SET IDENTITY_INSERT academic.Especialidades OFF;
    PRINT 'OK: 20 especialidades insertadas.';
END
ELSE
    PRINT 'OK: Especialidades ya cargadas (20).';
GO

-- =============================================
-- 6. PROFESORES (20)
-- =============================================
IF (SELECT COUNT(*) FROM academic.Profesores) < 20
BEGIN
    SET IDENTITY_INSERT academic.Profesores ON;
    INSERT INTO academic.Profesores (ProfesorId, TipoDocumento, NumeroDocumento, Nombres, Apellidos, Email, Celular, EspecialidadId, GradoAcademico)
    SELECT v.ProfesorId, v.TipoDocumento, v.NumeroDocumento, v.Nombres, v.Apellidos, v.Email, v.Celular, v.EspecialidadId, v.GradoAcademico
    FROM (VALUES
        (1, 'DNI', '12345678', 'Carlos Alberto', 'Rodriguez Sanchez', 'carlos.rodriguez@edufuturo.edu.pe', '987654321', 1, 'Magister'),
        (2, 'DNI', '23456789', 'Maria Fernanda', 'Garcia Lopez', 'maria.garcia@edufuturo.edu.pe', '987654322', 2, 'Magister'),
        (3, 'DNI', '34567890', 'Jose Luis', 'Martinez Torres', 'jose.martinez@edufuturo.edu.pe', '987654323', 3, 'Doctor'),
        (4, 'DNI', '45678901', 'Ana Patricia', 'Flores Vega', 'ana.flores@edufuturo.edu.pe', '987654324', 4, 'Magister'),
        (5, 'DNI', '56789012', 'Roberto Carlos', 'Diaz Mendoza', 'roberto.diaz@edufuturo.edu.pe', '987654325', 5, 'Magister'),
        (6, 'DNI', '67890123', 'Carmen Rosa', 'Huaman Quispe', 'carmen.huaman@edufuturo.edu.pe', '987654326', 6, 'Licenciado'),
        (7, 'DNI', '78901234', 'Fernando Miguel', 'Castro Rojas', 'fernando.castro@edufuturo.edu.pe', '987654327', 7, 'Magister'),
        (8, 'DNI', '89012345', 'Lucia Beatriz', 'Paredes Silva', 'lucia.paredes@edufuturo.edu.pe', '987654328', 8, 'Licenciado'),
        (9, 'DNI', '90123456', 'Diego Alejandro', 'Vargas Leon', 'diego.vargas@edufuturo.edu.pe', '987654329', 9, 'Licenciado'),
        (10, 'CE', '0123456789012', 'Patricia Elena', 'Ramos Cruz', 'patricia.ramos@edufuturo.edu.pe', '987654330', 10, 'Doctor'),
        (11, 'DNI', '11223344', 'Ricardo', 'Sanchez Gutierrez', 'ricardo.sanchez@edufuturo.edu.pe', '987654331', 11, 'Magister'),
        (12, 'DNI', '22334455', 'Valeria', 'Rojas Paredes', 'valeria.rojas@edufuturo.edu.pe', '987654332', 12, 'Magister'),
        (13, 'DNI', '33445566', 'Oscar', 'Cordova Meza', 'oscar.cordova@edufuturo.edu.pe', '987654333', 13, 'Doctor'),
        (14, 'DNI', '44556677', 'Karla', 'Villanueva Rios', 'karla.villanueva@edufuturo.edu.pe', '987654334', 14, 'Magister'),
        (15, 'DNI', '55667788', 'Miguel', 'Chavez Alarcon', 'miguel.chavez@edufuturo.edu.pe', '987654335', 15, 'Doctor'),
        (16, 'DNI', '66778899', 'Rosa', 'Salazar Vasquez', 'rosa.salazar@edufuturo.edu.pe', '987654336', 16, 'Magister'),
        (17, 'DNI', '77889900', 'Alberto', 'Montoya Castillo', 'alberto.montoya@edufuturo.edu.pe', '987654337', 17, 'Magister'),
        (18, 'DNI', '88990011', 'Nadia', 'Cabrera Flores', 'nadia.cabrera@edufuturo.edu.pe', '987654338', 18, 'Licenciado'),
        (19, 'DNI', '99001122', 'Hector', 'Quispe Yupanqui', 'hector.quispe@edufuturo.edu.pe', '987654339', 19, 'Magister'),
        (20, 'DNI', '00112233', 'Milagros', 'Aguilar Rondon', 'milagros.aguilar@edufuturo.edu.pe', '987654340', 20, 'Licenciado')
    ) v(ProfesorId, TipoDocumento, NumeroDocumento, Nombres, Apellidos, Email, Celular, EspecialidadId, GradoAcademico)
    WHERE NOT EXISTS (SELECT 1 FROM academic.Profesores p WHERE p.NumeroDocumento = v.NumeroDocumento);
    SET IDENTITY_INSERT academic.Profesores OFF;
    PRINT 'OK: 20 profesores insertados.';
END
ELSE
    PRINT 'OK: Profesores ya cargados (20).';
GO

-- =============================================
-- 7. CURSOS (20)
-- =============================================
IF (SELECT COUNT(*) FROM academic.Cursos) < 20
BEGIN
    SET IDENTITY_INSERT academic.Cursos ON;
    INSERT INTO academic.Cursos (CursoId, CodigoCurso, NombreCurso, Descripcion, Creditos, HorasTeoria, HorasPractica)
    SELECT v.CursoId, v.CodigoCurso, v.NombreCurso, v.Descripcion, v.Creditos, v.HorasTeoria, v.HorasPractica
    FROM (VALUES
        (1, 'MAT-101', 'Matematica Basica', 'Fundamentos de matematica para ingenieria', 4, 3, 2),
        (2, 'PRO-101', 'Fundamentos de Programacion', 'Introduccion a la programacion estructurada', 5, 3, 4),
        (3, 'BDD-201', 'Base de Datos I', 'Diseno y modelado de bases de datos relacionales', 4, 2, 4),
        (4, 'BDD-202', 'Base de Datos II', 'Administracion y optimizacion de bases de datos', 4, 2, 4),
        (5, 'WEB-301', 'Desarrollo Web', 'Desarrollo de aplicaciones web modernas', 5, 2, 6),
        (6, 'ADM-101', 'Administracion General', 'Principios basicos de administracion', 3, 3, 0),
        (7, 'CON-101', 'Contabilidad General', 'Fundamentos de contabilidad financiera', 4, 3, 2),
        (8, 'MKT-101', 'Marketing Fundamental', 'Conceptos basicos de marketing', 3, 3, 0),
        (9, 'ENF-101', 'Anatomia y Fisiologia', 'Estudio del cuerpo humano', 4, 4, 2),
        (10, 'GAS-101', 'Tecnicas Culinarias Basicas', 'Fundamentos de cocina', 4, 2, 4),
        (11, 'IA-401', 'Inteligencia Artificial', 'Sistemas inteligentes y machine learning', 4, 3, 2),
        (12, 'CIB-401', 'Ciberseguridad', 'Seguridad de redes y auditoria informatica', 4, 3, 2),
        (13, 'CIV-101', 'Ingenieria Civil I', 'Introduccion a la ingenieria civil', 4, 3, 2),
        (14, 'ARQ-101', 'Arquitectura I', 'Historia y fundamentos de la arquitectura', 3, 3, 0),
        (15, 'DER-101', 'Derecho Constitucional', 'Constitucion y derechos fundamentales', 4, 4, 0),
        (16, 'PSI-101', 'Psicologia General', 'Fundamentos de la psicologia', 4, 3, 2),
        (17, 'COM-101', 'Comunicacion Social', 'Comunicacion, prensa y multimedia', 3, 2, 2),
        (18, 'EDU-101', 'Pedagogia General', 'Teorias y practicas de la educacion', 4, 3, 2),
        (19, 'NUT-101', 'Nutricion Basica', 'Fundamentos de nutricion humana', 4, 3, 2),
        (20, 'FIS-101', 'Fisioterapia I', 'Fundamentos de fisioterapia', 4, 3, 2)
    ) v(CursoId, CodigoCurso, NombreCurso, Descripcion, Creditos, HorasTeoria, HorasPractica)
    WHERE NOT EXISTS (SELECT 1 FROM academic.Cursos c WHERE c.CodigoCurso = v.CodigoCurso);
    SET IDENTITY_INSERT academic.Cursos OFF;
    PRINT 'OK: 20 cursos insertados.';
END
ELSE
    PRINT 'OK: Cursos ya cargados (20).';
GO

-- =============================================
-- 8. MALLA CURRICULAR: CARRERA-CURSOS (42)
-- Cada carrera tiene al menos 2 cursos en su malla (RN-05).
-- =============================================
IF (SELECT COUNT(*) FROM academic.CarreraCursos) < 20
BEGIN
    SET IDENTITY_INSERT academic.CarreraCursos ON;
    INSERT INTO academic.CarreraCursos (CarreraCursoId, CarreraId, CursoId, Semestre)
    SELECT v.CarreraCursoId, v.CarreraId, v.CursoId, v.Semestre
    FROM (VALUES
        -- Ingenieria de Sistemas
        (1, 1, 1, 1), (2, 1, 2, 1), (3, 1, 3, 3), (4, 1, 4, 4), (5, 1, 5, 5),
        -- Ingenieria Industrial
        (17, 2, 1, 1), (18, 2, 6, 1), (19, 2, 7, 2), (20, 2, 8, 3),
        -- Administracion de Empresas
        (6, 3, 1, 1), (7, 3, 6, 1), (8, 3, 7, 2), (9, 3, 8, 3),
        -- Contabilidad y Finanzas
        (10, 4, 1, 1), (11, 4, 7, 1), (12, 4, 6, 2),
        -- Marketing Digital
        (13, 5, 8, 1), (14, 5, 5, 2),
        -- Enfermeria Tecnica
        (15, 6, 9, 1),
        -- Gastronomia y Turismo
        (16, 7, 10, 1),
        -- Ingenieria Civil
        (21, 8, 13, 1), (22, 8, 1, 2), (23, 8, 14, 4),
        -- Ingenieria Electronica
        (24, 9, 2, 1), (25, 9, 11, 4), (26, 9, 12, 5),
        -- Arquitectura y Urbanismo
        (27, 10, 14, 1), (28, 10, 6, 2),
        -- Derecho
        (29, 11, 15, 1), (30, 11, 7, 2),
        -- Psicologia
        (31, 12, 16, 1), (32, 12, 17, 3),
        -- Ciencias de la Comunicacion
        (33, 13, 17, 1), (34, 13, 8, 2),
        -- Educacion Inicial
        (35, 14, 18, 1), (36, 14, 1, 2),
        -- Nutricion y Dietetica
        (37, 15, 19, 1), (38, 15, 9, 2),
        -- Fisioterapia y Rehabilitacion
        (39, 16, 20, 1), (40, 16, 9, 2),
        -- Turismo y Hoteleria
        (41, 17, 10, 1), (42, 17, 8, 2)
    ) v(CarreraCursoId, CarreraId, CursoId, Semestre)
    WHERE NOT EXISTS (SELECT 1 FROM academic.CarreraCursos cc WHERE cc.CarreraCursoId = v.CarreraCursoId);
    SET IDENTITY_INSERT academic.CarreraCursos OFF;
    PRINT 'OK: 42 relaciones carrera-curso insertadas.';
END
ELSE
    PRINT 'OK: CarreraCursos ya cargados (42).';
GO

-- Malla de las carreras restantes (18, 19, 20) - deben tener cursos (RN-05)
IF NOT EXISTS (SELECT 1 FROM academic.CarreraCursos WHERE CarreraId = 18)
BEGIN
    SET IDENTITY_INSERT academic.CarreraCursos ON;
    INSERT INTO academic.CarreraCursos (CarreraCursoId, CarreraId, CursoId, Semestre)
    SELECT v.CarreraCursoId, v.CarreraId, v.CursoId, v.Semestre
    FROM (VALUES
        (43, 18, 9, 1), (44, 18, 19, 3), (45, 18, 20, 4),   -- Laboratorio Clinico
        (46, 19, 16, 1), (47, 19, 9, 2),                    -- Optometria
        (48, 20, 9, 1), (49, 20, 20, 2)                     -- Medicina Tecnica
    ) v(CarreraCursoId, CarreraId, CursoId, Semestre)
    WHERE NOT EXISTS (SELECT 1 FROM academic.CarreraCursos cc WHERE cc.CarreraCursoId = v.CarreraCursoId);
    SET IDENTITY_INSERT academic.CarreraCursos OFF;
    PRINT 'OK: Malla de carreras 18-20 completada (49 relaciones).';
END
ELSE
    PRINT 'OK: Malla de carreras 18-20 ya existe.';
GO

-- =============================================
-- 9. PROMOTORES (20)
-- =============================================
IF (SELECT COUNT(*) FROM sales.Promotores) < 20
BEGIN
    SET IDENTITY_INSERT sales.Promotores ON;
    INSERT INTO sales.Promotores (PromotorId, CodigoPromotor, TipoDocumento, NumeroDocumento, Nombres, Apellidos, Email, Celular, SedeId, PorcentajeComision)
    SELECT v.PromotorId, v.CodigoPromotor, v.TipoDocumento, v.NumeroDocumento, v.Nombres, v.Apellidos, v.Email, v.Celular, v.SedeId, v.PorcentajeComision
    FROM (VALUES
        (1, 'PROM-001', 'DNI', '11111111', 'Juan Carlos', 'Perez Gutierrez', 'juan.perez@edufuturo.edu.pe', '999888777', 1, 8.00),
        (2, 'PROM-002', 'DNI', '22222222', 'Maria Isabel', 'Lopez Ramirez', 'maria.lopez@edufuturo.edu.pe', '999888778', 1, 7.50),
        (3, 'PROM-003', 'DNI', '33333333', 'Pedro Antonio', 'Gonzalez Silva', 'pedro.gonzalez@edufuturo.edu.pe', '999888779', 2, 7.00),
        (4, 'PROM-004', 'DNI', '44444444', 'Sofia Alejandra', 'Torres Medina', 'sofia.torres@edufuturo.edu.pe', '999888780', 3, 8.50),
        (5, 'PROM-005', 'DNI', '55555555', 'Luis Fernando', 'Sanchez Vega', 'luis.sanchez@edufuturo.edu.pe', '999888781', 4, 7.50),
        (6, 'PROM-006', 'CE', '777777777777', 'Andrea Gabriela', 'Morales Castro', 'andrea.morales@edufuturo.edu.pe', '999888782', 5, 8.00),
        (7, 'PROM-007', 'DNI', '61111112', 'Rodrigo', 'Campos Vilchez', 'rodrigo.campos@edufuturo.edu.pe', '999888783', 2, 8.00),
        (8, 'PROM-008', 'DNI', '62222223', 'Diana', 'Navarro Suarez', 'diana.navarro@edufuturo.edu.pe', '999888784', 3, 7.50),
        (9, 'PROM-009', 'DNI', '63333334', 'Paul', 'Benavides Roca', 'paul.benavides@edufuturo.edu.pe', '999888785', 4, 8.00),
        (10, 'PROM-010', 'DNI', '64444445', 'Gisela', 'Ortiz Delgado', 'gisela.ortiz@edufuturo.edu.pe', '999888786', 5, 7.00),
        (11, 'PROM-011', 'DNI', '65555556', 'Enrique', 'Tello Rios', 'enrique.tello@edufuturo.edu.pe', '999888787', 6, 8.50),
        (12, 'PROM-012', 'DNI', '66666667', 'Paola', 'Medina Farfan', 'paola.medina@edufuturo.edu.pe', '999888788', 7, 7.50),
        (13, 'PROM-013', 'DNI', '67777778', 'Cesar', 'Ramos Bustamante', 'cesar.ramos@edufuturo.edu.pe', '999888789', 8, 8.00),
        (14, 'PROM-014', 'DNI', '68888889', 'Tatiana', 'Solis Guerrero', 'tatiana.solis@edufuturo.edu.pe', '999888790', 9, 7.00),
        (15, 'PROM-015', 'DNI', '69999990', 'Marco', 'Apaza Nina', 'marco.apaza@edufuturo.edu.pe', '999888791', 10, 8.00),
        (16, 'PROM-016', 'DNI', '71111112', 'Xiomara', 'Castillo Villanueva', 'xiomara.castillo@edufuturo.edu.pe', '999888792', 11, 7.50),
        (17, 'PROM-017', 'DNI', '72222223', 'Renato', 'Fuentes Caro', 'renato.fuentes@edufuturo.edu.pe', '999888793', 12, 8.00),
        (18, 'PROM-018', 'DNI', '73333334', 'Camila', 'Arias Peralta', 'camila.arias@edufuturo.edu.pe', '999888794', 13, 7.00),
        (19, 'PROM-019', 'DNI', '74444445', 'Jorge', 'Hidalgo Vega', 'jorge.hidalgo@edufuturo.edu.pe', '999888795', 14, 8.50),
        (20, 'PROM-020', 'DNI', '75555556', 'Fabiola', 'Quintana Lopez', 'fabiola.quintana@edufuturo.edu.pe', '999888796', 15, 7.50)
    ) v(PromotorId, CodigoPromotor, TipoDocumento, NumeroDocumento, Nombres, Apellidos, Email, Celular, SedeId, PorcentajeComision)
    WHERE NOT EXISTS (SELECT 1 FROM sales.Promotores p WHERE p.CodigoPromotor = v.CodigoPromotor);
    SET IDENTITY_INSERT sales.Promotores OFF;
    PRINT 'OK: 20 promotores insertados.';
END
ELSE
    PRINT 'OK: Promotores ya cargados (20).';
GO

-- =============================================
-- 10. CAMPANAS DE ADMISION (20)
-- Cada campana esta vinculada a su periodo academico (RN-09).
-- =============================================
IF (SELECT COUNT(*) FROM sales.CampaniasAdmision) < 20
BEGIN
    SET IDENTITY_INSERT sales.CampaniasAdmision ON;
    INSERT INTO sales.CampaniasAdmision (CampaniaId, CodigoCampania, NombreCampania, Descripcion, PeriodoId, FechaInicio, FechaFin, PorcentajeComisionBase, BonoPorMeta, MetaMatriculas)
    SELECT v.CampaniaId, v.CodigoCampania, v.NombreCampania, v.Descripcion, v.PeriodoId, v.FechaInicio, v.FechaFin, v.PorcentajeComisionBase, v.BonoPorMeta, v.MetaMatriculas
    FROM (VALUES
        (1, 'CAMP-2025-1', 'Campana Verano 2025', 'Campana de admision periodo 2025-I', 1, '2025-01-01', '2025-02-28', 10.00, 500.00, 50),
        (2, 'CAMP-2025-2', 'Campana Invierno 2025', 'Campana de admision periodo 2025-II', 2, '2025-06-01', '2025-07-31', 10.00, 500.00, 50),
        (3, 'CAMP-2026-1', 'Campana Verano 2026', 'Campana de admision periodo 2026-I', 3, '2026-01-01', '2026-02-28', 12.00, 600.00, 60),
        (4, 'CAMP-2026-2', 'Campana Invierno 2026', 'Campana de admision periodo 2026-II', 4, '2026-06-01', '2026-07-31', 12.00, 600.00, 60),
        (5, 'CAMP-2027-1', 'Campana Pre-Admision 2027', 'Campana de admision anticipada periodo 2027-I', 5, '2026-08-01', '2026-10-15', 12.00, 600.00, 60),
        (6, 'CAMP-2023-1', 'Campana Verano 2023', 'Campana de admision periodo 2023-I', 6, '2023-01-01', '2023-02-28', 10.00, 500.00, 50),
        (7, 'CAMP-2023-2', 'Campana Invierno 2023', 'Campana de admision periodo 2023-II', 7, '2023-06-01', '2023-07-31', 10.00, 500.00, 50),
        (8, 'CAMP-2024-1', 'Campana Verano 2024', 'Campana de admision periodo 2024-I', 8, '2024-01-01', '2024-02-28', 10.00, 500.00, 50),
        (9, 'CAMP-2024-2', 'Campana Invierno 2024', 'Campana de admision periodo 2024-II', 9, '2024-06-01', '2024-07-31', 10.00, 500.00, 50),
        (10, 'CAMP-2027-2', 'Campana Invierno 2027', 'Campana de admision periodo 2027-II', 10, '2027-06-01', '2027-07-31', 12.00, 600.00, 60),
        (11, 'CAMP-2028-1', 'Campana Verano 2028', 'Campana de admision periodo 2028-I', 11, '2028-01-01', '2028-02-28', 12.00, 600.00, 60),
        (12, 'CAMP-2028-2', 'Campana Invierno 2028', 'Campana de admision periodo 2028-II', 12, '2028-06-01', '2028-07-31', 12.00, 600.00, 60),
        (13, 'CAMP-2029-1', 'Campana Verano 2029', 'Campana de admision periodo 2029-I', 13, '2029-01-01', '2029-02-28', 12.00, 650.00, 65),
        (14, 'CAMP-2029-2', 'Campana Invierno 2029', 'Campana de admision periodo 2029-II', 14, '2029-06-01', '2029-07-31', 12.00, 650.00, 65),
        (15, 'CAMP-2030-1', 'Campana Verano 2030', 'Campana de admision periodo 2030-I', 15, '2030-01-01', '2030-02-28', 13.00, 700.00, 70),
        (16, 'CAMP-2030-2', 'Campana Invierno 2030', 'Campana de admision periodo 2030-II', 16, '2030-06-01', '2030-07-31', 13.00, 700.00, 70),
        (17, 'CAMP-2031-1', 'Campana Verano 2031', 'Campana de admision periodo 2031-I', 17, '2031-01-01', '2031-02-28', 13.00, 700.00, 70),
        (18, 'CAMP-2031-2', 'Campana Invierno 2031', 'Campana de admision periodo 2031-II', 18, '2031-06-01', '2031-07-31', 13.00, 700.00, 70),
        (19, 'CAMP-2032-1', 'Campana Verano 2032', 'Campana de admision periodo 2032-I', 19, '2032-01-01', '2032-02-28', 13.00, 750.00, 75),
        (20, 'CAMP-2032-2', 'Campana Invierno 2032', 'Campana de admision periodo 2032-II', 20, '2032-06-01', '2032-07-31', 13.00, 750.00, 75)
    ) v(CampaniaId, CodigoCampania, NombreCampania, Descripcion, PeriodoId, FechaInicio, FechaFin, PorcentajeComisionBase, BonoPorMeta, MetaMatriculas)
    WHERE NOT EXISTS (SELECT 1 FROM sales.CampaniasAdmision c WHERE c.CodigoCampania = v.CodigoCampania);
    SET IDENTITY_INSERT sales.CampaniasAdmision OFF;
    PRINT 'OK: 20 campanas de admision insertadas.';
END
ELSE
    PRINT 'OK: Campanias ya cargadas (20).';
GO

-- =============================================
-- 11. ESTUDIANTES (20)
-- =============================================
IF (SELECT COUNT(*) FROM core.Estudiantes) < 20
BEGIN
    SET IDENTITY_INSERT core.Estudiantes ON;
    INSERT INTO core.Estudiantes (EstudianteId, TipoDocumento, NumeroDocumento, Nombres, Apellidos, Email, Celular, FechaNacimiento, Genero, Direccion, UbigeoId)
    SELECT v.EstudianteId, v.TipoDocumento, v.NumeroDocumento, v.Nombres, v.Apellidos, v.Email, v.Celular, v.FechaNacimiento, v.Genero, v.Direccion, v.UbigeoId
    FROM (VALUES
        (1, 'DNI', '70123456', 'Carlos Andres', 'Mendoza Rios', 'cmendoza@gmail.com', '987111222', '2004-05-15', 'M', 'Jr. Las Flores 123', 5),
        (2, 'DNI', '70234567', 'Ana Lucia', 'Fernandez Cruz', 'afernandez@gmail.com', '987111223', '2003-08-22', 'F', 'Av. Los Alamos 456', 4),
        (3, 'DNI', '70345678', 'Miguel Angel', 'Vargas Salazar', 'mvargas@gmail.com', '987111224', '2004-11-10', 'M', 'Calle Los Pinos 789', 6),
        (4, 'DNI', '70456789', 'Gabriela Maria', 'Rojas Flores', 'grojas@gmail.com', '987111225', '2003-03-18', 'F', 'Av. Industrial 321', 2),
        (5, 'DNI', '70567890', 'Jose Luis', 'Castro Paredes', 'jcastro@gmail.com', '987111226', '2004-07-25', 'M', 'Jr. Comercio 654', 3),
        (6, 'DNI', '70678901', 'Daniela Sofia', 'Huaman Leon', 'dhuaman@gmail.com', '987111227', '2003-12-05', 'F', 'Av. Principal 987', 8),
        (7, 'DNI', '70789012', 'Fernando Jesus', 'Quispe Mamani', 'fquispe@gmail.com', '987111228', '2004-02-14', 'M', 'Calle Real 147', 7),
        (8, 'DNI', '70890123', 'Valeria Cristina', 'Diaz Soto', 'vdiaz@gmail.com', '987111229', '2003-09-30', 'F', 'Jr. Union 258', 9),
        (9, 'DNI', '70901234', 'Ricardo Manuel', 'Silva Ramirez', 'rsilva@gmail.com', '987111230', '2004-06-12', 'M', 'Av. Grau 369', 10),
        (10, 'CE', '601234567890', 'Isabella Nicole', 'Torres Vega', 'itorres@gmail.com', '987111231', '2003-04-08', 'F', 'Calle Lima 741', 11),
        (11, 'DNI', '72000001', 'Sebastian', 'Ramirez Paredes', 'sramirez@gmail.com', '987111232', '2004-01-20', 'M', 'Av. Los Jazmines 12', 12),
        (12, 'DNI', '72000002', 'Camila', 'Gutierrez Mendoza', 'cgutierrez@gmail.com', '987111233', '2005-03-11', 'F', 'Jr. Las Gardenias 34', 13),
        (13, 'DNI', '72000003', 'Andre', 'Palomino Caceres', 'apalomino@gmail.com', '987111234', '2003-10-02', 'M', 'Calle Los Cipreses 56', 14),
        (14, 'DNI', '72000004', 'Xiomara', 'Vega Salas', 'xvega@gmail.com', '987111235', '2004-12-25', 'F', 'Av. Los Prados 78', 15),
        (15, 'DNI', '72000005', 'Bruno', 'Nunez Castillo', 'bnunez@gmail.com', '987111236', '2005-02-14', 'M', 'Jr. Los Olivos 90', 16),
        (16, 'DNI', '72000006', 'Lucero', 'Chavez Portocarrero', 'lchavez@gmail.com', '987111237', '2003-07-19', 'F', 'Av. La Fuente 11', 17),
        (17, 'DNI', '72000007', 'Giancarlo', 'Tello Cabrera', 'gtello@gmail.com', '987111238', '2004-09-08', 'M', 'Calle Los Tulipanes 22', 18),
        (18, 'DNI', '72000008', 'Alejandra', 'Rios Fernandez', 'arios@gmail.com', '987111239', '2005-01-30', 'F', 'Jr. Las Acacias 33', 19),
        (19, 'DNI', '72000009', 'Matias', 'Escobar Quintana', 'mescobar@gmail.com', '987111240', '2003-05-27', 'M', 'Av. Los Algarrobos 44', 20),
        (20, 'DNI', '72000010', 'Briana', 'Cordova Maldonado', 'bcordova@gmail.com', '987111241', '2004-08-16', 'F', 'Calle Los Geranios 55', 1)
    ) v(EstudianteId, TipoDocumento, NumeroDocumento, Nombres, Apellidos, Email, Celular, FechaNacimiento, Genero, Direccion, UbigeoId)
    WHERE NOT EXISTS (SELECT 1 FROM core.Estudiantes e WHERE e.NumeroDocumento = v.NumeroDocumento);
    SET IDENTITY_INSERT core.Estudiantes OFF;
    PRINT 'OK: 20 estudiantes insertados.';
END
ELSE
    PRINT 'OK: Estudiantes ya cargados (20).';
GO

-- =============================================
-- 12. MATRICULAS (20)
-- Distribuidas entre periodos con ventana cerrada (2023-2026) y el
-- periodo vigente 2027-I (PeriodoId=5). Cada matricula genera su
-- comision automaticamente via TRG_Comision_Automatica (RN-09).
-- =============================================
IF (SELECT COUNT(*) FROM core.Matriculas) < 20
BEGIN
    SET IDENTITY_INSERT core.Matriculas ON;
    INSERT INTO core.Matriculas (MatriculaId, CodigoMatricula, EstudianteId, CarreraId, PeriodoId, SedeId, PromotorId, CampaniaId, FechaMatricula, MontoMatricula, EstadoMatricula)
    SELECT v.MatriculaId, v.CodigoMatricula, v.EstudianteId, v.CarreraId, v.PeriodoId, v.SedeId, v.PromotorId, v.CampaniaId, v.FechaMatricula, v.MontoMatricula, v.EstadoMatricula
    FROM (VALUES
        (1, 'MAT-2025-000001', 1, 1, 1, 1, 1, 1, '2025-01-20 10:30:00', 250.00, 'Activa'),
        (2, 'MAT-2025-000002', 2, 1, 1, 1, 1, 1, '2025-01-22 11:15:00', 250.00, 'Activa'),
        (3, 'MAT-2025-000003', 3, 2, 1, 2, 3, 1, '2025-01-25 14:20:00', 250.00, 'Activa'),
        (4, 'MAT-2025-000004', 4, 3, 1, 2, 3, 1, '2025-02-01 09:45:00', 220.00, 'Activa'),
        (5, 'MAT-2025-000005', 5, 4, 1, 1, 2, 1, '2025-02-03 16:00:00', 220.00, 'Activa'),
        (6, 'MAT-2025-000006', 6, 5, 1, 3, 4, 1, '2025-02-05 10:30:00', 200.00, 'Activa'),
        (7, 'MAT-2026-000007', 7, 6, 3, 4, 5, 3, '2026-01-20 13:15:00', 280.00, 'Activa'),
        (8, 'MAT-2026-000008', 8, 7, 3, 5, 6, 3, '2026-01-22 15:45:00', 300.00, 'Activa'),
        (9, 'MAT-2026-000009', 9, 1, 3, 1, 1, 3, '2026-01-25 11:00:00', 250.00, 'Activa'),
        (10, 'MAT-2026-000010', 10, 3, 3, 1, 2, 3, '2026-02-01 14:30:00', 220.00, 'Activa'),
        (11, 'MAT-2026-000011', 11, 1, 3, 1, 1, 3, '2026-02-03 09:00:00', 250.00, 'Activa'),
        (12, 'MAT-2026-000012', 12, 2, 3, 2, 3, 3, '2026-02-05 10:00:00', 250.00, 'Activa'),
        (13, 'MAT-2026-000013', 13, 8, 3, 2, 3, 3, '2026-02-08 11:00:00', 250.00, 'Activa'),
        (14, 'MAT-2026-000014', 14, 3, 3, 1, 2, 3, '2026-02-10 12:00:00', 220.00, 'Activa'),
        (15, 'MAT-2026-000015', 15, 4, 3, 3, 4, 3, '2026-02-12 15:00:00', 220.00, 'Retirada'),
        (16, 'MAT-2026-000016', 16, 5, 3, 4, 5, 3, '2026-02-15 16:00:00', 200.00, 'Suspendida'),
        (17, 'MAT-2027-000017', 17, 6, 5, 5, 6, 5, '2026-08-03 10:00:00', 280.00, 'Activa'),
        (18, 'MAT-2027-000018', 18, 7, 5, 1, 1, 5, '2026-08-05 11:30:00', 300.00, 'Activa'),
        (19, 'MAT-2027-000019', 19, 8, 5, 2, 3, 5, '2026-08-07 09:15:00', 250.00, 'Activa'),
        (20, 'MAT-2027-000020', 20, 9, 5, 3, 4, 5, '2026-08-10 14:00:00', 250.00, 'Activa')
    ) v(MatriculaId, CodigoMatricula, EstudianteId, CarreraId, PeriodoId, SedeId, PromotorId, CampaniaId, FechaMatricula, MontoMatricula, EstadoMatricula)
    WHERE NOT EXISTS (SELECT 1 FROM core.Matriculas m WHERE m.CodigoMatricula = v.CodigoMatricula);
    SET IDENTITY_INSERT core.Matriculas OFF;
    PRINT 'OK: 20 matriculas insertadas.';
END
ELSE
    PRINT 'OK: Matriculas ya cargadas (20).';
GO

-- =============================================
-- 13. ROLES DE SEGURIDAD (3, segun el caso)
-- El caso de negocio contempla 3 perfiles: Administrador,
-- Coordinador Academico y Promotor.
-- =============================================
IF (SELECT COUNT(*) FROM security.Roles) < 3
BEGIN
    SET IDENTITY_INSERT security.Roles ON;
    INSERT INTO security.Roles (RolId, NombreRol, Descripcion)
    SELECT v.RolId, v.NombreRol, v.Descripcion
    FROM (VALUES
        (1, 'Administrador', 'Acceso completo al sistema'),
        (2, 'Coordinador Academico', 'Gestion academica y reportes'),
        (3, 'Promotor', 'Registro de estudiantes y consulta de comisiones')
    ) v(RolId, NombreRol, Descripcion)
    WHERE NOT EXISTS (SELECT 1 FROM security.Roles r WHERE r.NombreRol = v.NombreRol);
    SET IDENTITY_INSERT security.Roles OFF;
    PRINT 'OK: 3 roles de seguridad insertados (Administrador, Coordinador Academico, Promotor).';
END
ELSE
    PRINT 'OK: Roles ya cargados (3).';
GO

-- =============================================
-- 14. USUARIOS DEL SISTEMA (4, segun el caso)
-- Un usuario por perfil del caso (mas el segundo promotor).
-- Las contrasenas se almacenan como hash SHA2-256 (desarrollo).
-- =============================================
IF (SELECT COUNT(*) FROM security.Usuarios) < 4
BEGIN
    SET IDENTITY_INSERT security.Usuarios ON;
    INSERT INTO security.Usuarios (UsuarioId, Username, PasswordHash, Email, NombresCompletos, RolId)
    SELECT v.UsuarioId, v.Username, HASHBYTES('SHA2_256', v.Clave), v.Email, v.NombresCompletos, v.RolId
    FROM (VALUES
        (1, 'admin', 'Admin#2026', 'admin@edufuturo.edu.pe', 'Administrador del Sistema', 1),
        (2, 'coord_acad', 'Coord#2026', 'coordinador@edufuturo.edu.pe', 'Coordinador Academico Principal', 2),
        (3, 'prom_juan', 'Promo#2026', 'juan.perez@edufuturo.edu.pe', 'Juan Carlos Perez Gutierrez', 3),
        (4, 'prom_maria', 'Promo#2026', 'maria.lopez@edufuturo.edu.pe', 'Maria Isabel Lopez Ramirez', 3)
    ) v(UsuarioId, Username, Clave, Email, NombresCompletos, RolId)
    WHERE NOT EXISTS (SELECT 1 FROM security.Usuarios u WHERE u.Username = v.Username);
    SET IDENTITY_INSERT security.Usuarios OFF;
    PRINT 'OK: 4 usuarios del sistema insertados (admin, coord_acad, prom_juan, prom_maria).';
END
ELSE
    PRINT 'OK: Usuarios ya cargados (4).';
GO

-- =============================================
-- 15. ASIGNACIONES CURSO-PROFESOR (20)
-- Distribuidas en periodos 2024-I (PeriodoId=3), 2025-I (5) y 2026-I (7).
-- =============================================
IF (SELECT COUNT(*) FROM academic.CursoProfesor) < 20
BEGIN
    SET IDENTITY_INSERT academic.CursoProfesor ON;
    INSERT INTO academic.CursoProfesor (CursoProfesorId, CursoId, ProfesorId, PeriodoId, SedeId, FechaAsignacion)
    SELECT v.CursoProfesorId, v.CursoId, v.ProfesorId, v.PeriodoId, v.SedeId, v.FechaAsignacion
    FROM (VALUES
        (1, 1, 5, 3, 1, '2024-01-10'),
        (2, 2, 1, 3, 1, '2024-01-10'),
        (3, 3, 2, 3, 1, '2024-01-10'),
        (4, 4, 2, 3, 1, '2024-01-10'),
        (5, 5, 1, 3, 1, '2024-01-10'),
        (6, 6, 4, 3, 1, '2024-01-10'),
        (7, 7, 6, 3, 1, '2024-01-10'),
        (8, 8, 7, 3, 1, '2024-01-10'),
        (9, 9, 8, 3, 3, '2024-01-10'),
        (10, 10, 9, 3, 5, '2024-01-10'),
        (11, 11, 11, 5, 1, '2025-01-10'),
        (12, 12, 12, 5, 1, '2025-01-10'),
        (13, 13, 13, 5, 2, '2025-01-10'),
        (14, 14, 14, 5, 2, '2025-01-10'),
        (15, 15, 15, 5, 3, '2025-01-10'),
        (16, 16, 16, 5, 3, '2025-01-10'),
        (17, 17, 17, 7, 4, '2026-01-10'),
        (18, 18, 18, 7, 4, '2026-01-10'),
        (19, 19, 19, 7, 5, '2026-01-10'),
        (20, 20, 20, 7, 5, '2026-01-10')
    ) v(CursoProfesorId, CursoId, ProfesorId, PeriodoId, SedeId, FechaAsignacion)
    WHERE NOT EXISTS (SELECT 1 FROM academic.CursoProfesor cp WHERE cp.CursoProfesorId = v.CursoProfesorId);
    SET IDENTITY_INSERT academic.CursoProfesor OFF;
    PRINT 'OK: 20 asignaciones curso-profesor insertadas.';
END
ELSE
    PRINT 'OK: CursoProfesor ya cargado (20).';
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