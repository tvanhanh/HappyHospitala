import { ethers } from "ethers";

const RPC_URL = process.env.RPC_URL || "";
const PRIVATE_KEY = process.env.PRIVATE_KEY || "";
const CONTRACT_ADDRESS = process.env.CONTRACT_ADDRESS || "";

const provider = new ethers.JsonRpcProvider(RPC_URL);

// Normalize PRIVATE_KEY
let normalizedKey = PRIVATE_KEY.includes("=")
  ? PRIVATE_KEY.split("=").pop() || ""
  : PRIVATE_KEY;
if (normalizedKey && !normalizedKey.startsWith("0x")) normalizedKey = "0x" + normalizedKey;

const wallet = new ethers.Wallet(normalizedKey, provider);

const ABI = [
  "function addRecord(string memory patientId, string memory ipfsHash, string memory dob, string memory data) external",
  "function getRecordCount(string memory patientId) public view returns (uint256)",
  "function getRecord(string memory patientId, uint256 index) public view returns (string memory, string memory, string memory, string memory, uint256)",
];

const contract = new ethers.Contract(CONTRACT_ADDRESS, ABI, wallet);

export async function uploadHashToBlockchain(
  recordId: string,
  ipfsCID : string,
  pdfHash: string
): Promise<{
  txHash: string;
  network?: string;
  blockNumber?: number;
  blockchainIndex?: number;
}> {
  console.log("=== uploadHashToBlockchain ===");
  console.log({ recordId, ipfsCID , pdfHash });

  const dob = "";

  // Check network
  const net = await provider.getNetwork();
  console.log("Connected to network:", net.name, "(chainId:", net.chainId, ")");

  // Verify contract exists
  const code = await provider.getCode(CONTRACT_ADDRESS);
  if (!code || code === "0x") throw new Error(`No contract code at ${CONTRACT_ADDRESS}`);
  console.log("Contract code verified");

  // Encode calldata (optional log)
  const calldata = contract.interface.encodeFunctionData("addRecord", [
    recordId,
    ipfsCID ,
    dob,
    pdfHash,
  ]);
  console.log("Encoded calldata:", calldata.substring(0, 100) + "...");

  // Send transaction
  const tx = await contract.addRecord(recordId, ipfsCID , dob, pdfHash, { gasLimit: 300000 });
  console.log("Transaction hash:", tx.hash);

  const receipt = await tx.wait(1);
  if (receipt.status === 0) throw new Error(`Transaction reverted: ${tx.hash}`);

  const count = await contract.getRecordCount(recordId);
  const blockchainIndex = Number(count) - 1;

  return {
    txHash: tx.hash,
    network: net.name,
    blockNumber: receipt.blockNumber,
    blockchainIndex,
  };
}

// Lấy record từ blockchain
export async function getRecordFromBlockchain(
  patientId: string,
  index: number
): Promise<{
  patientId: string;
  ipfsHash: string;
  dob: string;
  data: string;
  timestamp: number;
} | null> {
  try {
    const rc = await contract.getRecord(patientId, index);
    return {
      patientId: rc[0],
      ipfsHash: rc[1],
      dob: rc[2],
      data: rc[3],
      timestamp: Number(rc[4]),
    };
  } catch {
    return null;
  }
}
