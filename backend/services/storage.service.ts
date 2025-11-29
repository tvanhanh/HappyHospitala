// services/storage.service.ts
import AWS from "aws-sdk";
import fs from "fs";
import path from "path";

const USE_S3 = !!process.env.AWS_BUCKET;

if (USE_S3) {
  AWS.config.update({
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
    region: process.env.AWS_REGION,
  });
}
const s3 = new AWS.S3();

/**
 * uploadToStorage accepts:
 * - file: Multer file object OR { path, originalname, mimetype } OR a local file path string
 * returns public URL (or local path)
 */
export async function uploadToStorage(file: any): Promise<string> {
  // if string => treat as local path and return it (for local dev)
  if (typeof file === "string") {
    return file;
  }

  // if Multer or custom object with path
  const filePath = file.path || file.filePath;
  const originalname = file.originalname || path.basename(filePath);
  const mimetype = file.mimetype || "application/octet-stream";

  if (!filePath || !fs.existsSync(filePath)) {
    throw new Error("File not found for upload");
  }

  if (!USE_S3) {
    // local dev: move to public/uploads and return path
    const outDir = path.resolve(process.cwd(), "public", "uploads");
    if (!fs.existsSync(outDir)) fs.mkdirSync(outDir, { recursive: true });
    const outPath = path.join(outDir, `${Date.now()}_${originalname}`);
    fs.copyFileSync(filePath, outPath);
    return outPath; // caller should serve /public as static
  }

  const fileStream = fs.createReadStream(filePath);
  const key = `medical_records/${Date.now()}_${originalname}`;

  const params = {
    Bucket: process.env.AWS_BUCKET!,
    Key: key,
    Body: fileStream,
    ContentType: mimetype,
    ACL: "private", // or "public-read" if you want direct public access
  };

  const res = await s3.upload(params).promise();
  return res.Location;
}
