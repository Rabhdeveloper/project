from fastapi import APIRouter, HTTPException, Depends, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from app.models.user import UserCreate, UserResponse, UserInDB, UserUpdate
from app.core.security import get_password_hash, verify_password, create_access_token, decode_access_token
from app.core.database import get_database
from app.core.config import settings
from datetime import timedelta
import uuid

router = APIRouter()
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="api/auth/token")


# ─── Dependency: Get Current Authenticated User ───────────────────────────────

async def get_current_user(token: str = Depends(oauth2_scheme), db=Depends(get_database)):
    """Decode JWT token and return the authenticated user document from the DB."""
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    payload = decode_access_token(token)
    if payload is None:
        raise credentials_exception

    email: str = payload.get("sub")
    if email is None:
        raise credentials_exception

    user = await db["users"].find_one({"email": email})
    if user is None:
        raise credentials_exception

    return user


# ─── Register ─────────────────────────────────────────────────────────────────

@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def register(user: UserCreate, db=Depends(get_database)):
    # Check if user already exists
    existing_user = await db["users"].find_one({"email": user.email})
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )

    # Hash password and save user
    user_id = str(uuid.uuid4())
    hashed_pass = get_password_hash(user.password)

    db_user = UserInDB(
        _id=user_id,
        username=user.username,
        email=user.email,
        hashed_password=hashed_pass
    )

    await db["users"].insert_one(db_user.dict(by_alias=True))

    return UserResponse(
        id=user_id,
        username=user.username,
        email=user.email,
        created_at=db_user.created_at
    )


# ─── Login ────────────────────────────────────────────────────────────────────

@router.post("/token")
async def login(form_data: OAuth2PasswordRequestForm = Depends(), db=Depends(get_database)):
    # OAuth2 uses 'username' field — we treat it as email
    user_dict = await db["users"].find_one({"email": form_data.username})

    if not user_dict or not verify_password(form_data.password, user_dict["hashed_password"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user_dict["email"]}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}


# ─── Get My Profile ───────────────────────────────────────────────────────────

@router.get("/me", response_model=UserResponse)
async def get_my_profile(current_user: dict = Depends(get_current_user)):
    """Return the authenticated user's profile."""
    return UserResponse(
        id=current_user["_id"],
        username=current_user["username"],
        email=current_user["email"],
        created_at=current_user["created_at"]
    )


# ─── Update My Profile ────────────────────────────────────────────────────────

@router.put("/me", response_model=UserResponse)
async def update_my_profile(
    update_data: UserUpdate,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_database)
):
    """Update the authenticated user's profile (username only for now)."""
    update_fields = {}
    if update_data.username:
        update_fields["username"] = update_data.username

    if not update_fields:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No fields to update"
        )

    await db["users"].update_one(
        {"_id": current_user["_id"]},
        {"$set": update_fields}
    )

    # Return updated user
    updated_user = await db["users"].find_one({"_id": current_user["_id"]})
    return UserResponse(
        id=updated_user["_id"],
        username=updated_user["username"],
        email=updated_user["email"],
        created_at=updated_user["created_at"]
    )
