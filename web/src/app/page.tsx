"use client";

import { useEffect, useState } from "react";
import Link from "next/link";

interface VersionInfo {
  version: string;
  build: number;
  updatedAt: string;
  changelog: string;
}

type Status = "loading" | "ok" | "error";

export default function HomePage() {
  const [status, setStatus] = useState<Status>("loading");
  const [version, setVersion] = useState<VersionInfo | null>(null);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  useEffect(() => {
    fetch("/api/version")
      .then((r) => {
        if (!r.ok) throw new Error(`HTTP ${r.status}`);
        return r.json();
      })
      .then((data: VersionInfo) => {
        if (!data?.version) throw new Error("Risposta non valida");
        setVersion(data);
        setStatus("ok");
      })
      .catch((e) => {
        setErrorMessage(e instanceof Error ? e.message : "Errore sconosciuto");
        setStatus("error");
      });
  }, []);

  return (
    <div className="min-h-[calc(100vh-2rem)] flex flex-col items-center justify-center p-8">
      <div className="max-w-lg w-full text-center">
        <div className="inline-flex items-center justify-center w-20 h-20 rounded-2xl bg-fullio-dark text-white text-3xl font-bold mb-6 shadow-lg shadow-fullio-dark/20">
          F
        </div>

        <h1 className="text-3xl font-bold text-fullio-black tracking-tight">
          Fullio Config Server
        </h1>
        <p className="text-fullio-secondary-text mt-2 text-sm">
          Configurazione remota per l&apos;app iOS Fullio
        </p>

        <div className="mt-10 card text-left">
          {status === "loading" && (
            <div className="flex items-center gap-4 py-2">
              <div className="w-10 h-10 rounded-full border-2 border-fullio-green border-t-fullio-dark animate-spin flex-shrink-0" />
              <div>
                <p className="font-semibold text-fullio-black">Verifica in corso…</p>
                <p className="text-sm text-fullio-secondary-text">
                  Controllo API e versione configurazione
                </p>
              </div>
            </div>
          )}

          {status === "ok" && version && (
            <div className="space-y-4">
              <div className="flex items-start gap-4">
                <div className="w-12 h-12 rounded-xl bg-fullio-light-green flex items-center justify-center flex-shrink-0">
                  <svg
                    className="w-7 h-7 text-fullio-dark"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                    strokeWidth={2.5}
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      d="M5 13l4 4L19 7"
                    />
                  </svg>
                </div>
                <div>
                  <p className="text-lg font-bold text-fullio-dark">
                    Tutto funziona
                  </p>
                  <p className="text-sm text-fullio-secondary-text mt-0.5">
                    Il server risponde correttamente. L&apos;app può usare{" "}
                    <code className="text-xs bg-fullio-light-beige px-1.5 py-0.5 rounded">
                      /api/version
                    </code>{" "}
                    e{" "}
                    <code className="text-xs bg-fullio-light-beige px-1.5 py-0.5 rounded">
                      /api/config
                    </code>
                    .
                  </p>
                </div>
              </div>

              <div className="pt-4 border-t border-black/5 grid grid-cols-2 gap-3 text-sm">
                <div>
                  <p className="text-fullio-secondary-text text-xs">Versione config</p>
                  <p className="font-semibold text-fullio-black">{version.version}</p>
                </div>
                <div>
                  <p className="text-fullio-secondary-text text-xs">Build</p>
                  <p className="font-semibold text-fullio-black">{version.build}</p>
                </div>
              </div>
            </div>
          )}

          {status === "error" && (
            <div className="flex items-start gap-4">
              <div className="w-12 h-12 rounded-xl bg-fullio-light-warning flex items-center justify-center flex-shrink-0">
                <svg
                  className="w-7 h-7 text-fullio-warning"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                  strokeWidth={2}
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
                  />
                </svg>
              </div>
              <div>
                <p className="text-lg font-bold text-fullio-warning">
                  Qualcosa non va
                </p>
                <p className="text-sm text-fullio-secondary-text mt-1">
                  {errorMessage ?? "Impossibile contattare /api/version"}
                </p>
              </div>
            </div>
          )}
        </div>

        <div className="mt-8 flex flex-col sm:flex-row gap-3 justify-center">
          <Link href="/dashboard" className="btn-primary text-center">
            Apri dashboard
          </Link>
          <Link href="/config" className="btn-secondary text-center">
            Configurazione
          </Link>
          <Link
            href="/files"
            className="px-6 py-3 rounded-xl font-semibold border border-fullio-neutral/30 text-fullio-black hover:bg-white/80 transition-colors text-center"
          >
            File Swift
          </Link>
        </div>
      </div>
    </div>
  );
}
