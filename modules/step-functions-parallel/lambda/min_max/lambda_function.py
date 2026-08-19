def lambda_handler(event, context):
    numbers = event["numbers"]
    return {
        "operation": "min_max",
        "minimum": min(numbers),
        "maximum": max(numbers),
    }
