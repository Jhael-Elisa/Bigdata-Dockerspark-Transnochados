#!/bin/bash
# Paso 2: genera el dataset y lo carga en HDFS.
# Uso: 02_cargar.sh <1GB|10GB>
source "$(dirname "$0")/config.sh"
usar_dataset "$1"

titulo "Paso 2: carga del dataset de ${ETIQUETA}"

echo
echo "Generando ${BYTES} bytes y cargando en ${RUTA} ..."
inicio=$(date +%s)
nn bash -c "bash /scripts/lg15/generar_dataset.sh ${BYTES} \
    | tee >(md5sum | cut -d' ' -f1 > /tmp/md5_${ETIQUETA}) \
    | hdfs dfs -put -f - '${RUTA}'; sleep 1"
fin=$(date +%s)
nn cat "/tmp/md5_${ETIQUETA}" > "${DIR_RESULTADOS}/${ETIQUETA}_md5_original.txt"

echo "Tiempo de carga: $((fin - inicio)) s"
echo "MD5 del dataset original: $(cat "${DIR_RESULTADOS}/${ETIQUETA}_md5_original.txt")"

hdfs_cmd dfs -ls -h "${RAIZ_HDFS}/dataset_${ETIQUETA}"
echo
echo "\$ hdfs dfs -stat 'replicacion=%r  tam_bloque=%o  bytes=%b' ${RUTA}"
nn hdfs dfs -stat 'replicacion=%r  tam_bloque=%o  bytes=%b' "${RUTA}"
echo
echo "\$ hdfs dfs -head ${RUTA}   (primeras líneas)"
nn hdfs dfs -head "${RUTA}" | head -5
