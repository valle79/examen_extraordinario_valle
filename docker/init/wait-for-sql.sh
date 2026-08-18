#!/bin/bash
# =============================================
# Matricula Cloud 360 Enterprise
# wait-for-sql.sh | Arranque e inicializacion automatica
# =============================================
# Este script es el entrypoint del contenedor:
#   1. Inicia SQL Server en segundo plano.
#   2. Espera a que el motor responda.
#   3. Ejecuta init.sql (crea la BD, sus objetos y datos).
#   4. Mantiene el contenedor vivo esperando a SQL Server.
#
# Requiere la variable de entorno SA_PASSWORD (definida en compose).
# =============================================

set -u

# SQL Server 2025 instala sus herramientas en /opt/mssql-tools18
# (la ruta antigua /opt/mssql-tools NO existe en la imagen 2025).
SQLCMD=/opt/mssql-tools18/bin/sqlcmd

# -C : confia en el certificado autofirmado de SQL Server
#      (SQL Server 2022+ fuerza cifrado en las conexiones).
# -b : devuelve codigo de error distinto de 0 si falla una consulta.
# -I : activa QUOTED_IDENTIFIER (obligatorio para tablas con indices
#      filtrados; sqlcmd lo desactiva por defecto).
TRUST_ARGS="-C -b -I"

MAX_ATTEMPTS=90
ATTEMPTS=0

echo "[init] Iniciando SQL Server 2025 en segundo plano..."
/opt/mssql/bin/sqlservr &
SQL_PID=$!

echo "[init] Esperando a que SQL Server este listo (maximo $((MAX_ATTEMPTS * 2)) segundos)..."

# Espera triple:
#  1) Que el servidor responda (SELECT 1).
#  2) Que las bases del sistema (master/msdb/model) esten ONLINE: en el
#     primer arranque msdb tarda (restaura sus indices) y crear la base
#     mientras el motor aun inicia provoca Msg 904 ("cannot be autostarted
#     during server shutdown or startup").
#  3) Que MatriculaCloud360DB este ONLINE o no exista (al reiniciar puede
#     estar en recuperacion y fallaria con Msg 904 "USE MatriculaCloud360DB").
until $SQLCMD -S localhost -U SA -P "$SA_PASSWORD" $TRUST_ARGS \
        -Q "IF EXISTS (SELECT 1 FROM sys.databases WHERE name IN ('master','model','msdb') AND state <> 0) THROW 50000, 'Sistema en recuperacion', 1; IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'MatriculaCloud360DB' AND state <> 0) THROW 50001, 'BD en recuperacion', 1; SELECT 1" > /dev/null 2>&1
do
    ATTEMPTS=$((ATTEMPTS + 1))
    if [ "$ATTEMPTS" -ge "$MAX_ATTEMPTS" ]; then
        echo "[init] ERROR: SQL Server no respondio despues de $MAX_ATTEMPTS intentos."
        echo "[init] Revisa los logs: docker compose logs sqlserver"
        exit 1
    fi
    sleep 2
done

echo "[init] SQL Server listo. Ejecutando init.sql..."

# Los scripts son IDEMPOTENTES, asi que ante un fallo puntual (p. ej. una
# carrera con la recuperacion de la base) se reintenta hasta 3 veces.
MAX_INIT_ATTEMPTS=3
INIT_ATTEMPTS=0
INIT_OK=0
while [ "$INIT_ATTEMPTS" -lt "$MAX_INIT_ATTEMPTS" ]; do
    INIT_ATTEMPTS=$((INIT_ATTEMPTS + 1))
    if $SQLCMD -S localhost -U SA -P "$SA_PASSWORD" $TRUST_ARGS \
            -i /docker-entrypoint-initdb.d/init.sql
    then
        INIT_OK=1
        break
    fi
    echo "[init] ERROR: init.sql fallo en el intento $INIT_ATTEMPTS/$MAX_INIT_ATTEMPTS. Reintentando en 10 segundos..."
    sleep 10
