"use client";

import { useEffect, useState, useCallback } from "react";

type Section = "theme" | "categories" | "strings" | "features";

const SECTIONS: { key: Section; label: string; desc: string }[] = [
  { key: "theme", label: "Tema", desc: "Colori, font, spacing e raggi" },
  { key: "categories", label: "Categorie", desc: "Categorie delle transazioni" },
  { key: "strings", label: "Stringhe", desc: "Messaggi, saluti e testi UI" },
  { key: "features", label: "Feature Flags", desc: "Abilita/disabilita funzionalità" },
];

export default function ConfigPage() {
  const [activeSection, setActiveSection] = useState<Section>("theme");
  const [configData, setConfigData] = useState<Record<string, unknown>>({});
  const [editedJson, setEditedJson] = useState("");
  const [saving, setSaving] = useState(false);
  const [saveStatus, setSaveStatus] = useState<"idle" | "success" | "error">("idle");
  const [version, setVersion] = useState("");

  const loadSection = useCallback(async (section: Section) => {
    try {
      const res = await fetch(`/api/config/${section}`);
      const data = await res.json();
      setConfigData((prev) => ({ ...prev, [section]: data }));
      setEditedJson(JSON.stringify(data, null, 2));
    } catch {
      setEditedJson("// Errore nel caricamento");
    }
  }, []);

  useEffect(() => {
    loadSection(activeSection);
    fetch("/api/version")
      .then((r) => r.json())
      .then((v) => setVersion(v.version));
  }, [activeSection, loadSection]);

  const handleSave = async () => {
    setSaving(true);
    setSaveStatus("idle");
    try {
      const parsed = JSON.parse(editedJson);
      const res = await fetch(`/api/config/${activeSection}`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(parsed),
      });
      const result = await res.json();
      if (result.success) {
        setSaveStatus("success");
        setVersion(result.newVersion);
        setConfigData((prev) => ({ ...prev, [activeSection]: parsed }));
        setTimeout(() => setSaveStatus("idle"), 3000);
      } else {
        setSaveStatus("error");
      }
    } catch {
      setSaveStatus("error");
    }
    setSaving(false);
  };

  const handleReset = () => {
    const current = configData[activeSection];
    if (current) {
      setEditedJson(JSON.stringify(current, null, 2));
    }
  };

  return (
    <div className="p-8 max-w-6xl">
      <header className="mb-8 flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-fullio-black">Configurazione</h1>
          <p className="text-fullio-secondary-text mt-1">
            Modifica la configurazione remota dell&apos;app
          </p>
        </div>
        {version && (
          <div className="px-4 py-2 bg-fullio-light-green rounded-xl">
            <span className="text-xs text-fullio-secondary-text">Versione</span>
            <p className="text-sm font-bold text-fullio-dark">{version}</p>
          </div>
        )}
      </header>

      <div className="flex gap-2 mb-6 overflow-x-auto pb-2">
        {SECTIONS.map((s) => (
          <button
            key={s.key}
            onClick={() => setActiveSection(s.key)}
            className={`px-5 py-2.5 rounded-xl text-sm font-medium whitespace-nowrap transition-all ${
              activeSection === s.key
                ? "bg-fullio-dark text-white"
                : "bg-white text-fullio-black hover:bg-fullio-light-green"
            }`}
          >
            {s.label}
          </button>
        ))}
      </div>

      <div className="card mb-4">
        <div className="flex items-center justify-between mb-4">
          <div>
            <h2 className="text-lg font-bold">
              {SECTIONS.find((s) => s.key === activeSection)?.label}
            </h2>
            <p className="text-xs text-fullio-secondary-text">
              {SECTIONS.find((s) => s.key === activeSection)?.desc}
            </p>
          </div>
          <div className="flex items-center gap-2">
            <button
              onClick={handleReset}
              className="px-4 py-2 text-sm rounded-xl bg-gray-100 hover:bg-gray-200 transition-colors"
            >
              Reset
            </button>
            <button
              onClick={handleSave}
              disabled={saving}
              className="btn-primary !py-2 !px-5 text-sm disabled:opacity-50"
            >
              {saving ? "Salvando..." : "Salva & Pubblica"}
            </button>
          </div>
        </div>

        {saveStatus === "success" && (
          <div className="mb-4 px-4 py-3 bg-fullio-light-green rounded-xl text-sm text-fullio-dark font-medium">
            Configurazione salvata! Nuova versione: {version}
          </div>
        )}
        {saveStatus === "error" && (
          <div className="mb-4 px-4 py-3 bg-fullio-light-warning rounded-xl text-sm text-fullio-warning font-medium">
            Errore nel salvataggio. Controlla il formato JSON.
          </div>
        )}

        <textarea
          value={editedJson}
          onChange={(e) => setEditedJson(e.target.value)}
          className="code-editor w-full h-[500px] p-4 bg-fullio-black text-fullio-beige rounded-xl text-sm leading-relaxed resize-none"
          spellCheck={false}
        />
      </div>

      {activeSection === "theme" && configData.theme ? (
        <ThemePreview data={configData.theme as Record<string, unknown>} />
      ) : null}

      {activeSection === "features" && configData.features ? (
        <FeatureToggles
          data={configData.features as Record<string, boolean | number>}
          onToggle={(key) => {
            const updated = {
              ...(configData.features as Record<string, boolean | number>),
            };
            if (typeof updated[key] === "boolean") {
              updated[key] = !updated[key];
              setConfigData((prev) => ({ ...prev, features: updated }));
              setEditedJson(JSON.stringify(updated, null, 2));
            }
          }}
        />
      ) : null}
    </div>
  );
}

function ThemePreview({ data }: { data: Record<string, unknown> }) {
  const colors = (data.colors || {}) as Record<string, string>;
  return (
    <div className="card">
      <h3 className="text-lg font-bold mb-4">Anteprima Colori</h3>
      <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
        {Object.entries(colors).map(([name, hex]) => (
          <div key={name} className="text-center">
            <div
              className="w-full h-16 rounded-xl border border-black/10 mb-2"
              style={{ backgroundColor: hex }}
            />
            <p className="text-xs font-medium text-fullio-black">{name}</p>
            <p className="text-[10px] font-mono text-fullio-neutral">{hex}</p>
          </div>
        ))}
      </div>
    </div>
  );
}

function FeatureToggles({
  data,
  onToggle,
}: {
  data: Record<string, boolean | number>;
  onToggle: (key: string) => void;
}) {
  return (
    <div className="card">
      <h3 className="text-lg font-bold mb-4">Toggle Rapido</h3>
      <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
        {Object.entries(data).map(([key, value]) =>
          typeof value === "boolean" ? (
            <button
              key={key}
              onClick={() => onToggle(key)}
              className="flex items-center justify-between p-4 rounded-xl border border-black/5 hover:bg-fullio-light-beige transition-colors"
            >
              <span className="text-sm font-medium">{key}</span>
              <div
                className={`w-12 h-6 rounded-full relative transition-colors ${
                  value ? "bg-fullio-green" : "bg-fullio-neutral/30"
                }`}
              >
                <div
                  className={`absolute top-1 w-4 h-4 rounded-full bg-white shadow transition-transform ${
                    value ? "translate-x-7" : "translate-x-1"
                  }`}
                />
              </div>
            </button>
          ) : (
            <div
              key={key}
              className="flex items-center justify-between p-4 rounded-xl border border-black/5"
            >
              <span className="text-sm font-medium">{key}</span>
              <span className="text-sm font-mono text-fullio-secondary-text">
                {value}
              </span>
            </div>
          )
        )}
      </div>
    </div>
  );
}
