/**
 * Copia i file .swift da ../Fullio (root repo) in web/.native/fullio
 * così il bundle Vercel (rootDirectory=web) include sempre le sorgenti iOS.
 * In locale le API leggono direttamente ../Fullio se esiste (vedi config.ts).
 */
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const webRoot = path.join(__dirname, "..");
const sourceRoot = path.join(webRoot, "..", "Fullio");
const destRoot = path.join(webRoot, ".native", "fullio");

function rmrf(p) {
  if (fs.existsSync(p)) fs.rmSync(p, { recursive: true, force: true });
}

function copySwiftFiles(fromDir, baseDir) {
  if (!fs.existsSync(fromDir)) {
    console.warn(
      "[sync-native-sources] Cartella sorgente assente (ok in CI senza repo completo):",
      fromDir
    );
    return;
  }

  const entries = fs.readdirSync(fromDir, { withFileTypes: true });
  for (const entry of entries) {
    const src = path.join(fromDir, entry.name);
    if (entry.isDirectory()) {
      if (entry.name === "node_modules" || entry.name === ".git") continue;
      copySwiftFiles(src, baseDir);
    } else if (entry.name.endsWith(".swift")) {
      const rel = path.relative(baseDir, src);
      const out = path.join(destRoot, rel);
      fs.mkdirSync(path.dirname(out), { recursive: true });
      fs.copyFileSync(src, out);
    }
  }
}

rmrf(destRoot);
fs.mkdirSync(destRoot, { recursive: true });

if (fs.existsSync(sourceRoot)) {
  copySwiftFiles(sourceRoot, sourceRoot);
  const count = walkCount(destRoot);
  console.log(`[sync-native-sources] Copiati ${count} file .swift → .native/fullio`);
} else {
  console.warn("[sync-native-sources] Nessuna sorgente copiata.");
}

function walkCount(dir) {
  let n = 0;
  if (!fs.existsSync(dir)) return 0;
  for (const name of fs.readdirSync(dir)) {
    const p = path.join(dir, name);
    const st = fs.statSync(p);
    if (st.isDirectory()) n += walkCount(p);
    else n += 1;
  }
  return n;
}
