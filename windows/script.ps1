$searchPath = Read-Host -Prompt "Enter the path to search for duplicate files"
$outputFile = Join-Path -Path (Get-Location) -ChildPath "duplicate-files.html"
$fileHashes = @{}
$files = Get-ChildItem -Path $searchPath -File -Recurse

foreach ($file in $files) {
    try {
        $fileHash = Get-FileHash -Path $file.FullName -Algorithm SHA256 | Select-Object -ExpandProperty Hash
        if ($fileHashes.ContainsKey($fileHash)) {
            $fileHashes[$fileHash] += ,$file.FullName
        } else {
            $fileHashes[$fileHash] = @($file.FullName)
        }
    } catch {
        Write-Warning "Could not process file: $($file.FullName). Error: $_"
    }
}

$htmlOutput = @"
<!DOCTYPE html>
<html>
<head>
    <title>Duplicate Files in $searchpath</title>
    <style>
        body { font-family: Arial, sans-serif; }
        table { width: 100%; border-collapse: collapse; }
        th, td { border: 1px solid #ddd; padding: 8px; }
        th { background-color: #f2f2f2; text-align: left; }
        tr:nth-child(even) { background-color: #f9f9f9; }
    </style>
</head>
<body>
    <h1>Duplicate Files by Content Report</h1>
    <table>
        <tr>
            <th>File Hash</th>
            <th>Paths</th>
        </tr>
"@

foreach ($hash in $fileHashes.Keys) {
    if ($fileHashes[$hash].Count -gt 1) {
        $htmlOutput += "<tr>"
        $htmlOutput += "<td>$hash</td>"
        $htmlOutput += "<td><ul>"
        foreach ($path in $fileHashes[$hash]) {
            $htmlOutput += "<li>$path</li>"
        }
        $htmlOutput += "</ul></td>"
        $htmlOutput += "</tr>"
    }
}

$htmlOutput += @"
    </table>
</body>
</html>
"@

$htmlOutput | Out-File -FilePath $outputFile -Encoding UTF8
Write-Host "Log Stored at $outputFile"