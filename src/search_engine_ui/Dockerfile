FROM python:3.6-alpine
ENV FLASK_APP=ui.py
WORKDIR /app
COPY . /app
RUN apk update && pip install -r /app/requirements.txt
WORKDIR /app/ui
ENTRYPOINT ["gunicorn", "ui:app", "-b", "0.0.0.0"]