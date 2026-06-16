import { io } from "../server";

export const emitToRoom = (room: string, event: string, data: any) => {
  if (io) {
    console.log(`[Socket] Emitting event "${event}" to room "${room}":`, data);
    io.to(room).emit(event, data);
  } else {
    console.warn(`[Socket] Cannot emit event "${event}" — io is not initialized`);
  }
};

export const emitToUser = (userId: string, event: string, data: any) => {
  emitToRoom(`user_${userId}`, event, data);
};

export const emitToRole = (role: string, event: string, data: any) => {
  emitToRoom(`${role}_room`, event, data);
};