done

if [ "$INIT_OK" -eq 1 ]; then
    echo "[init] OK: Inicializacion completada correctamente."
else
    echo "[init] ERROR: init.sql termino con errores despues de $MAX_INIT_ATTEMPTS intentos."
    echo "[init] La base de datos puede estar incompleta. Revisa los logs."
fi

# =============================================
# Sincronizacion de respaldos hacia el proyecto:
# SQL Server escribe los respaldos en /var/opt/mssql/backup
# (volumen nombrado de Docker). Este bucle en segundo plano copia
# cada respaldo nuevo (.bak/.trn) tambien a /var/opt/mssql/backup-host,
# que es el bind-mount a docker/volumes/backup del proyecto.
# SQL Server jamas escribe en esa carpeta (evita el error 31 de
# Docker Desktop); solo este script (ejecutado como root) la llena.
#
# RETENCION: se eliminan automaticamente los respaldos mas antiguos
# que los dias configurados (BACKUP_RETENTION_FULL_DAYS para .bak y
# BACKUP_RETENTION_LOG_DAYS para .trn), tanto en el volumen nombrado
# como en la carpeta del proyecto. Por defecto: 7 y 2 dias.
# =============================================
BACKUP_HOST=/var/opt/mssql/backup-host
SYNC_INTERVAL=15
RETENTION_BAK_DAYS=${BACKUP_RETENTION_FULL_DAYS:-7}
RETENTION_TRN_DAYS=${BACKUP_RETENTION_LOG_DAYS:-2}
CLEANUP_EVERY=$(( (6 * 60 * 60) / SYNC_INTERVAL ))   # cada 6 horas
CLEANUP_COUNTER=0

cleanup_backups() {
    if [ "${RETENTION_BAK_DAYS}" -gt 0 ]; then
        find /var/opt/mssql/backup -maxdepth 1 -name '*.bak' -mtime "+${RETENTION_BAK_DAYS}" -delete 2>/dev/null
        [ -d "$BACKUP_HOST" ] && find "$BACKUP_HOST" -maxdepth 1 -name '*.bak' -mtime "+${RETENTION_BAK_DAYS}" -delete 2>/dev/null
    fi
    if [ "${RETENTION_TRN_DAYS}" -gt 0 ]; then
        find /var/opt/mssql/backup -maxdepth 1 -name '*.trn' -mtime "+${RETENTION_TRN_DAYS}" -delete 2>/dev/null
        [ -d "$BACKUP_HOST" ] && find "$BACKUP_HOST" -maxdepth 1 -name '*.trn' -mtime "+${RETENTION_TRN_DAYS}" -delete 2>/dev/null
    fi
}

# Limpieza inicial al arrancar + limpieza periodica dentro del bucle.
cleanup_backups
echo "[init] Sincronizacion y retencion de respaldos activas (cada $SYNC_INTERVAL s hacia $BACKUP_HOST; retencion ${RETENTION_BAK_DAYS}d .bak / ${RETENTION_TRN_DAYS}d .trn)."

(
    while true; do
        for f in /var/opt/mssql/backup/*.bak /var/opt/mssql/backup/*.trn; do
            [ -f "$f" ] || continue
            # Solo copia archivos cerrados (sin escribirle hace 5 seg).
            AGE=$(( $(date +%s) - $(stat -c %Y "$f" 2>/dev/null || echo 0) ))
            [ "${AGE:-0}" -ge 5 ] || continue
            cp -n "$f" "$BACKUP_HOST/" 2>/dev/null
        done
        CLEANUP_COUNTER=$((CLEANUP_COUNTER + 1))
        if [ "$CLEANUP_COUNTER" -ge "$CLEANUP_EVERY" ]; then
            cleanup_backups
            CLEANUP_COUNTER=0
        fi
        sleep "$SYNC_INTERVAL"
    done
) &

echo "[init] Contenedor operativo. Manteniendo SQL Server activo..."
wait $SQL_PID
