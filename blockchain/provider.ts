import { JsonRpcProvider, Wallet } from "ethers";

export const provider = new JsonRpcProvider(process.env.RPC_URL);

export const wallet = new Wallet(
  process.env.PRIVATE_KEY as string,
  provider
);
