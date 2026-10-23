param([int]$LongEdge = 7680)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$projectPath = Split-Path $PSScriptRoot -Parent
$exportPath = Join-Path $projectPath 'output/home_classroom/8k'
New-Item -ItemType Directory -Force -Path $exportPath | Out-Null
$report = @()
foreach ($phase in @('morning', 'sunset', 'night')) {
    $sourcePath = Join-Path $projectPath "assets/images/home_classroom/$phase.png"
    $targetPath = Join-Path $exportPath "$phase-8k.png"
    $sourceImage = [System.Drawing.Image]::FromFile($sourcePath)
    $targetHeight = $LongEdge
    $targetWidth = [int][Math]::Round($sourceImage.Width * $LongEdge / $sourceImage.Height)
    $bitmap = New-Object System.Drawing.Bitmap($targetWidth, $targetHeight)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $attributes = New-Object System.Drawing.Imaging.ImageAttributes
    try {
        $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $attributes.SetWrapMode([System.Drawing.Drawing2D.WrapMode]::TileFlipXY)
        $targetRect = New-Object System.Drawing.Rectangle(0, 0, $targetWidth, $targetHeight)
        $graphics.DrawImage($sourceImage, $targetRect, 0, 0,
            $sourceImage.Width, $sourceImage.Height,
            [System.Drawing.GraphicsUnit]::Pixel, $attributes)
        $bitmap.Save($targetPath, [System.Drawing.Imaging.ImageFormat]::Png)
        $report += [pscustomobject]@{
            phase = $phase
            source = "assets/images/home_classroom/$phase.png"
            sourceWidth = $sourceImage.Width
            sourceHeight = $sourceImage.Height
            export = "output/home_classroom/8k/$phase-8k.png"
            width = $targetWidth
            height = $targetHeight
            method = 'High-quality bicubic upscale; original composition preserved'
            sourceSha256 = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
            exportSha256 = (Get-FileHash -LiteralPath $targetPath -Algorithm SHA256).Hash
        }
        Write-Output "$phase exported: $targetWidth x $targetHeight"
    } finally {
        $attributes.Dispose()
        $graphics.Dispose()
        $bitmap.Dispose()
        $sourceImage.Dispose()
    }
}
$report | ConvertTo-Json -Depth 4 | Set-Content -Encoding UTF8 (Join-Path $exportPath 'manifest.json')
