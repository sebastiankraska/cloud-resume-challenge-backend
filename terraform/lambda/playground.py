import json
import logging
import boto3
import os

logger = logging.getLogger()
# No log level needed if I understand https://docs.aws.amazon.com/powertools/python/latest/core/logger/#aws-lambda-advanced-logging-controls-alc correctly

client = boto3.client('dynamodb')
dynamodb = boto3.resource("dynamodb")
table_name = os.environ['DYNAMODB_TABLE_NAME']
table = dynamodb.Table(table_name)

def lambda_handler(event, context):
    
    print(f"The table is called {table}")
    response = table.update_item(
      Key={'id': 'stats'},  # ✅ Matches hash_key
      UpdateExpression='ADD visits :inc',  # whatever you do, do not call it 'counter' or 'count' - appearently these are reseversed keywoards
      ExpressionAttributeValues={':inc': 1},
      ReturnValues='UPDATED_NEW'
    )
    print(f"response is {response}")
    new_count = response['Attributes']['visits']
    print(f"new count is {new_count}")