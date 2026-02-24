@echo off
rem file: tester.bat v1.0
rem Автопроверка CLI _Builder.bat. Первая итерация — только безопасные проверки:
rem ничего не меняем и не ломаем (нет сборок, очистки, menuconfig, wizard, import).
rem Запуск: из корня репозитория, где лежит _Builder.bat.

setlocal enabledelayedexpansion
cd /d "%~dp0"

set "BAT=_Builder.bat"
set "PASS=0"
set "FAIL=0"
set "ROUTERFW_NO_CLS=1"
rem ROUTERFW_NO_CLS — билдер не делает cls, вывод тестера не очищается

set "LOG=%~dp0tester_log_win.md"
set "TEMP_OUT=%~dp0tester_tmp_win_out.txt"
echo # tester.bat run %date% %time% > "%LOG%"
echo. >> "%LOG%"

set "TEE_LINE=" & call :tee
set "TEE_LINE=== CLI tester.bat (safe checks only) ===" & call :tee
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

rem --- Ожидание: exit 1 (ошибки, без побочных эффектов) ---
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
call :run 1 "positional 999999" 999999

rem --- Регистр ---
call :run 0 "HELP" HELP
call :run 1 "BUILD no id" BUILD

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

set "TEE_LINE=" & call :tee
set "TEE_LINE=== Итого: !PASS! OK, !FAIL! FAIL ===" & call :tee
set "TEE_LINE=" & call :tee
if exist "%TEMP_OUT%" del "%TEMP_OUT%"
exit /b 0

:run
set "EXPECT=%~1"
set "LABEL=%~2"
set "CMD=%~3 %~4 %~5 %~6 %~7 %~8 %~9"
set "TEE_LINE=" & call :tee
set "TEE_LINE=--- !LABEL! ^| cmd: !CMD! ---" & call :tee
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

:tee
if "!TEE_LINE!"=="" (echo. & echo. >> "%LOG%") else (echo !TEE_LINE! & echo !TEE_LINE! >> "%LOG%")
exit /b 0
