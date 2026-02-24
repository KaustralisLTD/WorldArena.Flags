#!/usr/bin/env python3
"""
Упрощенный скрипт для загрузки гимнов - загружает по одному с выводом прогресса
"""

import subprocess
import sys
from pathlib import Path
import time

OUTPUT_DIR = Path("real_anthems_complete")
OUTPUT_DIR.mkdir(exist_ok=True)

# Все страны
COUNTRIES = [
    "at", "us", "gb", "fr", "de", "it", "es", "ru", "cn", "jp",
    "br", "ca", "au", "in", "mx", "eg", "gr", "tr", "th", "ar", "za",
    "pl", "nl", "be", "ch", "se", "no", "dk", "fi", "pt", "ie",
    "cz", "hu", "ro", "bg", "hr", "rs", "il", "sa", "ae", "ir",
    "pk", "bd", "vn", "id", "ph", "my", "sg", "kr", "nz", "cl"
]

SEARCH_QUERIES = {
    "at": "Austria national anthem Land der Berge official instrumental",
    "us": "United States national anthem Star Spangled Banner official instrumental",
    "gb": "United Kingdom national anthem God Save the King official instrumental",
    "fr": "France national anthem La Marseillaise official instrumental",
    "de": "Germany national anthem Das Lied der Deutschen official instrumental",
    "it": "Italy national anthem Il Canto degli Italiani official instrumental",
    "es": "Spain national anthem Marcha Real official instrumental",
    "ru": "Russia national anthem State Anthem official instrumental",
    "cn": "China national anthem March of the Volunteers official instrumental",
    "jp": "Japan national anthem Kimigayo official instrumental",
    "br": "Brazil national anthem Hino Nacional Brasileiro official instrumental",
    "ca": "Canada national anthem O Canada official instrumental",
    "au": "Australia national anthem Advance Australia Fair official instrumental",
    "in": "India national anthem Jana Gana Mana official instrumental",
    "mx": "Mexico national anthem Himno Nacional Mexicano official instrumental",
    "eg": "Egypt national anthem Bilady official instrumental",
    "gr": "Greece national anthem Ymnos is tin Eleftherian official instrumental",
    "tr": "Turkey national anthem İstiklal Marşı official instrumental",
    "th": "Thailand national anthem Phleng Chat Thai official instrumental",
    "ar": "Argentina national anthem Himno Nacional Argentino official instrumental",
    "za": "South Africa national anthem official instrumental",
    "pl": "Poland national anthem Mazurek Dąbrowskiego official instrumental",
    "nl": "Netherlands national anthem Wilhelmus official instrumental",
    "be": "Belgium national anthem La Brabançonne official instrumental",
    "ch": "Switzerland national anthem Swiss Psalm official instrumental",
    "se": "Sweden national anthem Du gamla Du fria official instrumental",
    "no": "Norway national anthem Ja vi elsker dette landet official instrumental",
    "dk": "Denmark national anthem Der er et yndigt land official instrumental",
    "fi": "Finland national anthem Maamme official instrumental",
    "pt": "Portugal national anthem A Portuguesa official instrumental",
    "ie": "Ireland national anthem Amhrán na bhFiann official instrumental",
    "cz": "Czech Republic national anthem Kde domov můj official instrumental",
    "hu": "Hungary national anthem Himnusz official instrumental",
    "ro": "Romania national anthem Deșteaptă-te române official instrumental",
    "bg": "Bulgaria national anthem Mila Rodino official instrumental",
    "hr": "Croatia national anthem Lijepa naša domovino official instrumental",
    "rs": "Serbia national anthem Bože pravde official instrumental",
    "il": "Israel national anthem Hatikvah official instrumental",
    "sa": "Saudi Arabia national anthem Aash Al Maleek official instrumental",
    "ae": "United Arab Emirates national anthem Ishy Bilady official instrumental",
    "ir": "Iran national anthem Soroud-e Melli official instrumental",
    "pk": "Pakistan national anthem Qaumi Taranah official instrumental",
    "bd": "Bangladesh national anthem Amar Shonar Bangla official instrumental",
    "vn": "Vietnam national anthem Tiến Quân Ca official instrumental",
    "id": "Indonesia national anthem Indonesia Raya official instrumental",
    "ph": "Philippines national anthem Lupang Hinirang official instrumental",
    "my": "Malaysia national anthem Negaraku official instrumental",
    "sg": "Singapore national anthem Majulah Singapura official instrumental",
    "kr": "South Korea national anthem Aegukga official instrumental",
    "nz": "New Zealand national anthem God Defend New Zealand official instrumental",
    "cl": "Chile national anthem Himno Nacional de Chile official instrumental",
}

