"use client";

import { useEffect, useState } from "react";
import {
  PREDICTION_POOL_ABI,
  PREDICTION_POOL_ADDRESS,
  USDC_ADDRESS,
  USDC_ABI,
} from "@/lib/predictionPool";
import { publicClient } from "@/lib/publicClient";
import { getWalletClient } from "@/lib/walletClient";
import {
  useAppKit,
  useAppKitAccount,
  useAppKitNetwork,
  useAppKitProvider,
} from "@reown/appkit/react";
import { BrowserProvider, Contract } from "ethers";
import { arcTestnet } from "@/lib/reown";

export default function Home() {
  const [seconds, setSeconds] = useState<number | null>(null);
  const [btcPrice, setBtcPrice] = useState<number | null>(null);
  const [referencePrice, setReferencePrice] =
    useState<number | null>(null);
  const [marketStatus, setMarketStatus] = useState("WAITING");
  const [betAmount, setBetAmount] = useState<string | null>(null);
  const [roundId, setRoundId] = useState<bigint | null>(null);
  const [round, setRound] = useState<{
    id: bigint;
    startTime: bigint;
    endTime: bigint;
    referencePrice: bigint;
    settlementPrice: bigint;
    upPool: bigint;
    downPool: bigint;
    winner: number;
    resolved: boolean;
    locked: boolean;
  } | null>(null);
  const [resolver, setResolver] = useState<string | null>(null);
  const [account, setAccount] = useState<string | null>(null);
  const [usdcBalance, setUsdcBalance] = useState<bigint | null>(null);
  const { open } = useAppKit();
  const { address, isConnected } = useAppKitAccount();
  const { caipNetwork, chainId, switchNetwork } = useAppKitNetwork();
  const { walletProvider } = useAppKitProvider("eip155");
  const ethersProvider = walletProvider
    ? new BrowserProvider(walletProvider as any)
    : null;
  const isResolver =
    isConnected &&
    address &&
    resolver &&
    address.toLowerCase() === resolver.toLowerCase();

    function parseUsdcAmount(amount: string) {
    return BigInt(Number(amount) * 1_000_000);
  }

async function getSigner() {
  if (!ethersProvider) {
    throw new Error("Wallet not connected");
  }

  return await ethersProvider.getSigner();
}

async function getPredictionPoolContract() {
  const signer = await getSigner();

  return new Contract(
    PREDICTION_POOL_ADDRESS,
    PREDICTION_POOL_ABI,
    signer
  );
}

async function approveUsdc(amount: bigint) {
  const signer = await getSigner();

  const usdc = new Contract(
    USDC_ADDRESS,
    USDC_ABI,
    signer
  );

  const tx = await usdc.approve(
    PREDICTION_POOL_ADDRESS,
    amount
  );

  console.log("Approve transaction:", tx.hash);

  const receipt = await tx.wait();

  console.log("Approve confirmed:", receipt);
}

async function placeBet(direction: number) {
  if (betAmount === null) {
    alert("Please select a bet amount first");
    return;
  }

  if (roundId === null) {
    throw new Error("Round ID not loaded");
  }

  const amount = parseUsdcAmount(betAmount);

  console.log("Bet amount:", amount.toString());
  console.log("Direction:", direction);

  await approveUsdc(amount);

  const contract = await getPredictionPoolContract();

  const tx = await contract.bet(
    roundId,
    direction,
    amount
  );

  console.log("Bet transaction:", tx.hash);

  const receipt = await tx.wait();

  console.log("Bet confirmed:", receipt);
}

async function createRound() {
  if (!isResolver) {
    throw new Error("Only resolver can create a round");
  }

  const contract = await getPredictionPoolContract();

  const tx = await contract.createRound();

  console.log("Create round transaction:", tx.hash);

  const receipt = await tx.wait();

  console.log("Create round confirmed:", receipt);

  await loadRoundId();
}

async function startRound() {
  if (!isResolver) {
    throw new Error("Only resolver can start a round");
  }

  if (roundId === null) {
    throw new Error("Round ID not loaded");
  }

  if (btcPrice === null) {
    throw new Error("BTC price not available");
  }

  const contract = await getPredictionPoolContract();

  const referencePrice = Math.round(btcPrice * 100);

  const tx = await contract.startRound(
    roundId,
    referencePrice
  );

  console.log("Start round transaction:", tx.hash);

  const receipt = await tx.wait();

  console.log("Start round confirmed:", receipt);

  await loadRound();
}

async function switchToArc() {
  try {
    await switchNetwork(arcTestnet);
  } catch (error) {
    console.error("Failed to switch to Arc Testnet:", error);
  }
}

      useEffect(() => {
         if (isConnected && chainId !== 5042002) {
         switchToArc();
          }
         }, [isConnected, chainId]);

      async function connectWallet() {
       await open();
    }

async function loadUsdcBalance(address: string) {
  const result = await publicClient.readContract({
    address: "0x3600000000000000000000000000000000000000",
    abi: USDC_ABI,
    functionName: "balanceOf",
    args: [address as `0x${string}`],
  });

  setUsdcBalance(result);
}

  useEffect(() => {
    const ws = new WebSocket(
    "wss://stream.binance.com:9443/ws/btcusdt@aggTrade"
     );

     ws.onmessage = (event) => {
     const data = JSON.parse(event.data);
    setBtcPrice(Number(data.p));
     };

    return () => ws.close();
    }, []);

  useEffect(() => {
    if (round === null || round.endTime === BigInt(0)) {
      setSeconds(null);
    return;
     }

    const updateCountdown = () => {
      const now = Math.floor(Date.now() / 1000);
      const end = Number(round.endTime);

      const remaining = Math.max(0, end - now);

      setSeconds(remaining);
    };

    updateCountdown();

    const timer = setInterval(updateCountdown, 1000);

    return () => clearInterval(timer);
  }, [round]);

  async function loadRoundId() {
    const result = await publicClient.readContract({
      address: PREDICTION_POOL_ADDRESS,
      abi: PREDICTION_POOL_ABI,
      functionName: "roundId",
    });

    setRoundId(result);
  }

  useEffect(() => {
    loadRoundId();

    if (address) {
      loadUsdcBalance(address);
    }
  }, [address]);

async function loadRound() {
  if (roundId === null) return;

  const result = await publicClient.readContract({
    address: PREDICTION_POOL_ADDRESS,
    abi: PREDICTION_POOL_ABI,
    functionName: "rounds",
    args: [roundId],
  });

  console.log("Round data:", result);

  setRound({
    id: result[0],
    startTime: result[1],
    endTime: result[2],
    referencePrice: result[3],
    settlementPrice: result[4],
    upPool: result[5],
    downPool: result[6],
    winner: result[7],
    resolved: result[8],
    locked: result[9],
  });
}

useEffect(() => {
  loadRound();
}, [roundId]);

  useEffect(() => {
    if (round === null) return;

    if (round.id === BigInt(0)) {
      setMarketStatus("WAITING");
      return;
      }

    if (round.resolved) {
      setMarketStatus("RESOLVED");
      return;
      }

    if (round.locked) {
      setMarketStatus("LOCKED");
      return;
      }

    if (round.startTime > BigInt(0)) {
      setMarketStatus("LIVE");
      return;
      }

      setMarketStatus("WAITING");
  }, [round]);

  useEffect(() => {
   async function loadResolver() {
    const result = await publicClient.readContract({
      address: PREDICTION_POOL_ADDRESS,
      abi: PREDICTION_POOL_ABI,
      functionName: "resolver",
      });

    setResolver(result);
      }

    loadResolver();
      }, []);

  return (
    <main className="min-h-screen bg-black text-white">
      <div className="mx-auto flex min-h-screen max-w-5xl flex-col px-6 py-6">
        {/* Header */}
        <header className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold tracking-tight">ARC 60</h1>
            <p className="text-sm text-zinc-500">
              60-second prediction market
            </p>
          </div>

        <button
         onClick={connectWallet}
         className="rounded-xl border border-zinc-700 px-4 py-2 text-sm font-medium hover:bg-zinc-900"
        >

         {isConnected && address ? (
        <div className="text-right">
        <div className="font-medium">
         {address.slice(0, 6)}...{address.slice(-4)}
        </div>

        <div className="text-xs text-zinc-500">
           {usdcBalance !== null
             ? `${(Number(usdcBalance) / 1_000_000).toFixed(2)} USDC`
             : "Loading..."}
        </div>

        <div className="text-xs text-gray-400">
          {isResolver ? "Resolver" : "Player"}
        </div>

      </div>

    ) : (
      "Connect Wallet"
    )}
        </button>

        </header>

        {/* Market */}
        <section className="mt-10 rounded-3xl border border-zinc-800 bg-zinc-950 p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-zinc-500">Market</p>
              <h2 className="mt-1 text-2xl font-semibold">BTC / USDC</h2>
            </div>
          <div className="flex items-center gap-2">
            <div className="rounded-full border border-zinc-800 px-3 py-1 text-xs text-zinc-400">
            TESTNET
            </div>

         <div className="rounded-full border border-zinc-800 px-3 py-1 text-xs text-zinc-400">
            ● {marketStatus}
           </div>
           </div>
          </div>

          {/* Price */}
          <div className="mt-10 text-center">
            <p className="text-sm text-zinc-500">Reference Price</p>
            <p className="mt-2 text-5xl font-bold tracking-tight">
              {btcPrice !== null
             ? `$${btcPrice.toLocaleString("en-US", {
              minimumFractionDigits: 2,
               maximumFractionDigits: 2,
             })}`
             : "Loading..."}
            </p>

            <p className="mt-2 text-sm text-zinc-600">
              ● Live via Binance
           </p>

            <p className="mt-2 text-xs text-zinc-600">
               Contract Round: {roundId !== null ? roundId.toString() : "Loading..."}
           </p>

            <p className="text-xs text-zinc-600">
               Resolver: {resolver ?? "Loading..."}
           </p>
          </div>

          {/* Countdown */}
          <div className="mt-10 text-center">
            <p className="text-sm text-zinc-500">Round ends in</p>
            <p className="mt-2 font-mono text-4xl font-bold">
              {seconds !== null
                ? `00:${seconds.toString().padStart(2, "0")}`
                : "--:--"}
           </p>
          </div>

          {isResolver && (
            <button
              onClick={createRound}
              className="rounded-lg bg-white px-4 py-2 text-sm font-medium text-black"
            >
              Create Round
            </button>
          )}

          {isResolver && roundId !== null && round?.startTime === BigInt(0) && (
            <button
              onClick={startRound}
              className="rounded-lg bg-white px-4 py-2 text-sm font-medium text-black"
            >
              Start Round
            </button>
          )}

<div className="mt-4">
  <div className="mb-2 text-sm text-gray-400">
    Bet Amount
  </div>

  <div className="flex gap-2">
    {["1", "5", "10", "20"].map((amount) => (
      <button
        key={amount}
        onClick={() => setBetAmount(amount)}
        className={`rounded-lg px-4 py-2 text-sm font-medium ${
          betAmount === amount
            ? "bg-white text-black"
            : "bg-white/10 text-white"
        }`}
      >
        {amount} USDC
      </button>
    ))}
  </div>
</div>

          {/* Direction */}
          <div className="mt-10 grid grid-cols-2 gap-4">
<button
  onClick={() => {
    placeBet(1);
  }}
  className="rounded-2xl border border-zinc-800 bg-zinc-900 px-6 py-5 text-lg font-semibold transition hover:bg-zinc-800"
>
  UP ↑
</button>

<button
  onClick={() => {
    placeBet(2);
  }}
  className="rounded-2xl border border-zinc-800 bg-zinc-900 px-6 py-5 text-lg font-semibold transition hover:bg-zinc-800"
>
  DOWN ↓
</button>
          </div>

          {/* Pool */}
          <div className="mt-8 grid grid-cols-2 gap-4 text-center">
            <div className="rounded-2xl bg-zinc-900 p-4">
              <p className="text-xs text-zinc-500">UP Pool</p>
              <p className="mt-1 font-semibold">
                {round !== null
                  ? `${(Number(round.upPool) / 1_000_000).toFixed(2)} USDC`
                  : "Loading..."}
              </p>
            </div>

            <div className="rounded-2xl bg-zinc-900 p-4">
              <p className="text-xs text-zinc-500">DOWN Pool</p>
              <p className="mt-1 font-semibold">
                {round !== null
                  ? `${(Number(round.upPool) / 1_000_000).toFixed(2)} USDC`
                  : "Loading..."}
              </p>
            </div>
          </div>
        </section>

        {/* Footer */}
        <footer className="mt-auto pt-8 text-center text-xs text-zinc-600">
          Built on Arc • Testnet
        </footer>
      </div>
    </main>
  );
}
