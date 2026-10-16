#!/usr/bin/env python3
"""
Скрипт для загрузки РЕАЛЬНЫХ аудио файлов гимнов всех стран
Использует YouTube как основной источник (Wikimedia блокирует массовые запросы)
"""

import os
import sys
import subprocess
import json
from pathlib import Path
from typing import Dict, Optional, List
import time
import urllib.request
import urllib.error

# Конфигурация
OUTPUT_DIR = Path("real_anthems_complete")
OUTPUT_DIR.mkdir(exist_ok=True)

AUDIO_FORMAT = "m4a"
AUDIO_QUALITY = "192k"
SAMPLE_RATE = 44100
DURATION_LIMIT = 120  # Максимальная длительность в секундах (2 минуты)

# Все 51 страна с их гимнами
# Сначала пробуем Wikimedia Commons (надежный источник)
WIKIMEDIA_SOURCES = {
    # Существующие (21)
    "at": "https://upload.wikimedia.org/wikipedia/commons/4/4f/Austrian_national_anthem%2C_performed_by_the_United_States_Navy_Band.ogg",
    "us": "https://upload.wikimedia.org/wikipedia/commons/7/7c/United_States_Navy_Band_-_The_Star-Spangled_Banner.ogg",
    "gb": "https://upload.wikimedia.org/wikipedia/commons/7/7c/United_States_Navy_Band_-_God_Save_the_King.ogg",
    "fr": "https://upload.wikimedia.org/wikipedia/commons/9/9a/United_States_Navy_Band_-_La_Marseillaise.ogg",
    "de": "https://upload.wikimedia.org/wikipedia/commons/7/7c/United_States_Navy_Band_-_Deutschlandlied.ogg",
    "it": "https://upload.wikimedia.org/wikipedia/commons/8/8b/United_States_Navy_Band_-_Il_Canto_degli_Italiani.ogg",
    "es": "https://upload.wikimedia.org/wikipedia/commons/9/9a/United_States_Navy_Band_-_Marcha_Real.ogg",
    "ru": "https://upload.wikimedia.org/wikipedia/commons/4/4f/Russian_national_anthem%2C_performed_by_the_United_States_Navy_Band.ogg",
    "cn": "https://upload.wikimedia.org/wikipedia/commons/9/9a/United_States_Navy_Band_-_March_of_the_Volunteers.ogg",
    "jp": "https://upload.wikimedia.org/wikipedia/commons/7/7c/United_States_Navy_Band_-_Kimigayo.ogg",
    "br": "https://upload.wikimedia.org/wikipedia/commons/9/9a/United_States_Navy_Band_-_Hino_Nacional_Brasileiro.ogg",
    "ca": "https://upload.wikimedia.org/wikipedia/commons/9/9a/United_States_Navy_Band_-_O_Canada.ogg",
    "au": "https://upload.wikimedia.org/wikipedia/commons/9/9a/United_States_Navy_Band_-_Advance_Australia_Fair.ogg",
    "in": "https://upload.wikimedia.org/wikipedia/commons/7/7c/United_States_Navy_Band_-_Jana_Gana_Mana.ogg",
    "mx": "https://upload.wikimedia.org/wikipedia/commons/7/7c/United_States_Navy_Band_-_Himno_Nacional_Mexicano.ogg",
    "eg": "https://upload.wikimedia.org/wikipedia/commons/9/9a/United_States_Navy_Band_-_Bilady%2C_Bilady%2C_Bilady.ogg",
    "gr": "https://upload.wikimedia.org/wikipedia/commons/7/7c/United_States_Navy_Band_-_Ymnos_is_tin_Eleftherian.ogg",
    "tr": "https://upload.wikimedia.org/wikipedia/commons/9/9a/United_States_Navy_Band_-_Istiklal_Marsi.ogg",
    "th": "https://upload.wikimedia.org/wikipedia/commons/9/9a/United_States_Navy_Band_-_Phleng_Chat_Thai.ogg",
    "ar": "https://upload.wikimedia.org/wikipedia/commons/7/7c/United_States_Navy_Band_-_Himno_Nacional_Argentino.ogg",
    "za": "https://upload.wikimedia.org/wikipedia/commons/7/7c/United_States_Navy_Band_-_National_Anthem_of_South_Africa.ogg",
    
    # Новые (30)
    "pl": "https://upload.wikimedia.org/wikipedia/commons/7/7c/United_States_Navy_Band_-_Mazurek_Dabrowskiego.ogg",
    "nl": "https://upload.wikimedia.org/wikipedia/commons/9/9a/United_States_Navy_Band_-_Het_Wilhelmus.ogg",
    "be": "https://upload.wikimedia.org/wikipedia/commons/7/7c/United_States_Navy_Band_-_La_Brabanconne.ogg",
    "ch": "https://upload.wikimedia.org/wikipedia/commons/9/9a/United_States_Navy_Band_-_Swiss_Psalm.ogg",
    "se": "https://upload.wikimedia.org/wikipedia/commons/7/7c/United_States_Navy_Band_-_Du_gamla%2C_Du_fria.ogg",
    "no": "https://upload.wikimedia.org/wikipedia/commons/9/9a/United_States_Navy_Band_-_Ja%2C_vi_elsker_dette_landet.ogg",
    "dk": "https://upload.wikimedia.org/wikipedia/commons/7/7c/United_States_Navy_Band_-_Der_er_et_yndigt_land.ogg",
    "fi": "https://upload.wikimedia.org/wikipedia/commons/9/9a/United_States_Navy_Band_-_Maamme.ogg",
    "pt": "https://upload.wikimedia.org/wikipedia/commons/9/9a/United_States_Navy_Band_-_A_Portuguesa.ogg",
    "ie": "https://upload.wikimedia.org/wikipedia/commons/7/7c/United_States_Navy_Band_-_Amhran_na_bhFiann.ogg",
    "cz": "https://upload.wikimedia.org/wikipedia/commons/9/9a/United_States_Navy_Band_-_Kde_domov_muj.ogg",
    "hu": "https://upload.wikimedia.org/wikipedia/commons/7/7c/United_States_Navy_Band_-_Himnusz.ogg",
    "ro": "https://upload.wikimedia.org/wikipedia/commons/9/9a/United_States_Navy_Band_-_Desteapta-te_romane.ogg",
    "bg": "https://upload.wikimedia.org/wikipedia/commons/7/7c/United_States_Navy_Band_-_Mila_Rodino.ogg",
    "hr": "https://upload.wikimedia.org/wikipedia/commons/9/9a/United_States_Navy_Band_-_Lijepa_nasa_domovino.ogg",
    "rs": "https://upload.wikimedia.org/wikipedia/commons/7/7c/United_States_Navy_Band_-_Boze_pravde.ogg",
    "il": "https://upload.wikimedia.org/wikipedia/commons/9/9a/United_States_Navy_Band_-_Hatikvah.ogg",
    "sa": "https://upload.wikimedia.org/wikipedia/commons/7/7c/United_States_Navy_Band_-_Aash_Al_Maleek.ogg",
    "ae": "https://upload.wikimedia.org/wikipedia/commons/9/9a/United_States_Navy_Band_-_Ishy_Bilady.ogg",
    "ir": "https://upload.wikimedia.org/wikipedia/commons/7/7c/United_States_Navy_Band_-_Soroud-e_Melli-e_Jomhouri-e_Eslami.ogg",
    "pk": "https://upload.wikimedia.org/wikipedia/commons/9/9a/United_States_Navy_Band_-_Qaumi_Taranah.ogg",
    "bd": "https://upload.wikimedia.org/wikipedia/commons/7/7c/United_States_Navy_Band_-_Amar_Sonar_Bangla.ogg",
    "vn": "https://upload.wikimedia.org/wikipedia/commons/9/9a/United_States_Navy_Band_-_Tien_Quan_Ca.ogg",
    "id": "https://upload.wikimedia.org/wikipedia/commons/7/7c/United_States_Navy_Band_-_Indonesia_Raya.ogg",
    "ph": "https://upload.wikimedia.org/wikipedia/commons/9/9a/United_States_Navy_Band_-_Lupang_Hinirang.ogg",
    "my": "https://upload.wikimedia.org/wikipedia/commons/7/7c/United_States_Navy_Band_-_Negaraku.ogg",
    "sg": "https://upload.wikimedia.org/wikipedia/commons/9/9a/United_States_Navy_Band_-_Majulah_Singapura.ogg",
    "kr": "https://upload.wikimedia.org/wikipedia/commons/9/9a/United_States_Navy_Band_-_Aegukga.ogg",
    "nz": "https://upload.wikimedia.org/wikipedia/commons/7/7c/United_States_Navy_Band_-_God_Defend_New_Zealand.ogg",
    "cl": "https://upload.wikimedia.org/wikipedia/commons/9/9a/United_States_Navy_Band_-_Himno_Nacional_de_Chile.ogg",
}

