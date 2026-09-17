#!/usr/bin/env python3
"""Обновить TC correct answers headline и TC best correct record во всех .lproj."""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RES = ROOT / "World Arena. Flags" / "Resources"

# (headline with %d, best record with %d)
TRANSLATIONS: dict[str, tuple[str, str]] = {
    "en": ("%d correct", "Your best score: %d correct"),
    "ru": ("%d верно", "Лучший результат: %d верных"),
    "uk": ("%d вірно", "Найкращий рахунок: %d вірних"),
    "ca": ("%d correctes", "Millor puntuació: %d correctes"),
    "es": ("%d aciertos", "Tu mejor marca: %d aciertos"),
    "fr": ("%d bonnes réponses", "Meilleur score : %d bonnes réponses"),
    "de": ("%d richtig", "Bester Wert: %d richtig"),
    "it": ("%d corrette", "Miglior punteggio: %d corrette"),
    "pt-BR": ("%d corretas", "Melhor pontuação: %d corretas"),
    "nl": ("%d goed", "Je beste score: %d goed"),
    "pl": ("%d poprawnych", "Najlepszy wynik: %d poprawnych"),
    "zh": ("%d 题答对", "历史最佳：%d 题答对"),
    "zh-Hant": ("%d 題答對", "最佳成績：%d 題答對"),
    "hi": ("%d सही", "आपका सर्वश्रेष्ठ: %d सही"),
    "cs": ("%d správně", "Nejlepší skóre: %d správně"),
    "sv": ("%d rätt", "Ditt bästa: %d rätt"),
    "ja": ("%d 問正解", "自己ベスト: %d 問正解"),
    "ar": ("%d صحيحة", "أفضل نتيجة: %d صحيحة"),
    "bn": ("%d সঠিক", "আপনার সেরা: %d সঠিক"),
    "hu": ("%d helyes", "Legjobb eredményed: %d helyes"),
    "vi": ("%d đúng", "Điểm tốt nhất: %d đúng"),
    "el": ("%d σωστές", "Καλύτερο σκορ: %d σωστές"),
    "id": ("%d benar", "Skor terbaik: %d benar"),
    "ko": ("%d개 정답", "최고 기록: %d개 정답"),
    "ro": ("%d corecte", "Cel mai bun scor: %d corecte"),
    "th": ("%d ข้อถูก", "คะแนนสูงสุด: %d ข้อถูก"),
    "ta": ("%d சரியானவை", "உங்கள் சிறந்த மதிப்பெண்: %d சரியானவை"),
    "te": ("%d సరిగ్గా", "మీ అత్యుత్తమ స్కోరు: %d సరిగ్గా"),
    "tr": ("%d doğru", "En iyi skorun: %d doğru"),
    "fil": ("%d tama", "Pinakamataas na iskor: %d tama"),
}


def escape_strings_value(s: str) -> str:
    return s.replace("\\", "\\\\").replace('"', '\\"')


def patch_file(path: Path, lang: str) -> bool:
    if lang not in TRANSLATIONS:
        print(f"SKIP unknown lang: {lang}")
        return False
    headline, best = TRANSLATIONS[lang]
    h_esc = escape_strings_value(headline)
    b_esc = escape_strings_value(best)
    text = path.read_text(encoding="utf-8")
    text_new, n1 = re.subn(
        r'^"TC correct answers headline"\s*=\s*".*";',
        f'"TC correct answers headline" = "{h_esc}";',
        text,
        flags=re.MULTILINE,
    )
    text_new, n2 = re.subn(
        r'^"TC best correct record"\s*=\s*".*";',
        f'"TC best correct record" = "{b_esc}";',
        text_new,
        flags=re.MULTILINE,
    )
    if n1 != 1 or n2 != 1:
        print(f"WARN {path.name}: headline={n1}, best={n2}")
        return False
    path.write_text(text_new, encoding="utf-8")
    return True


def main() -> None:
    ok = 0
    for folder in sorted(RES.glob("*.lproj")):
        lang = folder.name.replace(".lproj", "")
        p = folder / "Localizable.strings"
        if not p.exists():
            continue
        if patch_file(p, lang):
            ok += 1
            print(f"OK {lang}")
    print(f"done: {ok} files")


if __name__ == "__main__":
    main()
