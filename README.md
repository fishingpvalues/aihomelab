# AI-Hosting Home Lab Simulation Manual (Mittwald-Inspired)

## Ziel

Ein vollständiges Setup zur lokalen Simulation eines AI-Hosting-Workflows wie bei Mittwald:

* Kubernetes-Cluster auf einem Windows-PC mit RTX 4070 Ti (via WSL2) als zentrale GPU-Node (Master+Worker)
* MacBook, Le Potato, iPad, Android-Termux als Clients via API
* Containerisierung aller Dienste
* Verwendung kleinerer LLMs + Vision + Embedding-Modelle
* Offloading via LMCache/llm-d
* Kompatibilität mit OpenAI API Schema (z.B. LiteLLM, vLLM, OpenWebUI)

---

## 1. Systemübersicht & Architektur

```
[PC (WSL2, RTX 4070 Ti)] <-- Kubernetes Cluster Master + Worker + GPU
│  ├─ Docker (NVIDIA)
│  ├─ vLLM, LiteLLM, LMCache, llm-d
│  ├─ PVC: HF-Modelle persistent
│  └─ Prometheus, Reverse Proxy, Swagger
│
├── MacBook: Client / Steuergerät
├── Le Potato: Lightweight Monitoring / Local Cache
├── Android + iPad: API-Zugriff, Mobile UI
```

---

## 2. Vorbereitungen

### 2.1 Windows-PC mit WSL2 (Ubuntu 22.04)

#### Installationen (Admin CMD):

```bash
wsl --install -d Ubuntu-22.04
wsl --set-version Ubuntu-22.04 2
wsl --update
```

#### Treiber & Docker:

* NVIDIA-Treiber (CUDA fähig) installieren
* Docker Desktop (mit WSL-Integration) installieren
* Docker Engine + Compose aktivieren
* Docker + NVIDIA-Support testen:

```bash
docker run --gpus all nvidia/cuda:12.2.0-base nvidia-smi
```

#### NVIDIA Container Toolkit in WSL2:

```bash
sudo apt update && sudo apt install -y nvidia-container-toolkit
sudo systemctl restart docker
```

### 2.2 Kubernetes (k3s) lokal installieren

```bash
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--node-taint CriticalAddonsOnly=true:NoExecute" sh -
kubectl get nodes
```

---

## 3. Basisdienste im Cluster

### 3.1 Persistent Volume Claims (PVC)

* Für HF-Modelle (lokale Downloads)
* Mount via HostPath:

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: model-cache
spec:
  capacity:
    storage: 100Gi
  accessModes:
    - ReadWriteMany
  hostPath:
    path: "/mnt/models"
```

### 3.2 vLLM Deployment (OpenAI-kompatibler Model-Runner)

```bash
helm repo add vllm https://vllm-project.github.io/helm-chart/
helm install vllm vllm/vllm -f values.yaml
```

* `values.yaml` enthält:

```yaml
model:
  name: mistralai/Mistral-7B-Instruct-v0.2
  quantization: gptq
  max_num_seqs: 16
  tensor_parallel_size: 1
  hf_token: <your_token>

gpu:
  enabled: true

storage:
  pvc: model-cache
```

### 3.3 LiteLLM (Routing + Token Mgmt)

```bash
docker run -d -p 4000:4000 --name=litellm \
  -v /mnt/config:/app/config \
  ghcr.io/berriai/litellm:latest \
  --config /app/config/config.yaml
```

```yaml
# config.yaml
litellm:
  model_list:
    - model_name: local-vllm
      base_url: http://vllm-service:8000
      api_key: default
```

---

## 4. Modelle installieren (MVP)

### GPT2

```bash
transformers-cli download gpt2 --cache-dir /mnt/models
```

### Clip-ViT-B/32 (Vision)

```bash
transformers-cli download openai/clip-vit-base-patch32
```

### all-MiniLM-L6-v2 (Embedding)

```bash
transformers-cli download sentence-transformers/all-MiniLM-L6-v2
```

---

## 5. LMCache oder llm-d installieren

### LMCache für CPU+RAM Offloading

```bash
git clone https://github.com/lm-sys/lmcache.git
cd lmcache && pip install .
```

* Konfiguriere Cache-Ordner + max RAM-Auslastung

### llm-d als Loadbalancer

```bash
docker run -d -p 8501:8501 ghcr.io/llm-tools/llm-d
```

---

## 6. Reverse Proxy & Gateway

```bash
# Caddy (oder Nginx)
caddy reverse-proxy --from :8080 --to localhost:4000
```

### IP-Filterung via Middleware

* Whitelist: lokale IPs + Devices

---

## 7. Monitoring & Metrics

### Prometheus + Grafana

```bash
helm install prom prometheus-community/kube-prometheus-stack
```

* Scraper für vLLM & LiteLLM einrichten (TPM, RPM etc.)

---

## 8. Nutzung auf Mac/iPad/Android

### Verbindung via LiteLLM Gateway (im Heimnetz)

* http\://<PC-IP>:8080/v1/completions
* API-Key: `default`
* Tools: OpenWebUI, AnyGPT, AnythingLLM, Dify

---

## 9. Sicherheit

### Hinweise zu vLLM Security

* Kein Auth by Default
* Token via Reverse Proxy erzwingen
* Optional: API-Routen filtern oder limitieren

---

## 10. Weiteres

* Backup-Skripte (PVCs, Configs)
* Datenformat `.safetensors`
* Dokumentation im lokalen Git-Repo
* Nutzung von `kubescape`, `trivy` für Security

---

## Nächste Schritte (optional)

* Deployment weiterer Modelle (Pixtral-12B, DeepSeek etc.)
* Toolcalls, WebSockets, Image-to-Text
* Offloading via `bitsandbytes`, `ggml`, `exllama` etc.
* Colocation-Strategie (z.B. mit Le Potato als Monitoring-Node)

---

> **Hinweis**: Für vollständige Helm-Charts, Dockerfiles, Configs, Swagger-Setup und automatisierte API-Key-Verwaltung folgt ein separates Repository. Gerne auf Wunsch!
