#!/bin/bash

# Start SSH server
service ssh start

# Format namenode if it hasn't been formatted
if [ ! -d "/tmp/hadoop-root/dfs/name" ]; then
    $HADOOP_HOME/bin/hdfs namenode -format -force
fi

# Start HDFS daemons
$HADOOP_HOME/bin/hdfs --daemon start namenode
$HADOOP_HOME/bin/hdfs --daemon start datanode

# Wait for HDFS to be available
echo "Waiting for HDFS to be available..."
until $HADOOP_HOME/bin/hdfs dfs -ls / > /dev/null 2>&1; do
    echo "HDFS not ready yet..."
    sleep 5
done
echo "HDFS is now available"

# Create necessary HDFS directories
$HADOOP_HOME/bin/hdfs dfs -mkdir -p /spark/jars
$HADOOP_HOME/bin/hdfs dfs -mkdir -p /spark/logs
$HADOOP_HOME/bin/hdfs dfs -mkdir -p /tmp
$HADOOP_HOME/bin/hdfs dfs -mkdir -p /user/root

# Set permissions
$HADOOP_HOME/bin/hdfs dfs -chmod -R 777 /spark
$HADOOP_HOME/bin/hdfs dfs -chmod -R 777 /tmp
$HADOOP_HOME/bin/hdfs dfs -chmod -R 777 /user

# Copy Spark jars to HDFS (solo la primera vez: HDFS persiste en el volumen hdfs-data)
if ! $HADOOP_HOME/bin/hdfs dfs -test -e /spark/jars/spark-core_*.jar 2>/dev/null; then
    $HADOOP_HOME/bin/hdfs dfs -put -f $SPARK_HOME/jars/* /spark/jars/
fi

# Start YARN daemons
$HADOOP_HOME/bin/yarn --daemon start resourcemanager
$HADOOP_HOME/bin/yarn --daemon start nodemanager

# Keep the script running and show logs
tail -f $HADOOP_HOME/logs/*