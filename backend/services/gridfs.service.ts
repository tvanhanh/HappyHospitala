
import { ObjectId } from "mongodb";
import { getGridFSBucket } from "../config/db";

export const getImageBufferFromGridFS = async (
  fileId: string
): Promise<Buffer> => {
  const bucket = getGridFSBucket();

  return new Promise((resolve, reject) => {
    const chunks: Buffer[] = [];

    bucket
      .openDownloadStream(new ObjectId(fileId))
      .on("data", (chunk) => chunks.push(chunk))
      .on("end", () => resolve(Buffer.concat(chunks)))
      .on("error", reject);
  });
};
