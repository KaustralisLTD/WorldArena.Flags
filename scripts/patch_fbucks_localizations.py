#!/usr/bin/env python3
"""Добавляет ключи fbucks.* во все Localizable.strings из en.lproj."""
import os

ROOT = os.path.join(os.path.dirname(__file__), "..", "World Arena. Flags", "Resources")
EN_PATH = os.path.join(ROOT, "en.lproj", "Localizable.strings")

# Полные переводы (остальные языки получают английский блок из en)
RU_BLOCK = r"""
/* F-Bucks screen */
"fbucks.close" = "Закрыть";
"fbucks.currency.name" = "F-Bucks";
"fbucks.hero.subtitle.enough" = "Хватит примерно на %d предмета";
"fbucks.hero.subtitle.rare" = "Можно купить редкий предмет";
"fbucks.hero.subtitle.save" = "Копи на что-то особенное";
"fbucks.daily.title" = "Ежедневный бонус";
"fbucks.daily.subtitle" = "+1 F-Bucks";
"fbucks.daily.claim" = "Забрать";
"fbucks.daily.claimed" = "Уже забрали сегодня";
"fbucks.daily.hint" = "+1 сегодня доступно — нажми «Забрать»";
"fbucks.earn.today.title" = "Заработать сегодня";
"fbucks.earn.today.subtitle" = "Сегодня можно до %d F-Bucks";
"fbucks.earn.perfect.title" = "Идеальная игра";
"fbucks.earn.perfect.sub" = "+1 за 10/10 или 15/15";
"fbucks.earn.streak" = "Серия";
"fbucks.earn.streak.sub" = "Серия (%d/10 дней)";
"fbucks.earn.league" = "Топ недели";
"fbucks.earn.league.sub" = "Попади в топ-3 своей лиги";
"fbucks.progress.title" = "Прогресс к следующему предмету";
"fbucks.progress.percent" = "%d%%";
"fbucks.progress.full" = "Хватает на следующие награды — открой магазин!";
"fbucks.want.title" = "Следующая цель";
"fbucks.want.price" = "Цена: %d F-Bucks";
"fbucks.want.you" = "У тебя: %d";
"fbucks.want.need" = "Не хватает ещё %d";
"fbucks.earn_more" = "Заработать ещё →";
"fbucks.buy_for" = "Купить за %d";
"fbucks.shop.title" = "Магазин";
"fbucks.shop.subtitle" = "Трать F-Bucks на эксклюзивные элементы аватара";
"fbucks.shop.tier.common" = "Обычные";
"fbucks.shop.tier.rare" = "Редкие";
"fbucks.shop.tier.legendary" = "Легендарные";
"fbucks.shop.limited" = "LIMITED";
"fbucks.perfect.badge" = "Идеальная";
"fbucks.tab.today" = "Сегодня";
"fbucks.tab.about" = "О валюте";
"fbucks.tab.history" = "История";
"fbucks.tab.shop" = "Магазин";
"fbucks.about.title" = "Что такое F-Bucks?";
"fbucks.about.body" = "F-Bucks (Flags Bucks) — внутриигровая валюта, которую можно заработать в World Arena Flags. Трать её на уникальные элементы аватара, скины и другие эксклюзивные предметы.";
"fbucks.about.how" = "Как заработать F-Bucks";
"fbucks.about.perfect.title" = "Идеальная игра";
"fbucks.about.perfect.desc" = "Идеальный результат (10/10 или 15/15)";
"fbucks.about.streak10.title" = "Серия 10 дней";
"fbucks.about.streak10.desc" = "Играй 10 дней подряд";
"fbucks.about.streak20.title" = "Серия 20 дней";
"fbucks.about.streak20.desc" = "Играй 20 дней подряд";
"fbucks.about.streak50.title" = "Серия 50 дней";
"fbucks.about.streak50.desc" = "Играй 50 дней подряд";
"fbucks.about.streak100.title" = "Серия 100 дней";
"fbucks.about.streak100.desc" = "Играй 100 дней подряд";
"fbucks.reward.plus1" = "+1 F-Bucks";
"fbucks.reward.plus2" = "+2 F-Bucks";
"fbucks.reward.plus5" = "+5 F-Bucks";
"fbucks.reward.plus10" = "+10 F-Bucks";
"fbucks.history.title" = "История начислений";
"fbucks.history.empty" = "История пуста";
"fbucks.history.empty.hint" = "Играй и зарабатывай F-Bucks!";
"fbucks.item.traveler_cap" = "Кепка путешественника";
"fbucks.item.champion_shirt" = "Футболка чемпиона";
"fbucks.item.socks" = "Носки";
"fbucks.item.rainbow_skin" = "Радужный скин";
"fbucks.item.gold_skin" = "Золотой скин";
"fbucks.item.explorer_jacket" = "Куртка исследователя";
"fbucks.item.fire_effect" = "Огненный эффект";
"fbucks.item.neon_skin" = "Неоновый скин";
"fbucks.item.stars_effect" = "Звёздный эффект";
"fbucks.item.champion_jacket" = "Куртка чемпиона";
"fbucks.tx.daily_bonus" = "Ежедневный бонус";
"""

