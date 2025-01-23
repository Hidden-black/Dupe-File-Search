$searchPath = Read-Host -Prompt "Enter the search path"

if (-not (Test-Path -Path $searchPath)) {
    Write-Host "The specified path does not exist. Please provide a valid path." -ForegroundColor Red
    exit
}

$outputFile = Join-Path -Path (Get-Location) -ChildPath "dupe-files.html"
$fileHashes = @{}
$errors = @()

Write-Host "Scanning files and calculating hashes..." -ForegroundColor Yellow

$files = Get-ChildItem -Path $searchPath -File -Recurse -ErrorAction SilentlyContinue

foreach ($file in $files) {
    try {
        $fileHash = Get-FileHash -Path $file.FullName -Algorithm SHA256 | Select-Object -ExpandProperty Hash
        if ($fileHashes.ContainsKey($fileHash)) {
            $fileHashes[$fileHash] += ,$file.FullName
        } else {
            $fileHashes[$fileHash] = @($file.FullName)
        }
    } catch {
        $errors += $file.FullName
    }
}

$duplicateFiles = $fileHashes.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 }

if (-not $duplicateFiles) {
    Write-Host "No duplicate files found." -ForegroundColor Green
    exit
}

$htmlOutput = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Duplicate Files Report</title>

    <style>
    </style>






</head>
<body>
    <h1>Duplicate Files Report</h1>
    <p>Search Path: $searchPath</p>
    <p>Generated on: $(Get-Date -Format "HH:mm:ss dd-MM-yyyy")</p>
"@

foreach ($entry in $duplicateFiles) {
    $hash = $entry.Key
    $paths = $entry.Value

    $htmlOutput += "<div class='hash-group'>"
    $htmlOutput += "<div class='hash-header'>File Hash: <span style='color: #00ff00;'>$hash</span></div>"
    $htmlOutput += "<table>"
    $htmlOutput += "<tr><th>Filename</th><th>Path</th><th>Actions</th></tr>"

    foreach ($path in $paths) {
        $encodedPath = [System.Web.HttpUtility]::HtmlEncode($path)
        $filename = [System.IO.Path]::GetFileName($path)

        $htmlOutput += "<tr>"
        $htmlOutput += "<td>$filename</td>"
        $htmlOutput += "<td><a href='file:///$encodedPath' target='_blank'>$encodedPath</a></td>"
        $htmlOutput += "<td>"
        $htmlOutput += "<button class='action-btn copy-btn' onclick='copyToClipboard(this, `"$path`")'>Copy Path</button>"
        $htmlOutput += "<button class='action-btn delete-btn' onclick='deleteFile(`"$path`")'>Delete File</button>"
        $htmlOutput += "</td>"
        $htmlOutput += "</tr>"
    }

    $htmlOutput += "</table>"
    $htmlOutput += "<hr />"
    $htmlOutput += "</div>"
}

if ($errors.Count -gt 0) {
    $htmlOutput += "<div class='error-section'>"
    $htmlOutput += "<h2>Skipped Files</h2>"
    $htmlOutput += "<ul>"
    foreach ($errorFile in $errors) {
        $htmlOutput += "<li>$errorFile</li>"
    }
    $htmlOutput += "</ul>"
    $htmlOutput += "</div>"
}

$htmlOutput += @"
    <footer>
        <p>Made by <a href='https://github.com/Hidden-black/Dupe-File-Search'>Hidden-black</a></p>
    </footer>
</body>
</html>
"@

$htmlOutput | Out-File -FilePath $outputFile -Encoding UTF8

Write-Host "Duplicate files report saved at: $outputFile" -ForegroundColor Green
Invoke-Item $outputFile