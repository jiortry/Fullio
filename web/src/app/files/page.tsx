"use client";

import { useEffect, useState, useCallback } from "react";

interface TreeNode {
  name: string;
  path: string;
  type: "file" | "folder";
  children?: TreeNode[];
}

interface FileContent {
  path: string;
  content: string;
  lines: number;
}

export default function FilesPage() {
  const [tree, setTree] = useState<TreeNode[]>([]);
  const [selectedFile, setSelectedFile] = useState<FileContent | null>(null);
  const [editedContent, setEditedContent] = useState("");
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [saveStatus, setSaveStatus] = useState<"idle" | "success" | "error">("idle");
  const [expandedFolders, setExpandedFolders] = useState<Set<string>>(new Set());
  const [isEditing, setIsEditing] = useState(false);

  useEffect(() => {
    fetch("/api/files")
      .then((r) => r.json())
      .then((data) => {
        setTree(data.tree || []);
        const allFolders = new Set<string>();
        function collectFolders(nodes: TreeNode[]) {
          for (const n of nodes) {
            if (n.type === "folder") {
              allFolders.add(n.path);
              if (n.children) collectFolders(n.children);
            }
          }
        }
        collectFolders(data.tree || []);
        setExpandedFolders(allFolders);
        setLoading(false);
      });
  }, []);

  const loadFile = useCallback(async (filePath: string) => {
    try {
      const res = await fetch(`/api/files/${filePath}`);
      const data = await res.json();
      setSelectedFile(data);
      setEditedContent(data.content);
      setIsEditing(false);
      setSaveStatus("idle");
    } catch {
      setSelectedFile(null);
    }
  }, []);

  const handleSave = async () => {
    if (!selectedFile) return;
    setSaving(true);
    try {
      const res = await fetch(`/api/files/${selectedFile.path}`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ content: editedContent }),
      });
      const result = await res.json();
      if (result.success) {
        setSaveStatus("success");
        setSelectedFile({ ...selectedFile, content: editedContent });
        setIsEditing(false);
        setTimeout(() => setSaveStatus("idle"), 3000);
      } else {
        setSaveStatus("error");
      }
    } catch {
      setSaveStatus("error");
    }
    setSaving(false);
  };

  const toggleFolder = (path: string) => {
    setExpandedFolders((prev) => {
      const next = new Set(prev);
      if (next.has(path)) next.delete(path);
      else next.add(path);
      return next;
    });
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-screen">
        <div className="w-8 h-8 border-2 border-fullio-dark border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  return (
    <div className="p-8 max-w-7xl">
      <header className="mb-8">
        <h1 className="text-3xl font-bold text-fullio-black">File Swift</h1>
        <p className="text-fullio-secondary-text mt-1">
          Visualizza e modifica i file sorgente dell&apos;app direttamente dal browser
        </p>
      </header>

      <div className="flex gap-6 h-[calc(100vh-200px)]">
        <div className="w-72 flex-shrink-0 card !p-3 overflow-y-auto">
          <p className="text-xs font-bold text-fullio-secondary-text uppercase tracking-wide px-2 py-2">
            Fullio/
          </p>
          {tree.map((node) => (
            <FileTreeNode
              key={node.path}
              node={node}
              depth={0}
              selectedPath={selectedFile?.path}
              expandedFolders={expandedFolders}
              onSelect={loadFile}
              onToggle={toggleFolder}
            />
          ))}
        </div>

        <div className="flex-1 card !p-0 overflow-hidden flex flex-col">
          {selectedFile ? (
            <>
              <div className="px-5 py-3 border-b border-black/5 flex items-center justify-between bg-white">
                <div>
                  <p className="text-sm font-bold text-fullio-black">
                    {selectedFile.path}
                  </p>
                  <p className="text-[11px] text-fullio-secondary-text">
                    {selectedFile.lines} righe
                  </p>
                </div>
                <div className="flex items-center gap-2">
                  {saveStatus === "success" && (
                    <span className="text-xs text-fullio-green font-medium">
                      Salvato!
                    </span>
                  )}
                  {saveStatus === "error" && (
                    <span className="text-xs text-fullio-warning font-medium">
                      Errore
                    </span>
                  )}
                  {isEditing ? (
                    <>
                      <button
                        onClick={() => {
                          setEditedContent(selectedFile.content);
                          setIsEditing(false);
                        }}
                        className="px-3 py-1.5 text-xs rounded-lg bg-gray-100 hover:bg-gray-200 transition-colors"
                      >
                        Annulla
                      </button>
                      <button
                        onClick={handleSave}
                        disabled={saving}
                        className="btn-primary !py-1.5 !px-4 text-xs disabled:opacity-50"
                      >
                        {saving ? "Salvando..." : "Salva"}
                      </button>
                    </>
                  ) : (
                    <button
                      onClick={() => setIsEditing(true)}
                      className="btn-secondary !py-1.5 !px-4 text-xs"
                    >
                      Modifica
                    </button>
                  )}
                </div>
              </div>
              <div className="flex-1 overflow-auto bg-fullio-black">
                {isEditing ? (
                  <textarea
                    value={editedContent}
                    onChange={(e) => setEditedContent(e.target.value)}
                    className="code-editor w-full h-full p-4 bg-transparent text-fullio-beige text-sm leading-relaxed resize-none"
                    spellCheck={false}
                  />
                ) : (
                  <pre className="p-4 text-sm leading-relaxed">
                    {selectedFile.content.split("\n").map((line, i) => (
                      <div key={i} className="flex">
                        <span className="w-10 text-right pr-4 text-fullio-neutral/40 select-none flex-shrink-0 text-xs leading-relaxed">
                          {i + 1}
                        </span>
                        <code className="text-fullio-beige flex-1 whitespace-pre">
                          {line || " "}
                        </code>
                      </div>
                    ))}
                  </pre>
                )}
              </div>
            </>
          ) : (
            <div className="flex-1 flex items-center justify-center text-fullio-secondary-text">
              <div className="text-center">
                <svg
                  className="w-16 h-16 mx-auto mb-4 text-fullio-neutral/30"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                  strokeWidth={1}
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    d="M17.25 6.75L22.5 12l-5.25 5.25m-10.5 0L1.5 12l5.25-5.25m7.5-3l-4.5 16.5"
                  />
                </svg>
                <p className="text-sm">Seleziona un file dalla sidebar</p>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

function FileTreeNode({
  node,
  depth,
  selectedPath,
  expandedFolders,
  onSelect,
  onToggle,
}: {
  node: TreeNode;
  depth: number;
  selectedPath?: string;
  expandedFolders: Set<string>;
  onSelect: (path: string) => void;
  onToggle: (path: string) => void;
}) {
  const isExpanded = expandedFolders.has(node.path);
  const isSelected = selectedPath === node.path;

  if (node.type === "folder") {
    return (
      <div>
        <button
          onClick={() => onToggle(node.path)}
          className="flex items-center gap-2 w-full px-2 py-1.5 rounded-lg hover:bg-fullio-light-beige transition-colors text-left"
          style={{ paddingLeft: `${depth * 12 + 8}px` }}
        >
          <svg
            className={`w-3.5 h-3.5 text-fullio-neutral transition-transform ${isExpanded ? "rotate-90" : ""}`}
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            strokeWidth={2}
          >
            <path strokeLinecap="round" strokeLinejoin="round" d="M8.25 4.5l7.5 7.5-7.5 7.5" />
          </svg>
          <svg className="w-4 h-4 text-amber-400" fill="currentColor" viewBox="0 0 24 24">
            <path d="M10 4H4a2 2 0 00-2 2v12a2 2 0 002 2h16a2 2 0 002-2V8a2 2 0 00-2-2h-8l-2-2z" />
          </svg>
          <span className="text-xs font-medium text-fullio-black truncate">
            {node.name}
          </span>
        </button>
        {isExpanded && node.children && (
          <div>
            {node.children
              .sort((a, b) => {
                if (a.type !== b.type) return a.type === "folder" ? -1 : 1;
                return a.name.localeCompare(b.name);
              })
              .map((child) => (
                <FileTreeNode
                  key={child.path}
                  node={child}
                  depth={depth + 1}
                  selectedPath={selectedPath}
                  expandedFolders={expandedFolders}
                  onSelect={onSelect}
                  onToggle={onToggle}
                />
              ))}
          </div>
        )}
      </div>
    );
  }

  return (
    <button
      onClick={() => onSelect(node.path)}
      className={`flex items-center gap-2 w-full px-2 py-1.5 rounded-lg transition-colors text-left ${
        isSelected
          ? "bg-fullio-dark text-white"
          : "hover:bg-fullio-light-beige"
      }`}
      style={{ paddingLeft: `${depth * 12 + 24}px` }}
    >
      <svg
        className={`w-4 h-4 flex-shrink-0 ${isSelected ? "text-fullio-green" : "text-fullio-green/60"}`}
        fill="none"
        viewBox="0 0 24 24"
        stroke="currentColor"
        strokeWidth={1.5}
      >
        <path strokeLinecap="round" strokeLinejoin="round" d="M17.25 6.75L22.5 12l-5.25 5.25m-10.5 0L1.5 12l5.25-5.25m7.5-3l-4.5 16.5" />
      </svg>
      <span className="text-xs truncate">{node.name}</span>
    </button>
  );
}
