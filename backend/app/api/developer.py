from fastapi import APIRouter, Depends, HTTPException, status
from typing import List
import secrets
import hashlib
from datetime import datetime
from bson import ObjectId

from app.core.database import get_database
from app.api.auth import get_current_user
from app.models.user import UserInDB
from app.models.developer import (
    PersonalAccessTokenCreate, 
    PersonalAccessTokenResponse, 
    PersonalAccessTokenCreateResponse,
    WebhookEndpointCreate,
    WebhookEndpointResponse
)

router = APIRouter()

def hash_token(token: str) -> str:
    return hashlib.sha256(token.encode()).hexdigest()

@router.post("/tokens", response_model=PersonalAccessTokenCreateResponse, status_code=status.HTTP_201_CREATED)
async def create_personal_access_token(token_in: PersonalAccessTokenCreate, current_user: UserInDB = Depends(get_current_user)):
    db = get_database()
    
    # Generate a random 32-byte hex token
    raw_token = secrets.token_hex(32)
    hashed_token = hash_token(raw_token)
    
    token_doc = {
        "user_id": str(current_user.id),
        "name": token_in.name,
        "token_hash": hashed_token,
        "created_at": datetime.utcnow()
    }
    
    result = await db["personal_access_tokens"].insert_one(token_doc)
    token_doc["_id"] = str(result.inserted_id)
    token_doc["token"] = raw_token  # Only returned this one time!
    
    return token_doc

@router.get("/tokens", response_model=List[PersonalAccessTokenResponse])
async def list_personal_access_tokens(current_user: UserInDB = Depends(get_current_user)):
    db = get_database()
    cursor = db["personal_access_tokens"].find({"user_id": str(current_user.id)})
    tokens = []
    async for token in cursor:
        token["_id"] = str(token["_id"])
        tokens.append(token)
    return tokens

@router.delete("/tokens/{token_id}", status_code=status.HTTP_204_NO_CONTENT)
async def revoke_personal_access_token(token_id: str, current_user: UserInDB = Depends(get_current_user)):
    db = get_database()
    if not ObjectId.is_valid(token_id):
        raise HTTPException(status_code=400, detail="Invalid token ID")
        
    result = await db["personal_access_tokens"].delete_one({"_id": ObjectId(token_id), "user_id": str(current_user.id)})
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Token not found")
    
    return None

@router.post("/webhooks", response_model=WebhookEndpointResponse, status_code=status.HTTP_201_CREATED)
async def register_webhook(webhook_in: WebhookEndpointCreate, current_user: UserInDB = Depends(get_current_user)):
    db = get_database()
    webhook_doc = {
        "user_id": str(current_user.id),
        "url": webhook_in.url,
        "events": webhook_in.events,
        "created_at": datetime.utcnow()
    }
    result = await db["webhooks"].insert_one(webhook_doc)
    webhook_doc["_id"] = str(result.inserted_id)
    return webhook_doc
