FROM python:3.6-alpine
WORKDIR /app
COPY . /app
RUN apk update && pip install -r /app/requirements.txt
ENTRYPOINT ["python", "-u", "crawler/crawler.py", "https://vitkhab.github.io/search_engine_test_site/"]