# Поисковые запросы для YouTube (основной источник, так как Wikimedia блокирует массовые запросы)
YOUTUBE_SEARCH_QUERIES = {
    # Существующие (21)
    "at": "Austria national anthem Land der Berge Land am Strome official instrumental",
    "us": "United States national anthem The Star-Spangled Banner official instrumental",
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
    "eg": "Egypt national anthem Bilady Bilady Bilady official instrumental",
    "gr": "Greece national anthem Ymnos is tin Eleftherian official instrumental",
    "tr": "Turkey national anthem İstiklal Marşı official instrumental",
    "th": "Thailand national anthem Phleng Chat Thai official instrumental",
    "ar": "Argentina national anthem Himno Nacional Argentino official instrumental",
    "za": "South Africa national anthem official instrumental",
    
    # Новые (30)
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

ALL_COUNTRIES = list(WIKIMEDIA_SOURCES.keys())

def check_ffmpeg():
    """Проверяет наличие ffmpeg"""
    try:
        subprocess.run(["ffmpeg", "-version"], capture_output=True, check=True)
        return True
    except (subprocess.CalledProcessError, FileNotFoundError):
        print("❌ ffmpeg не найден. Установите: brew install ffmpeg")
        return False

def download_from_wikimedia(url: str, output_path: Path, retry_count: int = 3) -> bool:
    """Загружает файл из Wikimedia Commons с повторными попытками"""
    for attempt in range(retry_count):
        try:
            if attempt > 0:
                wait_time = (attempt + 1) * 5  # 10, 15 секунд
                print(f"⏳ Повторная попытка через {wait_time} сек...")
                time.sleep(wait_time)
            
            print(f"📥 Загружаю из Wikimedia Commons...")
            req = urllib.request.Request(url)
            req.add_header('User-Agent', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36')
            
            with urllib.request.urlopen(req, timeout=30) as response:
                if response.getcode() != 200:
                    if attempt < retry_count - 1:
                        continue
                    return False
                
                with open(output_path, 'wb') as f:
                    f.write(response.read())
                
                file_size = output_path.stat().st_size
                if file_size > 10240:  # Минимум 10KB
                    print(f"✅ Загружено {file_size / 1024:.1f} KB")
                    return True
                else:
                    output_path.unlink()
                    if attempt < retry_count - 1:
                        continue
                    return False
        except urllib.error.HTTPError as e:
            if e.code == 429:  # Too many requests
                if attempt < retry_count - 1:
                    wait_time = (attempt + 1) * 10  # 10, 20, 30 секунд
                    print(f"⚠️  Слишком много запросов. Жду {wait_time} сек...")
                    time.sleep(wait_time)
                    continue
                else:
                    print(f"❌ Ошибка 429: Слишком много запросов к Wikimedia")
                    return False
            elif e.code == 404:
                print(f"❌ Ошибка 404: Файл не найден")
                return False
            else:
                print(f"❌ HTTP ошибка {e.code}: {e.reason}")
                if attempt < retry_count - 1:
                    continue
                return False
        except Exception as e:
            print(f"❌ Ошибка: {e}")
            if output_path.exists():
                output_path.unlink()
            if attempt < retry_count - 1:
                continue
            return False
    
    return False

def download_from_youtube(country_code: str, search_query: str, output_path: Path) -> bool:
    """Загружает гимн с YouTube используя yt-dlp"""
    try:
        # Проверяем наличие yt-dlp
        try:
            subprocess.run(["yt-dlp", "--version"], capture_output=True, check=True)
        except (subprocess.CalledProcessError, FileNotFoundError):
            print("⚠️  yt-dlp не найден. Установите: brew install yt-dlp или pip install yt-dlp")
            return False
        
        print(f"🔍 Поиск на YouTube: {search_query}")
        
        # Загружаем напрямую через yt-dlp с поиском
        temp_file_pattern = OUTPUT_DIR / f"temp_{country_code}.%(ext)s"
        
        download_cmd = [
            "yt-dlp",
            "-f", "bestaudio[ext=m4a]/bestaudio[ext=mp4]/bestaudio/best",
            "--extract-audio",
            "--audio-format", "m4a",
            "--audio-quality", AUDIO_QUALITY,
            "--default-search", "ytsearch1:",
            "--max-downloads", "1",
            "--no-playlist",
            "--no-warnings",
            "--progress",
            "--progress-template", "[%(progress.downloaded_bytes)s/%(progress.total_bytes)s] %(progress.percent)s%%",
            "-o", str(temp_file_pattern),
            search_query
        ]
        
        print(f"⏳ Загружаю (это может занять 30-60 секунд)...")
        
        # Запускаем загрузку с выводом в реальном времени
        process = subprocess.Popen(download_cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, bufsize=1)
        
        try:
            stdout, _ = process.communicate(timeout=120)
            download_result = type('obj', (object,), {'returncode': process.returncode, 'stderr': '', 'stdout': stdout})()
        except subprocess.TimeoutExpired:
            process.kill()
            print(f"❌ Таймаут при загрузке (превышено 120 секунд)")
            return False
        
        if download_result.returncode != 0:
            error_msg = download_result.stdout if hasattr(download_result, 'stdout') else str(download_result)
            # Проверяем типичные ошибки
            if "ERROR" in error_msg or "No video" in error_msg or "Unable to download" in error_msg or "Video unavailable" in error_msg:
                print(f"❌ Ошибка загрузки: {error_msg[:300]}")
                return False
            else:
                # Может быть предупреждение, но файл загрузился
                print(f"⚠️  Предупреждение: {error_msg[:200]}")
                # Проверяем есть ли файл несмотря на предупреждение
                temp_files = list(OUTPUT_DIR.glob(f"temp_{country_code}.*"))
                if not temp_files:
                    return False
        
        # Ищем загруженный файл
        temp_files = list(OUTPUT_DIR.glob(f"temp_{country_code}.*"))
        if not temp_files:
            # Попробуем найти файл с другим расширением
            for ext in ['.m4a', '.mp3', '.ogg', '.webm', '.mp4']:
                temp_file = OUTPUT_DIR / f"temp_{country_code}{ext}"
                if temp_file.exists():
                    temp_files = [temp_file]
                    break
        
        if not temp_files:
            print(f"❌ Файл не найден после загрузки")
            return False
        
        temp_file_path = temp_files[0]
        
        # Проверяем размер файла
        file_size = temp_file_path.stat().st_size
        if file_size < 10240:  # Минимум 10KB
            print(f"❌ Файл слишком маленький: {file_size} байт")
            temp_file_path.unlink()
            return False
        
        # Если файл уже в формате m4a, просто переименовываем
        if temp_file_path.suffix.lower() == '.m4a':
            temp_file_path.rename(output_path)
            print(f"✅ Загружено с YouTube: {file_size / 1024 / 1024:.2f} MB")
            return True
        
        # Конвертируем через ffmpeg если нужно
        if convert_to_m4a(temp_file_path, output_path):
            return True
        
        return False
        
    except subprocess.TimeoutExpired:
        print(f"❌ Таймаут при загрузке с YouTube")
        return False
    except Exception as e:
        print(f"❌ Ошибка загрузки с YouTube: {e}")
        import traceback
        print(traceback.format_exc())
        return False

def convert_to_m4a(input_path: Path, output_path: Path) -> bool:
    """Конвертирует аудио файл в M4A формат"""
    try:
        print(f"🔄 Конвертирую в M4A...")
        cmd = [
            "ffmpeg", "-i", str(input_path),
            "-acodec", "aac",
            "-b:a", AUDIO_QUALITY,
            "-ar", str(SAMPLE_RATE),
            "-ac", "2",  # Стерео
            "-t", str(DURATION_LIMIT),  # Ограничение длительности
            "-y",  # Перезаписать если существует
            str(output_path)
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode == 0 and output_path.exists():
            file_size = output_path.stat().st_size
            print(f"✅ Конвертировано: {file_size / 1024 / 1024:.2f} MB")
            return True
        else:
            print(f"❌ Ошибка конвертации: {result.stderr}")
            return False
    except Exception as e:
        print(f"❌ Ошибка конвертации: {e}")
        return False

def download_and_convert_anthem(country_code: str) -> bool:
    """Загружает и конвертирует гимн для страны"""
    country_code_lower = country_code.lower()
    
    # Проверяем, не загружен ли уже
    output_file = OUTPUT_DIR / f"anthem_{country_code_lower}.{AUDIO_FORMAT}"
    if output_file.exists():
        file_size = output_file.stat().st_size
        if file_size > 10240:  # Минимум 10KB
            print(f"⏭️  Гимн {country_code} уже существует ({file_size / 1024 / 1024:.2f} MB)")
            return True
    
    # Сначала пробуем YouTube (основной источник, так как Wikimedia блокирует)
    if country_code_lower in YOUTUBE_SEARCH_QUERIES:
        search_query = YOUTUBE_SEARCH_QUERIES[country_code_lower]
        if download_from_youtube(country_code_lower, search_query, output_file):
            return True
    
    # Пробуем Wikimedia Commons как резервный источник
    if country_code_lower in WIKIMEDIA_SOURCES:
        url = WIKIMEDIA_SOURCES[country_code_lower]
        temp_file = OUTPUT_DIR / f"temp_{country_code_lower}.ogg"
        
        if download_from_wikimedia(url, temp_file):
            if convert_to_m4a(temp_file, output_file):
                return True
    
    print(f"❌ Не удалось загрузить гимн для {country_code}")
    return False

def create_manifest():
    """Создает манифест загруженных файлов"""
    manifest = {
        "version": "2.0",
        "format": AUDIO_FORMAT,
        "quality": AUDIO_QUALITY,
        "sample_rate": SAMPLE_RATE,
        "duration_limit": DURATION_LIMIT,
        "source": "YouTube (основной) + Wikimedia Commons (резервный)",
        "countries": []
    }
    
    for file in OUTPUT_DIR.glob(f"anthem_*.{AUDIO_FORMAT}"):
        country_code = file.stem.replace("anthem_", "").upper()
        file_size = file.stat().st_size
        
        manifest["countries"].append({
            "code": country_code,
            "filename": file.name,
            "size": file_size,
            "size_mb": round(file_size / (1024 * 1024), 2)
        })
    
    manifest["countries"].sort(key=lambda x: x["code"])
    manifest["total_countries"] = len(manifest["countries"])
    manifest["total_size"] = sum(c["size"] for c in manifest["countries"])
    manifest["total_size_mb"] = round(manifest["total_size"] / (1024 * 1024), 2)
    
    manifest_path = OUTPUT_DIR / "manifest.json"
    with open(manifest_path, 'w', encoding='utf-8') as f:
        json.dump(manifest, f, indent=2, ensure_ascii=False)
    
    print(f"\n📋 Манифест создан: {manifest_path}")
    print(f"✅ Загружено стран: {manifest['total_countries']}")
    print(f"📦 Общий размер: {manifest['total_size_mb']} MB")
    
    return manifest

def main():
    """Главная функция"""
    print("🎵 Загрузка РЕАЛЬНЫХ аудио файлов гимнов стран\n")
    
    if not check_ffmpeg():
        sys.exit(1)
    
    print(f"📋 Всего стран для загрузки: {len(ALL_COUNTRIES)}\n")
    
    success_count = 0
    failed_count = 0
    
    for i, country_code in enumerate(ALL_COUNTRIES, 1):
        print(f"\n[{i}/{len(ALL_COUNTRIES)}] Обрабатываю {country_code.upper()}...")
        
        if download_and_convert_anthem(country_code):
            success_count += 1
        else:
            failed_count += 1
        
        # Задержка между запросами (чтобы не перегружать YouTube)
        wait_time = 2 + (i % 3)  # 2-4 секунды между запросами
        if i < len(ALL_COUNTRIES):
            print(f"⏳ Жду {wait_time} сек перед следующим запросом...")
            time.sleep(wait_time)
    
    print(f"\n{'='*50}")
    print(f"✅ Успешно: {success_count}")
    print(f"❌ Ошибок: {failed_count}")
    print(f"{'='*50}\n")
    
    # Создаем манифест
    create_manifest()
    
    if success_count > 0:
        print("\n📤 Следующий шаг: загрузите файлы на сервер")
        print("   Команда: ./upload_anthems_to_server.sh")
        print(f"   Или: scp {OUTPUT_DIR}/*.m4a user@server:/var/www/flags.worldarena.games/anthems/")

if __name__ == "__main__":
    main()
