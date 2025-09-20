import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame
from pyspark.sql.functions import col, sum as _sum, regexp_extract
from pyspark.sql.types import StringType

args = getResolvedOptions(sys.argv, ['JOB_NAME'])

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# --- THIS IS THE FIX ---
# We now use the Glue Data Catalog directly, which is the best practice.
# The database and table names are passed in as arguments.
# This makes the job more reusable.

# Get job arguments passed from the Step Function
args = getResolvedOptions(sys.argv, [
    'JOB_NAME',
    'input_database',
    'input_table'
])

# Read data directly from the Glue Data Catalog
input_dynamic_frame = glueContext.create_dynamic_frame.from_catalog(
    database=args['input_database'],
    table_name=args['input_table']
)

df = input_dynamic_frame.toDF()

print("--- Initial Schema from Glue Catalog ---")
df.printSchema()

# --- Transformation Logic using CORRECT column names ---
# The crawler normalizes column names (e.g., "Units Sold" -> "units_sold")
df = df.withColumn("Cleaned Units Sold", regexp_extract(col("units_sold"), r"(\d+)", 1))

df = df.withColumn("Units Sold Int", col("Cleaned Units Sold").cast("integer"))
df = df.withColumn("Unit Price Float", col("unit_price").cast("float"))

df = df.withColumn("Total Revenue", col("Units Sold Int") * col("Unit Price Float"))

aggregated_df = df.groupBy("item_type") \
                  .agg(_sum("Total Revenue").alias("AggregatedRevenue")) \
                  .withColumn("AggregatedRevenue", col("AggregatedRevenue").cast(StringType()))

print("--- Final Aggregated Schema ---")
aggregated_df.printSchema()

output_dynamic_frame = DynamicFrame.fromDF(aggregated_df, glueContext, "aggregated_df")

# This is also a fix. The output path must be passed to the job.
args = getResolvedOptions(sys.argv, ['JOB_NAME', 'output_path'])

glueContext.write_dynamic_frame.from_options(
    frame=output_dynamic_frame,
    connection_type="s3",
    connection_options={"path": args['output_path']},
    format="parquet"
)

job.commit()