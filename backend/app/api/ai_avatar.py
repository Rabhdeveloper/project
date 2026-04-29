from fastapi import APIRouter, Depends, status
from datetime import datetime
import random

from app.core.database import get_database
from app.api.auth import get_current_user
from app.models.user import UserInDB
from app.models.iot import (
    AvatarConversationRequest, AvatarConversationResponse,
    LectureIngestRequest, LectureIngestResponse,
)

router = APIRouter()

# Simulated AI responses for the omnipresent tutor
TUTOR_RESPONSES = [
    "Great question! Let me break that down for you...",
    "Based on your recent study patterns, I'd suggest focusing on the fundamentals first.",
    "I've noticed you're strongest in this area — let's build on that!",
    "Here's an interesting connection: this concept relates to what you studied yesterday.",
    "Let me generate some practice questions for you on this topic.",
]


@router.post("/converse", response_model=AvatarConversationResponse)
async def converse_with_avatar(
    msg_in: AvatarConversationRequest,
    current_user: UserInDB = Depends(get_current_user),
):
    """Natural language conversation with the omnipresent AI tutor."""
    db = get_database()
    
    # Store conversation message
    await db["avatar_conversations"].insert_one({
        "user_id": str(current_user.id),
        "role": "user", "content": msg_in.message,
        "context": msg_in.context, "timestamp": datetime.utcnow(),
    })
    
    # Simulated AI reply
    reply = random.choice(TUTOR_RESPONSES) + f" Regarding: '{msg_in.message[:60]}...'"
    suggestions = [
        "Try reviewing your flashcards on this topic",
        "Take a 5-minute break, then revisit",
        "Check the knowledge graph for related topics",
    ]
    
    # Store AI reply
    await db["avatar_conversations"].insert_one({
        "user_id": str(current_user.id),
        "role": "assistant", "content": reply,
        "timestamp": datetime.utcnow(),
    })
    
    return AvatarConversationResponse(reply=reply, suggestions=suggestions, generated_notes=[])


@router.post("/ingest-lecture", response_model=LectureIngestResponse)
async def ingest_lecture(
    lecture_in: LectureIngestRequest,
    current_user: UserInDB = Depends(get_current_user),
):
    """Submit lecture text for real-time note and quiz generation."""
    db = get_database()
    
    # Simulate AI processing of lecture text
    words = lecture_in.text.split()
    word_count = len(words)
    
    # Generate summary (simulated)
    summary = f"Summary of {word_count}-word lecture on '{lecture_in.subject or 'General'}': " + " ".join(words[:30]) + "..."
    
    # Generate key points (simulated)
    key_points = []
    chunk_size = max(1, word_count // 5)
    for i in range(0, min(word_count, chunk_size * 5), chunk_size):
        key_points.append("• " + " ".join(words[i:i+8]) + "...")
    
    # Store ingested lecture
    await db["ingested_lectures"].insert_one({
        "user_id": str(current_user.id),
        "text": lecture_in.text, "subject": lecture_in.subject,
        "source": lecture_in.source, "summary": summary,
        "key_points": key_points, "timestamp": datetime.utcnow(),
    })
    
    return LectureIngestResponse(
        summary=summary, key_points=key_points[:5],
        generated_flashcards=min(5, word_count // 50),
        generated_quiz_questions=min(3, word_count // 100),
    )


@router.get("/session-handoff")
async def session_handoff(current_user: UserInDB = Depends(get_current_user)):
    """Get session state for cross-device handoff (phone ↔ desktop ↔ watch ↔ VR)."""
    db = get_database()
    
    # Get last conversation messages
    cursor = db["avatar_conversations"].find(
        {"user_id": str(current_user.id)}
    ).sort("timestamp", -1).limit(10)
    messages = []
    async for msg in cursor:
        msg["_id"] = str(msg["_id"])
        messages.append({"role": msg["role"], "content": msg["content"]})
    
    return {
        "status": "success",
        "user_id": str(current_user.id),
        "active_session": True,
        "recent_messages": list(reversed(messages)),
        "handoff_token": f"handoff_{str(current_user.id)[:8]}_{int(datetime.utcnow().timestamp())}",
    }
