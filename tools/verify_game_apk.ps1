param([string]$ApkPath = 'build/app/outputs/flutter-apk/app-release.apk')
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$projectRoot = Split-Path -Parent $PSScriptRoot
$apk = [IO.Compression.ZipFile]::OpenRead((Join-Path $projectRoot $ApkPath))
try {
    $manifest = Get-Content (Join-Path $PSScriptRoot 'game_assets_manifest.json') -Raw | ConvertFrom-Json
    $removed = Get-Content (Join-Path $PSScriptRoot 'removed_legacy_assets.json') -Raw | ConvertFrom-Json
    $paths = @($manifest | ForEach-Object { $_.audio; $_.frames }) | Sort-Object -Unique
    $usageAuditPath = Join-Path $PSScriptRoot 'asset_usage_audit.json'
    if (Test-Path -LiteralPath $usageAuditPath) {
        $usageAudit = Get-Content -LiteralPath $usageAuditPath -Raw | ConvertFrom-Json
        $paths = @($paths) + @($usageAudit.required) | Sort-Object -Unique
    }
    foreach ($path in $paths) {
        $entry = $apk.GetEntry("assets/flutter_assets/$path")
        if ($null -eq $entry) { throw "Missing supplied asset: $path" }
        $sourceHash = (Get-FileHash -LiteralPath (Join-Path $projectRoot $path) -Algorithm SHA256).Hash
        $stream = $entry.Open()
        $hasher = [Security.Cryptography.SHA256]::Create()
        try { $apkHash = [BitConverter]::ToString($hasher.ComputeHash($stream)).Replace('-', '') }
        finally { $stream.Dispose(); $hasher.Dispose() }
        if ($sourceHash -ne $apkHash) { throw "Asset bytes differ: $path" }
    }
    foreach ($item in $removed) {
        $path = $item.path.Replace('\', '/')
        if ($null -ne $apk.GetEntry("assets/flutter_assets/$path")) {
            throw "Retired asset is still bundled: $path"
        }
    }
    $cleanupManifestPath = Join-Path $PSScriptRoot 'removed_unused_assets.json'
    $cleanupRemovedCount = 0
    if (Test-Path -LiteralPath $cleanupManifestPath) {
        $cleanupRemoved = Get-Content -LiteralPath $cleanupManifestPath -Raw | ConvertFrom-Json
        foreach ($item in $cleanupRemoved) {
            if ($null -ne $apk.GetEntry("assets/flutter_assets/$($item.path)")) {
                throw "Unused asset is still bundled: $($item.path)"
            }
        }
        $cleanupRemovedCount = $cleanupRemoved.Count
    }
    [pscustomobject]@{
        SuppliedWords = $manifest.Count
        VerifiedAssets = $paths.Count
        RemovedAssetsAbsent = $removed.Count
        CleanupFilesAbsent = $cleanupRemovedCount
        ApkBytes = (Get-Item -LiteralPath (Join-Path $projectRoot $ApkPath)).Length
        ApkSHA256 = (Get-FileHash -LiteralPath (Join-Path $projectRoot $ApkPath) -Algorithm SHA256).Hash
    } | ConvertTo-Json
}
finally { $apk.Dispose() }
