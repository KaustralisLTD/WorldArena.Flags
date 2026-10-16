#!/usr/bin/env python3
"""
Скрипт для скачивания всех недостающих гимнов стран
Автоматически определяет какие гимны уже есть на сервере и скачивает только недостающие
"""

import subprocess
import sys
import urllib.request
import urllib.error
from pathlib import Path
import time
import json

OUTPUT_DIR = Path("real_anthems_complete")
OUTPUT_DIR.mkdir(exist_ok=True)

# ВСЕ 193 страны (полный список)
ALL_COUNTRIES = [
    # Европа (44)
    "at", "al", "ad", "by", "be", "bg", "ba", "va", "gb", "hu", "de", "gr", "ge", "dk", "ie",
    "is", "es", "it", "cy", "lv", "lt", "li", "lu", "mt", "md", "mc", "nl", "no", "pl", "pt",
    "ru", "ro", "sm", "mk", "rs", "sk", "si", "ua", "fi", "fr", "hr", "me", "cz", "ch", "se", "tr", "ee",
    # Азия (43) - ge, cy, tr уже в Европе
    "af", "bd", "bh", "bn", "bt", "tl", "vn", "il", "in", "id", "jo", "iq", "ir", "ye",
    "kz", "kh", "qa", "kg", "cn", "kp", "kw", "la", "lb", "my", "mv", "mn", "mm", "np",
    "ae", "om", "pk", "ps", "sa", "sg", "sy", "tj", "th", "tm", "uz", "ph", "lk", "kr", "jp",
    # Африка (54)
    "dz", "ao", "bj", "bw", "bf", "bi", "ga", "gm", "gh", "gn", "gw", "dj", "eg", "zm", "zw",
    "cv", "cm", "ke", "km", "cd", "cg", "ci", "ls", "lr", "ly", "mu", "mr", "mg", "mw", "ml",
    "ma", "mz", "na", "ne", "ng", "rw", "st", "sz", "sc", "sn", "so", "sd", "sl", "tz", "tg",
    "tn", "ug", "cf", "td", "gq", "er", "et", "za", "ss",
    # Северная Америка (23)
    "ag", "bs", "bb", "bz", "ht", "gt", "hn", "gd", "dm", "do", "ca", "cu", "mx", "ni", "pa",
    "sv", "vc", "kn", "lc", "us", "tt", "jm",
    # Южная Америка (12)
    "ar", "bo", "br", "ve", "gy", "co", "py", "pe", "sr", "uy", "cl", "ec",
    # Океания (14)
    "au", "vu", "ki", "mh", "fm", "nr", "nz", "pw", "pg", "ws", "sb", "to", "tv", "fj"
]

# Страны с данными (143) - для справки, но скрипт проверяет ВСЕ страны
ALL_COUNTRIES_WITH_DATA = [
    # Европа (44)
    "at", "al", "ad", "by", "be", "bg", "ba", "va", "gb", "hu", "de", "gr", "ge", "dk", "ie",
    "is", "es", "it", "cy", "lv", "lt", "li", "lu", "mt", "md", "mc", "nl", "no", "pl", "pt",
    "ru", "ro", "sm", "mk", "rs", "sk", "si", "ua", "fi", "fr", "hr", "me", "cz", "ch", "se", "tr", "ee",
    # Азия (43)
    "af", "bd", "vn", "ge", "il", "in", "id", "ir", "kz", "kh", "cn", "cy", "my", "mn", "mm",
    "np", "ae", "pk", "sa", "sg", "th", "tr", "ph", "lk", "kr", "jp", "jo", "qa", "kw", "lb", "om", "uz",
    "bh", "iq", "ye", "bn", "bt", "kg", "tj", "tm", "mv", "sy", "tl", "kp", "ps",
    # Африка (15)
    "dz", "eg", "ke", "ma", "et", "za", "ng", "tz", "gh", "ug", "tn", "sn", "cm", "ao",
    # Северная Америка (22)
    "cu", "mx", "us", "ca", "cr", "jm", "pa", "gt", "hn", "ni", "sv", "do", "ht", "bz", "tt", "bs", "bb", "lc", "gd", "ag", "dm", "kn", "vc",
    # Южная Америка (12)
    "ar", "br", "co", "cl", "pe", "ec", "ve", "bo", "py", "uy", "gy", "sr",
    # Океания (13)
    "au", "nz", "fj", "pg", "ws", "to", "vu", "sb", "pw", "fm", "mh", "ki", "tv", "nr"
]

