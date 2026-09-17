#!/usr/bin/env python3
"""
Собирает полный каталог стран (~240) для квиза и CountryDatabase.

Входы:
  - ISO3166.swift (alpha-3 ↔ alpha-2)
  - countries_part{1,2,3}.json (существующие rich-записи)
  - встроенные region/meta для всех ISO-кодов + seed для недостающих

Выходы:
  - Resources/game_countries.json
  - Resources/countries_part{1,2,3}.json (merged, переразбитые)
  - Resources/country_regions.json (code → region/subregion для UI)
"""
from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RES = ROOT / "World Arena. Flags" / "Resources"
ISO_SWIFT = ROOT / "World Arena. Flags" / "Extensions" / "ISO3166.swift"
COUNTRY_COORDINATES = json.loads((ROOT / "scripts/data/country_coordinates.json").read_text())

# Не включаем в игровой каталог (необитаемые / без полноценного «флаг-квиза»)
EXCLUDE_FROM_GAME = {"AQ", "BV", "HM", "TF", "GS", "UM"}

# region, subregion для ISO alpha-2
REGION_MAP: dict[str, tuple[str, str]] = {
    # Europe
    **{c: ("Europe", "Europe") for c in [
        "AD","AL","AT","BA","BE","BG","BY","CH","CY","CZ","DE","DK","EE","ES","FI","FR","GB","GI","GR",
        "HR","HU","IE","IS","IT","LI","LT","LU","LV","MC","MD","ME","MK","MT","NL","NO","PL","PT","RO",
        "RS","RU","SE","SI","SK","SM","UA","VA","XK","FO","GG","IM","JE","SJ",
    ]},
    # Asia
    **{c: ("Asia", "Asia") for c in [
        "AE","AF","AM","AZ","BD","BH","BN","BT","CN","GE","HK","ID","IL","IN","IQ","IR","JO","JP","KG",
        "KH","KP","KR","KW","KZ","LA","LB","LK","MM","MN","MO","MV","MY","NP","OM","PH","PK","PS","QA",
        "SA","SG","SY","TH","TJ","TL","TM","TR","TW","UZ","VN","YE","CC","CX","IO",
    ]},
    # Africa
    **{c: ("Africa", "Africa") for c in [
        "AO","BF","BI","BJ","BW","CD","CF","CG","CI","CM","CV","DJ","DZ","EG","EH","ER","ET","GA","GH",
        "GM","GN","GQ","GW","KE","KM","LR","LS","LY","MA","MG","ML","MR","MU","MW","MZ","NA","NE","NG",
        "RE","RW","SC","SD","SL","SN","SO","SS","ST","SZ","TD","TG","TN","TZ","UG","YT","ZA","ZM","ZW",
        "SH",
    ]},
    # Oceania
    **{c: ("Oceania", "Oceania") for c in [
        "AU","FJ","FM","KI","MH","NC","NF","NR","NZ","PG","PW","SB","TO","TV","VU","WS","CK","NU","PF","TK","AS","GU","MP","PN","WF",
    ]},
    # Americas — Northern
    **{c: ("Americas", "Northern America") for c in ["CA", "US", "GL", "BM", "PM"]},
    # Americas — Central
    **{c: ("Americas", "Central America") for c in ["BZ", "CR", "GT", "HN", "MX", "NI", "PA", "SV"]},
    # Americas — Caribbean
    **{c: ("Americas", "Caribbean") for c in [
        "AG","AI","AW","BB","BL","BQ","BS","CU","CW","DM","DO","GD","GP","HT","JM","KN","KY","LC","MF",
        "MQ","MS","PR","SX","TC","TT","VC","VG","VI",
    ]},
    # Americas — South
    **{c: ("Americas", "South America") for c in [
        "AR","BO","BR","CL","CO","EC","FK","GF","GY","PE","PY","SR","UY","VE",
    ]},
}


def flag_emoji(code: str) -> str:
    return "".join(chr(0x1F1E6 + ord(c) - ord("A")) for c in code.upper())


def load_iso() -> dict[str, str]:
    text = ISO_SWIFT.read_text(encoding="utf-8")
    a3_to_a2 = dict(re.findall(r'"([A-Z]{3})":\s*"([A-Z]{2})"', text))
    return {a2: a3 for a3, a2 in a3_to_a2.items()}


def load_existing_parts() -> dict[str, dict]:
    by_code: dict[str, dict] = {}
    for name in ("countries_part1.json", "countries_part2.json", "countries_part3.json"):
        path = RES / name
        if not path.exists():
            continue
        for item in json.loads(path.read_text(encoding="utf-8")):
            code = item["en"]["code"].upper()
            by_code[code] = item
    return by_code


