#!/usr/bin/env python3
"""
Генерация Localizable.strings: перевод английского значения (RHS) в целевой язык.

Рабочий прогон (как у вас): только интерпретатор из venv с установленным deep-translator,
иначе импорт падает или --cache-only без перевода.

  PY=/tmp/l10n-venv/bin/python3
  SCR=/path/to/World Arena. Flags/Scripts/machine_translate_strings.py
  for t in id ko ro th ta te tr fil zh-Hant; do
    echo "========== $t =========="
    PYTHONUNBUFFERED=1 "$PY" "$SCR" --target "$t" --batch 30 --sleep 0.35 || exit 1
  done

--cache-only — отдельный режим: только сборка из .translate_cache_<target>.json без API.
"""
from __future__ import annotations

import argparse
import json
import re
import time
from pathlib import Path

try:
    from deep_translator import GoogleTranslator
except ImportError:
    GoogleTranslator = None  # type: ignore[misc, assignment]

# Не переводим как обычный текст (бренды / коды)
# Оставляем как в UI (бренды / аббревиатуры)
SKIP_EXACT = frozenset(
    {
        "XP",
        "F-BUCKS",
        "F-BUCKS EARNED",
        "World Arena Premium",
        "World Arena Flags",
        "vs",
    }
)

# В en.lproj RHS пустой — смысл только в ключе (рус.). Без API подставляем готовый перевод по target.
_EMPTY_RHS_RU = (
    "Теперь вы можете без единой ошибки отвечать на все наши вопросы с точностью в %d%%"
)
EMPTY_RHS_TRANSLATIONS: dict[str, dict[str, str]] = {
    "ro": {_EMPTY_RHS_RU: "Acum poți răspunde la toate întrebările noastre fără nici o greșeală, cu o acuratețe de %d%%"},
    "id": {_EMPTY_RHS_RU: "Sekarang Anda dapat menjawab semua pertanyaan kami tanpa satu kesalahan pun dengan akurasi %d%%"},
    "ko": {_EMPTY_RHS_RU: "이제 실수 없이 %d%%의 정확도로 모든 질문에 답할 수 있습니다"},
    "th": {_EMPTY_RHS_RU: "ตอนนี้คุณสามารถตอบคำถามทั้งหมดของเราได้โดยไม่มีข้อผิดพลาดเลยแม้แต่ข้อเดียว ด้วยความแม่นยำ %d%%"},
    "ta": {_EMPTY_RHS_RU: "இப்போது %d%% துல்லியத்துடன் எந்த தவறும் இன்றி எங்கள் அனைத்து கேள்விகளுக்கும் பதிலளிக்க முடியும்"},
    "te": {_EMPTY_RHS_RU: "ఇప్పుడు మీరు %d%% ఖచ్చితంతో ఒక్క తప్పు లేకుండా మా అన్ని ప్రశ్నలకు సమాధానం చెప్పగలరు"},
    "tr": {_EMPTY_RHS_RU: "Artık tüm sorularımıza tek bir hata yapmadan %d%% doğrulukla yanıt verebilirsiniz"},
    "fil": {_EMPTY_RHS_RU: "Maaari mo na ngayong masagot ang lahat ng aming mga tanong nang walang kahit isang pagkakamali, na may %d%% na katumpakan"},
    "zh-Hant": {_EMPTY_RHS_RU: "現在您可以毫無錯誤地回答我們所有問題，準確度為 %d%%"},
}

# Имя .lproj / кэша → код для GoogleTranslator (если отличается)
GOOGLE_TRANSLATE_TARGET: dict[str, str] = {
    "zh-Hant": "zh-TW",
    "fil": "tl",
}

LINE_RE = re.compile(
    r'^("(?:\\.|[^"\\])*")\s*=\s*("(?:\\.|[^"\\])*")\s*;\s*$'
)


def unescape_value(inner: str) -> str:
    out: list[str] = []
    i = 0
    while i < len(inner):
        if inner[i] == "\\" and i + 1 < len(inner):
            n = inner[i + 1]
            if n == "n":
                out.append("\n")
                i += 2
            elif n == "t":
                out.append("\t")
                i += 2
            elif n == '"':
                out.append('"')
                i += 2
            elif n == "\\":
                out.append("\\")
                i += 2
            else:
                out.append(inner[i])
                i += 1
        else:
            out.append(inner[i])
            i += 1
    return "".join(out)


def escape_value(s: str) -> str:
    return (
        s.replace("\\", "\\\\")
        .replace('"', '\\"')
        .replace("\n", "\\n")
        .replace("\r", "\\r")
        .replace("\t", "\\t")
    )


def parse_line(line: str) -> tuple[str | None, str | None, str]:
    """Возвращает (key_raw, value_raw_без_кавычек_unescaped, passthrough_line)."""
    stripped = line.rstrip("\n\r")
    if not stripped.strip():
        return None, None, line
    s = stripped.lstrip()
    if s.startswith("//") or s.startswith("/*"):
        return None, None, line
    m = LINE_RE.match(stripped)
    if not m:
        return None, None, line
    key_lit, val_lit = m.group(1), m.group(2)
    key_inner = key_lit[1:-1]
    val_inner = val_lit[1:-1]
    return unescape_value(key_inner), unescape_value(val_inner), stripped


