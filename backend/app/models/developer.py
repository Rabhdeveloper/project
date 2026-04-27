from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime
from bson import ObjectId

class PyObjectId(ObjectId):
    @classmethod
    def __get_validators__(cls):
        yield cls.validate

    @classmethod
    def validate(cls, v):
        if not ObjectId.is_valid(v):
            raise ValueError("Invalid objectid")
        return ObjectId(v)

    @classmethod
    def __modify_schema__(cls, field_schema):
        field_schema.update(type="string")

class PersonalAccessTokenCreate(BaseModel):
    name: str

class PersonalAccessTokenResponse(BaseModel):
    id: str = Field(alias="_id")
    user_id: str
    name: str
    created_at: datetime
    # We only show the actual token once, when it's generated, so we might need a separate schema for creation response
    
    class Config:
        populate_by_name = True
        json_encoders = {ObjectId: str}

class PersonalAccessTokenCreateResponse(PersonalAccessTokenResponse):
    token: str

class WebhookEndpointCreate(BaseModel):
    url: str
    events: List[str]

class WebhookEndpointResponse(WebhookEndpointCreate):
    id: str = Field(alias="_id")
    user_id: str
    created_at: datetime
    
    class Config:
        populate_by_name = True
        json_encoders = {ObjectId: str}
