# RouterFW 4.70

Версия 4.70 — крупное обновление стабильности, переносимости и контроля качества. Главный фокус релиза: полноценная поддержка Docker/Podman, одинаковое поведение Windows и Linux сборщиков, более надежный packer/unpacker и проверяемая CI/CD-цепочка.

## Главное

- Добавлена поддержка выбора контейнерного рантайма: `Docker` или `Podman`.
- В `_Builder.bat` и `_Builder.sh` добавлены ключи `--runtime=auto|docker|podman` и `-r auto|docker|podman`.
- При обычном интерактивном запуске, если доступны и Docker, и Podman, билдер спрашивает, какой движок использовать.
- В меню теперь явно показывается активный движок сборки: `через docker` или `через podman`.
- Для WSL добавлен fallback на Windows CLI: `docker.exe` и `podman.exe`.
- Версия проекта вынесена в `system/version.env`, синхронизирована с BAT/SH билдерами, README и архитектурной документацией.

## Docker и Podman

- Реализована единая runtime-обвязка для `docker compose`, `docker-compose`, `podman compose`, `podman-compose`, `docker.exe compose` и `podman.exe compose`.
- Добавлены Podman compose override-файлы:
  - `system/podman-compose.yaml`
  - `system/podman-compose-src.yaml`
- Compose-монты получили runtime-aware suffix-переменные для корректной работы bind mount'ов в Docker, Podman и SELinux/Podman окружениях.
- Исправлена работа SourceBuilder smoke-сценариев с output-каталогами.
- Убрана глобальная очистка Docker/Podman через опасный `system prune`; очистка теперь ограничена проектными контейнерами, томами и профилями.

## Builder UI и CLI

- Главное окно Windows BAT builder снова получает корректный заголовок.
- Окна запущенных сборок в BAT-версии снова получают уникальные имена, чтобы их было легко отличать.
- CLI-команды стали строже и понятнее:
  - `build`
  - `build-all`
  - `ib build`
  - `src build`
  - `--lang`
  - `--runtime`
- В SH и BAT версиях выровнен набор runtime-тестов и CLI-проверок.
- Массовая сборка в SH получила параллельный режим с лимитом по умолчанию `ROUTERFW_JOBS=6`.
- Параллельные тесты добавлены для SH и BAT tester'ов через `ROUTERFW_TEST_JOBS`.

## Packer / Unpacker

- Packer обновлен до `2.7MT` для Windows и Linux.
- Windows packer переведен на отдельный PowerShell worker: `system/packer_worker.ps1`.
- Исправлены ошибки CMD quoting при запуске worker-процессов.
- Исправлены ложные успешные завершения packer'а, когда `_unpacker.bat.new` не был заменен на `_unpacker.bat`.
- Добавлена строгая обработка ошибок:
  - не удалось удалить старый `.new`;
  - не удалось создать временную папку;
  - worker завершился с ошибкой;
  - worker завис;
  - итоговый unpacker не был заменен.
- Unpacker теперь строже проверяет Base64 payload и checksum перед записью файлов.
- Поврежденный payload теперь приводит к ошибке распаковки, а не к тихой записи битого файла.
- Нормальный запуск builder больше не запускает долгую проверку/восстановление ресурсов каждый раз; unpacker вызывается только при первом bootstrap, repair или отсутствии ключевых файлов.

## ImageBuilder и SourceBuilder

