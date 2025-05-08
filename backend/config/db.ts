import mongoose from "mongoose";
import dotenv from "dotenv";

dotenv.config();

const connectDB = async () => {
    try {
        await mongoose.connect(process.env.MONGO_URI as string);
        console.log("MongoDB connected");
    } catch (error) {
        console.error("MongoDB connection failed", error);
        process.exit(1);
    }
};

export default connectDB;
// emulator -avd Pixel_7_API_31
// Accout login 
// admin@gmail.com , pass: 123456
// doctor@gmail.com, pass: 123456 
