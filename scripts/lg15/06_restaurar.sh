#!/bin/bash
# Paso 6: vuelve a encender el DataNode detenido y espera a que HDFS se estabilice.
# Uso: 06_restaurar.sh <numero de DataNode: 1|2|3>
source "$(dirname "$0")/config.sh"
DN="datanode${1:?Uso: $0 <1|2|3>}"

titulo "Paso 6: se restaura ${DN}"

echo
echo "\$ docker compose start ${DN}"
docker compose start "${DN}"

echo
echo "Esperando a que el NameNode vuelva a ver 3 DataNodes y elimine las réplicas sobrantes..."
TMP_FSCK="$(mktemp)"
for _ in $(seq 1 60); do
    nn hdfs fsck "${RAIZ_HDFS}" > "$TMP_FSCK" 2> /dev/null
    sobre=$(contador_fsck "$TMP_FSCK" "Over-replicated blocks")
    vivos=$(metrica NumLiveDataNodes)
    echo "  vivos=${vivos}  bloques sobre-replicados en ${RAIZ_HDFS}=${sobre}"
    if [ "${vivos:-0}" -eq 3 ] && [ "${sobre:-1}" -eq 0 ]; then
        break
    fi
    sleep 5
done

echo
echo "\$ hdfs fsck ${RAIZ_HDFS}   (resumen)"
grep -E "Total blocks|Minimally replicated|Over-replicated|Under-replicated|Average block replication|Missing blocks:|Number of data-nodes|is HEALTHY|is CORRUPT" "$TMP_FSCK"
rm -f "$TMP_FSCK"
