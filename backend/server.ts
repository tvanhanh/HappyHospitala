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

  socket.on("send_message", async (msgData: { roomId: string; content: string; senderId: string; senderName: string; recipientId?: string }) => {
    const { roomId, content, senderId, senderName } = msgData;
    if (!roomId || !content) return;

    // Kiểm tra xem phòng khám này có bị khóa (Kết thúc phiên) không
    let isLocked = false;
    try {
      if (roomId.startsWith("chat:")) {
        const parts = roomId.replace("chat:", "").split("_");
        if (parts.length === 2) {
          const [patientId, doctorId] = parts;
          const Appointment = require("./models/Appointment").default;
          const lockedAppt = await Appointment.findOne({
            patient: patientId,
            doctor: doctorId,
            appointmentType: "online",
            isLocked: true
          });
          if (lockedAppt) {
            isLocked = true;
          }
        }
      }
    } catch (err) {
      console.error("Lỗi kiểm tra lock socket room:", err);
    }

    if (isLocked) {
      socket.emit("error", { message: "Phòng khám đã đóng. Khung chat hiện ở chế độ chỉ đọc." });
      return;
    }

    // Lưu tin nhắn mới vào database
    try {
      const Message = require("./models/Message").MessageModel;
      const newMessage = await Message.create({
        senderId,
        roomId,
        text: content,
        senderName
      });
      // Phát tin nhắn cho cả phòng nhận
      io.to(roomId).emit("receive_message", newMessage);
    } catch (saveErr) {
      console.error("Lỗi lưu socket message:", saveErr);
    }
  });

  socket.on("typing", (data: { roomId?: string }) => {
    if (data?.roomId) {
      socket.to(data.roomId).emit("typing", data);
    }
  });

  socket.on("stop_typing", (data: { roomId?: string }) => {
    if (data?.roomId) {
      socket.to(data.roomId).emit("stop_typing", data);
    }
  });

  socket.on("leave_room", (data: { roomId?: string }) => {
    if (data?.roomId) {
      socket.leave(data.roomId);
      console.log(`[Socket] Socket ${socket.id} left room: ${data.roomId}`);
    }
  });

  socket.on("disconnect", () => {
    console.log(`[Socket] User disconnected: ${socket.id}`);
  });
});

import appRouter from "./routes/index";
import { getMessages, createMessage } from "./controllers/messageController";
import { verifyToken } from "./middleware/auth";
import upload from "./middleware/upload";

app.use(cors());
app.use(express.json());
app.get("/", (req, res) => {
    res.send("Server is running!");
});

// Fallback toàn cục cho chat_screen.dart (Gọi trực tiếp không cần tiền tố /api)
app.get('/messages/:roomId', verifyToken, async (req: any, res: any) => {
  req.query.roomId = req.params.roomId;
  return getMessages(req, res);
});
app.post('/messages', upload.single('file'), verifyToken, createMessage);

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



