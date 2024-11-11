$searchpath = "D:\"
$out = "D:\dupe-files.html"

$folderHash = @{}

function Get-FolderContentHash ($folderpath) {
    $files = Get-ChildItem -Path $folderpath -File -Recurse | Sort-Object FullName
    $constr= ""
    foreach ($file in $files) {
        $fileHash = Get-FileHash -Path $file.FullName -Algorithm SHA256 | Select-Object -ExpandProperty Hash
        $constr += "$($file.FullName):$fileHash`n"
    }
    return(Get-FileHash -InputStream ([System.IO.MemoryStream]::new([System.Text.Encoding]::UTF8.GetBytes($contentString)))).Hash
}

$folders = Get-ChildItem -Path $searchPath -Directory -Recurse

foreach ($folder in $folders) {
    try {
        $folderHash = Get-FolderContentHash -folderpath $folder.FullName

        if ($folderHashes.ContainsKey($folderHash)) {
            $folderHashes[$folderHash] += ,$folder.Fullname
        } else {
            $folderHashes[$folderHash] = @($folder.FullName)
        }
    } catch {
        Write-Warning "Could not process folder: $($folder.FullName). Error $_"
    }
}

Write-Debug "Saved at $($out)"