- Docker-образ modern ImageBuilder обновлен с Ubuntu 22.04 до Ubuntu 24.04, чтобы локальные ImageBuilder-архивы, собранные SourceBuilder на новом toolchain/glibc, запускались без ошибок `GLIBC_2.38 not found`.
- Добавлена ранняя проверка GLIBC-совместимости для локальных ImageBuilder-архивов: если контейнер слишком старый для host tools из архива, сборка падает сразу с понятной диагностикой.
- ImageBuilder теперь очищает рабочее дерево перед новой распаковкой SDK/ImageBuilder, чтобы не ловить состояние от прерванных предыдущих запусков.
- Улучшена совместимость с кастомными ImageBuilder-архивами без arch-деклараций в `repositories.conf`.
- Для APK-based ImageBuilder добавлена генерация `repositories`/`packages.adb` и проверка доступности пакетов до старта `make image`.
- Для локальных IPK-пакетов корректно пересоздается локальный индекс и ослабляется signature check только там, где это действительно нужно.
- Добавлен фикс порядка установки `libgcc1` для некоторых кастомных 24.10 ImageBuilder архивов.
- Улучшена обработка output ownership после сборок в Docker и Podman.
- SourceBuilder получил расширенный пример `hooks.sh` для профиля `rax3000m_emmc_test_new`.

## Профили

- Профиль `me.conf` переименован в нормализованное имя:
  - `cmcc_rax3000me_24105_iw_full.conf`
- Убрано проблемное зеркало `immortalwrt.kyarucloud.moe` из профилей, где оно ломало загрузку ImageBuilder.
- Исправлены Fantastic APK feeds для OpenWrt 25.12: профили переведены на актуальный `fantastic-packages.github.io/releases/25.12`.
- Добавлены новые профили OpenWrt 25.12:
  - `cudy_tr3000_256mb_v1_25124_ow_full`
  - `glinet_gl_mt3600be_25124_ow_full`
- Обновлены и вычищены проблемные пакеты в ряде профилей:
  - `cmcc_rax3000m_24105_ow_full`
  - `cmcc_rax3000me_24105_iw_full`
  - `giga_24105_main_full`
  - `giga_24105_rep_full`
  - `netcore_n60_pro_2410_pad`
  - `rax3000m_emmc_test_new`
- Исправлены профили, которые не собирались из-за устаревших, переименованных или недоступных пакетов.

## CI/CD и качество

- Добавлен полноценный workflow `.github/workflows/tests.yml`.
- Проверяются Linux, Windows, Docker smoke и Podman smoke.
- Добавлены проверки:
  - shell syntax;
  - ShellCheck;
  - синхронизация версии;
  - локализация RU/EN;
  - BOM expectations;
  - запрет global prune;
  - deterministic packer output;
  - unpacker smoke;
  - corrupt unpacker smoke;
  - docker compose smoke;
  - podman compose smoke.
- GitHub Actions обновлены на Node 24-совместимые версии:
  - `actions/checkout@v5`
  - `actions/upload-artifact@v6`
- При любом результате тестов выгружаются tester logs для Linux и Windows.

## Документация

- README обновлен под Docker/Podman runtime model.
- Добавлена доверенная модель профилей и пакетов: сторонние `.conf`, `hooks.sh`, патчи, репозитории и локальные пакеты считаются доверенным вводом.
- Архитектурная документация обновлена до версии 4.70.
- APK Scanner отмечен как часть ветки 4.70.

## Важные замечания

- По умолчанию используется `ROUTERFW_RUNTIME=auto`.
- Если в системе доступны оба движка, интерактивный запуск спросит выбор.
- Для автоматизации и CI лучше явно указывать runtime:

```bash
./_Builder.sh --runtime=docker build 1
./_Builder.sh --runtime=podman build 1
```

```bat
_Builder.bat --runtime=docker build 1
_Builder.bat --runtime=podman build 1
```

- В WSL нативная команда `podman` может отсутствовать, но если установлен Windows Podman, SH builder умеет использовать `podman.exe`.
- После обычного `git clone` на Linux права запуска могут зависеть от Git/FS. В CI права нормализуются через `chmod +x`.

## Итог

RouterFW 4.70 делает проект заметно надежнее для повседневной сборки: меньше ручных действий, больше проверок, безопаснее packer/unpacker, понятнее runtime-выбор и полноценная проверка Docker/Podman на CI.
