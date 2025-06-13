# Home AI Cluster: Plug-and-Play Quickstart

This project enables you to run a full AI stack (text, vision, embedding models) on your Windows PC (WSL2 + RTX 4070ti) with Kubernetes, Docker, vLLM, Qdrant, and FastAPI microservices. All clients (MacBook, iPad, Android, Le Potato) can query the stack over your home network.

---

## Prerequisites

- Windows PC with WSL2 (Ubuntu 22.04 recommended)
- NVIDIA GPU (RTX 4070ti or similar) with latest drivers
- Docker Desktop (with WSL2 integration)
- Kubernetes (k3d or k3s recommended)
- Python 3.9+ (for local testing)
- `kubectl` CLI
- (Optional) GNU Make

---

## 1. Clone the Repository

```bash
git clone <your-repo-url>
cd aihomelab
```

---

## 2. Download Models (Automated)

**Run the provided script to download all required models:**

```bash
pip install huggingface-hub
bash download-models.sh
```

This will download all models to `/mnt/models` in WSL2.

---

## 3. Build and Deploy Everything

**One command to build Docker images and apply all Kubernetes manifests:**

```bash
make all
```

---

## 4. Port Forward Services for LAN Access

**Expose all services on your Windows PC's IP:**

```bash
bash kubectl-portforward.sh
```

- vLLM: `8000`
- Qdrant: `6333`
- CLIP: `8001`
- Embedding: `8002`

---

## 5. Query from Any Device

- Use the endpoints as described in HOWTO.md (OpenAI client, curl, etc).
- Example for vLLM (OpenAI-compatible):

```python
from openai import OpenAI
client = OpenAI(base_url="http://<windows_ip>:8000/v1", api_key="my-secret-key")
completion = client.completions.create(model="gpt2", prompt="Hello, world!", max_tokens=50)
print(completion.choices[0].text)
```

---

## 6. Clean Up

**Remove all Kubernetes resources:**

```bash
make clean
# or
bash kubectl-cleanup.sh
```

---

## 7. File Map

- `Makefile` — Automates build and deployment
- `download-models.sh` — Automates model downloading
- `kubectl-portforward.sh` — Port-forwards all services
- `kubectl-cleanup.sh` — Cleans up all K8s resources
- `pv.yaml`, `pvc.yaml`, `*-deployment.yaml`, `*-service.yaml` — K8s manifests
- `clip-service/`, `embedding-service/` — Custom FastAPI microservices (Dockerized)
- `HOWTO.md` — Full manual and troubleshooting

---

## 8. Next Steps

- Open firewall ports (8000, 8001, 8002, 6333) on your Windows PC
- (Optional) Add `.env` files for secrets if you want to use environment variables
- Extend with more models/services as needed

---

## 9. License

MIT License (see LICENSE)

---

**Start with Step 1 above. For detailed troubleshooting or advanced configuration, see HOWTO.md.**
