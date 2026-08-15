-- =============================================
-- Matricula Cloud 360 Enterprise
-- optimization/01_indexes.sql | Estrategia de indices (Sprint 3)
-- =============================================
-- Descripcion: Nuevos indices creados a partir del ANALISIS DE LAS
-- CONSULTAS CRITICAS (ver optimization/03_performance_tests.sql y
-- docs/sprint3-informe.md). Se complementan los 14 indices creados
-- en el Sprint 1 (03_tables.sql) con indices compuestos, filtrados
-- y con columnas incluidas (covering) que eliminan operaciones
-- costosas (INDEX SCAN / KEY LOOKUP / RID LOOKUP) en las consultas
-- mas frecuentes del dashboard y reporteria analitica.
--
-- CONSULTA CRITICA ANALIZADA        -> INDICE CREADO EN ESTE SCRIPT
-- -------------------------------------------------------------------
-- Q1 Dashboard: matriculas por      -> IX_Matriculas_PeriodoEstado
--    periodo y estado (agrupadas)      (compuesto + filtrado + cover)
-- Q2 vw_RankingPromotores: ranking  -> IX_Matriculas_PromotorPeriodo
--    de promotores por periodo          (compuesto + filtrado + cover)
-- Q3 Comisiones por campana y       -> IX_Comisiones_Campania
--    estado de pago                     (compuesto + cover)
--
-- NOTA SOBRE EL INDICE AGRUPADO (CLUSTERED):
-- Todas las claves primarias (PK_*) se crearon como CLUSTERED, es
-- decir, la tabla fisicamente se ordena por su PK. Es el indice
-- agrupado natural del diseno (identidad + busqueda por PK en la
-- mayoria de los JOIN del sistema).
--
-- IDEMPOTENTE: cada indice se crea solo si no existe.
-- =============================================

USE MatriculaCloud360DB;
GO

SET QUOTED_IDENTIFIER ON;
GO

PRINT '============================================';
PRINT 'optimization/01_indexes.sql - Indices Sprint 3';
PRINT '============================================';
GO

-- =============================================
-- INDICE 1: IX_Matriculas_PeriodoEstado
-- Justificacion: Q1 (dashboard) agrupa matriculas activas por
-- PeriodoId y EstadoMatricula sumando MontoMatricula.
--   - Compuesto (PeriodoId, EstadoMatricula) -> Seek + agregacion
--   - Filtrado (DeletedAt IS NULL) -> solo activas (mas pequeño)
--   - INCLUDE -> covering total: evita KEY LOOKUP a la tabla base
-- =============================================
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Matriculas_PeriodoEstado' AND object_id = OBJECT_ID('core.Matriculas'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_Matriculas_PeriodoEstado
        ON core.Matriculas(PeriodoId, EstadoMatricula)
        INCLUDE (MontoMatricula, PromotorId, SedeId, CampaniaId)
        WHERE DeletedAt IS NULL;
    PRINT 'OK: IX_Matriculas_PeriodoEstado creado (Q1 dashboard).';
END
ELSE
    PRINT 'OK: IX_Matriculas_PeriodoEstado ya existe.';
GO

-- =============================================
-- INDICE 2: IX_Matriculas_PromotorPeriodo
-- Justificacion: Q2 (vw_RankingPromotores) agrupa por PromotorId y
-- PeriodoId (funciones de ventana ROW_NUMBER/RANK) sobre matriculas
-- activas. El indice compuesto + filtrado elimina el SCAN y permite
-- la lectura ordenada por promotor y periodo (ideal para la ventana).
-- =============================================
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Matriculas_PromotorPeriodo' AND object_id = OBJECT_ID('core.Matriculas'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_Matriculas_PromotorPeriodo
        ON core.Matriculas(PromotorId, PeriodoId)
        INCLUDE (MontoMatricula, EstadoMatricula, FechaMatricula, EstudianteId, SedeId)
        WHERE DeletedAt IS NULL;
    PRINT 'OK: IX_Matriculas_PromotorPeriodo creado (Q2 ranking promotores).';
END
ELSE
    PRINT 'OK: IX_Matriculas_PromotorPeriodo ya existe.';
GO

-- =============================================
-- INDICE 3: IX_Comisiones_Campania
-- Justificacion: Q3 consulta comisiones por CampaniaId y EstadoPago
-- (pendientes/pagadas) para el plan de pagos a promotores. Indice
-- compuesto + covering: evita el scan y el lookup a la tabla base.
-- =============================================
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Comisiones_Campania' AND object_id = OBJECT_ID('sales.Comisiones'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_Comisiones_Campania
        ON sales.Comisiones(CampaniaId, EstadoPago)
        INCLUDE (MontoTotal, PromotorId, FechaPago);
    PRINT 'OK: IX_Comisiones_Campania creado (Q3 comisiones por campana).';
END
ELSE
    PRINT 'OK: IX_Comisiones_Campania ya existe.';
GO

-- =============================================
-- RESUMEN DE LA ESTRATEGIA DE INDEXACION
-- =============================================
PRINT '';
PRINT '============================================';
PRINT 'ESTRATEGIA GLOBAL DE INDICES:';
PRINT '--------------------------------------------';
PRINT '  Sprint 1: 14 indices (basicos + filtrados)';
PRINT '  Sprint 3:  3 indices nuevos ';
PRINT '             (compuestos + filtrados + cover)';
PRINT '  Total    : 17 indices no agrupados';
PRINT '--------------------------------------------';
PRINT '  Agrupados (clustered): 17 PK_*  (orden fisico)';
PRINT '============================================';
GO