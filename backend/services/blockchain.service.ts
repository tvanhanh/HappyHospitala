import { ethers } from "ethers";

const RPC_URL = process.env.RPC_URL || "";
const PRIVATE_KEY = process.env.PRIVATE_KEY || "";
const CONTRACT_ADDRESS = process.env.CONTRACT_ADDRESS || "";

const provider = new ethers.JsonRpcProvider(RPC_URL);

// Normalize PRIVATE_KEY in case .env contains "KEY_NAME=value" format
let normalizedKey = PRIVATE_KEY;
if (normalizedKey.includes("=")) {
  normalizedKey = normalizedKey.split("=").pop() || normalizedKey;
}
if (normalizedKey && !normalizedKey.startsWith("0x")) {
  normalizedKey = "0x" + normalizedKey;
}

const wallet = new ethers.Wallet(normalizedKey, provider);

// ABI for MedicalRecords.sol
const ABI = [
  "function addRecord(string memory patientId, string memory name, string memory dob, string memory data) external",
  "function getRecordCount(string memory patientId) public view returns (uint256)",
  "function getRecord(string memory patientId, uint256 index) public view returns (string memory, string memory, string memory, string memory, uint256)",
];

// Create contract instance
const contract = new ethers.Contract(
  CONTRACT_ADDRESS,
  ABI,
  wallet
);


export async function uploadHashToBlockchain(
  recordId: string,
  patientName: string,
  pdfHash: string
): Promise<{ txHash: string; network?: string; blockNumber?: number }> {
  console.log("=== uploadHashToBlockchain called ===");
  console.log("recordId:", recordId);
  console.log("patientName:", patientName);
  console.log("pdfHash:", pdfHash);
  console.log("CONTRACT_ADDRESS:", CONTRACT_ADDRESS);
  console.log("RPC_URL:", RPC_URL.substring(0, 50) + "...");

  const patientId = recordId;
  const name = patientName;
  const dob = "";
  const data = pdfHash;

  // Diagnostics: check network
  try {
    const net = await provider.getNetwork();
    console.log("Connected to network:", net.name, "(chainId:", net.chainId + ")");
  } catch (err) {
    console.error("Failed to get network info:", err);
  }

  // Diagnostics: verify contract code exists
  try {
    const code = await provider.getCode(CONTRACT_ADDRESS);
    if (!code || code === "0x") {
      throw new Error(
        `No contract code found at ${CONTRACT_ADDRESS}. Check RPC URL and CONTRACT_ADDRESS.`
      );
    }
    console.log("Contract code verified at", CONTRACT_ADDRESS);
  } catch (err) {
    console.error("Contract code check failed:", err);
    throw err;
  }

  // Log encoded calldata
  try {
    const calldata = (contract as any).interface.encodeFunctionData("addRecord", [
      patientId,
      name,
      dob,
      data,
    ]);
    console.log("Encoded calldata:", calldata.substring(0, 100) + "...");
  } catch (err) {
    console.error("Failed to encode calldata:", err);
  }

  // Send transaction
  try {
    console.log("Sending transaction...");
    const tx = await (contract as any).addRecord(patientId, name, dob, data, {
      gasLimit: 300000,
    });
    console.log("Transaction hash:", tx.hash);

    const receipt = await tx.wait(1);
    console.log("Transaction receipt status:", receipt?.status);

    if (receipt?.status === 0) {
      throw new Error(
        `Transaction reverted. txHash=${receipt.transactionHash} blockNumber=${receipt.blockNumber}`
      );
    }

    console.log("Transaction succeeded txHash =", tx.hash);

    // get network name if possible
    let networkName: string | undefined;
    try {
      const net = await provider.getNetwork();
      networkName = net.name;
    } catch (err) {
      networkName = undefined;
    }

    return {
      txHash: tx.hash,
      network: networkName,
      blockNumber: receipt.blockNumber,
    };
  } catch (err) {
    console.error("Transaction failed:", err);
    throw err;
  }
}

/**
 * getRecordFromBlockchain(patientId, index)
 */
export async function getRecordFromBlockchain(
  patientId: string,
  index: number
): Promise<{
  patientId: string;
  name: string;
  dob: string;
  data: string;
  timestamp: number;
} | null> {
  try {
    const rc = await (contract as any).getRecord(patientId, index);
    return {
      patientId: rc[0],
      name: rc[1],
      dob: rc[2],
      data: rc[3],
      timestamp: Number(rc[4]),
    };
  } catch {
    return null;
  }
}
