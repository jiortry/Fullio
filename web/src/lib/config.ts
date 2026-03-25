import { existsSync } from "fs";
import { promises as fs } from "fs";
import path from "path";

const CONFIG_DIR = path.join(process.cwd(), "public", "config");

/** Cartella Xcode con i .swift (sibling di `web/` nella repo). */
const SWIFT_SOURCE_DIR = path.join(process.cwd(), "..", "Fullio");

/** Copia usata su Vercel dopo `prebuild` (dentro `web/`, finisce nel deploy). */
const SWIFT_BUNDLE_DIR = path.join(process.cwd(), ".native", "fullio");

function getSwiftReadRoot(): string {
  const onVercel = process.env.VERCEL === "1";
  if (onVercel || !existsSync(SWIFT_SOURCE_DIR)) {
    return SWIFT_BUNDLE_DIR;
  }
  return SWIFT_SOURCE_DIR;
}

function getSwiftWriteRoot(): string {
  if (process.env.VERCEL === "1") {
    throw new Error("Scrittura file Swift non supportata su Vercel (filesystem effimero). Usa git in locale.");
  }
  if (!existsSync(SWIFT_SOURCE_DIR)) {
    throw new Error("Cartella sorgente Fullio non trovata.");
  }
  return SWIFT_SOURCE_DIR;
}

export type ConfigSection =
  | "version"
  | "theme"
  | "categories"
  | "strings"
  | "features";

export async function readConfig(section: ConfigSection) {
  const filePath = path.join(CONFIG_DIR, `${section}.json`);
  const data = await fs.readFile(filePath, "utf-8");
  return JSON.parse(data);
}

export async function writeConfig(section: ConfigSection, data: unknown) {
  const filePath = path.join(CONFIG_DIR, `${section}.json`);
  await fs.writeFile(filePath, JSON.stringify(data, null, 2), "utf-8");
}

export async function readAllConfigs() {
  const sections: ConfigSection[] = [
    "version",
    "theme",
    "categories",
    "strings",
    "features",
  ];

  const configs: Record<string, unknown> = {};
  for (const section of sections) {
    configs[section] = await readConfig(section);
  }
  return configs;
}

export async function bumpVersion(changelog?: string) {
  const version = await readConfig("version");
  const parts = version.version.split(".").map(Number);
  parts[2] = (parts[2] || 0) + 1;
  version.version = parts.join(".");
  version.build = (version.build || 0) + 1;
  version.updatedAt = new Date().toISOString();
  if (changelog) version.changelog = changelog;
  await writeConfig("version", version);
  return version;
}

async function walkDir(dir: string, base: string): Promise<string[]> {
  const files: string[] = [];
  try {
    const entries = await fs.readdir(dir, { withFileTypes: true });
    for (const entry of entries) {
      const fullPath = path.join(dir, entry.name);
      const relPath = path.relative(base, fullPath);
      if (entry.isDirectory()) {
        if (entry.name === ".git" || entry.name === "node_modules") continue;
        files.push(...(await walkDir(fullPath, base)));
      } else if (entry.name.endsWith(".swift")) {
        files.push(relPath);
      }
    }
  } catch {
    // directory may not exist
  }
  return files;
}

export async function listSwiftFiles() {
  const root = getSwiftReadRoot();
  return walkDir(root, root);
}

export async function readSwiftFile(relativePath: string) {
  const safePath = path.normalize(relativePath).replace(/^(\.\.(\/|\\|$))+/, "");
  const swiftRoot = getSwiftReadRoot();
  const fullPath = path.join(swiftRoot, safePath);

  if (!fullPath.startsWith(path.resolve(swiftRoot))) {
    throw new Error("Access denied: path traversal detected");
  }

  if (!fullPath.endsWith(".swift")) {
    throw new Error("Only .swift files can be read");
  }

  return fs.readFile(fullPath, "utf-8");
}

export async function writeSwiftFile(relativePath: string, content: string) {
  const safePath = path.normalize(relativePath).replace(/^(\.\.(\/|\\|$))+/, "");
  const swiftRoot = getSwiftWriteRoot();
  const fullPath = path.join(swiftRoot, safePath);

  if (!fullPath.startsWith(path.resolve(swiftRoot))) {
    throw new Error("Access denied: path traversal detected");
  }

  if (!fullPath.endsWith(".swift")) {
    throw new Error("Only .swift files can be written");
  }

  await fs.writeFile(fullPath, content, "utf-8");
}
