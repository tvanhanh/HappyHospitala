"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.app = void 0;
const express_1 = __importDefault(require("express"));
const dotenv_1 = __importDefault(require("dotenv"));
const db_1 = __importDefault(require("./config/db"));
const cors_1 = __importDefault(require("cors"));
const auth_routes_1 = __importDefault(require("./routes/auth_routes"));
const appointment_routes_1 = __importDefault(require("./routes/appointment_routes"));
const doctor_routes_1 = __importDefault(require("./routes/doctor_routes"));
dotenv_1.default.config();
(0, db_1.default)();
const app = (0, express_1.default)();
exports.app = app;
app.use((0, cors_1.default)());
app.use(express_1.default.json());
app.get("/", (req, res) => {
    res.send("Server is running!");
});
app.use("/auth", auth_routes_1.default);
app.use("/appointments", appointment_routes_1.default);
app.use("/doctors", doctor_routes_1.default);
app.listen(5000, () => console.log("Server running on port 5000"));
