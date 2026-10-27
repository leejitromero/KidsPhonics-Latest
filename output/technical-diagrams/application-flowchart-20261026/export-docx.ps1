$ErrorActionPreference='Stop'
$flowDir='C:/Users/leeji/KidsPhonicsProject/newphonics/Kidsphonics-latest/output/technical-diagrams/application-flowchart-20261026'
$base=Get-Content -LiteralPath 'C:/Users/leeji/AppData/Local/Temp/kidsphonics-review-export.ps1' -Raw -Encoding UTF8
$index=$base.IndexOf('$script:links =');if($index -lt 0){throw 'DOCX exporter missing'}
$exporter=$base.Substring($index)
$imageXml=@'
<w:p><w:pPr><w:jc w:val="center"/><w:spacing w:before="0" w:after="0"/></w:pPr><w:r><w:drawing><wp:inline xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing" distT="0" distB="0" distL="0" distR="0"><wp:extent cx="12783820" cy="9715500"/><wp:docPr id="1" name="KidsPhonics Application Flowchart" descr="Source-verified application flowchart; see reading guide on the following pages."/><a:graphic xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"><a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture"><pic:pic xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture"><pic:nvPicPr><pic:cNvPr id="0" name="application_flowchart.png"/><pic:cNvPicPr/></pic:nvPicPr><pic:blipFill><a:blip r:embed="flowImage"/><a:stretch><a:fillRect/></a:stretch></pic:blipFill><pic:spPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="12783820" cy="9715500"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom></pic:spPr></pic:pic></a:graphicData></a:graphic></wp:inline></w:drawing></w:r></w:p>
'@
$sectionBreak='<w:p><w:pPr><w:spacing w:before="0" w:after="0"/><w:sectPr><w:type w:val="nextPage"/><w:pgSz w:w="23811" w:h="16838" w:orient="landscape"/><w:pgMar w:top="360" w:right="360" w:bottom="360" w:left="360" w:header="0" w:footer="0" w:gutter="0"/></w:sectPr></w:pPr></w:p>'
$exporter=$exporter.Replace("[void]"+'$body.Append((ParagraphXml ''KidsPhonics Research Paper Review'' ''Title''))',"[void]"+'$body.Append($imageXml)')
$exporter=[regex]::Replace($exporter,"\[void\]"+'\$body.Append\(\(ParagraphXml ''Chapters [^'']+'' ''Subtitle''\)\)', '')
$exporter=$exporter.Replace("[void]"+'$body.Append((ParagraphXml ''Petsa ng review: 25 October 2026'' ''Subtitle''))',"[void]"+'$body.Append($sectionBreak)')
$exporter=$exporter.Replace('KidsPhonics_Research_Paper_Review.docx','KidsPhonics_Application_Flowchart.docx')
$exporter=[regex]::Replace($exporter,'KidsPhonics Research Review [^<]+','KidsPhonics Application Flowchart - ')
$exporter=$exporter.Replace('<Relationship Id="styles"','<Relationship Id="flowImage" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/application_flowchart.png"/><Relationship Id="styles"')
$exporter=$exporter.Replace('<Default Extension="rels"','<Default Extension="png" ContentType="image/png"/><Default Extension="rels"')
$exporter=$exporter.Replace('$outputDir=Join-Path (Get-Location).Path ''output\research-review''','$outputDir=$flowDir')
$exporter=[regex]::Replace($exporter,"@\('Mga diagram[^\r\n]+?\)","@('Quick Check','Parents','Settings','Source mapping','1.0.37+38','26 October 2026')")
$binaryInsert=@'
 $binaryEntry=$archive.CreateEntry('word/media/application_flowchart.png')
 $binaryStream=$binaryEntry.Open()
 try{$pngBytes=[IO.File]::ReadAllBytes((Join-Path $flowDir 'KidsPhonics_Application_Flowchart.png'));$binaryStream.Write($pngBytes,0,$pngBytes.Length)}finally{$binaryStream.Dispose()}
'@
$exporter=$exporter.Replace(' $parts=@{',($binaryInsert+[Environment]::NewLine+' $parts=@{'))
$markdown=Get-Content -LiteralPath (Join-Path $flowDir 'Application_Flowchart_Notes.md') -Raw -Encoding UTF8
$markdown=$markdown.Replace('# KidsPhonics Application Flowchart','# Reading Guide and Source Verification')
$markdown=[regex]::Replace($markdown,'(?m)^#{1,3}\s+(.+)$','**$1**')
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
& ([scriptblock]::Create($exporter))
