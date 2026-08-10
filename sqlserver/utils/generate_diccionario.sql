-- =============================================
-- Matricula Cloud 360 Enterprise
-- utils/generate_diccionario.sql
-- =============================================
-- Descripcion: Consulta los metadatos de la base de datos y
-- devuelve la informacion completa para elaborar el diccionario
-- de datos (tablas, columnas, relaciones, restricciones e indices).
--
-- Uso: ejecutar en SSMS / Azure Data Studio y exportar a Excel o PDF.
-- El diccionario oficial del Sprint 1 es datasets/DiccionarioDatos.pdf.
-- =============================================

USE MatriculaCloud360DB;
GO

PRINT '============================================';
PRINT 'DICCIONARIO DE DATOS - CONSULTAS DE SOPORTE';
PRINT '============================================';
GO

-- ==========================================================
-- 1. TABLAS POR ESQUEMA
-- ==========================================================
PRINT '1. TABLAS POR ESQUEMA';
GO
SELECT
    s.name AS Esquema,
    t.name AS Tabla,
    (SELECT COUNT(*) FROM sys.columns WHERE object_id = t.object_id) AS TotalColumnas,
    (SELECT COUNT(*) FROM sys.foreign_keys WHERE parent_object_id = t.object_id) AS TotalFKs,
    (SELECT COUNT(*) FROM sys.indexes WHERE object_id = t.object_id AND is_primary_key = 0 AND type = 2) AS TotalIndicesNC
FROM sys.tables t
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE s.name IN ('core', 'academic', 'sales', 'security', 'audit')
ORDER BY s.name, t.name;
GO

-- ==========================================================
-- 2. COLUMNAS POR TABLA
-- ==========================================================
PRINT '2. COLUMNAS POR TABLA';
GO
SELECT
    s.name AS Esquema,
    t.name AS Tabla,
    c.column_id AS Orden,
    c.name AS Columna,
    ty.name AS TipoBase,
    CASE
        WHEN ty.name IN ('varchar', 'nvarchar', 'char', 'nchar')
        THEN ty.name + '(' + CASE WHEN c.max_length = -1 THEN 'MAX' ELSE CAST(c.max_length AS VARCHAR) END + ')'
        WHEN ty.name IN ('decimal', 'numeric')
        THEN ty.name + '(' + CAST(c.precision AS VARCHAR) + ',' + CAST(c.scale AS VARCHAR) + ')'
        ELSE ty.name
    END AS TipoCompleto,
    CASE WHEN c.is_nullable = 1 THEN 'SI' ELSE 'NO' END AS PermiteNull,
    CASE WHEN ic.column_id IS NOT NULL THEN 'PK' ELSE '' END AS EsPK,
    CASE WHEN c.is_identity = 1 THEN 'SI' ELSE 'NO' END AS EsIdentity,
    ISNULL(dc.definition, '') AS ValorPorDefecto
FROM sys.tables t
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN sys.columns c ON t.object_id = c.object_id
INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
LEFT JOIN sys.indexes i ON t.object_id = i.object_id AND i.is_primary_key = 1
LEFT JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id AND c.column_id = ic.column_id
LEFT JOIN sys.default_constraints dc ON c.default_object_id = dc.object_id
WHERE s.name IN ('core', 'academic', 'sales', 'security', 'audit')
ORDER BY s.name, t.name, c.column_id;
GO

-- ==========================================================
-- 3. RELACIONES (FOREIGN KEYS)
-- ==========================================================
PRINT '3. RELACIONES (FOREIGN KEYS)';
GO
SELECT
    s1.name AS EsquemaOrigen,
    t1.name AS TablaOrigen,
    c1.name AS ColumnaOrigen,
    s2.name AS EsquemaDestino,
    t2.name AS TablaDestino,
    c2.name AS ColumnaDestino,
    fk.name AS NombreFK,
    CASE WHEN fk.delete_referential_action = 1 THEN 'CASCADE' ELSE 'NO ACTION' END AS OnDelete
FROM sys.foreign_keys fk
INNER JOIN sys.tables t1 ON fk.parent_object_id = t1.object_id
INNER JOIN sys.schemas s1 ON t1.schema_id = s1.schema_id
INNER JOIN sys.tables t2 ON fk.referenced_object_id = t2.object_id
INNER JOIN sys.schemas s2 ON t2.schema_id = s2.schema_id
INNER JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
INNER JOIN sys.columns c1 ON fkc.parent_object_id = c1.object_id AND fkc.parent_column_id = c1.column_id
INNER JOIN sys.columns c2 ON fkc.referenced_object_id = c2.object_id AND fkc.referenced_column_id = c2.column_id
WHERE s1.name IN ('core', 'academic', 'sales', 'security', 'audit')
ORDER BY s1.name, t1.name, c1.name;
GO