UK_BLOCK = r"""
/* F-Bucks screen */
"fbucks.close" = "Закрити";
"fbucks.currency.name" = "F-Bucks";
"fbucks.hero.subtitle.enough" = "Вистачить приблизно на %d предмети";
"fbucks.hero.subtitle.rare" = "Можна купити рідкий предмет";
"fbucks.hero.subtitle.save" = "Копи на щось особливе";
"fbucks.daily.title" = "Щоденний бонус";
"fbucks.daily.subtitle" = "+1 F-Bucks";
"fbucks.daily.claim" = "Забрати";
"fbucks.daily.claimed" = "Уже забрали сьогодні";
"fbucks.daily.hint" = "+1 сьогодні доступно — натисни «Забрати»";
"fbucks.earn.today.title" = "Заробити сьогодні";
"fbucks.earn.today.subtitle" = "Сьогодні можна до %d F-Bucks";
"fbucks.earn.perfect.title" = "Ідеальна гра";
"fbucks.earn.perfect.sub" = "+1 за 10/10 або 15/15";
"fbucks.earn.streak" = "Серія";
"fbucks.earn.streak.sub" = "Серія (%d/10 днів)";
"fbucks.earn.league" = "Топ тижня";
"fbucks.earn.league.sub" = "Потрап у топ-3 своєї ліги";
"fbucks.progress.title" = "Прогрес до наступного предмета";
"fbucks.progress.percent" = "%d%%";
"fbucks.progress.full" = "Вистачає на наступні нагороди — відкрий магазин!";
"fbucks.want.title" = "Наступна ціль";
"fbucks.want.price" = "Ціна: %d F-Bucks";
"fbucks.want.you" = "У тебе: %d";
"fbucks.want.need" = "Не вистачає ще %d";
"fbucks.earn_more" = "Заробити ще →";
"fbucks.buy_for" = "Купити за %d";
"fbucks.shop.title" = "Магазин";
"fbucks.shop.subtitle" = "Витрачай F-Bucks на ексклюзивні елементи аватара";
"fbucks.shop.tier.common" = "Звичайні";
"fbucks.shop.tier.rare" = "Рідкісні";
"fbucks.shop.tier.legendary" = "Легендарні";
"fbucks.shop.limited" = "LIMITED";
"fbucks.perfect.badge" = "Ідеально";
"fbucks.tab.today" = "Сьогодні";
"fbucks.tab.about" = "Про валюту";
"fbucks.tab.history" = "Історія";
"fbucks.tab.shop" = "Магазин";
"fbucks.about.title" = "Що таке F-Bucks?";
"fbucks.about.body" = "F-Bucks (Flags Bucks) — внутрішньоігрова валюта, яку можна заробити в World Arena Flags. Витрачай її на унікальні елементи аватара, скіни та інші ексклюзивні предмети.";
"fbucks.about.how" = "Як заробити F-Bucks";
"fbucks.about.perfect.title" = "Ідеальна гра";
"fbucks.about.perfect.desc" = "Ідеальний результат (10/10 або 15/15)";
"fbucks.about.streak10.title" = "Серія 10 днів";
"fbucks.about.streak10.desc" = "Грай 10 днів поспіль";
"fbucks.about.streak20.title" = "Серія 20 днів";
"fbucks.about.streak20.desc" = "Грай 20 днів поспіль";
"fbucks.about.streak50.title" = "Серія 50 днів";
"fbucks.about.streak50.desc" = "Грай 50 днів поспіль";
"fbucks.about.streak100.title" = "Серія 100 днів";
"fbucks.about.streak100.desc" = "Грай 100 днів поспіль";
"fbucks.reward.plus1" = "+1 F-Bucks";
"fbucks.reward.plus2" = "+2 F-Bucks";
"fbucks.reward.plus5" = "+5 F-Bucks";
"fbucks.reward.plus10" = "+10 F-Bucks";
"fbucks.history.title" = "Історія нарахувань";
"fbucks.history.empty" = "Історія порожня";
"fbucks.history.empty.hint" = "Грай і заробляй F-Bucks!";
"fbucks.item.traveler_cap" = "Кепка мандрівника";
"fbucks.item.champion_shirt" = "Футболка чемпіона";
"fbucks.item.socks" = "Шкарпетки";
"fbucks.item.rainbow_skin" = "Веселковий скін";
"fbucks.item.gold_skin" = "Золотий скін";
"fbucks.item.explorer_jacket" = "Куртка дослідника";
"fbucks.item.fire_effect" = "Вогняний ефект";
"fbucks.item.neon_skin" = "Неоновий скін";
"fbucks.item.stars_effect" = "Зоряний ефект";
"fbucks.item.champion_jacket" = "Куртка чемпіона";
"fbucks.tx.daily_bonus" = "Щоденний бонус";
"""


def read_en_block() -> str:
    with open(EN_PATH, encoding="utf-8") as f:
        text = f.read()
    start = text.find("/* F-Bucks screen */")
    if start < 0:
        raise SystemExit("F-Bucks block not found in en")
    return "\n" + text[start:].lstrip()


def main() -> None:
    en_block = read_en_block()
    overrides = {"ru": RU_BLOCK.strip() + "\n", "uk": UK_BLOCK.strip() + "\n"}

    for name in os.listdir(ROOT):
        if not name.endswith(".lproj"):
            continue
        code = name.replace(".lproj", "")
        if code == "en":
            continue
        path = os.path.join(ROOT, name, "Localizable.strings")
        if not os.path.isfile(path):
            continue
        with open(path, encoding="utf-8") as f:
            content = f.read()
        if '"fbucks.close"' in content:
            continue
        block = overrides.get(code, en_block)
        if not content.endswith("\n"):
            content += "\n"
        with open(path, "w", encoding="utf-8") as f:
            f.write(content + "\n" + block)
        print("patched", path)


if __name__ == "__main__":
    main()
