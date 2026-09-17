#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Патч Localizable.strings: TC/Survival, секунды, weekly, детальные TC (2 аргумента)."""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "World Arena. Flags" / "Resources"

KEY_RE = re.compile(r'^"(?P<k>(?:\\.|[^"\\])*)" = "(?P<v>(?:\\.|[^"\\])*)";', re.MULTILINE)


def de_esc(s: str) -> str:
    return s.replace("\\\\", "\\").replace('\\"', '"')


def esc(s: str) -> str:
    return s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")


def parse_strings(text: str) -> dict[str, str]:
    out: dict[str, str] = {}
    for m in KEY_RE.finditer(text):
        k = de_esc(m.group("k"))
        v = de_esc(m.group("v"))
        out[k] = v
    return out


def set_key(text: str, key: str, value: str) -> str:
    ek = esc(key)
    ev = esc(value)
    line = f'"{ek}" = "{ev}";'
    pat = re.compile(r'^"' + re.escape(ek) + r'" = .*$', re.MULTILINE)
    if pat.search(text):
        return pat.sub(line, text, count=1)
    if not text.endswith("\n"):
        text += "\n"
    return text + line + "\n"


# --- Форматы с повторяющимся %2$@ / %3$@ (dur, unit, add, sub) и регионы (5 аргументов) ---
DIFF: dict[str, tuple[str, str, str]] = {
    "en": (
        "%1$d %2$@ round • +%3$d %2$@ every 5 correct • −%4$d %2$@ per wrong",
        "All countries • %1$d %2$@ round • +%3$d %2$@ every 5 correct • −%4$d %2$@ per wrong",
        "%1$d countries • %2$d %3$@ round • +%4$d %3$@ every 5 correct • −%5$d %3$@ per wrong",
    ),
    "ru": (
        "%1$d %2$@ за раунд • +%3$d %2$@ за комбо из 5 верных • −%4$d %2$@ за ошибку",
        "Все страны • %1$d %2$@ за раунд • +%3$d %2$@ за комбо из 5 верных • −%4$d %2$@ за ошибку",
        "%1$d стран • %2$d %3$@ за раунд • +%4$d %3$@ за комбо из 5 верных • −%5$d %3$@ за ошибку",
    ),
    "uk": (
        "%1$d %2$@ за раунд • +%3$d %2$@ за комбо з 5 вірних поспіль • −%4$d %2$@ за помилку",
        "Усі країни • %1$d %2$@ за раунд • +%3$d %2$@ за комбо з 5 вірних поспіль • −%4$d %2$@ за помилку",
        "%1$d країн • %2$d %3$@ за раунд • +%4$d %3$@ за комбо з 5 вірних поспіль • −%5$d %3$@ за помилку",
    ),
    "de": (
        "%1$d %2$@ Runde • +%3$d %2$@ je 5 richtige in Folge • −%4$d %2$@ pro Fehler",
        "Alle Länder • %1$d %2$@ Runde • +%3$d %2$@ je 5 richtige in Folge • −%4$d %2$@ pro Fehler",
        "%1$d Länder • %2$d %3$@ Runde • +%4$d %3$@ je 5 richtige in Folge • −%5$d %3$@ pro Fehler",
    ),
    "fr": (
        "%1$d %2$@ la manche • +%3$d %2$@ tous les 5 bons d’affilée • −%4$d %2$@ par erreur",
        "Tous les pays • %1$d %2$@ la manche • +%3$d %2$@ tous les 5 bons d’affilée • −%4$d %2$@ par erreur",
        "%1$d pays • %2$d %3$@ la manche • +%4$d %3$@ tous les 5 bons d’affilée • −%5$d %3$@ par erreur",
    ),
    "es": (
        "%1$d %2$@ por ronda • +%3$d %2$@ cada 5 aciertos seguidos • −%4$d %2$@ por error",
        "Todos los países • %1$d %2$@ por ronda • +%3$d %2$@ cada 5 aciertos seguidos • −%4$d %2$@ por error",
        "%1$d países • %2$d %3$@ por ronda • +%4$d %3$@ cada 5 aciertos seguidos • −%5$d %3$@ por error",
    ),
    "it": (
        "%1$d %2$@ a round • +%3$d %2$@ ogni 5 corrette di fila • −%4$d %2$@ per errore",
        "Tutti i paesi • %1$d %2$@ a round • +%3$d %2$@ ogni 5 corrette di fila • −%4$d %2$@ per errore",
        "%1$d paesi • %2$d %3$@ a round • +%4$d %3$@ ogni 5 corrette di fila • −%5$d %3$@ per errore",
    ),
    "pt-BR": (
        "%1$d %2$@ por rodada • +%3$d %2$@ a cada 5 acertos seguidos • −%4$d %2$@ por erro",
        "Todos os países • %1$d %2$@ por rodada • +%3$d %2$@ a cada 5 acertos seguidos • −%4$d %2$@ por erro",
        "%1$d países • %2$d %3$@ por rodada • +%4$d %3$@ a cada 5 acertos seguidos • −%5$d %3$@ por erro",
    ),
    "pl": (
        "%1$d %2$@ na rundę • +%3$d %2$@ co 5 poprawnych z rzędu • −%4$d %2$@ za błąd",
        "Wszystkie kraje • %1$d %2$@ na rundę • +%3$d %2$@ co 5 poprawnych z rzędu • −%4$d %2$@ za błąd",
        "%1$d krajów • %2$d %3$@ na rundę • +%4$d %3$@ co 5 poprawnych z rzędu • −%5$d %3$@ za błąd",
    ),
    "nl": (
        "%1$d %2$@ per ronde • +%3$d %2$@ per 5 goed op rij • −%4$d %2$@ per fout",
        "Alle landen • %1$d %2$@ per ronde • +%3$d %2$@ per 5 goed op rij • −%4$d %2$@ per fout",
        "%1$d landen • %2$d %3$@ per ronde • +%4$d %3$@ per 5 goed op rij • −%5$d %3$@ per fout",
    ),
    "ca": (
        "%1$d %2$@ per ronda • +%3$d %2$@ cada 5 encerts seguits • −%4$d %2$@ per error",
        "Tots els països • %1$d %2$@ per ronda • +%3$d %2$@ cada 5 encerts seguits • −%4$d %2$@ per error",
        "%1$d països • %2$d %3$@ per ronda • +%4$d %3$@ cada 5 encerts seguits • −%5$d %3$@ per error",
    ),
    "sv": (
        "%1$d %2$@ per runda • +%3$d %2$@ per 5 rätt i rad • −%4$d %2$@ per fel",
        "Alla länder • %1$d %2$@ per runda • +%3$d %2$@ per 5 rätt i rad • −%4$d %2$@ per fel",
        "%1$d länder • %2$d %3$@ per runda • +%4$d %3$@ per 5 rätt i rad • −%5$d %3$@ per fel",
    ),
    "cs": (
        "%1$d %2$@ na kolo • +%3$d %2$@ za každých 5 správných v řadě • −%4$d %2$@ za chybu",
        "Všechny země • %1$d %2$@ na kolo • +%3$d %2$@ za každých 5 správných v řadě • −%4$d %2$@ za chybu",
        "%1$d zemí • %2$d %3$@ na kolo • +%4$d %3$@ za každých 5 správných v řadě • −%5$d %3$@ za chybu",
    ),
    "ro": (
        "%1$d %2$@ rundă • +%3$d %2$@ la fiecare 5 corecte la rând • −%4$d %2$@ per greșeală",
        "Toate țările • %1$d %2$@ rundă • +%3$d %2$@ la fiecare 5 corecte la rând • −%4$d %2$@ per greșeală",
        "%1$d țări • %2$d %3$@ rundă • +%4$d %3$@ la fiecare 5 corecte la rând • −%5$d %3$@ per greșeală",
    ),
    "hu": (
        "%1$d %2$@ kör • +%3$d %2$@ minden 5 egymás utáni helyesre • −%4$d %2$@ hibánként",
        "Minden ország • %1$d %2$@ kör • +%3$d %2$@ minden 5 egymás utáni helyesre • −%4$d %2$@ hibánként",
        "%1$d ország • %2$d %3$@ kör • +%4$d %3$@ minden 5 egymás utáni helyesre • −%5$d %3$@ hibánként",
    ),
    "el": (
        "%1$d %2$@ γύρος • +%3$d %2$@ ανά 5 σωστές στη σειρά • −%4$d %2$@ ανά λάθος",
        "Όλες οι χώρες • %1$d %2$@ γύρος • +%3$d %2$@ ανά 5 σωστές στη σειρά • −%4$d %2$@ ανά λάθος",
        "%1$d χώρες • %2$d %3$@ γύρος • +%4$d %3$@ ανά 5 σωστές στη σειρά • −%5$d %3$@ ανά λάθος",
    ),
    "tr": (
        "%1$d %2$@ tur • üst üste 5 doğruya +%3$d %2$@ • hataya −%4$d %2$@",
        "Tüm ülkeler • %1$d %2$@ tur • üst üste 5 doğruya +%3$d %2$@ • hataya −%4$d %2$@",
        "%1$d ülke • %2$d %3$@ tur • üst üste 5 doğruya +%4$d %3$@ • hataya −%5$d %3$@",
    ),
    "vi": (
        "%1$d %2$@ mỗi vòng • +%3$d %2$@ mỗi 5 câu đúng liên tiếp • −%4$d %2$@ mỗi sai",
        "Tất cả quốc gia • %1$d %2$@ mỗi vòng • +%3$d %2$@ mỗi 5 câu đúng liên tiếp • −%4$d %2$@ mỗi sai",
        "%1$d quốc gia • %2$d %3$@ mỗi vòng • +%4$d %3$@ mỗi 5 câu đúng liên tiếp • −%5$d %3$@ mỗi sai",
    ),
    "th": (
        "%1$d %2$@ ต่อรอบ • +%3$d %2$@ ทุก 5 ข้อถูกติดกัน • −%4$d %2$@ ต่อคำตอบผิด",
        "ทุกประเทศ • %1$d %2$@ ต่อรอบ • +%3$d %2$@ ทุก 5 ข้อถูกติดกัน • −%4$d %2$@ ต่อคำตอบผิด",
        "%1$d ประเทศ • %2$d %3$@ ต่อรอบ • +%4$d %3$@ ทุก 5 ข้อถูกติดกัน • −%5$d %3$@ ต่อคำตอบผิด",
    ),
    "id": (
        "%1$d %2$@ per ronde • +%3$d %2$@ tiap 5 benar beruntun • −%4$d %2$@ per salah",
        "Semua negara • %1$d %2$@ per ronde • +%3$d %2$@ tiap 5 benar beruntun • −%4$d %2$@ per salah",
        "%1$d negara • %2$d %3$@ per ronde • +%4$d %3$@ tiap 5 benar beruntun • −%5$d %3$@ per salah",
    ),
    "fil": (
        "%1$d %2$@ bawat round • +%3$d %2$@ bawat 5 tamang sunod-sunod • −%4$d %2$@ bawat mali",
        "Lahat ng bansa • %1$d %2$@ bawat round • +%3$d %2$@ bawat 5 tamang sunod-sunod • −%4$d %2$@ bawat mali",
        "%1$d (na) bansa • %2$d %3$@ bawat round • +%4$d %3$@ bawat 5 tamang sunod-sunod • −%5$d %3$@ bawat mali",
    ),
    "hi": (
        "%1$d %2$@ प्रति राउंड • लगातार 5 सही पर +%3$d %2$@ • गलती पर −%4$d %2$@",
        "सभी देश • %1$d %2$@ प्रति राउंड • लगातार 5 सही पर +%3$d %2$@ • गलती पर −%4$d %2$@",
        "%1$d देश • %2$d %3$@ प्रति राउंड • लगातार 5 सही पर +%4$d %3$@ • गलती पर −%5$d %3$@",
    ),
    "bn": (
        "%1$d %2$@ প্রতি রাউন্ড • টানা ৫টি সঠিকে +%3$d %2$@ • ভুলে −%4$d %2$@",
        "সব দেশ • %1$d %2$@ প্রতি রাউন্ড • টানা ৫টি সঠিকে +%3$d %2$@ • ভুলে −%4$d %2$@",
        "%1$dটি দেশ • %2$d %3$@ প্রতি রাউন্ড • টানা ৫টি সঠিকে +%4$d %3$@ • ভুলে −%5$d %3$@",
    ),
    "ta": (
        "%1$d %2$@ ஒரு சுற்றுக்கு • தொடர்ந்து 5 சரிக்கு +%3$d %2$@ • தவறுக்கு −%4$d %2$@",
        "அனைத்து நாடுகளும் • %1$d %2$@ ஒரு சுற்றுக்கு • தொடர்ந்து 5 சரிக்கு +%3$d %2$@ • தவறுக்கு −%4$d %2$@",
        "%1$d நாடுகள் • %2$d %3$@ ஒரு சுற்றுக்கு • தொடர்ந்து 5 சரிக்கு +%4$d %3$@ • தவறுக்கு −%5$d %3$@",
    ),
    "te": (
        "%1$d %2$@ రౌండుకు • వరుసగా 5 సరైనవికి +%3$d %2$@ • తప్పుకు −%4$d %2$@",
        "అన్ని దేశాలు • %1$d %2$@ రౌండుకు • వరుసగా 5 సరైనవికి +%3$d %2$@ • తప్పుకు −%4$d %2$@",
        "%1$d దేశాలు • %2$d %3$@ రౌండుకు • వరుసగా 5 సరైనవికి +%4$d %3$@ • తప్పుకు −%5$d %3$@",
    ),
    "ar": (
        "%1$d %2$@ للجولة • +%3$d %2$@ كل 5 صحيحة متتالية • −%4$d %2$@ لكل خطأ",
        "كل البلدان • %1$d %2$@ للجولة • +%3$d %2$@ كل 5 صحيحة متتالية • −%4$d %2$@ لكل خطأ",
        "%1$d بلداً • %2$d %3$@ للجولة • +%4$d %3$@ كل 5 صحيحة متتالية • −%5$d %3$@ لكل خطأ",
    ),
    "ja": (
        "%1$d %2$@のラウンド • 連続5正解で +%3$d %2$@ • 不正解で −%4$d %2$@",
        "全ての国 • %1$d %2$@のラウンド • 連続5正解で +%3$d %2$@ • 不正解で −%4$d %2$@",
        "%1$d か国 • %2$d %3$@のラウンド • 連続5正解で +%4$d %3$@ • 不正解で −%5$d %3$@",
    ),
    "ko": (
        "%1$d %2$@ 라운드 • 연속 5정답마다 +%3$d %2$@ • 오답마다 −%4$d %2$@",
        "모든 국가 • %1$d %2$@ 라운드 • 연속 5정답마다 +%3$d %2$@ • 오답마다 −%4$d %2$@",
        "%1$d개 국가 • %2$d %3$@ 라운드 • 연속 5정답마다 +%4$d %3$@ • 오답마다 −%5$d %3$@",
    ),
    "zh": (
        "%1$d %2$@一局 • 连续答对 5 题 +%3$d %2$@ • 答错 −%4$d %2$@",
        "全球所有国家/地区 • %1$d %2$@一局 • 连续答对 5 题 +%3$d %2$@ • 答错 −%4$d %2$@",
        "%1$d 个国家/地区 • %2$d %3$@一局 • 连续答对 5 题 +%4$d %3$@ • 答错 −%5$d %3$@",
    ),
    "zh-Hant": (
        "%1$d %2$@一局 • 連續答對 5 題 +%3$d %2$@ • 答錯 −%4$d %2$@",
        "全球所有國家/地區 • %1$d %2$@一局 • 連續答對 5 題 +%3$d %2$@ • 答錯 −%4$d %2$@",
        "%1$d 個國家/地區 • %2$d %3$@一局 • 連續答對 5 題 +%4$d %3$@ • 答錯 −%5$d %3$@",
    ),
}

