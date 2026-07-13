@echo off
rem file: tester.bat v1.2
rem Автопроверка CLI _Builder.bat.
rem
rem Запуск без аргументов = все тесты.
rem Запуск с аргументами = только тесты с указанными метками.
rem Метки, содержащие пробелы, необходимо заключать в кавычки.
rem Пример: tester.bat "Localization Keys" help
rem
rem Доступные метки:
rem --- CLI (Коды выхода 0) ---
rem help, -h, --help, state, s, ib help, src help, image help, source help,
rem --lang=EN help, --lang=RU help, -l EN help, -l RU help, HELP
rem
rem --- CLI (Коды выхода 1) ---
rem build (no id), build spaces, build 999999, build no_such,
rem edit 999999, edit spaces, unknown -> profile not found,
rem --state -> profile not found, --lang=XX help, --lang help, -l help,
rem positional 999999, BUILD no id
rem
rem --- Health Checks (Проверки здоровья) ---
rem Localization Keys
rem BOM Signature
rem

setlocal enabledelayedexpansion
cd /d "%~dp0"

set "BAT=_Builder.bat"
set "PASS=0"
set "FAIL=0"
set "ROUTERFW_NO_CLS=1"
set "ROUTERFW_TEST_MODE=1"
set "LOG=%~dp0tester_log_win.md"
set "TEMP_OUT=%~dp0tester_tmp_win_out.txt"

echo # tester.bat run %date% %time% > "%LOG%"
echo. >> "%LOG%"

set "TEST_ARGS="
if not "%~1"=="" (
  set "TEST_ARGS=%*"
  echo Running filtered tests: %*
  echo.
)

set "TEE_LINE=" & call :tee
set "TEE_LINE=== CLI tester.bat (safe checks only) ==="
call :tee
set "TEE_LINE=" & call :tee

rem --- Ожидание: exit 0 ---
call :run 0 "help" help
call :run 0 "-h" -h
call :run 0 "--help" --help
call :run 0 "state" state
call :run 0 "s" s
call :run 0 "ib help" ib help
call :run 0 "src help" src help
call :run 0 "image help" image help
call :run 0 "source help" source help
call :run 0 "--lang=EN help" --lang=EN help
call :run 0 "--lang=RU help" --lang=RU help
call :run 0 "-l EN help" -l EN help
call :run 0 "-l RU help" -l RU help
call :run 0 "--runtime=auto help" --runtime=auto help
call :run 0 "--runtime=docker help" --runtime=docker help
call :run 0 "--runtime=podman help" --runtime=podman help

rem --- Ожидание: exit 1 ---
call :run 1 "build (no id)" build
call :run 1 "build spaces" build "   "
call :run 1 "build 999999" build 999999
call :run 1 "build no_such" build no_such_profile_xyz
call :run 1 "edit 999999" edit 999999
call :run 1 "edit spaces" edit "   "
call :run 1 "unknown -> profile not found" unknown_cmd_xyz
call :run 1 "--state -> profile not found" --state
call :run 1 "--lang=XX help" --lang=XX help
call :run 1 "--lang help" --lang help
call :run 1 "-l help" -l help
call :run 1 "--runtime=bad help" --runtime=bad help
call :run 1 "--runtime help" --runtime help
call :run 1 "-r help" -r help
call :run 1 "positional 999999" 999999
call :run 1 "build path traversal" build ..\evil
call :run 1 "src menuconfig no id" src menuconfig
call :run 1 "ib menuconfig 1" ib menuconfig 1

rem --- Регистр ---
call :run 0 "HELP" HELP
call :run 1 "BUILD no id" BUILD
call :run_env 0 "build forced 0" 0
call :run_env 1 "build forced 1" 1
call :run_env 42 "build forced 42" 42
call :run_env 0 "build-all forced 0" 0 build-all
call :run_env 1 "build-all forced 1" 1 build-all

