from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from typing import Optional
from app.api.auth import get_current_user
from app.core.database import get_database
from datetime import datetime
import uuid

router = APIRouter()


# ─── Pydantic Models ──────────────────────────────────────────────────────────

class SubjectCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=50)
    color: str = Field(default="#6366F1", description="Hex color code")
    icon: str = Field(default="📖", description="Emoji icon for the subject")


class SubjectResponse(BaseModel):
    id: str
    name: str
    color: str
    icon: str
    created_at: datetime


# ─── GET / — list user's subjects ────────────────────────────────────────────

@router.get("/", response_model=list[SubjectResponse])
async def get_subjects(
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database),
):
    """Return all subjects for the authenticated user."""
    cursor = db["subjects"].find({"user_id": current_user["_id"]}).sort("created_at", 1)
    subjects = []
    async for doc in cursor:
        subjects.append(SubjectResponse(
            id=doc["_id"],
            name=doc["name"],
            color=doc["color"],
            icon=doc["icon"],
            created_at=doc["created_at"],
        ))
    return subjects


# ─── POST / — create a subject ──────────────────────────────────────────────

@router.post("/", response_model=SubjectResponse, status_code=status.HTTP_201_CREATED)
async def create_subject(
    body: SubjectCreate,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database),
):
    """Create a new study subject for the authenticated user."""
    subject_id = str(uuid.uuid4())
    now = datetime.utcnow()

    doc = {
        "_id": subject_id,
        "user_id": current_user["_id"],
        "name": body.name,
        "color": body.color,
        "icon": body.icon,
        "created_at": now,
    }

    await db["subjects"].insert_one(doc)

    return SubjectResponse(
        id=subject_id,
        name=body.name,
        color=body.color,
        icon=body.icon,
        created_at=now,
    )


# ─── DELETE /{id} — delete a subject ────────────────────────────────────────

@router.delete("/{subject_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_subject(
    subject_id: str,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database),
):
    """Delete a subject owned by the authenticated user."""
    result = await db["subjects"].delete_one({
        "_id": subject_id,
        "user_id": current_user["_id"],
    })
    if result.deleted_count == 0:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Subject not found",
        )
