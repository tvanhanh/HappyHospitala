// services/hash.service.ts
import fs from "fs";
import crypto from "crypto";

/**
 * calculateHash(path): returns '0x' + hex digest
 */
export async function calculateHash(filePath: string): Promise<string> {
  return new Promise((resolve, reject) => {
    try {
      const hash = crypto.createHash("sha256");
      const stream = fs.createReadStream(filePath);
      stream.on("data", (chunk) => hash.update(chunk));
      stream.on("end", () => resolve("0x" + hash.digest("hex")));
      stream.on("error", (err) => reject(err));
    } catch (err) {
      reject(err);
    }
  });
}
