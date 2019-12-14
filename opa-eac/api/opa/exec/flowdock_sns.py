import botocore.vendored.requests as requests
import os

def lambda_handler(event, context):
    d = event_dict(event)
    print(d)

    #TODO: Parse the Alerts
    #TODO: get a flow token by source name instead of Hardcoding it
    #TODO: Organize the alert message
    print("Start")
    data = {
            "flow_token": "382c3ed6ecd94fbe49d51d14476d2a03",
            "event": "message",
            "content": "Howdy-Doo.This lambda can post a message."
        }
    print("Post")
    response = requests.post("https://api.flowdock.com/messages", data=data)
    print("Post Done")
    if not response.ok:
        response.raise_for_status()
    return "Done"

def event_dict(event):
    message = event["Records"][0]["Sns"]["Message"].strip()
    d = {k: v.strip("'") for k, v in (x.split("=") for x in message.split("\n"))}
    print(d)
    return d

# #flow token for flowdock-sns 382c3ed6ecd94fbe49d51d14476d2a03
# flow token for demo lambda e5f1396c9415e7f39de7f6505bca70eb
# chat = Chat('382c3ed6ecd94fbe49d51d14476d2a03')
# chat.post('Message posted to chat', 'Nihanshu')