#!/bin/bash
# file: tester.sh v1.2
#
# Автопроверка CLI _Builder.sh.
# Запуск без аргументов = все тесты.
# Запуск с аргументами = только тесты с указанными метками.
# Пример: ./tester.sh help "Localization Keys"
#
# Запуск без аргументов = все тесты.
# Запуск с аргументами = только тесты с указанными метками.
# Метки, содержащие пробелы, необходимо заключать в кавычки.
# Пример: ./tester.sh "Localization Keys" help
#
# Доступные метки:
# --- CLI (Коды выхода 0) ---
# help, -h, --help, state, s, ib help, src help, image help, source help,
# --lang=EN help, --lang=RU help, -l EN help, -l RU help, HELP
#
# --- CLI (Коды выхода 1) ---
# build (no id), build spaces, build 999999, build no_such,
# edit 999999, edit spaces, unknown -> profile not found,
# --state -> profile not found, --lang=XX help, --lang help, -l help,
# positional 999999, BUILD no id
#
# --- Health Checks (Проверки здоровья) ---
# Localization Keys
# BOM Signature
#

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

SH="_Builder.sh"
PASS=0
FAIL=0
export ROUTERFW_NO_CLS=1
export ROUTERFW_TEST_MODE=1

LOG="$SCRIPT_DIR/tester_log_lin.md"
TEMP_OUT="$SCRIPT_DIR/tester_tmp_lin_out.txt"
echo "# tester.sh run $(date '+%Y-%m-%d %H:%M:%S')" > "$LOG"
echo "" >> "$LOG"

# 1. Сохраняем аргументы скрипта в глобальный массив, сохраняя пробелы
FILTERS=("$@")

