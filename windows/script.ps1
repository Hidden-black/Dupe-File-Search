$searchPath = Read-Host -Prompt "Enter the path to search for duplicate folders"
$outputFile = Join-Path -Path (Get-Location) -ChildPath "duplicate_files.html"

$folderHashes = @{}
function Get-FolderContentHash ($folderPath) {
    $files = Get-ChildItem -Path $folderPath -File -Recurse | Sort-Object FullName
    $contentString = ""
    foreach ($file in $files) {
        $fileHash = Get-FileHash -Path $file.FullName -Algorithm SHA256 | Select-Object -ExpandProperty Hash
        $contentString += "$($file.FullName):$fileHash`n"
    }
    return (Get-FileHash -InputStream ([System.IO.MemoryStream]::new([System.Text.Encoding]::UTF8.GetBytes($contentString)))).Hash
}

$folders = Get-ChildItem -Path $searchPath -Directory -Recurse

foreach ($folder in $folders) {
    try {

        $folderHash = Get-FolderContentHash -folderPath $folder.FullName
        if ($folderHashes.ContainsKey($folderHash)) {
            $folderHashes[$folderHash] += ,$folder.FullName
        } else {
            $folderHashes[$folderHash] = @($folder.FullName)
        }
    } catch {
        Write-Warning "Could not process folder: $($folder.FullName). Error: $_"
    }
}

$htmlOutput = @"
<!DOCTYPE html>
<html>
<head>
    <title>Duplicate Folders by Content</title>
    <style>
        body { font-family: Arial, sans-serif; }
        table { width: 100%; border-collapse: collapse; }
        th, td { border: 1px solid #ddd; padding: 8px; }
        th { background-color: #f2f2f2; text-align: left; }
        tr:nth-child(even) { background-color: #f9f9f9; }
    </style>
</head>
<body>
    <h1>Duplicate Folders by Content Report</h1>
    <table>
        <tr>
            <th>Content Hash</th>
            <th>Paths</th>
        </tr>
"@

foreach ($hash in $folderHashes.Keys) {
    if ($folderHashes[$hash].Count -gt 1) {
        $htmlOutput += "<tr>"
        $htmlOutput += "<td>$hash</td>"
        $htmlOutput += "<td><ul>"
        foreach ($path in $folderHashes[$hash]) {
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

Write-Host "Duplicate folders by content have been saved to $outputFile"