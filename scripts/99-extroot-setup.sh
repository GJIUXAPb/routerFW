#!/bin/sh
# Professional Extroot Setup Script for OpenWrt v2.3 (Audited & Debuggable)
# Финальная версия: fstab копируется в текущий оверлей с флагом -f.

# === CONFIGURATION ===
DISK="/dev/mmcblk0"
PART_ROOT="${DISK}p6"
PART_SWAP="${DISK}p7"
SWAP_SIZE_GB="2"
VERSION="2.4"
# =====================

fail() {
    echo -e "\033[0;31m[ERROR] $1\033[0m" >&2
    exit 1
}

info() {
    echo -e "\033[0;32m[INFO] $1\033[0m"
}

info "--- Запуск Professional Extroot Script v${VERSION} ---"
info "Целевой диск: ${DISK}"

# 1. Проверка зависимостей
info "[Этап 1/4] Проверка зависимостей..."
PKGS=""
# blkid: нужен для поиска разделов по UUID - самый надежный способ.
command -v blkid >/dev/null || PKGS="$PKGS blkid"
# block-mount: критически важен, именно он обрабатывает /etc/config/fstab при загрузке.
if ! opkg list-installed | grep -q block-mount; then
    PKGS="$PKGS block-mount"
fi
# gptfdisk: содержит sgdisk, утилиту для неинтерактивного управления GPT. Ключ к надежности.
command -v sgdisk >/dev/null || PKGS="$PKGS gptfdisk"
# parted: содержит partprobe для перечитывания таблицы разделов без перезагрузки.
command -v partprobe >/dev/null || PKGS="$PKGS parted"

if [ -n "$PKGS" ]; then
    info "--> Установка недостающих пакетов: $PKGS"
    opkg update
    opkg install $PKGS || fail "Не удалось установить пакеты."
else
    info "--> Все зависимости на месте."
fi
info "[Этап 1/4] Зависимости в порядке."

