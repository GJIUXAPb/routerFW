# RouterFW — Релиз 4.48

**Версия:** 4.48  
**Период изменений:** от тега 4.46 до текущего состояния

---

## Русский

### Что нового

- **Новая CLI-команда `check-clear`.**  
  Добавлена команда для удаления контрольных сумм из файлов:  
  — Без аргументов или с `all` — очищает `checksum:MD5` из всех файлов, перечисленных в unpacker, а также из самого unpacker.  
  — С указанным ID профиля — очищает checksum только из конкретного файла `profiles/<ID>.conf`.

- **Улучшение скриптов упаковщика (`_packer.sh`, `_packer.bat`).**  
  Теперь при упаковке генерируется таблица MD5-хешей для распаковщика.  
  MD5 каждого файла сохраняется и передается в unpacker для логирования при верификации.

- **Улучшение скриптов распаковщика (`_unpacker.sh`, `_unpacker.bat`).**  
  Теперь при восстановлении файлов в лог выводится MD5-хеш рядом с каждым файлом.  
  Формат: `[UNPACK] Recover: <filename> - md5(<hash>)`.

- **Обновление языковых словарей.**  
  В `system/lang/ru.env` и `system/lang/en.env` добавлен новый ключ `L_CLI_DESC_CHKSUM_CLEAR` для команды `check-clear`.  
  Обновлен текст ключа `L_CHKSUM_ALL_START`.

- **Обновление документации.**  
  Команда `check-clear` добавлена в таблицы CLI команд в файлах:  
  — `README.md`  
  — `README.en.md`  
  — `docs/ARCHITECTURE_diagram_ru.md`  
  — `docs/ARCHITECTURE_diagram_en.md`

- **Обновление архивов Docker Builder.**  
  Новые сборки:  
  — `routerFW_LinuxDockerBuilder_v01.03.2026_01-40.tar.gz`  
  — `routerFW_WinDockerBuilder_v01.03.2026_01-41.zip`

---

## English

### What's New

- **New CLI command `check-clear`.**  
  Added a command to remove checksums from files:  
  — Without arguments or with `all` — clears `checksum:MD5` from all files listed in the unpacker, plus the unpacker itself.  
  — With a specific profile ID — clears checksum only from that specific `profiles/<ID>.conf` file.

- **Enhanced packer scripts (`_packer.sh`, `_packer.bat`).**  
  Now generates an MD5 hash table for the unpacker during packaging.  
  Each file's MD5 is saved and passed to the unpacker for verification logging.

- **Enhanced unpacker scripts (`_unpacker.sh`, `_unpacker.bat`).**  
  Now displays the MD5 hash next to each recovered file in the log.  
  Format: `[UNPACK] Recover: <filename> - md5(<hash>)`.

- **Language dictionary updates.**  
  Added new key `L_CLI_DESC_CHKSUM_CLEAR` for the `check-clear` command to `system/lang/ru.env` and `system/lang/en.env`.  
  Updated the `L_CHKSUM_ALL_START` text.

- **Documentation updated.**  
  Added `check-clear` command to CLI tables in:  
  — `README.md`  
  — `README.en.md`  
  — `docs/ARCHITECTURE_diagram_ru.md`  
  — `docs/ARCHITECTURE_diagram_en.md`

- **Updated Docker Builder archives.**  
  New builds:  
  — `routerFW_LinuxDockerBuilder_v01.03.2026_01-40.tar.gz`  
  — `routerFW_WinDockerBuilder_v01.03.2026_01-41.zip`

---

*Release notes for GitHub — summary of changes from tag 4.46 to current 4.48.*
