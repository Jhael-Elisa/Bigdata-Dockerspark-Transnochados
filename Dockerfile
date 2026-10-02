FROM eclipse-temurin:11-jdk

# Set versions
ENV HADOOP_VERSION=3.3.5
ENV SPARK_VERSION=3.4.1
ENV HIVE_VERSION=3.1.3

# Set environment variables
ENV HADOOP_HOME=/opt/hadoop
ENV SPARK_HOME=/opt/spark
ENV HIVE_HOME=/opt/hive
ENV PATH=$PATH:$HADOOP_HOME/bin:$SPARK_HOME/bin:$HIVE_HOME/bin

# Install necessary packages
RUN apt-get update && apt-get install -y \
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

# Download and install Hadoop
RUN wget https://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz \
    && tar -xzf hadoop-${HADOOP_VERSION}.tar.gz \
    && mv hadoop-${HADOOP_VERSION} ${HADOOP_HOME} \
    && rm hadoop-${HADOOP_VERSION}.tar.gz

# Download and install Spark
RUN wget https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop3.tgz \
    && tar -xzf spark-${SPARK_VERSION}-bin-hadoop3.tgz \
    && mv spark-${SPARK_VERSION}-bin-hadoop3 ${SPARK_HOME} \
    && rm spark-${SPARK_VERSION}-bin-hadoop3.tgz

# Download and install Hive
RUN wget https://archive.apache.org/dist/hive/hive-${HIVE_VERSION}/apache-hive-${HIVE_VERSION}-bin.tar.gz \
    && tar -xzf apache-hive-${HIVE_VERSION}-bin.tar.gz \
    && mv apache-hive-${HIVE_VERSION}-bin ${HIVE_HOME} \
    && rm apache-hive-${HIVE_VERSION}-bin.tar.gz

# Create necessary directories
RUN mkdir -p /opt/spark/work-dir
RUN mkdir -p /opt/hive/warehouse
RUN mkdir -p /opt/spark/logs
RUN mkdir -p /opt/hive/logs

# Copy configuration files
COPY config/spark/ ${SPARK_HOME}/conf/
COPY config/hive/ ${HIVE_HOME}/conf/

# Copy entrypoint script
COPY scripts/entrypoint.sh /
RUN chmod +x /entrypoint.sh

WORKDIR /opt/spark/work-dir

ENTRYPOINT ["/entrypoint.sh"]