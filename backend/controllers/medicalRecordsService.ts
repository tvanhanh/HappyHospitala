import { ethers } from "ethers";
import MedicalRecordsABI from "../../blockchain/artifacts/contracts/MedicalRecords.sol/MedicalRecords.json";

const provider = new ethers.JsonRpcProvider(process.env.SEPOLIA_RPC_URL!);
const signer = new ethers.Wallet(process.env.SEPOLIA_PRIVATE_KEY!, provider);
const CONTRACT_ADDRESS = "0xc6B58592A13a32f344DA58a40755F251a0ac605b"; 

const medicalRecordsContract = new ethers.Contract(
  CONTRACT_ADDRESS,
  MedicalRecordsABI.abi,
  signer
);

export async function addRecord(patientId: string, ipfsHash: string, dob: string, data: string) {
  const tx = await medicalRecordsContract.addRecord(patientId, ipfsHash, dob, data);
  await tx.wait();
  return tx.hash;
}

export async function getRecordCount(patientId: string) {
  return await medicalRecordsContract.getRecordCount(patientId);
}

export async function getRecord(patientId: string, index: number) {
  return await medicalRecordsContract.getRecord(patientId, index);
}
