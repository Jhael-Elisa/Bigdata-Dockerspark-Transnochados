#!/bin/bash

# Start SSH service
service ssh start

# Format HDFS if not already formatted
if [ ! -d "/tmp/hadoop-root/dfs/name" ]; then
    $HADOOP_HOME/bin/hdfs namenode -format
fi

# Start HDFS services
$HADOOP_HOME/sbin/start-dfs.sh

# Create necessary HDFS directories for Spark and YARN
$HADOOP_HOME/bin/hdfs dfs -mkdir -p /spark/jars
$HADOOP_HOME/bin/hdfs dfs -mkdir -p /spark/logs
$HADOOP_HOME/bin/hdfs dfs -mkdir -p /tmp
$HADOOP_HOME/bin/hdfs dfs -mkdir -p /user/root
$HADOOP_HOME/bin/hdfs dfs -chmod 777 /tmp
$HADOOP_HOME/bin/hdfs dfs -chmod 777 /user/root
$HADOOP_HOME/bin/hdfs dfs -chmod 777 /spark/logs

# Copy Spark jars to HDFS
$HADOOP_HOME/bin/hdfs dfs -put $SPARK_HOME/jars/* /spark/jars/

# Create Spark archive
cd $SPARK_HOME/jars
jar cvf spark-libs.jar *.jar
$HADOOP_HOME/bin/hdfs dfs -put spark-libs.jar /spark/

# Start YARN services
$HADOOP_HOME/sbin/start-yarn.sh

# Keep container running
tail -f /dev/null