rem ========== НЕ ТЕСТИРУЕМ (раскомментировать для полного прогона) ==========
rem --- реальные сборки: долгие процессы, проверять вручную; N = существующий профиль ---
rem call :run 0 "build N" build 1
rem call :run 0 "b N" b 1
rem call :run 0 "build name" build myprofile
rem call :run 0 "build-all" build-all
rem call :run 0 "all" all
rem call :run 0 "a" a
rem call :run 0 "ib build N" ib build 1
rem call :run 0 "src build N" src build 1
rem call :run 0 "positional N" 1
rem --- menuconfig: требует id, в SOURCE открывает mc; в IB даёт SOURCE only ---
rem call :run 1 "menuconfig (no id)" menuconfig
rem call :run 1 "menuconfig 999999" menuconfig 999999
rem call :run 1 "ib menuconfig 1 (SOURCE only)" ib menuconfig 1
rem --- import: то же; wizard и clean — интерактивны или меняют систему ---
rem call :run 1 "import (no id)" import
rem call :run 1 "ib import 1 (SOURCE only)" ib import 1
rem --- wizard / profile wizard (запуск create_profile) ---
rem call :run 0 "wizard" wizard
rem call :run 0 "w" w
rem --- clean: все сценарии (меню, prune, типы 1–6/1–3) — меняют кэши/контейнеры ---
rem call :run 1 "clean 0 1" clean 0 1
rem call :run 1 "clean 7 1 (IMAGE)" clean 7 1
rem call :run 1 "clean 09 1" clean 09 1
rem call :run 1 "clean 4 1 (IMAGE, 4 only SOURCE)" clean 4 1
rem clean без аргументов → интерактивное меню (не проверяем автоматически)
rem clean 9 → docker prune (не проверяем)
rem clean 1 N, clean 2 N ... → реальная очистка (не проверяем)

rem --- Project Health Checks ---
set "TEE_LINE=" & call :tee
set "TEE_LINE=== Project Health Checks ==="
call :tee
set "TEE_LINE=" & call :tee

