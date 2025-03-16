from fastapi import FastAPI, UploadFile, File
import uvicorn
import cv2
import numpy as np
import torch
import timm
import torch.nn.functional as F
from io import BytesIO
from PIL import Image

app = FastAPI()

model = timm.create_model("hf_hub:gaunernst/vit_tiny_patch8_112.arcface_ms1mv3", pretrained=True).eval()

known_faces = {}  # {"name": embedding}


def get_embedding(image: np.ndarray):
    """Process image and extract face embeddings."""
    image = cv2.resize(image, (112, 112))  # Resize to model input size
    image = np.transpose(image, (2, 0, 1))  # Convert HWC to CHW
    image = torch.tensor(image, dtype=torch.float32).unsqueeze(0)  # Add batch dimension
    embs = model(image)  # Get embeddings
    embs = F.normalize(embs, dim=1)  # Normalize embeddings
    return embs.detach().numpy().flatten()  # Convert to 1D array


@app.post("/learn/")
async def learn_face(file: UploadFile = File(...), name: str = "Unknown"):
    """Upload an image to learn a new face."""
    contents = await file.read()
    image = np.array(Image.open(BytesIO(contents)).convert("RGB"))

    embedding = get_embedding(image)  # Extract embedding
    known_faces[name] = embedding  # Store in dictionary

    return {"message": f"✅ Face '{name}' learned!", "total_faces": len(known_faces)}


@app.post("/recognize/")
async def recognize_face(file: UploadFile = File(...)):
    """Upload an image and recognize the person."""
    contents = await file.read()
    image = np.array(Image.open(BytesIO(contents)).convert("RGB"))

    new_embedding = get_embedding(image)  # Extract face embedding

    best_match = None
    min_distance = float("inf")

    for name, stored_embedding in known_faces.items():
        distance = np.linalg.norm(stored_embedding - new_embedding)  # Euclidean distance
        if distance < min_distance:
            min_distance = distance
            best_match = name

    if min_distance < 0.5:  # Threshold can be adjusted
        return {"recognized": best_match}
    else:
        return {"recognized": "Unknown"}


@app.get("/")
def read_root():
    return {"message": "Face Recognition API is running!", "known_faces": list(known_faces.keys())}