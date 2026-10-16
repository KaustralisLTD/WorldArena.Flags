#!/usr/bin/env python3
"""
Скрипт для загрузки реальных гимнов всех стран
Поддерживает загрузку из Wikimedia Commons и конвертацию в M4A формат
"""

import os
import sys
import requests
import subprocess
import json
from pathlib import Path
from typing import Dict, Optional
import time

# Конфигурация
OUTPUT_DIR = Path("real_anthems_all")
OUTPUT_DIR.mkdir(exist_ok=True)

# Формат вывода
AUDIO_FORMAT = "m4a"
AUDIO_QUALITY = "192k"
SAMPLE_RATE = 44100

# Все страны с их гимнами (51 страна: 21 существующая + 30 новых)
ANTHEM_SOURCES = {
    # Существующие страны (21)
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
    
    # Новые страны (30)
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

# Альтернативные источники (если основные недоступны)
ALTERNATIVE_SOURCES = {
    "pl": "https://ia800504.us.archive.org/15/items/national_anthems/poland_national_anthem.ogg",
    "nl": "https://ia800504.us.archive.org/15/items/national_anthems/netherlands_national_anthem.ogg",
    "be": "https://ia800504.us.archive.org/15/items/national_anthems/belgium_national_anthem.ogg",
    "ch": "https://ia800504.us.archive.org/15/items/national_anthems/switzerland_national_anthem.ogg",
    "se": "https://ia800504.us.archive.org/15/items/national_anthems/sweden_national_anthem.ogg",
    "no": "https://ia800504.us.archive.org/15/items/national_anthems/norway_national_anthem.ogg",
    "dk": "https://ia800504.us.archive.org/15/items/national_anthems/denmark_national_anthem.ogg",
    "fi": "https://ia800504.us.archive.org/15/items/national_anthems/finland_national_anthem.ogg",
    "pt": "https://ia800504.us.archive.org/15/items/national_anthems/portugal_national_anthem.ogg",
    "ie": "https://ia800504.us.archive.org/15/items/national_anthems/ireland_national_anthem.ogg",
    "cz": "https://ia800504.us.archive.org/15/items/national_anthems/czech_republic_national_anthem.ogg",
    "hu": "https://ia800504.us.archive.org/15/items/national_anthems/hungary_national_anthem.ogg",
    "ro": "https://ia800504.us.archive.org/15/items/national_anthems/romania_national_anthem.ogg",
    "bg": "https://ia800504.us.archive.org/15/items/national_anthems/bulgaria_national_anthem.ogg",
    "hr": "https://ia800504.us.archive.org/15/items/national_anthems/croatia_national_anthem.ogg",
    "rs": "https://ia800504.us.archive.org/15/items/national_anthems/serbia_national_anthem.ogg",
    "il": "https://ia800504.us.archive.org/15/items/national_anthems/israel_national_anthem.ogg",
    "sa": "https://ia800504.us.archive.org/15/items/national_anthems/saudi_arabia_national_anthem.ogg",
    "ae": "https://ia800504.us.archive.org/15/items/national_anthems/uae_national_anthem.ogg",
    "ir": "https://ia800504.us.archive.org/15/items/national_anthems/iran_national_anthem.ogg",
    "pk": "https://ia800504.us.archive.org/15/items/national_anthems/pakistan_national_anthem.ogg",
    "bd": "https://ia800504.us.archive.org/15/items/national_anthems/bangladesh_national_anthem.ogg",
    "vn": "https://ia800504.us.archive.org/15/items/national_anthems/vietnam_national_anthem.ogg",
    "id": "https://ia800504.us.archive.org/15/items/national_anthems/indonesia_national_anthem.ogg",
    "ph": "https://ia800504.us.archive.org/15/items/national_anthems/philippines_national_anthem.ogg",
    "my": "https://ia800504.us.archive.org/15/items/national_anthems/malaysia_national_anthem.ogg",
    "sg": "https://ia800504.us.archive.org/15/items/national_anthems/singapore_national_anthem.ogg",
    "kr": "https://ia800504.us.archive.org/15/items/national_anthems/south_korea_national_anthem.ogg",
    "nz": "https://ia800504.us.archive.org/15/items/national_anthems/new_zealand_national_anthem.ogg",
    "cl": "https://ia800504.us.archive.org/15/items/national_anthems/chile_national_anthem.ogg",
}

def check_ffmpeg():
    """Проверяет наличие ffmpeg"""
    try:
        subprocess.run(["ffmpeg", "-version"], capture_output=True, check=True)
        return True
    except (subprocess.CalledProcessError, FileNotFoundError):
        print("❌ ffmpeg не найден. Установите: brew install ffmpeg")
        return False

def download_file(url: str, output_path: Path) -> bool:
    """Загружает файл по URL"""
    try:
        print(f"📥 Загружаю {output_path.name}...")
        response = requests.get(url, timeout=30, stream=True)
        response.raise_for_status()
        
        with open(output_path, 'wb') as f:
            for chunk in response.iter_content(chunk_size=8192):
                f.write(chunk)
        
        file_size = output_path.stat().st_size
        print(f"✅ Загружено {file_size / 1024:.1f} KB")
        return True
    except Exception as e:
        print(f"❌ Ошибка загрузки: {e}")
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
            "-y",  # Перезаписать если существует
            str(output_path)
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode == 0 and output_path.exists():
            file_size = output_path.stat().st_size
            print(f"✅ Конвертировано: {file_size / 1024:.1f} KB")
            # Удаляем исходный файл
            input_path.unlink()
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
        print(f"⏭️  Гимн {country_code} уже существует, пропускаю")
        return True
    
    # Пробуем основной источник
    if country_code_lower in ANTHEM_SOURCES:
        url = ANTHEM_SOURCES[country_code_lower]
        temp_file = OUTPUT_DIR / f"temp_{country_code_lower}.ogg"
        
        if download_file(url, temp_file):
            if convert_to_m4a(temp_file, output_file):
                return True
    
    # Пробуем альтернативный источник
    if country_code_lower in ALTERNATIVE_SOURCES:
        url = ALTERNATIVE_SOURCES[country_code_lower]
        temp_file = OUTPUT_DIR / f"temp_{country_code_lower}_alt.ogg"
        
        if download_file(url, temp_file):
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
    print("🎵 Загрузка реальных гимнов стран\n")
    
    if not check_ffmpeg():
        sys.exit(1)
    
    # Все страны для загрузки
    all_countries = list(ANTHEM_SOURCES.keys())
    
    print(f"📋 Всего стран для загрузки: {len(all_countries)}\n")
    
    success_count = 0
    failed_count = 0
    
    for i, country_code in enumerate(all_countries, 1):
        print(f"\n[{i}/{len(all_countries)}] Обрабатываю {country_code.upper()}...")
        
        if download_and_convert_anthem(country_code):
            success_count += 1
        else:
            failed_count += 1
        
        # Небольшая задержка между запросами
        time.sleep(1)
    
    print(f"\n{'='*50}")
    print(f"✅ Успешно: {success_count}")
    print(f"❌ Ошибок: {failed_count}")
    print(f"{'='*50}\n")
    
    # Создаем манифест
    create_manifest()
    
    print("\n📤 Следующий шаг: загрузите файлы на сервер")
    print("   Команда: ./upload_to_server.sh")

if __name__ == "__main__":
    main()
