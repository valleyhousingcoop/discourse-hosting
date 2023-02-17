FROM python:3.10

RUN pip install Flask gunicorn sentry-sdk[flask]

WORKDIR /code

COPY email_relay.py ./

EXPOSE 8080

CMD ["gunicorn", "-b", "0.0.0.0:8080", "--access-logfile=-", "--error-logfile=-", "email_relay:app"]
