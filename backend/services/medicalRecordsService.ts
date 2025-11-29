import { ethers } from "ethers";
import MedicalRecordsABI from "../../blockchain/artifacts/contracts/MedicalRecords.sol/MedicalRecords.json";

const provider = new ethers.JsonRpcProvider(process.env.SEPOLIA_RPC_URL!);
const signer = new ethers.Wallet(process.env.SEPOLIA_PRIVATE_KEY!, provider);
const CONTRACT_ADDRESS = "0x5Db627E8956c7b9d62515B04Fb4EA2363F4cFba1"; // thay bằng contract của bạn

const medicalRecordsContract = new ethers.Contract(
  CONTRACT_ADDRESS,
  MedicalRecordsABI.abi,
  signer
);

export async function addRecord(patientId: string, name: string, dob: string, data: string) {
  const tx = await medicalRecordsContract.addRecord(patientId, name, dob, data);
  await tx.wait();
  return tx.hash;
}

export async function getRecordCount(patientId: string) {
  return await medicalRecordsContract.getRecordCount(patientId);
}

export async function getRecord(patientId: string, index: number) {
  return await medicalRecordsContract.getRecord(patientId, index);
}
