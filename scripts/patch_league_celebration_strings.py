#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Добавляет строки праздничного модала лиги после league.weekly_result.cta.claim во всех lproj."""

from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
RES = ROOT / "World Arena. Flags" / "Resources"
CHECK = '"league.weekly_result.promotion.tagline"'

BLOCK_EN = """
"league.weekly_result.promotion.tagline" = "🔥 New level!";
"league.weekly_result.promotion.title" = "🚀 You're in %@!";
"league.weekly_result.promotion.subtitle.top3_a" = "#%d — strong result!";
"league.weekly_result.promotion.subtitle.top3_b" = "Top 3 — not a fluke.";
"league.weekly_result.promotion.subtitle.other" = "You placed #%d — level up!";
"league.weekly_result.win.hero" = "🏆 League champion!";
"league.weekly_result.nice.title" = "Top %d — great week!";
"league.weekly_result.reward.fbucks" = "+%d F-Bucks 💰";
"league.weekly_result.next_goal" = "Next goal — %@ 🏆";
"league.weekly_result.next_goal.alt" = "A little more — the top league awaits!";
"league.weekly_result.next_goal.pinnacle" = "You're among the best in the world! ✨";
"league.weekly_result.cta.keep_playing_arrow" = "Keep playing →";
"league.weekly_result.cta.toward_league_arrow" = "Toward %@ →";
"league.weekly_result.demotion.cta" = "Got it →";
"league.weekly_result.stayed.cta" = "Onward →";
"""

BLOCK_UK = """
"league.weekly_result.promotion.tagline" = "🔥 Новий рівень!";
"league.weekly_result.promotion.title" = "🚀 Ти вийшов у %@!";
"league.weekly_result.promotion.subtitle.top3_a" = "#%d місце — сильний результат!";
"league.weekly_result.promotion.subtitle.top3_b" = "Топ-3. Це вже не випадковість.";
"league.weekly_result.promotion.subtitle.other" = "Ти #%d — рівень вище!";
"league.weekly_result.win.hero" = "🏆 Чемпіон тижня!";
"league.weekly_result.nice.title" = "Топ-%d — крутий тиждень!";
"league.weekly_result.reward.fbucks" = "+%d F-Bucks 💰";
"league.weekly_result.next_goal" = "Наступна ціль — %@ 🏆";
"league.weekly_result.next_goal.alt" = "Ще трохи — і ти в топ-лізі!";
"league.weekly_result.next_goal.pinnacle" = "Ти серед найкращих у світі! ✨";
"league.weekly_result.cta.keep_playing_arrow" = "Грати далі →";
"league.weekly_result.cta.toward_league_arrow" = "До %@ →";
"league.weekly_result.demotion.cta" = "Зрозуміло →";
"league.weekly_result.stayed.cta" = "Далі →";
"""

BLOCK_RU = """
"league.weekly_result.promotion.tagline" = "🔥 Новый уровень!";
"league.weekly_result.promotion.title" = "🚀 Ты в %@!";
"league.weekly_result.promotion.subtitle.top3_a" = "#%d место — сильный результат!";
"league.weekly_result.promotion.subtitle.top3_b" = "Топ-3. Это уже не случайность.";
"league.weekly_result.promotion.subtitle.other" = "Ты #%d — уровень выше!";
"league.weekly_result.win.hero" = "🏆 Чемпион недели!";
"league.weekly_result.nice.title" = "Топ-%d — отличная неделя!";
"league.weekly_result.reward.fbucks" = "+%d F-Bucks 💰";
"league.weekly_result.next_goal" = "Следующая цель — %@ 🏆";
"league.weekly_result.next_goal.alt" = "Ещё чуть-чуть — и ты в топ-лиге!";
"league.weekly_result.next_goal.pinnacle" = "Ты среди лучших в мире! ✨";
"league.weekly_result.cta.keep_playing_arrow" = "Играть дальше →";
"league.weekly_result.cta.toward_league_arrow" = "К %@ →";
"league.weekly_result.demotion.cta" = "Понятно →";
"league.weekly_result.stayed.cta" = "Вперёд →";
"""

LANG_BLOCKS = {
    "uk": BLOCK_UK,
    "ru": BLOCK_RU,
}


def patch(path: Path) -> bool:
    text = path.read_text(encoding="utf-8")
    if CHECK in text:
        return False
    m = re.search(r'^"league\.weekly_result\.cta\.claim"\s*=\s*[^;]+;\s*\n', text, re.MULTILINE)
    if not m:
        print(f"SKIP no claim line: {path}")
        return False
    folder = path.parent.name.replace(".lproj", "")
    block = LANG_BLOCKS.get(folder, BLOCK_EN)
    insert = m.end()
    path.write_text(text[:insert] + block + text[insert:], encoding="utf-8")
    return True


def main() -> None:
    n = 0
    for lproj in sorted(RES.glob("*.lproj")):
        f = lproj / "Localizable.strings"
        if f.is_file() and patch(f):
            print(f"Patched {f.relative_to(ROOT)}")
            n += 1
    print(f"Done. Patched {n} files.")


if __name__ == "__main__":
    main()