# Seed: недостающие страны. Короткие локализации + факты на en/ru; es/uk/ca/zh — имена/столицы + en-тело где нет перевода.
SEED: dict[str, dict] = {
    "US": {
        "en": ("United States", "Washington, D.C.", "English", "Federal presidential republic", "Joe Biden", "+1", "331,900,000", "US Dollar (USD)", "1776", "9,833,517 km²"),
        "ru": ("США", "Вашингтон", "Английский", "Федеративная президентская республика", "Джо Байден", "+1", "331,900,000", "Доллар США (USD)", "1776", "9,833,517 км²"),
        "es": ("Estados Unidos", "Washington D. C.", "Inglés", "República federal presidencial", "Joe Biden", "+1", "331,900,000", "Dólar estadounidense (USD)", "1776", "9,833,517 km²"),
        "uk": ("США", "Вашингтон", "Англійська", "Федеративна президентська республіка", "Джо Байден", "+1", "331,900,000", "Долар США (USD)", "1776", "9,833,517 км²"),
        "ca": ("Estats Units", "Washington DC", "Anglès", "República federal presidencional", "Joe Biden", "+1", "331,900,000", "Dòlar dels EUA (USD)", "1776", "9,833,517 km²"),
        "zh": ("美国", "华盛顿", "英语", "联邦总统制共和国", "乔·拜登", "+1", "331,900,000", "美元 (USD)", "1776", "9,833,517 km²"),
        "facts_en": [
            "The US has the world's largest economy by nominal GDP.",
            "There are 50 states and one federal district.",
            "The Statue of Liberty was a gift from France in 1886.",
        ],
        "facts_ru": [
            "США — крупнейшая экономика мира по номинальному ВВП.",
            "В стране 50 штатов и федеральный округ Колумбия.",
            "Статуя Свободы — подарок Франции 1886 года.",
        ],
    },
    "CA": {
        "en": ("Canada", "Ottawa", "English, French", "Federal parliamentary constitutional monarchy", "Justin Trudeau", "+1", "38,000,000", "Canadian Dollar (CAD)", "1867", "9,984,670 km²"),
        "ru": ("Канада", "Оттава", "Английский, французский", "Федеративная парламентская конституционная монархия", "Джастин Трюдо", "+1", "38,000,000", "Канадский доллар (CAD)", "1867", "9,984,670 км²"),
        "es": ("Canadá", "Ottawa", "Inglés, francés", "Monarquía constitucional parlamentaria federal", "Justin Trudeau", "+1", "38,000,000", "Dólar canadiense (CAD)", "1867", "9,984,670 km²"),
        "uk": ("Канада", "Оттава", "Англійська, французька", "Федеративна парламентська конституційна монархія", "Джастін Трюдо", "+1", "38,000,000", "Канадський долар (CAD)", "1867", "9,984,670 км²"),
        "ca": ("Canadà", "Ottawa", "Anglès, francès", "Monarquia constitucional parlamentària federal", "Justin Trudeau", "+1", "38,000,000", "Dòlar canadenc (CAD)", "1867", "9,984,670 km²"),
        "zh": ("加拿大", "渥太华", "英语、法语", "联邦议会制君主立宪制", "贾斯汀·特鲁多", "+1", "38,000,000", "加元 (CAD)", "1867", "9,984,670 km²"),
        "facts_en": [
            "Canada is the second-largest country by total area.",
            "It has the world's longest coastline.",
            "Official bilingualism: English and French.",
        ],
        "facts_ru": [
            "Канада — вторая по площади страна мира.",
            "У неё самая длинная береговая линия.",
            "Официальные языки — английский и французский.",
        ],
    },
    "MX": {
        "en": ("Mexico", "Mexico City", "Spanish", "Federal presidential republic", "Claudia Sheinbaum", "+52", "126,000,000", "Mexican Peso (MXN)", "1821", "1,964,375 km²"),
        "ru": ("Мексика", "Мехико", "Испанский", "Федеративная президентская республика", "Клаудия Шейнбаум", "+52", "126,000,000", "Мексиканское песо (MXN)", "1821", "1,964,375 км²"),
        "es": ("México", "Ciudad de México", "Español", "República federal presidencial", "Claudia Sheinbaum", "+52", "126,000,000", "Peso mexicano (MXN)", "1821", "1,964,375 km²"),
        "uk": ("Мексика", "Мехіко", "Іспанська", "Федеративна президентська республіка", "Клаудія Шейнбаум", "+52", "126,000,000", "Мексиканське песо (MXN)", "1821", "1,964,375 км²"),
        "ca": ("Mèxic", "Ciutat de Mèxic", "Castellà", "República federal presidencional", "Claudia Sheinbaum", "+52", "126,000,000", "Pes mexicà (MXN)", "1821", "1,964,375 km²"),
        "zh": ("墨西哥", "墨西哥城", "西班牙语", "联邦总统制共和国", "克劳迪娅·辛鲍姆", "+52", "126,000,000", "墨西哥比索 (MXN)", "1821", "1,964,375 km²"),
        "facts_en": [
            "Mexico City is one of the largest metropolitan areas in the Americas.",
            "Chocolate, corn, and chili have deep roots in Mexican culture.",
            "Mexico has 35 UNESCO World Heritage sites.",
        ],
        "facts_ru": [
            "Мехико — один из крупнейших мегаполисов Америки.",
            "Шоколад, кукуруза и чили — часть мексиканского наследия.",
            "В Мексике 35 объектов ЮНЕСКО.",
        ],
    },
    "BR": {
        "en": ("Brazil", "Brasília", "Portuguese", "Federal presidential republic", "Luiz Inácio Lula da Silva", "+55", "215,000,000", "Brazilian Real (BRL)", "1822", "8,515,767 km²"),
        "ru": ("Бразилия", "Бразилиа", "Португальский", "Федеративная президентская республика", "Луис Инасиу Лула да Силва", "+55", "215,000,000", "Бразильский реал (BRL)", "1822", "8,515,767 км²"),
        "es": ("Brasil", "Brasilia", "Portugués", "República federal presidencial", "Luiz Inácio Lula da Silva", "+55", "215,000,000", "Real brasileño (BRL)", "1822", "8,515,767 km²"),
        "uk": ("Бразилія", "Бразиліа", "Португальська", "Федеративна президентська республіка", "Луїс Інасіу Лула да Сілва", "+55", "215,000,000", "Бразильський реал (BRL)", "1822", "8,515,767 км²"),
        "ca": ("Brasil", "Brasília", "Portuguès", "República federal presidencional", "Luiz Inácio Lula da Silva", "+55", "215,000,000", "Real brasiler (BRL)", "1822", "8,515,767 km²"),
        "zh": ("巴西", "巴西利亚", "葡萄牙语", "联邦总统制共和国", "卢拉", "+55", "215,000,000", "巴西雷亚尔 (BRL)", "1822", "8,515,767 km²"),
        "facts_en": [
            "Brazil is the largest country in South America.",
            "The Amazon rainforest covers a huge part of its territory.",
            "Portuguese is the official language — unique in mainland Latin America.",
        ],
        "facts_ru": [
            "Бразилия — крупнейшая страна Южной Америки.",
            "Амазония занимает огромную часть территории.",
            "Официальный язык — португальский.",
        ],
    },
    "AR": {
        "en": ("Argentina", "Buenos Aires", "Spanish", "Federal presidential republic", "Javier Milei", "+54", "46,000,000", "Argentine Peso (ARS)", "1816", "2,780,400 km²"),
        "ru": ("Аргентина", "Буэнос-Айрес", "Испанский", "Федеративная президентская республика", "Хавьер Милей", "+54", "46,000,000", "Аргентинское песо (ARS)", "1816", "2,780,400 км²"),
        "es": ("Argentina", "Buenos Aires", "Español", "República federal presidencial", "Javier Milei", "+54", "46,000,000", "Peso argentino (ARS)", "1816", "2,780,400 km²"),
        "uk": ("Аргентина", "Буенос-Айрес", "Іспанська", "Федеративна президентська республіка", "Хав'єр Мілей", "+54", "46,000,000", "Аргентинське песо (ARS)", "1816", "2,780,400 км²"),
        "ca": ("Argentina", "Buenos Aires", "Castellà", "República federal presidencional", "Javier Milei", "+54", "46,000,000", "Pes argentí (ARS)", "1816", "2,780,400 km²"),
        "zh": ("阿根廷", "布宜诺斯艾利斯", "西班牙语", "联邦总统制共和国", "哈维尔·米莱", "+54", "46,000,000", "阿根廷比索 (ARS)", "1816", "2,780,400 km²"),
        "facts_en": [
            "Argentina is famous for tango, football, and Patagonia.",
            "It shares the Andes with Chile along a long border.",
            "Spanish is the official language.",
        ],
        "facts_ru": [
            "Аргентина известна танго, футболом и Патагонией.",
            "С Чили её разделяют Анды.",
            "Официальный язык — испанский.",
        ],
    },
    "AU": {
        "en": ("Australia", "Canberra", "English", "Federal parliamentary constitutional monarchy", "Anthony Albanese", "+61", "26,000,000", "Australian Dollar (AUD)", "1901", "7,692,024 km²"),
        "ru": ("Австралия", "Канберра", "Английский", "Федеративная парламентская конституционная монархия", "Энтони Албаниз", "+61", "26,000,000", "Австралийский доллар (AUD)", "1901", "7,692,024 км²"),
        "es": ("Australia", "Canberra", "Inglés", "Monarquía constitucional parlamentaria federal", "Anthony Albanese", "+61", "26,000,000", "Dólar australiano (AUD)", "1901", "7,692,024 km²"),
        "uk": ("Австралія", "Канберра", "Англійська", "Федеративна парламентська конституційна монархія", "Ентоні Албаніз", "+61", "26,000,000", "Австралійський долар (AUD)", "1901", "7,692,024 км²"),
        "ca": ("Austràlia", "Canberra", "Anglès", "Monarquia constitucional parlamentària federal", "Anthony Albanese", "+61", "26,000,000", "Dòlar australià (AUD)", "1901", "7,692,024 km²"),
        "zh": ("澳大利亚", "堪培拉", "英语", "联邦议会制君主立宪制", "安东尼·阿尔巴尼斯", "+61", "26,000,000", "澳元 (AUD)", "1901", "7,692,024 km²"),
        "facts_en": [
            "Australia is both a country and a continent.",
            "It is home to unique wildlife like kangaroos and koalas.",
            "The Great Barrier Reef lies off its northeast coast.",
        ],
        "facts_ru": [
            "Австралия — и страна, и континент.",
            "Здесь живут кенгуру и коалы.",
            "У северо-восточного побережья — Большой Барьерный риф.",
        ],
    },
    "NZ": {
        "en": ("New Zealand", "Wellington", "English, Māori", "Unitary parliamentary constitutional monarchy", "Christopher Luxon", "+64", "5,200,000", "New Zealand Dollar (NZD)", "1907", "268,021 km²"),
        "ru": ("Новая Зеландия", "Веллингтон", "Английский, маори", "Унитарная парламентская конституционная монархия", "Кристофер Лаксон", "+64", "5,200,000", "Новозеландский доллар (NZD)", "1907", "268,021 км²"),
        "es": ("Nueva Zelanda", "Wellington", "Inglés, maorí", "Monarquía constitucional parlamentaria unitaria", "Christopher Luxon", "+64", "5,200,000", "Dólar neozelandés (NZD)", "1907", "268,021 km²"),
        "uk": ("Нова Зеландія", "Веллінгтон", "Англійська, маорі", "Унітарна парламентська конституційна монархія", "Крістофер Лаксон", "+64", "5,200,000", "Новозеландський долар (NZD)", "1907", "268,021 км²"),
        "ca": ("Nova Zelanda", "Wellington", "Anglès, maori", "Monarquia constitucional parlamentària unitària", "Christopher Luxon", "+64", "5,200,000", "Dòlar neozelandès (NZD)", "1907", "268,021 km²"),
        "zh": ("新西兰", "惠灵顿", "英语、毛利语", "单一制议会君主立宪制", "克里斯托弗·拉克森", "+64", "5,200,000", "新西兰元 (NZD)", "1907", "268,021 km²"),
        "facts_en": [
            "New Zealand consists mainly of two islands: North and South.",
            "It was one of the first countries to grant women the vote.",
            "The Māori name for the country is Aotearoa.",
        ],
        "facts_ru": [
            "Новая Зеландия — в основном Северный и Южный острова.",
            "Одна из первых стран, где женщины получили право голоса.",
            "На языке маори страна называется Аотеароа.",
        ],
    },
    "EG": {
        "en": ("Egypt", "Cairo", "Arabic", "Unitary semi-presidential republic", "Abdel Fattah el-Sisi", "+20", "110,000,000", "Egyptian Pound (EGP)", "1922", "1,001,450 km²"),
        "ru": ("Египет", "Каир", "Арабский", "Унитарная смешанная республика", "Абдель Фаттах ас-Сиси", "+20", "110,000,000", "Египетский фунт (EGP)", "1922", "1,001,450 км²"),
        "es": ("Egipto", "El Cairo", "Árabe", "República semipresidencial unitaria", "Abdel Fatah al-Sisi", "+20", "110,000,000", "Libra egipcia (EGP)", "1922", "1,001,450 km²"),
        "uk": ("Єгипет", "Каїр", "Арабська", "Унітарна змішана республіка", "Абдель Фаттах ас-Сісі", "+20", "110,000,000", "Єгипетський фунт (EGP)", "1922", "1,001,450 км²"),
        "ca": ("Egipte", "El Caire", "Àrab", "República semipresidencial unitària", "Abdel Fattah al-Sisi", "+20", "110,000,000", "Lliura egípcia (EGP)", "1922", "1,001,450 km²"),
        "zh": ("埃及", "开罗", "阿拉伯语", "单一制半总统制共和国", "塞西", "+20", "110,000,000", "埃及镑 (EGP)", "1922", "1,001,450 km²"),
        "facts_en": [
            "Ancient Egypt built the pyramids of Giza.",
            "The Nile is the country's lifeline.",
            "Cairo is Africa's largest city by metro population.",
        ],
        "facts_ru": [
            "Древний Египет построил пирамиды Гизы.",
            "Нил — главная водная артерия страны.",
            "Каир — один из крупнейших городов Африки.",
        ],
    },
    "ZA": {
        "en": ("South Africa", "Pretoria", "11 official languages", "Unitary parliamentary republic with executive presidency", "Cyril Ramaphosa", "+27", "60,000,000", "South African Rand (ZAR)", "1910", "1,221,037 km²"),
        "ru": ("ЮАР", "Претория", "11 официальных языков", "Унитарная парламентская республика", "Сирил Рамафоса", "+27", "60,000,000", "Южноафриканский рэнд (ZAR)", "1910", "1,221,037 км²"),
        "es": ("Sudáfrica", "Pretoria", "11 idiomas oficiales", "República parlamentaria unitaria", "Cyril Ramaphosa", "+27", "60,000,000", "Rand sudafricano (ZAR)", "1910", "1,221,037 km²"),
        "uk": ("ПАР", "Преторія", "11 офіційних мов", "Унітарна парламентська республіка", "Сіріл Рамафоса", "+27", "60,000,000", "Південноафриканський ренд (ZAR)", "1910", "1,221,037 км²"),
        "ca": ("Sud-àfrica", "Pretòria", "11 llengües oficials", "República parlamentària unitària", "Cyril Ramaphosa", "+27", "60,000,000", "Rand sud-africà (ZAR)", "1910", "1,221,037 km²"),
        "zh": ("南非", "比勒陀利亚", "11种官方语言", "单一制议会共和制", "西里尔·拉马福萨", "+27", "60,000,000", "南非兰特 (ZAR)", "1910", "1,221,037 km²"),
        "facts_en": [
            "South Africa has three capital cities for different branches of government.",
            "It is famous for safari wildlife and Table Mountain.",
            "Nelson Mandela became president in 1994 after apartheid ended.",
        ],
        "facts_ru": [
            "У ЮАР три столицы для разных ветвей власти.",
            "Страна известна сафари и Столовой горой.",
            "Нельсон Мандела стал президентом в 1994 году.",
        ],
    },
    "CZ": {
        "en": ("Czechia", "Prague", "Czech", "Unitary parliamentary republic", "Petr Pavel", "+420", "10,500,000", "Czech Koruna (CZK)", "1993", "78,871 km²"),
        "ru": ("Чехия", "Прага", "Чешский", "Унитарная парламентская республика", "Петр Павел", "+420", "10,500,000", "Чешская крона (CZK)", "1993", "78,871 км²"),
        "es": ("Chequia", "Praga", "Checo", "República parlamentaria unitaria", "Petr Pavel", "+420", "10,500,000", "Corona checa (CZK)", "1993", "78,871 km²"),
        "uk": ("Чехія", "Прага", "Чеська", "Унітарна парламентська республіка", "Петр Павел", "+420", "10,500,000", "Чеська крона (CZK)", "1993", "78,871 км²"),
        "ca": ("Txèquia", "Praga", "Txec", "República parlamentària unitària", "Petr Pavel", "+420", "10,500,000", "Corona txeca (CZK)", "1993", "78,871 km²"),
        "zh": ("捷克", "布拉格", "捷克语", "单一制议会共和制", "彼得·帕维尔", "+420", "10,500,000", "捷克克朗 (CZK)", "1993", "78,871 km²"),
        "facts_en": [
            "Prague's historic centre is a UNESCO World Heritage site.",
            "Czechia was part of Czechoslovakia until 1993.",
            "It is known for beer culture and castles.",
        ],
        "facts_ru": [
            "Исторический центр Праги — объект ЮНЕСКО.",
            "Чехия вышла из Чехословакии в 1993 году.",
            "Страна известна пивной культурой и замками.",
        ],
    },
}


