import json
from lambda_function import lambda_handler


def test_lambda_handler_success():
    event = {"key": "value"}
    response = lambda_handler(event, None)
    assert response["statusCode"] == 200
