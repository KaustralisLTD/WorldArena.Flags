# API дуэлей (Duel) — World Arena Flags

Сервер хранит пользователей, друзей и вызовы в SQLite; доставляет вызовы оппоненту (Push — в планах).

## Хранилище (SQLite)
- **users**: username (PK), friend_code (уникальный код для добавления в друзья), device_token, level, xp, streak, total_games_played, correct_answers, best_time
- **friendships**: пары (user_username, friend_username)
- **duel_challenges**: вызовы с полями id, challenger_id/opponent_id (username), seed, scores, status

## Базовый URL
```
https://flags.worldarena.games/api/v1
```

## Аутентификация
Все запросы (кроме регистрации/логина) передают заголовок:
- `Authorization: Bearer <access_token>` или
- `X-User-Id: <uuid>` + `X-Device-Token: <apns_or_fcm_token>` для упрощённой схемы

## Модели

### DuelChallenge (на сервере)
- `id` (string)
- `challengerId`, `challengerName`
- `opponentId`, `opponentName`
- `seed` (int) — для одинаковой игры у обоих
- `createdAt`, `status`: `pending` | `challenger_completed` | `opponent_completed` | `completed`
- `challengerScore`, `opponentScore` (int | null)

### Игрок (для подбора случайного соперника)
- `userId`, `username`, `level`, `xp`, `streak`
- `totalGamesPlayed`, `correctAnswers` (для точности)
- `avgTimePerGame` или `bestTime` (для подбора по времени)
- `deviceToken` (для Push)

---

## Эндпоинты

### 1. Создать вызов на дуэль
**POST** `/duel/challenge`

**Body:**
```json
{
  "opponentId": "uuid-оппонента",
  "seed": 12345678,
  "challengerName": "Имя вызывающего"
}
```

**Ответ:** `201`
```json
{
  "challengeId": "uuid",
  "seed": 12345678,
  "opponentName": "Имя оппонента"
}
```

**Логика сервера:**
- Сохранить вызов со статусом `pending`.
- Отправить Push оппоненту: «Вам бросил вызов [challengerName]» (payload с `challengeId`, `seed`, `challengerId`, `challengerName`).

---

### 2. Входящие вызовы
**GET** `/duel/incoming`

**Ответ:** `200`
```json
{
  "challenges": [
    {
      "id": "...",
      "challengerId": "...",
      "challengerName": "...",
      "seed": 12345678,
      "createdAt": "...",
      "challengerScore": null,
      "status": "pending"
    }
  ]
}
```

Нужно вызывать при открытии приложения и по pull-to-refresh; при получении Push с типом `duel_challenge` добавить вызов в локальный список и показать экран дуэли.

---

### 3. Принять вызов
**POST** `/duel/accept`

**Body:**
```json
{
  "challengeId": "uuid"
}
```

**Ответ:** `200`
```json
{
  "seed": 12345678,
  "challengerName": "...",
  "challengerScore": null
}
```

Клиент сохраняет вызов в `incomingDuelChallenges` (если ещё не сохранён из Push), запускает игру с этим `seed`.

---

### 4. Отправить результат
**POST** `/duel/submit`

**Body:**
```json
{
  "challengeId": "uuid",
  "score": 12,
  "side": "challenger" | "opponent"
}
```