# 2. Разметка диска (метод sgdisk)
# Мы используем sgdisk вместо fdisk, так как он предназначен для скриптов:
# - Неинтерактивный: не задает неожиданных вопросов.
# - Надежный: атомарно выполняет операции с GPT, умеет исправлять ошибки.
# - Идемпотентный: команды можно безопасно выполнять повторно.
info "[Этап 2/4] Проверка/создание разделов..."
if ! [ -b "$PART_SWAP" ]; then
    info "--> Раздел ${PART_SWAP} не найден. Требуется разметка."
    info "--> НАЧАЛО РАЗМЕТКИ ДИСКА (метод sgdisk)..."
    
    # --- Расчет геометрии диска ---
    DISK_NAME=${DISK##*/}
    TOTAL_SECTORS=$(cat /sys/class/block/${DISK_NAME}/size)
    SECTOR_SIZE=$(cat /sys/class/block/${DISK_NAME}/queue/hw_sector_size 2>/dev/null || echo 512)
    SWAP_SECTORS=$(awk "BEGIN {print int($SWAP_SIZE_GB * 1024 * 1024 * 1024 / $SECTOR_SIZE)}")
    SWAP_START=$(awk "BEGIN {print $TOTAL_SECTORS - $SWAP_SECTORS}")
    ROOT_END=$(awk "BEGIN {print $SWAP_START - 1}")
    # Начало раздела extroot (ROOT_START) жестко задано, т.к. оно следует сразу
    # за системными разделами и является константой для данной модели устройства.
    ROOT_START=1048576

    info "--> Геометрия диска: RootStart=${ROOT_START}, RootEnd=${ROOT_END}, SwapStart=${SWAP_START}"

    # --- Выполнение разметки ---
    # Удаляем старые разделы для чистоты. Ошибки игнорируем (> /dev/null 2>&1),
    # так как на чистой системе этих разделов и не будет.
    info "--> Удаление старых разделов p6 и p7 (если существуют)..."
    sgdisk --delete=7 "$DISK" >/dev/null 2>&1
    sgdisk --delete=6 "$DISK" >/dev/null 2>&1

    # Создаем раздел для extroot:
    # --new=<номер>:<начало>:<конец>
    # --change-name=<номер>:<имя>
    info "--> Создание раздела extroot (p6)..."
    sgdisk --new=6:${ROOT_START}:${ROOT_END} --change-name=6:extroot "$DISK" || fail "Не удалось создать раздел p6"
    
    # Создаем раздел для swap:
    # 0 в качестве конца означает "использовать все оставшееся место".
    # --typecode=<номер>:<GUID_типа> (8200 - стандартный код для Linux swap).
    info "--> Создание раздела swap (p7)..."
    sgdisk --new=7:${SWAP_START}:0 --change-name=7:swap --typecode=7:8200 "$DISK" || fail "Не удалось создать раздел p7"
    
    info "--> РАЗМЕТКА ДИСКА ЗАВЕРШЕНА."
    info "--> Обновление таблицы разделов в ядре с помощью partprobe..."
    partprobe "$DISK" || fail "Не удалось обновить таблицу разделов в ядре"
    sleep 2 # Даем ядру время обработать изменения
else
    info "--> Разделы уже существуют. Пропускаем разметку."
fi
info "[Этап 2/4] Разделы в порядке."


# 3. Форматирование
info "[Этап 3/4] Проверка/форматирование файловых систем..."
if ! blkid "$PART_ROOT" | grep -q 'TYPE="ext4"'; then
    info "--> Раздел ${PART_ROOT} не отформатирован. Форматирование в ext4..."
    mkfs.ext4 -F -L emmc_data "$PART_ROOT" || fail "Ошибка форматирования ext4"
    info "--> Форматирование ${PART_ROOT} завершено."
else
    info "--> Раздел ${PART_ROOT} уже отформатирован в ext4."
fi

if ! blkid "$PART_SWAP" | grep -q 'TYPE="swap"'; then
    info "--> Раздел ${PART_SWAP} не отформатирован. Создание swap..."
    mkswap "$PART_SWAP" || fail "Ошибка создания swap"
    info "--> Создание swap на ${PART_SWAP} завершено."
else
    info "--> Раздел ${PART_SWAP} уже является swap."
fi
info "[Этап 3/4] Файловые системы в порядке."


# 4. Настройка Extroot
info "[Этап 4/4] Проверка/настройка Extroot..."
CURRENT_OVERLAY_DEV=$(mount | grep 'on /overlay ' | awk '{print $1}')

if [ "$CURRENT_OVERLAY_DEV" != "$PART_ROOT" ]; then
    info "--> Extroot не активен на ${PART_ROOT}. Запуск финальной настройки..."

    # Ждем появления устройства, если partprobe отработал с задержкой
    i=0
    while [ $i -lt 10 ]; do
        [ -b "$PART_ROOT" ] && break
        sleep 1
        i=$((i+1))
    done
    [ -b "$PART_ROOT" ] || fail "Раздел $PART_ROOT так и не появился в системе."

    UUID_ROOT=$(blkid -o value -s UUID "$PART_ROOT")
    [ -z "$UUID_ROOT" ] && fail "Не удалось получить UUID для $PART_ROOT"
    info "--> UUID для ${PART_ROOT} найден: ${UUID_ROOT}"
    
    MNT="/mnt/new_extroot"
    mkdir -p "$MNT"
    info "--> Монтирование ${PART_ROOT} в ${MNT}..."
    mount "$PART_ROOT" "$MNT" || fail "Не удалось смонтировать $PART_ROOT"

    info "--> Копирование данных из /overlay в ${MNT}..."
    tar -C /overlay -cvf - . | tar -C "$MNT" -xf -

    # --- Создание чистого fstab ---
    info "--> Создание чистого fstab на новом разделе..."
    FSTAB_PATH="$MNT/upper/etc/config/fstab"

    # Генерируем новый, чистый fstab с помощью here-document.
    cat > "$FSTAB_PATH" <<EOF
config global
	option anon_swap '0'
	option anon_mount '0'
	option auto_swap '1'
	option auto_mount '1'
	option delay_root '10'
	option check_fs '1'

config mount
	option target '/overlay'
	option uuid '$UUID_ROOT'
	option enabled '1'

config swap
	option device '$PART_SWAP'
	option enabled '1'
EOF

    # === КЛЮЧЕВОЕ ИСПРАВЛЕНИЕ ===
    # Копируем созданный fstab в текущий оверлей, чтобы первая загрузка
    # увидела все инструкции (и extroot, и swap).
    info "--> Копирование нового fstab в текущую систему для первой загрузки..."
    cp -f "$FSTAB_PATH" /etc/config/fstab || fail "Не удалось скопировать fstab в /etc/config/"

    info "--> Отмонтирование ${MNT}..."
    umount "$MNT"
    
    info "--> Настройка завершена успешно. Финальная перезагрузка для активации."
    reboot    
    exit 0
else
    info "--> Extroot уже активен на ${PART_ROOT}. Никаких действий не требуется."
fi
info "[Этап 4/4] Extroot в порядке."

info "--- Скрипт настройки Extroot завершил работу. ---"
exit 0
