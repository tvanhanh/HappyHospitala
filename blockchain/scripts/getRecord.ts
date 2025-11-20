import { ethers } from "hardhat";

async function main() {
  const contractAddress = "0x5Db627E8956c7b9d62515B04Fb4EA2363F4cFba1";
  const MedicalRecords = await ethers.getContractAt("MedicalRecords", contractAddress);

  const patientId: string = "PAT123"; // giống phía trên
  const index = 0; // chỉ số hồ sơ (lần đầu thì là 0, viết nhiều thì là 1, 2,...)

  const record = await MedicalRecords.getRecord(patientId, index);
  console.log(
    `Thông tin hồ sơ:\nPatientId: ${record[0]}\nName: ${record[1]}\nDOB: ${record[2]}\nData: ${record[3]}\nTimestamp: ${record[4]}`
  );
}

main().catch((error) => {
  console.error("Lỗi khi lấy hồ sơ bệnh án:", error);
  process.exitCode = 1;
});
