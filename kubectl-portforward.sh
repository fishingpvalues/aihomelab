#!/bin/bash
# Port-forward all services for external access
set -e
kubectl port-forward --address 0.0.0.0 service/vllm-service 8000:8000 &
kubectl port-forward --address 0.0.0.0 service/qdrant-service 6333:6333 &
kubectl port-forward --address 0.0.0.0 service/clip-service 8001:8001 &
kubectl port-forward --address 0.0.0.0 service/embedding-service 8002:8002 &
echo "Port forwarding started for vLLM (8000), Qdrant (6333), CLIP (8001), Embedding (8002)"
echo "Press Ctrl+C to stop."
wait 