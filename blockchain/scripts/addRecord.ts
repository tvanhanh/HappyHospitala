import { ethers } from "hardhat";

async function main() {
  // Địa chỉ contract MedicalRecords đã deploy trên Sepolia
  const contractAddress = "0x5Db627E8956c7b9d62515B04Fb4EA2363F4cFba1"; // thay bằng địa chỉ contract của bạn

  // Lấy instance contract MedicalRecords đã deploy
  const MedicalRecords = await ethers.getContractAt("MedicalRecords", contractAddress);

  // Dữ liệu hồ sơ bệnh án
  const patientId: string = "PAT123";                     // Mã bệnh nhân (string, ví dụ mã hồ sơ)
  const name: string = "Nguyen Van A";                    // Họ tên bệnh nhân
  const dob: string = "2001-01-01";                       // Ngày sinh
  const data: string = "Qm123abc... hoặc dữ liệu hồ sơ";  // Thông tin hoặc mã IPFS/file của hồ sơ

  // Gọi hàm contract để thêm hồ sơ bệnh án
  const tx = await MedicalRecords.addRecord(patientId, name, dob, data);
  await tx.wait();

  console.log("Thêm hồ sơ bệnh án lên blockchain thành công! Tx Hash:", tx.hash);
}

main().catch((error) => {
  console.error("Lỗi khi thêm hồ sơ:", error);
  process.exitCode = 1;
});
