from fastapi import APIRouter, HTTPException, Depends, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from app.models.user import UserCreate, UserResponse, UserInDB
from app.core.security import get_password_hash, verify_password, create_access_token
from app.core.database import get_database
from app.core.config import settings
from datetime import timedelta
import uuid

router = APIRouter()
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="api/auth/token")

@router.post("/register", response_model=UserResponse)
async def register(user: UserCreate, db = Depends(get_database)):
    # Check if user exists
    existing_user = await db["users"].find_one({"email": user.email})
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )
    
    # Hash password and insert
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

@router.post("/token")
async def login(form_data: OAuth2PasswordRequestForm = Depends(), db = Depends(get_database)):
    user_dict = await db["users"].find_one({"email": form_data.username})  # Using email as username
    
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
