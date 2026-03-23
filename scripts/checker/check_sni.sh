#!/bin/bash
# ver 0.2

# ================= НАСТРОЙКИ =================
INPUT_FILE="tocheck.txt"
GOOD_FILE="good_snis.txt"
BAD_FILE="bad_snis.txt"
UNSTABLE_FILE="unstable_snis.txt"

CHECKS_PER_DOMAIN=5    # Количество проверок подряд (N)
DELAY_BETWEEN_CHECKS=1 # Секунд между попытками (чтобы защита сайта не забанила curl)
CURL_TIMEOUT=5         # Таймаут одной попытки
# =============================================

if [ ! -f "$INPUT_FILE" ]; then
    echo "❌ Файл $INPUT_FILE не найден!"
    exit 1
fi

# Очищаем файлы
> "$GOOD_FILE"
> "$BAD_FILE"
> "$UNSTABLE_FILE"

echo "🔍 Начинаем проверку доменов (по $CHECKS_PER_DOMAIN раз каждый)..."
echo "=================================================="

while IFS= read -r domain || [ -n "$domain" ]; do
    if [ -z "$domain" ]; then continue; fi
    domain=$(echo "$domain" | xargs)

    if [[ ! "$domain" =~ ^https?:// ]]; then
        url="https://$domain"
    else
        url="$domain"
    fi

    success_count=0
    codes_history=""

    # Делаем N проверок подряд
    for (( i=1; i<=CHECKS_PER_DOMAIN; i++ )); do
        http_code=$(curl -s -o /dev/null -w "%{http_code}" -m "$CURL_TIMEOUT" --tlsv1.3 "$url")
        
        # Записываем код в историю (для наглядности)
        codes_history="$codes_history $http_code"

        if  [ "$http_code" != "000" ]; then
            ((success_count++))
        fi

        # Пауза между проверками (кроме последней итерации)
        if [ "$i" -lt "$CHECKS_PER_DOMAIN" ]; then
            sleep "$DELAY_BETWEEN_CHECKS"
        fi
    done

    # Анализируем результаты серии проверок
    if [ "$success_count" -eq "$CHECKS_PER_DOMAIN" ]; then
        # 100% успех
        echo -e "[\e[32mОТЛИЧНО\e[0m] $domain ($success_count/$CHECKS_PER_DOMAIN) | Коды:$codes_history"
        echo "$domain" >> "$GOOD_FILE"

    elif [ "$success_count" -eq 0 ]; then
        # 100% провал
        echo -e "[\e[31mВ МУСОР\e[0m] $domain ($success_count/$CHECKS_PER_DOMAIN) | Коды:$codes_history"
        echo "$domain" >> "$BAD_FILE"

    else
        # Плавающий результат
        echo -e "[\e[33mНЕСТАБИЛЬНО\e[0m] $domain ($success_count/$CHECKS_PER_DOMAIN) | Коды:$codes_history"
        echo "$domain" >> "$UNSTABLE_FILE"
    fi

done < <(tr -d '\r' < "$INPUT_FILE")

echo "=================================================="
echo "✅ Проверка завершена!"
echo "🟢 Идеальные: $GOOD_FILE"
echo "🟡 Плавающие: $UNSTABLE_FILE"
echo "🔴 Мертвые:   $BAD_FILE"