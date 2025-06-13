# CLIP Vision Model Service

This service provides a FastAPI interface for the CLIP vision model (`clip-vit-base-patch32`).

## Build Docker Image

```bash
cd clip-service
# Optionally create a virtualenv and install requirements for local testing
# python -m venv venv && source venv/bin/activate && pip install -r requirements.txt
# Build Docker image
sudo docker build -t clip-service:latest .
```

## Run Locally (for testing)

```bash
python app.py
# or
uvicorn app:app --host 0.0.0.0 --port 8001
```

## Usage

POST to `/vision` with a JSON body:

```json
{"text": "A cat"}
```

Returns text features as a list.