**Ответ:** `200**
```json
{
  "status": "challenger_completed" | "opponent_completed" | "completed",
  "winner": "challenger" | "opponent" | null,
  "challengerScore": 12,
  "opponentScore": null
}
```

**Логика сервера:**
- Обновить `challengerScore` или `opponentScore`, обновить статус.
- Если оба результата есть: вычислить победителя (больше очков), установить `status: completed`, отправить Push победителю: «Вы победили в дуэли!».

---

### 5. Случайный соперник (похожая статистика)
**POST** `/duel/random-opponent`

**Body:**
```json
{
  "excludeFriendIds": ["uuid1", "uuid2"],
  "myStats": {
    "totalGamesPlayed": 100,
    "correctAnswers": 850,
    "bestTime": 120.5,
    "level": 5
  }
}
```

**Ответ:** `200`
```json
{
  "opponentId": "uuid",
  "opponentName": "Соперник",
  "level": 5,
  "xp": 4200
}
```

Сервер выбирает игрока с близкой статистикой (по точности, времени, уровню), не из друзей. Если такого нет — вернуть 404 или «лучшего доступного».

---

## Push-уведомления

### Требования
- iOS: APNs (device token сохраняется при логине/настройках).
- Android (если будет): FCM.

### Типы payload
1. **duel_challenge** — входящий вызов  
   - `challengeId`, `seed`, `challengerId`, `challengerName`  
   - Заголовок: «Дуэль», текст: «[challengerName] вызвал вас на дуэль».

2. **duel_won** — победа в дуэли  
   - Заголовок: «Дуэль», текст: «Вы победили в дуэли!».

3. **nudge** — напоминание от друга  
   - Заголовок: «[fromUsername] reminds you», тело — мотивационная фраза (англ. на push; в приложении — по языку пользователя).  
   - Реализовано в `Server/push.js` (опционально: env `APNS_KEY_ID`, `APNS_TEAM_ID`, `APNS_BUNDLE_ID`, `APNS_KEY_P8_PATH`, пакет `apn`).

---

---

## Пользователи и друзья

### Регистрация / обновление пользователя
**POST** `/users/register`

**Body:**
```json
{
  "userId": "username или uuid",
  "username": "Отображаемое имя",
  "deviceToken": "apns-токен или null",
  "stats": { "level": 1, "xp": 0, "streak": 0, "totalGamesPlayed": 0, "correctAnswers": 0, "bestTime": null }
}
```

**Ответ:** `200`
```json
{
  "ok": true,
  "username": "Player",
  "friendCode": "ABC12XYZ"
}
```
При первом регистрации сервер выдаёт уникальный **friendCode** (8 символов). Его показывают в «Добавить друзей» и передают другим игрокам для добавления в друзья.

---

### Найти пользователя по коду друга
**GET** `/users/by-code/:code`

**Ответ:** `200`
```json
{
  "username": "FriendName",
  "friendCode": "ABC12XYZ",
  "level": 5,
  "xp": 4200,
  "streak": 3
}
```
Используется при добавлении друга по коду: клиент сначала запрашивает данные по коду, затем вызывает `POST /friends/add`.

---

### Добавить друга по коду
**POST** `/friends/add`

**Заголовок:** `X-User-Id: <мой username>`

**Body:**
```json
{
  "friendCode": "ABC12XYZ"
}
```

**Ответ:** `200`
```json
{
  "ok": true,
  "friend": {
    "username": "FriendName",
    "friendCode": "ABC12XYZ",
    "level": 5,
    "xp": 4200,
    "streak": 3
  }
}
```

---

### Список друзей
**GET** `/users/me/friends?userId=<username>`

**Ответ:** `200`
```json
{
  "friends": [
    {
      "username": "FriendName",
      "friendCode": "ABC12XYZ",
      "level": 5,
      "xp": 4200,
      "streak": 3
    }
  ]
}
```
Можно вызывать при старте приложения для синхронизации списка друзей с сервером.

---

## Напоминания друзьям (Nudge)

### Отправить напоминание
**POST** `/nudge`

**Заголовок:** `X-User-Id: <мой username>`

**Body:**
```json
{
  "toUsername": "username друга",
  "phraseId": 0
}
```
`phraseId` — индекс мотивационной фразы (0..14). В приложении получателя фраза показывается на его языке по ключу `nudge_phrase_1` … `nudge_phrase_15`. Отправить можно только другу (проверка по friendships).

**Ответ:** `200` `{ "ok": true, "nudgeId": "uuid" }`

Сервер сохраняет nudge в БД и при наличии у получателя `device_token` отправляет APNs push (заголовок: «[fromUsername] reminds you», тело — фраза на англ.). Без настройки APNs push не уходит, но при открытии приложения получатель увидит напоминание через inbox.

### Inbox напоминаний
**GET** `/nudge/inbox?userId=<username>`

**Заголовок:** `X-User-Id: <username>` (опционально)

**Ответ:** `200`
```json
{
  "nudges": [
    { "id": "uuid", "fromUsername": "Anton", "phraseId": 2, "createdAt": "2025-02-19T12:00:00.000Z" }
  ]
}
```
Только непрочитанные. В приложении: показать alert «[fromUsername] напоминает вам» + локализованная фраза по `phraseId`.

### Отметить как прочитанные
**POST** `/nudge/read`

**Заголовок:** `X-User-Id: <username>`

**Body:** `{ "userId": "username" }` (опционально)

**Ответ:** `200` `{ "ok": true }`

---

## Стек сервера
- **Node.js + Express**
- Хранилище: **SQLite** (better-sqlite3), файл `Server/data/duel.db`
- Push: в планах (node-apn / firebase-admin)
