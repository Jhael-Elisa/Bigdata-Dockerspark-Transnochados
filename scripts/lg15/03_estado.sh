#!/bin/bash
# Paso 3: registra el estado de los DataNodes y de los bloques del dataset.
# Uso: 03_estado.sh <1GB|10GB> <antes|durante|despues>
source "$(dirname "$0")/config.sh"
usar_dataset "$1"
FASE="${2:?Uso: $0 <1GB|10GB> <antes|durante|despues>}"

titulo "Estado ${FASE^^} de la falla - dataset de ${ETIQUETA}"

REPORTE="${DIR_RESULTADOS}/${ETIQUETA}_${FASE}_dfsadmin_report.txt"
FSCK="${DIR_RESULTADOS}/${ETIQUETA}_${FASE}_fsck.txt"

hdfs_cmd dfsadmin -report 2> /dev/null | tee "$REPORTE"
hdfs_cmd fsck "${RUTA}" -files -blocks -locations 2> /dev/null | tee "$FSCK"
distribucion_bloques "$FSCK" | tee "${DIR_RESULTADOS}/${ETIQUETA}_${FASE}_distribucion.txt"

echo
echo "Guardado en grupo${GRUPO}/resultados/${ETIQUETA}_${FASE}_*.txt"
