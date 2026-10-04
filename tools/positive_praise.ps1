# Shared SSML for a brighter praise delivery, without speeding up spelling.
function New-PositivePraiseSsml {
  param([Parameter(Mandatory)][string]$Word, [switch]$SayWordFirst)
  $safeWord = [Security.SecurityElement]::Escape($Word.ToLowerInvariant())
  $safeLetters = [Security.SecurityElement]::Escape($Word.ToUpperInvariant())
  $opening = if ($SayWordFirst) { "$safeWord! <break time='90ms'/>" } else { '' }
  return @"
<speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" xml:lang="en-US">
  <prosody pitch="+12%" rate="+8%">${opening}<emphasis level="moderate">Great job!</emphasis></prosody>
  <break time="180ms"/>
  <prosody pitch="+6%" rate="medium"><say-as interpret-as="characters">$safeLetters</say-as> makes <emphasis level="moderate">$safeWord!</emphasis></prosody>
</speak>
"@
}