def download_anthem(country_code):
    """Загружает один гимн"""
    output_file = OUTPUT_DIR / f"anthem_{country_code}.m4a"
    
    # Проверяем если уже загружен
    if output_file.exists():
        file_size = output_file.stat().st_size
        # Если файл меньше 500KB - это скорее всего заглушка, перезагружаем
        MIN_SIZE_KB = 500 * 1024  # 500 KB минимум для реального гимна
        if file_size > MIN_SIZE_KB:
            size_mb = file_size / 1024 / 1024
            print(f"⏭️  {country_code.upper()} уже загружен ({size_mb:.2f} MB)")
            return True
        else:
            # Файл слишком маленький - это заглушка, удаляем и перезагружаем
            size_kb = file_size / 1024
            print(f"⚠️  {country_code.upper()} найден заглушка ({size_kb:.1f} KB), перезагружаю...")
            output_file.unlink()
    
    search_query = SEARCH_QUERIES.get(country_code, f"{country_code} national anthem official")
    
    print(f"\n{'='*60}")
    print(f"🎵 [{country_code.upper()}] Загружаю: {search_query}")
    print(f"{'='*60}")
    
    cmd = [
        "yt-dlp",
        "-f", "bestaudio[ext=m4a]/bestaudio[ext=mp4]/bestaudio",
        "--extract-audio",
        "--audio-format", "m4a",
        "--audio-quality", "192k",
        "--default-search", "ytsearch1:",
        "--max-downloads", "1",
        "--no-playlist",
        "-o", str(OUTPUT_DIR / f"temp_{country_code}.%(ext)s"),
        search_query
    ]
    
    try:
        # Запускаем с выводом в реальном времени
        process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, 
                                   text=True, bufsize=1, universal_newlines=True)
        
        # Читаем вывод построчно
        for line in process.stdout:
            if line.strip():
                print(f"  {line.strip()}")
        
        process.wait()
        
        # Ищем загруженный файл (даже если process.returncode != 0, файл может быть загружен)
        temp_files = list(OUTPUT_DIR.glob(f"temp_{country_code}.*"))
        if not temp_files:
            # Проверяем код возврата только если файл не найден
            if process.returncode != 0:
                print(f"❌ Ошибка загрузки {country_code.upper()} (код: {process.returncode})")
            else:
                print(f"❌ Файл не найден для {country_code.upper()}")
            return False
        
        temp_file = temp_files[0]
        
        # Проверяем размер файла
        file_size = temp_file.stat().st_size
        if file_size < 10240:  # Минимум 10KB
            print(f"❌ Файл слишком маленький: {file_size} байт")
            temp_file.unlink()
            return False
        
        # Переименовываем если уже в формате m4a
        if temp_file.suffix.lower() == '.m4a':
            temp_file.rename(output_file)
            size_mb = output_file.stat().st_size / 1024 / 1024
            print(f"✅ {country_code.upper()} загружен: {size_mb:.2f} MB")
            return True
        else:
            # Конвертируем через ffmpeg если другой формат
            print(f"🔄 Конвертирую {temp_file.suffix} -> m4a...")
            conv_cmd = [
                "ffmpeg", "-i", str(temp_file),
                "-acodec", "aac", "-b:a", "192k", "-ar", "44100", "-ac", "2",
                "-y", str(output_file)
            ]
            result = subprocess.run(conv_cmd, capture_output=True)
            temp_file.unlink()
            
            if result.returncode == 0 and output_file.exists():
                size_mb = output_file.stat().st_size / 1024 / 1024
                print(f"✅ {country_code.upper()} загружен: {size_mb:.2f} MB")
                return True
            else:
                print(f"❌ Ошибка конвертации {country_code.upper()}")
                return False
        
        return False
        
    except Exception as e:
        print(f"❌ Ошибка: {e}")
        return False

def main():
    print("🎵 Загрузка реальных гимнов стран")
    print(f"📋 Всего стран: {len(COUNTRIES)}\n")
    
    success = 0
    failed = 0
    
    for i, country in enumerate(COUNTRIES, 1):
        print(f"\n[{i}/{len(COUNTRIES)}] ", end="")
        
        if download_anthem(country):
            success += 1
        else:
            failed += 1
        
        # Пауза между запросами
        if i < len(COUNTRIES):
            wait = 2 + (i % 3)
            print(f"⏳ Жду {wait} сек...")
            time.sleep(wait)
    
    print(f"\n{'='*60}")
    print(f"✅ Успешно: {success}")
    print(f"❌ Ошибок: {failed}")
    print(f"{'='*60}")

if __name__ == "__main__":
    main()
