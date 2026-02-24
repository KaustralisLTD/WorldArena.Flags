#!/usr/bin/env python3
"""
Скрипт для загрузки реальных гимнов стран из общедоступных источников
"""

import os
import requests
import subprocess
import json
from pathlib import Path
from typing import Dict, List, Optional

class AnthemDownloader:
    def __init__(self):
        self.output_dir = Path("real_anthems")
        self.output_dir.mkdir(exist_ok=True)
        
        # Источники гимнов (общественное достояние)
        self.anthem_sources = {
            # Европа
            "at": "https://upload.wikimedia.org/wikipedia/commons/4/4f/Austrian_national_anthem%2C_performed_by_the_United_States_Navy_Band.ogg",
            "de": "https://upload.wikimedia.org/wikipedia/commons/7/7c/United_States_Navy_Band_-_Deutschlandlied.ogg",
            "fr": "https://upload.wikimedia.org/wikipedia/commons/9/9a/United_States_Navy_Band_-_La_Marseillaise.ogg",
            "it": "https://upload.wikimedia.org/wikipedia/commons/8/8b/United_States_Navy_Band_-_Il_Canto_degli_Italiani.ogg",
            "es": "https://upload.wikimedia.org/wikipedia/commons/9/9a/United_States_Navy_Band_-_Marcha_Real.ogg",
            "gb": "https://upload.wikimedia.org/wikipedia/commons/7/7c/United_States_Navy_Band_-_God_Save_the_King.ogg",
            "ru": "https://upload.wikimedia.org/wikipedia/commons/4/4f/Russian_national_anthem%2C_performed_by_the_United_States_Navy_Band.ogg",
            "ua": "https://upload.wikimedia.org/wikipedia/commons/4/4f/Ukrainian_national_anthem%2C_performed_by_the_United_States_Navy_Band.ogg",
            "pl": "https://upload.wikimedia.org/wikipedia/commons/7/7c/United_States_Navy_Band_-_Mazurek_Dabrowskiego.ogg",
            "nl": "https://upload.wikimedia.org/wikipedia/commons/9/9a/United_States_Navy_Band_-_Het_Wilhelmus.ogg",
            "be": "https://upload.wikimedia.org/wikipedia/commons/7/7c/United_States_Navy_Band_-_La_Brabanconne.ogg",
            "ch": "https://upload.wikimedia.org/wikipedia/commons/9/9a/United_States_Navy_Band_-_Swiss_Psalm.ogg",
            "se": "https://upload.wikimedia.org/wikipedia/commons/7/7c/United_States_Navy_Band_-_Du_gamla%2C_Du_fria.ogg",
            "no": "https://upload.wikimedia.org/wikipedia/commons/9/9a/United_States_Navy_Band_-_Ja%2C_vi_elsker_dette_landet.ogg",
            "dk": "https://upload.wikimedia.org/wikipedia/commons/7/7c/United_States_Navy_Band_-_Der_er_et_yndigt_land.ogg",
            "fi": "https://upload.wikimedia.org/wikipedia/commons/9/9a/United_States_Navy_Band_-_Maamme.ogg",
            "ie": "https://upload.wikimedia.org/wikipedia/commons/7/7c/United_States_Navy_Band_-_Amhran_na_bhFiann.ogg",
            "pt": "https://upload.wikimedia.org/wikipedia/commons/9/9a/United_States_Navy_Band_-_A_Portuguesa.ogg",
            "gr": "https://upload.wikimedia.org/wikipedia/commons/7/7c/United_States_Navy_Band_-_Ymnos_is_tin_Eleftherian.ogg",
            "cz": "https://upload.wikimedia.org/wikipedia/commons/9/9a/United_States_Navy_Band_-_Kde_domov_muj.ogg",
            
            # Америка
            "us": "https://upload.wikimedia.org/wikipedia/commons/7/7c/United_States_Navy_Band_-_The_Star-Spangled_Banner.ogg",
            "ca": "https://upload.wikimedia.org/wikipedia/commons/9/9a/United_States_Navy_Band_-_O_Canada.ogg",
            "mx": "https://upload.wikimedia.org/wikipedia/commons/7/7c/United_States_Navy_Band_-_Himno_Nacional_Mexicano.ogg",
            "br": "https://upload.wikimedia.org/wikipedia/commons/9/9a/United_States_Navy_Band_-_Hino_Nacional_Brasileiro.ogg",
            "ar": "https://upload.wikimedia.org/wikipedia/commons/7/7c/United_States_Navy_Band_-_Himno_Nacional_Argentino.ogg",
            
            # Азия
            "cn": "https://upload.wikimedia.org/wikipedia/commons/9/9a/United_States_Navy_Band_-_March_of_the_Volunteers.ogg",
            "jp": "https://upload.wikimedia.org/wikipedia/commons/7/7c/United_States_Navy_Band_-_Kimigayo.ogg",
            "kr": "https://upload.wikimedia.org/wikipedia/commons/9/9a/United_States_Navy_Band_-_Aegukga.ogg",
            "in": "https://upload.wikimedia.org/wikipedia/commons/7/7c/United_States_Navy_Band_-_Jana_Gana_Mana.ogg",
            "th": "https://upload.wikimedia.org/wikipedia/commons/9/9a/United_States_Navy_Band_-_Phleng_Chat_Thai.ogg",
            
            # Африка
            "za": "https://upload.wikimedia.org/wikipedia/commons/7/7c/United_States_Navy_Band_-_National_Anthem_of_South_Africa.ogg",
            "eg": "https://upload.wikimedia.org/wikipedia/commons/9/9a/United_States_Navy_Band_-_Bilady%2C_Bilady%2C_Bilady.ogg",
            "ng": "https://upload.wikimedia.org/wikipedia/commons/7/7c/United_States_Navy_Band_-_Arise%2C_O_Compatriots.ogg",
            "ke": "https://upload.wikimedia.org/wikipedia/commons/9/9a/United_States_Navy_Band_-_Ee_Mungu_Nguvu_Yetu.ogg",
            "gh": "https://upload.wikimedia.org/wikipedia/commons/7/7c/United_States_Navy_Band_-_God_Bless_Our_Homeland_Ghana.ogg",
            
            # Океания
            "au": "https://upload.wikimedia.org/wikipedia/commons/9/9a/United_States_Navy_Band_-_Advance_Australia_Fair.ogg",
            "nz": "https://upload.wikimedia.org/wikipedia/commons/7/7c/United_States_Navy_Band_-_God_Defend_New_Zealand.ogg",
            "fj": "https://upload.wikimedia.org/wikipedia/commons/9/9a/United_States_Navy_Band_-_God_Bless_Fiji.ogg",
            "pg": "https://upload.wikimedia.org/wikipedia/commons/7/7c/United_States_Navy_Band_-_O_Arise%2C_All_You_Sons.ogg",
            "ws": "https://upload.wikimedia.org/wikipedia/commons/9/9a/United_States_Navy_Band_-_The_Banner_of_Freedom.ogg"
        }
        
        # Альтернативные источники (если основные недоступны)
        self.alternative_sources = {
            "at": "https://ia800504.us.archive.org/15/items/national_anthems/austria_national_anthem.ogg",
            "de": "https://ia800504.us.archive.org/15/items/national_anthems/germany_national_anthem.ogg",
            "fr": "https://ia800504.us.archive.org/15/items/national_anthems/france_national_anthem.ogg",
            "it": "https://ia800504.us.archive.org/15/items/national_anthems/italy_national_anthem.ogg",
            "es": "https://ia800504.us.archive.org/15/items/national_anthems/spain_national_anthem.ogg",
            "gb": "https://ia800504.us.archive.org/15/items/national_anthems/uk_national_anthem.ogg",
            "ru": "https://ia800504.us.archive.org/15/items/national_anthems/russia_national_anthem.ogg",
            "ua": "https://ia800504.us.archive.org/15/items/national_anthems/ukraine_national_anthem.ogg",
            "pl": "https://ia800504.us.archive.org/15/items/national_anthems/poland_national_anthem.ogg",
            "nl": "https://ia800504.us.archive.org/15/items/national_anthems/netherlands_national_anthem.ogg",
            "be": "https://ia800504.us.archive.org/15/items/national_anthems/belgium_national_anthem.ogg",
            "ch": "https://ia800504.us.archive.org/15/items/national_anthems/switzerland_national_anthem.ogg",
            "se": "https://ia800504.us.archive.org/15/items/national_anthems/sweden_national_anthem.ogg",
            "no": "https://ia800504.us.archive.org/15/items/national_anthems/norway_national_anthem.ogg",
            "dk": "https://ia800504.us.archive.org/15/items/national_anthems/denmark_national_anthem.ogg",
            "fi": "https://ia800504.us.archive.org/15/items/national_anthems/finland_national_anthem.ogg",
            "ie": "https://ia800504.us.archive.org/15/items/national_anthems/ireland_national_anthem.ogg",
            "pt": "https://ia800504.us.archive.org/15/items/national_anthems/portugal_national_anthem.ogg",
            "gr": "https://ia800504.us.archive.org/15/items/national_anthems/greece_national_anthem.ogg",
            "cz": "https://ia800504.us.archive.org/15/items/national_anthems/czech_republic_national_anthem.ogg"
        }
    
    def download_file(self, url: str, filename: str) -> bool:
        """Загружает файл по URL"""
        try:
            print(f"📥 Загружаю {filename}...")
            response = requests.get(url, timeout=30, stream=True)
            response.raise_for_status()
            
            filepath = self.output_dir / filename
            with open(filepath, 'wb') as f:
                for chunk in response.iter_content(chunk_size=8192):
                    f.write(chunk)
            
            print(f"✅ Загружен: {filename}")
            return True
            
        except Exception as e:
            print(f"❌ Ошибка загрузки {filename}: {e}")
            return False
    
    def convert_to_m4a(self, input_file: str) -> bool:
        """Конвертирует аудиофайл в M4A формат"""
        try:
            input_path = self.output_dir / input_file
            output_file = input_file.replace('.ogg', '.m4a').replace('.mp3', '.m4a').replace('.wav', '.m4a')
            output_path = self.output_dir / output_file
            
            # Используем ffmpeg для конвертации
            cmd = [
                'ffmpeg', '-i', str(input_path),
                '-c:a', 'aac',
                '-b:a', '192k',
                '-ar', '44100',
                '-y',  # Перезаписать существующий файл
                str(output_path)
            ]
            
            result = subprocess.run(cmd, capture_output=True, text=True)
            
            if result.returncode == 0:
                print(f"✅ Конвертирован: {output_file}")
                # Удаляем исходный файл
                input_path.unlink()
                return True
            else:
                print(f"❌ Ошибка конвертации {input_file}: {result.stderr}")
                return False
                
        except Exception as e:
            print(f"❌ Ошибка конвертации {input_file}: {e}")
            return False
    
    def download_and_convert_anthem(self, country_code: str) -> bool:
        """Загружает и конвертирует гимн для страны"""
        # Пробуем основной источник
        if country_code in self.anthem_sources:
            url = self.anthem_sources[country_code]
            filename = f"anthem_{country_code}.ogg"
            
            if self.download_file(url, filename):
                return self.convert_to_m4a(filename)
        
        # Пробуем альтернативный источник
        if country_code in self.alternative_sources:
            url = self.alternative_sources[country_code]
            filename = f"anthem_{country_code}_alt.ogg"
            
            if self.download_file(url, filename):
                return self.convert_to_m4a(filename)
        
        print(f"❌ Не удалось загрузить гимн для {country_code}")
        return False
    
    def create_manifest(self):
        """Создает манифест с информацией о загруженных гимнах"""
        manifest = {
            "total_anthems": 0,
            "successful_downloads": 0,
            "failed_downloads": 0,
            "anthems": {}
        }
        
        for file in self.output_dir.glob("anthem_*.m4a"):
            country_code = file.stem.replace("anthem_", "").replace("_alt", "")
            manifest["anthems"][country_code] = {
                "filename": file.name,
                "size_bytes": file.stat().st_size,
                "size_mb": round(file.stat().st_size / (1024 * 1024), 2)
            }
            manifest["total_anthems"] += 1
            manifest["successful_downloads"] += 1
        
        manifest["failed_downloads"] = len(self.anthem_sources) - manifest["successful_downloads"]
        
        with open(self.output_dir / "manifest.json", 'w', encoding='utf-8') as f:
            json.dump(manifest, f, indent=2, ensure_ascii=False)
        
        print(f"📋 Создан манифест: {manifest['successful_downloads']}/{len(self.anthem_sources)} гимнов загружено")
    
    def run(self):
        """Запускает процесс загрузки всех гимнов"""
        print("🎵 Начинаю загрузку реальных гимнов стран...")
        print("=" * 60)
        
        successful = 0
        total = len(self.anthem_sources)
        
        for country_code in self.anthem_sources.keys():
            if self.download_and_convert_anthem(country_code):
                successful += 1
            print("-" * 40)
        
        print("=" * 60)
        print(f"🎵 Загрузка завершена: {successful}/{total} гимнов успешно загружено")
        
        # Создаем манифест
        self.create_manifest()
        
        # Показываем список файлов
        print("\n📁 Загруженные файлы:")
        for file in sorted(self.output_dir.glob("anthem_*.m4a")):
            size_mb = file.stat().st_size / (1024 * 1024)
            print(f"  {file.name} ({size_mb:.1f} MB)")

def main():
    downloader = AnthemDownloader()
    downloader.run()

if __name__ == "__main__":
    main()
