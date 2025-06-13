Below is a detailed, step-by-step manual to set up a home AI cluster using your Windows PC (with WSL2 and an RTX 4070ti GPU) as both the Kubernetes master and worker node, leveraging Docker, CUDA, vLLM, Kubernetes, Qdrant, and LMCache for CPU and RAM offloading. Your MacBook will act as a client (not a server, as per your clarification that the server runs on the Windows PC), alongside your iPad, Android phone (via Termux), and Le Potato, to query the LLMs. This setup will simulate a full AI stack with smaller models like `gpt2` (text), `clip-vit-base-patch32` (vision), and `all-MiniLM-L6-v2` (embedding), all sharing the GPU, and will generate API tokens for OpenAI-compatible interfacing across your home network.

---

### Hardware Overview
- **Windows PC**: Runs WSL2, RTX 4070ti GPU, 64GB RAM, hosts Kubernetes master and worker, runs the AI server.
- **MacBook**: Client device for querying (macOS).
- **Le Potato**: Client device (Linux-based single-board computer).
- **iPad**: Client device (iOS).
- **Android Phone (Termux)**: Client device (Linux-like environment).

### Goals
- Run a Kubernetes cluster on the Windows PC via WSL2 with GPU support.
- Deploy `vLLM` for text models (`gpt2`), a custom service for vision models (`clip-vit-base-patch32`), and an embedding service (`all-MiniLM-L6-v2`) with Qdrant as the vector store.
- Use LMCache or vLLM’s native CPU offloading to leverage the PC’s CPU and 64GB RAM.
- Generate API tokens for secure querying from all devices over the home network.

---

## Step-by-Step Manual

### Step 1: Set Up WSL2 on Windows PC
1. **Enable WSL2**:
   - Open PowerShell as Administrator and run:
     ```powershell
     dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
     dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
     ```
   - Restart your PC.

2. **Install Ubuntu in WSL2**:
   - Open the Microsoft Store, search for "Ubuntu 22.04 LTS", and install it.
   - Launch Ubuntu from the Start menu, set up a username and password when prompted.

3. **Update Ubuntu**:
   - In the Ubuntu terminal:
     ```bash
     sudo apt update && sudo apt upgrade -y
     ```

---

