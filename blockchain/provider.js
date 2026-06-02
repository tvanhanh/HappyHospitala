"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.wallet = exports.provider = void 0;
const ethers_1 = require("ethers");
exports.provider = new ethers_1.JsonRpcProvider(process.env.RPC_URL);
exports.wallet = new ethers_1.Wallet(process.env.PRIVATE_KEY, exports.provider);
