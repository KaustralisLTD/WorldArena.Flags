#!/usr/bin/env python3
import json
import re
import sys
from pathlib import Path


LANG_ORDER = ["en", "ru", "uk", "es", "ca", "zh", "de", "fr", "it", "pt-BR", "pl", "nl"]


def parse_markdown_table(lines, start_index):
    headers = [h.strip() for h in lines[start_index].strip().strip("|").split("|")]
    data = []
    i = start_index + 2  # skip delimiter row
    while i < len(lines):
        line = lines[i].rstrip("\n")
        if not line.strip().startswith("|"):
            break
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) < len(headers):
            cells += [""] * (len(headers) - len(cells))
        row = dict(zip(headers, cells))
        data.append(row)
        i += 1
    return headers, data, i


def find_section(lines, title):
    for i, line in enumerate(lines):
        if line.strip() == title:
            return i
    raise RuntimeError(f"Section not found: {title}")


def to_bool(v):
    return v.strip().lower() in {"yes", "true", "да"}


def load_asset_map(definitions_path: Path):
    text = definitions_path.read_text(encoding="utf-8")
    pattern = re.compile(r'AchievementDefinition\(id:\s*"([^"]+)".*imageAssetName:\s*"([^"]+)"')
    result = {}
    for m in pattern.finditer(text):
        result[m.group(1)] = m.group(2)
    return result


def main():
    if len(sys.argv) != 3:
        print("Usage: export_gamecenter_achievements_from_markdown.py <input_md> <output_json>")
        sys.exit(1)

    input_md = Path(sys.argv[1])
    output_json = Path(sys.argv[2])
    repo_root = input_md.parents[2]
    definitions_path = repo_root / "World Arena. Flags" / "Models" / "AchievementDefinitions.swift"

    lines = input_md.read_text(encoding="utf-8").splitlines()
    asset_map = load_asset_map(definitions_path)

    meta_idx = find_section(lines, "## Примечания")
    _ = meta_idx
    base_idx = find_section(lines, "| Achievement ID | titleKey | descriptionKey | Point value | Hidden | Repeatable | Properties (key=value) | Associated action |")
    _, base_rows, _ = parse_markdown_table(lines, base_idx)

    titles_idx = find_section(lines, "## Titles (локализованные)") + 1
    _, title_rows, _ = parse_markdown_table(lines, titles_idx)

    desc_before_idx = find_section(lines, "## Descriptions (достижение НЕ получено) (локализованные)") + 1
    _, before_rows, _ = parse_markdown_table(lines, desc_before_idx)

    desc_after_idx = find_section(lines, "## Descriptions (достижение получено) (локализованные)") + 2
    _, after_rows, _ = parse_markdown_table(lines, desc_after_idx)

    by_id_titles = {r["Achievement ID"]: r for r in title_rows}
    by_id_before = {r["Achievement ID"]: r for r in before_rows}
    by_id_after = {r["Achievement ID"]: r for r in after_rows}

    achievements = []
    for row in base_rows:
        ach_id = row["Achievement ID"]
        title_loc = by_id_titles.get(ach_id, {})
        before_loc = by_id_before.get(ach_id, {})
        after_loc = by_id_after.get(ach_id, {})
        localizations = {}
        for lang in LANG_ORDER:
            localizations[lang] = {
                "title": title_loc.get(lang, ""),
                "before_earned_description": before_loc.get(lang, ""),
                "after_earned_description": after_loc.get(lang, "")
            }

        asset_name = asset_map.get(ach_id)
        asset_path = None
        if asset_name:
            asset_path = f"World Arena. Flags/Assets.xcassets/{asset_name}.imageset"

        achievements.append({
            "id": ach_id,
            "reference_name": title_loc.get("en") or row["titleKey"],
            "title_key": row["titleKey"],
            "description_key": row["descriptionKey"],
            "points": int(row["Point value"]),
            "hidden": to_bool(row["Hidden"]),
            "reusable": to_bool(row["Repeatable"]),
            "asset_name": asset_name,
            "asset_imageset_path": asset_path,
            "localizations": localizations
        })

    payload = {
        "schema_version": 1,
        "source_markdown": str(input_md),
        "achievements_count": len(achievements),
        "achievements": achievements
    }
    output_json.parent.mkdir(parents=True, exist_ok=True)
    output_json.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Generated {len(achievements)} achievements -> {output_json}")


if __name__ == "__main__":
    main()
