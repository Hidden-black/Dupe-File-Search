$searchPath = Read-Host -Prompt "Enter the search Path"
$outputFile = Join-Path -Path (Get-Location) -ChildPath "dupe-files.html"
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
        Write-Host "Please Report the error"
    }
}

$htmlOutput = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Duplicate Files by Content</title>
    <style>
        body {font-family: "Signika Negative", sans-serif;font-weight: 300;cursor: none;margin: 0;padding: 0;background-color: #111;color: aliceblue;}
        table { width: 100%; border-collapse: collapse; }
        th, td { border: 1px solid #ddd; padding: 8px; }
        th {background-color: #111;color: aliceblue; text-align: left; }
        tr:nth-child(even) {background-color: #111;color: aliceblue;}
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
            $enPath = [System.Web.HttpUtility]::HtmlEncode($path)
            $htmlOutput += "<li>$enPath</li>"
        }
        $htmlOutput += "</ul></td>"
        $htmlOutput += "</tr>"
    }
}

$htmlOutput += @"
    </table>
<h3>End of content</h3>
<p align="right"><a href="https://github.com/Hidden-black/Dupe-File-Search">Made by hidden-black</a></p>
</body>
</html>
"@

$htmlOutput | Out-File -FilePath $outputFile -Encoding UTF8

Write-Host "Log saved at $outputFile"
Invoke-Item .\dupe-files.html