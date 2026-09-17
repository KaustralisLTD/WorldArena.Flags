#!/usr/bin/env python3
"""Восстанавливает рекламный promotional_text (не «Что нового»). Лимит App Store: 170 символов."""
from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
META = ROOT / "fastlane" / "metadata"
MAX_LEN = 170

# Смысл как у en-US / master: игра, 30+ языков, дуэли, серии, достижения, ежедневно, рейтинг.
PROMO: dict[str, str] = {
    "en-US": (
        "Learn world flags through play: 30+ languages, friend duels, streaks, and achievements. "
        "Train your memory daily and climb the leaderboard!"
    ),
    # Как в fastlane/templates/master_promotional_text.txt (две строки)
    "ru": (
        "Изучайте флаги мира в игре: 30+ языков, дуэли с друзьями, серии и достижения. \n"
        "Тренируйте память каждый день и поднимайтесь в рейтинге!"
    ),
    "de-DE": (
        "Weltflaggen spielerisch lernen: 30+ Sprachen, Duelle mit Freunden, Serien & Erfolge. "
        "Täglich trainieren und in der Bestenliste steigen!"
    ),
    "es-ES": (
        "Aprende banderas jugando: más de 30 idiomas, duelos entre amigos, rachas y logros. "
        "Entrena cada día y sube en el ranking."
    ),
    "fr-FR": (
        "Découvrez les drapeaux en jouant : 30+ langues, duels entre amis, séries et succès. "
        "Entraînez-vous chaque jour et grimpez au classement !"
    ),
    "it": (
        "Impara le bandiere giocando: oltre 30 lingue, duelli tra amici, serie e traguardi. "
        "Allenati ogni giorno e scala la classifica!"
    ),
    "pt-BR": (
        "Aprenda bandeiras jogando: mais de 30 idiomas, duelos com amigos, sequências e conquistas. "
        "Treine todo dia e suba no ranking!"
    ),
    "nl-NL": (
        "Leer vlaggen door te spelen: 30+ talen, duels met vrienden, reeksen en prestaties. "
        "Train dagelijks en klim in het klassement!"
    ),
    "pl": (
        "Poznawaj flagi w grze: 30+ języków, pojedynki ze znajomymi, serie i osiągnięcia. "
        "Trenuj codziennie i wspinaj się w rankingu!"
    ),
    "sv": (
        "Lär dig flaggor genom spel: 30+ språk, dueller med vänner, sviter och achievements. "
        "Träna dagligen och klättra på topplistan!"
    ),
    "cs": (
        "Poznejte vlajky hrou: 30+ jazyků, souboje s přáteli, série a úspěchy. "
        "Trénujte denně a stoupejte v žebříčku!"
    ),
    "el": (
        "Μάθετε σημαίες παίζοντας: 30+ γλώσσες, μονομαχίες φίλων, σερί και επιτεύγματα. "
        "Εξασκηθείτε καθημερινά και ανεβείτε στην κατάταξη!"
    ),
    "tr": (
        "Oyunla bayrak öğrenin: 30+ dil, arkadaş düelloları, seriler ve başarılar. "
        "Her gün antrenman yapın, sıralamada yükselin!"
    ),
    "uk": (
        "Вивчайте прапори в грі: 30+ мов, дуелі з друзями, серії й досягнення. "
        "Тренуйтеся щодня й піднімайтесь у рейтингу!"
    ),
    "ja": (
        "遊びながら国旗を学べます。30以上の言語、フレンド対戦、連続記録と実績。"
        "毎日トレーニングしてランキングを上げよう！"
    ),
    "ko": (
        "게임으로 세계 국기를 배우세요. 30개 이상 언어, 친구 대결, 연속 기록과 업적."
        "매일 연습하고 리더보드에 도전하세요!"
    ),
    "zh-Hans": "边玩边学世界国旗：30多种语言、好友对战、连胜与成就。每日练习，攀登排行榜！",
    "zh-Hant": "邊玩邊學世界國旗：30多種語言、好友對戰、連勝與成就。每日練習，攀登排行榜！",
    "hi": (
        "खेलकर दुनिया के झंडे सीखें: 30+ भाषाएँ, मित्रों से द्वंद्व, स्ट्रीक और उपलब्धियाँ। "
        "रोज़ अभ्यास करें और लीडरबोर्ड पर चढ़ें!"
    ),
    "ar-SA": (
        "تعرّف على أعلام العالم باللعب: أكثر من 30 لغة، تحديات مع الأصدقاء، سلسلة وإنجازات. "
        "تدرّب يوميًا وتقدّم في التصنيف!"
    ),
    "vi": (
        "Học cờ thế giới qua chơi: 30+ ngôn ngữ, đấu bạn bè, chuỗi & thành tựu. "
        "Luyện mỗi ngày và leo bảng xếp hạng!"
    ),
    "th": (
        "เรียนรู้ธงผ่านเกม: กว่า 30 ภาษา ดวลเพื่อน สตรีค และความสำเร็จ "
        "ฝึกทุกวันแล้วไต่อันดับ!"
    ),
    "id": (
        "Belajar bendera lewat permainan: 30+ bahasa, duel teman, streak & pencapaian. "
        "Latih setiap hari dan naik papan peringkat!"
    ),
    "ro": (
        "Învață steagurile lumii jucând: 30+ limbi, dueluri cu prietenii, serii și realizări. "
        "Antrenează-te zilnic și urcă în clasament!"
    ),
    "ca": (
        "Aprèn banderes jugant: més de 30 idiomes, duels amb amics, ratxes i assoliments. "
        "Entrena cada dia i puja al rànquing!"
    ),
    "hu": (
        "Tanulj zászlókat játék közben: 30+ nyelv, baráti párbajok, sorozatok és eredmények. "
        "Gyakorolj naponta és lépj előre a ranglistán!"
    ),
}


def main() -> None:
    bad: list[tuple[str, int]] = []
    for loc, text in sorted(PROMO.items()):
        if loc == "ru":
            s = text  # как в master: перенос строки между предложениями
        else:
            s = " ".join(text.split())
        n = len(s)
        if n > MAX_LEN:
            bad.append((loc, n))
        p = META / loc / "promotional_text.txt"
        if not p.parent.is_dir():
            raise SystemExit(f"Missing folder {p.parent}")
        p.write_text(s + "\n", encoding="utf-8")
        print(f"{loc}: {n} chars")

    if bad:
        raise SystemExit(f"Over {MAX_LEN} chars: {bad}")


if __name__ == "__main__":
    main()
