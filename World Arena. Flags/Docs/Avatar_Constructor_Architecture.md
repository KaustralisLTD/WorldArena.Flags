# Архитектура конструктора аватара (как у Duolingo: composition, не один PNG)

## Источник правды

| Идея (веб / Duolingo) | В проекте |
|------------------------|-----------|
| `avatar = composition(layers)` | `AvatarConfiguration` (Codable) + `AvatarStorage` |
| Слои не «одна картинка» | `AvatarLayeredComposerView` складывает imageset’ы; вектор — fallback |
| Синхронизация без Apply | `@Published draft` в `AvatarEditorViewModel`, превью на `draft` |
| Один anchor / кадр | Для `avatar_body_*`: `AvatarDuolingoCanvasComposer` — логический холст **501×684** (как `temporary_examples`); иначе `GeometryReader` в `legacyLayeredStack` |

## Маппинг полей (JS → Swift)

```text
body / outfit     → bodyStyle + clothingStyle + clothingColor
skinColor         → skinTone (AvatarColorToken)
eyes              → eyeColor + слой `AvatarLayerAssetNames.eyes`
mouth             → expression → `mouthPrimary` / `mouthFallback`
hair              → hairstyle + hairColor
glasses           → glassesStyle + glassesColor?
beard             → facialHairStyle + facialHairColor?
hat               → headwearStyle + headwearColor?
background        → backgroundColor
```

Цельные PNG конструктора (`avatar_body_*`, `avatar_expression_*`, `avatar_hair_*`) — те же **слои логической модели**, просто один imageset закрывает несколько полей визуально.

## Порядок слоёв (снизу вверх)

- **Duolingo-холст** (`avatar_body_*`): `AvatarDuolingoCanvasComposer` — тело → волосы → выражение (или глаза+рот) → очки → шапка; без бороды поверх цельного тела.
- **Legacy**: `AvatarLayeredComposerView.legacyLayeredStack` — тело → head_base (если есть) → одежда (если не цельное тело) → глаза → рот/выражение → борода → волосы → очки → шапка.

## Layout экрана редактора (SwiftUI)

- **Compact** (телефон портрет): сверху превью → табы категорий → скролл опций.
- **Regular** (iPad и широкая ширина): **слева** превью на всю высоту блока, **справа** скролл опций, **снизу** общая полоса табов (как нижняя навигация у Duolingo).

## Следующие шаги по ассетам

1. Все слои — **один размер холста** и общая точка привязки (подбородок / центр лица).
2. `head_base` без лица; `eyes_*` / `mouth_*` или `avatar_expression_*` согласованы по позиции.
3. Торс `avatar_body_*` или векторный fallback — один вертикальный масштаб с головой.

## Сервер / друзья

`DuelAPIService.updateMyAvatarConfig` шлёт сериализованный `AvatarConfiguration` — это и есть «не PNG, а модель».