# Компактные записи для остальных недостающих (имя/столица по языкам).
# Формат: code -> {lang: (name, capital), dial, currency, pop, area, independence, language, government, leader}
COMPACT: dict[str, dict] = {
    "AM": {"en": ("Armenia", "Yerevan"), "ru": ("Армения", "Ереван"), "es": ("Armenia", "Ereván"), "uk": ("Вірменія", "Єреван"), "ca": ("Armènia", "Erevan"), "zh": ("亚美尼亚", "埃里温"),
           "meta": ("+374", "Armenian Dram (AMD)", "2,800,000", "29,743 km²", "1991", "Armenian", "Unitary parliamentary republic", "Vahagn Khachaturyan")},
    "AZ": {"en": ("Azerbaijan", "Baku"), "ru": ("Азербайджан", "Баку"), "es": ("Azerbaiyán", "Bakú"), "uk": ("Азербайджан", "Баку"), "ca": ("Azerbaidjan", "Bakú"), "zh": ("阿塞拜疆", "巴库"),
           "meta": ("+994", "Azerbaijani Manat (AZN)", "10,200,000", "86,600 km²", "1991", "Azerbaijani", "Unitary semi-presidential republic", "Ilham Aliyev")},
    "TW": {"en": ("Taiwan", "Taipei"), "ru": ("Тайвань", "Тайбэй"), "es": ("Taiwán", "Taipéi"), "uk": ("Тайвань", "Тайбей"), "ca": ("Taiwan", "Taipei"), "zh": ("台湾", "台北"),
           "meta": ("+886", "New Taiwan Dollar (TWD)", "23,500,000", "36,197 km²", "1912", "Mandarin Chinese", "Unitary semi-presidential republic", "Lai Ching-te")},
    "XK": {"en": ("Kosovo", "Pristina"), "ru": ("Косово", "Приштина"), "es": ("Kosovo", "Prístina"), "uk": ("Косово", "Приштина"), "ca": ("Kosovo", "Pristina"), "zh": ("科索沃", "普里什蒂纳"),
           "meta": ("+383", "Euro (EUR)", "1,800,000", "10,887 km²", "2008", "Albanian, Serbian", "Unitary parliamentary republic", "Vjosa Osmani")},
    "HK": {"en": ("Hong Kong", "Hong Kong"), "ru": ("Гонконг", "Гонконг"), "es": ("Hong Kong", "Hong Kong"), "uk": ("Гонконг", "Гонконг"), "ca": ("Hong Kong", "Hong Kong"), "zh": ("香港", "香港"),
           "meta": ("+852", "Hong Kong Dollar (HKD)", "7,500,000", "1,106 km²", "—", "Chinese, English", "Special administrative region", "John Lee")},
    "MO": {"en": ("Macau", "Macau"), "ru": ("Макао", "Макао"), "es": ("Macao", "Macao"), "uk": ("Макао", "Макао"), "ca": ("Macau", "Macau"), "zh": ("澳门", "澳门"),
           "meta": ("+853", "Macanese Pataca (MOP)", "680,000", "115 km²", "—", "Chinese, Portuguese", "Special administrative region", "Ho Iat Seng")},
    "PR": {"en": ("Puerto Rico", "San Juan"), "ru": ("Пуэрто-Рико", "Сан-Хуан"), "es": ("Puerto Rico", "San Juan"), "uk": ("Пуерто-Рико", "Сан-Хуан"), "ca": ("Puerto Rico", "San Juan"), "zh": ("波多黎各", "圣胡安"),
           "meta": ("+1", "US Dollar (USD)", "3,200,000", "9,104 km²", "—", "Spanish, English", "Unincorporated US territory", "Pedro Pierluisi")},
    "GL": {"en": ("Greenland", "Nuuk"), "ru": ("Гренландия", "Нуук"), "es": ("Groenlandia", "Nuuk"), "uk": ("Гренландія", "Нуук"), "ca": ("Grenlàndia", "Nuuk"), "zh": ("格陵兰", "努克"),
           "meta": ("+299", "Danish Krone (DKK)", "56,000", "2,166,086 km²", "—", "Greenlandic", "Autonomous territory of Denmark", "Múte Bourup Egede")},
    "IS": None,  # already in DB often
}


