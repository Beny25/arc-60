"use client";

import { AppKitProvider as ReownAppKitProvider } from "@reown/appkit/react";
import { ReactNode } from "react";
import { arcTestnet, ethersAdapter } from "@/lib/reown";

export default function AppKitProvider({
  children,
}: {
  children: ReactNode;
}) {
  return (
    <ReownAppKitProvider
      adapters={[ethersAdapter]}
      networks={[arcTestnet]}
      projectId={process.env.NEXT_PUBLIC_REOWN_PROJECT_ID!}
      metadata={{
        name: "ARC 60",
        description: "60-second prediction market on Arc",
        url: "http://localhost:3000",
        icons: [],
      }}
    >
      {children}
    </ReownAppKitProvider>
  );
}
