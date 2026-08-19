def lambda_handler(event, context):
    numbers = event["numbers"]
    return {"operation": "sum", "result": sum(numbers)}
