#!/usr/bin/env python3
"""
Скрипт для загрузки реальных национальных гимнов
Использует различные источники для получения официальных аудиофайлов
"""

import os
import json
import requests
import time
from pathlib import Path
import yt_dlp
from pydub import AudioSegment
import sys

# Конфигурация
OUTPUT_DIR = "real_anthems_v2"
DURATION_LIMIT = 60  # Максимальная длительность в секундах
AUDIO_QUALITY = "192k"  # Битрейт для M4A
SAMPLE_RATE = 44100  # Частота дискретизации

# Список стран с поисковыми запросами для гимнов
COUNTRIES_ANTHEMS = {
    "ad": "Andorra national anthem El Gran Carlemany official",
    "ae": "United Arab Emirates national anthem Ishy Bilady official",
    "af": "Afghanistan national anthem Milli Surood official",
    "ag": "Antigua and Barbuda national anthem Fair Antigua We Salute Thee official",
    "ai": "Anguilla national anthem God Save the Queen official",
    "al": "Albania national anthem Hymni i Flamurit official",
    "am": "Armenia national anthem Mer Hayrenik official",
    "ao": "Angola national anthem Angola Avante official",
    "ar": "Argentina national anthem Himno Nacional Argentino official",
    "as": "American Samoa national anthem Amerika Samoa official",
    "at": "Austria national anthem Land der Berge Land am Strome official",
    "au": "Australia national anthem Advance Australia Fair official",
    "aw": "Aruba national anthem Aruba Dushi Tera official",
    "ax": "Åland national anthem Ålänningens sång official",
    "az": "Azerbaijan national anthem Azərbaycan marşı official",
    "ba": "Bosnia and Herzegovina national anthem Državna himna official",
    "bb": "Barbados national anthem In Plenty and In Time of Need official",
    "bd": "Bangladesh national anthem Amar Shonar Bangla official",
    "be": "Belgium national anthem La Brabançonne official",
    "bf": "Burkina Faso national anthem Une Seule Nuit official",
    "bg": "Bulgaria national anthem Mila Rodino official",
    "bh": "Bahrain national anthem Bahrainona official",
    "bi": "Burundi national anthem Burundi Bwacu official",
    "bj": "Benin national anthem L'Aube Nouvelle official",
    "bl": "Saint Barthélemy national anthem La Marseillaise official",
    "bm": "Bermuda national anthem God Save the Queen official",
    "bn": "Brunei national anthem Allah Peliharakan Sultan official",
    "bo": "Bolivia national anthem Canción Patriótica official",
    "bq": "Caribbean Netherlands national anthem Wilhelmus official",
    "br": "Brazil national anthem Hino Nacional Brasileiro official",
    "bs": "Bahamas national anthem March On Bahamaland official",
    "bt": "Bhutan national anthem Druk tsendhen official",
    "bv": "Bouvet Island national anthem Ja vi elsker dette landet official",
    "bw": "Botswana national anthem Fatshe leno la rona official",
    "by": "Belarus national anthem My Belarusy official",
    "bz": "Belize national anthem Land of the Free official",
    "ca": "Canada national anthem O Canada official",
    "cc": "Cocos Islands national anthem Advance Australia Fair official",
    "cd": "Democratic Republic of Congo national anthem Debout Congolais official",
    "cf": "Central African Republic national anthem La Renaissance official",
    "cg": "Republic of Congo national anthem La Congolaise official",
    "ch": "Switzerland national anthem Swiss Psalm official",
    "ci": "Côte d'Ivoire national anthem L'Abidjanaise official",
    "ck": "Cook Islands national anthem Te Atua Mou E official",
    "cl": "Chile national anthem Himno Nacional de Chile official",
    "cm": "Cameroon national anthem Ô Cameroun Berceau de nos Ancêtres official",
    "cn": "China national anthem March of the Volunteers official",
    "co": "Colombia national anthem Himno Nacional de Colombia official",
    "cr": "Costa Rica national anthem Himno Nacional de Costa Rica official",
    "cu": "Cuba national anthem La Bayamesa official",
    "cv": "Cape Verde national anthem Cântico da Liberdade official",
    "cw": "Curaçao national anthem Himno di Kòrsou official",
    "cx": "Christmas Island national anthem Advance Australia Fair official",
    "cy": "Cyprus national anthem Ymnos is tin Eleftherian official",
    "cz": "Czech Republic national anthem Kde domov můj official",
    "de": "Germany national anthem Das Lied der Deutschen official",
    "dj": "Djibouti national anthem Jabuuti official",
    "dk": "Denmark national anthem Der er et yndigt land official",
    "dm": "Dominica national anthem Isle of Beauty Isle of Splendour official",
    "do": "Dominican Republic national anthem Himno Nacional official",
    "dz": "Algeria national anthem Kassaman official",
    "ec": "Ecuador national anthem Salve Oh Patria official",
    "ee": "Estonia national anthem Mu isamaa mu õnn ja rõõm official",
    "eg": "Egypt national anthem Bilady Bilady Bilady official",
    "eh": "Western Sahara national anthem Mawtini official",
    "er": "Eritrea national anthem Ertra Ertra Ertra official",
    "es": "Spain national anthem Marcha Real official",
    "et": "Ethiopia national anthem Whedefit Gesgeshi Woude Henate Ethiopia official",
    "fi": "Finland national anthem Maamme official",
    "fj": "Fiji national anthem God Bless Fiji official",
    "fk": "Falkland Islands national anthem God Save the Queen official",
    "fm": "Micronesia national anthem Patriots of Micronesia official",
    "fo": "Faroe Islands national anthem Tú alfagra land mítt official",
    "fr": "France national anthem La Marseillaise official",
    "ga": "Gabon national anthem La Concorde official",
    "gb": "United Kingdom national anthem God Save the King official",
    "gd": "Grenada national anthem Hail Grenada official",
    "ge": "Georgia national anthem Tavisupleba official",
    "gf": "French Guiana national anthem La Marseillaise official",
    "gg": "Guernsey national anthem Sarnia Cherie official",
    "gh": "Ghana national anthem God Bless Our Homeland Ghana official",
    "gi": "Gibraltar national anthem God Save the King official",
    "gl": "Greenland national anthem Nunarput utoqqarsuanngoravit official",
    "gm": "Gambia national anthem For The Gambia Our Homeland official",
    "gn": "Guinea national anthem Liberté official",
    "gp": "Guadeloupe national anthem La Marseillaise official",
    "gq": "Equatorial Guinea national anthem Caminemos pisando official",
    "gr": "Greece national anthem Ymnos is tin Eleftherian official",
    "gs": "South Georgia national anthem God Save the King official",
    "gt": "Guatemala national anthem Himno Nacional de Guatemala official",
    "gu": "Guam national anthem Stand Ye Guamanians official",
    "gw": "Guinea-Bissau national anthem Esta É a Nossa Pátria Bem Amada official",
    "gy": "Guyana national anthem Dear Land of Guyana of Rivers and Plains official",
    "hk": "Hong Kong national anthem March of the Volunteers official",
    "hm": "Heard Island national anthem Advance Australia Fair official",
    "hn": "Honduras national anthem Himno Nacional de Honduras official",
    "hr": "Croatia national anthem Lijepa naša domovino official",
    "ht": "Haiti national anthem La Dessalinienne official",
    "hu": "Hungary national anthem Himnusz official",
    "id": "Indonesia national anthem Indonesia Raya official",
    "ie": "Ireland national anthem Amhrán na bhFiann official",
    "il": "Israel national anthem Hatikvah official",
    "im": "Isle of Man national anthem O Land of Our Birth official",
    "in": "India national anthem Jana Gana Mana official",
    "io": "British Indian Ocean Territory national anthem God Save the King official",
    "iq": "Iraq national anthem Mawtini official",
    "ir": "Iran national anthem Sorude Melli official",
    "is": "Iceland national anthem Lofsöngur official",
    "it": "Italy national anthem Il Canto degli Italiani official",
    "je": "Jersey national anthem Island Home official",
    "jm": "Jamaica national anthem Jamaica Land We Love official",
    "jo": "Jordan national anthem As-salam al-malaki al-urduni official",
    "jp": "Japan national anthem Kimigayo official",
    "ke": "Kenya national anthem Ee Mungu Nguvu Yetu official",
    "kg": "Kyrgyzstan national anthem Kyrgyz Respublikasynyn Mamlekettik Gimni official",
    "kh": "Cambodia national anthem Nokoreach official",
    "ki": "Kiribati national anthem Teirake kaini Kiribati official",
    "km": "Comoros national anthem Udzima wa ya Masiwa official",
    "kn": "Saint Kitts and Nevis national anthem O Land of Beauty official",
    "kp": "North Korea national anthem Aegukka official",
    "kr": "South Korea national anthem Aegukga official",
    "kw": "Kuwait national anthem Al-Nasheed Al-Watani official",
    "ky": "Cayman Islands national anthem God Save the King official",
    "kz": "Kazakhstan national anthem Menin Qazaqstanim official",
    "la": "Laos national anthem Pheng Xat Lao official",
    "lb": "Lebanon national anthem Kulluna lil-watan official",
    "lc": "Saint Lucia national anthem Sons and Daughters of Saint Lucia official",
    "li": "Liechtenstein national anthem Oben am jungen Rhein official",
    "lk": "Sri Lanka national anthem Sri Lanka Matha official",
    "lr": "Liberia national anthem All Hail Liberia Hail official",
    "ls": "Lesotho national anthem Lesotho Fatse La Bo-ntat'a Rona official",
    "lt": "Lithuania national anthem Tautiška giesmė official",
    "lu": "Luxembourg national anthem Ons Heemecht official",
    "lv": "Latvia national anthem Dievs svētī Latviju official",
    "ly": "Libya national anthem Libya Libya Libya official",
    "ma": "Morocco national anthem Hymne Chérifien official",
    "mc": "Monaco national anthem Hymne Monégasque official",
    "md": "Moldova national anthem Limba noastră official",
    "me": "Montenegro national anthem Oj svijetla majska zoro official",
    "mf": "Saint Martin national anthem La Marseillaise official",
    "mg": "Madagascar national anthem Ry Tanindrazanay malala ô official",
    "mh": "Marshall Islands national anthem Forever Marshall Islands official",
    "mk": "North Macedonia national anthem Denes nad Makedonija official",
    "ml": "Mali national anthem Le Mali official",
    "mm": "Myanmar national anthem Kaba Ma Kyei official",
    "mn": "Mongolia national anthem Mongol ulsyn töriin duulal official",
    "mo": "Macau national anthem March of the Volunteers official",
    "mp": "Northern Mariana Islands national anthem Gi Talo Gi Halom Tasi official",
    "mq": "Martinique national anthem La Marseillaise official",
    "mr": "Mauritania national anthem Nashid al-watani al-muritani official",
    "ms": "Montserrat national anthem God Save the King official",
    "mt": "Malta national anthem L-Innu Malti official",
    "mu": "Mauritius national anthem Motherland official",
    "mv": "Maldives national anthem Gaumee Salaam official",
    "mw": "Malawi national anthem Mulungu dalitsani Malawi official",
    "mx": "Mexico national anthem Himno Nacional Mexicano official",
    "my": "Malaysia national anthem Negaraku official",
    "mz": "Mozambique national anthem Pátria Amada official",
    "na": "Namibia national anthem Namibia Land of the Brave official",
    "nc": "New Caledonia national anthem La Marseillaise official",
    "ne": "Niger national anthem La Nigérienne official",
    "nf": "Norfolk Island national anthem Come Ye Blessed official",
    "ng": "Nigeria national anthem Arise O Compatriots official",
    "ni": "Nicaragua national anthem Salve a ti Nicaragua official",
    "nl": "Netherlands national anthem Wilhelmus official",
    "no": "Norway national anthem Ja vi elsker dette landet official",
    "np": "Nepal national anthem Sayaun Thunga Phool Ka official",
    "nr": "Nauru national anthem Nauru Bwiema official",
    "nu": "Niue national anthem Ko e Iki he Lagi official",
    "nz": "New Zealand national anthem God Defend New Zealand official",
    "om": "Oman national anthem Nashid as-Salaam as-Sultani official",
    "pa": "Panama national anthem Himno Istmeño official",
    "pe": "Peru national anthem Himno Nacional del Perú official",
    "pf": "French Polynesia national anthem Ia Ora 'O Tahiti Nui official",
    "pg": "Papua New Guinea national anthem O Arise All You Sons official",
    "ph": "Philippines national anthem Lupang Hinirang official",
    "pk": "Pakistan national anthem Qaumi Taranah official",
    "pl": "Poland national anthem Mazurek Dąbrowskiego official",
    "pm": "Saint Pierre and Miquelon national anthem La Marseillaise official",
    "pn": "Pitcairn Islands national anthem God Save the King official",
    "pr": "Puerto Rico national anthem La Borinqueña official",
    "ps": "Palestine national anthem Fida'i official",
    "pt": "Portugal national anthem A Portuguesa official",
    "pw": "Palau national anthem Belau rekid official",
    "py": "Paraguay national anthem Himno Nacional Paraguayo official",
    "qa": "Qatar national anthem As Salam al Amiri official",
    "re": "Réunion national anthem La Marseillaise official",
    "ro": "Romania national anthem Deșteaptă-te române official",
    "rs": "Serbia national anthem Bože pravde official",
    "ru": "Russia national anthem State Anthem of Russian Federation official",
    "rw": "Rwanda national anthem Rwanda nziza official",
    "sa": "Saudi Arabia national anthem Aash Al Maleek official",
    "sb": "Solomon Islands national anthem God Save Our Solomon Islands official",
    "sc": "Seychelles national anthem Koste Seselwa official",
    "sd": "Sudan national anthem Nahnu Djundulla Djundulwatan official",
    "se": "Sweden national anthem Du gamla Du fria official",
    "sg": "Singapore national anthem Majulah Singapura official",
    "sh": "Saint Helena national anthem God Save the King official",
    "si": "Slovenia national anthem Zdravljica official",
    "sj": "Svalbard national anthem Ja vi elsker dette landet official",
    "sk": "Slovakia national anthem Nad Tatrou sa blýska official",
    "sl": "Sierra Leone national anthem High We Exalt Thee Realm of the Free official",
    "sm": "San Marino national anthem Inno Nazionale della Repubblica official",
    "sn": "Senegal national anthem Pincez Tous vos Koras Frappez les Balafons official",
    "so": "Somalia national anthem Soomaaliyeey toosoo official",
    "sr": "Suriname national anthem God zij met ons Suriname official",
    "ss": "South Sudan national anthem South Sudan Oyee official",
    "st": "São Tomé and Príncipe national anthem Independência total official",
    "sv": "El Salvador national anthem Himno Nacional de El Salvador official",
    "sx": "Sint Maarten national anthem O Sweet Saint Martin's Land official",
    "sy": "Syria national anthem Humat ad-Diyar official",
    "sz": "Eswatini national anthem Nkulunkulu Mnikati wetibusiso temaSwati official",
    "tc": "Turks and Caicos Islands national anthem God Save the King official",
    "td": "Chad national anthem La Tchadienne official",
    "tf": "French Southern Territories national anthem La Marseillaise official",
    "tg": "Togo national anthem Salut à toi pays de nos aïeux official",
    "th": "Thailand national anthem Phleng Chat Thai official",
    "tj": "Tajikistan national anthem Surudi milli official",
    "tk": "Tokelau national anthem God Save the King official",
    "tl": "East Timor national anthem Pátria official",
    "tm": "Turkmenistan national anthem Garaşsyz Bitarap Türkmenistanyň döwlet gimni official",
    "tn": "Tunisia national anthem Humat al-Hima official",
    "to": "Tonga national anthem Ko e fasi 'o e tu'i 'o e 'Otu Tonga official",
    "tr": "Turkey national anthem İstiklal Marşı official",
    "tt": "Trinidad and Tobago national anthem Forged from the Love of Liberty official",
    "tv": "Tuvalu national anthem Tuvalu mo te Atua official",
    "tw": "Taiwan national anthem National Anthem of the Republic of China official",
    "tz": "Tanzania national anthem Mungu ibariki Afrika official",
    "ua": "Ukraine national anthem Shche ne vmerla Ukrainy official",
    "ug": "Uganda national anthem Oh Uganda Land of Beauty official",
    "um": "United States Minor Outlying Islands national anthem The Star-Spangled Banner official",
    "us": "United States national anthem The Star-Spangled Banner official",
    "uy": "Uruguay national anthem Himno Nacional official",
    "uz": "Uzbekistan national anthem O'zbekiston Respublikasining Davlat Madhiyasi official",
    "va": "Vatican City national anthem Inno e Marcia Pontificale official",
    "vc": "Saint Vincent and the Grenadines national anthem St Vincent Land so Beautiful official",
    "ve": "Venezuela national anthem Gloria al Bravo Pueblo official",
    "vg": "British Virgin Islands national anthem God Save the King official",
    "vi": "U.S. Virgin Islands national anthem Virgin Islands March official",
    "vn": "Vietnam national anthem Tiến Quân Ca official",
    "vu": "Vanuatu national anthem Yumi Yumi Yumi official",
    "wf": "Wallis and Futuna national anthem La Marseillaise official",
    "ws": "Samoa national anthem The Banner of Freedom official",
    "xk": "Kosovo national anthem Europe official",
    "ye": "Yemen national anthem United Republic official",
    "yt": "Mayotte national anthem La Marseillaise official",
    "za": "South Africa national anthem National Anthem of South Africa official",
    "zm": "Zambia national anthem Lumbanyeni Zambia official",
    "zw": "Zimbabwe national anthem Blessed be the land of Zimbabwe official"
}

