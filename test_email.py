"""
Send a test email to the discourse address to see if the mail reciever is working.
"""

import datetime
import os
import smtplib
from email.message import EmailMessage

msg = EmailMessage()
msg.set_content("""This is a new topic for the discourse forum.

It's a test, I hope it works very well.

Please let me know if it does not work.
""")

msg['Subject'] = 'A test post to see if the mail reciever is working.'
msg['From'] = os.environ['FROM_ADDRESS']
msg['To'] = os.environ['TO_ADDRESS']
msg['Date'] = datetime.datetime.now()

# Send the message via our own SMTP server.
s = smtplib.SMTP('mail-reciever')
print(s.send_message(msg))
s.quit()
