# Embedding Model Service

This service provides a FastAPI interface for the `all-MiniLM-L6-v2` embedding model.

## Build Docker Image

```bash
cd embedding-service
# Optionally create a virtualenv and install requirements for local testing
# python -m venv venv && source venv/bin/activate && pip install -r requirements.txt
# Build Docker image
sudo docker build -t embedding-service:latest .
```

## Run Locally (for testing)

```bash
python app.py
# or
uvicorn app:app --host 0.0.0.0 --port 8002
```

## Usage

POST to `/embed` with a JSON body:

```json
{"text": "A sentence"}
```

Returns embedding as a list.
