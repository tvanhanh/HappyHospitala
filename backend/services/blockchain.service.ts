// services/blockchain.service.ts
import { ethers } from "ethers";

const RPC_URL = process.env.RPC_URL || "";
const PRIVATE_KEY = process.env.PRIVATE_KEY || "";
const CONTRACT_ADDRESS = process.env.CONTRACT_ADDRESS || "";

const provider = new ethers.JsonRpcProvider(RPC_URL);
const wallet = new ethers.Wallet(PRIVATE_KEY, provider);

// Minimal ABI for our contract
const ABI = [
  "function storeRecordHash(string recordId, string recordHash) external",
  "function getRecord(string recordId) view returns (string recordHash, address creator, uint256 timestamp)"
];

const contract = new ethers.Contract(CONTRACT_ADDRESS, ABI, wallet);

/**
 * uploadHashToBlockchain(recordId, recordHash)
 * returns txHash (string)
 */
export async function uploadHashToBlockchain(recordId: string, recordHash: string): Promise<string> {
  // Note: add error handling and optional whitelist check in contract
  const tx = await contract.storeRecordHash(recordId, recordHash, { gasLimit: 300000 });
  const receipt = await tx.wait(1);
  return receipt.transactionHash;
}

/**
 * getHashFromBlockchain(recordId)
 */
export async function getHashFromBlockchain(recordId: string): Promise<{ recordHash: string; creator: string; timestamp: number } | null> {
  try {
    const rc = await contract.getRecord(recordId);
    return { recordHash: rc[0], creator: rc[1], timestamp: Number(rc[2]) };
  } catch (err) {
    return null;
  }
}
