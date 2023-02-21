"""
Relay emails POSTed by sengrid to the local SMTP server at `mail-reciever`.
"""

import os
import smtplib
import json

import sentry_sdk
from flask import Flask, request
from sentry_sdk.integrations.flask import FlaskIntegration

sentry_sdk.init(
    os.environ["SENTRY_DSN"],
    integrations=[FlaskIntegration()],
    send_default_pii=True,
    request_bodies="always",
    with_locals=True,
)


app = Flask(__name__)


@app.route("/", methods=["GET", "POST"])
def hello_world():
    smtp = smtplib.SMTP("mail-reciever")
    payload = request.form
    # Use envelope to get the sender and recipient, instead of to/from from email
    # so that to matches our address, not who was in the "to" field...
    envelope = json.loads(payload['envelope'])
    # https://docs.sendgrid.com/for-developers/parsing-email/setting-up-the-inbound-parse-webhook#raw-parameters
    smtp.sendmail(envelope["from"], envelope["to"], payload["email"])
    smtp.close()
    return "OK"

if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=8080)