BASE_URL = "https://flags.worldarena.games/anthems"
TIMEOUT = 5

# Поисковые запросы для гимнов
SEARCH_QUERIES = {
    # Европа
    "al": "Albania national anthem Hymni i Flamurit official instrumental",
    "ad": "Andorra national anthem El Gran Carlemany official instrumental",
    "by": "Belarus national anthem My Belarusy official instrumental",
    "ba": "Bosnia and Herzegovina national anthem Državna himna official instrumental",
    "va": "Vatican City national anthem Inno e Marcia Pontificale official instrumental",
    "is": "Iceland national anthem Lofsöngur official instrumental",
    "cy": "Cyprus national anthem Hymn to Liberty official instrumental",
    "lv": "Latvia national anthem Dievs svētī Latviju official instrumental",
    "lt": "Lithuania national anthem Tautiška giesmė official instrumental",
    "li": "Liechtenstein national anthem Oben am jungen Rhein official instrumental",
    "lu": "Luxembourg national anthem Ons Heemecht official instrumental",
    "mt": "Malta national anthem L-Innu Malti official instrumental",
    "md": "Moldova national anthem Limba noastră official instrumental",
    "mc": "Monaco national anthem Hymne Monégasque official instrumental",
    "sm": "San Marino national anthem Inno Nazionale official instrumental",
    "mk": "North Macedonia national anthem Denes nad Makedonija official instrumental",
    "sk": "Slovakia national anthem Nad Tatrou sa blýska official instrumental",
    "si": "Slovenia national anthem Zdravljica official instrumental",
    "me": "Montenegro national anthem Oj svijetla majska zoro official instrumental",
    "ee": "Estonia national anthem Mu isamaa official instrumental",
    
    # Азия
    "af": "Afghanistan national anthem Millī Surūd official instrumental",
    "jo": "Jordan national anthem As-salam al-malaki al-urdoni official instrumental",
    "qa": "Qatar national anthem As-Salam al-Amiri official instrumental",
    "kw": "Kuwait national anthem Al-Nasheed Al-Watani official instrumental",
    "lb": "Lebanon national anthem Koullouna Lilouataan official instrumental",
    "om": "Oman national anthem Nashid as-Salaam as-Sultani official instrumental",
    "uz": "Uzbekistan national anthem O'zbekiston Respublikasining Davlat Madhiyasi official instrumental",
    
    # Азия (дополнительные)
    "bh": "Bahrain national anthem Bahrainona official instrumental",
    "iq": "Iraq national anthem Mawtini official instrumental",
    "ye": "Yemen national anthem United Republic official instrumental",
    "bn": "Brunei national anthem Allah Peliharakan Sultan official instrumental",
    "bt": "Bhutan national anthem Druk tsendhen official instrumental",
    "kg": "Kyrgyzstan national anthem Кыргыз Республикасынын Мамлекеттик Гимни official instrumental",
    "tj": "Tajikistan national anthem Суруди Миллии official instrumental",
    "tm": "Turkmenistan national anthem Гарашсыз Битарап Түркменистаның Дöвлет Гимни official instrumental",
    "mv": "Maldives national anthem Gaumii salaam official instrumental",
    "sy": "Syria national anthem Homat el Diyar official instrumental",
    "tl": "East Timor national anthem Pátria official instrumental",
    "kp": "North Korea national anthem Aegukka official instrumental",
    "ps": "Palestine national anthem Fida'i official instrumental",
    "la": "Laos national anthem Pheng Xat Lao official instrumental",
    
    # Африка
    "dz": "Algeria national anthem Kassaman official instrumental",
    "ao": "Angola national anthem Angola Avante official instrumental",
    "bj": "Benin national anthem L'Aube Nouvelle official instrumental",
    "bw": "Botswana national anthem Fatshe leno la rona official instrumental",
    "bf": "Burkina Faso national anthem Une Seule Nuit official instrumental",
    "bi": "Burundi national anthem Burundi bwacu official instrumental",
    "cv": "Cape Verde national anthem Cântico da Liberdade official instrumental",
    "cm": "Cameroon national anthem O Cameroun Berceau de nos Ancêtres official instrumental",
    "cf": "Central African Republic national anthem La Renaissance official instrumental",
    "td": "Chad national anthem La Tchadienne official instrumental",
    "km": "Comoros national anthem Udzima wa ya Masiwa official instrumental",
    "cd": "DR Congo national anthem Debout Congolais official instrumental",
    "cg": "Republic of the Congo national anthem La Congolaise official instrumental",
    "ci": "Ivory Coast national anthem L'Abidjanaise official instrumental",
    "dj": "Djibouti national anthem Djibouti official instrumental",
    "eg": "Egypt national anthem Bilady Bilady Bilady official instrumental",
    "gq": "Equatorial Guinea national anthem Caminemos pisando las sendas official instrumental",
    "er": "Eritrea national anthem Ertra Ertra Ertra official instrumental",
    "et": "Ethiopia national anthem Wodefit Gesgeshi official instrumental",
    "ga": "Gabon national anthem La Concorde official instrumental",
    "gm": "Gambia national anthem For The Gambia Our Homeland official instrumental",
    "gh": "Ghana national anthem God Bless Our Homeland Ghana official instrumental",
    "gn": "Guinea national anthem Liberté official instrumental",
    "gw": "Guinea-Bissau national anthem Esta É a Nossa Pátria Bem Amada official instrumental",
    "ke": "Kenya national anthem Ee Mungu Nguvu Yetu official instrumental",
    "ls": "Lesotho national anthem Lesotho Fatse La Bontata Rona official instrumental",
    "lr": "Liberia national anthem All Hail Liberia Hail official instrumental",
    "ly": "Libya national anthem Libya Libya Libya official instrumental",
    "mg": "Madagascar national anthem Ry Tanindrazanay malala ô official instrumental",
    "mw": "Malawi national anthem Mlungu dalitsani Malaŵi official instrumental",
    "ml": "Mali national anthem Le Mali official instrumental",
    "mr": "Mauritania national anthem Bilada-l ubati-l hudati-l kiram official instrumental",
    "mu": "Mauritius national anthem Motherland official instrumental",
    "ma": "Morocco national anthem Hymne Chérifien official instrumental",
    "mz": "Mozambique national anthem Pátria Amada official instrumental",
    "na": "Namibia national anthem Namibia Land of the Brave official instrumental",
    "ne": "Niger national anthem La Nigérienne official instrumental",
    "ng": "Nigeria national anthem Arise O Compatriots official instrumental",
    "rw": "Rwanda national anthem Rwanda nziza official instrumental",
    "st": "São Tomé and Príncipe national anthem Independência total official instrumental",
    "sn": "Senegal national anthem Pincez Tous vos Koras official instrumental",
    "sc": "Seychelles national anthem Koste Seselwa official instrumental",
    "sl": "Sierra Leone national anthem High We Exalt Thee Realm of the Free official instrumental",
    "so": "Somalia national anthem Qolobaa Calankeed official instrumental",
    "ss": "South Sudan national anthem South Sudan Oyee official instrumental",
    "sd": "Sudan national anthem Nahnu Jund Allah Jund Al-watan official instrumental",
    "sz": "Eswatini national anthem Nkulunkulu Mnikati wetibusiso temaSwati official instrumental",
    "tz": "Tanzania national anthem Mungu ibariki Afrika official instrumental",
    "tg": "Togo national anthem Salut à toi pays de nos aïeux official instrumental",
    "tn": "Tunisia national anthem Humat al-Hima official instrumental",
    "ug": "Uganda national anthem Oh Uganda Land of Beauty official instrumental",
    "za": "South Africa national anthem Nkosi Sikelel' iAfrika official instrumental",
    "zm": "Zambia national anthem Stand and Sing of Zambia Proud and Free official instrumental",
    "zw": "Zimbabwe national anthem Simudzai Mureza WeZimbabwe official instrumental",
    
    # Северная Америка
    "cu": "Cuba national anthem La Bayamesa official instrumental",
    "cr": "Costa Rica national anthem Himno Nacional de Costa Rica official instrumental",
    "jm": "Jamaica national anthem Jamaica Land We Love official instrumental",
    "pa": "Panama national anthem Himno Istmeño official instrumental",
    "gt": "Guatemala national anthem Himno Nacional de Guatemala official instrumental",
    "hn": "Honduras national anthem Himno Nacional de Honduras official instrumental",
    "ni": "Nicaragua national anthem Salve a ti Nicaragua official instrumental",
    "sv": "El Salvador national anthem Himno Nacional de El Salvador official instrumental",
    "do": "Dominican Republic national anthem Himno Nacional official instrumental",
    "ht": "Haiti national anthem La Dessalinienne official instrumental",
    "bz": "Belize national anthem Land of the Free official instrumental",
    "tt": "Trinidad and Tobago national anthem Forged from the Love of Liberty official instrumental",
    "bs": "Bahamas national anthem March On Bahamaland official instrumental",
    "bb": "Barbados national anthem In Plenty and In Time of Need official instrumental",
    "lc": "Saint Lucia national anthem Sons and Daughters of Saint Lucia official instrumental",
    "gd": "Grenada national anthem Hail Grenada official instrumental",
    "ag": "Antigua and Barbuda national anthem Fair Antigua We Salute Thee official instrumental",
    "dm": "Dominica national anthem Isle of Beauty Isle of Splendour official instrumental",
    "kn": "Saint Kitts and Nevis national anthem O Land of Beauty official instrumental",
    "vc": "Saint Vincent and the Grenadines national anthem Saint Vincent Land So Beautiful official instrumental",
    
    # Южная Америка
    "co": "Colombia national anthem Himno Nacional de la República de Colombia official instrumental",
    "pe": "Peru national anthem Himno Nacional del Perú official instrumental",
    "ec": "Ecuador national anthem Salve Oh Patria official instrumental",
    "ve": "Venezuela national anthem Gloria al Bravo Pueblo official instrumental",
    "bo": "Bolivia national anthem Himno Nacional de Bolivia official instrumental",
    "py": "Paraguay national anthem Paraguayos República o Muerte official instrumental",
    "uy": "Uruguay national anthem Himno Nacional official instrumental",
    "gy": "Guyana national anthem Dear Land of Guyana of Rivers and Plains official instrumental",
    "sr": "Suriname national anthem God zij met ons Suriname official instrumental",
    
    # Океания
    "fj": "Fiji national anthem God Bless Fiji official instrumental",
    "pg": "Papua New Guinea national anthem O Arise All You Sons official instrumental",
    "ws": "Samoa national anthem O Le Fua o Le Saoloto o Samoa official instrumental",
    "to": "Tonga national anthem Ko e fasi o e tui o e Otu Tonga official instrumental",
    "vu": "Vanuatu national anthem Yumi Yumi Yumi official instrumental",
    "sb": "Solomon Islands national anthem God Save Our Solomon Islands official instrumental",
    "pw": "Palau national anthem Belau rekid official instrumental",
    "fm": "Micronesia national anthem Patriots of Micronesia official instrumental",
    "mh": "Marshall Islands national anthem Forever Marshall Islands official instrumental",
    "ki": "Kiribati national anthem Teirake Kaini Kiribati official instrumental",
    "tv": "Tuvalu national anthem Tuvalu mo te Atua official instrumental",
    "nr": "Nauru national anthem Nauru Bwiema official instrumental",
}

