import boto3

s3 = boto3.client('s3')

s3.upload_file('test.txt', 'tech610-sumiya-test-boto3', 'test.txt')

print("File uploaded successfully")
