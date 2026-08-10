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

echo "[init] Contenedor operativo. Manteniendo SQL Server activo..."
wait $SQL_PID
