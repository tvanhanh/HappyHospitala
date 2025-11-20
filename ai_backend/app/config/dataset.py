from pymongo import MongoClient
import os

MONGO_URI = os.getenv("mongodb://localhost:27017")
client = MongoClient(MONGO_URI)

db = client["datasets"] 
patient_collection = db["dataset"] 
