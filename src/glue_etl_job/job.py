import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame
from pyspark.sql.functions import col, sum as _sum, regexp_extract
from pyspark.sql.types import StringType, IntegerType, FloatType

# Get arguments passed from the Step Function
args = getResolvedOptions(sys.argv, [
    'JOB_NAME',
    'input_path',
    'output_path'
])

# Standard Glue job setup
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# Read the raw/uncleaned CSV from the S3 input path
input_dynamic_frame = glueContext.create_dynamic_frame.from_options(
    connection_type="s3",
    connection_options={"paths": [args['input_path']]},
    format="csv",
    format_options={"withHeader": True}
)

df = input_dynamic_frame.toDF()

# --- THIS IS THE FINAL, GUARANTEED FIX ---
# Step 1: Normalize all column names to be clean and predictable.
# This is a professional data engineering best practice.
for column in df.columns:
    new_column_name = column.lower().replace(' ', '_')
    df = df.withColumnRenamed(column, new_column_name)

print("--- Schema After Normalization ---")
df.printSchema()

# Step 2: Perform all subsequent operations using the clean, predictable names.
# No more backticks or guessing about spaces.
df = df.withColumn("cleaned_units_sold", regexp_extract(col("units_sold"), r"(\d+)", 1))
df = df.withColumn("units_sold_int", col("cleaned_units_sold").cast(IntegerType()))
df = df.withColumn("unit_price_float", col("unit_price").cast(FloatType()))

# Step 3: CRITICAL - Drop rows where casting failed (e.g., empty Unit Price)
df = df.dropna(subset=["units_sold_int", "unit_price_float"])

# Step 4: Calculate total revenue for each valid record
df = df.withColumn("total_revenue", col("units_sold_int") * col("unit_price_float"))

# Step 5: Group, aggregate, and ensure the final columns have clean names
aggregated_df = df.groupBy("item_type") \
                  .agg(_sum("total_revenue").alias("aggregated_revenue")) \
                  .withColumn("aggregated_revenue", col("aggregated_revenue").cast(StringType()))

print("--- Final Aggregated Schema ---")
aggregated_df.printSchema()

# Convert back to a DynamicFrame before writing
output_dynamic_frame = DynamicFrame.fromDF(aggregated_df, glueContext, "aggregated_df")

# Write the final, aggregated data to the output path in Parquet format
glueContext.write_dynamic_frame.from_options(
    frame=output_dynamic_frame,
    connection_type="s3",
    connection_options={"path": args['output_path']},
    format="parquet"
)

job.commit()