# Дополнительный компактный список остальных недостающих кодов (имя EN/RU + столица).
EXTRA_NAMES: dict[str, dict[str, tuple[str, str]]] = {
    "AI": {"en": ("Anguilla", "The Valley"), "ru": ("Ангилья", "Валли")},
    "AS": {"en": ("American Samoa", "Pago Pago"), "ru": ("Американское Самоа", "Паго-Паго")},
    "AW": {"en": ("Aruba", "Oranjestad"), "ru": ("Аруба", "Ораньестад")},
    "BL": {"en": ("Saint Barthélemy", "Gustavia"), "ru": ("Сен-Бартелеми", "Густавия")},
    "BM": {"en": ("Bermuda", "Hamilton"), "ru": ("Бермуды", "Гамильтон")},
    "BQ": {"en": ("Caribbean Netherlands", "Kralendijk"), "ru": ("Карибские Нидерланды", "Кралендейк")},
    "CK": {"en": ("Cook Islands", "Avarua"), "ru": ("Острова Кука", "Аваруа")},
    "CW": {"en": ("Curaçao", "Willemstad"), "ru": ("Кюрасао", "Виллемстад")},
    "FK": {"en": ("Falkland Islands", "Stanley"), "ru": ("Фолклендские острова", "Стэнли")},
    "FO": {"en": ("Faroe Islands", "Tórshavn"), "ru": ("Фарерские острова", "Торсхавн")},
    "GF": {"en": ("French Guiana", "Cayenne"), "ru": ("Французская Гвиана", "Кайенна")},
    "GG": {"en": ("Guernsey", "Saint Peter Port"), "ru": ("Гернси", "Сент-Питер-Порт")},
    "GI": {"en": ("Gibraltar", "Gibraltar"), "ru": ("Гибралтар", "Гибралтар")},
    "GP": {"en": ("Guadeloupe", "Basse-Terre"), "ru": ("Гваделупа", "Бас-Тер")},
    "GU": {"en": ("Guam", "Hagåtña"), "ru": ("Гуам", "Хагатна")},
    "IM": {"en": ("Isle of Man", "Douglas"), "ru": ("Остров Мэн", "Дуглас")},
    "JE": {"en": ("Jersey", "Saint Helier"), "ru": ("Джерси", "Сент-Хелиер")},
    "KY": {"en": ("Cayman Islands", "George Town"), "ru": ("Каймановы острова", "Джорджтаун")},
    "MF": {"en": ("Saint Martin", "Marigot"), "ru": ("Сен-Мартен", "Мариго")},
    "MP": {"en": ("Northern Mariana Islands", "Saipan"), "ru": ("Северные Марианские острова", "Сайпан")},
    "MQ": {"en": ("Martinique", "Fort-de-France"), "ru": ("Мартиника", "Фор-де-Франс")},
    "MS": {"en": ("Montserrat", "Plymouth"), "ru": ("Монтсеррат", "Плимут")},
    "NC": {"en": ("New Caledonia", "Nouméa"), "ru": ("Новая Каледония", "Нумеа")},
    "NU": {"en": ("Niue", "Alofi"), "ru": ("Ниуэ", "Алофи")},
    "PF": {"en": ("French Polynesia", "Papeete"), "ru": ("Французская Полинезия", "Папеэте")},
    "PM": {"en": ("Saint Pierre and Miquelon", "Saint-Pierre"), "ru": ("Сен-Пьер и Микелон", "Сен-Пьер")},
    "RE": {"en": ("Réunion", "Saint-Denis"), "ru": ("Реюньон", "Сен-Дени")},
    "SH": {"en": ("Saint Helena", "Jamestown"), "ru": ("Остров Святой Елены", "Джеймстаун")},
    "SJ": {"en": ("Svalbard and Jan Mayen", "Longyearbyen"), "ru": ("Шпицберген и Ян-Майен", "Лонгйир")},
    "SX": {"en": ("Sint Maarten", "Philipsburg"), "ru": ("Синт-Мартен", "Филипсбург")},
    "TC": {"en": ("Turks and Caicos Islands", "Cockburn Town"), "ru": ("Теркс и Кайкос", "Коберн-Таун")},
    "VG": {"en": ("British Virgin Islands", "Road Town"), "ru": ("Британские Виргинские острова", "Род-Таун")},
    "VI": {"en": ("U.S. Virgin Islands", "Charlotte Amalie"), "ru": ("Виргинские острова США", "Шарлотта-Амалия")},
    "WF": {"en": ("Wallis and Futuna", "Mata-Utu"), "ru": ("Уоллис и Футуна", "Мата-Уту")},
    "YT": {"en": ("Mayotte", "Mamoudzou"), "ru": ("Майотта", "Мамудзу")},
    "EH": {"en": ("Western Sahara", "Laayoune"), "ru": ("Западная Сахара", "Эль-Аюн")},
    "CC": {"en": ("Cocos Islands", "West Island"), "ru": ("Кокосовые острова", "Уэст-Айленд")},
    "CX": {"en": ("Christmas Island", "Flying Fish Cove"), "ru": ("Остров Рождества", "Флайн-Фиш-Ков")},
    "IO": {"en": ("British Indian Ocean Territory", "Diego Garcia"), "ru": ("Британская территория в Индийском океане", "Диего-Гарсия")},
    "NF": {"en": ("Norfolk Island", "Kingston"), "ru": ("Остров Норфолк", "Кингстон")},
    "PN": {"en": ("Pitcairn Islands", "Adamstown"), "ru": ("Острова Питкэрн", "Адамстаун")},
    "TK": {"en": ("Tokelau", "Fakaofo"), "ru": ("Токелау", "Факаофо")},
    "AQ": {"en": ("Antarctica", "—"), "ru": ("Антарктида", "—")},
    "BV": {"en": ("Bouvet Island", "—"), "ru": ("Остров Буве", "—")},
    "HM": {"en": ("Heard Island", "—"), "ru": ("Остров Херд", "—")},
    "TF": {"en": ("French Southern Territories", "—"), "ru": ("Французские Южные территории", "—")},
    "GS": {"en": ("South Georgia", "King Edward Point"), "ru": ("Южная Георгия", "Кинг-Эдуард-Пойнт")},
    "UM": {"en": ("U.S. Minor Outlying Islands", "—"), "ru": ("Внешние малые острова США", "—")},
}


