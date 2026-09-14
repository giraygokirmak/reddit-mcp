FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

COPY . /app
RUN pip install .

EXPOSE 8000

ENTRYPOINT ["/app/docker/entrypoint.sh"]
