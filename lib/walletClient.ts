import { createWalletClient, custom } from "viem";
import { ARC_TESTNET } from "./predictionPool";

export function getWalletClient() {
  if (!window.ethereum) {
    throw new Error("Wallet not found");
  }

  return createWalletClient({
    chain: ARC_TESTNET,
    transport: custom(
      window.ethereum as {
        request: (args: {
          method: string;
          params?: unknown[];
        }) => Promise<unknown>;
      }
    ),
  });
}
