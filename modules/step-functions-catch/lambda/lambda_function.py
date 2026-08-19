import json
import random
import time


class CustomError(Exception):
    pass


class GenericError(Exception):
    pass


def lambda_handler(event, context):
    outcome = random.randrange(3)
    print(json.dumps({"selected_outcome": outcome, "event": event}))

    if outcome == 0:
        raise CustomError("This is the custom error branch.")

    if outcome == 1:
        time.sleep(5)
        return {"status": "unexpectedly completed"}

    raise GenericError("This error is handled by the catch-all branch.")
