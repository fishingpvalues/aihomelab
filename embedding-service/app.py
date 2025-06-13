from fastapi import FastAPI
from sentence_transformers import SentenceTransformer

app = FastAPI()
model = SentenceTransformer("/models/all-MiniLM-L6-v2")

@app.post("/embed")
async def embed_text(text: str):
    embedding = model.encode(text)
    return {"embedding": embedding.tolist()} 