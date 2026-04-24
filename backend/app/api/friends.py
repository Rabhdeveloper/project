from fastapi import APIRouter, Depends, HTTPException, status
from app.models.friends import FriendRequestCreate, FriendRequestResponse, FriendResponse
from app.api.auth import get_current_user
from app.core.database import get_database
from datetime import datetime
import uuid

router = APIRouter()


# ─── POST /request — send a friend request ───────────────────────────────────

@router.post("/request", status_code=status.HTTP_201_CREATED)
async def send_friend_request(
    body: FriendRequestCreate,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database),
):
    """Send a friend request to another user."""
    from_id = current_user["_id"]
    to_id = body.to_user_id

    # Can't friend yourself
    if from_id == to_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot send a friend request to yourself",
        )

    # Check target user exists
    target_user = await db["users"].find_one({"_id": to_id})
    if not target_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )

    # Check if already friends
    existing = await db["friend_requests"].find_one({
        "$or": [
            {"from_user_id": from_id, "to_user_id": to_id, "status": "accepted"},
            {"from_user_id": to_id, "to_user_id": from_id, "status": "accepted"},
        ]
    })
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Already friends with this user",
        )

    # Check for existing pending request
    pending = await db["friend_requests"].find_one({
        "$or": [
            {"from_user_id": from_id, "to_user_id": to_id, "status": "pending"},
            {"from_user_id": to_id, "to_user_id": from_id, "status": "pending"},
        ]
    })
    if pending:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="A friend request already exists between you and this user",
        )

    req_id = str(uuid.uuid4())
    now = datetime.utcnow()

    await db["friend_requests"].insert_one({
        "_id": req_id,
        "from_user_id": from_id,
        "to_user_id": to_id,
        "status": "pending",
        "created_at": now,
    })

    return {"id": req_id, "message": "Friend request sent"}


# ─── GET /requests — list pending incoming requests ──────────────────────────

@router.get("/requests", response_model=list[FriendRequestResponse])
async def get_pending_requests(
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database),
):
    """Return all pending incoming friend requests."""
    cursor = db["friend_requests"].find({
        "to_user_id": current_user["_id"],
        "status": "pending",
    }).sort("created_at", -1)

    results = []
    async for doc in cursor:
        # Look up sender username
        sender = await db["users"].find_one({"_id": doc["from_user_id"]})
        results.append(FriendRequestResponse(
            id=doc["_id"],
            from_user_id=doc["from_user_id"],
            from_username=sender["username"] if sender else "Unknown",
            to_user_id=doc["to_user_id"],
            to_username=current_user["username"],
            status=doc["status"],
            created_at=doc["created_at"],
        ))
    return results


# ─── PUT /accept/{req_id} — accept a friend request ─────────────────────────

@router.put("/accept/{req_id}")
async def accept_friend_request(
    req_id: str,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database),
):
    """Accept a pending incoming friend request."""
    req = await db["friend_requests"].find_one({"_id": req_id})
    if not req:
        raise HTTPException(status_code=404, detail="Request not found")
    if req["to_user_id"] != current_user["_id"]:
        raise HTTPException(status_code=403, detail="Not your request to accept")
    if req["status"] != "pending":
        raise HTTPException(status_code=400, detail="Request already processed")

    await db["friend_requests"].update_one(
        {"_id": req_id},
        {"$set": {"status": "accepted", "accepted_at": datetime.utcnow()}},
    )
    return {"message": "Friend request accepted"}


# ─── PUT /reject/{req_id} — reject a friend request ─────────────────────────

@router.put("/reject/{req_id}")
async def reject_friend_request(
    req_id: str,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database),
):
    """Reject a pending incoming friend request."""
    req = await db["friend_requests"].find_one({"_id": req_id})
    if not req:
        raise HTTPException(status_code=404, detail="Request not found")
    if req["to_user_id"] != current_user["_id"]:
        raise HTTPException(status_code=403, detail="Not your request to reject")
    if req["status"] != "pending":
        raise HTTPException(status_code=400, detail="Request already processed")

    await db["friend_requests"].update_one(
        {"_id": req_id},
        {"$set": {"status": "rejected"}},
    )
    return {"message": "Friend request rejected"}


# ─── GET / — list all accepted friends ───────────────────────────────────────

@router.get("/", response_model=list[FriendResponse])
async def get_friends(
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database),
):
    """Return all accepted friends with their stats."""
    user_id = current_user["_id"]

    cursor = db["friend_requests"].find({
        "$or": [
            {"from_user_id": user_id, "status": "accepted"},
            {"to_user_id": user_id, "status": "accepted"},
        ]
    })

    friends = []
    async for doc in cursor:
        friend_id = doc["to_user_id"] if doc["from_user_id"] == user_id else doc["from_user_id"]
        friend_user = await db["users"].find_one({"_id": friend_id})
        if not friend_user:
            continue

        # Get friend's session count
        session_count = await db["study_sessions"].count_documents({"user_id": friend_id})

        # Get friend's streak
        goal_doc = await db["user_goals"].find_one({"user_id": friend_id})
        daily_target = goal_doc["daily_target"] if goal_doc else 4
        from app.api.goals import _compute_streak
        streak = await _compute_streak(db, friend_id, daily_target)

        friends.append(FriendResponse(
            user_id=friend_id,
            username=friend_user["username"],
            email=friend_user["email"],
            current_streak=streak,
            total_sessions=session_count,
            since=doc.get("accepted_at", doc["created_at"]),
        ))

    return friends


# ─── DELETE /{friend_id} — remove a friend ──────────────────────────────────

@router.delete("/{friend_id}", status_code=status.HTTP_204_NO_CONTENT)
async def remove_friend(
    friend_id: str,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database),
):
    """Remove an accepted friend."""
    user_id = current_user["_id"]

    result = await db["friend_requests"].delete_one({
        "$or": [
            {"from_user_id": user_id, "to_user_id": friend_id, "status": "accepted"},
            {"from_user_id": friend_id, "to_user_id": user_id, "status": "accepted"},
        ]
    })
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Friend not found")


# ─── GET /search?q= — search users by username ──────────────────────────────

@router.get("/search")
async def search_users(
    q: str = "",
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database),
):
    """Search users by username (case-insensitive partial match)."""
    if len(q.strip()) < 2:
        return []

    import re
    pattern = re.compile(re.escape(q.strip()), re.IGNORECASE)

    cursor = db["users"].find({
        "username": {"$regex": pattern},
        "_id": {"$ne": current_user["_id"]},
    }).limit(20)

    results = []
    async for user in cursor:
        results.append({
            "user_id": user["_id"],
            "username": user["username"],
            "email": user["email"],
        })
    return results
