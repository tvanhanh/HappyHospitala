import { ethers } from "ethers";
import MedicalRecordsABI from "./artifacts/contracts/MedicalRecords.sol/MedicalRecords.json";



const provider = new ethers.JsonRpcProvider(process.env.RPC_URL);

const contract = new ethers.Contract(
  process.env.CONTRACT_ADDRESS!,
  MedicalRecordsABI.abi,
  provider
);

export async function getPdfHashFromBlockchain(
  patientId: string,
  index: number
): Promise<string> {
  const record = await contract.getRecord(patientId, index);

  return record[3]; // 👈 data = pdfHash
}
