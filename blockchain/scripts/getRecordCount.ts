import { ethers } from "hardhat";

async function main() {
  const contractAddress = "0x5Db627E8956c7b9d62515B04Fb4EA2363F4cFba1"; // địa chỉ contract của bạn
  const MedicalRecords = await ethers.getContractAt("MedicalRecords", contractAddress);

  const patientId: string = "PAT123"; // mã bệnh nhân bạn đã nhập lúc ghi hồ sơ

  const count = await MedicalRecords.getRecordCount(patientId);
  console.log(`Số hồ sơ bệnh án của bệnh nhân ${patientId}:`, count.toString());
}

main().catch((error) => {
  console.error("Lỗi khi lấy số hồ sơ:", error);
  process.exitCode = 1;
});
