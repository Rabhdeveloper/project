from pydantic import BaseModel, Field
from typing import List, Optional, Dict
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


# ─── Knowledge Graph Nodes & Edges ────────────────────────────────────────────

class KnowledgeNode(BaseModel):
    """Represents a topic/concept in the global knowledge graph."""
    id: str = Field(alias="_id")
    title: str
    category: str  # subject, concept, skill, resource
    description: str = ""
    tags: List[str] = []
    contributor_count: int = 0
    rating: float = 0.0  # Community average rating
    created_by: str = ""
    created_at: datetime

    class Config:
        populate_by_name = True
        json_encoders = {ObjectId: str}


class KnowledgeNodeCreate(BaseModel):
    title: str
    category: str = "concept"
    description: str = ""
    tags: List[str] = []


class KnowledgeEdge(BaseModel):
    """Directional relationship between two knowledge nodes."""
    source_id: str
    target_id: str
    relationship: str  # prerequisite, related, builds_on, contrasts_with
    weight: float = 1.0  # Strength of connection


class KnowledgeEdgeCreate(BaseModel):
    source_id: str
    target_id: str
    relationship: str = "related"


# ─── AI Auto-Generated Courses ────────────────────────────────────────────────

class CourseDayPlan(BaseModel):
    day: int
    title: str
    topics: List[str] = []
    resources: List[str] = []  # IDs of related notes/flashcards from the knowledge graph
    estimated_minutes: int = 45
    completed: bool = False


class AutoCourseBase(BaseModel):
    goal: str  # e.g., "Learn Quantum Computing from scratch"
    difficulty: str = "beginner"  # beginner, intermediate, advanced
    duration_days: int = 30


class AutoCourseCreate(AutoCourseBase):
    pass


class AutoCourseResponse(AutoCourseBase):
    id: str = Field(alias="_id")
    user_id: str
    title: str
    description: str
    syllabus: List[CourseDayPlan] = []
    progress_percent: float = 0.0
    status: str = "active"  # active, completed, paused
    generated_at: datetime

    class Config:
        populate_by_name = True
        json_encoders = {ObjectId: str}


# ─── Verifiable Credentials (Web3) ────────────────────────────────────────────

class VerifiableCredentialBase(BaseModel):
    title: str  # e.g., "Mastered Linear Algebra"
    description: str = ""
    credential_type: str = "achievement"  # achievement, course_completion, skill_mastery
    subject: str = ""
    study_hours: float = 0.0
    test_score: Optional[float] = None


class CredentialMintRequest(VerifiableCredentialBase):
    pass


class VerifiableCredentialResponse(VerifiableCredentialBase):
    id: str = Field(alias="_id")
    user_id: str
    token_id: str  # Simulated blockchain token ID
    chain: str = "polygon_testnet"  # Simulated chain
    tx_hash: str = ""  # Simulated transaction hash
    is_verified: bool = True
    issued_at: datetime
    public_url: str = ""  # Public verification URL

    class Config:
        populate_by_name = True
        json_encoders = {ObjectId: str}


# ─── Learning Pathway ─────────────────────────────────────────────────────────

class LearningPathway(BaseModel):
    """A suggested learning path connecting topics across the knowledge graph."""
    start_topic: str
    end_topic: str
    path: List[str] = []  # Ordered list of topic IDs
    path_titles: List[str] = []  # Human-readable topic names
    total_hops: int = 0
    estimated_hours: float = 0.0
