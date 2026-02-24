#!/usr/bin/env python3
"""
Упрощенный скрипт для загрузки национальных гимнов
Использует открытые источники и библиотеки аудио
"""

import os
import json
import requests
import time
from pathlib import Path
import subprocess
import sys
from urllib.parse import urlparse, quote

# Конфигурация
OUTPUT_DIR = "real_anthems_final"
DURATION_LIMIT = 90  # Максимальная длительность в секундах

# Список источников для гимнов (открытые архивы)
ANTHEM_SOURCES = {
    "us": "https://upload.wikimedia.org/wikipedia/commons/e/e6/United_States_National_Anthem.ogg",
    "gb": "https://upload.wikimedia.org/wikipedia/commons/7/78/God_Save_the_Queen_instrumental.ogg",
    "fr": "https://upload.wikimedia.org/wikipedia/commons/6/6f/La_Marseillaise.ogg", 
    "de": "https://upload.wikimedia.org/wikipedia/commons/d/dd/Deutschlandlied_instrumental.ogg",
    "it": "https://upload.wikimedia.org/wikipedia/commons/0/07/Inno_di_Mameli_instrumental.ogg",
    "es": "https://upload.wikimedia.org/wikipedia/commons/9/99/Marcha_Real_-_instrumental_version.ogg",
    "ru": "https://upload.wikimedia.org/wikipedia/commons/f/f3/Anthem_of_Russia_piano.ogg",
    "cn": "https://upload.wikimedia.org/wikipedia/commons/f/fa/March_of_the_Volunteers_instrumental.ogg",
    "jp": "https://upload.wikimedia.org/wikipedia/commons/6/61/Kimi_ga_Yo_instrumental.ogg",
    "ca": "https://upload.wikimedia.org/wikipedia/commons/c/c8/O_Canada_instrumental.ogg",
    "au": "https://upload.wikimedia.org/wikipedia/commons/2/24/Advance_Australia_Fair_instrumental.ogg",
    "br": "https://upload.wikimedia.org/wikipedia/commons/9/9b/Hino_Nacional_Brasileiro_instrumental_Orquestra.ogg",
    "in": "https://upload.wikimedia.org/wikipedia/commons/9/94/Jana_Gana_Mana_instrumental.ogg",
    "mx": "https://upload.wikimedia.org/wikipedia/commons/0/02/Mexico_National_Anthem_instrumental.ogg",
    "ar": "https://upload.wikimedia.org/wikipedia/commons/2/23/Argentine_National_Anthem_instrumental.ogg",
    "nl": "https://upload.wikimedia.org/wikipedia/commons/d/d4/Wilhelmus_instrumental.ogg",
    "be": "https://upload.wikimedia.org/wikipedia/commons/7/7e/La_Brabanconne_instrumental.ogg",
    "ch": "https://upload.wikimedia.org/wikipedia/commons/9/96/Swiss_Psalm_instrumental.ogg",
    "at": "https://upload.wikimedia.org/wikipedia/commons/2/2a/Austria_National_Anthem_instrumental.ogg",
    "se": "https://upload.wikimedia.org/wikipedia/commons/8/8c/Du_gamla_Du_fria_instrumental.ogg",
    "no": "https://upload.wikimedia.org/wikipedia/commons/4/4f/Ja_vi_elsker_dette_landet_instrumental.ogg",
    "dk": "https://upload.wikimedia.org/wikipedia/commons/c/c6/Der_er_et_yndigt_land_instrumental.ogg",
    "fi": "https://upload.wikimedia.org/wikipedia/commons/d/d9/Maamme_instrumental.ogg",
    "pl": "https://upload.wikimedia.org/wikipedia/commons/e/e9/Mazurek_Dabrowskiego_instrumental.ogg",
    "cz": "https://upload.wikimedia.org/wikipedia/commons/0/0c/Kde_domov_muj_instrumental.ogg",
    "hu": "https://upload.wikimedia.org/wikipedia/commons/6/6f/Himnusz_instrumental.ogg",
    "gr": "https://upload.wikimedia.org/wikipedia/commons/5/5e/Ymnos_is_tin_Eleftherian_instrumental.ogg",
    "pt": "https://upload.wikimedia.org/wikipedia/commons/7/74/A_Portuguesa_instrumental.ogg",
    "ie": "https://upload.wikimedia.org/wikipedia/commons/4/4f/Amhran_na_bhFiann_instrumental.ogg",
    "ua": "https://upload.wikimedia.org/wikipedia/commons/4/49/Shche_ne_vmerla_Ukrainy_instrumental.ogg",
    "tr": "https://upload.wikimedia.org/wikipedia/commons/8/8c/Istiklal_Marsi_instrumental.ogg",
    "il": "https://upload.wikimedia.org/wikipedia/commons/c/c8/Hatikvah_instrumental.ogg",
    "eg": "https://upload.wikimedia.org/wikipedia/commons/f/f0/Bilady_Bilady_Bilady_instrumental.ogg",
    "za": "https://upload.wikimedia.org/wikipedia/commons/3/31/South_Africa_National_Anthem_instrumental.ogg",
    "ng": "https://upload.wikimedia.org/wikipedia/commons/1/1f/Arise_O_Compatriots_instrumental.ogg",
    "ke": "https://upload.wikimedia.org/wikipedia/commons/c/c8/Ee_Mungu_Nguvu_Yetu_instrumental.ogg",
    "gh": "https://upload.wikimedia.org/wikipedia/commons/2/21/God_Bless_Our_Homeland_Ghana_instrumental.ogg",
    "th": "https://upload.wikimedia.org/wikipedia/commons/3/3e/Phleng_Chat_Thai_instrumental.ogg",
    "kr": "https://upload.wikimedia.org/wikipedia/commons/1/1a/Aegukga_instrumental.ogg",
    "sg": "https://upload.wikimedia.org/wikipedia/commons/c/cb/Majulah_Singapura_instrumental.ogg",
    "my": "https://upload.wikimedia.org/wikipedia/commons/8/85/Negaraku_instrumental.ogg",
    "id": "https://upload.wikimedia.org/wikipedia/commons/f/f6/Indonesia_Raya_instrumental.ogg",
    "ph": "https://upload.wikimedia.org/wikipedia/commons/9/99/Lupang_Hinirang_instrumental.ogg",
    "vn": "https://upload.wikimedia.org/wikipedia/commons/5/5d/Tien_Quan_Ca_instrumental.ogg",
    "nz": "https://upload.wikimedia.org/wikipedia/commons/f/fe/God_Defend_New_Zealand_instrumental.ogg",
    "fj": "https://upload.wikimedia.org/wikipedia/commons/b/bc/God_Bless_Fiji_instrumental.ogg",
    "pg": "https://upload.wikimedia.org/wikipedia/commons/4/48/O_Arise_All_You_Sons_instrumental.ogg",
    "ws": "https://upload.wikimedia.org/wikipedia/commons/a/a7/The_Banner_of_Freedom_instrumental.ogg"
}

