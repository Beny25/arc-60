import { EthersAdapter } from "@reown/appkit-adapter-ethers";

const projectId = process.env.NEXT_PUBLIC_REOWN_PROJECT_ID;

export const arcTestnet = {
  id: 5042002,
  caipNetworkId: "eip155:5042002",
  chainNamespace: "eip155",
  name: "Arc Testnet",
  nativeCurrency: {
    name: "USDC",
    symbol: "USDC",
    decimals: 6,
  },
  rpcUrls: {
    default: {
      http: ["https://rpc.testnet.arc.network/"],
    },
  },
  blockExplorers: {
    default: {
      name: "Arc Explorer",
      url: "https://testnet.arc-scan.org/",
    },
  },
};

export const ethersAdapter = new EthersAdapter();