def setup_output_directory():
    """Создает выходную директорию"""
    output_path = Path(OUTPUT_DIR)
    output_path.mkdir(exist_ok=True)
    return output_path

def download_anthem_youtube(country_code, search_query, output_path):
    """Загружает гимн с YouTube используя yt-dlp"""
    try:
        print(f"🔍 Поиск гимна для {country_code.upper()}: {search_query}")
        
        # Настройки yt-dlp
        ydl_opts = {
            'format': 'bestaudio[ext=m4a]/bestaudio[ext=mp4]/bestaudio',
            'outtmpl': str(output_path / f'temp_{country_code}.%(ext)s'),
            'quiet': True,
            'no_warnings': True,
            'extract_flat': False,
            'default_search': 'ytsearch1:',  # Ищем только первый результат
            'max_downloads': 1,
            'audio_quality': 0,  # Лучшее качество
        }
        
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            # Загружаем аудио
            ydl.download([search_query])
            
            # Ищем загруженный файл
            temp_files = list(output_path.glob(f'temp_{country_code}.*'))
            if not temp_files:
                print(f"❌ Файл не найден для {country_code}")
                return False
                
            temp_file = temp_files[0]
            final_file = output_path / f"anthem_{country_code}.m4a"
            
            # Конвертируем в M4A с нужными параметрами
            print(f"🔄 Конвертирую {temp_file.name} -> {final_file.name}")
            
            audio = AudioSegment.from_file(temp_file)
            
            # Обрезаем до нужной длительности
            if len(audio) > DURATION_LIMIT * 1000:  # AudioSegment работает в миллисекундах
                audio = audio[:DURATION_LIMIT * 1000]
                print(f"✂️ Обрезано до {DURATION_LIMIT} секунд")
            
            # Нормализация громкости
            audio = audio.normalize()
            
            # Экспорт в M4A
            audio.export(
                final_file,
                format="mp4",  # M4A это MP4 контейнер
                codec="aac",
                bitrate=AUDIO_QUALITY,
                parameters=["-ar", str(SAMPLE_RATE)]
            )
            
            # Удаляем временный файл
            temp_file.unlink()
            
            # Проверяем размер файла
            file_size = final_file.stat().st_size
            print(f"✅ Загружен {country_code.upper()}: {final_file.name} ({file_size/1024/1024:.2f} MB)")
            
            return True
            
    except Exception as e:
        print(f"❌ Ошибка загрузки {country_code}: {str(e)}")
        return False

