import json
import logging
import boto3
import os

logger = logging.getLogger()
# No log level needed if I understand https://docs.aws.amazon.com/powertools/python/latest/core/logger/#aws-lambda-advanced-logging-controls-alc correctly
# log_level = os.environ['LOG_LEVEL']
# logger.setLevel(logging.getLevelName(log_level))

client = boto3.client('dynamodb')
dynamodb = boto3.resource("dynamodb")
# table = dynamodb.Table('http-crud-tutorial-items')
# tableName = 'http-crud-tutorial-items'
table_name = os.environ['DYNAMODB_TABLE_NAME']
table = dynamodb.Table(table_name)

# environment = os.environ['ENVIRONMENT']

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

    # Get the length and width parameters from the event object. The 
    # runtime converts the event object to a Python dictionary
    # length = event['length']
    # width = event['width']
    
    # area = calculate_area(length, width)
    # print(f"The area is {area}")
        
    # logger.info(f"CloudWatch logs group: {context.log_group_name}")
    
    # # return the calculated area as a JSON string
    # data = {"area": area}
    # return json.dumps(data)
    
# def calculate_area(length, width):
#     return length*width