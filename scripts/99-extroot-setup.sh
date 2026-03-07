#!/bin/sh

# Функция для вывода ошибок и аварийного завершения.
# Скрипт uci-defaults не будет удален, что поможет в отладке.
fail() {
  echo "Error: $1" >&2
  exit 1
}

echo "--- Запуск скрипта настройки Extroot ---"

# --- Установка blkid ---
# Убедимся, что blkid установлен, он нам понадобится.
if ! command -v blkid >/dev/null; then
  echo "Установка blkid..."
  opkg update && opkg install blkid || fail "Не удалось установить blkid."
fi

# --- Этап 1: Разметка диска ---
# Если конечный раздел (/dev/mmcblk0p7) не существует, значит, разметку нужно выполнить.
if ! [ -b /dev/mmcblk0p7 ]; then
  echo "Этап 1: Создание разделов..."
  
  # Используем команды, которые мы отладили вручную.
  printf 'd
6
n

1048576
117932031
w
' | fdisk /dev/mmcblk0
  printf 'n



t
7
19
w
' | fdisk /dev/mmcblk0
  
  echo "Разделы созданы. Перезагрузка для применения новой таблицы разделов..."
  reboot
  exit 0
fi

# --- Этап 2: Форматирование ---
# Этот этап выполняется после первой перезагрузки.
# Проверяем, отформатирован ли раздел.
if ! blkid /dev/mmcblk0p6 | grep -q 'TYPE="ext4"'; then
  echo "Этап 2: Форматирование разделов..."
  mkfs.ext4 -L emmc_data /dev/mmcblk0p6 || fail "Не удалось отформатировать раздел ext4."
  mkswap /dev/mmcblk0p7 || fail "Не удалось отформатировать раздел swap."
fi

# --- Этап 3: Настройка и финальная перезагрузка ---
# Проверяем, не работает ли уже extroot на нужном устройстве.
CURRENT_OVERLAY_DEV=$(mount | grep 'on /overlay ' | cut -d' ' -f1)

if [ "$CURRENT_OVERLAY_DEV" != "/dev/mmcblk0p6" ]; then
  echo "Этап 3: Копирование данных и настройка fstab..."

  EXTROOT_DEV="/dev/mmcblk0p6"
  EXTROOT_UUID=$(blkid -o value -s UUID ${EXTROOT_DEV})
  [ -n "$EXTROOT_UUID" ] || fail "Не удалось получить UUID для ${EXTROOT_DEV}."

  MOUNT_POINT="/mnt/extroot"
  mkdir -p "${MOUNT_POINT}"
  
  if mount "${EXTROOT_DEV}" "${MOUNT_POINT}"; then
    echo "Копирование данных overlay..."
    tar -C /overlay -cvf - . | tar -C "${MOUNT_POINT}" -xf -
    
    # ВАЖНО: Изменяем fstab на новом, еще не активном разделе!
    echo "Настройка fstab на новом разделе..."
    FSTAB_PATH="${MOUNT_POINT}/upper/etc/config"
    uci -c "${FSTAB_PATH}" set fstab.@mount[1].uuid="${EXTROOT_UUID}"
    uci -c "${FSTAB_PATH}" set fstab.@mount[1].enabled='1'
    uci -c "${FSTAB_PATH}" delete fstab.swap.uuid # удаляем старый uuid, если есть
    uci -c "${FSTAB_PATH}" set fstab.swap.device='/dev/mmcblk0p7'
    uci -c "${FSTAB_PATH}" set fstab.swap.enabled='1'
    uci -c "${FSTAB_PATH}" commit fstab
    
    echo "Отмонтирование нового раздела..."
    umount "${MOUNT_POINT}"
  else
    fail "Не удалось смонтировать ${EXTROOT_DEV} в ${MOUNT_POINT}."
  fi
  
  echo "Extroot настроен. Финальная перезагрузка для его активации..."
  reboot
  exit 0
fi

echo "--- Настройка Extroot уже завершена. Скрипт отработал. ---"
exit 0
