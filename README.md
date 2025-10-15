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

## Usage

1. Build and start the containers:
   ```bash
   docker-compose up -d
   ```

2. Access services:
   - Spark Master UI: http://localhost:8080
   - Spark Worker UI: http://localhost:8081
   - YARN ResourceManager UI: http://localhost:8088
   - YARN NodeManager UI: http://localhost:8042
   - Hive Server: localhost:10000
   - Hive Metastore: localhost:9083

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