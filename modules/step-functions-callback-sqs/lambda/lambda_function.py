import json
import os
import random
from time import time, sleep

import boto3


sfn = boto3.client("stepfunctions")
sqs = boto3.client("sqs")
QUEUE_URL = os.environ["QUEUE_URL"]


def handler(event, context):
    sleep(5)
    for record in event["Records"]:
        message = json.loads(record["body"])
        task_token = message["TaskToken"]

        if random.random() < 2 / 3:
            sfn.send_task_success(
                taskToken=task_token,
                output=json.dumps({
                    "status": "success",
                    "message": "Callback completed successfully.",
                }),
            )
        else:
            sfn.send_task_failure(
                taskToken=task_token,
                error="CallbackWorkerFailed",
                cause="The callback worker selected the failure path.",
            )

        # Delete only after the callback API accepts the token. If the callback
        # fails, leaving the message visible allows SQS to retry it.
        sqs.delete_message(
            QueueUrl=QUEUE_URL,
            ReceiptHandle=record["receiptHandle"],
        )

    return {"processed": len(event["Records"])}
