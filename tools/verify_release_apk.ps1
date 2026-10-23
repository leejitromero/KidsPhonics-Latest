param(
    [string]$ApkPath = 'build/app/outputs/flutter-apk/app-release.apk',
    [string]$SnapshotPath = 'tools/release_1_0_20_source_snapshot.json',
    [string]$ReportPath = 'tools/release_1_0_20_verification.json'
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$projectRoot = Split-Path -Parent $PSScriptRoot
$apkFile = Join-Path $projectRoot $ApkPath
$versionMatch = [regex]::Match(
    (Get-Content -LiteralPath (Join-Path $projectRoot 'pubspec.yaml') -Raw),
    '(?m)^version:\s*(\d+\.\d+\.\d+)\+(\d+)\s*$')
if (!$versionMatch.Success) { throw 'Expected a version name and build number in pubspec.yaml' }
$versionName = $versionMatch.Groups[1].Value
$versionCode = [int]$versionMatch.Groups[2].Value
$snapshot = Get-Content -LiteralPath (Join-Path $projectRoot $SnapshotPath) -Raw | ConvertFrom-Json
$sourceHashes = @{}
foreach ($inputFile in $snapshot) {
    $sourcePath = Join-Path $projectRoot $inputFile.path
    $hash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
    if ($hash -ne $inputFile.sha256) { throw "Source changed during compilation: $($inputFile.path)" }
    $sourceHashes[$inputFile.path] = $hash
}
$apk = [IO.Compression.ZipFile]::OpenRead($apkFile)
$verified = 0
try {
    $required = (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'asset_usage_audit.json') -Raw | ConvertFrom-Json).required
    foreach ($path in $required) {
        if ($null -eq $apk.GetEntry("assets/flutter_assets/$path")) { throw "Missing runtime asset: $path" }
    }
    foreach ($entry in $apk.Entries) {
        if (!$entry.FullName.StartsWith('assets/flutter_assets/assets/') -or $entry.FullName.EndsWith('/')) { continue }
        $path = $entry.FullName.Substring('assets/flutter_assets/'.Length)
        if (!$sourceHashes.ContainsKey($path)) { throw "Bundled asset has no reviewed source: $path" }
        $stream = $entry.Open()
        $hasher = [Security.Cryptography.SHA256]::Create()
        try { $hash = [BitConverter]::ToString($hasher.ComputeHash($stream)).Replace('-', '') }
        finally { $stream.Dispose(); $hasher.Dispose() }
        if ($hash -ne $sourceHashes[$path]) { throw "APK asset differs from source: $path" }
        $verified++
    }
    foreach ($manifest in @('removed_legacy_assets.json', 'removed_unused_assets.json')) {
        foreach ($item in (Get-Content -LiteralPath (Join-Path $PSScriptRoot $manifest) -Raw | ConvertFrom-Json)) {
            $path = $item.path.Replace('\', '/')
            if ($null -ne $apk.GetEntry("assets/flutter_assets/$path")) { throw "Retired asset still bundled: $path" }
        }
    }
} finally { $apk.Dispose() }
$metadata = & 'C:/Android/Sdk/build-tools/35.0.0/aapt.exe' dump badging $apkFile
if ($LASTEXITCODE -ne 0) { throw 'APK metadata verification failed' }
if ($metadata[0] -notmatch "versionCode='$versionCode' versionName='$([regex]::Escape($versionName))'") {
    throw "Unexpected APK version: $($metadata[0])"
}
$signature = & 'C:/Android/Sdk/build-tools/35.0.0/apksigner.bat' verify --print-certs $apkFile
if ($LASTEXITCODE -ne 0) { throw 'APK signature verification failed' }
$certificateLine = $signature | Where-Object { $_ -match '^Signer #1 certificate SHA-256 digest:' }
$certificate = ($certificateLine -split ': ', 2)[1].Trim()
$previous = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'latest_apk_verification.json') -Raw | ConvertFrom-Json
if ($certificate -ne $previous.signerCertificateSHA256) { throw 'APK signing certificate differs from the previous release' }
$report = [ordered]@{
    version = "$versionName+$versionCode"
    verifiedUtc = [DateTime]::UtcNow.ToString('o')
    APK = $ApkPath
    sourceInputCount = $snapshot.Count
    capturedInputsUnchangedAfterBuild = $true
    RequiredAssetsVerified = $required.Count
    AllBundledSourceAssetsVerified = $verified
    homeRecordingCount = @(Get-ChildItem -LiteralPath (Join-Path $projectRoot 'assets/audio/home_intro') -Filter '*.mp3' -File).Count
    dialogueArtworkCount = 4
    ApkBytes = (Get-Item -LiteralPath $apkFile).Length
    ApkSHA256 = (Get-FileHash -LiteralPath $apkFile -Algorithm SHA256).Hash
    androidVersionName = $versionName
    androidVersionCode = $versionCode
    signatureVerified = $true
    signerCertificateSHA256 = $certificate
    updateCertificateMatchesPreviousRelease = $true
    packageMetadata = @($metadata[0..6])
}
$json = $report | ConvertTo-Json -Depth 5
[IO.File]::WriteAllText((Join-Path $projectRoot $ReportPath), $json, [Text.UTF8Encoding]::new($false))
$json