def create_manifest(output_path, successful_downloads):
    """Создает manifest.json с информацией о загруженных файлах"""
    manifest = {
        "total_countries": len(COUNTRIES_ANTHEMS),
        "downloaded_countries": len(successful_downloads),
        "format": f"M4A (AAC, {AUDIO_QUALITY}, {SAMPLE_RATE}Hz, Stereo)",
        "duration": f"up to {DURATION_LIMIT} seconds",
        "type": "real_anthems",
        "description": "Реальные национальные гимны, загруженные с YouTube",
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
                "size_mb": round(file_size / 1024 / 1024, 2)
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
    print("🎵 Загрузка реальных национальных гимнов")
    print("=" * 50)
    
    # Проверяем зависимости
    try:
        import yt_dlp
        from pydub import AudioSegment
    except ImportError as e:
        print(f"❌ Отсутствует зависимость: {e}")
        print("Установите зависимости:")
        print("pip install yt-dlp pydub")
        sys.exit(1)
    
    # Создаем выходную директорию
    output_path = setup_output_directory()
    print(f"📁 Выходная директория: {output_path}")
    
    successful_downloads = []
    failed_downloads = []
    
    # Загружаем гимны
    total_countries = len(COUNTRIES_ANTHEMS)
    for i, (country_code, search_query) in enumerate(COUNTRIES_ANTHEMS.items(), 1):
        print(f"\n[{i}/{total_countries}] Загружаю {country_code.upper()}")
        
        # Проверяем, не существует ли уже файл
        existing_file = output_path / f"anthem_{country_code}.m4a"
        if existing_file.exists():
            print(f"⏭️ Файл уже существует: {existing_file.name}")
            successful_downloads.append(country_code)
            continue
        
        # Загружаем
        if download_anthem_youtube(country_code, search_query, output_path):
            successful_downloads.append(country_code)
        else:
            failed_downloads.append(country_code)
        
        # Небольшая пауза между загрузками
        time.sleep(2)
    
    # Создаем manifest
    create_manifest(output_path, successful_downloads)
    
    # Итоговая статистика
    print("\n" + "=" * 50)
    print("📊 РЕЗУЛЬТАТЫ ЗАГРУЗКИ")
    print("=" * 50)
    print(f"✅ Успешно загружено: {len(successful_downloads)} из {total_countries}")
    print(f"❌ Ошибки загрузки: {len(failed_downloads)}")
    
    if failed_downloads:
        print(f"\n❌ Не удалось загрузить:")
        for code in failed_downloads:
            print(f"   - {code.upper()}")
    
    print(f"\n📁 Файлы сохранены в: {output_path}")
    print(f"📄 Manifest: {output_path}/manifest.json")
    
    if successful_downloads:
        print(f"\n🚀 Для загрузки на сервер выполните:")
        print(f"   cd {output_path.parent}")
        print(f"   ./upload_to_server.sh")

if __name__ == "__main__":
    main()

