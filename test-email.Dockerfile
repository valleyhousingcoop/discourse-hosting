FROM python:latest

WORKDIR /usr/src/app

COPY test_email.py ./

CMD [ "python", "./test_email.py" ]
