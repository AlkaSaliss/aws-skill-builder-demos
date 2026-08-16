import json


class CustomError(Exception):
    pass


def lambda_handler(event, context):
    print("Received event: " + json.dumps(event, indent=2))
    raise CustomError("This is a custom error for testing retries.")