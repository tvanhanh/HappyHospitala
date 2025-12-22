import { ethers } from "ethers";
import MedicalRecordsABI from "../../blockchain/artifacts/contracts/MedicalRecords.sol/MedicalRecords.json";

const provider = new ethers.JsonRpcProvider(process.env.SEPOLIA_RPC_URL!);
const signer = new ethers.Wallet(process.env.SEPOLIA_PRIVATE_KEY!, provider);
const CONTRACT_ADDRESS = "0x7e398Ab8cb7457e655E3A49Abe3D6608fB924535"; 

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
