import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame
# Import the functions we need for data cleaning
from pyspark.sql.functions import col, sum as _sum, regexp_extract
from pyspark.sql.types import StringType

# Get job arguments
args = getResolvedOptions(sys.argv, ['JOB_NAME', 'input_path', 'output_path'])

# Initialize contexts
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# Read the preprocessed data from the S3 input path
input_dynamic_frame = glueContext.create_dynamic_frame.from_options(
    connection_type="s3",
    connection_options={"paths": [args['input_path']]},
    format="csv",
    format_options={"withHeader": True}
)

df = input_dynamic_frame.toDF()

# --- THIS IS THE FINAL FIX ---
# Robust Data Cleaning and Transformation Logic

# 1. Clean the 'Units Sold' column by extracting leading numbers
# The regex '(\d+)' captures one or more digits at the start of the string.
df = df.withColumn("Cleaned Units Sold", regexp_extract(col("Units Sold"), r"(\d+)", 1))

# 2. Cast columns to the correct numeric types for calculation
df = df.withColumn("Units Sold Int", col("Cleaned Units Sold").cast("integer"))
df = df.withColumn("Unit Price Float", col("Unit Price").cast("float"))

# 3. Calculate total revenue for each record
df = df.withColumn("Total Revenue", col("Units Sold Int") * col("Unit Price Float"))

# 4. Group by 'Item Type' and calculate the sum of 'Total Revenue'
#    Then, cast the final result to a StringType so it's never null in the JSON.
aggregated_df = df.groupBy("Item Type") \
                  .agg(_sum("Total Revenue").alias("AggregatedRevenue")) \
                  .withColumn("AggregatedRevenue", col("AggregatedRevenue").cast(StringType()))

print("Aggregation complete. Resulting schema:")
aggregated_df.printSchema()

# Convert back to DynamicFrame
output_dynamic_frame = DynamicFrame.fromDF(aggregated_df, glueContext, "aggregated_df")

# Write the final data to the output path in Parquet format
glueContext.write_dynamic_frame.from_options(
    frame=output_dynamic_frame,
    connection_type="s3",
    connection_options={"path": args['output_path']},
    format="parquet"
)

job.commit()