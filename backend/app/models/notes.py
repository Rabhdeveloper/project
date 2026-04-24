from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime


# ─── Note Models ──────────────────────────────────────────────────────────────

class NoteCreate(BaseModel):
    title: str = Field(..., min_length=1, max_length=200)
    content: str = Field(default="")
    subject_id: Optional[str] = Field(None, description="Optional subject tag")


class NoteUpdate(BaseModel):
    title: Optional[str] = Field(None, min_length=1, max_length=200)
    content: Optional[str] = None
    subject_id: Optional[str] = None


class NoteResponse(BaseModel):
    id: str
    title: str
    content: str
    subject_id: Optional[str] = None
    subject_name: Optional[str] = None
    subject_color: Optional[str] = None
    created_at: datetime
    updated_at: datetime


# ─── Flashcard Models ─────────────────────────────────────────────────────────

class FlashcardCreate(BaseModel):
    question: str = Field(..., min_length=1, max_length=500)
    answer: str = Field(..., min_length=1, max_length=2000)
    subject_id: Optional[str] = Field(None, description="Optional subject tag")


class FlashcardUpdate(BaseModel):
    question: Optional[str] = Field(None, min_length=1, max_length=500)
    answer: Optional[str] = Field(None, min_length=1, max_length=2000)
    subject_id: Optional[str] = None


class FlashcardReview(BaseModel):
    quality: int = Field(..., ge=1, le=5, description="Review quality: 1=Again, 5=Easy")


class FlashcardResponse(BaseModel):
    id: str
    question: str
    answer: str
    subject_id: Optional[str] = None
    subject_name: Optional[str] = None
    subject_color: Optional[str] = None
    easiness: float = 2.5
    interval: int = 1  # days
    repetitions: int = 0
    next_review: datetime
    created_at: datetime
