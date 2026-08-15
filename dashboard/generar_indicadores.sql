-- =============================================
-- Matricula Cloud 360 Enterprise
-- dashboard/generar_indicadores.sql
-- =============================================
-- GENERADOR DEL DASHBOARD DE INDICADORES INSTITUCIONALES (Sprint 3)
--
-- Consultas analiticas para: matriculas, carreras, sedes, campanas
-- y promotores. El script construye un reporte HTML autocontenido
-- (sin dependencias externas) y lo guarda en:
--       /dashboard/indicadores.html  ->  dashboard/indicadores.html (host)
-- (la carpeta dashboard/ esta montada en el host: docker-compose.yml)
--
-- Base del reporte: core.vw_IndicadoresMatricula,
-- sales.vw_RankingPromotores, core.vw_TendenciaMatriculas
-- (funciones de ventana del Sprint 3).
--
-- Uso:
--   docker compose exec sqlserver /opt/mssql-tools18/bin/sqlcmd `
--     -S localhost -U SA -P "$SA_PASSWORD" -C `
--     -i /dashboard/generar_indicadores.sql
-- =============================================

USE MatriculaCloud360DB;
GO

SET NOCOUNT ON;
GO

-- Todo el output va al archivo HTML (sin resultados tabulares)
:out /dashboard/indicadores.html

-- ============================================================
-- 1. INDICADORES CLAVE (KPIs)
-- ============================================================
DECLARE @TotalMatriculas INT = (SELECT COUNT(*) FROM core.Matriculas WHERE DeletedAt IS NULL);
DECLARE @EstudiantesActivos INT = (SELECT COUNT(*) FROM core.Estudiantes WHERE DeletedAt IS NULL);
DECLARE @Carreras INT = (SELECT COUNT(*) FROM core.Carreras WHERE DeletedAt IS NULL);
DECLARE @Sedes INT = (SELECT COUNT(*) FROM core.Sedes WHERE DeletedAt IS NULL);
DECLARE @Periodos INT = (SELECT COUNT(*) FROM core.PeriodosAcademicos);
DECLARE @Campanias INT = (SELECT COUNT(*) FROM sales.CampaniasAdmision);
DECLARE @Promotores INT = (SELECT COUNT(*) FROM sales.Promotores WHERE DeletedAt IS NULL);
DECLARE @ComisionesPagadas INT = (SELECT COUNT(*) FROM sales.Comisiones WHERE EstadoPago = 'Pagada');
DECLARE @ComisionesPendientes INT = (SELECT COUNT(*) FROM sales.Comisiones WHERE EstadoPago IN ('Pendiente', 'Aprobada'));
DECLARE @MontoRecaudado DECIMAL(12,2) = (SELECT ISNULL(SUM(MontoMatricula), 0) FROM core.Matriculas WHERE DeletedAt IS NULL);
DECLARE @MontoComisiones DECIMAL(12,2) = (SELECT ISNULL(SUM(MontoTotal), 0) FROM sales.Comisiones WHERE EstadoPago <> 'Anulada');

-- ============================================================
-- 2. FILAS DE TABLAS (FOR XML PATH)
-- ============================================================
DECLARE @RowsCarrera NVARCHAR(MAX), @MaxCarrera INT;
SELECT @MaxCarrera = MAX(cnt) FROM (
    SELECT COUNT(*) AS cnt FROM core.Matriculas WHERE DeletedAt IS NULL GROUP BY CarreraId
) t;

SELECT @RowsCarrera = STRING_AGG(rw, '') WITHIN GROUP (ORDER BY cnt DESC)
FROM (
    SELECT t.cnt, c.NombreCarrera, SUM(m.MontoMatricula) AS Monto
    FROM (
        SELECT CarreraId, COUNT(*) AS cnt
        FROM core.Matriculas WHERE DeletedAt IS NULL
        GROUP BY CarreraId
    ) t
    INNER JOIN core.Carreras c ON c.CarreraId = t.CarreraId
    INNER JOIN core.Matriculas m ON m.CarreraId = t.CarreraId AND m.DeletedAt IS NULL
    GROUP BY c.NombreCarrera, t.cnt
) d
CROSS APPLY (
    SELECT '<tr>' +
        '<td>' + REPLACE(REPLACE(REPLACE(d.NombreCarrera, '&', '&amp;'), '<', '&lt;'), '>', '&gt;') + '</td>' +
        '<td><div class="bar"><div class="fill" style="width:' + CAST(ROUND(100.0 * d.cnt / @MaxCarrera, 0) AS VARCHAR) + '%"></div></div></td>' +
        '<td class="num">' + CAST(d.cnt AS VARCHAR) + '</td>' +
        '<td class="num">' + REPLACE(CONVERT(VARCHAR, CAST(d.Monto AS MONEY), 1), '.00', '') + '</td>' +
        '</tr>' AS rw
) r;

