#!/bin/bash
# Paso 7: copia a HDFS los resultados generados y muestra la estructura final.
source "$(dirname "$0")/config.sh"

titulo "Paso 7: resultados del grupo en HDFS"

for f in "${DIR_RESULTADOS}"/*.txt; do
    nn hdfs dfs -put -f - "${RAIZ_HDFS}/resultados/$(basename "$f")" < "$f"
done
hdfs_cmd dfs -ls -R -h "${RAIZ_HDFS}"
hdfs_cmd dfs -du -h "${RAIZ_HDFS}"