if [ ${#FILTERS[@]} -gt 0 ]; then
  echo "Running filtered tests: ${FILTERS[*]}"
  echo ""
fi

tee_line() {
  if [ -z "${TEE_LINE:-}" ]; then
    echo ""
    echo "" >> "$LOG"
  else
    echo "$TEE_LINE"
    echo "$TEE_LINE" >> "$LOG"
  fi
}

# Функция проверки фильтра (общая логика)
should_run() {
  local label="$1"
  # Если фильтров нет — запускаем всё
  if [ ${#FILTERS[@]} -eq 0 ]; then
    return 0 # true (bash shell exit code 0 means success/true)
  fi
  
  # Проверяем совпадение метки с одним из фильтров
  for filter in "${FILTERS[@]}"; do
    if [ "$filter" = "$label" ]; then
      return 0 # found match
    fi
  done
  
  return 1 # false (skip)
}

run() {
  local expect="$1"
  local label="$2"
  shift 2
  
  # Проверка фильтрации
  if ! should_run "$label"; then
    return 0
  fi

  TEE_LINE="" tee_line
  TEE_LINE="--- Test: $label ---" tee_line
  
  set +e
  "$SCRIPT_DIR/$SH" "$@" > "$TEMP_OUT" 2>&1
  local got=$?
  set -e
  
  cat "$TEMP_OUT"
  cat "$TEMP_OUT" >> "$LOG"
  
  TEE_LINE="" tee_line
  if [ "$expect" = "$got" ]; then
    TEE_LINE="[OK] $label" tee_line
    ((PASS++)) || true
  else
    TEE_LINE="[FAIL] $label (expected exit $expect, got $got)" tee_line
    ((FAIL++)) || true
  fi
}

run_check() {
  local expect="$1"
  local label="$2"
  local cmd="$3"

  # Проверка фильтрации
  if ! should_run "$label"; then
    return 0
  fi

  TEE_LINE="" tee_line
  TEE_LINE="--- Check: $label ---" tee_line
  
  set +e
  bash -c "$cmd" > "$TEMP_OUT" 2>&1
  local got=$?
  set -e
  
  cat "$TEMP_OUT"
  cat "$TEMP_OUT" >> "$LOG"
  
  TEE_LINE="" tee_line
  if [ "$expect" = "$got" ]; then
    TEE_LINE="[OK] $label" tee_line
    ((PASS++)) || true
  else
    TEE_LINE="[FAIL] $label (expected exit $expect, got $got)" tee_line
    ((FAIL++)) || true
  fi
}

run_env() {
  local expect="$1"
  local label="$2"
  shift 2

  if ! should_run "$label"; then
    return 0
  fi

  TEE_LINE="" tee_line
  TEE_LINE="--- Test: $label ---" tee_line

  set +e
  env "$@" > "$TEMP_OUT" 2>&1
  local got=$?
  set -e

  cat "$TEMP_OUT"
  cat "$TEMP_OUT" >> "$LOG"

  TEE_LINE="" tee_line
  if [ "$expect" = "$got" ]; then
    TEE_LINE="[OK] $label" tee_line
    ((PASS++)) || true
  else
    TEE_LINE="[FAIL] $label (expected exit $expect, got $got)" tee_line
    ((FAIL++)) || true
  fi
}

TEE_LINE="" tee_line
TEE_LINE="=== CLI tester.sh (safe checks only) ===" tee_line
TEE_LINE="" tee_line

# --- Ожидание: exit 0 ---
run 0 "help" help
run 0 "-h" -h
run 0 "--help" --help
run 0 "state" state
run 0 "s" s
run 0 "ib help" ib help
run 0 "src help" src help
run 0 "image help" image help
run 0 "source help" source help
run 0 "--lang=EN help" --lang=EN help
run 0 "--lang=RU help" --lang=RU help
run 0 "-l EN help" -l EN help
run 0 "-l RU help" -l RU help
run 0 "--runtime=auto help" --runtime=auto help
run 0 "--runtime=docker help" --runtime=docker help
run 0 "--runtime=podman help" --runtime=podman help

# --- Ожидание: exit 1 (ошибки) ---
run 1 "build (no id)" build
run 1 "build spaces" build "   "
run 1 "build 999999" build 999999
run 1 "build no_such" build no_such_profile_xyz
run 1 "edit 999999" edit 999999
run 1 "edit spaces" edit "   "
run 1 "unknown -> profile not found" unknown_cmd_xyz
run 1 "--state -> profile not found" --state
run 1 "--lang=XX help" --lang=XX help
run 1 "--lang help" --lang help
run 1 "-l help" -l help
run 1 "--runtime=bad help" --runtime=bad help
run 1 "--runtime help" --runtime help
run 1 "-r help" -r help
run 1 "positional 999999" 999999
run 1 "build path traversal" build ../evil
run 1 "src menuconfig no id" src menuconfig
run 1 "ib menuconfig 1" ib menuconfig 1

# --- Регистр ---
run 0 "HELP" HELP
run 1 "BUILD no id" BUILD
run_env 0 "build forced 0" ROUTERFW_TEST_BUILD_STATUS=0 "$SCRIPT_DIR/$SH" build 1
run_env 1 "build forced 1" ROUTERFW_TEST_BUILD_STATUS=1 "$SCRIPT_DIR/$SH" build 1
run_env 42 "build forced 42" ROUTERFW_TEST_BUILD_STATUS=42 "$SCRIPT_DIR/$SH" build 1
run_env 0 "build-all forced 0" ROUTERFW_TEST_BUILD_STATUS=0 "$SCRIPT_DIR/$SH" build-all
run_env 1 "build-all forced 1" ROUTERFW_TEST_BUILD_STATUS=1 "$SCRIPT_DIR/$SH" build-all

# ========== НЕ ТЕСТИРУЕМ (раскомментировать для полного прогона) ==========
# --- реальные сборки: долгие процессы, проверять вручную; N = существующий профиль ---
# run 0 "build N" build 1
# run 0 "b N" b 1
# run 0 "build name" build myprofile
# run 0 "build-all" build-all
# run 0 "all" all
# run 0 "a" a
# run 0 "ib build N" ib build 1
# run 0 "src build N" src build 1
# run 0 "positional N" 1
# --- menuconfig: требует id, в SOURCE открывает mc; в IB даёт SOURCE only ---
# run 1 "menuconfig (no id)" menuconfig
# run 1 "menuconfig 999999" menuconfig 999999
# run 1 "ib menuconfig 1 (SOURCE only)" ib menuconfig 1
# --- import: то же; wizard и clean — интерактивны или меняют систему ---
# run 1 "import (no id)" import
# run 1 "ib import 1 (SOURCE only)" ib import 1
# --- wizard / profile wizard (запуск create_profile) ---
# run 0 "wizard" wizard
# run 0 "w" w
# --- clean: все сценарии (меню, prune, типы 1–6/1–3) — меняют кэши/контейнеры ---
# run 1 "clean 0 1" clean 0 1
# run 1 "clean 7 1 (IMAGE)" clean 7 1
# run 1 "clean 09 1" clean 09 1
# run 1 "clean 4 1 (IMAGE, 4 only SOURCE)" clean 4 1
# clean без аргументов → интерактивное меню (не проверяем автоматически)
# clean 9 → docker prune (не проверяем)
# clean 1 N, clean 2 N ... → реальная очистка (не проверяем)

# --- Project Health Checks ---
TEE_LINE="" tee_line
TEE_LINE="=== Project Health Checks ===" tee_line
TEE_LINE="" tee_line

# Сравнение ключей
run_check 0 "Localization Keys" "diff <(grep -E '^(L_|H_)' system/lang/ru.env | sed 's/=.*//' | sort) <(grep -E '^(L_|H_)' system/lang/en.env | sed 's/=.*//' | sort)"
run_check 0 "Version Sync" "ver=\$(grep -E '^ROUTERFW_VERSION=' system/version.env | cut -d= -f2 | tr -d '\r'); grep -Fq \"VER_NUM=\\\"\$ver\\\"\" _Builder.sh && grep -Fq \"set \\\"VER_NUM=\$ver\\\"\" _Builder.bat && grep -Fq \"v\$ver+\" README.md && grep -Fq \"v\$ver+\" README.en.md && grep -Fq \"Version: \$ver.\" docs/ARCHITECTURE_en.md && grep -Fq \"Версия: \$ver.\" docs/ARCHITECTURE_ru.md"
run_check 0 "Shell Syntax" "for f in _Builder.sh tester.sh system/*.sh; do bash -n \"\$f\" || exit 1; done"
run_check 0 "No Global Docker Prune" "pat='docker(\\.exe)? (network|volume|system) pr''une|\\$C_EXE .*system pr''une|%CONTAINER_EXE% system pr''une'; ! grep -R -E \"\$pat\" _Builder.sh _Builder.bat system/*.sh system/*.ps1 >/dev/null"
run_check 0 "Runtime Env Override" "tmpdir=\$(mktemp -d); trap 'rm -rf \"\$tmpdir\"' EXIT; printf '%s\n' '#!/bin/sh' 'exit 1' >\"\$tmpdir/docker\"; printf '%s\n' '#!/bin/sh' 'case \"\$1 \$2\" in' '  \"info \"|\"info\") exit 0 ;;' '  \"compose version\") exit 0 ;;' '  \"--version \"|\"--version\") echo \"podman version 5.0.0\"; exit 0 ;;' '  *) exit 0 ;;' 'esac' >\"\$tmpdir/podman\"; chmod +x \"\$tmpdir/docker\" \"\$tmpdir/podman\"; PATH=\"\$tmpdir:\$PATH\" ROUTERFW_TEST_MODE= ROUTERFW_RUNTIME=podman \"$SCRIPT_DIR/$SH\" help >/dev/null 2>&1"
run_check 0 "Runtime Explicit Failure" "tmpdir=\$(mktemp -d); trap 'rm -rf \"\$tmpdir\"' EXIT; printf '%s\n' '#!/bin/sh' 'exit 1' >\"\$tmpdir/docker\"; chmod +x \"\$tmpdir/docker\"; PATH=\"\$tmpdir:\$PATH\" ROUTERFW_TEST_MODE= \"$SCRIPT_DIR/$SH\" --runtime=docker help >/dev/null 2>&1; test \$? -eq 1"

# Проверка BOM
BOM_CHECK_CMD="
  test_bom() { [[ \"\$(head -c 3 \"\$1\")\" == \$'\\xef\\xbb\\xbf' ]]; };
  errors=0;
  BOM_EXPECTED=('system/create_profile.ps1' 'system/import_ipk.ps1');
  NO_BOM_EXPECTED=('_Builder.sh' 'system/lang/ru.env' 'README.md');
  for f in \"\${BOM_EXPECTED[@]}\"; do 
    if [ -f \"\$f\" ]; then
        test_bom \"\$f\" || { echo \"BOM missing in \$f\"; ((errors++)); }; 
    fi
  done;
  for f in \"\${NO_BOM_EXPECTED[@]}\"; do 
    if [ -f \"\$f\" ]; then
        test_bom \"\$f\" && { echo \"Unexpected BOM in \$f\"; ((errors++)); }; 
    fi
  done;
  exit \$errors
"
run_check 0 "BOM Signature" "$BOM_CHECK_CMD"

TEE_LINE="" tee_line
TEE_LINE="=== Итого: $PASS OK, $FAIL FAIL ===" tee_line
TEE_LINE="" tee_line
rm -f "$TEMP_OUT"
if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
