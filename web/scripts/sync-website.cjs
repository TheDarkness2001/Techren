/**
 * Copy Next.js static export into website/ while preserving downloads/.
 */
const fs = require("fs");
const path = require("path");

const root = path.resolve(__dirname, "..");
const outDir = path.join(root, "out");
const websiteDir = path.resolve(root, "..", "website");
const downloadsDir = path.join(websiteDir, "downloads");

function rimrafExcept(dir, keepNames) {
  if (!fs.existsSync(dir)) return;
  for (const name of fs.readdirSync(dir)) {
    if (keepNames.has(name)) continue;
    fs.rmSync(path.join(dir, name), { recursive: true, force: true });
  }
}

function copyRecursive(src, dest) {
  const stat = fs.statSync(src);
  if (stat.isDirectory()) {
    fs.mkdirSync(dest, { recursive: true });
    for (const name of fs.readdirSync(src)) {
      copyRecursive(path.join(src, name), path.join(dest, name));
    }
    return;
  }
  fs.mkdirSync(path.dirname(dest), { recursive: true });
  fs.copyFileSync(src, dest);
}

if (!fs.existsSync(outDir)) {
  console.error("Missing web/out — run next build first.");
  process.exit(1);
}

fs.mkdirSync(websiteDir, { recursive: true });
fs.mkdirSync(downloadsDir, { recursive: true });

rimrafExcept(websiteDir, new Set(["downloads"]));

for (const name of fs.readdirSync(outDir)) {
  copyRecursive(path.join(outDir, name), path.join(websiteDir, name));
}

console.log("Synced web/out → website/ (downloads/ preserved)");
