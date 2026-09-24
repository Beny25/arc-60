"use client";

import { useEffect, useState } from "react";
import {
  PREDICTION_POOL_ABI,
  PREDICTION_POOL_ADDRESS,
  USDC_ABI,
} from "@/lib/predictionPool";
import { publicClient } from "@/lib/publicClient";
import { getWalletClient } from "@/lib/walletClient";
import { useAppKit, useAppKitAccount, useAppKitNetwork } from "@reown/appkit/react";
import { arcTestnet } from "@/lib/reown";

export default function Home() {
  const [seconds, setSeconds] = useState(60);
  const [btcPrice, setBtcPrice] = useState<number | null>(null);
  const [referencePrice, setReferencePrice] =
    useState<number | null>(null);
  const [marketStatus, setMarketStatus] = useState("LIVE");
  const [roundId, setRoundId] = useState<bigint | null>(null);
  const [resolver, setResolver] = useState<string | null>(null); 
  const [account, setAccount] = useState<string | null>(null);
  const [usdcBalance, setUsdcBalance] = useState<bigint | null>(null);
  const { open } = useAppKit();
  const { address, isConnected } = useAppKitAccount();
  const { caipNetwork, chainId, switchNetwork } = useAppKitNetwork();

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

async function loadUsdcBalance(address: `0x${string}`) {
  const result = await publicClient.readContract({
    address: "0x3600000000000000000000000000000000000000",
    abi: USDC_ABI,
    functionName: "balanceOf",
    args: [address],
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
    const timer = setInterval(() => {
     setSeconds((current) => {
      if (current <= 1) {
         return 60;
       }

       return current - 1;
       });
       }, 1000);

    return () => clearInterval(timer);
      }, []);

  useEffect(() => {
   async function loadRoundId() {
    const result = await publicClient.readContract({
      address: PREDICTION_POOL_ADDRESS,
      abi: PREDICTION_POOL_ABI,
      functionName: "roundId",
      });

    setRoundId(result);
      }

    loadRoundId();
      }, []);

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
               00:{seconds.toString().padStart(2, "0")}
           </p>  
          </div>

          {/* Direction */}
          <div className="mt-10 grid grid-cols-2 gap-4">
            <button className="rounded-2xl border border-zinc-800 bg-zinc-900 px-6 py-5 text-lg font-semibold transition hover:bg-zinc-800">
              UP ↑
            </button>

            <button className="rounded-2xl border border-zinc-800 bg-zinc-900 px-6 py-5 text-lg font-semibold transition hover:bg-zinc-800">
              DOWN ↓
            </button>
          </div>

          {/* Pool */}
          <div className="mt-8 grid grid-cols-2 gap-4 text-center">
            <div className="rounded-2xl bg-zinc-900 p-4">
              <p className="text-xs text-zinc-500">UP Pool</p>
              <p className="mt-1 font-semibold">— USDC</p>
            </div>

            <div className="rounded-2xl bg-zinc-900 p-4">
              <p className="text-xs text-zinc-500">DOWN Pool</p>
              <p className="mt-1 font-semibold">— USDC</p>
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