UNITS: dict[str, str] = {
    "en": "s",
    "ru": "с",
    "uk": "с",
    "de": "s",
    "fr": "s",
    "es": "s",
    "it": "s",
    "pt-BR": "s",
    "pl": "s",
    "nl": "s",
    "ca": "s",
    "sv": "s",
    "cs": "s",
    "ro": "s",
    "hu": "s",
    "el": "δ",
    "tr": "sn",
    "vi": "giây",
    "th": "วิ",
    "id": "dtk",
    "fil": "s",
    "hi": "से",
    "bn": "সে",
    "ta": "வி.",
    "te": "సెక్",
    "ar": "ث",
    "ja": "秒",
    "ko": "초",
    "zh": "秒",
    "zh-Hant": "秒",
}

TC_DETAIL: dict[str, tuple[str, str]] = {
    "en": (
        "Timer: −%1$d %2$@ (wrong)",
        "Timer: +%1$d %2$@ (5 correct streak)",
    ),
    "ru": ("Таймер: −%1$d %2$@ (ошибка)", "Таймер: +%1$d %2$@ (5 верных подряд)"),
    "uk": ("Таймер: −%1$d %2$@ (помилка)", "Таймер: +%1$d %2$@ (5 вірних поспіль)"),
    "de": ("Timer: −%1$d %2$@ (falsch)", "Timer: +%1$d %2$@ (5 richtige in Folge)"),
    "fr": ("Chrono : −%1$d %2$@ (erreur)", "Chrono : +%1$d %2$@ (5 bonnes d’affilée)"),
    "es": ("Temporizador: −%1$d %2$@ (error)", "Temporizador: +%1$d %2$@ (5 aciertos seguidos)"),
    "it": ("Timer: −%1$d %2$@ (errore)", "Timer: +%1$d %2$@ (5 corrette di fila)"),
    "pt-BR": ("Timer: −%1$d %2$@ (erro)", "Timer: +%1$d %2$@ (5 acertos seguidos)"),
    "pl": ("Timer: −%1$d %2$@ (błąd)", "Timer: +%1$d %2$@ (5 poprawnych z rzędu)"),
    "nl": ("Timer: −%1$d %2$@ (fout)", "Timer: +%1$d %2$@ (5 goed op rij)"),
    "ca": ("Temporitzador: −%1$d %2$@ (error)", "Temporitzador: +%1$d %2$@ (5 encerts seguits)"),
    "sv": ("Timer: −%1$d %2$@ (fel)", "Timer: +%1$d %2$@ (5 rätt i rad)"),
    "cs": ("Časovač: −%1$d %2$@ (chyba)", "Časovač: +%1$d %2$@ (5 správných v řadě)"),
    "ro": ("Cronometru: −%1$d %2$@ (greșeală)", "Cronometru: +%1$d %2$@ (5 corecte la rând)"),
    "hu": ("Időzítő: −%1$d %2$@ (hiba)", "Időzítő: +%1$d %2$@ (5 helyes egymás után)"),
    "el": ("Χρονόμετρο: −%1$d %2$@ (λάθος)", "Χρονόμετρο: +%1$d %2$@ (5 σωστές στη σειρά)"),
    "tr": ("Süre: −%1$d %2$@ (yanlış)", "Süre: +%1$d %2$@ (üst üste 5 doğru)"),
    "vi": ("Hẹn giờ: −%1$d %2$@ (sai)", "Hẹn giờ: +%1$d %2$@ (5 đúng liên tiếp)"),
    "th": ("ตัวจับเวลา: −%1$d %2$@ (ผิด)", "ตัวจับเวลา: +%1$d %2$@ (5 ข้อถูกติดกัน)"),
    "id": ("Timer: −%1$d %2$@ (salah)", "Timer: +%1$d %2$@ (5 benar beruntun)"),
    "fil": ("Timer: −%1$d %2$@ (mali)", "Timer: +%1$d %2$@ (5 tamang sunod-sunod)"),
    "hi": ("टाइमर: −%1$d %2$@ (गलत)", "टाइमर: +%1$d %2$@ (लगातार 5 सही)"),
    "bn": ("টাইমার: −%1$d %2$@ (ভুল)", "টাইমার: +%1$d %2$@ (টানা ৫টি সঠিক)"),
    "ta": ("டைமர்: −%1$d %2$@ (தவறு)", "டைமர்: +%1$d %2$@ (தொடர்ந்து 5 சரி)"),
    "te": ("టైమర్: −%1$d %2$@ (తప్పు)", "టైమర్: +%1$d %2$@ (వరుసగా 5 సరైనవి)"),
    "ar": ("المؤقت: −%1$d %2$@ (خطأ)", "المؤقت: +%1$d %2$@ (5 صحيحة متتالية)"),
    "ja": ("タイマー: −%1$d %2$@（不正解）", "タイマー: +%1$d %2$@（5連続正解）"),
    "ko": ("타이머: −%1$d %2$@ (오답)", "타이머: +%1$d %2$@ (연속 5정답)"),
    "zh": ("计时：−%1$d %2$@（错误）", "计时：+%1$d %2$@（连续答对 5 题）"),
    "zh-Hant": ("計時：−%1$d %2$@（錯誤）", "計時：+%1$d %2$@（連續答對 5 題）"),
}


