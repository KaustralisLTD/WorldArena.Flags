# Слои аватара (PNG + имена в Asset Catalog)

Сборка в коде: `AvatarLayeredComposerView` (ветка `legacyLayeredStack` или `AvatarDuolingoCanvasComposer` для `avatar_body_*`) → порядок слоёв снизу вверх.  
Имена задаются в `AvatarLayerAssetNames.swift` (должны совпадать с **именем imageset** в `Assets.xcassets`).

## Логическая структура (как в ТЗ)

| Папка (логика) | Файл | Imageset name (пример) |
|----------------|------|-------------------------|
| `head/` | `head_base.png` | `head_base` |
| `body/` | `body_default`, `body_slim`, `body_wide` | то же имя |
| `hair/` | только волосы, альфа | `hair_short`, `hair_curly`, … |
| `eyes/` | только глаза | `eyes_black`, `eyes_brown`, … |
| `mouth/` | только рот | `mouth_neutral`, `mouth_smile`, … |
| `glasses/` | | `glasses_round`, … |
| `beard/` | | `avatar_facial_hair_2` … `avatar_facial_hair_7` (холст как у тела) |
| `hat/` | | `avatar_hat_1` (cap), `avatar_hat_2` (sport); `avatar_hat_SilverLeague`, `avatar_hat_10_day_streak`, `avatar_hat_beginner`, `avatar_hat_Premium`; прочие — `hat_beanie` … при наличии |

## Обязательные имена (минимум для новой схемы)

- **Тело:** `body_default`, `body_slim`, `body_wide` — сейчас в проекте заполняются копиями старых bust PNG; можно заменить на **торс без головы**, если добавите `head_base`.
- **Голова:** `head_base` — опционально; если есть, на неё кладётся `colorMultiply` тона кожи. Пока не добавите отдельный торс, можно **не** класть `head_base` (оставить только составной `body_*`).

## Волосы в нижней сетке

Используются те же файлы, что и в превью: `hair_sidepart`, `hair_short`, `hair_curly`, `hair_mohawk`, `hair_buzz`.  
Формат: **только причёска**, прозрачный фон, без лица.

## Рот

Имена по `AvatarExpression.rawValue`:  
`mouth_neutral`, `mouth_smile`, `mouth_wink`, `mouth_tongue`, `mouth_angry`, `mouth_focused`.  
Пока файла нет — рисуется векторный запасной вариант.

## Fallback

Если imageset отсутствует, используются прежние ассеты (`AvatarEditorBody*`, векторные фигуры, старые `AvatarPicker*` в UI).

## Тело без лица / без волос (`avatar_body_1…6`)

Базовые торсы с пустой головой (под слои выражения и волос). Маппинг в `AvatarLayerAssetNames.body(for:)`: slim→1, regular→2, wide→3, hoodie→4, tshirt→5, sweater→6.

## Наборы конструктора (цельные PNG)

Маппинг в `AvatarLayerAssetNames`:

| Редактор | Imageset |
|----------|----------|
| Тело: slim … sweater | `avatar_body_1` … `avatar_body_6` |
| Причёска (не bald) | `avatar_hair_1` … `avatar_hair_9` |
| Выражение | `avatar_expression_1` … `avatar_expression_23` (`AvatarExpression.e1…e23`) |

Для `avatar_body_*` и `avatar_hair_*` **не** применяется `colorMultiply` (цвета в макете). Для `avatar_expression_*` отдельный слой глаз в композиторе **не** рисуется (лицо целиком на PNG). Рот fallback: `mouth_<rawValue>` если primary нет в каталоге.

**Один холст с телом** — для `avatar_body_*` в рантайме: `AvatarDuolingoCanvasComposer`, логический размер **501×684** (как в `temporary_examples`), все слои `avatar_body_*` / `avatar_hair_*` / `avatar_expression_*` в одном `frame`. Ранее: `bustW × bustH` в legacy-ветке.

| Слой | Ассет | Содержимое |
|------|--------|------------|
| Ниже | `avatar_hair_*` | Только волосы; **прозрачно** там, где лицо (иначе перекроют глаза/рот). |
| Выше | `avatar_expression_1…23` | Лица на холсте. JSON: число 1…23; старые строки `calm`/`expressive`/`dreamy` → 1/2/3. Поверх волос. |

**Порядок в ZStack (снизу вверх):** тело → волосы → выражение → очки → шапка. В legacy-ветке кадр лица не должен быть шире торса (`headW`/`headH`, `expressionScale`, `exprY`); в Duolingo-ветке выравнивание даёт общий холст.
