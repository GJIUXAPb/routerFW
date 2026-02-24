# RouterFW — Релиз 4.44

**Версия:** 4.44  
**Период изменений:** от тега 4.43 до текущего состояния ветки 4.44

---

## Русский

### Что нового

- **CLI (аргументы командной строки).**  
  `_Builder.bat` и `_Builder.sh` принимают аргументы для неинтерактивного запуска: выбор профиля, режима сборки (Image Builder / Source Builder) и других действий без входа в интерактивное меню. Удобно для скриптов и CI.

- **Тестовые оболочки CLI.**  
  Добавлены `tester.bat` и `tester.sh` — первые версии тестовых оболочек для проверки CLI: запуск билдеров с аргументами, проверка кодов выхода и вывода. Выполняют только безопасные проверки (без сборок, очистки, menuconfig, wizard). Логи и артефакты (`tester_log_*.md`, `tester_tmp_*_out.txt`) добавлены в `.gitignore`.

- **Определение языка на Linux.**  
  Улучшено автоматическое определение языка при старте `_Builder.sh` (переменная/окружение); словари `ru.env` / `en.env` по-прежнему загружаются до меню.

- **Source Builder — исправление определения цели/устройства.**  
  Исправлен баг с определением target/subtarget и профиля в `src_builder.sh` и в мастерах создания профилей (`create_profile.sh`, `create_profile.ps1`). Корректное использование конфигурации профиля при сборке из исходников. Добавлены примеры профилей для TP-Link TL-WR1043ND v2 (OpenWrt 24.01.05).

- **Шаблоны URL в мастере профилей.**  
  В шаблонах профилей (Fantastic packages) исправлены URL: добавлен сегмент `/packages/` и корректное использование переменной архитектуры (`$ARCH` / `$arch`) в `create_profile.sh` и `create_profile.ps1`.

- **Документация.**  
  — Добавлена карта документации: `docs/map.md`, `docs/map.en.md`.  
  — Схема архитектуры разделена на русскую и английскую версии: `docs/ARCHITECTURE_diagram_ru.md`, `docs/ARCHITECTURE_diagram_en.md` (общий `ARCHITECTURE_diagram.md` удалён).  
  — Новые гайды: `docs/06-rax3000m-emmc-flash.md` / `.en.md` (прошивка eMMC на Rax3000M), `docs/07-troubleshooting-faq.md` / `.en.md` (часто задаваемые вопросы и решение проблем).  
  — Обновлены вводная часть, разделы по Source Build, патчам и индексы (`docs/index.md`, `docs/index.en.md`, `docs/ARCHITECTURE_*.md`).

- **Визуализация релизов и каталог `dist/`.**  
  — GitHub Actions workflow `release-visualizer.yml`: по расписанию и ручному запуску обновляет CHANGELOG из GitHub Releases (`system/get-git.ps1`), генерирует SVG: timeline, tree, виджеты V3 (heatmap, river, bars, stats), «архитектурный тетрис» (`system/changelog-to-svg.ps1`, `system/changelog-to-svg-v3.ps1`, `system/architecture-tetris.ps1`), змейку контрибуций; деплоит результат в ветку `output`.  
  — Каталог `dist/` описан в правилах проекта как место для сгенерированных SVG-артефактов.

- **Правила и игноры репозитория.**  
  — Добавлен `.cursorignore`: исключение из индекса Cursor токсичных файлов (`_unpacker.*`), приватных каталогов, `firmware_output/`, тестовых сред (`nl_test/`, `nw_test/`), `.docker_tmp/` — в соответствии с `.gitignore` и правилами проекта.  
  — Обновлены `.cursor/rules/project-overview.mdc` и `documentation.mdc` (CLI, тестеры, Source Builder fix, dist, .cursorignore).

