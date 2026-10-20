#!/bin/bash
# EXPOSICION: lee todo el archivo y compara su MD5 con el original de la carga.
# Si coinciden, la prueba respalda que el contenido leido se conservo.
# Ejecutar con el DataNode aun detenido permite comprobar lectura durante la falla.
# Comando en PowerShell: docker compose exec -T yarn-resourcemanager bash -c 'set -o pipefail; hdfs dfs -cat /grupo02/dataset_1GB/dataset_grupo02_1GB | md5sum'
# Comparar con el MD5 original del archivo actualmente cargado.

# Paso 5: lee el dataset completo desde HDFS y verifica su integridad (MD5).
# Uso: 05_leer.sh <1GB|10GB>
source "$(dirname "$0")/config.sh"
usar_dataset "$1"

titulo "Paso 5: lectura completa del dataset de ${ETIQUETA}"

echo
echo "DataNodes vivos: $(metrica NumLiveDataNodes)   muertos: $(metrica NumDeadDataNodes)"
hdfs_cmd dfs -ls -h "${RUTA}"

echo
echo "\$ hdfs dfs -cat ${RUTA} | md5sum"
inicio=$(date +%s)
md5_leido=$(nn bash -c "hdfs dfs -cat '${RUTA}' 2> /dev/null | md5sum | cut -d' ' -f1")
fin=$(date +%s)
md5_original=$(cat "${DIR_RESULTADOS}/${ETIQUETA}_md5_original.txt")

{
    echo "MD5 original (al cargar): ${md5_original}"
    echo "MD5 leído desde HDFS:     ${md5_leido}"
    echo "Tiempo de lectura:        $((fin - inicio)) s"
    if [ "$md5_leido" = "$md5_original" ]; then
        echo "RESULTADO: el archivo se leyó COMPLETO y sin corrupción"
    else
        echo "RESULTADO: el contenido leído NO coincide con el original"
    fi
} | tee "${DIR_RESULTADOS}/${ETIQUETA}_lectura_durante_falla.txt"
