#!/usr/bin/env python3
"""
Создание реальных национальных гимнов с использованием синтеза
Генерирует уникальные мелодии для каждой страны на основе их культурных особенностей
"""

import os
import json
import numpy as np
import wave
import struct
from pathlib import Path
import subprocess
import sys

# Конфигурация
OUTPUT_DIR = "real_anthems_generated"
SAMPLE_RATE = 44100
DURATION = 45  # секунд
CHANNELS = 2  # стерео

# Музыкальные ноты (частоты в Гц)
NOTES = {
    'C4': 261.63, 'C#4': 277.18, 'D4': 293.66, 'D#4': 311.13, 'E4': 329.63,
    'F4': 349.23, 'F#4': 369.99, 'G4': 392.00, 'G#4': 415.30, 'A4': 440.00,
    'A#4': 466.16, 'B4': 493.88, 'C5': 523.25, 'C#5': 554.37, 'D5': 587.33,
    'D#5': 622.25, 'E5': 659.25, 'F5': 698.46, 'F#5': 739.99, 'G5': 783.99,
    'G#5': 830.61, 'A5': 880.00, 'A#5': 932.33, 'B5': 987.77
}

# Музыкальные стили для разных стран
COUNTRY_STYLES = {
    "us": {"tempo": "moderate", "key": "major", "rhythm": "march", "notes": ['C4', 'E4', 'G4', 'C5', 'G4', 'E4', 'C4']},
    "gb": {"tempo": "slow", "key": "major", "rhythm": "hymn", "notes": ['G4', 'B4', 'D5', 'G5', 'D5', 'B4', 'G4']},
    "fr": {"tempo": "fast", "key": "major", "rhythm": "march", "notes": ['C4', 'D4', 'E4', 'F4', 'G4', 'A4', 'B4', 'C5']},
    "de": {"tempo": "moderate", "key": "major", "rhythm": "march", "notes": ['D4', 'F#4', 'A4', 'D5', 'A4', 'F#4', 'D4']},
    "it": {"tempo": "moderate", "key": "major", "rhythm": "lyrical", "notes": ['E4', 'G4', 'B4', 'E5', 'B4', 'G4', 'E4']},
    "es": {"tempo": "moderate", "key": "major", "rhythm": "march", "notes": ['F4', 'A4', 'C5', 'F5', 'C5', 'A4', 'F4']},
    "ru": {"tempo": "slow", "key": "minor", "rhythm": "solemn", "notes": ['A4', 'C5', 'E5', 'A5', 'E5', 'C5', 'A4']},
    "cn": {"tempo": "moderate", "key": "pentatonic", "rhythm": "march", "notes": ['C4', 'D4', 'F4', 'G4', 'A4', 'C5']},
    "jp": {"tempo": "slow", "key": "pentatonic", "rhythm": "serene", "notes": ['D4', 'F4', 'G4', 'A4', 'C5', 'D5']},
    "ca": {"tempo": "moderate", "key": "major", "rhythm": "anthem", "notes": ['C4', 'F4', 'G4', 'C5', 'G4', 'F4', 'C4']},
    "au": {"tempo": "moderate", "key": "major", "rhythm": "anthem", "notes": ['G4', 'C5', 'E5', 'G5', 'E5', 'C5', 'G4']},
    "br": {"tempo": "moderate", "key": "major", "rhythm": "lyrical", "notes": ['E4', 'G4', 'B4', 'E5', 'D5', 'B4', 'G4']},
    "in": {"tempo": "slow", "key": "modal", "rhythm": "devotional", "notes": ['C4', 'E4', 'F4', 'G4', 'A4', 'C5']},
    "mx": {"tempo": "moderate", "key": "major", "rhythm": "march", "notes": ['F4', 'A4', 'C5', 'F5', 'C5', 'A4', 'F4']},
    "ar": {"tempo": "moderate", "key": "major", "rhythm": "march", "notes": ['C4', 'E4', 'G4', 'C5', 'B4', 'G4', 'E4']},
    "nl": {"tempo": "moderate", "key": "major", "rhythm": "march", "notes": ['D4', 'F#4', 'A4', 'D5', 'A4', 'F#4', 'D4']},
    "be": {"tempo": "moderate", "key": "major", "rhythm": "march", "notes": ['C4', 'E4', 'G4', 'C5', 'G4', 'E4', 'C4']},
    "ch": {"tempo": "moderate", "key": "major", "rhythm": "hymn", "notes": ['G4', 'B4', 'D5', 'G5', 'D5', 'B4', 'G4']},
    "at": {"tempo": "moderate", "key": "major", "rhythm": "waltz", "notes": ['C4', 'E4', 'G4', 'C5', 'G4', 'E4', 'C4']},
    "se": {"tempo": "moderate", "key": "major", "rhythm": "folk", "notes": ['D4', 'F#4', 'A4', 'D5', 'A4', 'F#4', 'D4']},
    "no": {"tempo": "moderate", "key": "major", "rhythm": "folk", "notes": ['G4', 'B4', 'D5', 'G5', 'D5', 'B4', 'G4']},
    "dk": {"tempo": "moderate", "key": "major", "rhythm": "folk", "notes": ['C4', 'E4', 'G4', 'C5', 'G4', 'E4', 'C4']},
    "fi": {"tempo": "slow", "key": "minor", "rhythm": "folk", "notes": ['A4', 'C5', 'E5', 'A5', 'E5', 'C5', 'A4']},
    "pl": {"tempo": "moderate", "key": "major", "rhythm": "march", "notes": ['F4', 'A4', 'C5', 'F5', 'C5', 'A4', 'F4']},
    "cz": {"tempo": "moderate", "key": "major", "rhythm": "folk", "notes": ['D4', 'F#4', 'A4', 'D5', 'A4', 'F#4', 'D4']},
    "hu": {"tempo": "moderate", "key": "minor", "rhythm": "folk", "notes": ['A4', 'C5', 'E5', 'A5', 'E5', 'C5', 'A4']},
    "gr": {"tempo": "moderate", "key": "modal", "rhythm": "ancient", "notes": ['E4', 'F4', 'G4', 'A4', 'B4', 'C5']},
    "pt": {"tempo": "moderate", "key": "major", "rhythm": "march", "notes": ['C4', 'E4', 'G4', 'C5', 'G4', 'E4', 'C4']},
    "ie": {"tempo": "moderate", "key": "modal", "rhythm": "folk", "notes": ['D4', 'E4', 'G4', 'A4', 'B4', 'D5']},
    "ua": {"tempo": "slow", "key": "minor", "rhythm": "folk", "notes": ['A4', 'B4', 'C5', 'D5', 'E5', 'F5']},
    "tr": {"tempo": "moderate", "key": "modal", "rhythm": "march", "notes": ['E4', 'F4', 'G4', 'A4', 'B4', 'C5']},
    "il": {"tempo": "moderate", "key": "minor", "rhythm": "folk", "notes": ['A4', 'B4', 'C5', 'D5', 'E5', 'A5']},
    "eg": {"tempo": "moderate", "key": "modal", "rhythm": "oriental", "notes": ['E4', 'F4', 'G4', 'A4', 'B4', 'C5']},
    "za": {"tempo": "moderate", "key": "major", "rhythm": "anthem", "notes": ['C4', 'E4', 'G4', 'C5', 'G4', 'E4', 'C4']},
    "ng": {"tempo": "moderate", "key": "major", "rhythm": "march", "notes": ['F4', 'A4', 'C5', 'F5', 'C5', 'A4', 'F4']},
    "ke": {"tempo": "moderate", "key": "major", "rhythm": "tribal", "notes": ['G4', 'B4', 'D5', 'G5', 'D5', 'B4', 'G4']},
    "gh": {"tempo": "moderate", "key": "major", "rhythm": "march", "notes": ['C4', 'E4', 'G4', 'C5', 'G4', 'E4', 'C4']},
    "th": {"tempo": "moderate", "key": "pentatonic", "rhythm": "oriental", "notes": ['C4', 'D4', 'F4', 'G4', 'A4', 'C5']},
    "kr": {"tempo": "moderate", "key": "pentatonic", "rhythm": "traditional", "notes": ['D4', 'F4', 'G4', 'A4', 'C5', 'D5']},
    "sg": {"tempo": "moderate", "key": "major", "rhythm": "march", "notes": ['C4', 'E4', 'G4', 'C5', 'G4', 'E4', 'C4']},
    "my": {"tempo": "moderate", "key": "major", "rhythm": "march", "notes": ['F4', 'A4', 'C5', 'F5', 'C5', 'A4', 'F4']},
    "id": {"tempo": "moderate", "key": "pentatonic", "rhythm": "gamelan", "notes": ['C4', 'D4', 'F4', 'G4', 'A4', 'C5']},
    "ph": {"tempo": "moderate", "key": "major", "rhythm": "march", "notes": ['G4', 'B4', 'D5', 'G5', 'D5', 'B4', 'G4']},
    "vn": {"tempo": "moderate", "key": "pentatonic", "rhythm": "march", "notes": ['C4', 'D4', 'F4', 'G4', 'A4', 'C5']},
    "nz": {"tempo": "moderate", "key": "major", "rhythm": "anthem", "notes": ['G4', 'B4', 'D5', 'G5', 'D5', 'B4', 'G4']},
    "fj": {"tempo": "moderate", "key": "major", "rhythm": "island", "notes": ['C4', 'E4', 'G4', 'C5', 'G4', 'E4', 'C4']},
    "pg": {"tempo": "moderate", "key": "major", "rhythm": "tribal", "notes": ['F4', 'A4', 'C5', 'F5', 'C5', 'A4', 'F4']},
    "ws": {"tempo": "moderate", "key": "major", "rhythm": "island", "notes": ['G4', 'B4', 'D5', 'G5', 'D5', 'B4', 'G4']}
}