- **Очистка и обслуживание.**  
  — Удалены устаревшие скрипты в `scripts/rax3000m/`: `manual_config*`, `run_generator.bat`, `generate_options.ps1`.  
  — Удалён `scripts/old_hooks.sh`.  
  — В `.gitattributes` добавлено правило для `profiles/personal.flag` (EOL).  
  — Упаковщики `_packer.bat` / `_packer.sh`: обновление формата/версии распаковщиков.

---

## English

### What's New

- **CLI (command-line arguments).**  
  `_Builder.bat` and `_Builder.sh` accept command-line arguments for non-interactive runs: profile selection, build mode (Image Builder / Source Builder), and other actions without entering the interactive menu. Suitable for scripts and CI.

- **CLI test harnesses.**  
  Added `tester.bat` and `tester.sh` — first versions of test harnesses for CLI verification: running builders with arguments and checking exit codes and output. They only perform safe checks (no builds, clean, menuconfig, wizard). Logs and artifacts (`tester_log_*.md`, `tester_tmp_*_out.txt`) are listed in `.gitignore`.

- **Language detection on Linux.**  
  Improved automatic language detection at `_Builder.sh` startup (variable/environment); dictionaries `ru.env` / `en.env` are still loaded before the menu.

- **Source Builder — target/device detection fix.**  
  Fixed a bug in target/subtarget and profile handling in `src_builder.sh` and in the profile creation wizards (`create_profile.sh`, `create_profile.ps1`). Profile configuration is now correctly applied when building from source. Example profiles for TP-Link TL-WR1043ND v2 (OpenWrt 24.01.05) added.

- **URL templates in profile wizard.**  
  Profile templates (Fantastic packages) now use corrected URLs: the `/packages/` path segment and the correct architecture variable (`$ARCH` / `$arch`) in `create_profile.sh` and `create_profile.ps1`.

- **Documentation.**  
  — Documentation map added: `docs/map.md`, `docs/map.en.md`.  
  — Architecture diagram split into Russian and English: `docs/ARCHITECTURE_diagram_ru.md`, `docs/ARCHITECTURE_diagram_en.md` (single `ARCHITECTURE_diagram.md` removed).  
  — New guides: `docs/06-rax3000m-emmc-flash.md` / `.en.md` (Rax3000M eMMC flashing), `docs/07-troubleshooting-faq.md` / `.en.md` (FAQ and troubleshooting).  
  — Introduction, Source Build and patch sections, and indexes updated (`docs/index.md`, `docs/index.en.md`, `docs/ARCHITECTURE_*.md`).

- **Release visualization and `dist/`.**  
  — GitHub Actions workflow `release-visualizer.yml`: on schedule and manual trigger it refreshes CHANGELOG from GitHub Releases (`system/get-git.ps1`), generates SVG assets: timeline, tree, V3 widgets (heatmap, river, bars, stats), “architecture tetris” (`system/changelog-to-svg.ps1`, `system/changelog-to-svg-v3.ps1`, `system/architecture-tetris.ps1`), contribution snake; deploys results to the `output` branch.  
  — The `dist/` directory is documented in project rules as the place for generated SVG artifacts.

- **Repository rules and ignores.**  
  — Added `.cursorignore`: excludes from Cursor index toxic files (`_unpacker.*`), private dirs, `firmware_output/`, test envs (`nl_test/`, `nw_test/`), `.docker_tmp/` — aligned with `.gitignore` and project rules.  
  — Updated `.cursor/rules/project-overview.mdc` and `documentation.mdc` (CLI, testers, Source Builder fix, dist, .cursorignore).

- **Cleanup and maintenance.**  
  — Removed obsolete scripts in `scripts/rax3000m/`: `manual_config*`, `run_generator.bat`, `generate_options.ps1`.  
  — Removed `scripts/old_hooks.sh`.  
  — `.gitattributes`: added rule for `profiles/personal.flag` (EOL).  
  — Packagers `_packer.bat` / `_packer.sh`: updated unpacker format/version.

---

*Release notes for GitHub — summary of changes from tag 4.43 to current 4.44.*
