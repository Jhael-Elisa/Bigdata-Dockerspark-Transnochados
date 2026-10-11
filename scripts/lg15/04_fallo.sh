#!/bin/bash
# Paso 4: detiene un DataNode y observa cómo reacciona HDFS hasta que
# los bloques del dataset recuperan su factor de replicación.
# Uso: 04_fallo.sh <1GB|10GB> <numero de DataNode: 1|2|3>
source "$(dirname "$0")/config.sh"
usar_dataset "$1"
DN="datanode${2:?Uso: $0 <1GB|10GB> <1|2|3>}"

titulo "Paso 4: FALLA de ${DN} - dataset de ${ETIQUETA}"

TMP_FSCK="$(mktemp)"
FSCK_DURANTE="${DIR_RESULTADOS}/${ETIQUETA}_durante_fsck.txt"
REGISTRO="${DIR_RESULTADOS}/${ETIQUETA}_falla_${DN}_monitoreo.txt"
TRANSFERENCIAS="${DIR_RESULTADOS}/${ETIQUETA}_falla_${DN}_nuevas_replicas.txt"
RESUMEN="${DIR_RESULTADOS}/${ETIQUETA}_falla_${DN}_resumen.txt"
rm -f "$FSCK_DURANTE"

# Réplicas del dataset que guarda el DataNode que se va a detener.
nn hdfs fsck "${RUTA}" -files -blocks -locations > "$TMP_FSCK" 2> /dev/null
distribucion_bloques "$TMP_FSCK" | tee "${TMP_FSCK}.dist"
afectados=$(awk -v dn="$DN" '$1 == dn {print $4}' "${TMP_FSCK}.dist")
total_bloques=$(contador_fsck "$TMP_FSCK" "Total blocks (validated)")
BLOQUES_DATASET="$(grep -o 'blk_[0-9]*' "$TMP_FSCK" | sort -u)"
echo
echo "${DN} guarda ${afectados} de los ${total_bloques} bloques del dataset."

echo
echo "\$ docker compose stop ${DN}"
docker compose stop "${DN}"
t0=$(date +%s)
echo "${DN} detenido a las $(date '+%H:%M:%S')"

echo
echo "¿El archivo sigue siendo legible justo después de la caída?"
echo "\$ hdfs dfs -head ${RUTA}"
nn hdfs dfs -head "${RUTA}" 2> /dev/null | head -3

echo
echo "Monitoreo. HDFS declara muerto al DataNode tras ~90 s sin heartbeats."
printf '%-9s %-7s %-9s %-24s\n' "TIEMPO" "VIVOS" "MUERTOS" "SUBREPLICADOS_DATASET" | tee "$REGISTRO"

t_muerto=""
t_recuperado=""
max_sub=0
estado_previo=""
t_impreso=0
while true; do
    nn hdfs fsck "${RUTA}" -files -blocks -locations > "$TMP_FSCK" 2> /dev/null
    sub=$(contador_fsck "$TMP_FSCK" "Under-replicated blocks")
    vivos=$(metrica NumLiveDataNodes)
    muertos=$(metrica NumDeadDataNodes)
    t=$(( $(date +%s) - t0 ))
    # Se muestra una línea cuando algo cambia o cada ~10 s.
    estado="${vivos}/${muertos}/${sub}"
    if [ "$estado" != "$estado_previo" ] || [ $((t - t_impreso)) -ge 10 ]; then
        printf '%-9s %-7s %-9s %-24s\n' "+${t}s" "$vivos" "$muertos" "$sub" | tee -a "$REGISTRO"
        estado_previo="$estado"
        t_impreso=$t
    fi

    if [ -z "$t_muerto" ] && [ "${muertos:-0}" -ge 1 ]; then
        t_muerto=$t
        echo "   >> El NameNode declaró MUERTO a ${DN} (+${t}s)" | tee -a "$REGISTRO"
    fi
    if [ "${sub:-0}" -gt "$max_sub" ]; then
        max_sub=$sub
        cp "$TMP_FSCK" "$FSCK_DURANTE"
    fi
    # Termina cuando, tras la caída, los bloques subreplicados vuelven a 0
    # (o si el DataNode no guardaba réplicas del dataset y no hay nada que recuperar).
    if [ -n "$t_muerto" ] && [ "${sub:-0}" -eq 0 ]; then
        if [ "$max_sub" -gt 0 ] || [ "${afectados:-0}" -eq 0 ] || [ $((t - t_muerto)) -gt 60 ]; then
            t_recuperado=$t
            echo "   >> Todos los bloques del dataset vuelven a tener sus réplicas (+${t}s)" | tee -a "$REGISTRO"
            break
        fi
    fi
    if [ "$t" -gt 1800 ]; then
        echo "   >> Tiempo de espera agotado (30 min)" | tee -a "$REGISTRO"
        break
    fi
    # Cerca del momento de la detección se consulta sin pausa para no perder el evento.
    if [ "$t" -lt 75 ]; then sleep 4; fi
done

# Nuevas réplicas: transferencias DataNode -> DataNode ordenadas por el NameNode.
docker compose logs --no-log-prefix --since "$t0" datanode1 datanode2 datanode3 2> /dev/null \
    | grep "Transmitted" | grep -F -f <(echo "$BLOQUES_DATASET") \
    | sed -E 's/^([0-9-]+ [0-9:]+),[0-9]+ .*DataTransfer, at ([a-z0-9]+):[0-9]+: Transmitted [^:]+:(blk_[0-9]+)_[0-9]+ \(numBytes=([0-9]+)\) to \/([0-9.]+):.*/\1  \2 -> \5  \3  \4 bytes/' \
    | sort > "$TRANSFERENCIAS"
nuevas=$(wc -l < "$TRANSFERENCIAS")

if [ -f "$FSCK_DURANTE" ]; then
    echo
    echo "fsck en el momento de máxima subreplicación (grupo${GRUPO}/resultados/$(basename "$FSCK_DURANTE")):"
    grep -E "Under-replicated blocks|Minimally replicated blocks|Average block replication|Missing blocks:|Number of data-nodes|is HEALTHY|is CORRUPT" "$FSCK_DURANTE"
    grep -o "Under replicated [^.]*\. Target Replicas is [0-9]* but found [0-9]* live replica(s)" "$FSCK_DURANTE" | head -3
fi

echo
echo "Re-replicación automática (logs de los DataNodes, hora UTC; origen -> IP destino):"
head -5 "$TRANSFERENCIAS"
[ "$nuevas" -gt 5 ] && echo "   ... (${nuevas} en total, ver grupo${GRUPO}/resultados/$(basename "$TRANSFERENCIAS"))"

{
    echo
    echo "RESUMEN - GRUPO ${GRUPO} - dataset ${ETIQUETA} - falla de ${DN}"
    echo "Bloques del dataset:                        ${total_bloques}"
    echo "Bloques con réplica en ${DN} (afectados): ${afectados}"
    echo "Bloques subreplicados (máximo observado):   ${max_sub}"
    echo "Nuevas réplicas creadas:                    ${nuevas}"
    echo "Tiempo hasta detectar la caída:             ${t_muerto:-no detectado} s"
    if [ -n "$t_recuperado" ]; then
        echo "Tiempo de re-replicación (tras detectar):   $((t_recuperado - t_muerto)) s"
        echo "Tiempo total de recuperación:               ${t_recuperado} s"
    fi
} | tee "$RESUMEN"
rm -f "$TMP_FSCK" "${TMP_FSCK}.dist"
