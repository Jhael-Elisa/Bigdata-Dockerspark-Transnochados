# Origen de Hadoop, Spark y Hive:
#   - "downloader" (por defecto): los descarga de Apache (lento: archive.apache.org).
#   - Una imagen local que ya los tenga en /opt, p. ej. "dockerspark-binaries:local",
#     para no volver a descargarlos (ver BINARIES_SOURCE en docker-compose.yml).
ARG BINARIES_SOURCE=downloader

# ---------------------------------------------------------------------------
# Etapa 1: descarga de binarios (solo se ejecuta si BINARIES_SOURCE=downloader)
# ---------------------------------------------------------------------------
FROM eclipse-temurin:8-jdk AS downloader

ARG HADOOP_VERSION=3.3.5
ARG SPARK_VERSION=3.4.1
ARG HIVE_VERSION=3.1.3
ARG APACHE_MIRROR=https://archive.apache.org/dist

RUN set -eux; \
    curl -fSL --retry 5 "${APACHE_MIRROR}/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz" | tar -xz -C /opt; \
    mv /opt/hadoop-${HADOOP_VERSION} /opt/hadoop; \
    rm -rf /opt/hadoop/share/doc

RUN set -eux; \
    curl -fSL --retry 5 "${APACHE_MIRROR}/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop3.tgz" | tar -xz -C /opt; \
    mv /opt/spark-${SPARK_VERSION}-bin-hadoop3 /opt/spark

RUN set -eux; \
    curl -fSL --retry 5 "${APACHE_MIRROR}/hive/hive-${HIVE_VERSION}/apache-hive-${HIVE_VERSION}-bin.tar.gz" | tar -xz -C /opt; \
    mv /opt/apache-hive-${HIVE_VERSION}-bin /opt/hive

FROM ${BINARIES_SOURCE} AS binaries

# ---------------------------------------------------------------------------
# Etapa 2: imagen final
# Java 8 es obligatorio: Hive 3.1.x no funciona con Java 11
# (ClassCastException AppClassLoader -> URLClassLoader al arrancar HiveServer2).
# ---------------------------------------------------------------------------
FROM eclipse-temurin:8-jdk

ENV HADOOP_HOME=/opt/hadoop
ENV SPARK_HOME=/opt/spark
ENV HIVE_HOME=/opt/hive
ENV PATH=$PATH:$HADOOP_HOME/bin:$SPARK_HOME/bin:$HIVE_HOME/bin

RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    curl \
    netcat-openbsd \
    python3 \
    python3-pip \
    ssh \
    pdsh \
    && rm -rf /var/lib/apt/lists/*

# Setup SSH for YARN
RUN ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && \
    chmod 0600 ~/.ssh/authorized_keys

COPY --from=binaries /opt/hadoop ${HADOOP_HOME}
COPY --from=binaries /opt/spark ${SPARK_HOME}
COPY --from=binaries /opt/hive ${HIVE_HOME}

RUN mkdir -p /opt/spark/work-dir /opt/spark/logs /opt/hive/warehouse /opt/hive/logs

# Copy configuration files
COPY config/spark/ ${SPARK_HOME}/conf/
COPY config/hive/ ${HIVE_HOME}/conf/

# Copy entrypoint script
COPY scripts/entrypoint.sh /
RUN chmod +x /entrypoint.sh

WORKDIR /opt/spark/work-dir

ENTRYPOINT ["/entrypoint.sh"]
