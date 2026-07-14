param(
    [Parameter(Mandatory = $true)]
    [string]$FilePath,

    [Parameter(Mandatory = $true)]
    [string]$Id,

    [Parameter(Mandatory = $true)]
    [string]$TempDir
)

$ErrorActionPreference = "Stop"

[void](New-Item -ItemType Directory -Force -Path $TempDir)

function Get-Md5Hex {
    param([byte[]]$Bytes)

    $md5 = [System.Security.Cryptography.MD5]::Create()
    try {
        $hash = $md5.ComputeHash($Bytes)
        $sb = [System.Text.StringBuilder]::new()
        foreach ($b in $hash) {
            [void]$sb.Append($b.ToString("x2"))
        }
        return $sb.ToString()
    }
    finally {
        $md5.Dispose()
    }
}

$tmp = Join-Path $TempDir "$Id.tmp"
$staged = Join-Path $TempDir "$Id.staged"
$out = Join-Path $TempDir "$Id.chunk"
$ready = Join-Path $TempDir "$Id.ready"
$hashOut = Join-Path $TempDir "$Id.md5"
$failed = Join-Path $TempDir "$Id.failed"

function Remove-LastLine {
    param([string[]]$Lines)

    if ($Lines.Count -le 1) {
        return @()
    }

    return @($Lines[0..($Lines.Count - 2)])
}

try {
    if (-not (Test-Path -LiteralPath $FilePath -PathType Leaf)) {
        throw "Required packer input not found: $FilePath"
    }

    $isPs1 = [bool]($FilePath -match '\.ps1$')
    $enc = [System.Text.UTF8Encoding]::new($isPs1)
    $content = [System.IO.File]::ReadAllText($FilePath, $enc).TrimEnd([char]13, [char]10)
    $crlf = [string][char]13 + [string][char]10
    $lf = [string][char]10
    $eol = if ($isPs1 -or $content.Contains($crlf)) { $crlf } else { $lf }
    $lines = @([regex]::Split($content, '\r?\n'))

    while ($lines.Count -gt 0) {
        $last = $lines[-1] -replace '\r$', ''
        if ([string]::IsNullOrWhiteSpace($last)) {
            $lines = Remove-LastLine $lines
        }
        elseif ($last -match '^\s*(::|#)?\s*checksum:MD5=[0-9a-fA-F]{32}\s*$') {
            $lines = Remove-LastLine $lines
            if ($lines.Count -gt 0 -and [string]::IsNullOrWhiteSpace(($lines[-1] -replace '\r$', ''))) {
                $lines = Remove-LastLine $lines
            }
        }
        else {
            break
        }
    }

    $cleaned = if ($lines.Count -gt 0) { ($lines -join $eol) + $eol } else { "" }
    [System.IO.File]::WriteAllText($staged, $cleaned, $enc)

    $hash = Get-Md5Hex ([System.IO.File]::ReadAllBytes($staged))

    $ext = [System.IO.Path]::GetExtension($FilePath)
    $prefix = if ($ext -ieq ".bat" -or $ext -ieq ".cmd") { "::" } else { "#" }
    [System.IO.File]::AppendAllText($staged, "$prefix checksum:MD5=$hash", $enc)

    $payloadHash = Get-Md5Hex ([System.IO.File]::ReadAllBytes($staged))
    $payloadHash | Set-Content -LiteralPath $hashOut -Encoding ASCII

    $b64 = [Convert]::ToBase64String(
        [System.IO.File]::ReadAllBytes($staged),
        [Base64FormattingOptions]::InsertLineBreaks
    )

    $chunk = @(
        ""
        ":: BEGIN_B64_ $FilePath"
        $b64
        ":: END_B64_ $FilePath"
    ) -join [Environment]::NewLine

    [System.IO.File]::WriteAllText($out, $chunk + [Environment]::NewLine, [System.Text.UTF8Encoding]::new($false))
    Remove-Item -LiteralPath $tmp, $staged -Force -ErrorAction SilentlyContinue
    "done" | Set-Content -LiteralPath $ready -Encoding ASCII
    exit 0
}
catch {
    ":: ERROR_PACKING_FILE: $FilePath" | Set-Content -LiteralPath $out -Encoding UTF8
    $_.Exception.Message | Set-Content -LiteralPath $failed -Encoding UTF8
    "done" | Set-Content -LiteralPath $ready -Encoding ASCII
    Write-Error $_.Exception.Message
    exit 1
}