def setup_output_directory():
    """Создает выходную директорию"""
    output_path = Path(OUTPUT_DIR)
    output_path.mkdir(exist_ok=True)
    return output_path

def check_ffmpeg():
    """Проверяет наличие ffmpeg"""
    try:
        subprocess.run(['ffmpeg', '-version'], capture_output=True, check=True)
        return True
    except (subprocess.CalledProcessError, FileNotFoundError):
        return False

def download_file(url, output_path):
    """Загружает файл по URL"""
    try:
        print(f"📥 Загружаю: {url}")
        
        headers = {
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
        }
        
        response = requests.get(url, headers=headers, timeout=30)
        response.raise_for_status()
        
        with open(output_path, 'wb') as f:
            f.write(response.content)
        
        print(f"✅ Загружено: {output_path.name} ({len(response.content)/1024/1024:.2f} MB)")
        return True
        
    except Exception as e:
        print(f"❌ Ошибка загрузки: {str(e)}")
        return False

def convert_to_m4a(input_file, output_file):
    """Конвертирует аудиофайл в M4A используя ffmpeg"""
    try:
        print(f"🔄 Конвертирую {input_file.name} -> {output_file.name}")
        
        # Команда ffmpeg для конвертации в M4A
        cmd = [
            'ffmpeg',
            '-i', str(input_file),
            '-c:a', 'aac',
            '-b:a', '192k',
            '-ar', '44100',
            '-ac', '2',
            '-t', str(DURATION_LIMIT),  # Ограничение длительности
            '-y',  # Перезаписать существующий файл
            str(output_file)
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode == 0:
            print(f"✅ Конвертация успешна: {output_file.name}")
            return True
        else:
            print(f"❌ Ошибка конвертации: {result.stderr}")
            return False
            
    except Exception as e:
        print(f"❌ Ошибка конвертации: {str(e)}")
        return False

def create_manifest(output_path, successful_downloads):
    """Создает manifest.json с информацией о загруженных файлах"""
    manifest = {
        "total_countries": len(ANTHEM_SOURCES),
        "downloaded_countries": len(successful_downloads),
        "format": "M4A (AAC, 192kbps, 44.1kHz, Stereo)",
        "duration": f"up to {DURATION_LIMIT} seconds",
        "type": "real_anthems_wikimedia",
        "description": "Реальные национальные гимны из Wikimedia Commons",
        "source": "https://commons.wikimedia.org",
        "countries": []
    }
    
    for country_code in successful_downloads:
        file_path = output_path / f"anthem_{country_code}.m4a"
        if file_path.exists():
            file_size = file_path.stat().st_size
            manifest["countries"].append({
                "code": country_code,
                "filename": f"anthem_{country_code}.m4a",
                "size_bytes": file_size,
                "size_mb": round(file_size / 1024 / 1024, 2),
                "source_url": ANTHEM_SOURCES.get(country_code, "")
            })
    
    # Сортируем по коду страны
    manifest["countries"].sort(key=lambda x: x["code"])
    
    # Сохраняем manifest
    manifest_path = output_path / "manifest.json"
    with open(manifest_path, 'w', encoding='utf-8') as f:
        json.dump(manifest, f, indent=2, ensure_ascii=False)
    
    print(f"📄 Создан manifest: {manifest_path}")

def main():
    """Основная функция"""
    print("🎵 Загрузка реальных национальных гимнов из Wikimedia Commons")
    print("=" * 60)
    
    # Проверяем ffmpeg
    if not check_ffmpeg():
        print("❌ ffmpeg не найден!")
        print("Установите ffmpeg:")
        print("  macOS: brew install ffmpeg")
        print("  Ubuntu: sudo apt install ffmpeg")
        print("  Windows: скачайте с https://ffmpeg.org/")
        sys.exit(1)
    
    print("✅ ffmpeg найден")
    
    # Создаем выходную директорию
    output_path = setup_output_directory()
    print(f"📁 Выходная директория: {output_path}")
    
    successful_downloads = []
    failed_downloads = []
    
    # Загружаем гимны
    total_countries = len(ANTHEM_SOURCES)
    for i, (country_code, url) in enumerate(ANTHEM_SOURCES.items(), 1):
        print(f"\n[{i}/{total_countries}] Загружаю гимн {country_code.upper()}")
        
        # Проверяем, не существует ли уже файл
        final_file = output_path / f"anthem_{country_code}.m4a"
        if final_file.exists():
            print(f"⏭️ Файл уже существует: {final_file.name}")
            successful_downloads.append(country_code)
            continue
        
        # Определяем расширение исходного файла
        parsed_url = urlparse(url)
        original_ext = Path(parsed_url.path).suffix or '.ogg'
        temp_file = output_path / f"temp_{country_code}{original_ext}"
        
        try:
            # Загружаем исходный файл
            if download_file(url, temp_file):
                # Конвертируем в M4A
                if convert_to_m4a(temp_file, final_file):
                    successful_downloads.append(country_code)
                    print(f"✅ Готово: {country_code.upper()}")
                else:
                    failed_downloads.append(country_code)
                
                # Удаляем временный файл
                if temp_file.exists():
                    temp_file.unlink()
            else:
                failed_downloads.append(country_code)
        
        except Exception as e:
            print(f"❌ Ошибка обработки {country_code}: {str(e)}")
            failed_downloads.append(country_code)
            
            # Очищаем временные файлы
            if temp_file.exists():
                temp_file.unlink()
        
        # Пауза между загрузками
        time.sleep(1)
    
    # Создаем manifest
    create_manifest(output_path, successful_downloads)
    
    # Итоговая статистика
    print("\n" + "=" * 60)
    print("📊 РЕЗУЛЬТАТЫ ЗАГРУЗКИ")
    print("=" * 60)
    print(f"✅ Успешно загружено: {len(successful_downloads)} из {total_countries}")
    print(f"❌ Ошибки загрузки: {len(failed_downloads)}")
    
    if failed_downloads:
        print(f"\n❌ Не удалось загрузить:")
        for code in failed_downloads:
            print(f"   - {code.upper()}")
    
    print(f"\n📁 Файлы сохранены в: {output_path}")
    print(f"📄 Manifest: {output_path}/manifest.json")
    
    if successful_downloads:
        total_size = sum((output_path / f"anthem_{code}.m4a").stat().st_size 
                        for code in successful_downloads 
                        if (output_path / f"anthem_{code}.m4a").exists())
        print(f"💾 Общий размер: {total_size/1024/1024:.2f} MB")
        
        print(f"\n🚀 Для загрузки на сервер:")
        print(f"   cd '{output_path.parent}'")
        print(f"   ./upload_anthems_final.sh")

if __name__ == "__main__":
    main()

