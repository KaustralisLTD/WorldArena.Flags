#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Улучшенный скрипт для извлечения данных из Swift файлов CountryDatabasePart*.swift
"""

import re
import json
import os
from typing import List, Dict, Any

def find_matching_paren(text: str, start_pos: int) -> int:
    """Находит позицию закрывающей скобки для открывающей скобки на start_pos."""
    depth = 1
    pos = start_pos + 1
    while pos < len(text) and depth > 0:
        if text[pos] == '(':
            depth += 1
        elif text[pos] == ')':
            depth -= 1
        pos += 1
    return pos - 1 if depth == 0 else -1

def extract_string_value(text: str, start_pos: int) -> tuple:
    """Извлекает строковое значение, учитывая экранирование."""
    if start_pos >= len(text) or text[start_pos] != '"':
        return None, start_pos
    
    pos = start_pos + 1
    result = []
    escaped = False
    
    while pos < len(text):
        char = text[pos]
        if escaped:
            if char == 'n':
                result.append('\n')
            elif char == 't':
                result.append('\t')
            elif char == 'r':
                result.append('\r')
            elif char == '\\':
                result.append('\\')
            elif char == '"':
                result.append('"')
            else:
                result.append(char)
            escaped = False
        elif char == '\\':
            escaped = True
        elif char == '"':
            return ''.join(result), pos + 1
        else:
            result.append(char)
        pos += 1
    
    return ''.join(result), pos

def parse_country_data_block(block: str) -> Dict[str, Any]:
    """Парсит блок CountryData и извлекает все поля."""
    data = {}
    
    # Простые строковые поля
    simple_fields = {
        'code': r'code:\s*"([^"]+)"',
        'name': r'name:\s*"([^"]+)"',
        'flag': r'flag:\s*"([^"]+)"',
        'capital': r'capital:\s*"([^"]+)"',
        'officialLanguage': r'officialLanguage:\s*"([^"]+)"',
        'government': r'government:\s*"([^"]+)"',
        'leader': r'leader:\s*"([^"]+)"',
        'dialingCode': r'dialingCode:\s*"([^"]+)"',
        'population': r'population:\s*"([^"]+)"',
        'currency': r'currency:\s*"([^"]+)"',
        'independence': r'independence:\s*"([^"]+)"',
        'area': r'area:\s*"([^"]+)"',
        'anthemAudio': r'anthemAudio:\s*"([^"]+)"',
    }
    
    for field, pattern in simple_fields.items():
        match = re.search(pattern, block)
        if match:
            data[field] = match.group(1)
    
    # Многострочные поля - используем более гибкий подход
    multiline_fields = ['description', 'flagDescription', 'anthemDescription', 'anthemMeaning']
    for field in multiline_fields:
        # Ищем поле: field: "..." или field: """..."""
        pattern = rf'{field}:\s*"'
        match = re.search(pattern, block)
        if match:
            start = match.end()
            value, end_pos = extract_string_value(block, start - 1)
            if value is not None:
                data[field] = value
    
    # Массивы photos
    photos_match = re.search(r'photos:\s*\[', block)
    if photos_match:
        start = photos_match.end()
        # Находим закрывающую скобку массива
        depth = 1
        pos = start
        while pos < len(block) and depth > 0:
            if block[pos] == '[':
                depth += 1
            elif block[pos] == ']':
                depth -= 1
            pos += 1
        
        if depth == 0:
            array_content = block[start:pos-1]
            photos = []
            for item_match in re.finditer(r'"([^"]+)"', array_content):
                photos.append(item_match.group(1))
            data['photos'] = photos
        else:
            data['photos'] = []
    else:
        data['photos'] = []
    
    # Массив interestingFacts
    facts_match = re.search(r'interestingFacts:\s*\[', block)
    if facts_match:
        start = facts_match.end()
        depth = 1
        pos = start
        while pos < len(block) and depth > 0:
            if block[pos] == '[':
                depth += 1
            elif block[pos] == ']':
                depth -= 1
            pos += 1
        
        if depth == 0:
            array_content = block[start:pos-1]
            facts = []
            for item_match in re.finditer(r'"([^"]+)"', array_content):
                facts.append(item_match.group(1))
            data['interestingFacts'] = facts
        else:
            data['interestingFacts'] = []
    else:
        data['interestingFacts'] = []
    
    return data

def parse_localized_country_data(content: str) -> List[Dict[str, Any]]:
    """Парсит весь файл и извлекает все LocalizedCountryData объекты."""
    countries = []
    
    # Находим все вхождения LocalizedCountryData(
    pattern = r'LocalizedCountryData\s*\('
    pos = 0
    
    while True:
        match = re.search(pattern, content[pos:])
        if not match:
            break
        
        start_pos = pos + match.end() - 1  # Позиция открывающей скобки
        end_pos = find_matching_paren(content, start_pos)
        
        if end_pos == -1:
            pos = start_pos + 1
            continue
        
        block = content[start_pos + 1:end_pos]
        country_data = {}
        
        # Извлекаем данные для каждого языка
        languages = ['ru', 'en', 'es', 'uk', 'ca', 'zh']
        
        for lang in languages:
            lang_pattern = rf'{lang}:\s*CountryData\s*\('
            lang_match = re.search(lang_pattern, block)
            
            if lang_match:
                lang_start = pos + match.start() + len(match.group(0)) + block.find(lang_match.group(0)) + len(lang_match.group(0)) - 1
                # Пересчитываем относительно начала блока
                block_start = block.find(lang_match.group(0)) + len(lang_match.group(0))
                lang_start_in_block = block_start - 1
                
                # Находим открывающую скобку CountryData
                paren_pos = block.find('(', lang_start_in_block)
                if paren_pos != -1:
                    lang_end = find_matching_paren(block, paren_pos)
                    if lang_end != -1:
                        data_block = block[paren_pos + 1:lang_end]
                        country_data[lang] = parse_country_data_block(data_block)
        
        if country_data and len(country_data) == 6:
            countries.append(country_data)
        
        pos = end_pos + 1
    
    return countries

def main():
    """Основная функция."""
    base_path = "World Arena. Flags/Models"
    output_path = "World Arena. Flags/Resources"
    
    files = [
        ("CountryDatabasePart1.swift", "countries_part1.json"),
        ("CountryDatabasePart2.swift", "countries_part2.json"),
        ("CountryDatabasePart3.swift", "countries_part3.json"),
    ]
    
    total_countries = 0
    
    for swift_file, json_file in files:
        swift_path = os.path.join(base_path, swift_file)
        json_path = os.path.join(output_path, json_file)
        
        if not os.path.exists(swift_path):
            print(f"⚠️ Файл не найден: {swift_path}")
            continue
        
        print(f"📖 Обработка {swift_file}...")
        
        try:
            with open(swift_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Подсчитываем количество LocalizedCountryData вручную
            manual_count = len(re.findall(r'LocalizedCountryData\s*\(', content))
            print(f"   Найдено LocalizedCountryData блоков: {manual_count}")
            
            countries = parse_localized_country_data(content)
            print(f"   ✅ Успешно извлечено: {len(countries)} стран")
            
            if len(countries) != manual_count:
                print(f"   ⚠️ Предупреждение: извлечено {len(countries)}, ожидалось {manual_count}")
            
            # Сохраняем в JSON
            os.makedirs(output_path, exist_ok=True)
            with open(json_path, 'w', encoding='utf-8') as f:
                json.dump(countries, f, ensure_ascii=False, indent=2)
            
            print(f"   💾 Сохранено в {json_path}\n")
            total_countries += len(countries)
            
        except Exception as e:
            print(f"   ❌ Ошибка при обработке {swift_file}: {e}")
            import traceback
            traceback.print_exc()
    
    print(f"🎉 Готово! Всего извлечено: {total_countries} стран из JSON файлов")

if __name__ == "__main__":
    main()
