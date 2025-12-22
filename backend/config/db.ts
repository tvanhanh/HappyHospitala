// config/db.ts
import mongoose from "mongoose";
import dotenv from "dotenv";
import { GridFSBucket } from "mongodb";

dotenv.config();

let gridFSBucket: GridFSBucket | null = null;

const connectDB = async () => {
  try {
    const conn = await mongoose.connect(process.env.MONGO_URI as string);

    console.log("MongoDB connected");

    const db = conn.connection.db;
    if (!db) {
      throw new Error("MongoDB Db instance is undefined");
    }

    // Khởi tạo GridFSBucket
    gridFSBucket = new mongoose.mongo.GridFSBucket(db, {
      bucketName: "medical_files",
    });

  } catch (error) {
    console.error("MongoDB connection failed", error);
    process.exit(1);
  }
};

// Lấy GridFSBucket để dùng trong controller
export const getGridFSBucket = (): GridFSBucket => {
  if (!gridFSBucket) {
    throw new Error("GridFSBucket chưa được khởi tạo. Hãy gọi connectDB() trước.");
  }
  return gridFSBucket;
};

export default connectDB;

// emulator -avd Pixel_7_API_31
// Accout login 
// admin@gmail.com , pass: 123456
// doctor@gmail.com, pass: 123456 
