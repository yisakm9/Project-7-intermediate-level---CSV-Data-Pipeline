import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame
from pyspark.sql.functions import col, sum as _sum, regexp_extract
from pyspark.sql.types import StringType, FloatType, IntegerType

args = getResolvedOptions(sys.argv, [
    'JOB_NAME',
    'input_path',
    'output_path'
])

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# Read the raw CSV directly from the S3 input path
input_dynamic_frame = glueContext.create_dynamic_frame.from_options(
    connection_type="s3",
    connection_options={"paths": [args['input_path']]},
    format="csv",
    format_options={"withHeader": True}
)

df = input_dynamic_frame.toDF()

# --- THIS IS THE FINAL FIX: All Cleaning and Transformation Logic is Here ---

# 1. Clean the 'Units Sold' column by extracting leading numbers
df = df.withColumn("Cleaned Units Sold", regexp_extract(col("`Units Sold`"), r"(\d+)", 1))

# 2. Cast all necessary columns to their correct numeric types
df = df.withColumn("Units Sold Int", col("Cleaned Units Sold").cast(IntegerType()))
df = df.withColumn("Unit Price Float", col("`Unit Price`").cast(FloatType()))

# 3. CRITICAL: Drop any rows where the casting failed (e.g., empty Unit Price)
#    This is the step that removes the bad data that was causing the nulls.
df = df.dropna(subset=["Units Sold Int", "Unit Price Float"])

# 4. Calculate total revenue for each valid record
df = df.withColumn("Total Revenue", col("Units Sold Int") * col("Unit Price Float"))

# 5. Group, aggregate, and RENAME the columns to create a clean, final schema
aggregated_df = df.groupBy("`Item Type`") \
                  .agg(_sum("Total Revenue").alias("aggregated_revenue")) \
                  .withColumn("aggregated_revenue", col("aggregated_revenue").cast(StringType())) \
                  .withColumnRenamed("Item Type", "item_type")

output_dynamic_frame = DynamicFrame.fromDF(aggregated_df, glueContext, "aggregated_df")

# Write the final, aggregated data to the output path in Parquet format
glueContext.write_dynamic_frame.from_options(
    frame=output_dynamic_frame,
    connection_type="s3",
    connection_options={"path": args['output_path']},
    format="parquet",
    # Use overwrite to ensure idempotency if the job is re-run
    format_options={"write.partition.overwrite.mode": "dynamic"}
)

job.commit()