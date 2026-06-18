import express from "express";
import dotenv from "dotenv";
import path from "path";
import connectDB from "./config/db";
import cors from "cors";
import { createServer } from "http";
import { Server } from "socket.io";
import { startCronJobs } from "./jobs/cron";

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

  socket.on("join_room", (data: { userId?: string; role?: string; roomId?: string }) => {
    const { userId, role, roomId } = data ?? {};
    if (roomId) {
      socket.join(roomId);
      console.log(`[Socket] Socket ${socket.id} joined room: ${roomId}`);
    }
    if (userId) {
      socket.join(`user_${userId}`);
      console.log(`[Socket] Socket ${socket.id} joined private room: user_${userId}`);
    }
    if (role) {
      socket.join(`${role}_room`);
      console.log(`[Socket] Socket ${socket.id} joined role room: ${role}_room`);
    }
  });

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

httpServer.listen(5001, () => {
  console.log("Server running on port 5001");

  // 🔥 START CRON HERE
  startCronJobs();
});
export { app, io };