DECLARE @RowsSede NVARCHAR(MAX), @MaxSede INT;
SELECT @MaxSede = MAX(cnt) FROM (
    SELECT COUNT(*) AS cnt FROM core.Matriculas WHERE DeletedAt IS NULL GROUP BY SedeId
) t;

SELECT @RowsSede = STRING_AGG(rw, '') WITHIN GROUP (ORDER BY cnt DESC)
FROM (
    SELECT t.cnt, s.NombreSede, SUM(m.MontoMatricula) AS Monto
    FROM (
        SELECT SedeId, COUNT(*) AS cnt
        FROM core.Matriculas WHERE DeletedAt IS NULL
        GROUP BY SedeId
    ) t
    INNER JOIN core.Sedes s ON s.SedeId = t.SedeId
    INNER JOIN core.Matriculas m ON m.SedeId = t.SedeId AND m.DeletedAt IS NULL
    GROUP BY s.NombreSede, t.cnt
) d
CROSS APPLY (
    SELECT '<tr>' +
        '<td>' + REPLACE(REPLACE(REPLACE(d.NombreSede, '&', '&amp;'), '<', '&lt;'), '>', '&gt;') + '</td>' +
        '<td><div class="bar"><div class="fill" style="width:' + CAST(ROUND(100.0 * d.cnt / @MaxSede, 0) AS VARCHAR) + '%"></div></div></td>' +
        '<td class="num">' + CAST(d.cnt AS VARCHAR) + '</td>' +
        '<td class="num">' + REPLACE(CONVERT(VARCHAR, CAST(d.Monto AS MONEY), 1), '.00', '') + '</td>' +
        '</tr>' AS rw
) r;

DECLARE @RowsPeriodo NVARCHAR(MAX);
SELECT @RowsPeriodo = STRING_AGG(rw, '') WITHIN GROUP (ORDER BY PeriodoId)
FROM (
    SELECT
        t.PeriodoId,
        p.CodigoPeriodo,
        t.n,
        t.monto,
        t.pct
    FROM (
        SELECT
            PeriodoId,
            COUNT(*) AS n,
            SUM(MontoMatricula) AS monto,
            100.0 * COUNT(*) / SUM(COUNT(*)) OVER () AS pct
        FROM core.Matriculas WHERE DeletedAt IS NULL
        GROUP BY PeriodoId
    ) t
    INNER JOIN core.PeriodosAcademicos p ON p.PeriodoId = t.PeriodoId
) d
CROSS APPLY (
    SELECT '<tr>' +
        '<td>' + d.CodigoPeriodo + '</td>' +
        '<td class="num">' + CAST(d.n AS VARCHAR) + '</td>' +
        '<td class="num">' + REPLACE(CONVERT(VARCHAR, CAST(d.monto AS MONEY), 1), '.00', '') + '</td>' +
        '<td class="num">' + CAST(ROUND(d.pct, 1) AS VARCHAR) + '%</td>' +
        '</tr>' AS rw
) r;

DECLARE @RowsCampania NVARCHAR(MAX);
SELECT @RowsCampania = STRING_AGG(rw, '') WITHIN GROUP (ORDER BY n DESC)
FROM (
    SELECT ca.NombreCampania, ca.CodigoCampania, COUNT(m.MatriculaId) AS n, ISNULL(SUM(m.MontoMatricula), 0) AS Monto
    FROM sales.CampaniasAdmision ca
    LEFT JOIN core.Matriculas m ON m.CampaniaId = ca.CampaniaId AND m.DeletedAt IS NULL
    GROUP BY ca.NombreCampania, ca.CodigoCampania
) d
CROSS APPLY (
    SELECT '<tr>' +
        '<td>' + REPLACE(REPLACE(REPLACE(d.NombreCampania, '&', '&amp;'), '<', '&lt;'), '>', '&gt;') + '</td>' +
        '<td>' + d.CodigoCampania + '</td>' +
        '<td class="num">' + CAST(d.n AS VARCHAR) + '</td>' +
        '<td class="num">' + REPLACE(CONVERT(VARCHAR, CAST(d.Monto AS MONEY), 1), '.00', '') + '</td>' +
        '</tr>' AS rw
) r;

