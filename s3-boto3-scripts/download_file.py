import boto3

s3 = boto3.client('s3')

s3.download_file('tech610-sumiya-test-boto3', 'test.txt', 'downloaded_test.txt')

print("File downloaded successfully")
