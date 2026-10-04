param([string]$Voice = 'Microsoft Zira Desktop', [switch]$PraiseOnly)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Speech
. (Join-Path $PSScriptRoot 'positive_praise.ps1')
$blendOutput = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../assets/audio/blending_lesson'))
New-Item -ItemType Directory -Force -Path $blendOutput | Out-Null
$blendWords = @('DOG','CAT','SUN','PIG','HAT','BED','PEN','FOX','CUP','MAP','BUS','LOG','HEN','FIN','RUG','CAP','BAG','VAN','PAN','RAM','RED','TEN','LEG','JET','WEB','BIG','LIP','DIG','KID','RIB','BOX','MOP','POT','HOT','COT','MUG','HUG','NUT','HUT','PUP')
$blendSynth = New-Object System.Speech.Synthesis.SpeechSynthesizer
try {
  $blendSynth.SelectVoice($Voice)
  $blendSynth.Rate = -1
  $blendFormat = New-Object System.Speech.AudioFormat.SpeechAudioFormatInfo(22050, [System.Speech.AudioFormat.AudioBitsPerSample]::Sixteen, [System.Speech.AudioFormat.AudioChannel]::Mono)
  if (-not $PraiseOnly) {
    foreach ($cue in @(@('intro', "Let's blend some sounds! Drag the letters to build the word!"), @('try-another', 'Try another spot!'))) {
      $blendSynth.SetOutputToWaveFile((Join-Path $blendOutput ($cue[0] + '.wav')), $blendFormat)
      $blendSynth.Speak($cue[1])
      $blendSynth.SetOutputToNull()
    }
  }
  foreach ($blendWord in $blendWords) {
    $blendSlug = $blendWord.ToLowerInvariant()
    if (-not $PraiseOnly -and -not (Test-Path -LiteralPath (Join-Path $PSScriptRoot "../assets/audio/cvc_lesson/word-$blendSlug.wav"))) {
      $blendSynth.SetOutputToWaveFile((Join-Path $blendOutput "word-$blendSlug.wav"), $blendFormat)
      $blendSynth.Speak($blendSlug)
      $blendSynth.SetOutputToNull()
    }
    $blendSynth.SetOutputToWaveFile((Join-Path $blendOutput "praise-$blendSlug.wav"), $blendFormat)
    $blendSynth.SpeakSsml((New-PositivePraiseSsml -Word $blendWord))
    $blendSynth.SetOutputToNull()
  }
} finally { $blendSynth.Dispose() }
Write-Output "Generated blending narration using $Voice (PraiseOnly: $PraiseOnly)."