### Step 2: Install Docker Desktop with WSL2 Integration
1. **Install Docker Desktop**:
   - Download Docker Desktop from [docker.com](https://www.docker.com/products/docker-desktop/).
   - Install it, ensuring the "Use WSL2" option is selected during setup.

2. **Enable WSL2 Integration**:
   - Open Docker Desktop > Settings > Resources > WSL Integration.
   - Enable integration with your Ubuntu-22.04 distro and click "Apply & Restart".

---

### Step 3: Set Up NVIDIA GPU Support
1. **Install NVIDIA Drivers on Windows**:
   - Visit [NVIDIA’s driver download page](https://www.nvidia.com/Download/index.aspx), select RTX 4070ti, download, and install the latest drivers.
   - Reboot if prompted.

2. **Verify GPU Access in WSL2**:
   - In Ubuntu (WSL2), test GPU availability via Docker:
     ```bash
     docker run --gpus all nvidia/cuda:11.0-base nvidia-smi
     ```
   - Expected output: Displays GPU info (e.g., RTX 4070ti). If it fails, ensure Docker Desktop and NVIDIA drivers are correctly installed.

---

### Step 4: Install k3d for Kubernetes on WSL2
1. **Install k3d**:
   - In Ubuntu:
     ```bash
     wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
     ```

2. **Create a Kubernetes Cluster with GPU Support**:
   - Create a single-node cluster (master and worker on Windows PC):
     ```bash
     k3d cluster create mycluster --gpus all -v /mnt/models:/models@agent:0
     ```
   - This mounts `/mnt/models` (for model storage) into the cluster.

3. **Verify Cluster**:
   - Check nodes:
     ```bash
     kubectl get nodes
     ```
   - Output should show one node (`k3d-mycluster-agent-0`).

4. **Install NVIDIA Device Plugin**:
   - Enable GPU scheduling in Kubernetes:
     ```bash
     kubectl apply -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/v0.14.1/nvidia-device-plugin.yml
     ```
   - Verify GPU availability:
     ```bash
     kubectl get nodes -o json | jq '.items[].status.capacity'
     ```
   - Look for `"nvidia.com/gpu": "1"`.

---

### Step 5: Set Up Persistent Storage for Models
1. **Create Model Directory in WSL2**:
   - In Ubuntu:
     ```bash
     sudo mkdir -p /mnt/models
     sudo chmod 777 /mnt/models
     ```

2. **Define PersistentVolume (PV)**:
   - Create `pv.yaml`:
     ```yaml
     apiVersion: v1
     kind: PersistentVolume
     metadata:
       name: models-pv
     spec:
       capacity:
         storage: 100Gi
       accessModes:
         - ReadWriteOnce
       hostPath:
         path: /models
     ```
   - Apply it:
     ```bash
     kubectl apply -f pv.yaml
     ```

3. **Define PersistentVolumeClaim (PVC)**:
   - Create `pvc.yaml`:
     ```yaml
     apiVersion: v1
     kind: PersistentVolumeClaim
     metadata:
       name: models-pvc
     spec:
       accessModes:
         - ReadWriteOnce
       resources:
         requests:
           storage: 100Gi
       volumeName: models-pv
     ```
   - Apply it:
     ```bash
     kubectl apply -f pvc.yaml
     ```

---

### Step 6: Download Models
1. **Install Hugging Face CLI**:
   - In Ubuntu:
     ```bash
     pip install huggingface-hub
     ```

2. **Download Models**:
   - **gpt2** (text):
     ```bash
     huggingface-cli download gpt2 --local-dir /mnt/models/gpt2
     ```
   - **clip-vit-base-patch32** (vision):
     ```bash
     huggingface-cli download openai/clip-vit-base-patch32 --local-dir /mnt/models/clip-vit-base-patch32
     ```
   - **all-MiniLM-L6-v2** (embedding):
     ```bash
     huggingface-cli download sentence-transformers/all-MiniLM-L6-v2 --local-dir /mnt/models/all-MiniLM-L6-v2
     ```

---

### Step 7: Deploy vLLM for Text Models (gpt2)
1. **Create vLLM Deployment**:
   - Create `vllm-deployment.yaml`:
     ```yaml
     apiVersion: apps/v1
     kind: Deployment
     metadata:
       name: vllm-deployment
     spec:
       replicas: 1
       selector:
         matchLabels:
           app: vllm
       template:
         metadata:
           labels:
             app: vllm
         spec:
           containers:
           - name: vllm
             image: vllm/vllm-openai:latest
             command: ["vllm", "serve", "/models/gpt2", "--cpu-offload-gb", "32"]
             volumeMounts:
             - mountPath: /models
               name: models-volume
             resources:
               requests:
                 cpu: 4
                 memory: 48Gi
               limits:
                 nvidia.com/gpu: 1
                 memory: 48Gi
           volumes:
           - name: models-volume
             persistentVolumeClaim:
               claimName: models-pvc
     ```
   - Apply it:
     ```bash
     kubectl apply -f vllm-deployment.yaml
     ```

2. **Expose vLLM Service**:
   - Create `vllm-service.yaml`:
     ```yaml
     apiVersion: v1
     kind: Service
     metadata:
       name: vllm-service
     spec:
       selector:
         app: vllm
       ports:
         - protocol: TCP
           port: 8000
           targetPort: 8000
     ```
   - Apply it:
     ```bash
     kubectl apply -f vllm-service.yaml
     ```

3. **Port Forward for Access**:
   - In Ubuntu:
     ```bash
     kubectl port-forward --address 0.0.0.0 service/vllm-service 8000:8000
     ```
   - Note your Windows IP (e.g., `192.168.1.x`) via `ipconfig` in Command Prompt. Access vLLM at `<windows_ip>:8000`.

---

### Step 8: Deploy Qdrant for Vector Storage
1. **Create Qdrant Deployment**:
   - Create `qdrant-deployment.yaml`:
     ```yaml
     apiVersion: apps/v1
     kind: Deployment
     metadata:
       name: qdrant-deployment
     spec:
       replicas: 1
       selector:
         matchLabels:
           app: qdrant
       template:
         metadata:
           labels:
             app: qdrant
         spec:
           containers:
           - name: qdrant
             image: qdrant/qdrant:latest
             ports:
             - containerPort: 6333
     ```
   - Apply it:
     ```bash
     kubectl apply -f qdrant-deployment.yaml
     ```

2. **Expose Qdrant Service**:
   - Create `qdrant-service.yaml`:
     ```yaml
     apiVersion: v1
     kind: Service
     metadata:
       name: qdrant-service
     spec:
       selector:
         app: qdrant
       ports:
         - protocol: TCP
           port: 6333
           targetPort: 6333
     ```
   - Apply it:
     ```bash
     kubectl apply -f qdrant-service.yaml
     ```

3. **Port Forward Qdrant**:
   - In a new terminal:
     ```bash
     kubectl port-forward --address 0.0.0.0 service/qdrant-service 6333:6333
     ```
   - Access at `<windows_ip>:6333`.

---

### Step 9: Deploy Vision Model (clip-vit-base-patch32)
1. **Create a Custom Docker Image**:
   - Create a directory `clip-service` and add:
     - `Dockerfile`:
       ```dockerfile
       FROM python:3.9-slim
       WORKDIR /app
       RUN pip install torch transformers fastapi uvicorn
       COPY app.py .
       CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8001"]
       ```
     - `app.py`:
       ```python
       from fastapi import FastAPI
       from transformers import CLIPProcessor, CLIPModel
       import torch

       app = FastAPI()
       model = CLIPModel.from_pretrained("/models/clip-vit-base-patch32")
       processor = CLIPProcessor.from_pretrained("/models/clip-vit-base-patch32")

       @app.post("/vision")
       async def process_image(text: str):
           inputs = processor(text=[text], images=None, return_tensors="pt", padding=True)
           outputs = model.get_text_features(**inputs)
           return {"text_features": outputs.tolist()}
       ```
   - Build and push (or use locally):
     ```bash
     docker build -t clip-service:latest .
     ```

2. **Deploy CLIP Service**:
   - Create `clip-deployment.yaml`:
     ```yaml
     apiVersion: apps/v1
     kind: Deployment
     metadata:
       name: clip-deployment
     spec:
       replicas: 1
       selector:
         matchLabels:
           app: clip
       template:
         metadata:
           labels:
             app: clip
         spec:
           containers:
           - name: clip
             image: clip-service:latest
             volumeMounts:
             - mountPath: /models
               name: models-volume
             resources:
               limits:
                 nvidia.com/gpu: 1
           volumes:
           - name: models-volume
             persistentVolumeClaim:
               claimName: models-pvc
     ```
   - Apply it:
     ```bash
     kubectl apply -f clip-deployment.yaml
     ```

3. **Expose CLIP Service**:
   - Create `clip-service.yaml`:
     ```yaml
     apiVersion: v1
     kind: Service
     metadata:
       name: clip-service
     spec:
       selector:
         app: clip
       ports:
         - protocol: TCP
           port: 8001
           targetPort: 8001
     ```
   - Apply it:
     ```bash
     kubectl apply -f clip-service.yaml
     ```

4. **Port Forward**:
   - ```bash
     kubectl port-forward --address 0.0.0.0 service/clip-service 8001:8001
     ```

---

### Step 10: Deploy Embedding Model (all-MiniLM-L6-v2)
1. **Create a Custom Docker Image**:
   - Create `embedding-service` directory with:
     - `Dockerfile`:
       ```dockerfile
       FROM python:3.9-slim
       WORKDIR /app
       RUN pip install torch sentence-transformers fastapi uvicorn
       COPY app.py .
       CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8002"]
       ```
     - `app.py`:
       ```python
       from fastapi import FastAPI
       from sentence_transformers import SentenceTransformer

       app = FastAPI()
       model = SentenceTransformer("/models/all-MiniLM-L6-v2")

       @app.post("/embed")
       async def embed_text(text: str):
           embedding = model.encode(text)
           return {"embedding": embedding.tolist()}
       ```
   - Build:
     ```bash
     docker build -t embedding-service:latest .
     ```

2. **Deploy Embedding Service**:
   - Create `embedding-deployment.yaml`:
     ```yaml
     apiVersion: apps/v1
     kind: Deployment
     metadata:
       name: embedding-deployment
     spec:
       replicas: 1
       selector:
         matchLabels:
           app: embedding
       template:
         metadata:
           labels:
             app: embedding
         spec:
           containers:
           - name: embedding
             image: embedding-service:latest
             volumeMounts:
             - mountPath: /models
               name: models-volume
             resources:
               limits:
                 nvidia.com/gpu: 1
           volumes:
           - name: models-volume
             persistentVolumeClaim:
               claimName: models-pvc
     ```
   - Apply it:
     ```bash
     kubectl apply -f embedding-deployment.yaml
     ```

3. **Expose Embedding Service**:
   - Create `embedding-service.yaml`:
     ```yaml
     apiVersion: v1
     kind: Service
     metadata:
       name: embedding-service
     spec:
       selector:
         app: embedding
       ports:
         - protocol: TCP
           port: 8002
           targetPort: 8002
     ```
   - Apply it:
     ```bash
     kubectl apply -f embedding-service.yaml
     ```

4. **Port Forward**:
   - ```bash
     kubectl port-forward --address 0.0.0.0 service/embedding-service 8002:8002
     ```

---

### Step 11: Configure LMCache/CPU Offloading
- **vLLM Native Offloading**:
  - Already configured in Step 7 with `--cpu-offload-gb 32`, utilizing 32GB of RAM for offloading alongside the GPU.
- **LMCache Alternative** (optional):
  - Replace the vLLM image with `lmcache/vllm-openai:latest` (if available) in `vllm-deployment.yaml`. Check [LMCache docs](https://github.com/lmcache) for config details, e.g., environment variables for CPU/RAM usage.

---

### Step 12: Generate API Tokens
1. **Set API Key in vLLM**:
   - Modify `vllm-deployment.yaml` to include an API key:
     ```yaml
     spec:
       containers:
       - name: vllm
         image: vllm/vllm-openai:latest
         command: ["vllm", "serve", "/models/gpt2", "--cpu-offload-gb", "32", "--api-key", "my-secret-key"]
     ```
   - Reapply:
     ```bash
     kubectl apply -f vllm-deployment.yaml
     ```
   - Use `my-secret-key` (or generate a secure one) for queries.

---

### Step 13: Query from Devices
1. **MacBook**:
   - Install OpenAI client:
     ```bash
     pip install openai
     ```
   - Run:
     ```python
     from openai import OpenAI
     client = OpenAI(base_url="http://<windows_ip>:8000/v1", api_key="my-secret-key")
     completion = client.completions.create(model="gpt2", prompt="Hello, world!", max_tokens=50)
     print(completion.choices[0].text)
     ```

2. **Le Potato**:
   - Install Python and OpenAI client, then use the same script as above.

3. **iPad**:
   - Use an app like Prompt (configure with custom API endpoint `<windows_ip>:8000/v1` and key).

4. **Android (Termux)**:
   - Install Python:
     ```bash
     pkg install python
     pip install openai
     ```
   - Use the same script.

5. **Test Vision/Embedding**:
   - For CLIP: `curl -X POST http://<windows_ip>:8001/vision -d '{"text": "A cat"}'`
   - For Embedding: `curl -X POST http://<windows_ip>:8002/embed -d '{"text": "A sentence"}'`

---

### Notes
- **Firewall**: Ensure Windows firewall allows ports 8000, 8001, 8002, 6333.
- **GPU Sharing**: Models share the RTX 4070ti; adjust resource limits if contention occurs.
- **MVP Focus**: This setup covers vLLM, Qdrant, and basic model serving. Add `LiteLLM` or `llm-d` later for advanced load balancing.

This manual sets up your home AI cluster as requested, fully operational from your Windows PC with querying capabilities across all devices!