def parse_pop(s: str) -> int:
    digits = re.sub(r"[^0-9]", "", s or "")
    return int(digits) if digits else 1


def parse_area(s: str) -> float | None:
    if not s or s.strip() in {"—", "-"}:
        return None
    m = re.search(r"([0-9][0-9,\.\s]*)", s)
    if not m:
        return None
    try:
        return float(m.group(1).replace(" ", "").replace(",", ""))
    except ValueError:
        return None


def make_lang_block(
    code: str,
    lang: str,
    name: str,
    capital: str,
    official_language: str,
    government: str,
    leader: str,
    dial: str,
    population: str,
    currency: str,
    independence: str,
    area: str,
    facts: list[str],
    description: str,
    flag_description: str,
    anthem_description: str,
    anthem_meaning: str,
) -> dict:
    return {
        "code": code,
        "name": name,
        "flag": flag_emoji(code),
        "capital": capital,
        "officialLanguage": official_language,
        "government": government,
        "leader": leader,
        "dialingCode": dial,
        "population": population,
        "currency": currency,
        "independence": independence,
        "area": area,
        "description": description,
        "flagDescription": flag_description,
        "anthemDescription": anthem_description,
        "anthemMeaning": anthem_meaning,
        "photos": [f"flag_{code.lower()}"],
        "anthemAudio": f"anthem_{code.lower()}",
        "interestingFacts": facts,
    }