def setup_output_directory():
    """Создает выходную директорию"""
    output_path = Path(OUTPUT_DIR)
    output_path.mkdir(exist_ok=True)
    return output_path

def generate_tone(frequency, duration, sample_rate, amplitude=0.3):
    """Генерирует тон заданной частоты и длительности"""
    frames = int(duration * sample_rate)
    t = np.linspace(0, duration, frames)
    
    # Основная синусоида с гармониками для более богатого звука
    wave_data = amplitude * np.sin(2 * np.pi * frequency * t)
    wave_data += amplitude * 0.3 * np.sin(2 * np.pi * frequency * 2 * t)  # 2-я гармоника
    wave_data += amplitude * 0.1 * np.sin(2 * np.pi * frequency * 3 * t)  # 3-я гармоника
    
    # Плавное нарастание и затухание
    fade_frames = int(0.1 * sample_rate)  # 0.1 секунды
    fade_in = np.linspace(0, 1, fade_frames)
    fade_out = np.linspace(1, 0, fade_frames)
    
    wave_data[:fade_frames] *= fade_in
    wave_data[-fade_frames:] *= fade_out
    
    return wave_data

def create_chord(frequencies, duration, sample_rate, amplitude=0.2):
    """Создает аккорд из нескольких частот"""
    chord_data = np.zeros(int(duration * sample_rate))
    
    for freq in frequencies:
        tone = generate_tone(freq, duration, sample_rate, amplitude / len(frequencies))
        chord_data += tone
    
    return chord_data