-- ==========================================================
-- 4. UNIQUE CONSTRAINTS
-- ==========================================================
PRINT '4. UNIQUE CONSTRAINTS';
GO
SELECT
    s.name AS Esquema,
    t.name AS Tabla,
    i.name AS NombreConstraint,
    STRING_AGG(c.name, ', ') WITHIN GROUP (ORDER BY ic.key_ordinal) AS Columnas
FROM sys.indexes i
INNER JOIN sys.tables t ON i.object_id = t.object_id
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
WHERE i.is_unique = 1
    AND i.is_primary_key = 0
    AND s.name IN ('core', 'academic', 'sales', 'security', 'audit')
GROUP BY s.name, t.name, i.name
ORDER BY s.name, t.name;
GO

-- ==========================================================
-- 5. CHECK CONSTRAINTS
-- ==========================================================
PRINT '5. CHECK CONSTRAINTS';
GO
SELECT
    s.name AS Esquema,
    t.name AS Tabla,
    cc.name AS NombreConstraint,
    cc.definition AS Definicion
FROM sys.check_constraints cc
INNER JOIN sys.tables t ON cc.parent_object_id = t.object_id
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE s.name IN ('core', 'academic', 'sales', 'security', 'audit')
ORDER BY s.name, t.name, cc.name;
GO

-- ==========================================================
-- 6. INDICES
-- ==========================================================
PRINT '6. INDICES';
GO
SELECT
    s.name AS Esquema,
    t.name AS Tabla,
    i.name AS NombreIndice,
    CASE
        WHEN i.is_primary_key = 1 THEN 'PRIMARY KEY'
        WHEN i.is_unique = 1 THEN 'UNIQUE'
        ELSE 'NONCLUSTERED'
    END AS TipoIndice,
    STRING_AGG(
        c.name + CASE WHEN ic.is_descending_key = 1 THEN ' DESC' ELSE ' ASC' END,
        ', '
    ) WITHIN GROUP (ORDER BY ic.key_ordinal) AS Columnas,
    ISNULL(i.filter_definition, '') AS Filtro
FROM sys.indexes i
INNER JOIN sys.tables t ON i.object_id = t.object_id
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
WHERE s.name IN ('core', 'academic', 'sales', 'security', 'audit')
    AND i.type > 0
GROUP BY s.name, t.name, i.name, i.is_primary_key, i.is_unique, i.filter_definition
ORDER BY s.name, t.name, i.is_primary_key DESC;
GO

-- ==========================================================
-- 7. ESTADISTICAS DE DATOS
-- ==========================================================
PRINT '7. ESTADISTICAS DE DATOS';
GO
SELECT 'core.Sedes' AS Tabla, COUNT(*) AS TotalRegistros FROM core.Sedes
UNION ALL SELECT 'core.Carreras', COUNT(*) FROM core.Carreras
UNION ALL SELECT 'core.Estudiantes', COUNT(*) FROM core.Estudiantes
UNION ALL SELECT 'core.PeriodosAcademicos', COUNT(*) FROM core.PeriodosAcademicos
UNION ALL SELECT 'core.Matriculas', COUNT(*) FROM core.Matriculas
UNION ALL SELECT 'academic.Profesores', COUNT(*) FROM academic.Profesores
UNION ALL SELECT 'academic.Cursos', COUNT(*) FROM academic.Cursos
UNION ALL SELECT 'academic.CarreraCursos', COUNT(*) FROM academic.CarreraCursos
UNION ALL SELECT 'academic.CursoProfesor', COUNT(*) FROM academic.CursoProfesor
UNION ALL SELECT 'sales.Promotores', COUNT(*) FROM sales.Promotores
UNION ALL SELECT 'sales.CampaniasAdmision', COUNT(*) FROM sales.CampaniasAdmision
UNION ALL SELECT 'sales.Comisiones', COUNT(*) FROM sales.Comisiones
UNION ALL SELECT 'security.Roles', COUNT(*) FROM security.Roles
UNION ALL SELECT 'security.Usuarios', COUNT(*) FROM security.Usuarios
UNION ALL SELECT 'audit.AuditLog', COUNT(*) FROM audit.AuditLog
ORDER BY Tabla;
GO

PRINT '============================================';
PRINT 'Consulta del diccionario finalizada.';
PRINT 'Exporte los resultados para generar documentos.';
PRINT '============================================';
GO