def build_from_seed(code: str, seed: dict) -> dict:
    out = {}
    facts_en = seed.get("facts_en") or [
        f"{seed['en'][0]} is a country represented in World Arena Flags.",
        f"Its capital is {seed['en'][1]}.",
        f"Calling code: {seed['en'][5]}.",
    ]
    facts_ru = seed.get("facts_ru") or facts_en
    for lang in ("en", "ru", "es", "uk", "ca", "zh"):
        t = seed[lang]
        name, capital, lang_name, gov, leader, dial, pop, cur, indep, area = t
        facts = facts_ru if lang in {"ru", "uk"} else facts_en
        desc = (
            f"{name} — государство с столицей {capital}."
            if lang in {"ru", "uk"}
            else f"{name} is a country with capital {capital}."
        )
        flag_d = (
            f"Национальный флаг {name}."
            if lang in {"ru", "uk"}
            else f"The national flag of {name}."
        )
        anthem_d = (
            f"Государственный гимн {name}."
            if lang in {"ru", "uk"}
            else f"The national anthem of {name}."
        )
        anthem_m = (
            "Гимн отражает историю и культуру страны."
            if lang in {"ru", "uk"}
            else "The anthem reflects the country's history and culture."
        )
        out[lang] = make_lang_block(
            code, lang, name, capital, lang_name, gov, leader, dial, pop, cur, indep, area,
            facts, desc, flag_d, anthem_d, anthem_m,
        )
    return out