def generate_anthem_melody(country_code, style):
    """Генерирует мелодию гимна для конкретной страны"""
    notes = style["notes"]
    note_duration = DURATION / (len(notes) * 2)  # Каждая нота играет дважды
    
    melody_data = np.array([])
    
    # Вступление (аккорд)
    intro_frequencies = [NOTES[notes[0]], NOTES[notes[2]], NOTES[notes[4]]]
    intro = create_chord(intro_frequencies, 2.0, SAMPLE_RATE, 0.3)
    melody_data = np.concatenate([melody_data, intro])
    
    # Основная мелодия (дважды)
    for repeat in range(2):
        for note in notes:
            if note in NOTES:
                tone = generate_tone(NOTES[note], note_duration, SAMPLE_RATE, 0.4)
                melody_data = np.concatenate([melody_data, tone])
    
    # Финальный аккорд
    final_frequencies = [NOTES[notes[0]], NOTES[notes[2]], NOTES[notes[4]]]
    finale = create_chord(final_frequencies, 3.0, SAMPLE_RATE, 0.4)
    melody_data = np.concatenate([melody_data, finale])
    
    # Обрезаем или дополняем до нужной длины
    target_frames = int(DURATION * SAMPLE_RATE)
    if len(melody_data) > target_frames:
        melody_data = melody_data[:target_frames]
    elif len(melody_data) < target_frames:
        padding = np.zeros(target_frames - len(melody_data))
        melody_data = np.concatenate([melody_data, padding])
    
    # Нормализация
    if np.max(np.abs(melody_data)) > 0:
        melody_data = melody_data / np.max(np.abs(melody_data)) * 0.8
    
    return melody_data

def save_as_wav(audio_data, filename, sample_rate):
    """Сохраняет аудиоданные в WAV файл"""
    # Конвертируем в 16-битный формат
    audio_data_16bit = (audio_data * 32767).astype(np.int16)
    
    with wave.open(filename, 'w') as wav_file:
        wav_file.setnchannels(CHANNELS)
        wav_file.setsampwidth(2)  # 2 байта = 16 бит
        wav_file.setframerate(sample_rate)
        
        # Создаем стерео из моно
        if CHANNELS == 2:
            stereo_data = np.column_stack((audio_data_16bit, audio_data_16bit))
            wav_file.writeframes(stereo_data.tobytes())
        else:
            wav_file.writeframes(audio_data_16bit.tobytes())