def check_server_anthem(country_code: str) -> bool:
    """Проверяет наличие гимна на сервере"""
    url = f"{BASE_URL}/anthem_{country_code.lower()}.m4a"
    try:
        req = urllib.request.Request(url, method='HEAD')
        req.add_header('User-Agent', 'Mozilla/5.0')
        with urllib.request.urlopen(req, timeout=TIMEOUT) as response:
            return response.getcode() == 200
    except:
        return False

def download_anthem(country_code: str) -> bool:
    """Скачивает один гимн"""
    output_file = OUTPUT_DIR / f"anthem_{country_code}.m4a"
    
    # Проверяем если уже скачан локально
    if output_file.exists():
        file_size = output_file.stat().st_size
        MIN_SIZE_KB = 500 * 1024  # 500 KB минимум
        if file_size > MIN_SIZE_KB:
            size_mb = file_size / 1024 / 1024
            print(f"⏭️  {country_code.upper()} уже скачан локально ({size_mb:.2f} MB)")
            return True
        else:
            print(f"⚠️  {country_code.upper()} найден заглушка, перезагружаю...")
            output_file.unlink()
    
    search_query = SEARCH_QUERIES.get(country_code, f"{country_code} national anthem official instrumental")
    
    print(f"\n{'='*60}")
    print(f"🎵 [{country_code.upper()}] Скачиваю: {search_query}")
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
        process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, 
                                   text=True, bufsize=1, universal_newlines=True)
        
        for line in process.stdout:
            if line.strip():
                print(f"  {line.strip()}")
        
        process.wait()
        
        temp_files = list(OUTPUT_DIR.glob(f"temp_{country_code}.*"))
        if not temp_files:
            if process.returncode != 0:
                print(f"❌ Ошибка скачивания {country_code.upper()} (код: {process.returncode})")
            else:
                print(f"❌ Файл не найден для {country_code.upper()}")
            return False
        
        temp_file = temp_files[0]
        file_size = temp_file.stat().st_size
        if file_size < 10240:  # Минимум 10KB
            print(f"❌ Файл слишком маленький: {file_size} байт")
            temp_file.unlink()
            return False
        
        if temp_file.suffix.lower() == '.m4a':
            temp_file.rename(output_file)
            size_mb = output_file.stat().st_size / 1024 / 1024
            print(f"✅ {country_code.upper()} скачан: {size_mb:.2f} MB")
            return True
        else:
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
                print(f"✅ {country_code.upper()} скачан: {size_mb:.2f} MB")
                return True
            else:
                print(f"❌ Ошибка конвертации {country_code.upper()}")
                return False
        
    except Exception as e:
        print(f"❌ Ошибка: {e}")
        return False

