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