rem ВНИМАНИЕ: Ниже исправленные регулярки (одна ^ вместо двух ^^) и полные имена команд PS
call :run_ps 0 "Localization Keys" "$ProgressPreference='SilentlyContinue'; if ( (Compare-Object (gc system/lang/ru.env | Where-Object { $_ -match '^(L_|H_)' } | ForEach-Object { if ($_ -match '^([^=]+)=') { $Matches[1] } }) (gc system/lang/en.env | Where-Object { $_ -match '^(L_|H_)' } | ForEach-Object { if ($_ -match '^([^=]+)=') { $Matches[1] } })).Length -eq 0) { exit 0 } else { exit 1 }"
call :run_ps 0 "BOM Signature" "$BOM_EXPECTED = @('system/create_profile.ps1', 'system/import_ipk.ps1'); $NO_BOM_EXPECTED = @('_Builder.sh', 'system/lang/ru.env', 'README.md'); $errors = 0; function Test-BOM($path) { $bytes = gc $path -Enc Byte -Total 3; return ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF); }; foreach ($f in $BOM_EXPECTED) { if (-not (Test-BOM $f)) { Write-Error ('BOM missing in ' + $f); $errors++; } }; foreach ($f in $NO_BOM_EXPECTED) { if (Test-BOM $f) { Write-Error ('Unexpected BOM in ' + $f); $errors++; } }; exit $errors"
call :run_ps 0 "Version Sync" "$ver=((Get-Content system/version.env | Where-Object { $_ -match '^ROUTERFW_VERSION=' }) -replace '^ROUTERFW_VERSION=','').Trim(); $checks = @((Select-String -Path _Builder.sh -SimpleMatch ('VER_NUM=' + [char]34 + $ver + [char]34)), (Select-String -Path _Builder.bat -SimpleMatch ('set ' + [char]34 + 'VER_NUM=' + $ver + [char]34)), (Select-String -Path README.md -SimpleMatch ('v' + $ver + '+')), (Select-String -Path README.en.md -SimpleMatch ('v' + $ver + '+')), (Select-String -Path docs\\ARCHITECTURE_en.md -SimpleMatch ('Version: ' + $ver + '.')), (Select-String -Path docs\\ARCHITECTURE_ru.md -SimpleMatch ('Версия: ' + $ver + '.'))); if(($checks | Where-Object { $_ }).Count -eq 6){exit 0}else{exit 1}"
call :run_ps 0 "No Global Docker Prune" "$paths = @('_Builder.sh','_Builder.bat','tester.sh','tester.bat') + (Get-ChildItem system -Filter *.sh | ForEach-Object FullName) + (Get-ChildItem system -Filter *.ps1 | ForEach-Object FullName); $pattern = ('(docker(\.exe)?|podman) (network|volume|system) pr' + 'une|run_container .* (network|volume|system) pr' + 'une|\$C_EXE .*system pr' + 'une|%%CONTAINER_EXE%% system pr' + 'une'); $matches = Select-String -Path $paths -Pattern $pattern; if($matches){$matches | ForEach-Object { $_.Path + ': ' + $_.Line }; exit 1} else {exit 0}"
call :run_ps 0 "Runtime Env Override" "$out = cmd /v:on /c 'set ROUTERFW_RUNTIME=podman&& call _Builder.bat help' 2>&1; if(($out -join [Environment]::NewLine) -match 'podman \(TEST MODE\)'){exit 0}else{exit 1}"
call :run_ps 0 "Runtime Explicit Failure" "$tmp = Join-Path $env:TEMP ('routerfw-test-' + [guid]::NewGuid()); New-Item -ItemType Directory -Path $tmp | Out-Null; try { @('@echo off','exit /b 1') | Set-Content -LiteralPath (Join-Path $tmp 'docker.cmd') -Encoding Ascii; $cmd = 'set ROUTERFW_TEST_MODE=&& set PATH=' + $tmp + ';%PATH%&& call _Builder.bat --runtime=docker help >nul 2>&1'; cmd /v:on /c $cmd; if($LASTEXITCODE -eq 1){exit 0}else{exit 1} } finally { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue }"
call :run_ps 0 "Compose Wrapper Docker" "$log = Join-Path $env:TEMP ('routerfw-compose-' + [guid]::NewGuid() + '.log'); try { $cmd = 'set ROUTERFW_TEST_MODE=1&& set ROUTERFW_NO_CLS=1&& set ROUTERFW_TEST_COMPOSE_BASE=system/docker-compose.yaml&& set ROUTERFW_TEST_COMPOSE_ARGS=-p audit up builder-openwrt&& set ROUTERFW_TEST_COMPOSE_LOG=' + $log + '&& call _Builder.bat help >nul 2>&1'; cmd /v:on /c $cmd; if($LASTEXITCODE -ne 0){exit 1}; $line = Get-Content -LiteralPath $log -ErrorAction Stop | Select-Object -First 1; if(($line -match '^docker compose -f system/docker-compose\.yaml -p audit up builder-openwrt$') -and ($line -notmatch 'docker-compose\.yaml .*docker-compose\.yaml')){exit 0}else{exit 1} } finally { Remove-Item -LiteralPath $log -Force -ErrorAction SilentlyContinue }"
call :run_ps 0 "Compose Wrapper Podman" "$log = Join-Path $env:TEMP ('routerfw-compose-' + [guid]::NewGuid() + '.log'); try { $cmd = 'set ROUTERFW_TEST_MODE=1&& set ROUTERFW_NO_CLS=1&& set ROUTERFW_RUNTIME=podman&& set ROUTERFW_TEST_COMPOSE_BASE=system/docker-compose.yaml&& set ROUTERFW_TEST_COMPOSE_ARGS=-p audit up builder-openwrt&& set ROUTERFW_TEST_COMPOSE_LOG=' + $log + '&& call _Builder.bat help >nul 2>&1'; cmd /v:on /c $cmd; if($LASTEXITCODE -ne 0){exit 1}; $line = Get-Content -LiteralPath $log -ErrorAction Stop | Select-Object -First 1; if(($line -match '^podman-compose -f system/docker-compose\.yaml -f system/podman-compose\.yaml -p audit up builder-openwrt$') -and ($line -notmatch 'docker-compose\.yaml .*docker-compose\.yaml')){exit 0}else{exit 1} } finally { Remove-Item -LiteralPath $log -Force -ErrorAction SilentlyContinue }"
call :run_ps 0 "Compose Wrapper Docker Standalone" "$log = Join-Path $env:TEMP ('routerfw-compose-' + [guid]::NewGuid() + '.log'); try { $cmd = 'set ROUTERFW_TEST_MODE=1&& set ROUTERFW_NO_CLS=1&& set ROUTERFW_TEST_COMPOSE_PROVIDER=standalone&& set ROUTERFW_TEST_COMPOSE_BASE=system/docker-compose.yaml&& set ROUTERFW_TEST_COMPOSE_ARGS=-p audit up builder-openwrt&& set ROUTERFW_TEST_COMPOSE_LOG=' + $log + '&& call _Builder.bat help >nul 2>&1'; cmd /v:on /c $cmd; if($LASTEXITCODE -ne 0){exit 1}; $line = Get-Content -LiteralPath $log -ErrorAction Stop | Select-Object -First 1; if($line -match '^docker-compose -f system/docker-compose\.yaml -p audit up builder-openwrt$'){exit 0}else{exit 1} } finally { Remove-Item -LiteralPath $log -Force -ErrorAction SilentlyContinue }"
call :run_ps 0 "Compose Wrapper Podman Standalone" "$log = Join-Path $env:TEMP ('routerfw-compose-' + [guid]::NewGuid() + '.log'); try { $cmd = 'set ROUTERFW_TEST_MODE=1&& set ROUTERFW_NO_CLS=1&& set ROUTERFW_RUNTIME=podman&& set ROUTERFW_TEST_COMPOSE_PROVIDER=standalone&& set ROUTERFW_TEST_COMPOSE_BASE=system/docker-compose.yaml&& set ROUTERFW_TEST_COMPOSE_ARGS=-p audit up builder-openwrt&& set ROUTERFW_TEST_COMPOSE_LOG=' + $log + '&& call _Builder.bat help >nul 2>&1'; cmd /v:on /c $cmd; if($LASTEXITCODE -ne 0){exit 1}; $line = Get-Content -LiteralPath $log -ErrorAction Stop | Select-Object -First 1; if($line -match '^podman-compose -f system/docker-compose\.yaml -f system/podman-compose\.yaml -p audit up builder-openwrt$'){exit 0}else{exit 1} } finally { Remove-Item -LiteralPath $log -Force -ErrorAction SilentlyContinue }"

