<<<<<<< HEAD
# Dockerized Spark, Hive, and YARN Environment

This project provides a containerized environment for Apache Spark, Apache Hive, and Apache Hadoop YARN using Docker.

## Components

- Apache Spark 3.4.1
- Apache Hive 3.1.3
- Apache Hadoop 3.3.5
- Apache YARN (Hadoop 3.3.5)

## Directory Structure

```
DockerSpark/
├── docker-compose.yml
├── Dockerfile
├── config/
│   ├── spark/
│   ├── hive/
│   └── hadoop/
├── scripts/
│   ├── entrypoint.sh
│   ├── init-hdfs.sh
│   └── init-yarn.sh
├── logs/
│   ├── spark/
│   ├── hive/
│   └── yarn/
└── data/
```

## Usage Guide

### Prerequisites

- Docker Engine 20.10.0 or later
- Docker Compose v2.0.0 or later
- At least 8GB of RAM allocated to Docker
- At least 20GB of free disk space

### Getting Started

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd DockerSpark
   ```

2. Build and start the containers:
   ```bash
   docker-compose up -d
   ```

3. Wait for all services to initialize (about 1-2 minutes)

4. Access service UIs:
   - Spark Master UI: http://localhost:8080
   - Spark Worker UI: http://localhost:8081
   - YARN ResourceManager UI: http://localhost:8088
   - YARN NodeManager UI: http://localhost:8042
   - Hive Server: localhost:10000
   - Hive Metastore: localhost:9083

### Running Spark Applications

#### 1. Using Spark Standalone Mode

```bash
# Submit a Python application
docker exec spark-master /opt/spark/bin/spark-submit \
    --master spark://spark-master:7077 \
    /path/to/your/app.py

# Submit a Spark SQL application
docker exec spark-master /opt/spark/bin/spark-sql \
    --master spark://spark-master:7077 \
    -f /path/to/your/query.sql
```

#### 2. Using YARN Mode

```bash
# Submit in client mode
docker exec spark-master /opt/spark/bin/spark-submit \
    --master yarn \
    --deploy-mode client \
    /path/to/your/app.py

# Submit in cluster mode
docker exec spark-master /opt/spark/bin/spark-submit \
    --master yarn \
    --deploy-mode cluster \
    /path/to/your/app.py
```

### Using Hive

1. Connect to Hive Server:
   ```bash
   docker exec -it hive-server beeline -u jdbc:hive2://localhost:10000
   ```

2. Run Hive queries:
   ```sql
   -- Create a database
   CREATE DATABASE example;
   USE example;

   -- Create a table
   CREATE TABLE test (id INT, name STRING);

   -- Insert data
   INSERT INTO test VALUES (1, 'test1'), (2, 'test2');

   -- Query data
   SELECT * FROM test;
   ```

### Working with HDFS

```bash
# List HDFS contents
docker exec yarn-resourcemanager hdfs dfs -ls /

# Create a directory
docker exec yarn-resourcemanager hdfs dfs -mkdir -p /user/data

# Upload a file
docker exec yarn-resourcemanager hdfs dfs -put /path/to/local/file /user/data/

# View a file
docker exec yarn-resourcemanager hdfs dfs -cat /user/data/file
```

### Example Applications

1. Run the included Spark-Hive test:
   ```bash
   docker cp test_spark_hive.py spark-master:/opt/spark/work-dir/
   docker exec spark-master /opt/spark/bin/spark-submit \
       --master spark://spark-master:7077 \
       /opt/spark/work-dir/test_spark_hive.py
   ```

2. Run the YARN test application:
   ```bash
   docker cp yarn_test.py spark-master:/opt/spark/work-dir/
   docker exec spark-master /opt/spark/bin/spark-submit \
       --master yarn \
       --deploy-mode client \
       /opt/spark/work-dir/yarn_test.py
   ```

### Monitoring and Maintenance

1. View container logs:
   ```bash
   # View Spark Master logs
   docker logs spark-master

   # View YARN ResourceManager logs
   docker logs yarn-resourcemanager
   ```

2. Access container shell:
   ```bash
   # Access Spark Master
   docker exec -it spark-master bash

   # Access YARN ResourceManager
   docker exec -it yarn-resourcemanager bash
   ```

3. Stop all services:
   ```bash
   docker-compose down
   ```

4. Reset everything (including volumes):
   ```bash
   docker-compose down -v
   ```

### Troubleshooting

1. If YARN applications fail to start:
   - Check YARN ResourceManager UI (http://localhost:8088)
   - Verify HDFS is running: `docker exec yarn-resourcemanager hdfs dfsadmin -report`
   - Check container logs for errors

2. If Spark applications fail:
   - Check Spark Master UI (http://localhost:8080)
   - Verify Spark Worker is connected
   - Check application logs in the respective UI

3. If Hive queries fail:
   - Verify Hive Metastore is running
   - Check Hive Server logs
   - Ensure the database exists and permissions are correct

## Configuration

Configuration files are located in the `config` directory:
- `config/spark/`: Spark configuration files
- `config/hive/`: Hive configuration files
- `config/hadoop/`: Hadoop/YARN configuration files

## Running Applications

### Submitting Spark Applications to YARN

You can submit Spark applications to YARN in either client or cluster mode:

```bash
# Client mode
spark-submit --master yarn --deploy-mode client your_app.py

# Cluster mode
spark-submit --master yarn --deploy-mode cluster your_app.py
```

### YARN Resource Management

The YARN ResourceManager is configured with a default queue that has:
- 100% capacity allocation
- Minimum user limit of 100%
- Fair scheduler for resource allocation

### HDFS Storage

HDFS is configured with:
- NameNode running on the YARN ResourceManager container
- DataNode running on the YARN NodeManager container
- Default replication factor of 1 for development purposes
- Root directories for Spark and YARN applications

## Monitoring

You can monitor your applications through:
1. YARN ResourceManager UI (http://localhost:8088) for:
   - Application status
   - Resource usage
   - Container allocation
2. YARN NodeManager UI (http://localhost:8042) for:
   - Container logs
   - Node health
3. Spark UI (http://localhost:8080) for:
   - Spark application details
   - Job progress
   - Stage information
=======
# Bigdata-Dockerspark-Transnochados
Clúster Big Data con Apache Spark, Hadoop, Hive y YARN desplegado con Docker Compose para almacenamiento HDFS y procesamiento distribuido.
>>>>>>> 11863254061d37cde9c1d13abfc66c3ec124c081