def main():
    print("🎵 Скачивание недостающих гимнов стран\n")
    print("=" * 70)
    
    # Определяем какие гимны нужно скачать
    print(f"🔍 Проверяю какие гимны уже есть на сервере...")
    print(f"📋 Всего стран для проверки: {len(ALL_COUNTRIES)}\n")
    
    missing_countries = []
    existing_on_server = []
    
    # Проверяем ВСЕ страны, а не только те у которых есть данные
    for i, country in enumerate(ALL_COUNTRIES, 1):
        country_lower = country.lower()
        if i % 20 == 0:
            print(f"   Проверено {i}/{len(ALL_COUNTRIES)}...", end="\r")
        
        if check_server_anthem(country_lower):
            existing_on_server.append(country_lower)
        else:
            missing_countries.append(country_lower)
    
    print(f"\n✅ На сервере уже есть: {len(existing_on_server)} гимнов")
    print(f"❌ Нужно скачать: {len(missing_countries)} гимнов\n")
    
    if not missing_countries:
        print("🎉 Все гимны уже загружены на сервер!")
        return
    
    print("=" * 70)
    print(f"\n📋 Список стран для скачивания ({len(missing_countries)}):")
    for i, country in enumerate(missing_countries, 1):
        print(f"   {i}. {country.upper()}")
    
    print(f"\n🚀 Начинаю скачивание...\n")
    
    success = 0
    failed = 0
    
    for i, country in enumerate(missing_countries, 1):
        print(f"\n[{i}/{len(missing_countries)}] ", end="")
        
        if download_anthem(country):
            success += 1
        else:
            failed += 1
        
        # Пауза между запросами (избегаем блокировок)
        if i < len(missing_countries):
            wait = 3 + (i % 4)  # 3-6 секунд
            print(f"⏳ Жду {wait} сек...")
            time.sleep(wait)
    
    print(f"\n{'='*70}")
    print(f"✅ Успешно скачано: {success}")
    print(f"❌ Ошибок: {failed}")
    print(f"{'='*70}")
    
    if success > 0:
        print(f"\n📤 Теперь загрузите файлы на сервер:")
        print(f"   ./upload_all_anthems_to_server.sh")

if __name__ == "__main__":
    main()
