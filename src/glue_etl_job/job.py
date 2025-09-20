import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame
from pyspark.sql.functions import col, sum as _sum, regexp_extract
from pyspark.sql.types import StringType

# Get arguments: the INPUT S3 path and the OUTPUT S3 path
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

# Read directly from the S3 input path, explicitly defining the format as CSV
input_dynamic_frame = glueContext.create_dynamic_frame.from_options(
    connection_type="s3",
    connection_options={"paths": [args['input_path']]},
    format="csv",
    format_options={"withHeader": True}
)

df = input_dynamic_frame.toDF()

# --- Transformation Logic ---
# 1. Clean the 'Units Sold' column by extracting leading numbers
df = df.withColumn("Cleaned Units Sold", regexp_extract(col("`Units Sold`"), r"(\d+)", 1))

# 2. Cast columns to the correct numeric types for calculation
df = df.withColumn("Units Sold Int", col("Cleaned Units Sold").cast("integer"))
df = df.withColumn("Unit Price Float", col("`Unit Price`").cast("float"))

# 3. Calculate total revenue for each record
df = df.withColumn("Total Revenue", col("Units Sold Int") * col("Unit Price Float"))

# --- THIS IS THE FIX ---
# 4. Group, aggregate, cast the result to a string, and RENAME the columns to be clean
aggregated_df = df.groupBy("`Item Type`") \
                  .agg(_sum("Total Revenue").alias("aggregated_revenue")) \
                  .withColumn("aggregated_revenue", col("aggregated_revenue").cast(StringType())) \
                  .withColumnRenamed("Item Type", "item_type")

output_dynamic_frame = DynamicFrame.fromDF(aggregated_df, glueContext, "aggregated_df")

# Write the final data to the specified output path
glueContext.write_dynamic_frame.from_options(
    frame=output_dynamic_frame,
    connection_type="s3",
    connection_options={"path": args['output_path']},
    format="parquet"
)

job.commit()