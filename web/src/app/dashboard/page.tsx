"use client";

import { useEffect, useState } from "react";

interface VersionInfo {
  version: string;
  build: number;
  updatedAt: string;
  changelog: string;
}

interface ConfigData {
  version: VersionInfo;
  theme: Record<string, unknown>;
  categories: { categories: Array<{ key: string; label: string; icon: string }> };
  strings: Record<string, unknown>;
  features: Record<string, boolean | number>;
}

export default function Dashboard() {
  const [config, setConfig] = useState<ConfigData | null>(null);
  const [fileCount, setFileCount] = useState(0);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    Promise.all([
      fetch("/api/config").then((r) => r.json()),
      fetch("/api/files").then((r) => r.json()),
    ]).then(([cfg, files]) => {
      setConfig(cfg);
      setFileCount(files.files?.length || 0);
      setLoading(false);
    });
  }, []);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-screen">
        <div className="w-8 h-8 border-2 border-fullio-dark border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  if (!config) return null;

  const featureCount = Object.values(config.features).filter(
    (v) => v === true
  ).length;
  const totalFeatures = Object.values(config.features).filter(
    (v) => typeof v === "boolean"
  ).length;

  return (
    <div className="p-8 max-w-6xl">
      <header className="mb-8">
        <h1 className="text-3xl font-bold text-fullio-black">Dashboard</h1>
        <p className="text-fullio-secondary-text mt-1">
          Panoramica della configurazione remota di Fullio
        </p>
      </header>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
        <StatCard
          label="Versione"
          value={config.version.version}
          sub={`Build ${config.version.build}`}
          color="bg-fullio-dark"
        />
        <StatCard
          label="Categorie"
          value={String(config.categories.categories.length)}
          sub="categorie transazione"
          color="bg-fullio-green"
        />
        <StatCard
          label="Feature Attive"
          value={`${featureCount}/${totalFeatures}`}
          sub="feature flags"
          color="bg-amber-500"
        />
        <StatCard
          label="File Swift"
          value={String(fileCount)}
          sub="file nel progetto"
          color="bg-indigo-500"
        />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="card">
          <h2 className="text-lg font-bold mb-4">Informazioni Versione</h2>
          <div className="space-y-3">
            <InfoRow label="Versione" value={config.version.version} />
            <InfoRow label="Build" value={String(config.version.build)} />
            <InfoRow
              label="Ultimo aggiornamento"
              value={new Date(config.version.updatedAt).toLocaleString("it-IT")}
            />
            <InfoRow label="Changelog" value={config.version.changelog} />
          </div>
        </div>

        <div className="card">
          <h2 className="text-lg font-bold mb-4">Colori Tema</h2>
          <div className="grid grid-cols-2 gap-2">
            {Object.entries(
              (config.theme as { colors: Record<string, string> }).colors
            ).map(([name, hex]) => (
              <div key={name} className="flex items-center gap-2 py-1">
                <div
                  className="w-6 h-6 rounded-lg border border-black/10 flex-shrink-0"
                  style={{ backgroundColor: hex }}
                />
                <span className="text-xs text-fullio-secondary-text truncate">
                  {name}
                </span>
                <span className="text-[10px] font-mono text-fullio-neutral ml-auto">
                  {hex}
                </span>
              </div>
            ))}
          </div>
        </div>

        <div className="card">
          <h2 className="text-lg font-bold mb-4">Categorie</h2>
          <div className="flex flex-wrap gap-2">
            {config.categories.categories.map((cat) => (
              <span
                key={cat.key}
                className="inline-flex items-center gap-1.5 px-3 py-1.5 bg-fullio-light-green rounded-full text-xs font-medium text-fullio-dark"
              >
                {cat.label}
              </span>
            ))}
          </div>
        </div>

        <div className="card">
          <h2 className="text-lg font-bold mb-4">Feature Flags</h2>
          <div className="space-y-2">
            {Object.entries(config.features).map(([key, value]) =>
              typeof value === "boolean" ? (
                <div key={key} className="flex items-center justify-between py-1">
                  <span className="text-sm text-fullio-black">{key}</span>
                  <span
                    className={`text-xs font-medium px-2 py-0.5 rounded-full ${
                      value
                        ? "bg-fullio-light-green text-fullio-dark"
                        : "bg-fullio-light-warning text-fullio-warning"
                    }`}
                  >
                    {value ? "ON" : "OFF"}
                  </span>
                </div>
              ) : null
            )}
          </div>
        </div>
      </div>

      <div className="mt-8 card">
        <h2 className="text-lg font-bold mb-4">API Endpoints</h2>
        <div className="space-y-3">
          <EndpointRow method="GET" path="/api/version" desc="Versione corrente della configurazione" />
          <EndpointRow method="GET" path="/api/config" desc="Configurazione completa (tutte le sezioni)" />
          <EndpointRow method="GET" path="/api/config/[section]" desc="Sezione specifica (theme, categories, strings, features)" />
          <EndpointRow method="PUT" path="/api/config/[section]" desc="Aggiorna una sezione (auto-bump versione)" />
          <EndpointRow method="GET" path="/api/files" desc="Lista di tutti i file Swift" />
          <EndpointRow method="GET" path="/api/files/[...path]" desc="Contenuto di un file Swift" />
          <EndpointRow method="PUT" path="/api/files/[...path]" desc="Modifica un file Swift" />
        </div>
      </div>
    </div>
  );
}

function StatCard({
  label,
  value,
  sub,
  color,
}: {
  label: string;
  value: string;
  sub: string;
  color: string;
}) {
  return (
    <div className="card flex items-start gap-4">
      <div className={`w-12 h-12 ${color} rounded-xl flex items-center justify-center flex-shrink-0`}>
        <span className="text-white font-bold text-lg">{value.charAt(0)}</span>
      </div>
      <div>
        <p className="text-xs text-fullio-secondary-text">{label}</p>
        <p className="text-xl font-bold text-fullio-black">{value}</p>
        <p className="text-[11px] text-fullio-neutral">{sub}</p>
      </div>
    </div>
  );
}

function InfoRow({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex justify-between items-center py-1 border-b border-black/5 last:border-0">
      <span className="text-sm text-fullio-secondary-text">{label}</span>
      <span className="text-sm font-medium text-fullio-black">{value}</span>
    </div>
  );
}

function EndpointRow({
  method,
  path,
  desc,
}: {
  method: string;
  path: string;
  desc: string;
}) {
  const colors: Record<string, string> = {
    GET: "bg-fullio-light-green text-fullio-dark",
    PUT: "bg-amber-50 text-amber-600",
    POST: "bg-blue-50 text-blue-600",
  };

  return (
    <div className="flex items-center gap-3 py-2 border-b border-black/5 last:border-0">
      <span className={`text-[10px] font-bold px-2 py-0.5 rounded ${colors[method]}`}>
        {method}
      </span>
      <code className="text-sm font-mono text-fullio-black flex-1">{path}</code>
      <span className="text-xs text-fullio-secondary-text hidden md:block">{desc}</span>
    </div>
  );
}