set "TEE_LINE=" & call :tee
set "TEE_LINE=== Итого: !PASS! OK, !FAIL! FAIL ==="
call :tee
set "TEE_LINE=" & call :tee
if exist "%TEMP_OUT%" del "%TEMP_OUT%"
if not "%FAIL%"=="0" exit /b 1
exit /b 0

:run
set "EXPECT=%~1"
set "LABEL=%~2"
if defined TEST_ARGS (
  set "SHOULD_RUN=0"
  set "LABEL_NO_QUOTES=!LABEL:"=!"
  for %%T in (!TEST_ARGS!) do (
    set "CLEAN_T=%%~T"
    if /i "!CLEAN_T!"=="!LABEL_NO_QUOTES!" set "SHOULD_RUN=1"
  )
  if "!SHOULD_RUN!"=="0" exit /b 0
)
set "CMD=%~3 %~4 %~5 %~6 %~7 %~8 %~9"
set "TEE_LINE=" & call :tee
rem УБРАЛИ !CMD! ИЗ ВЫВОДА
set "TEE_LINE=--- Test: !LABEL! ---" & call :tee
call "%BAT%" %~3 %~4 %~5 %~6 %~7 %~8 %~9 > "%TEMP_OUT%" 2>&1
set "GOT=!errorlevel!"
type "%TEMP_OUT%"
type "%TEMP_OUT%" >> "%LOG%"
set "TEE_LINE=" & call :tee
if "!EXPECT!"=="!GOT!" (
  set "TEE_LINE=[OK] !LABEL!" & call :tee
  set /a PASS+=1
) else (
  set "LABEL_ECHO=!LABEL:>=^>!"
  set "LABEL_ECHO=!LABEL_ECHO:<=^<!"
  set "TEE_LINE=[FAIL] !LABEL_ECHO! ^(expected exit !EXPECT!, got !GOT!^)" & call :tee
  set /a FAIL+=1
)
exit /b 0

