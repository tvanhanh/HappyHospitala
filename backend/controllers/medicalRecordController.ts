import MedicalRecord from "../models/medicalRecord";
import CryptoJS from "crypto-js";
import { create } from "ipfs-http-client";
import { ethers } from "ethers";
import contractAbi from "../config/contractAbi.json";

// Setup IPFS client
const ipfsClient = create({ url: "https://ipfs.infura.io:5001" });

const addMedicalRecord = async (req, res) => {
  const { patientId, doctorId, ehrContent } = req.body;
  // 1. Mã hóa
  const secretKey = process.env.SECRET_KEY;
  const encrypted = CryptoJS.AES.encrypt(ehrContent, secretKey).toString();

  // 2. Upload IPFS
  const ipfsResult = await ipfsClient.add(encrypted);
  const ipfsCid = ipfsResult.cid.toString();

  // 3. Hash
  const ehrHash = ethers.utils.keccak256(Buffer.from(encrypted, "utf8"));

  // 4. Lưu blockchain (Ethereum/Polygon/BSC)
  const provider = new ethers.providers.JsonRpcProvider(process.env.BLOCKCHAIN_RPC);
  const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);
  const contract = new ethers.Contract(process.env.CONTRACT_ADDRESS, contractAbi, wallet);

  const tx = await contract.storeRecord(ehrHash, ipfsCid, patientId, doctorId);

  // 5. Lưu MongoDB
  await MedicalRecord.create({
    patientId, doctorId,
    content: encrypted, ipfsCid, ehrHash,
    blockchainTxId: tx.hash,
  });

  res.json({ success: true, ehrHash, ipfsCid, blockchainTxId: tx.hash });
};
export { addMedicalRecord };
