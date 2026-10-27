$ErrorActionPreference='Stop'
$flowDir='C:/Users/leeji/KidsPhonicsProject/newphonics/Kidsphonics-latest/output/technical-diagrams/application-flowchart-20261026'
$profile=Join-Path $env:TEMP 'kidsphonics-diagram-browser-20261026'
$edge='C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe'
$uri=([Uri](Join-Path $flowDir 'KidsPhonics_Application_Flowchart.html')).AbsoluteUri
$common=@('--headless=new','--disable-gpu','--no-first-run','--no-default-browser-check','--disable-background-networking','--disable-extensions','--disable-sync',('--user-data-dir="'+$profile+'"'))
$png=Join-Path $flowDir 'KidsPhonics_Application_Flowchart.png'
$argsPng=$common+@('--hide-scrollbars','--force-device-scale-factor=1','--window-size=5000,3800',('--screenshot="'+$png+'"'),$uri)
$pngProcess=Start-Process -FilePath $edge -ArgumentList $argsPng -PassThru -Wait -WindowStyle Hidden -RedirectStandardError (Join-Path $flowDir 'render-png.log')
if($pngProcess.ExitCode -ne 0 -or !(Test-Path -LiteralPath $png)){throw 'PNG render failed'}
$pdf=Join-Path $flowDir 'KidsPhonics_Application_Flowchart.pdf'
$argsPdf=$common+@('--no-pdf-header-footer',('--print-to-pdf="'+$pdf+'"'),$uri)
$pdfProcess=Start-Process -FilePath $edge -ArgumentList $argsPdf -PassThru -Wait -WindowStyle Hidden -RedirectStandardError (Join-Path $flowDir 'render-pdf.log')
if($pdfProcess.ExitCode -ne 0 -or !(Test-Path -LiteralPath $pdf)){throw 'PDF render failed'}
Get-Item -LiteralPath $png,$pdf|Select-Object Name,Length
