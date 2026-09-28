export const PREDICTION_POOL_ADDRESS =
  "0xac26f01427a4b9cc0f05a58760f0312694527134";

export const ARC_TESTNET = {
  id: 5042002,
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
} as const;

export const PREDICTION_POOL_ABI = [
  {
    name: "resolver",
    type: "function",
    stateMutability: "view",
    inputs: [],
    outputs: [{ type: "address" }],
  },

  {
    name: "usdc",
    type: "function",
    stateMutability: "view",
    inputs: [],
    outputs: [{ type: "address" }],
  },

  {
    name: "roundId",
    type: "function",
    stateMutability: "view",
    inputs: [],
    outputs: [{ type: "uint256" }],
  },

  {
    name: "createRound",
    type: "function",
    stateMutability: "nonpayable",
    inputs: [],
    outputs: [],
  },

  {
    name: "startRound",
    type: "function",
    stateMutability: "nonpayable",
    inputs: [
      { name: "_roundId", type: "uint256" },
      { name: "_referencePrice", type: "uint256" },
    ],
    outputs: [],
  },

  {
    name: "rounds",
    type: "function",
    stateMutability: "view",
    inputs: [{ name: "", type: "uint256" }],
    outputs: [
      { name: "id", type: "uint256" },
      { name: "startTime", type: "uint256" },
      { name: "endTime", type: "uint256" },
      { name: "referencePrice", type: "uint256" },
      { name: "settlementPrice", type: "uint256" },
      { name: "upPool", type: "uint256" },
      { name: "downPool", type: "uint256" },
      { name: "winner", type: "uint8" },
      { name: "resolved", type: "bool" },
      { name: "locked", type: "bool" },
    ],
  },

  {
    name: "bet",
    type: "function",
    stateMutability: "nonpayable",
    inputs: [
      { name: "_roundId", type: "uint256" },
      { name: "_direction", type: "uint8" },
      { name: "_amount", type: "uint256" },
    ],
    outputs: [],
  },
] as const;

export const USDC_ABI = [
  {
    name: "balanceOf",
    type: "function",
    stateMutability: "view",
    inputs: [{ name: "account", type: "address" }],
    outputs: [{ type: "uint256" }],
  },

  {
    name: "approve",
    type: "function",
    stateMutability: "nonpayable",
    inputs: [
      { name: "spender", type: "address" },
      { name: "amount", type: "uint256" },
    ],
    outputs: [{ type: "bool" }],
  },
] as const;

export const USDC_ADDRESS =
  "0x3600000000000000000000000000000000000000";