DECLARE @RowsRanking NVARCHAR(MAX), @MaxRank INT;
SELECT @MaxRank = MAX(MatriculasCaptadas) FROM sales.vw_RankingPromotores;

SELECT @RowsRanking = STRING_AGG(rw, '') WITHIN GROUP (ORDER BY CodigoPeriodo, Ranking)
FROM (
    SELECT TOP (10)
        Ranking, NombrePromotor, CodigoPeriodo, MatriculasCaptadas, ComisionTotal, VariacionComisionPct
    FROM sales.vw_RankingPromotores
) d
CROSS APPLY (
    SELECT '<tr>' +
        '<td class="num">' + CAST(d.Ranking AS VARCHAR) + '</td>' +
        '<td>' + REPLACE(REPLACE(REPLACE(d.NombrePromotor, '&', '&amp;'), '<', '&lt;'), '>', '&gt;') + '</td>' +
        '<td>' + d.CodigoPeriodo + '</td>' +
        '<td class="num">' + CAST(d.MatriculasCaptadas AS VARCHAR) + '</td>' +
        '<td class="num">' + REPLACE(CONVERT(VARCHAR, CAST(d.ComisionTotal AS MONEY), 1), '.00', '') + '</td>' +
        '<td class="num">' + CASE WHEN d.VariacionComisionPct IS NULL THEN '-' ELSE CAST(ROUND(d.VariacionComisionPct, 1) AS VARCHAR) + '%' END + '</td>' +
        '</tr>' AS rw
) r;

DECLARE @RowsTendencia NVARCHAR(MAX);
SELECT @RowsTendencia = STRING_AGG(rw, '') WITHIN GROUP (ORDER BY Fecha DESC)
FROM (
    SELECT TOP (15)
        Fecha, MatriculasDelDia, AcumuladoMatriculas, MontoDelDia, CrecimientoDiarioPct
    FROM core.vw_TendenciaMatriculas
) d
CROSS APPLY (
    SELECT '<tr>' +
        '<td>' + CONVERT(VARCHAR(10), d.Fecha, 103) + '</td>' +
        '<td class="num">' + CAST(d.MatriculasDelDia AS VARCHAR) + '</td>' +
        '<td class="num">' + CAST(d.AcumuladoMatriculas AS VARCHAR) + '</td>' +
        '<td class="num">' + REPLACE(CONVERT(VARCHAR, CAST(ISNULL(d.MontoDelDia, 0) AS MONEY), 1), '.00', '') + '</td>' +
        '<td class="num">' + CASE WHEN d.CrecimientoDiarioPct IS NULL THEN '-' ELSE CAST(ROUND(d.CrecimientoDiarioPct, 1) AS VARCHAR) + '%' END + '</td>' +
        '</tr>' AS rw
) r;

DECLARE @RowsAuditoria NVARCHAR(MAX);
SELECT @RowsAuditoria = STRING_AGG(rw, '') WITHIN GROUP (ORDER BY AuditId DESC)
FROM (
    SELECT TOP (10)
        AuditId, FechaOperacion, TableName, Operation, RecordId, Usuario
    FROM audit.AuditLog
) d
CROSS APPLY (
    SELECT '<tr>' +
        '<td>' + CONVERT(VARCHAR(10), d.FechaOperacion, 103) + ' ' + CONVERT(VARCHAR(8), d.FechaOperacion, 108) + '</td>' +
        '<td>' + REPLACE(REPLACE(REPLACE(d.TableName, '&', '&amp;'), '<', '&lt;'), '>', '&gt;') + '</td>' +
        '<td>' + d.Operation + '</td>' +
        '<td class="num">' + CAST(d.RecordId AS VARCHAR) + '</td>' +
        '<td>' + REPLACE(REPLACE(REPLACE(ISNULL(d.Usuario, '-'), '&', '&amp;'), '<', '&lt;'), '>', '&gt;') + '</td>' +
        '</tr>' AS rw
) r;

-- ============================================================
-- 3. INFORMACION DE RESPLADO Y MANTENIMIENTO
-- ============================================================
DECLARE @UltimoBackup NVARCHAR(200) = (SELECT TOP 1
    'FULL ' + CONVERT(VARCHAR(10), backup_finish_date, 103) + ' ' + CONVERT(VARCHAR(8), backup_finish_date, 108) + ' (' +
    CAST(CAST(backup_size / 1048576.0 AS DECIMAL(10,2)) AS VARCHAR) + ' MB) - ' + bmf.physical_device_name
    FROM msdb.dbo.backupset bs
    INNER JOIN msdb.dbo.backupmediafamily bmf ON bs.media_set_id = bmf.media_set_id
    WHERE bs.database_name = 'MatriculaCloud360DB' AND bs.type = 'D'
    ORDER BY bs.backup_finish_date DESC);

