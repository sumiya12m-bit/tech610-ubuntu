import boto3

s3 = boto3.resource('s3')

bucket = s3.Bucket('tech610-sumiya-test-boto3')

bucket.objects.all().delete()

bucket.delete()

print("Bucket deleted successfully")
