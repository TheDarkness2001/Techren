# Publish website1 (Vite) into website/ for local API serving.
# Keeps website/downloads (status.json + installers).
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$src = Join-Path $root 'website1'
$dest = Join-Path $root 'website'
$downloads = Join-Path $dest 'downloads'

if (-not (Test-Path $src)) { throw "Missing website1 at $src" }

Push-Location $src
try {
  npm ci
  if ($LASTEXITCODE -ne 0) { throw "npm ci failed" }
  npm run build
  if ($LASTEXITCODE -ne 0) { throw "vite build failed" }
}
finally {
  Pop-Location
}

$built = Join-Path $src 'dist'
if (-not (Test-Path (Join-Path $built 'index.html'))) {
  throw "Build missing index.html in $built"
}

# Wipe old Next landing assets, keep downloads/
Get-ChildItem $dest -Force | Where-Object { $_.Name -ne 'downloads' } | Remove-Item -Recurse -Force
Copy-Item -Path (Join-Path $built '*') -Destination $dest -Recurse -Force
if (-not (Test-Path $downloads)) {
  New-Item -ItemType Directory -Path $downloads | Out-Null
}

Write-Host "Published website1 → website/ (downloads preserved)"
