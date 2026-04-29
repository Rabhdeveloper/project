from fastapi import APIRouter, Depends, HTTPException, status
from typing import List
from datetime import datetime
from bson import ObjectId

from app.core.database import get_database
from app.api.auth import get_current_user
from app.models.user import UserInDB
from app.models.knowledge_graph import (
    AutoCourseCreate, AutoCourseResponse,
    KnowledgeNodeCreate, KnowledgeNode,
    KnowledgeEdgeCreate, LearningPathway,
)
from app.core.knowledge_graph import knowledge_graph_engine

router = APIRouter()


@router.get("/topics")
async def list_knowledge_topics(current_user: UserInDB = Depends(get_current_user)):
    topics = knowledge_graph_engine.get_all_topics()
    return {"status": "success", "data": topics, "total": len(topics)}


@router.get("/pathway")
async def find_learning_pathway(start: str, end: str, current_user: UserInDB = Depends(get_current_user)):
    path = knowledge_graph_engine.find_path(start, end)
    if path is None:
        raise HTTPException(status_code=404, detail=f"No pathway found between '{start}' and '{end}'.")
    return LearningPathway(
        start_topic=start, end_topic=end, path=path, path_titles=path,
        total_hops=len(path) - 1, estimated_hours=round((len(path) - 1) * 2.5, 1),
    )


@router.get("/explore/{topic}")
async def explore_six_degrees(topic: str, current_user: UserInDB = Depends(get_current_user)):
    result = knowledge_graph_engine.six_degrees_of_knowledge(topic)
    if not result["connections"]:
        raise HTTPException(status_code=404, detail=f"Topic '{topic}' not found in the knowledge graph.")
    return {"status": "success", "data": result}


@router.post("/generate", response_model=AutoCourseResponse, status_code=status.HTTP_201_CREATED)
async def generate_course(course_in: AutoCourseCreate, current_user: UserInDB = Depends(get_current_user)):
    db = get_database()
    curriculum_data = knowledge_graph_engine.generate_curriculum(goal=course_in.goal, duration_days=course_in.duration_days)
    course_doc = {
        "user_id": str(current_user.id), "goal": course_in.goal, "difficulty": course_in.difficulty,
        "duration_days": course_in.duration_days, "title": curriculum_data["title"],
        "description": curriculum_data["description"], "syllabus": curriculum_data["syllabus"],
        "progress_percent": 0.0, "status": "active", "generated_at": datetime.utcnow(),
    }
    result = await db["auto_courses"].insert_one(course_doc)
    course_doc["_id"] = str(result.inserted_id)
    return course_doc


@router.get("", response_model=List[AutoCourseResponse])
async def list_courses(current_user: UserInDB = Depends(get_current_user)):
    db = get_database()
    cursor = db["auto_courses"].find({"user_id": str(current_user.id)}).sort("generated_at", -1)
    courses = []
    async for course in cursor:
        course["_id"] = str(course["_id"])
        courses.append(course)
    return courses


@router.get("/{course_id}", response_model=AutoCourseResponse)
async def get_course(course_id: str, current_user: UserInDB = Depends(get_current_user)):
    db = get_database()
    if not ObjectId.is_valid(course_id):
        raise HTTPException(status_code=400, detail="Invalid course ID")
    course = await db["auto_courses"].find_one({"_id": ObjectId(course_id), "user_id": str(current_user.id)})
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")
    course["_id"] = str(course["_id"])
    return course
