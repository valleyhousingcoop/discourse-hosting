"""
Relay emails POSTed by sengrid to the local SMTP server at `mail-reciever`.
"""

import atexit
import os
import smtplib

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

smtp = smtplib.SMTP("mail-reciever")
atexit.register(smtp.close)


@app.route("/", methods=["GET", "POST"])
def hello_world():
    payload = request.form
    # https://docs.sendgrid.com/for-developers/parsing-email/setting-up-the-inbound-parse-webhook#raw-parameters
    smtp.sendmail(payload["from"], payload["to"], payload["email"])
    return "OK"


if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=8080)
