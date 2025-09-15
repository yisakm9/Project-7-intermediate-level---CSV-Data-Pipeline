import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame
from pyspark.sql.functions import col, sum as _sum
from pyspark.sql.types import StringType # Import StringType for casting

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

# Convert to Spark DataFrame for easier manipulation
df = input_dynamic_frame.toDF()

# --- Transformation Logic ---
# Ensure numeric columns are cast correctly for calculation
df = df.withColumn("Units Sold", col("Units Sold").cast("integer"))
df = df.withColumn("Unit Price", col("Unit Price").cast("float"))

# Calculate total revenue for each record
df = df.withColumn("Total Revenue", col("Units Sold") * col("Unit Price"))

# Group by 'Item Type' and calculate the sum of 'Total Revenue'
# --- THIS IS THE FIX ---
# Cast the final aggregated column to a StringType to prevent it from being null
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