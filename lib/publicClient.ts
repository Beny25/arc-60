import { createPublicClient, http } from "viem";
import { ARC_TESTNET } from "./predictionPool";

export const publicClient = createPublicClient({
  chain: ARC_TESTNET,
  transport: http(),
});
