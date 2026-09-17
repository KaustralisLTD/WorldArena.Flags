#!/usr/bin/env python3
"""One-off: insert duel invite popup keys after \"24h to accept\" in each .lproj."""
from __future__ import annotations

import re
from pathlib import Path

RES = Path(__file__).resolve().parent.parent / "World Arena. Flags" / "Resources"

# (title, body_format with %@, accept, remind_1h, decline)
LANG: dict[str, tuple[str, str, str, str, str]] = {
    "en": (
        "Duel challenge",
        "%@ calls you to duel",
        "Accept",
        "Remind · 1 h",
        "Decline",
    ),
    "ru": (
        "Вызов на дуэль",
        "%@ вызывает вас на дуэль",
        "Принять",
        "Напомнить · 1 ч",
        "Отклонить",
    ),
    "de": (
        "Duell-Herausforderung",
        "%@ fordert dich zum Duell",
        "Annehmen",
        "Erinnern · 1 Std.",
        "Ablehnen",
    ),
    "fr": (
        "Défi en duel",
        "%@ te défie en duel",
        "Accepter",
        "Rappeler · 1 h",
        "Refuser",
    ),
    "es": (
        "Desafío de duelo",
        "%@ te reta a un duelo",
        "Aceptar",
        "Recordar · 1 h",
        "Rechazar",
    ),
    "it": (
        "Sfida a duello",
        "%@ ti sfida a duello",
        "Accetta",
        "Promemoria · 1 h",
        "Rifiuta",
    ),
    "pt-BR": (
        "Desafio de duelo",
        "%@ te desafia para um duelo",
        "Aceitar",
        "Lembrar · 1 h",
        "Recusar",
    ),
    "pl": (
        "Wyzwanie na pojedynek",
        "%@ wzywa cię na pojedynek",
        "Przyjmij",
        "Przypomnij · 1 h",
        "Odrzuć",
    ),
    "uk": (
        "Виклик на дуель",
        "%@ викликає вас на дуель",
        "Прийняти",
        "Нагадати · 1 год",
        "Відхилити",
    ),
    "nl": (
        "Duel-uitdaging",
        "%@ daagt je uit voor een duel",
        "Accepteren",
        "Herinner · 1 u",
        "Weigeren",
    ),
    "ca": (
        "Repte de duel",
        "%@ et desafia a un duel",
        "Acceptar",
        "Recorda · 1 h",
        "Rebutjar",
    ),
    "zh": (
        "决斗挑战",
        "%@向你发起决斗",
        "接受",
        "提醒 · 1小时",
        "拒绝",
    ),
    "zh-Hant": (
        "決鬥挑戰",
        "%@向你發起決鬥",
        "接受",
        "提醒 · 1 小時",
        "拒絕",
    ),
    "ja": (
        "デュエルの挑戦",
        "%@がデュエルを申し込んでいます",
        "受け入れる",
        "1時間後に通知",
        "断る",
    ),
    "ko": (
        "결투 신청",
        "%@님이 결투를 신청했습니다",
        "수락",
        "1시간 후 알림",
        "거절",
    ),
    "ar": (
        "تحدي المبارزة",
        "%@ يتحداك في مبارزة",
        "قبول",
        "تذكير · ١ ساعة",
        "رفض",
    ),
    "hi": (
        "द्वंद्व चुनौती",
        "%@ ने आपको द्वंद्व के लिए बुलाया",
        "स्वीकार करें",
        "याद दिलाएँ · १ घं.",
        "मना करें",
    ),
    "cs": (
        "Výzva na duel",
        "%@ vás vyzývá na duel",
        "Přijmout",
        "Připomenout · 1 h",
        "Odmítnout",
    ),
    "sv": (
        "Duellutmaning",
        "%@ utmanar dig till duell",
        "Acceptera",
        "Påminn · 1 h",
        "Avvisa",
    ),
    "hu": (
        "Párbaj kihívás",
        "%@ párbajra hív",
        "Elfogadás",
        "Emlékeztető · 1 ó",
        "Elutasítás",
    ),
    "ro": (
        "Provocare la duel",
        "%@ te provoacă la duel",
        "Acceptă",
        "Reamintește · 1 h",
        "Refuză",
    ),
    "tr": (
        "Düello meydan okuması",
        "%@ seni düelloya davet ediyor",
        "Kabul et",
        "Hatırlat · 1 sa",
        "Reddet",
    ),
    "vi": (
        "Thách đấu",
        "%@ mời bạn thách đấu",
        "Chấp nhận",
        "Nhắc · 1 giờ",
        "Từ chối",
    ),
    "th": (
        "ท้าดวล",
        "%@ ท้าทายคุณดวล",
        "รับ",
        "เตือน · 1 ชม.",
        "ปฏิเสธ",
    ),
    "id": (
        "Tantangan duel",
        "%@ menantang Anda berduel",
        "Terima",
        "Ingatkan · 1 jam",
        "Tolak",
    ),
    "el": (
        "Πρόκληση μονομαχίας",
        "Ο/Η %@ σας προκαλεί σε μονομαχία",
        "Αποδοχή",
        "Υπενθύμιση · 1 ώρα",
        "Απόρριψη",
    ),
    "bn": (
        "ডুয়েল চ্যালেঞ্জ",
        "%@ আপনাকে ডুয়েলে ডাকছে",
        "গ্রহণ",
        "মনে করিয়ে দিন · ১ ঘ.",
        "প্রত্যাখ্যান",
    ),
    "ta": (
        "இரட்டைப் போர் சவால்",
        "%@ உங்களை இரட்டைப் போருக்கு அழைக்கிறார்",
        "ஏற்று",
        "நினைவூட்டு · 1 மணி",
        "மறுக்க",
    ),
    "te": (
        "డ్యూయల్ సవాలు",
        "%@ మీను డ్యూయల్‌కు పిలుస్తున్నారు",
        "అంగీకరించు",
        "గుర్తు · 1 గం",
        "తిరస్కరించు",
    ),
    "fil": (
        "Hamong sa duwelo",
        "Inimbitahan ka ni %@ sa duwelo",
        "Tanggapin",
        "Paalala · 1 oras",
        "Tanggihan",
    ),
}


def esc(s: str) -> str:
    return s.replace("\\", "\\\\").replace('"', '\\"')


def block_for(lang: str) -> str:
    t, b, a, r, d = LANG.get(lang, LANG["en"])
    lines = [
        f'"duel_invite_popup_title" = "{esc(t)}";',
        f'"duel_invite_popup_body_format" = "{esc(b)}";',
        f'"duel_invite_popup_accept" = "{esc(a)}";',
        f'"duel_invite_popup_remind_1h" = "{esc(r)}";',
        f'"duel_invite_popup_decline" = "{esc(d)}";',
    ]
    return "\n".join(lines) + "\n"


def main() -> None:
    marker = re.compile(r'^"24h to accept"\s*=\s*".*";', re.MULTILINE)
    key_check = "duel_invite_popup_title"

    for lproj in sorted(RES.glob("*.lproj")):
        path = lproj / "Localizable.strings"
        if not path.is_file():
            continue
        text = path.read_text(encoding="utf-8")
        if key_check in text:
            continue
        m = marker.search(text)
        if not m:
            print(f"SKIP (no 24h marker): {path}")
            continue
        lang = lproj.name.replace(".lproj", "")
        insert = block_for(lang)
        end = m.end()
        new_text = text[:end] + "\n" + insert + text[end:]
        path.write_text(new_text, encoding="utf-8")
        print(f"OK: {path.name} ({lang})")


if __name__ == "__main__":
    main()
