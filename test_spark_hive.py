from pyspark.sql import SparkSession
import sys

try:
    print("Initializing Spark session with Hive support...")
    spark = SparkSession.builder \
        .appName("Spark Hive Test") \
        .config("spark.sql.warehouse.dir", "/opt/hive/warehouse") \
        .config("hive.metastore.uris", "thrift://hive-metastore:9083") \
        .enableHiveSupport() \
        .getOrCreate()

    print("\nDropping existing 'employees' table if it exists...")
    spark.sql("DROP TABLE IF EXISTS employees")

    print("\nCreating sample data...")
    data = [
        ("John", 30, "New York"),
        ("Anna", 25, "San Francisco"),
        ("Peter", 35, "London")
    ]
    df = spark.createDataFrame(data, ["name", "age", "city"])

    print("\nCreating Hive table 'employees'...")
    df.write.saveAsTable("employees")

    print("\nQuerying all employees:")
    result = spark.sql("SELECT * FROM employees")
    result.show()

    print("\nCalculating average age by city:")
    avg_age = spark.sql("""
        SELECT city, AVG(age) as avg_age 
        FROM employees 
        GROUP BY city
    """)
    avg_age.show()

    print("\nListing all tables in default database:")
    spark.sql("SHOW TABLES").show()

except Exception as e:
    print(f"\nError occurred: {str(e)}")
    sys.exit(1)

finally:
    print("\nClosing Spark session...")
    spark.stop()