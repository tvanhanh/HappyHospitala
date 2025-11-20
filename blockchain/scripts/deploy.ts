import { ethers } from "hardhat";

async function main() {
  const MedicalRecords = await ethers.getContractFactory("MedicalRecords");
  const contract = await MedicalRecords.deploy();
  const address = await contract.getAddress();
  console.log("MedicalRecords deployed to:", address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
