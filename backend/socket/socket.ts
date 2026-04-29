// import express from "express";
// import http from "http";
// import { Server } from "socket.io";

// const app = express();
// const server = http.createServer(app);

// const io = new Server(server, {
//   cors: { origin: "*" }
// });

// io.on("connection", (socket) => {
//   console.log("User connected");
// });

// app.post("/create-appointment", async (req, res) => {
//   const appointment = req.body;

//   await db.collection("appointments").insertOne(appointment);

//   io.emit("new_appointment", appointment);

//   res.json({ success: true });
// });

// server.listen(5000, () => {
//   console.log("Server running");
// });