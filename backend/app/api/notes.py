from fastapi import APIRouter, Depends, HTTPException, status
from app.models.notes import NoteCreate, NoteUpdate, NoteResponse
from app.api.auth import get_current_user
from app.core.database import get_database
from datetime import datetime
import uuid

router = APIRouter()


# ─── POST / — create a note ─────────────────────────────────────────────────

@router.post("/", response_model=NoteResponse, status_code=status.HTTP_201_CREATED)
async def create_note(
    body: NoteCreate,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database),
):
    """Create a new study note."""
    note_id = str(uuid.uuid4())
    now = datetime.utcnow()

    doc = {
        "_id": note_id,
        "user_id": current_user["_id"],
        "title": body.title,
        "content": body.content,
        "subject_id": body.subject_id,
        "created_at": now,
        "updated_at": now,
    }

    await db["notes"].insert_one(doc)

    # Resolve subject info
    subject_name, subject_color = None, None
    if body.subject_id:
        subj = await db["subjects"].find_one({"_id": body.subject_id})
        if subj:
            subject_name = subj["name"]
            subject_color = subj["color"]

    return NoteResponse(
        id=note_id,
        title=body.title,
        content=body.content,
        subject_id=body.subject_id,
        subject_name=subject_name,
        subject_color=subject_color,
        created_at=now,
        updated_at=now,
    )


# ─── GET / — list all notes ─────────────────────────────────────────────────

@router.get("/", response_model=list[NoteResponse])
async def get_notes(
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database),
):
    """Return all notes for the user, newest first."""
    cursor = db["notes"].find(
        {"user_id": current_user["_id"]}
    ).sort("updated_at", -1)

    # Pre-fetch subjects for this user
    subjects_map = {}
    subj_cursor = db["subjects"].find({"user_id": current_user["_id"]})
    async for s in subj_cursor:
        subjects_map[s["_id"]] = s

    notes = []
    async for doc in cursor:
        subj = subjects_map.get(doc.get("subject_id"))
        notes.append(NoteResponse(
            id=doc["_id"],
            title=doc["title"],
            content=doc.get("content", ""),
            subject_id=doc.get("subject_id"),
            subject_name=subj["name"] if subj else None,
            subject_color=subj["color"] if subj else None,
            created_at=doc["created_at"],
            updated_at=doc.get("updated_at", doc["created_at"]),
        ))
    return notes


# ─── GET /{id} — get single note ────────────────────────────────────────────

@router.get("/{note_id}", response_model=NoteResponse)
async def get_note(
    note_id: str,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database),
):
    """Return a single note by ID."""
    doc = await db["notes"].find_one({
        "_id": note_id,
        "user_id": current_user["_id"],
    })
    if not doc:
        raise HTTPException(status_code=404, detail="Note not found")

    subj = None
    if doc.get("subject_id"):
        subj = await db["subjects"].find_one({"_id": doc["subject_id"]})

    return NoteResponse(
        id=doc["_id"],
        title=doc["title"],
        content=doc.get("content", ""),
        subject_id=doc.get("subject_id"),
        subject_name=subj["name"] if subj else None,
        subject_color=subj["color"] if subj else None,
        created_at=doc["created_at"],
        updated_at=doc.get("updated_at", doc["created_at"]),
    )


# ─── PUT /{id} — update a note ──────────────────────────────────────────────

@router.put("/{note_id}", response_model=NoteResponse)
async def update_note(
    note_id: str,
    body: NoteUpdate,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database),
):
    """Update an existing note."""
    existing = await db["notes"].find_one({
        "_id": note_id,
        "user_id": current_user["_id"],
    })
    if not existing:
        raise HTTPException(status_code=404, detail="Note not found")

    update_fields = {"updated_at": datetime.utcnow()}
    if body.title is not None:
        update_fields["title"] = body.title
    if body.content is not None:
        update_fields["content"] = body.content
    if body.subject_id is not None:
        update_fields["subject_id"] = body.subject_id

    await db["notes"].update_one({"_id": note_id}, {"$set": update_fields})

    updated = await db["notes"].find_one({"_id": note_id})
    subj = None
    if updated.get("subject_id"):
        subj = await db["subjects"].find_one({"_id": updated["subject_id"]})

    return NoteResponse(
        id=updated["_id"],
        title=updated["title"],
        content=updated.get("content", ""),
        subject_id=updated.get("subject_id"),
        subject_name=subj["name"] if subj else None,
        subject_color=subj["color"] if subj else None,
        created_at=updated["created_at"],
        updated_at=updated["updated_at"],
    )


# ─── DELETE /{id} — delete a note ───────────────────────────────────────────

@router.delete("/{note_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_note(
    note_id: str,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database),
):
    """Delete a note."""
    result = await db["notes"].delete_one({
        "_id": note_id,
        "user_id": current_user["_id"],
    })
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Note not found")