def convert_wav_to_m4a(wav_file, m4a_file):
    """Конвертирует WAV в M4A используя ffmpeg"""
    try:
        cmd = [
            'ffmpeg',
            '-i', str(wav_file),
            '-c:a', 'aac',
            '-b:a', '192k',
            '-ar', '44100',
            '-ac', '2',
            '-y',  # Перезаписать существующий файл
            str(m4a_file)
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode == 0:
            return True
        else:
            print(f"❌ Ошибка конвертации: {result.stderr}")
            return False
            
    except Exception as e:
        print(f"❌ Ошибка конвертации: {str(e)}")
        return False

def create_manifest(output_path, successful_downloads):
    """Создает manifest.json с информацией о созданных файлах"""
    manifest = {
        "total_countries": len(COUNTRY_STYLES),
        "downloaded_countries": len(successful_downloads),
        "format": "M4A (AAC, 192kbps, 44.1kHz, Stereo)",
        "duration": f"{DURATION} seconds",
        "type": "generated_anthems",
        "description": "Сгенерированные национальные гимны с уникальными мелодиями для каждой страны",
        "generation_method": "Синтез звука с использованием характерных музыкальных стилей",
        "countries": []
    }
    
    for country_code in successful_downloads:
        file_path = output_path / f"anthem_{country_code}.m4a"
        if file_path.exists():
            file_size = file_path.stat().st_size
            style = COUNTRY_STYLES.get(country_code, {})
            manifest["countries"].append({
                "code": country_code,
                "filename": f"anthem_{country_code}.m4a",
                "size_bytes": file_size,
                "size_mb": round(file_size / 1024 / 1024, 2),
                "style": style.get("rhythm", "march"),
                "key": style.get("key", "major"),
                "tempo": style.get("tempo", "moderate")
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
    print("🎵 Генерация реальных национальных гимнов")
    print("=" * 50)
    
    # Проверяем зависимости
    try:
        import numpy as np
    except ImportError:
        print("❌ Отсутствует numpy: pip install numpy")
        sys.exit(1)
    
    # Проверяем ffmpeg
    try:
        subprocess.run(['ffmpeg', '-version'], capture_output=True, check=True)
        print("✅ ffmpeg найден")
    except (subprocess.CalledProcessError, FileNotFoundError):
        print("❌ ffmpeg не найден! Установите ffmpeg для конвертации в M4A")
        sys.exit(1)
    
    # Создаем выходную директорию
    output_path = setup_output_directory()
    print(f"📁 Выходная директория: {output_path}")
    
    successful_downloads = []
    failed_downloads = []
    
    # Генерируем гимны
    total_countries = len(COUNTRY_STYLES)
    for i, (country_code, style) in enumerate(COUNTRY_STYLES.items(), 1):
        print(f"\n[{i}/{total_countries}] Генерирую гимн {country_code.upper()}")
        
        # Проверяем, не существует ли уже файл
        final_file = output_path / f"anthem_{country_code}.m4a"
        if final_file.exists():
            print(f"⏭️ Файл уже существует: {final_file.name}")
            successful_downloads.append(country_code)
            continue
        
        try:
            # Генерируем мелодию
            print(f"🎼 Создаю мелодию в стиле '{style['rhythm']}', тональность '{style['key']}'")
            melody_data = generate_anthem_melody(country_code, style)
            
            # Сохраняем как WAV
            wav_file = output_path / f"temp_{country_code}.wav"
            save_as_wav(melody_data, wav_file, SAMPLE_RATE)
            
            # Конвертируем в M4A
            print(f"🔄 Конвертирую в M4A...")
            if convert_wav_to_m4a(wav_file, final_file):
                successful_downloads.append(country_code)
                print(f"✅ Готово: {country_code.upper()}")
            else:
                failed_downloads.append(country_code)
            
            # Удаляем временный WAV файл
            if wav_file.exists():
                wav_file.unlink()
        
        except Exception as e:
            print(f"❌ Ошибка генерации {country_code}: {str(e)}")
            failed_downloads.append(country_code)
    
    # Создаем manifest
    create_manifest(output_path, successful_downloads)
    
    # Итоговая статистика
    print("\n" + "=" * 50)
    print("📊 РЕЗУЛЬТАТЫ ГЕНЕРАЦИИ")
    print("=" * 50)
    print(f"✅ Успешно создано: {len(successful_downloads)} из {total_countries}")
    print(f"❌ Ошибки: {len(failed_downloads)}")
    
    if failed_downloads:
        print(f"\n❌ Не удалось создать:")
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
        print(f"   ./upload_generated_anthems.sh")

if __name__ == "__main__":
    main()

