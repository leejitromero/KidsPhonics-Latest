$ErrorActionPreference='Stop'
$dir='C:/Users/leeji/KidsPhonicsProject/newphonics/Kidsphonics-latest/output/technical-diagrams/application-flowchart-20261026'
Add-Type -AssemblyName System.IO.Compression.FileSystem
[xml]$svg=Get-Content -LiteralPath (Join-Path $dir 'KidsPhonics_Application_Flowchart.svg') -Raw -Encoding UTF8
$png=[IO.File]::ReadAllBytes((Join-Path $dir 'KidsPhonics_Application_Flowchart.png'))
$width=($png[16]*16777216)+($png[17]*65536)+($png[18]*256)+$png[19]
$height=($png[20]*16777216)+($png[21]*65536)+($png[22]*256)+$png[23]
if($width -ne 5000 -or $height -ne 3800){throw 'Unexpected PNG dimensions'}
$pdf=[Text.Encoding]::GetEncoding(28591).GetString([IO.File]::ReadAllBytes((Join-Path $dir 'KidsPhonics_Application_Flowchart.pdf')))
$pages=[regex]::Matches($pdf,'/Type\s*/Page\b').Count
if($pages -ne 1){throw ('PDF is not one page: '+$pages)}
$zip=[IO.Compression.ZipFile]::OpenRead((Join-Path $dir 'KidsPhonics_Application_Flowchart.docx'))
try{
 foreach($entry in $zip.Entries|Where-Object{$_.FullName -match '\.(xml|rels)$'}){$reader=New-Object IO.StreamReader($entry.Open());try{[xml]$part=$reader.ReadToEnd()}finally{$reader.Dispose()}}
 $reader=New-Object IO.StreamReader($zip.GetEntry('word/document.xml').Open());try{[xml]$doc=$reader.ReadToEnd()}finally{$reader.Dispose()}
 $ns=New-Object Xml.XmlNamespaceManager($doc.NameTable);$ns.AddNamespace('w','http://schemas.openxmlformats.org/wordprocessingml/2006/main');$ns.AddNamespace('a','http://schemas.openxmlformats.org/drawingml/2006/main')
 $plain=($doc.SelectNodes('//w:t',$ns)|ForEach-Object{$_.InnerText}) -join ' '
 foreach($token in @('Reading Guide','Source mapping','Letter Recognition','Flappy Letters','PIN','Quick Check','four of five','on-device')){if(!$plain.Contains($token)){throw ('Missing Word content: '+$token)}}
 if($plain.Contains('Chapters 1')){throw 'Unrelated exporter content remains'}
 if($doc.SelectNodes('//a:blip',$ns).Count -ne 1){throw 'DOCX diagram image missing'}
 $sizes=@($doc.SelectNodes('//w:pgSz',$ns)|ForEach-Object{($_.GetAttribute('w','http://schemas.openxmlformats.org/wordprocessingml/2006/main'))+'x'+($_.GetAttribute('h','http://schemas.openxmlformats.org/wordprocessingml/2006/main'))})
 if($sizes -notcontains '23811x16838'){throw 'A3 landscape diagram section missing'}
 $stream=$zip.GetEntry('word/media/application_flowchart.png').Open();$hash=[Security.Cryptography.SHA256]::Create();try{$embedded=[BitConverter]::ToString($hash.ComputeHash($stream)).Replace('-','')}finally{$stream.Dispose();$hash.Dispose()}
 if($embedded -ne (Get-FileHash -LiteralPath (Join-Path $dir 'KidsPhonics_Application_Flowchart.png') -Algorithm SHA256).Hash){throw 'DOCX embedded image differs'}
 $result=[ordered]@{svgXML='Passed';pngDimensions=($width.ToString()+'x'+$height.ToString());pdfPages=$pages;docxParts=$zip.Entries.Count;docxDiagramImages=1;docxEmbeddedPNGHashMatches=$true;docxSectionSizes=$sizes;docxTextCharacters=$plain.Length;visualInspection='PNG visually reviewed; final Word application rendering not performed'}
 $result|ConvertTo-Json -Depth 4|Set-Content -LiteralPath (Join-Path $dir 'artifact-validation.json') -Encoding UTF8
 $result|ConvertTo-Json -Depth 4
}finally{$zip.Dispose()}
