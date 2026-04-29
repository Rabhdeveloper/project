from fastapi import APIRouter, Depends, HTTPException, status
from typing import List
from datetime import datetime
import secrets
import hashlib
from bson import ObjectId

from app.core.database import get_database
from app.api.auth import get_current_user
from app.models.user import UserInDB
from app.models.knowledge_graph import CredentialMintRequest, VerifiableCredentialResponse

router = APIRouter()


@router.post("/mint", response_model=VerifiableCredentialResponse, status_code=status.HTTP_201_CREATED)
async def mint_credential(cred_in: CredentialMintRequest, current_user: UserInDB = Depends(get_current_user)):
    """Mint a verifiable credential (simulated Soulbound Token) for a completed milestone."""
    db = get_database()
    token_id = f"SBT-{secrets.token_hex(8).upper()}"
    tx_hash = f"0x{secrets.token_hex(32)}"
    
    cred_doc = {
        "user_id": str(current_user.id),
        "title": cred_in.title, "description": cred_in.description,
        "credential_type": cred_in.credential_type, "subject": cred_in.subject,
        "study_hours": cred_in.study_hours, "test_score": cred_in.test_score,
        "token_id": token_id, "chain": "polygon_testnet", "tx_hash": tx_hash,
        "is_verified": True, "issued_at": datetime.utcnow(),
        "public_url": f"https://verify.smartstudy.io/credentials/{token_id}",
    }
    result = await db["verifiable_credentials"].insert_one(cred_doc)
    cred_doc["_id"] = str(result.inserted_id)
    return cred_doc


@router.get("", response_model=List[VerifiableCredentialResponse])
async def list_credentials(current_user: UserInDB = Depends(get_current_user)):
    """List all verifiable credentials earned by the user."""
    db = get_database()
    cursor = db["verifiable_credentials"].find({"user_id": str(current_user.id)}).sort("issued_at", -1)
    creds = []
    async for cred in cursor:
        cred["_id"] = str(cred["_id"])
        creds.append(cred)
    return creds


@router.get("/verify/{credential_id}")
async def verify_credential(credential_id: str):
    """Public endpoint to verify authenticity of a credential (no auth required)."""
    db = get_database()
    cred = await db["verifiable_credentials"].find_one({"token_id": credential_id})
    if not cred:
        raise HTTPException(status_code=404, detail="Credential not found")
    cred["_id"] = str(cred["_id"])
    return {"verified": cred["is_verified"], "credential": cred}
