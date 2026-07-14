import boto3

s3 = boto3.client('s3', region_name='eu-west-1')

s3.create_bucket(
    Bucket='tech610-sumiya-test-boto3',
    CreateBucketConfiguration={'LocationConstraint': 'eu-west-1'}
)

print("Bucket created successfully")
