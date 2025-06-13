#!/bin/bash
# download-models.sh: Download all required models for the home AI cluster
set -e

MODEL_DIR="/mnt/models"

mkdir -p "$MODEL_DIR"

# Download gpt2 (text)
echo "Downloading gpt2..."
huggingface-cli download gpt2 --local-dir "$MODEL_DIR/gpt2" --local-dir-use-symlinks False

# Download clip-vit-base-patch32 (vision)
echo "Downloading openai/clip-vit-base-patch32..."
huggingface-cli download openai/clip-vit-base-patch32 --local-dir "$MODEL_DIR/clip-vit-base-patch32" --local-dir-use-symlinks False

# Download all-MiniLM-L6-v2 (embedding)
echo "Downloading sentence-transformers/all-MiniLM-L6-v2..."
huggingface-cli download sentence-transformers/all-MiniLM-L6-v2 --local-dir "$MODEL_DIR/all-MiniLM-L6-v2" --local-dir-use-symlinks False

echo "All models downloaded to $MODEL_DIR." 