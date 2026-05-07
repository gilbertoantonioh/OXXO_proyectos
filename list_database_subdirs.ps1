$runPath = Join-Path (Get-Location) 'run'
Set-Location $runPath
Get-ChildItem -Directory | Where-Object { Test-Path (Join-Path $_.FullName 'database') } | ForEach-Object {
    $name = $_.Name
    Write-Output $name
    Get-ChildItem -Directory -Path (Join-Path $_.FullName 'database') | Select-Object -ExpandProperty Name | ForEach-Object { Write-Output ('  ' + $_) }
    Write-Output ''
}
