import json
import requests


def lambda_handler(event, context):
    # Example of using requests
    print("This is my first CICD pipeline demo!")
    response = requests.get("https://api.github.com")
    return {
        'statusCode': 200,
        'body': json.dumps({
            'message': 'Hello from Lambda!',
            'api_response': response.json()
        })
    }
