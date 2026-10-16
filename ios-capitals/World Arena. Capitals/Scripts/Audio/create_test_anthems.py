#!/usr/bin/env python3
"""
Скрипт для создания тестовых аудиофайлов гимнов
Генерирует простые тональные сигналы для демонстрации функциональности
"""

import os
import subprocess
import json
from pathlib import Path

# Список стран для которых создаем гимны
COUNTRIES = [
    'at', 'be', 'ch', 'cz', 'de', 'dk', 'es', 'fi', 'fr', 'gb', 'gr', 'ie', 'it', 'nl', 'no', 'pl', 'pt', 'ru', 'se', 'ua',
    'us', 'ca', 'mx', 'br', 'ar', 'cn', 'jp', 'kr', 'in', 'th', 'za', 'eg', 'ng', 'ke', 'gh', 'au', 'nz', 'fj', 'pg', 'ws'
]

def create_test_anthem(country_code, duration=30):
    """Создает тестовый аудиофайл для страны"""
    output_dir = Path("real_anthems")
    output_dir.mkdir(exist_ok=True)
    
    output_file = output_dir / f"anthem_{country_code}.m4a"
    
    # Генерируем разные частоты для разных стран (чтобы файлы отличались)
    base_freq = 440 + (hash(country_code) % 200)  # 440-640 Hz
    
    # Создаем простой тональный сигнал с помощью ffmpeg
    cmd = [
        'ffmpeg', '-y',  # -y для перезаписи файла
        '-f', 'lavfi',   # Используем фильтр
        '-i', f'sine=frequency={base_freq}:duration={duration}',  # Синусоидальный сигнал
        '-c:a', 'aac',   # AAC кодек
        '-b:a', '192k',  # Битрейт 192k
        '-ar', '44100',  # Частота дискретизации 44.1kHz
        '-ac', '2',      # Стерео
        str(output_file)
    ]
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        print(f"✅ Создан тестовый гимн для {country_code.upper()}: {output_file}")
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ Ошибка создания гимна для {country_code}: {e}")
        return False

def create_manifest():
    """Создает манифест с информацией о загруженных гимнах"""
    output_dir = Path("real_anthems")
    manifest = {
        "total_countries": len(COUNTRIES),
        "downloaded_countries": len(COUNTRIES),
        "format": "M4A (AAC, 192kbps, 44.1kHz, Stereo)",
        "duration": "30 seconds",
        "type": "test_anthems",
        "description": "Тестовые аудиофайлы для демонстрации функциональности",
        "countries": []
    }
    
    for country_code in COUNTRIES:
        file_path = output_dir / f"anthem_{country_code}.m4a"
        if file_path.exists():
            file_size = file_path.stat().st_size
            manifest["countries"].append({
                "code": country_code,
                "filename": f"anthem_{country_code}.m4a",
                "size_bytes": file_size,
                "size_mb": round(file_size / (1024 * 1024), 2)
            })
    
    manifest_file = output_dir / "manifest.json"
    with open(manifest_file, 'w', encoding='utf-8') as f:
        json.dump(manifest, f, indent=2, ensure_ascii=False)
    
    print(f"📋 Создан манифест: {manifest_file}")

def main():
    """Основная функция"""
    print("🎵 Создание тестовых гимнов стран...")
    print("=" * 60)
    
    # Создаем папку для результатов
    output_dir = Path("real_anthems")
    output_dir.mkdir(exist_ok=True)
    
    success_count = 0
    
    for country_code in COUNTRIES:
        print(f"🎵 Создаю тестовый гимн для {country_code.upper()}...")
        if create_test_anthem(country_code):
            success_count += 1
    
    print("=" * 60)
    print(f"🎵 Создание завершено: {success_count}/{len(COUNTRIES)} гимнов успешно создано")
    
    # Создаем манифест
    create_manifest()
    
    # Проверяем результаты
    print("\n📊 Проверяю результаты создания...")
    m4a_files = list(output_dir.glob("*.m4a"))
    print(f"📁 Найдено {len(m4a_files)} M4A файлов")
    
    if m4a_files:
        total_size = sum(f.stat().st_size for f in m4a_files)
        print(f"📦 Общий размер: {total_size / (1024*1024):.1f} MB")
        print("✅ Тестовые гимны готовы к загрузке на сервер")
    else:
        print("❌ M4A файлы не найдены")

if __name__ == "__main__":
    main()

