from fastapi import APIRouter, Depends, HTTPException, status
from app.models.notes import FlashcardCreate, FlashcardUpdate, FlashcardReview, FlashcardResponse
from app.api.auth import get_current_user
from app.core.database import get_database
from datetime import datetime, timedelta
import uuid
import math

router = APIRouter()


# ─── SM-2 Algorithm ──────────────────────────────────────────────────────────

def sm2_update(easiness: float, interval: int, repetitions: int, quality: int):
    """
    SM-2 spaced repetition algorithm.
    quality: 1=Again 2=Hard 3=Good 4=Easy 5=Perfect
    Returns (new_easiness, new_interval, new_repetitions).
    """
    # Map 1-5 to 0-5 scale used by SM-2
    q = quality  # keep 1-5

    if q < 3:
        # Failed: reset
        return max(1.3, easiness), 1, 0

    # Successful review
    new_easiness = easiness + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
    new_easiness = max(1.3, new_easiness)

    if repetitions == 0:
        new_interval = 1
    elif repetitions == 1:
        new_interval = 6
    else:
        new_interval = math.ceil(interval * new_easiness)

    return new_easiness, new_interval, repetitions + 1


# ─── POST / — create a flashcard ────────────────────────────────────────────

@router.post("/", response_model=FlashcardResponse, status_code=status.HTTP_201_CREATED)
async def create_flashcard(
    body: FlashcardCreate,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database),
):
    """Create a new flashcard."""
    card_id = str(uuid.uuid4())
    now = datetime.utcnow()

    doc = {
        "_id": card_id,
        "user_id": current_user["_id"],
        "question": body.question,
        "answer": body.answer,
        "subject_id": body.subject_id,
        "easiness": 2.5,
        "interval": 1,
        "repetitions": 0,
        "next_review": now,  # available for review immediately
        "created_at": now,
    }

    await db["flashcards"].insert_one(doc)

    subject_name, subject_color = None, None
    if body.subject_id:
        subj = await db["subjects"].find_one({"_id": body.subject_id})
        if subj:
            subject_name = subj["name"]
            subject_color = subj["color"]

    return FlashcardResponse(
        id=card_id,
        question=body.question,
        answer=body.answer,
        subject_id=body.subject_id,
        subject_name=subject_name,
        subject_color=subject_color,
        easiness=2.5,
        interval=1,
        repetitions=0,
        next_review=now,
        created_at=now,
    )


# ─── GET / — list all flashcards ────────────────────────────────────────────

@router.get("/", response_model=list[FlashcardResponse])
async def get_flashcards(
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database),
):
    """Return all flashcards for the user."""
    cursor = db["flashcards"].find(
        {"user_id": current_user["_id"]}
    ).sort("created_at", -1)

    subjects_map = {}
    subj_cursor = db["subjects"].find({"user_id": current_user["_id"]})
    async for s in subj_cursor:
        subjects_map[s["_id"]] = s

    cards = []
    async for doc in cursor:
        subj = subjects_map.get(doc.get("subject_id"))
        cards.append(FlashcardResponse(
            id=doc["_id"],
            question=doc["question"],
            answer=doc["answer"],
            subject_id=doc.get("subject_id"),
            subject_name=subj["name"] if subj else None,
            subject_color=subj["color"] if subj else None,
            easiness=doc.get("easiness", 2.5),
            interval=doc.get("interval", 1),
            repetitions=doc.get("repetitions", 0),
            next_review=doc.get("next_review", doc["created_at"]),
            created_at=doc["created_at"],
        ))
    return cards


# ─── GET /review — cards due for review ──────────────────────────────────────

