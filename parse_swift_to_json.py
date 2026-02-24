#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Скрипт для парсинга Swift массива LocalizedCountryData и создания JSON файлов
"""

import json
import re

def find_matching_paren(content, start_pos):
    """Находит соответствующую закрывающую скобку"""
    if start_pos >= len(content) or content[start_pos] != '(':
        return -1
    
    count = 1
    pos = start_pos + 1
    in_string = False
    escape = False
    
    while pos < len(content) and count > 0:
        char = content[pos]
        
        if escape:
            escape = False
            pos += 1
            continue
        
        if char == '\\':
            escape = True
            pos += 1
            continue
        
        if char == '"' and not escape:
            in_string = not in_string
            pos += 1
            continue
        
        if not in_string:
            if char == '(':
                count += 1
            elif char == ')':
                count -= 1
        
        pos += 1
    
    return pos if count == 0 else -1

def extract_string(content, start_pos):
    """Извлекает строку в кавычках"""
    if start_pos >= len(content) or content[start_pos] != '"':
        return None, start_pos
    
    pos = start_pos + 1
    result = []
    escape = False
    
    while pos < len(content):
        char = content[pos]
        
        if escape:
            if char == 'n':
                result.append('\n')
            elif char == 't':
                result.append('\t')
            elif char == '\\':
                result.append('\\')
            elif char == '"':
                result.append('"')
            else:
                result.append(char)
            escape = False
        elif char == '\\':
            escape = True
        elif char == '"':
            return ''.join(result), pos + 1
        else:
            result.append(char)
        
        pos += 1
    
    return None, start_pos

def extract_array(content, start_pos):
    """Извлекает массив строк"""
    pos = start_pos
    while pos < len(content) and content[pos] != '[':
        pos += 1
    
    if pos >= len(content):
        return None, start_pos
    
    pos += 1
    result = []
    
    while pos < len(content):
        while pos < len(content) and content[pos] in ' \n\t':
            pos += 1
        
        if pos >= len(content):
            break
        
        if content[pos] == ']':
            return result, pos + 1
        
        if content[pos] == '"':
            value, new_pos = extract_string(content, pos)
            if value is not None:
                result.append(value)
                pos = new_pos
                while pos < len(content) and content[pos] in ' \n\t,':
                    pos += 1
            else:
                pos += 1
        else:
            pos += 1
    
    return result, pos

def parse_country_data_block(block_content):
    """Парсит блок CountryData(...)"""
    data = {}
    
    fields = [
        'code', 'name', 'flag', 'capital', 'officialLanguage', 'government',
        'leader', 'dialingCode', 'population', 'currency', 'independence', 'area',
        'description', 'flagDescription', 'anthemDescription', 'anthemMeaning',
        'photos', 'anthemAudio', 'interestingFacts'
    ]
    
    for field in fields:
        # Ищем field: значение
        pattern = rf'{re.escape(field)}:\s*'
        match = re.search(pattern, block_content)
        if not match:
            continue
        
        value_start = match.end()
        
        # Пропускаем пробелы
        while value_start < len(block_content) and block_content[value_start] in ' \n\t':
            value_start += 1
        
        if value_start >= len(block_content):
            continue
        
        # Если массив
        if block_content[value_start] == '[':
            value, _ = extract_array(block_content, value_start)
            if value is not None:
                data[field] = value
        # Если строка
        elif block_content[value_start] == '"':
            value, _ = extract_string(block_content, value_start)
            if value is not None:
                data[field] = value
    
    return data

def parse_localized_block(content, block_start):
    """Парсит один блок LocalizedCountryData"""
    # Находим конец блока используя правильный подсчет скобок
    end_pos = find_matching_paren(content, block_start)
    if end_pos == -1:
        return None, block_start
    
    # Извлекаем содержимое блока (без внешних скобок)
    # block_start указывает на открывающую скобку LocalizedCountryData(, поэтому содержимое начинается с block_start + 1
    block_content = content[block_start + 1:end_pos - 1]
    
    country = {}
    
    # Парсим каждый язык
    for lang in ['ru', 'en', 'es', 'uk', 'ca', 'zh']:
        # Ищем lang: CountryData(...)
        pattern = rf'{re.escape(lang)}:\s*CountryData\s*\('
        match = re.search(pattern, block_content)
        if not match:
            continue
        
        # Находим начало CountryData( в полном контенте
        lang_start_in_block = match.end() - 1  # Включаем открывающую скобку
        lang_start_absolute = block_start + 1 + lang_start_in_block  # block_start + 1 это начало содержимого блока
        
        # Находим конец CountryData(...)
        lang_end = find_matching_paren(content, lang_start_absolute)
        if lang_end == -1:
            continue
        
        # Извлекаем содержимое CountryData(...)
        lang_block = content[lang_start_absolute + 1:lang_end - 1]
        lang_data = parse_country_data_block(lang_block)
        
        if lang_data and 'code' in lang_data:
            country[lang] = lang_data
    
    return country if len(country) == 6 else None, end_pos

def main():
    swift_file = "World Arena. Flags/Models/Temporary-CountryDatabase"
    output_dir = "World Arena. Flags/Resources"
    
    print("Парсинг Swift файла...")
    
    with open(swift_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Находим все позиции LocalizedCountryData(
    pattern = r'LocalizedCountryData\s*\('
    matches = list(re.finditer(pattern, content))
    
    print(f"Найдено вхождений LocalizedCountryData: {len(matches)}")
    
    countries = []
    
    for i, match in enumerate(matches):
        block_start = match.end() - 1  # Включаем открывающую скобку
        country_data, block_end = parse_localized_block(content, block_start)
        
        if country_data and len(country_data) == 6:
            countries.append(country_data)
        elif i < 5:  # Выводим отладочную информацию для первых 5 блоков
            print(f"Блок {i+1}: не удалось распарсить (найдено языков: {len(country_data) if country_data else 0})")
    
    print(f"Успешно распарсено стран: {len(countries)}")
    
    if len(countries) == 0:
        print("❌ Ошибка: не найдено ни одной страны!")
        # Отладочная информация
        if matches:
            test_block_start = matches[0].end() - 1
            test_block_content = content[test_block_start:test_block_start + 500]
            print(f"Первые 500 символов первого блока: {test_block_content}")
        return
    
    # Разбиваем на 3 части
    total = len(countries)
    part1_size = total // 3
    part2_size = total // 3
    part3_size = total - part1_size - part2_size
    
    part1 = countries[:part1_size]
    part2 = countries[part1_size:part1_size + part2_size]
    part3 = countries[part1_size + part2_size:]
    
    print(f"Part1: {len(part1)} стран")
    print(f"Part2: {len(part2)} стран")
    print(f"Part3: {len(part3)} стран")
    
    # Сохраняем в JSON
    with open(f"{output_dir}/countries_part1.json", 'w', encoding='utf-8') as f:
        json.dump(part1, f, ensure_ascii=False, indent=2)
    
    with open(f"{output_dir}/countries_part2.json", 'w', encoding='utf-8') as f:
        json.dump(part2, f, ensure_ascii=False, indent=2)
    
    with open(f"{output_dir}/countries_part3.json", 'w', encoding='utf-8') as f:
        json.dump(part3, f, ensure_ascii=False, indent=2)
    
    print("✅ JSON файлы созданы успешно!")

if __name__ == '__main__':
    main()
