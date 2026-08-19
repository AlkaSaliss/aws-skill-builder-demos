def lambda_handler(event, context):
    numbers = event["numbers"]
    return {"operation": "average", "result": sum(numbers) / len(numbers)}
