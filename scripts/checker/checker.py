#!/usr/bin/env python3
import subprocess
import concurrent.futures
import time
import sys
import threading
import os

# ================= НАСТРОЙКИ =================
INPUT_FILE = "tocheck.txt"
GOOD_FILE = "good_snis.txt"
BAD_FILE = "bad_snis.txt"
UNSTABLE_FILE = "unstable_snis.txt"

CHECKS_PER_DOMAIN = 10      # Сколько раз проверяем
DELAY_BETWEEN_CHECKS = 1   # Пауза (сек) между запросами к одному домену
CURL_TIMEOUT = 5           # Таймаут (сек)
MAX_THREADS = 50           # КОЛИЧЕСТВО ПОТОКОВ (ОДНОВРЕМЕННЫХ ПРОВЕРОК)
# =============================================

print_lock = threading.Lock()
done_count = 0
total_count = 0

def check_domain(domain):
    domain = domain.strip()
    if not domain:
        return None
    
    # Формируем URL
    url = f"https://{domain}" if not domain.startswith("http") else domain
    clean_domain = domain.split("//")[-1].split("/")[0] if "://" in domain else domain
    
    success_count = 0
    codes =[]
    
    # Делаем N проверок для одного домена
    for i in range(CHECKS_PER_DOMAIN):
        try:
            cmd =[
                "curl", "-s", "-o", "/dev/null", "-w", "%{http_code}", 
                "-m", str(CURL_TIMEOUT), "--tlsv1.3", url
            ]
            # Запускаем curl под капотом
            result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
            code = result.stdout.strip()
            if not code or not code.isdigit():
                code = "000"
        except Exception:
            code = "000"
            
        codes.append(code)
        if code != "000":
            success_count += 1
            
        if i < CHECKS_PER_DOMAIN - 1:
            time.sleep(DELAY_BETWEEN_CHECKS)
            
    # Анализируем результат
    codes_str = " ".join(codes)
    if success_count == CHECKS_PER_DOMAIN:
        status = "\033[32m[ОТЛИЧНО]\033[0m"
        file_dest = GOOD_FILE
    elif success_count == 0:
        status = "\033[31m[В МУСОР]\033[0m"
        file_dest = BAD_FILE
    else:
        status = "\033[33m[ПЛАВАЕТ]\033[0m"
        file_dest = UNSTABLE_FILE
        
    # Выравниваем текст для красоты
    result_text = f"{status} {clean_domain:<25} ({success_count}/{CHECKS_PER_DOMAIN}) | Коды: {codes_str}"
    return clean_domain, result_text, file_dest

def update_ui(result_text):
    global done_count
    done_count += 1
    # Блокировка вывода, чтобы потоки не перемешали текст в консоли
    with print_lock:
        # Стираем текущую строку (с прогресс-баром)
        sys.stdout.write('\r\033[K')
        # Печатаем результат завершенного домена
        sys.stdout.write(result_text + '\n')
        
        # Отрисовываем новый прогресс-бар в самом низу
        percent = done_count / total_count if total_count > 0 else 0
        bar_len = 30
        filled = int(bar_len * percent)
        bar = '█' * filled + '░' * (bar_len - filled)
        sys.stdout.write(f'\r\033[1;36m[ПРОГРЕСС]\033[0m [{bar}] {done_count}/{total_count} ({int(percent*100)}%)')
        sys.stdout.flush()

def main():
    global total_count
    
    if not os.path.exists(INPUT_FILE):
        print(f"❌ Файл {INPUT_FILE} не найден!")
        return
        
    with open(INPUT_FILE, 'r', encoding='utf-8') as f:
        domains = [line.strip() for line in f if line.strip()]
        
    total_count = len(domains)
    if total_count == 0:
        print("❌ Файл с доменами пуст!")
        return

    # Очищаем файлы перед стартом
    for f in (GOOD_FILE, BAD_FILE, UNSTABLE_FILE):
        open(f, 'w').close()

    print(f"🔍 Запуск проверки в {MAX_THREADS} потоков...")
    print("=" * 60)
    
    # Скрываем курсор для красоты и рисуем начальный бар
    sys.stdout.write("\033[?25l")
    sys.stdout.write(f'\r\033[1;36m[ПРОГРЕСС]\033[0m[{"░" * 30}] 0/{total_count} (0%)')
    sys.stdout.flush()

    try:
        # Запускаем ThreadPool (Пул потоков)
        with concurrent.futures.ThreadPoolExecutor(max_workers=MAX_THREADS) as executor:
            future_to_domain = {executor.submit(check_domain, dom): dom for dom in domains}
            
            for future in concurrent.futures.as_completed(future_to_domain):
                res = future.result()
                if res:
                    domain, result_text, file_dest = res
                    # Дописываем домен в нужный файл
                    with open(file_dest, 'a', encoding='utf-8') as f:
                        f.write(domain + '\n')
                    # Обновляем прогресс-бар и лог
                    update_ui(result_text)
    finally:
        # Возвращаем курсор по завершении (или при нажатии Ctrl+C)
        with print_lock:
            sys.stdout.write('\r\033[K')
            print("=" * 60)
            print("✅ Многопоточная проверка завершена!")
            print(f"🟢 Идеальные: {GOOD_FILE}")
            print(f"🟡 Плавающие: {UNSTABLE_FILE}")
            print(f"🔴 Мертвые:   {BAD_FILE}")
            sys.stdout.write("\033[?25h")
            sys.stdout.flush()

if __name__ == "__main__":
    main()
