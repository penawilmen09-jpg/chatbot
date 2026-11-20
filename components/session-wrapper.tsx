"use client";

import { SessionProvider } from "next-auth/react";

// Solo las pantallas de chat e inicio de sesión necesitan la sesión de Auth.js.
// El generador de WILMEN AI (página principal) no la usa.
export function AuthSessionProvider({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <SessionProvider
      basePath={`${process.env.NEXT_PUBLIC_BASE_PATH ?? ""}/api/auth`}
    >
      {children}
    </SessionProvider>
  );
}