DECLARE @Jobs NVARCHAR(400) = ISNULL((
    SELECT STRING_AGG(name, ', ') FROM msdb.dbo.sysjobs WHERE name LIKE 'MC360_%' AND enabled = 1), 'sin jobs');

-- ============================================================
-- 4. CONSTRUCCION DEL HTML
-- ============================================================
DECLARE @h NVARCHAR(MAX) = N'';

SET @h = @h + N'<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<title>Matricula Cloud 360 Enterprise - Dashboard Sprint 3</title>
<style>
  body { font-family: "Segoe UI", Arial, sans-serif; margin: 0; background: #f3f6fa; color: #22303f; }
  header { background: linear-gradient(90deg, #0f4c81, #1d6fb8); color: #fff; padding: 22px 28px; }
  header h1 { margin: 0; font-size: 22px; }
  header p { margin: 4px 0 0; opacity: .85; font-size: 13px; }
  main { padding: 24px; max-width: 1100px; margin: 0 auto; }
  .kpis { display: grid; grid-template-columns: repeat(auto-fit, minmax(160px, 1fr)); gap: 12px; margin-bottom: 26px; }
  .kpi { background: #fff; border-radius: 10px; padding: 14px 16px; box-shadow: 0 1px 3px rgba(0,0,0,.08); border-top: 4px solid #1d6fb8; }
  .kpi .v { font-size: 24px; font-weight: 700; color: #0f4c81; }
  .kpi .l { font-size: 12px; color: #5a6b7b; margin-top: 2px; }
  .card { background: #fff; border-radius: 10px; padding: 18px 20px; margin-bottom: 22px; box-shadow: 0 1px 3px rgba(0,0,0,.08); }
  .card h2 { margin: 0 0 12px; font-size: 16px; color: #0f4c81; border-left: 4px solid #1d6fb8; padding-left: 10px; }
  table { width: 100%; border-collapse: collapse; font-size: 13px; }
  th { text-align: left; color: #5a6b7b; font-weight: 600; border-bottom: 2px solid #dbe4ec; padding: 8px 6px; }
  td { border-bottom: 1px solid #eef2f6; padding: 7px 6px; }
  .num { text-align: right; }
  .bar { background: #eef2f6; border-radius: 5px; height: 14px; width: 220px; }
  .fill { background: #1d6fb8; height: 14px; border-radius: 5px; }
  footer { text-align: center; color: #8b9aa8; font-size: 12px; padding: 18px; }
</style>
</head>
<body>
<header>
  <h1>Matricula Cloud 360 Enterprise</h1>
  <p>Dashboard de indicadores institucionales - Sprint 3 (auditoria, indices, seguridad, respaldo)</p>
  <p>Generado: ' + CONVERT(VARCHAR(10), GETDATE(), 103) + ' ' + CONVERT(VARCHAR(8), GETDATE(), 108) + '</p>
</header>
<main>
  <div class="kpis">
    <div class="kpi"><div class="v">' + CAST(@TotalMatriculas AS VARCHAR) + '</div><div class="l">Matriculas activas</div></div>
    <div class="kpi"><div class="v">' + CAST(@EstudiantesActivos AS VARCHAR) + '</div><div class="l">Estudiantes activos</div></div>
    <div class="kpi"><div class="v">' + CAST(@Carreras AS VARCHAR) + '</div><div class="l">Carreras</div></div>
    <div class="kpi"><div class="v">' + CAST(@Sedes AS VARCHAR) + '</div><div class="l">Sedes</div></div>
    <div class="kpi"><div class="v">' + CAST(@Periodos AS VARCHAR) + '</div><div class="l">Periodos academicos</div></div>
    <div class="kpi"><div class="v">' + CAST(@Campanias AS VARCHAR) + '</div><div class="l">Campanas de admision</div></div>
    <div class="kpi"><div class="v">' + CAST(@Promotores AS VARCHAR) + '</div><div class="l">Promotores</div></div>
    <div class="kpi"><div class="v">' + CAST(@ComisionesPagadas AS VARCHAR) + '</div><div class="l">Comisiones pagadas</div></div>
    <div class="kpi"><div class="v">' + REPLACE(CONVERT(VARCHAR, CAST(@MontoRecaudado AS MONEY), 1), '.00', '') + '</div><div class="l">Monto recaudado (S/)</div></div>
    <div class="kpi"><div class="v">' + REPLACE(CONVERT(VARCHAR, CAST(@MontoComisiones AS MONEY), 1), '.00', '') + '</div><div class="l">Comisiones por pagar (S/)</div></div>
  </div>';

SET @h = @h + N'  <div class="card">
    <h2>Matriculas por carrera (core.vw_IndicadoresMatricula)</h2>
    <table><tr><th>Carrera</th><th>Distribucion</th><th class="num">Matriculas</th><th class="num">Monto (S/)</th></tr>' +
    ISNULL(@RowsCarrera, '') + '</table></div>';

SET @h = @h + N'  <div class="card">
    <h2>Matriculas por sede</h2>
    <table><tr><th>Sede</th><th>Distribucion</th><th class="num">Matriculas</th><th class="num">Monto (S/)</th></tr>' +
    ISNULL(@RowsSede, '') + '</table></div>';

SET @h = @h + N'  <div class="card">
    <h2>Matriculas por periodo (ventana: participacion porcentual)</h2>
    <table><tr><th>Periodo</th><th class="num">Matriculas</th><th class="num">Monto (S/)</th><th class="num">Participacion</th></tr>' +
    ISNULL(@RowsPeriodo, '') + '</table></div>';

SET @h = @h + N'  <div class="card">
    <h2>Matriculas por campana de admision</h2>
    <table><tr><th>Campana</th><th>Codigo</th><th class="num">Matriculas</th><th class="num">Monto (S/)</th></tr>' +
    ISNULL(@RowsCampania, '') + '</table></div>';

SET @h = @h + N'  <div class="card">
    <h2>Ranking de promotores - top 10 (sales.vw_RankingPromotores, RANK + LAG)</h2>
    <table><tr><th>#</th><th>Promotor</th><th>Periodo</th><th class="num">Matriculas</th><th class="num">Comision (S/)</th><th class="num">Variacion vs period. ant.</th></tr>' +
    ISNULL(@RowsRanking, '') + '</table></div>';

SET @h = @h + N'  <div class="card">
    <h2>Tendencia diaria de matriculas (running total + LAG)</h2>
    <table><tr><th>Fecha</th><th class="num">Matriculas del dia</th><th class="num">Acumulado</th><th class="num">Monto del dia (S/)</th><th class="num">Crecimiento</th></tr>' +
    ISNULL(@RowsTendencia, '') + '</table></div>';

SET @h = @h + N'  <div class="card">
    <h2>Ultimas operaciones registradas en auditoria (audit.AuditLog)</h2>
    <table><tr><th>Fecha</th><th>Tabla</th><th>Operacion</th><th class="num">Registro</th><th>Usuario</th></tr>' +
    ISNULL(@RowsAuditoria, '') + '</table></div>';

SET @h = @h + N'  <div class="card">
    <h2>Respaldo y mantenimiento automatizado</h2>
    <table>
      <tr><th>Ultimo respaldo FULL</th><td>' + ISNULL(@UltimoBackup, 'Sin respaldos') + '</td></tr>
      <tr><th>Jobs de SQL Agent (MC360_*)</th><td>' + ISNULL(@Jobs, 'Sin jobs') + '</td></tr>
      <tr><th>Modelo de recuperacion</th><td>' + (SELECT recovery_model_desc FROM sys.databases WHERE name = 'MatriculaCloud360DB') + '</td></tr>
    </table></div>
</main>
<footer>Generado con consultas analiticas T-SQL (CTE + funciones de ventana) - Matricula Cloud 360 Enterprise</footer>
</body>
</html>';

-- ============================================================
-- 5. ESCRITURA DEL ARCHIVO (en bloques <= 800 caracteres)
-- Nota: sqlcmd trunca el output de PRINT a ~4000 bytes; bloques
-- pequenos garantizan que el HTML se escriba completo.
-- ============================================================
DECLARE @pos INT = 1;
DECLARE @len INT = LEN(@h);

WHILE @pos <= @len
BEGIN
    PRINT SUBSTRING(@h, @pos, 800);
    SET @pos = @pos + 800;
END
GO

:out stdout

PRINT 'Dashboard generado: /dashboard/indicadores.html (dashboard/indicadores.html en el host)';
GO