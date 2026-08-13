$ErrorActionPreference = 'Stop'

# NTNH Server - Git LFS pointer resolver (Windows)
# Replaces Git LFS pointer files with real content via the GitHub LFS batch API.
# Works without git-lfs. Exit code 0 on success, 1 if any file failed.

$REPO = 'NTNewHorizons/NTNH-Server'
$BATCH_URL = "https://github.com/$REPO.git/info/lfs/objects/batch"
$POINTER_LINE = 'version https://git-lfs.github.com/spec/v1'
$RETRIES = 3

$root = (Get-Location).Path

$files = Get-ChildItem -LiteralPath $root -Recurse -File |
    Where-Object { $_.FullName -notmatch '\\\.git[\\/]' }

$failures = 0
$resolved = 0

foreach ($file in $files) {
    $path = $file.FullName
    try {
        $bytes = New-Object byte[] 256
        $fs = [System.IO.File]::OpenRead($path)
        try {
            $read = $fs.Read($bytes, 0, 256)
        } finally {
            $fs.Dispose()
        }
        $first = [System.Text.Encoding]::UTF8.GetString($bytes, 0, $read).Split("`n")[0].Trim()
    } catch {
        continue
    }
    if ($first -ne $POINTER_LINE) {
        continue
    }

    $oid = $null
    $size = 0
    foreach ($line in (Get-Content -LiteralPath $path -ErrorAction Stop)) {
        if ($line -match '^oid sha256:(.*)$') {
            $oid = $Matches[1].Trim()
        } elseif ($line -match '^size (.*)$') {
            $size = [long]$Matches[1]
        }
    }

    $rel = $path.Substring($root.Length + 1)
    Write-Host "  Downloading: $rel ($size bytes)"

    if (-not $oid -or $size -le 0) {
        Write-Host "    FAILED: malformed pointer"
        $failures++
        continue
    }

    $body = @{
        operation  = 'download'
        transfers  = @('basic')
        objects    = @(@{ oid = $oid; size = $size })
    } | ConvertTo-Json -Depth 5

    $ok = $false
    for ($attempt = 1; $attempt -le $RETRIES; $attempt++) {
        try {
            $resp = Invoke-RestMethod -Uri $BATCH_URL -Method Post `
                -Headers @{ 'Accept' = 'application/vnd.git-lfs+json' } `
                -ContentType 'application/json' -Body $body -TimeoutSec 120
            $href = $resp.objects[0].actions.download.href
            $tmp = "$path.download"
            Invoke-WebRequest -Uri $href -OutFile $tmp -UseBasicParsing -TimeoutSec 600

            $hash = (Get-FileHash -LiteralPath $tmp -Algorithm SHA256).Hash.ToLower()
            if ($hash -ne $oid) {
                Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
                throw 'sha256 mismatch'
            }
            Move-Item -LiteralPath $tmp -Destination $path -Force
            $ok = $true
            break
        } catch {
            Write-Host "    attempt $attempt failed: $($_.Exception.Message)"
            Start-Sleep -Seconds (2 * $attempt)
        }
    }

    if ($ok) {
        $resolved++
        Write-Host "    OK"
    } else {
        $failures++
        Write-Host "    FAILED"
    }
}

Write-Host "Resolved $resolved file(s)."
if ($failures -gt 0) {
    Write-Host "ERROR: $failures file(s) could not be downloaded." -ForegroundColor Red
    exit 1
}
exit 0
