# Flags notification center

The iPhone/iPad application uses one account-scoped inbox for the icon badge, Profile tab, Profile notification entry and duel counters. Opening a message marks only that event read. The explicit toolbar action marks the displayed inbox history read. Read receipts survive offline use and are retried after reconnecting. Scheduled daily reminders are not unread events.

New duel invitations and results are saved even when APNs is unavailable or disabled. Lifecycle emails are copied to the inbox after successful delivery; existing delivered lifecycle emails appear as read history. Achievements and level increases are logged locally whether or not system push delivery is enabled.

## Operator messages without an app update

Run these commands inside the Flags server directory. No new public administrator API is exposed. Create a JSON file with a stable campaign ID, explicit recipient usernames and localized copy:

```json
{
  "id": "map-tip-october-2026",
  "users": ["RECIPIENT_USERNAME"],
  "copy": {
    "en": {"title": "Your world, your progress", "body": "Open Profile → World Progress Map to see the countries you know best and choose what to practise next."},
    "ru": {"title": "Твой мир. Твой прогресс", "body": "Открой Профиль → Карта прогресса мира: посмотри, какие страны ты знаешь увереннее, и выбери следующую цель."},
    "uk": {"title": "Твій світ. Твій прогрес", "body": "Відкрий Профіль → Карта прогресу світу: переглянь, які країни ти знаєш найкраще, та обери наступну мету."}
  }
}
```

Preview (does not send): `node send-inbox-message.js message.json`

Save in the recipients’ inboxes: `node send-inbox-message.js message.json --send`

Also request an APNs push: `node send-inbox-message.js message.json --send --push`

A repeated campaign ID does not duplicate or reopen the inbox event. Missing translations use the explicit English fallback. A push may still fail independently; the inbox message remains available. No messages have been sent as part of implementation/testing.

## Server installation

On the Mac: `bash "/Users/spilberg/Flags.World 08.04.2026/Server/deploy-flags-experience.sh"`

The installer backs up the Flags database and code and updates only the Flags process. Capitals is not modified.

## Duel refresh diagnostics

Concurrent foreground and duel-list GET refreshes share one request. Mutation requests are never automatically repeated. HTTP failures log the status and X-Request-ID, while network and server-response errors use the app’s language. The 17 October investigation returned HTTP 200 for both live duel sync endpoints; the collected server log did not contain a fresh sync failure matching the screenshot. A specific root cause for that historical client error is therefore not confirmed.