def folder_lang(folder: str) -> str:
    return folder.replace(".lproj", "")


def must_preserve_existing(key: str) -> bool:
    """Уже переведённые подписи TC — не затирать английским из en."""
    if key in {
        "TC correct answers headline",
        "TC best correct record",
        "Share TC headline",
    }:
        return True
    if key.startswith("TC intro"):
        return True
    return False


def main() -> int:
    en_path = ROOT / "en.lproj" / "Localizable.strings"
    if not en_path.is_file():
        print("Missing en.lproj", file=sys.stderr)
        return 1
    en_text = en_path.read_text(encoding="utf-8")
    en_map = parse_strings(en_text)

    _want_prefixes = (
        "Answer as many",
        "Wrong answer",
        "5 correct in a row",
        "Best combo",
        "TC stat",
        "Time ",
        "Difficulty description TC",
        "Difficulty TC",
        "TC correct",
        "TC best",
        "TC intro",
        "TC detail",
        "Share TC",
        "Share Survival",
        "Survival ",
    )
    _want_exact = {
        "Duration",
        "Best score",
        "New record!",
        "Day leaderboard place",
        "Week leaderboard place",
        "Start",
    }
    keys_to_sync = [
        k
        for k in en_map
        if k.startswith(_want_prefixes) or k in _want_exact
    ]

    diff_keys = (
        "Difficulty description TC",
        "Difficulty TC erudite all",
        "Difficulty TC erudite regions",
    )

    overlay_dir = Path(__file__).resolve().parent
    overlay_all: dict[str, dict[str, str]] = {}
    for name in (
        "l10n_overlay.json",
        "l10n_overlay_eu.json",
        "l10n_overlay_asia.json",
        "survival_tc_overlay.json",
    ):
        p = overlay_dir / name
        if p.is_file():
            chunk = json.load(p.open(encoding="utf-8"))
            for lang_code, entries in chunk.items():
                overlay_all.setdefault(lang_code, {}).update(entries)

    time_ui_keys = (
        "Time TC delta seconds fmt",
        "Time intro duration seconds fmt",
        "Time intro penalty seconds fmt",
        "Time intro bonus seconds fmt",
    )

    for lproj in sorted(ROOT.glob("*.lproj")):
        lang = folder_lang(lproj.name)
        path = lproj / "Localizable.strings"
        if not path.is_file():
            continue
        text = path.read_text(encoding="utf-8")
        cur = parse_strings(text)

        if lang in DIFF:
            d1, d2, d3 = DIFF[lang]
            text = set_key(text, diff_keys[0], d1)
            text = set_key(text, diff_keys[1], d2)
            text = set_key(text, diff_keys[2], d3)
        elif lang != "en":
            d1, d2, d3 = DIFF["en"]
            text = set_key(text, diff_keys[0], d1)
            text = set_key(text, diff_keys[1], d2)
            text = set_key(text, diff_keys[2], d3)

        unit = UNITS.get(lang, UNITS["en"])
        text = set_key(text, "Time seconds unit short", unit)

        td = TC_DETAIL.get(lang) or TC_DETAIL["en"]
        text = set_key(text, "TC detail time penalty fmt", td[0])
        text = set_key(text, "TC detail time combo fmt", td[1])

        if lang != "en":
            for tk in time_ui_keys:
                if tk in en_map:
                    text = set_key(text, tk, en_map[tk])

            for k in keys_to_sync:
                if k in diff_keys or k == "Time seconds unit short":
                    continue
                if k in ("TC detail time penalty fmt", "TC detail time combo fmt"):
                    continue
                if k.startswith("Time "):
                    continue
                if k.startswith("Survival") or k.startswith("Share Survival"):
                    continue
                val = en_map.get(k)
                if val is None:
                    continue
                if must_preserve_existing(k) and k in cur:
                    continue
                if k not in cur:
                    text = set_key(text, k, val)

            for k in en_map:
                if not (k.startswith("Survival") or k.startswith("Share Survival")):
                    continue
                if k not in keys_to_sync:
                    continue
                if k in en_map:
                    text = set_key(text, k, en_map[k])

            for k, v in overlay_all.get(lang, {}).items():
                text = set_key(text, k, v)

        path.write_text(text, encoding="utf-8")
        print("Patched", path.relative_to(ROOT))

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