def build_from_compact(code: str, compact: dict) -> dict:
    dial, cur, pop, area, indep, language, gov, leader = compact["meta"]
    out = {}
    for lang in ("en", "ru", "es", "uk", "ca", "zh"):
        name, capital = compact[lang]
        facts = [
            f"{name} — capital {capital}.",
            f"Currency: {cur}.",
            f"Calling code: {dial}.",
        ]
        if lang in {"ru", "uk"}:
            facts = [
                f"{name} — столица {capital}.",
                f"Валюта: {cur}.",
                f"Телефонный код: {dial}.",
            ]
        desc = f"{name} / {capital}."
        out[lang] = make_lang_block(
            code, lang, name, capital, language, gov, leader, dial, pop, cur, indep, area,
            facts, desc, f"Flag of {name}.", f"Anthem of {name}.", "National anthem.",
        )
    return out


DIAL_CODES = {
    "AI": "+1", "AS": "+1", "AW": "+297", "BL": "+590", "BM": "+1", "BQ": "+599",
    "CK": "+682", "CW": "+599", "FK": "+500", "FO": "+298", "GF": "+594", "GG": "+44",
    "GI": "+350", "GP": "+590", "GU": "+1", "IM": "+44", "JE": "+44", "KY": "+1",
    "MF": "+590", "MP": "+1", "MQ": "+596", "MS": "+1", "NC": "+687", "NU": "+683",
    "PF": "+689", "PM": "+508", "RE": "+262", "SH": "+290", "SJ": "+47", "SX": "+1",
    "TC": "+1", "VG": "+1", "VI": "+1", "WF": "+681", "YT": "+262", "EH": "+212",
    "CC": "+61", "CX": "+61", "IO": "+246", "NF": "+672", "PN": "+64", "TK": "+690",
    "AQ": "", "BV": "", "HM": "", "TF": "", "GS": "+500", "UM": "+1",
}


