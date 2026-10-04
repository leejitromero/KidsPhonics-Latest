param([string]$Voice = 'Microsoft Zira Desktop', [switch]$PraiseOnly)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Speech
. (Join-Path $PSScriptRoot 'positive_praise.ps1')
$cvcOutput = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../assets/audio/cvc_lesson'))
New-Item -ItemType Directory -Force -Path $cvcOutput | Out-Null
$cvcWords = @('CAT','BAT','HAT','MAP','FAN','BED','HEN','PEN','NET','PET','PIG','WIG','FIN','PIN','SIT','DOG','LOG','FOX','TOP','HOP','SUN','BUS','CUP','BUG','RUN')
$cvcSynth = New-Object System.Speech.Synthesis.SpeechSynthesizer
try {
  $cvcSynth.SelectVoice($Voice)
  $cvcSynth.Rate = -1
  $cvcFormat = New-Object System.Speech.AudioFormat.SpeechAudioFormatInfo(22050, [System.Speech.AudioFormat.AudioBitsPerSample]::Sixteen, [System.Speech.AudioFormat.AudioChannel]::Mono)
  if (-not $PraiseOnly) {
    $cvcSynth.SetOutputToWaveFile((Join-Path $cvcOutput 'intro.wav'), $cvcFormat)
    $cvcSynth.Speak("Let's learn C V C words!")
    $cvcSynth.SetOutputToNull()
  }
  foreach ($cvcWord in $cvcWords) {
    $cvcSlug = $cvcWord.ToLowerInvariant()
    if (-not $PraiseOnly) {
      $cvcSynth.SetOutputToWaveFile((Join-Path $cvcOutput "word-$cvcSlug.wav"), $cvcFormat)
      $cvcSynth.Speak($cvcSlug)
      $cvcSynth.SetOutputToNull()
    }
    $cvcSynth.SetOutputToWaveFile((Join-Path $cvcOutput "praise-$cvcSlug.wav"), $cvcFormat)
    $cvcSynth.SpeakSsml((New-PositivePraiseSsml -Word $cvcWord -SayWordFirst))
    $cvcSynth.SetOutputToNull()
  }
} finally { $cvcSynth.Dispose() }
Write-Output "Generated CVC narration using $Voice (PraiseOnly: $PraiseOnly)."