:run_ps
set "EXPECT=%~1"
set "LABEL=%~2"
if defined TEST_ARGS (
  set "SHOULD_RUN=0"
  set "LABEL_NO_QUOTES=!LABEL:"=!"
  for %%T in (!TEST_ARGS!) do (
    set "CLEAN_T=%%~T"
    if /i "!CLEAN_T!"=="!LABEL_NO_QUOTES!" set "SHOULD_RUN=1"
  )
  if "!SHOULD_RUN!"=="0" exit /b 0
)
set "CMD=%~3"
set "TEE_LINE=" & call :tee
rem УБРАЛИ !CMD! ИЗ ВЫВОДА
set "TEE_LINE=--- Check: !LABEL! ---" & call :tee
powershell -Command "%~3" > "%TEMP_OUT%" 2>&1
set "GOT=!errorlevel!"
type "%TEMP_OUT%"
type "%TEMP_OUT%" >> "%LOG%"
set "TEE_LINE=" & call :tee
if "!EXPECT!"=="!GOT!" (
  set "TEE_LINE=[OK] !LABEL!" & call :tee
  set /a PASS+=1
) else (
  set "LABEL_ECHO=!LABEL:>=^>!"
  set "LABEL_ECHO=!LABEL_ECHO:<=^<!"
  set "TEE_LINE=[FAIL] !LABEL_ECHO! ^(expected exit !EXPECT!, got !GOT!^)" & call :tee
  set /a FAIL+=1
)
exit /b 0

:run_env
set "EXPECT=%~1"
set "LABEL=%~2"
set "FORCED_STATUS=%~3"
set "RUN_CMD=%~4"
if not defined RUN_CMD set "RUN_CMD=build 1"
if defined TEST_ARGS (
  set "SHOULD_RUN=0"
  set "LABEL_NO_QUOTES=!LABEL:"=!"
  for %%T in (!TEST_ARGS!) do (
    set "CLEAN_T=%%~T"
    if /i "!CLEAN_T!"=="!LABEL_NO_QUOTES!" set "SHOULD_RUN=1"
  )
  if "!SHOULD_RUN!"=="0" exit /b 0
)
set "TEE_LINE=" & call :tee
set "TEE_LINE=--- Test: !LABEL! ---" & call :tee
cmd /v:on /c "set ROUTERFW_TEST_BUILD_STATUS=%FORCED_STATUS%&& call %BAT% !RUN_CMD!" > "%TEMP_OUT%" 2>&1
set "GOT=!errorlevel!"
type "%TEMP_OUT%"
type "%TEMP_OUT%" >> "%LOG%"
set "TEE_LINE=" & call :tee
if "!EXPECT!"=="!GOT!" (
  set "TEE_LINE=[OK] !LABEL!" & call :tee
  set /a PASS+=1
) else (
  set "TEE_LINE=[FAIL] !LABEL! ^(expected exit !EXPECT!, got !GOT!^)" & call :tee
  set /a FAIL+=1
)
exit /b 0

:tee
if "!TEE_LINE!"=="" (echo. & echo. >> "%LOG%") else (echo !TEE_LINE! & echo !TEE_LINE! >> "%LOG%")
exit /b 0
