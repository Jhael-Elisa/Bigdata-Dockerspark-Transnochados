#!/bin/bash
# Configuración y funciones comunes de la práctica LG15
# (tolerancia a fallos y replicación de datos en HDFS).

GRUPO="${GRUPO:-02}"
RAIZ_HDFS="/grupo${GRUPO}"
NAMENODE_UI="http://localhost:9870"

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DIR_LOCAL="${REPO_DIR}/grupo${GRUPO}"
DIR_RESULTADOS="${DIR_LOCAL}/resultados"

cd "$REPO_DIR" || exit 1
mkdir -p "$DIR_RESULTADOS" "${DIR_LOCAL}/evidencias"

if ! docker ps > /dev/null 2>&1; then
    echo "No hay acceso a Docker. Ejecuta primero:  newgrp docker"
    exit 1
fi

# Ejecuta un comando dentro del contenedor del NameNode.
nn() {
    docker compose exec -T yarn-resourcemanager "$@"
}

# Ejecuta un comando hdfs en el NameNode mostrando antes el comando.
hdfs_cmd() {
    echo
    echo "\$ hdfs $*"
    nn hdfs "$@"
}

titulo() {
    echo
    echo "=================================================================="
    echo " LG15 - GRUPO ${GRUPO} - $*"
    echo " $(date '+%Y-%m-%d %H:%M:%S')"
    echo "=================================================================="
}

# Valida el tamaño del dataset (1GB o 10GB) y define RUTA, BYTES y ETIQUETA.
usar_dataset() {
    case "$1" in
        1GB)  BYTES=$((1 * 1024 * 1024 * 1024)) ;;
        10GB) BYTES=$((10 * 1024 * 1024 * 1024)) ;;
        *) echo "Uso: $0 <1GB|10GB> ..."; exit 1 ;;
    esac
    ETIQUETA="$1"
    RUTA="${RAIZ_HDFS}/dataset_${ETIQUETA}/dataset_grupo${GRUPO}_${ETIQUETA}"
}

# Lee una métrica numérica del NameNode (JMX).
metrica() {
    curl -s "${NAMENODE_UI}/jmx?qry=Hadoop:service=NameNode,name=FSNamesystemState" \
        | grep -o "\"$1\" : [0-9]*" | grep -o '[0-9]*$'
}

# Extrae un contador del resumen de fsck, p. ej. "Under-replicated blocks".
contador_fsck() {
    grep "$2:" "$1" | head -1 | awk -F':' '{print $2}' | awk '{print $1}'
}

# Tabla DataNode / IP / estado / bloques del dataset, a partir de una salida de fsck.
distribucion_bloques() {
    local salida_fsck="$1"
    echo
    echo "Distribución de las réplicas de ${RUTA}:"
    printf '%-12s %-14s %-8s %s\n' "DATANODE" "IP" "ESTADO" "REPLICAS_DEL_DATASET"
    nn hdfs dfsadmin -report 2> /dev/null | awk '
        /^Live datanodes/ { estado = "ACTIVO" }
        /^Dead datanodes/ { estado = "CAIDO" }
        /^Name:/          { split($2, a, ":"); ip = a[1] }
        /^Hostname:/      { print $2, ip, estado }
    ' | sort | while read -r host ip estado; do
        n=$(grep -o "DatanodeInfoWithStorage\[${ip}:" "$salida_fsck" | wc -l)
        printf '%-12s %-14s %-8s %s\n' "$host" "$ip" "$estado" "$n"
    done
}
