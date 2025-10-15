from pyspark.sql import SparkSession
import time

def main():
    # Initialize Spark session with YARN
    spark = SparkSession.builder \
        .appName("YARNWordCount") \
        .master("yarn") \
        .config("spark.submit.deployMode", "client") \
        .getOrCreate()

    print("Successfully created Spark session")
    
    # Create some sample text
    text = [
        "Apache Spark is a multi-language engine for executing data engineering",
        "analytics and machine learning on single-node machines or clusters",
        "Apache Spark provides high-level APIs in Java Scala Python and R",
        "Spark runs on YARN Kubernetes Mesos or standalone"
    ]
    
    print("Created sample text data")

    # Create RDD from text
    rdd = spark.sparkContext.parallelize(text)
    
    # Split into words and count
    word_counts = rdd.flatMap(lambda line: line.split(" ")) \
                    .map(lambda word: (word.lower(), 1)) \
                    .reduceByKey(lambda a, b: a + b) \
                    .sortBy(lambda x: x[1], ascending=False)
    
    print("\nTop 10 most frequent words:")
    for word, count in word_counts.take(10):
        print(f"{word}: {count}")
    
    # Show execution details
    print("\nApplication Details:")
    print(f"Application ID: {spark.sparkContext.applicationId}")
    print(f"Web UI URL: {spark.sparkContext.uiWebUrl}")
    
    # Keep the application running for a few seconds to check the YARN UI
    print("\nWaiting for 10 seconds before shutting down...")
    time.sleep(10)
    
    # Clean up
    spark.stop()
    print("Spark session stopped")

if __name__ == "__main__":
    main()