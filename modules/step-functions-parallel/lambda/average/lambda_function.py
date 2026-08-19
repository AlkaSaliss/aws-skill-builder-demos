import time


def lambda_handler(event, context):
    time.sleep(15)
    numbers = event["numbers"]
    return {"operation": "average", "result": sum(numbers) / len(numbers)}
