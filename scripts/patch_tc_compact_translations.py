#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Компактные секунды TC, переводы названия режима и престартовых подписей."""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "World Arena. Flags" / "Resources"


def esc_value(s: str) -> str:
    return s.replace("\\", "\\\\").replace('"', '\\"')


def set_line(content: str, key: str, value: str) -> str:
    ek = esc_value(key)
    ev = esc_value(value)
    line = f'"{ek}" = "{ev}";'
    pat = re.compile(r'^"' + re.escape(ek) + r'" = .*;$', re.MULTILINE)
    if pat.search(content):
        return pat.sub(line, content, count=1)
    if not content.endswith("\n"):
        content += "\n"
    return content + line + "\n"


# Название режима (по запросу + en)
TIME_CHALLENGE_TITLE = {
    "en": "Time Challenge",
    "es": "Desafío contra el Tiempo",
    "ru": "Испытание на Время",
    "uk": "Випробування на Час",
    "ca": "Repte contra el Temps",
    "fr": "Défi contre la montre",
    "de": "Zeit-Herausforderung",
    "it": "Sfida a Tempo",
    "pt-BR": "Desafio contra o tempo",
    "nl": "Tijdsuitdaging",
    "pl": "Wyzwanie czasowe",
    "zh": "限时挑战",
    "zh-Hant": "限時挑戰",
    "hi": "समय चुनौती",
    "cs": "Časová výzva",
    "sv": "Tidsutmaning",
    "ja": "タイムチャレンジ",
    "ar": "تحدي الوقت",
    "bn": "সময় চ্যালেঞ্জ",
    "hu": "Idő kihívás",
    "vi": "Thử thách thời gian",
    "el": "Πρόκληση χρόνου",
    "id": "Tantangan waktu",
    "ko": "시간 도전",
    "ro": "Provocare contra timpului",
    "th": "ความท้าทายตามเวลา",
    "ta": "நேர சவால்",
    "te": "సమయ సవాలు",
    "tr": "Zaman Mücadelesi",
    "fil": "Hamon sa Oras",
}

TC_BEST_CORRECT = {
    "en": "Best (correct)",
    "ru": "Лучший (верные)",
    "uk": "Найкраще (вірні)",
    "de": "Bestwert (richtig)",
    "fr": "Meilleur (bons)",
    "es": "Mejor (aciertos)",
    "it": "Migliore (corrette)",
    "pt-BR": "Melhor (certas)",
    "pl": "Najlepszy (poprawne)",
    "nl": "Beste (goed)",
    "ca": "Millor (encerts)",
    "sv": "Bästa (rätt)",
    "cs": "Nejlepší (správně)",
    "ro": "Cel mai bun (corecte)",
    "hu": "Legjobb (helyes)",
    "el": "Καλύτερο (σωστές)",
    "tr": "En iyi (doğru)",
    "vi": "Tốt nhất (đúng)",
    "th": "ดีที่สุด (ถูก)",
    "id": "Terbaik (benar)",
    "fil": "Pinakamahusay (tama)",
    "hi": "सर्वश्रेष्ठ (सही)",
    "bn": "সেরা (সঠিক)",
    "ta": "சிறந்தது (சரி)",
    "te": "ఉత్తమం (సరైనవి)",
    "ar": "الأفضل (صحيح)",
    "ja": "ベスト（正解）",
    "ko": "최고 (정답)",
    "zh": "最佳（答对）",
    "zh-Hant": "最佳（答對）",
}

TC_COMBO5 = {
    "en": "5 correct combo",
    "ru": "Комбо: 5 верных подряд",
    "uk": "Комбо з 5 вірних поспіль",
    "de": "+5 richtige in Folge",
    "fr": "Combo 5 bonnes d’affilée",
    "es": "Combo de 5 aciertos",
    "it": "Combo 5 corrette",
    "pt-BR": "Combo de 5 acertos",
    "pl": "Combo 5 poprawnych z rzędu",
    "nl": "Combo 5 goed op rij",
    "ca": "Combo de 5 encerts",
    "sv": "Combo 5 rätt i rad",
    "cs": "Kombo 5 správných v řadě",
    "ro": "Combo 5 corecte la rând",
    "hu": "5 helyes kombó",
    "el": "Combo 5 σωστών στη σειρά",
    "tr": "Üst üste 5 doğru kombo",
    "vi": "Combo 5 câu đúng liên tiếp",
    "th": "คอมโบ 5 ข้อถูกติดกัน",
    "id": "Kombo 5 benar beruntun",
    "fil": "Combo ng 5 tamang sunod-sunod",
    "hi": "लगातार 5 सही कॉम्बो",
    "bn": "টানা ৫টি সঠিক কম্বো",
    "ta": "தொடர்ந்து 5 சரி காம்போ",
    "te": "వరుసగా 5 సరైన కాంబో",
    "ar": "سلسلة 5 صحيحة",
    "ja": "連続5正解コンボ",
    "ko": "연속 5정답 콤보",
    "zh": "连对 5 题",
    "zh-Hant": "連對 5 題",
}


def compact_tc_diff_lines(text: str) -> str:
    """Убирает пробел между числом и единицей в строках Difficulty * TC."""
    keys = (
        "Difficulty description TC",
        "Difficulty TC erudite all",
        "Difficulty TC erudite regions",
    )
    lines = text.split("\n")
    out = []
    for line in lines:
        stripped = line.lstrip()
        if any(stripped.startswith(f'"{k}"') for k in keys):
            line = line.replace("%1$d %2$@", "%1$d%2$@")
            line = line.replace("%3$d %2$@", "%3$d%2$@")
            line = line.replace("%4$d %2$@", "%4$d%2$@")
            line = line.replace("%2$d %3$@", "%2$d%3$@")
            line = line.replace("%4$d %3$@", "%4$d%3$@")
            line = line.replace("%5$d %3$@", "%5$d%3$@")
        out.append(line)
    return "\n".join(out)


def main() -> int:
    for lproj in sorted(ROOT.glob("*.lproj")):
        lang = lproj.name.replace(".lproj", "")
        path = lproj / "Localizable.strings"
        if not path.is_file():
            continue
        text = path.read_text(encoding="utf-8")

        text = set_line(text, "Time intro penalty seconds fmt", "−%1$d")
        text = set_line(text, "Time intro duration seconds fmt", "%1$d%2$@")
        text = set_line(text, "Time intro bonus seconds fmt", "+%1$d%2$@")

        text = compact_tc_diff_lines(text)

        tc_title = TIME_CHALLENGE_TITLE.get(lang, TIME_CHALLENGE_TITLE["en"])
        text = set_line(text, "Time Challenge", tc_title)

        text = set_line(
            text,
            "TC intro best correct title",
            TC_BEST_CORRECT.get(lang, TC_BEST_CORRECT["en"]),
        )
        text = set_line(
            text,
            "TC intro combo5 bonus title",
            TC_COMBO5.get(lang, TC_COMBO5["en"]),
        )

        path.write_text(text, encoding="utf-8")
        print("OK", path.relative_to(ROOT))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
