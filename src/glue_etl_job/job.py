import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame
from pyspark.sql.functions import col, sum as _sum, regexp_extract
from pyspark.sql.types import StringType

# Get all arguments passed from the Step Function at the start
args = getResolvedOptions(sys.argv, [
    'JOB_NAME',
    'input_database',
    'input_table',
    'output_path'
])

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# --- THIS IS THE FIX ---
# Instead of a simple from_catalog, we use a more specific call that
# explicitly tells Glue the format of the data, overriding any
# incorrect classification from the crawler.
input_dynamic_frame = glueContext.create_dynamic_frame.from_catalog(
    database=args['input_database'],
    table_name=args['input_table'],
    transformation_ctx="input_dynamic_frame",
    additional_options={"classification": "csv", "separator": ",", "withHeader": True}
)

df = input_dynamic_frame.toDF()

# --- Transformation Logic using CORRECT, crawler-generated column names ---
df = df.withColumn("Cleaned Units Sold", regexp_extract(col("`Units Sold`"), r"(\d+)", 1))
df = df.withColumn("Units Sold Int", col("Cleaned Units Sold").cast("integer"))
df = df.withColumn("Unit Price Float", col("`Unit Price`").cast("float"))
df = df.withColumn("Total Revenue", col("Units Sold Int") * col("Unit Price Float"))

aggregated_df = df.groupBy("`Item Type`") \
                  .agg(_sum("Total Revenue").alias("AggregatedRevenue")) \
                  .withColumn("AggregatedRevenue", col("AggregatedRevenue").cast(StringType()))

output_dynamic_frame = DynamicFrame.fromDF(aggregated_df, glueContext, "aggregated_df")

# Write the final data to the specified output path
glueContext.write_dynamic_frame.from_options(
    frame=output_dynamic_frame,
    connection_type="s3",
    connection_options={"path": args['output_path']},
    format="parquet"
)

job.commit()