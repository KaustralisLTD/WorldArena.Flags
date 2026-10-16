#!/usr/bin/env python3
"""
Скрипт для проверки наличия аудио файлов гимнов на сервере
"""

import urllib.request
import urllib.error
from typing import List, Dict
import sys

# Список всех стран (51 страна)
ALL_COUNTRIES = [
    # Существующие (21)
    "at", "us", "gb", "fr", "de", "it", "es", "ru", "cn", "jp",
    "br", "ca", "au", "in", "mx", "eg", "gr", "tr", "th", "ar", "za",
    # Новые (30)
    "pl", "nl", "be", "ch", "se", "no", "dk", "fi", "pt", "ie",
    "cz", "hu", "ro", "bg", "hr", "rs", "il", "sa", "ae", "ir",
    "pk", "bd", "vn", "id", "ph", "my", "sg", "kr", "nz", "cl"
]

BASE_URL = "https://flags.worldarena.games/anthems"
TIMEOUT = 10

def check_file_exists(country_code: str) -> Dict[str, any]:
    """Проверяет наличие файла гимна на сервере"""
    url = f"{BASE_URL}/anthem_{country_code.lower()}.m4a"
    
    try:
        req = urllib.request.Request(url, method='HEAD')
        req.add_header('User-Agent', 'Mozilla/5.0')
        
        with urllib.request.urlopen(req, timeout=TIMEOUT) as response:
            status_code = response.getcode()
            
            if status_code == 200:
                size = response.headers.get('Content-Length', 'unknown')
                content_type = response.headers.get('Content-Type', 'unknown')
                
                return {
                    "exists": True,
                    "status": status_code,
                    "size": size,
                    "content_type": content_type,
                    "url": url
                }
            else:
                return {
                    "exists": False,
                    "status": status_code,
                    "url": url
                }
    except urllib.error.HTTPError as e:
        return {
            "exists": False,
            "status": e.code,
            "url": url
        }
    except Exception as e:
        return {
            "exists": False,
            "error": str(e),
            "url": url
        }

def main():
    """Главная функция"""
    print("🔍 Проверка наличия аудио файлов гимнов на сервере\n")
    print(f"🌐 Сервер: {BASE_URL}\n")
    print("=" * 70)
    
    existing_files = []
    missing_files = []
    errors = []
    
    total = len(ALL_COUNTRIES)
    
    for i, country_code in enumerate(ALL_COUNTRIES, 1):
        print(f"[{i}/{total}] Проверяю {country_code.upper()}...", end=" ", flush=True)
        
        result = check_file_exists(country_code)
        
        if result.get("exists"):
            size = result.get("size", "unknown")
            if size != "unknown":
                size_mb = int(size) / (1024 * 1024)
                print(f"✅ Найден ({size_mb:.1f} MB)")
            else:
                print("✅ Найден")
            existing_files.append((country_code, result))
        elif "error" in result:
            print(f"❌ Ошибка: {result['error']}")
            errors.append((country_code, result))
        else:
            print(f"❌ Не найден (HTTP {result.get('status', 'unknown')})")
            missing_files.append(country_code)
    
    print("\n" + "=" * 70)
    print("\n📊 Результаты проверки:\n")
    
    print(f"✅ Найдено файлов: {len(existing_files)}/{total}")
    print(f"❌ Отсутствует файлов: {len(missing_files)}/{total}")
    if errors:
        print(f"⚠️  Ошибок при проверке: {len(errors)}")
    
    if existing_files:
        print(f"\n✅ Найденные файлы ({len(existing_files)}):")
        for country_code, result in existing_files:
            size = result.get("size", "unknown")
            if size != "unknown":
                size_mb = int(size) / (1024 * 1024)
                print(f"   {country_code.upper()}: {size_mb:.1f} MB")
            else:
                print(f"   {country_code.upper()}: найден")
    
    if missing_files:
        print(f"\n❌ Отсутствующие файлы ({len(missing_files)}):")
        for country_code in missing_files:
            print(f"   {country_code.upper()}")
    
    if errors:
        print(f"\n⚠️  Ошибки при проверке ({len(errors)}):")
        for country_code, result in errors:
            print(f"   {country_code.upper()}: {result.get('error', 'unknown')}")
    
    # Статистика
    print("\n" + "=" * 70)
    print(f"\n📈 Статистика:")
    print(f"   Покрытие: {len(existing_files) * 100 / total:.1f}%")
    
    if len(existing_files) == total:
        print("\n🎉 Все файлы присутствуют на сервере!")
    elif len(existing_files) > 0:
        print(f"\n⚠️  Необходимо загрузить {len(missing_files)} файлов")
        print(f"   Используйте: python3 download_all_anthems.py")
        print(f"   Затем: ./upload_anthems_to_server.sh")
    else:
        print("\n❌ Файлы отсутствуют на сервере")
        print(f"   Необходимо загрузить все {total} файлов")
        print(f"   Используйте: python3 download_all_anthems.py")
        print(f"   Затем: ./upload_anthems_to_server.sh")
    
    # Возвращаем код выхода
    if len(existing_files) == total:
        sys.exit(0)
    else:
        sys.exit(1)

if __name__ == "__main__":
    main()
