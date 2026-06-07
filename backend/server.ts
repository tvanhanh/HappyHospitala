import express from "express";
import dotenv from "dotenv";
import path from "path";
import connectDB from "./config/db";
import cors from "cors";
import { createServer } from "http";
import { Server } from "socket.io";


dotenv.config();
connectDB();

const app = express();
const httpServer = createServer(app);
const io = new Server(httpServer, {
  cors: {
    origin: "*",
    methods: ["GET", "POST", "PUT", "PATCH", "DELETE"]
  }
});

io.on("connection", (socket) => {
  console.log(`[Socket] User connected: ${socket.id}`);
  socket.on("disconnect", () => {
    console.log(`[Socket] User disconnected: ${socket.id}`);
  });
});

import appRouter from "./routes/index";

app.use(cors());
app.use(express.json());
app.get("/", (req, res) => {
    res.send("Server is running!");
});

// Apply global API prefix matching the nested architecture
app.use("/api", appRouter);
// Legacy alias to preserve clients still targeting /api/v1
app.use("/api/v1", appRouter);

httpServer.listen(5000, () => console.log("Server running on port 5000"));
// Force reload nodemon
export { app, io };