from motor.motor_asyncio import AsyncIOMotorClient
from app.core.config import settings

class Database:
    client: AsyncIOMotorClient = None
    db = None

db = Database()

def connect_to_mongo():
    print("Connecting to mongo...")
    db.client = AsyncIOMotorClient(settings.MONGODB_URL)
    db.db = db.client[settings.DATABASE_NAME]
    print(f"Connected. db.db is {db.db}")

def close_mongo_connection():
    db.client.close()

def get_database():
    print(f"get_database called, returning {db.db}")
    return db.db
