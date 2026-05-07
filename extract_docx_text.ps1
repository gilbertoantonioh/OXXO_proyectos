Add-Type -AssemblyName System.IO.Compression.FileSystem
$docxPath = Join-Path (Get-Location) 'FCTI_ARM_Estandar Desarrollo Oracle EBS Rev. 3.docx'
$zip = [System.IO.Compression.ZipFile]::OpenRead($docxPath)
$entry = $zip.GetEntry('word/document.xml')
$reader = [System.IO.StreamReader]::new($entry.Open())
$xml = $reader.ReadToEnd()
$reader.Close()
$zip.Dispose()
$text = [System.Text.RegularExpressions.Regex]::Replace($xml, '<[^>]+>', ' ')
[System.IO.File]::WriteAllText((Join-Path (Get-Location) 'docx_text_extract.txt'), $text, [System.Text.Encoding]::UTF8)
Write-Output 'EXTRACTION_DONE'
