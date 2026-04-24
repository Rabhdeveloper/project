from fastapi import APIRouter, Depends, HTTPException, status
from app.models.reminders import ReminderCreate, ReminderUpdate, ReminderResponse
from app.api.auth import get_current_user
from app.core.database import get_database
from datetime import datetime
import uuid

router = APIRouter()

VALID_DAYS = {"mon", "tue", "wed", "thu", "fri", "sat", "sun"}


@router.get("/", response_model=list[ReminderResponse])
async def get_reminders(
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database),
):
    """Return all reminders for the user."""
    cursor = db["reminders"].find(
        {"user_id": current_user["_id"]}
    ).sort("time", 1)

    reminders = []
    async for doc in cursor:
        reminders.append(ReminderResponse(
            id=doc["_id"],
            title=doc["title"],
            time=doc["time"],
            days=doc["days"],
            enabled=doc.get("enabled", True),
            created_at=doc["created_at"],
        ))
    return reminders


@router.post("/", response_model=ReminderResponse, status_code=status.HTTP_201_CREATED)
async def create_reminder(
    body: ReminderCreate,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database),
):
    """Create a study reminder."""
    for day in body.days:
        if day.lower() not in VALID_DAYS:
            raise HTTPException(status_code=400, detail=f"Invalid day: {day}")

    reminder_id = str(uuid.uuid4())
    now = datetime.utcnow()

    doc = {
        "_id": reminder_id,
        "user_id": current_user["_id"],
        "title": body.title,
        "time": body.time,
        "days": [d.lower() for d in body.days],
        "enabled": body.enabled,
        "created_at": now,
    }

    await db["reminders"].insert_one(doc)

    return ReminderResponse(
        id=reminder_id, title=body.title, time=body.time,
        days=doc["days"], enabled=body.enabled, created_at=now,
    )


@router.put("/{reminder_id}", response_model=ReminderResponse)
async def update_reminder(
    reminder_id: str,
    body: ReminderUpdate,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database),
):
    """Update a reminder."""
    existing = await db["reminders"].find_one({
        "_id": reminder_id, "user_id": current_user["_id"],
    })
    if not existing:
        raise HTTPException(status_code=404, detail="Reminder not found")

    update_fields = {}
    if body.title is not None:
        update_fields["title"] = body.title
    if body.time is not None:
        update_fields["time"] = body.time
    if body.days is not None:
        for day in body.days:
            if day.lower() not in VALID_DAYS:
                raise HTTPException(status_code=400, detail=f"Invalid day: {day}")
        update_fields["days"] = [d.lower() for d in body.days]
    if body.enabled is not None:
        update_fields["enabled"] = body.enabled

    if update_fields:
        await db["reminders"].update_one({"_id": reminder_id}, {"$set": update_fields})

    updated = await db["reminders"].find_one({"_id": reminder_id})
    return ReminderResponse(
        id=updated["_id"], title=updated["title"], time=updated["time"],
        days=updated["days"], enabled=updated.get("enabled", True),
        created_at=updated["created_at"],
    )


@router.delete("/{reminder_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_reminder(
    reminder_id: str,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database),
):
    """Delete a reminder."""
    result = await db["reminders"].delete_one({
        "_id": reminder_id, "user_id": current_user["_id"],
    })
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Reminder not found")
