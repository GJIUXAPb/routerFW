#!/bin/bash

SEARCH_DIR="."

echo "Поиск файлов и папок, начинающихся с zz..."
echo "Директория: $(pwd)"
echo

find "$SEARCH_DIR" -name 'zz*' -print

echo
read -p "Удалить всё найденное? [y/N]: " answer

if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
    echo
    echo "Удаление..."
    find "$SEARCH_DIR" -name 'zz*' -exec rm -rf -- {} +
    echo "Готово."
else
    echo "Удаление отменено."
fi
