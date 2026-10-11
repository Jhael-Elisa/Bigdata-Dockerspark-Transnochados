#!/bin/bash
# Paso 1: crea en HDFS la estructura de directorios del grupo.
source "$(dirname "$0")/config.sh"

titulo "Paso 1: estructura de directorios en HDFS"

hdfs_cmd dfs -mkdir -p "${RAIZ_HDFS}/dataset_1GB" "${RAIZ_HDFS}/dataset_10GB" \
    "${RAIZ_HDFS}/resultados" "${RAIZ_HDFS}/evidencias"
hdfs_cmd dfs -ls "${RAIZ_HDFS}"
hdfs_cmd getconf -confKey dfs.replication
hdfs_cmd getconf -confKey dfs.blocksize
