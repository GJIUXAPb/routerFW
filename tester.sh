#!/bin/bash
# file: tester.sh v1.0
# Автопроверка CLI _Builder.sh. Первая итерация — только безопасные проверки:
# ничего не меняем и не ломаем (нет сборок, очистки, menuconfig, wizard, import).
# Запуск: из корня репозитория, где лежит _Builder.sh.

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

SH="_Builder.sh"
PASS=0
FAIL=0
export ROUTERFW_NO_CLS=1
# ROUTERFW_NO_CLS — билдер не делает clear, вывод тестера не очищается (если поддерживается)

LOG="$SCRIPT_DIR/tester_log_lin.md"
TEMP_OUT="$SCRIPT_DIR/tester_tmp_lin_out.txt"
echo "# tester.sh run $(date '+%Y-%m-%d %H:%M:%S')" > "$LOG"
echo "" >> "$LOG"

tee_line() {
  if [ -z "${TEE_LINE:-}" ]; then
    echo ""
    echo "" >> "$LOG"
  else
    echo "$TEE_LINE"
    echo "$TEE_LINE" >> "$LOG"
  fi
}

run() {
  local expect="$1"
  local label="$2"
  shift 2
  local cmd="$*"
  TEE_LINE="" tee_line
  TEE_LINE="--- $label | cmd: $cmd ---" tee_line
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

# --- Ожидание: exit 1 (ошибки, без побочных эффектов) ---
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
run 1 "positional 999999" 999999

# --- Регистр ---
run 0 "HELP" HELP
run 1 "BUILD no id" BUILD

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

TEE_LINE="" tee_line
TEE_LINE="=== Итого: $PASS OK, $FAIL FAIL ===" tee_line
TEE_LINE="" tee_line
rm -f "$TEMP_OUT"
exit 0
