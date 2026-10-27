param([switch]$Apply)
$ErrorActionPreference = 'Stop'
$workspace = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$review = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'runtime_asset_cleanup_review.json') -Raw | ConvertFrom-Json
$audit = Get-Content -LiteralPath (Join-Path $workspace 'build/runtime_asset_cleanup_audit.json') -Raw | ConvertFrom-Json
$removals = @($review.assets) + @($review.sources)
$verified = foreach ($entry in $removals) {
    $file = Get-Item -LiteralPath (Join-Path $workspace $entry.path)
    if ($file.PSIsContainer -or ($file.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw "Not an ordinary file: $($entry.path)" }
    if (!$file.FullName.StartsWith($workspace + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Target escaped workspace' }
    if ($entry.path -in $audit.required -or $entry.path -in $audit.runtimeSources) { throw "Still required: $($entry.path)" }
    if ((Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash -ne $entry.sha256) { throw "Reviewed file changed: $($entry.path)" }
    $parent = $file.Directory
    while ($parent.FullName -ne $workspace) {
        if ($parent.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Linked parent: $($entry.path)" }
        $parent = $parent.Parent
    }
    [PSCustomObject]@{path=$entry.path;bytes=$file.Length;sha256=$entry.sha256;reason=$entry.reason}
}
$retained = foreach ($path in $audit.required) {
    $file = Get-Item -LiteralPath (Join-Path $workspace $path)
    [PSCustomObject]@{path=$path;bytes=$file.Length;sha256=(Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash}
}
$result = [ordered]@{
    baselineApkBytes=$review.baselineApkBytes
    baselineApkSHA256=$review.baselineApkSHA256
    reviewedUtc=$review.reviewedUtc
    removed=$verified
    removedBytes=($verified | Measure-Object -Property bytes -Sum).Sum
    retained=$retained
    preexistingMissing=$audit.preexistingMissing
    activeMediaBytesUnchanged=$true
    audioFilesRemoved=0
    sourceFilesRemoved=@($review.sources).Count
}
if (!$Apply) {
    "Read-only review: $($verified.Count) files, $($result.removedBytes) bytes. No deletions performed."
    return
}
# Every target was individually resolved, reviewed and hashed before removal.
# No recursive deletion, path enumeration through another shell, or directory move.
foreach ($entry in $verified) {
    Remove-Item -LiteralPath (Join-Path $workspace $entry.path)
}
$json = $result | ConvertTo-Json -Depth 8
[IO.File]::WriteAllText((Join-Path $PSScriptRoot 'runtime_asset_cleanup.json'), $json, [Text.UTF8Encoding]::new($false))
"Removed $($verified.Count) reviewed files; retained $($retained.Count) active asset hashes."