def should_skip_translation(text: str) -> bool:
    t = text.strip()
    if not t:
        return True
    if t in SKIP_EXACT:
        return True
    # Только плейсхолдеры / цифры / символы
    if re.fullmatch(r"[\d\s%@.,!?•+\-:×]+", t):
        return True
    return False


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--source", default="en", help="код языка источника для Google")
    ap.add_argument("--target", required=True, help="код языка назначения (hi, cs, ...)")
    ap.add_argument(
        "--input",
        type=Path,
        default=Path(__file__).resolve().parents[1] / "Resources" / "en.lproj" / "Localizable.strings",
    )
    ap.add_argument(
        "--output",
        type=Path,
        help="выходной файл (по умолчанию Resources/<target>.lproj/Localizable.strings)",
    )
    ap.add_argument("--batch", type=int, default=30)
    ap.add_argument("--sleep", type=float, default=0.35, help="пауза между батчами, сек")
    ap.add_argument("--limit", type=int, default=0, help="0 = все; иначе только N уникальных строк (тест)")
    ap.add_argument(
        "--cache",
        type=Path,
        help="JSON-кэш переводов (en_text -> translated); при повторном запуске пропускает уже переведённые",
    )
    ap.add_argument(
        "--cache-only",
        action="store_true",
        help="Только собрать .strings из кэша (без сети). Нужен полный кэш; deep_translator не требуется.",
    )
    args = ap.parse_args()

    base = Path(__file__).resolve().parents[1] / "Resources"
    out_path = args.output
    if out_path is None:
        out_path = base / f"{args.target}.lproj" / "Localizable.strings"

    text = args.input.read_text(encoding="utf-8")
    lines = text.splitlines(keepends=True)

    entries: list[tuple[int, str, str]] = []
    passthrough: dict[int, str] = {}
    for idx, line in enumerate(lines):
        k, v, raw = parse_line(line)
        if k is None and raw == line:
            passthrough[idx] = line
            continue
        if k is None:
            passthrough[idx] = line
            continue
        entries.append((idx, k, v))

    unique: list[str] = []
    seen: dict[str, None] = {}
    for _, _, v in entries:
        if v not in seen:
            seen[v] = None
            unique.append(v)

    to_translate = [u for u in unique if not should_skip_translation(u)]
    if args.limit > 0:
        to_translate = to_translate[: args.limit]
    skip_map = {u: u for u in unique if should_skip_translation(u)}

    cache_path = args.cache
    if cache_path is None:
        cache_path = Path(__file__).resolve().parent / f".translate_cache_{args.target}.json"

    disk_cache: dict[str, str] = {}
    if cache_path.is_file():
        try:
            disk_cache = json.loads(cache_path.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            disk_cache = {}

    value_map: dict[str, str] = dict(skip_map)
    for k, v in disk_cache.items():
        if k in seen and k not in value_map:
            value_map[k] = v

    batch = max(1, args.batch)
    pending = [s for s in to_translate if s not in value_map]
    print(f"Перевести: {len(pending)} (из кэша: {len(to_translate) - len(pending)})", flush=True)

    def save_cache() -> None:
        merged = {**{k: value_map[k] for k in to_translate if k in value_map}, **skip_map}
        for k, v in disk_cache.items():
            merged.setdefault(k, v)
        cache_path.write_text(json.dumps(merged, ensure_ascii=False, indent=0), encoding="utf-8")

    translator = None
    if pending and not args.cache_only:
        if GoogleTranslator is None:
            raise SystemExit("Установите: pip install deep-translator (или используйте --cache-only при полном кэше)")
        google_lang = GOOGLE_TRANSLATE_TARGET.get(args.target, args.target)
        translator = GoogleTranslator(source=args.source, target=google_lang)
        for i, src in enumerate(pending):
            if i % batch == 0:
                print(f"Translating {i + 1}/{len(pending)} ...", flush=True)
            try:
                value_map[src] = translator.translate(src)
            except Exception as e:
                print(f"  error, keep EN: {e!s}", flush=True)
                value_map[src] = src
            if (i + 1) % batch == 0:
                save_cache()
                time.sleep(args.sleep)
        save_cache()
    elif args.cache_only and pending:
        raise SystemExit(
            f"Кэш неполный: не хватает {len(pending)} фраз. Догоните без --cache-only."
        )
    elif not pending:
        print("Все строки уже в кэше, записываю выходной файл.", flush=True)

    out_lines = list(lines)
    for idx, k, v in entries:
        if not v.strip() and k.strip():
            nv = EMPTY_RHS_TRANSLATIONS.get(args.target, {}).get(k)
            if nv is None and translator is not None:
                try:
                    nv = translator.translate(k)
                except Exception:
                    nv = k
            if nv is None:
                nv = k
            out_lines[idx] = f'"{escape_value(k)}" = "{escape_value(nv)}";\n'
            continue
        new_val = value_map.get(v, v)
        out_lines[idx] = f'"{escape_value(k)}" = "{escape_value(new_val)}";\n'

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text("".join(out_lines), encoding="utf-8")
    print(f"Wrote {out_path}")


if __name__ == "__main__":
    main()