def build_from_extra(code: str, names: dict[str, tuple[str, str]]) -> dict:
    en_name, en_cap = names.get("en", (code, "—"))
    ru_name, ru_cap = names.get("ru", (en_name, en_cap))
    region, sub = REGION_MAP.get(code, ("Americas", "Caribbean"))
    dial = DIAL_CODES.get(code, "—") or "—"
    cur = "—"
    pop = "—"
    area = "—"
    out = {}
    for lang, (name, capital) in {
        "en": (en_name, en_cap),
        "ru": (ru_name, ru_cap),
        "es": (en_name, en_cap),
        "uk": (ru_name, ru_cap),
        "ca": (en_name, en_cap),
        "zh": (en_name, en_cap),
    }.items():
        facts = [
            f"{name} is listed in the World Arena country catalog.",
            f"Region: {region} / {sub}.",
            f"ISO code: {code}. Calling code: {dial}.",
        ]
        if lang in {"ru", "uk"}:
            facts = [
                f"{name} входит в каталог World Arena.",
                f"Регион: {region} / {sub}.",
                f"Код ISO: {code}. Телефон: {dial}.",
            ]
        out[lang] = make_lang_block(
            code, lang, name, capital, "—", "—", "—", dial, pop, cur, "—", area,
            facts,
            f"{name}.",
            f"Flag of {name}.",
            f"Anthem of {name}.",
            "National anthem.",
        )
    return out


def to_game_country(code: str, a2_to_a3: dict[str, str], item: dict) -> dict | None:
    a3 = a2_to_a3.get(code)
    if not a3:
        return None
    region, sub = REGION_MAP.get(code, ("Americas", "Caribbean"))
    en = item["en"]
    return {
        "cca3": a3,
        "name": {
            "common": en["name"],
            "official": en["name"],
            "nativeName": {"eng": {"official": en["name"], "common": en["name"]}},
        },
        "flags": {"png": f"https://flagcdn.com/w320/{code.lower()}.png"},
        "region": region,
        "subregion": sub,
        "capital": [en["capital"]] if en.get("capital") and en["capital"] != "—" else [],
        "population": parse_pop(en.get("population", "")),
        "area": parse_area(en.get("area", "")),
        "translations": None,
        "latlng": COUNTRY_COORDINATES[a3],
    }


def main() -> None:
    a2_to_a3 = load_iso()
    existing = load_existing_parts()
    print(f"ISO codes: {len(a2_to_a3)}; existing DB: {len(existing)}")

    # Fill missing LocalizedCountryData
    for code in sorted(a2_to_a3.keys()):
        if code in existing:
            continue
        if code in SEED:
            existing[code] = build_from_seed(code, SEED[code])
        elif code in COMPACT and COMPACT[code] is not None:
            existing[code] = build_from_compact(code, COMPACT[code])
        elif code in EXTRA_NAMES:
            existing[code] = build_from_extra(code, EXTRA_NAMES[code])
        else:
            # Generic fallback from code
            existing[code] = build_from_extra(code, {"en": (code, "—"), "ru": (code, "—")})

    # Ensure major seeds overwrite weak placeholders if somehow present partially
    for code, seed in SEED.items():
        existing[code] = build_from_seed(code, seed)
    for code, compact in COMPACT.items():
        if compact is not None:
            existing[code] = build_from_compact(code, compact)

    all_codes = sorted(existing.keys())
    print(f"Total LocalizedCountryData: {len(all_codes)}")

    # Split into 3 parts
    n = len(all_codes)
    cuts = [n // 3, 2 * n // 3, n]
    start = 0
    for i, end in enumerate(cuts, 1):
        chunk = [existing[c] for c in all_codes[start:end]]
        path = RES / f"countries_part{i}.json"
        path.write_text(json.dumps(chunk, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(f"wrote {path.name}: {len(chunk)}")
        start = end

    # game_countries
    game = []
    regions_index = {}
    for code in all_codes:
        if code in EXCLUDE_FROM_GAME:
            continue
        if code not in REGION_MAP:
            # skip unknown region mapping edge cases still add with Americas/Caribbean default
            REGION_MAP[code] = ("Americas", "Caribbean")
        gc = to_game_country(code, a2_to_a3, existing[code])
        if gc:
            game.append(gc)
            regions_index[code] = {"region": gc["region"], "subregion": gc["subregion"], "cca3": gc["cca3"]}

    game.sort(key=lambda x: x["cca3"])
    (RES / "game_countries.json").write_text(
        json.dumps(game, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    (RES / "country_regions.json").write_text(
        json.dumps(regions_index, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    from collections import Counter
    print(f"game_countries: {len(game)}")
    print("by region:", dict(Counter(x["region"] for x in game)))


if __name__ == "__main__":
    main()
