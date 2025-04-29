import express from "express";
import dotenv from "dotenv";
import path from "path";
import connectDB from "./config/db";
import cors from "cors";
import auth_routes from "./routes/auth_routes";
import appointments_routes from "./routes/appointment_routes";



dotenv.config();
connectDB();

const app = express();
app.use(cors());
app.use(express.json());
app.get("/", (req, res) => {
    res.send("Server is running!");
  });
  
  app.use("/auth", auth_routes);
  app.use("/appointments", appointments_routes);
 

app.listen(5000, () => console.log("Server running on port 5000"));
export { app };