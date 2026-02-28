<#
.SYNOPSIS
    Выгружает тексты GitHub-релизов по тегам в CHANGELOG.md в корне проекта.
# file: system/get-git.ps1 v1.1
.DESCRIPTION
    Обновляет теги с remote (git fetch --tags), затем получает список тегов
    (git tag -l --sort=creatordate), для каждого вызывает gh release view
    и дописывает вывод в CHANGELOG.md.
    Требует: git, gh CLI, запуск из корня репозитория или из system/.
.EXAMPLE
    .\system\get-git.ps1
#>

$ErrorActionPreference = "Stop"

# Корень репозитория: скрипт лежит в system/get-git.ps1
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = (Get-Item $ScriptDir).Parent.FullName
$ChangelogPath = Join-Path $ProjectRoot "CHANGELOG.md"

# Запуск из корня репозитория
$null = Set-Location $ProjectRoot

# Обновить теги с remote (чтобы учесть новые релизы)
$fetchResult = git fetch --tags 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Предупреждение: не удалось обновить теги (git fetch --tags). Используются локальные теги." -ForegroundColor Yellow
}

$header = @"
# RouterFW — тексты релизов (по тегам)

Выгружено из репозитория по тегам через ``gh release view``.
Дата выгрузки: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss').

---

"@

Set-Content -Path $ChangelogPath -Value $header -Encoding UTF8

$tags = git tag -l --sort=creatordate
$count = 0
foreach ($t in $tags) {
    Add-Content -Path $ChangelogPath -Value "`n`n## ========== TAG: $t ==========`n" -Encoding UTF8
    $out = & gh release view $t 2>&1
    if ($LASTEXITCODE -ne 0) {
        Add-Content -Path $ChangelogPath -Value "(нет GitHub Release для тега $t или ошибка gh)`n" -Encoding UTF8
    } else {
        Add-Content -Path $ChangelogPath -Value $out -Encoding UTF8
        $count++
    }
}

Write-Host "CHANGELOG.md записан: $ChangelogPath"
Write-Host "Обработано тегов с релизами: $count из $($tags.Count)"