@router.get("/review", response_model=list[FlashcardResponse])
async def get_review_cards(
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database),
):
    """Return flashcards due for review (next_review <= now)."""
    now = datetime.utcnow()

    cursor = db["flashcards"].find({
        "user_id": current_user["_id"],
        "next_review": {"$lte": now},
    }).sort("next_review", 1)

    subjects_map = {}
    subj_cursor = db["subjects"].find({"user_id": current_user["_id"]})
    async for s in subj_cursor:
        subjects_map[s["_id"]] = s

    cards = []
    async for doc in cursor:
        subj = subjects_map.get(doc.get("subject_id"))
        cards.append(FlashcardResponse(
            id=doc["_id"],
            question=doc["question"],
            answer=doc["answer"],
            subject_id=doc.get("subject_id"),
            subject_name=subj["name"] if subj else None,
            subject_color=subj["color"] if subj else None,
            easiness=doc.get("easiness", 2.5),
            interval=doc.get("interval", 1),
            repetitions=doc.get("repetitions", 0),
            next_review=doc.get("next_review", doc["created_at"]),
            created_at=doc["created_at"],
        ))
    return cards


# ─── PUT /{id} — update a flashcard ─────────────────────────────────────────

@router.put("/{card_id}", response_model=FlashcardResponse)
async def update_flashcard(
    card_id: str,
    body: FlashcardUpdate,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database),
):
    """Update a flashcard's question/answer."""
    existing = await db["flashcards"].find_one({
        "_id": card_id,
        "user_id": current_user["_id"],
    })
    if not existing:
        raise HTTPException(status_code=404, detail="Flashcard not found")

    update_fields = {}
    if body.question is not None:
        update_fields["question"] = body.question
    if body.answer is not None:
        update_fields["answer"] = body.answer
    if body.subject_id is not None:
        update_fields["subject_id"] = body.subject_id

    if update_fields:
        await db["flashcards"].update_one({"_id": card_id}, {"$set": update_fields})

    updated = await db["flashcards"].find_one({"_id": card_id})
    subj = None
    if updated.get("subject_id"):
        subj = await db["subjects"].find_one({"_id": updated["subject_id"]})

    return FlashcardResponse(
        id=updated["_id"],
        question=updated["question"],
        answer=updated["answer"],
        subject_id=updated.get("subject_id"),
        subject_name=subj["name"] if subj else None,
        subject_color=subj["color"] if subj else None,
        easiness=updated.get("easiness", 2.5),
        interval=updated.get("interval", 1),
        repetitions=updated.get("repetitions", 0),
        next_review=updated.get("next_review", updated["created_at"]),
        created_at=updated["created_at"],
    )


# ─── DELETE /{id} — delete a flashcard ───────────────────────────────────────

@router.delete("/{card_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_flashcard(
    card_id: str,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database),
):
    """Delete a flashcard."""
    result = await db["flashcards"].delete_one({
        "_id": card_id,
        "user_id": current_user["_id"],
    })
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Flashcard not found")


# ─── POST /{id}/review — mark as reviewed with SM-2 ─────────────────────────

@router.post("/{card_id}/review")
async def review_flashcard(
    card_id: str,
    body: FlashcardReview,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database),
):
    """Review a flashcard. Updates next_review using SM-2 algorithm."""
    doc = await db["flashcards"].find_one({
        "_id": card_id,
        "user_id": current_user["_id"],
    })
    if not doc:
        raise HTTPException(status_code=404, detail="Flashcard not found")

    old_easiness = doc.get("easiness", 2.5)
    old_interval = doc.get("interval", 1)
    old_reps = doc.get("repetitions", 0)

    new_easiness, new_interval, new_reps = sm2_update(
        old_easiness, old_interval, old_reps, body.quality
    )

    next_review = datetime.utcnow() + timedelta(days=new_interval)

    await db["flashcards"].update_one(
        {"_id": card_id},
        {
            "$set": {
                "easiness": new_easiness,
                "interval": new_interval,
                "repetitions": new_reps,
                "next_review": next_review,
            }
        },
    )

    return {
        "message": "Review recorded",
        "next_review": next_review.isoformat(),
        "interval_days": new_interval,
        "easiness": round(new_easiness, 2),
    }
