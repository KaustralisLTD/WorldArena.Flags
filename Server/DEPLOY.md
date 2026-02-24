# Деплой API дуэлей на DigitalOcean (flags.worldarena.games)

Сервер: **157.230.11.51**  
Домен: **flags.worldarena.games**

---

## Что сделать прямо сейчас (команды по порядку)

Откройте **Терминал** на Mac. Копируйте и вставляйте блоки по очереди, после каждого нажимайте **Enter**.

**1. Перейти в папку Server на Mac:**

```bash
cd "/Volumes/spilberg/3.Work/9.iOS/Flags.World 06.04.2025/Server"
```

**2. Скопировать файлы API на сервер (введёте пароль root, когда попросит):**

```bash
scp package.json server.js db.js root@157.230.11.51:/var/www/flags.worldarena.games/duel-api/
```

**3. Зайти на сервер:**

```bash
ssh root@157.230.11.51
```

(Снова введите пароль root, если попросит.)

**4. Перейти в папку API и поставить зависимости:**

```bash
cd /var/www/flags.worldarena.games/duel-api
npm install
```

Подождать, пока закончится.

**5. Перезапустить API:**

```bash
pm2 restart duel-api
```

**6. Проверить:**

```bash
curl -s http://127.0.0.1:3001/api/v1/health
```

Должно вывести: `{"ok":true,"service":"duel-api"}`.

**7. Выйти с сервера:**

```bash
exit
```

Готово. После этого приложение будет сохранять пользователей, друзей и дуэли в базу на сервере.

---

# Пошаговая инструкция «как для чайников» (полный цикл с нуля)

Делать нужно **по порядку**. Если что-то пошло не так — смотри раздел «Частые ошибки» в конце.

---

## Шаг 0. Что понадобится

- **Пароль root** от сервера 157.230.11.51 (или доступ по SSH-ключу). Пароль обычно даёт DigitalOcean при создании дроплета; если забыли — сбросьте в панели DigitalOcean: Droplet → Access → Reset Root Password.
- **Терминал на Mac**: Программы → Утилиты → «Терминал», или в Spotlight (Cmd+Пробел) набрать «Terminal» и нажать Enter. Все команды ниже вводятся в этом окне и подтверждаются клавишей **Enter**.

---

## Шаг 1. Подключиться к серверу

1. Откройте **Терминал**.
2. Введите **ровно** эту строку и нажмите Enter:

```bash
ssh root@157.230.11.51
```

3. Если спросят «Are you sure you want to continue connecting?» — введите **yes** и Enter.
4. Если попросят пароль — введите **пароль root** (при вводе символы не отображаются — это нормально) и Enter.

**Получилось:** в начале строки появилось что-то вроде `root@WorldArena:~#` — вы на сервере.  
**Не получилось:** «Permission denied» — неверный пароль или не настроен ключ; сбросьте пароль в DigitalOcean или проверьте ключ.

Дальше все команды до шага 4 выполняются **на сервере** (в этом же окне).

---

## Шаг 2. Установить Node.js (один раз)

Вводите по одной команде, после каждой нажимайте Enter.

**2.1.** Скачать скрипт установки Node 20:

```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
```

Подождите, пока всё пройдёт без ошибок.

**2.2.** Установить Node.js:

```bash
sudo apt-get install -y nodejs
```

Может спросить пароль — введите тот же пароль root.

**2.3.** Проверить, что Node установился:

```bash
node -v
```

Должно вывести что-то вроде `v20.x.x`. Если команда не найдена — повторите 2.1 и 2.2.

**2.4.** Установить PM2 (чтобы приложение не падало и перезапускалось после перезагрузки сервера):

```bash
sudo npm install -g pm2
```

---

## Шаг 3. Создать папку для API на сервере

Введите:

```bash
mkdir -p /var/www/flags.worldarena.games/duel-api
```

Затем перейти в неё:

```bash
cd /var/www/flags.worldarena.games/duel-api
```

Проверка: введите `pwd` — должно показать `/var/www/flags.worldarena.games/duel-api`.

---

## Шаг 4. Выйти с сервера и скопировать файлы с Mac

**4.1.** Выйти с сервера (остаётесь в Терминале, но уже на своём Mac):

```bash
exit
```

**4.2.** Перейти в папку Server на вашем Mac (путь подставьте свой, если проект лежит в другом месте):

```bash
cd "/Volumes/spilberg/3.Work/9.iOS/Flags.World 06.04.2025/Server"
```

**4.3.** Скопировать файлы на сервер (снова попросит пароль root при необходимости):

```bash
scp package.json server.js db.js root@157.230.11.51:/var/www/flags.worldarena.games/duel-api/
```

**Получилось:** в конце будет строка с процентами и именами файлов.  
**Не получилось:** «Permission denied» — проверьте пароль; «No such file» — проверьте путь в команде `cd` (должна быть папка Server с файлами package.json и server.js).

---

## Шаг 5. Снова зайти на сервер и запустить API

**5.1.** Подключиться к серверу снова:

```bash
ssh root@157.230.11.51
```

**5.2.** Перейти в папку API:

```bash
cd /var/www/flags.worldarena.games/duel-api
```

**5.3.** Установить зависимости (скачает библиотеки для Node):

```bash
npm install
```

Подождите окончания. Данные (пользователи, друзья, дуэли) хранятся в SQLite: при первом запуске создаётся каталог `data/` и файл `data/duel.db`.

**5.4.** Запустить API через PM2 (порт 3001):

```bash
PORT=3001 pm2 start server.js --name duel-api
```

**5.5.** Сохранить список процессов PM2, чтобы после перезагрузки сервера API поднялся сам:

```bash
pm2 save
```

**5.6.** Включить автозапуск PM2 при загрузке сервера. Введите:

```bash
pm2 startup
```

В конце команда покажет строку вида `sudo env PATH=... pm2 startup systemd -u root --hp /root`. **Скопируйте и выполните эту строку целиком** (она будет своей у вас). После этого снова выполните:

```bash
pm2 save
```

**5.7.** Проверить, что API отвечает **внутри** сервера:

```bash
curl -s http://127.0.0.1:3001/api/v1/health
```

Должно вывести: `{"ok":true,"service":"duel-api"}`. Если пусто или ошибка — смотрите логи: `pm2 logs duel-api`.

---

## Шаг 6. Настроить nginx (чтобы https://flags.worldarena.games/api/ работал снаружи)

Вы всё ещё на сервере (после `ssh root@157.230.11.51`).

**6.1.** Узнать, какой конфиг отвечает за flags.worldarena.games:

```bash
ls /etc/nginx/sites-available/
```

Запомните имя файла с flags или worldarena (например `flags.worldarena.games` или `default`). Дальше подставьте его вместо `ИМЯ_ФАЙЛА`.

**6.2.** Открыть конфиг в редакторе:

```bash
sudo nano /etc/nginx/sites-available/ИМЯ_ФАЙЛА
```

(замените ИМЯ_ФАЙЛА на то, что увидели в 6.1)

**6.3.** В nano найдите блок `server {`. Внутри него уже есть разные `location` (например для сайта, для /anthems/ и т.д.). Поставьте курсор в пустую строку **внутри** блока `server { }` (например после какого-нибудь `location`) и вставьте **ровно** этот блок:

```nginx
# ^~ — приоритет над location / и try_files, чтобы /api/* не отдавал SPA
location ^~ /api/ {
    proxy_pass http://127.0.0.1:3001;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

- Сохранение в nano: **Ctrl+O**, Enter, затем выход: **Ctrl+X**.

**6.4.** Проверить конфиг nginx:

```bash
sudo nginx -t
```

Должно быть: `syntax is ok` и `test is successful`. Если «syntax error» — откройте конфиг снова и проверьте, что скобки и точка с запятой на месте.

**6.5.** Применить конфиг:

```bash
sudo systemctl reload nginx
```

**6.6.** Проверить с вашего Mac (можно в новом окне Терминала или в браузере):

```bash
curl -s https://flags.worldarena.games/api/v1/health
```

Или откройте в браузере: **https://flags.worldarena.games/api/v1/health** — должна открыться строка `{"ok":true,"service":"duel-api"}`.

**Получилось** — API доступен снаружи, приложение может к нему обращаться.  
**Не получилось:** 502 Bad Gateway — значит nginx не дотягивается до порта 3001; проверьте шаг 5 и `pm2 list` (должен быть duel-api в статусе online).

---

## Шаг 7. Дальнейшие обновления (когда меняете server.js)

Когда вы изменили код API на Mac:

1. Откройте Терминал на Mac.
2. Выполните:

```bash
cd "/Volumes/spilberg/3.Work/9.iOS/Flags.World 06.04.2025/Server"
scp server.js root@157.230.11.51:/var/www/flags.worldarena.games/duel-api/
ssh root@157.230.11.51 "cd /var/www/flags.worldarena.games/duel-api && pm2 restart duel-api"
```

Или запустите готовый скрипт (если настроен SSH без пароля):

```bash
cd "/Volumes/spilberg/3.Work/9.iOS/Flags.World 06.04.2025/Server"
./deploy-to-server.sh
```

---

## Частые ошибки

| Что видите | Что делать |
|------------|------------|
| `Permission denied (publickey,password)` | Неверный пароль или нет ключа. Сбросьте пароль root в DigitalOcean или настройте SSH-ключ. |
| `command not found: node` | Node.js не установлен. Повторите шаг 2. |
| `EADDRINUSE` или порт 3001 занят | Кто-то уже слушает 3001. Выполните `pm2 delete duel-api` и снова `PORT=3001 pm2 start server.js --name duel-api`. |
| 502 Bad Gateway в браузере | API не запущен или nginx не туда смотрит. На сервере: `pm2 list`, `pm2 logs duel-api`, проверьте шаг 6. |
| `npm install` падает с ошибкой | На сервере выполните `sudo apt-get update` и снова `npm install` в папке duel-api. |

---

## Кратко: что мы сделали

1. Зашли на сервер по SSH.  
2. Установили Node.js и PM2.  
3. Создали папку и скопировали туда `package.json` и `server.js`.  
4. Запустили API через PM2 на порту 3001.  
5. Настроили nginx, чтобы запросы на `https://flags.worldarena.games/api/` шли на этот процесс.

Теперь приложение в телефоне обращается к **https://flags.worldarena.games/api/v1/** — вызовы дуэлей сохраняются на сервере.

---

# Справка (для опытных)

## Статус деплоя (проверено)

- На сервере **157.230.11.51** развёрнуто:
  - Файлы API в `/var/www/flags.worldarena.games/duel-api/`
  - Node.js + PM2, процесс `duel-api` на порту **3001** (online)
  - В nginx для `flags.worldarena.games` добавлен блок **location ^~ /api/** (прокси на 127.0.0.1:3001)
- Проверка **на сервере**: `curl http://127.0.0.1:3001/api/v1/health` → `{"ok":true,"service":"duel-api"}`
- Если с интернета **https://flags.worldarena.games/api/v1/health** отдаёт не JSON, а главную страницу — трафик к домену идёт не на этот сервер (CDN/другой хост). Нужно направить домен (или поддомен API) на 157.230.11.51 в DNS или в настройках CDN.

---

## Проверка прямо на дроплете (когда вы уже залогинены)

Выполняйте по очереди (копируйте и вставляйте в терминал):

**1. API запущен и отвечает:**
```bash
pm2 list
curl -s http://127.0.0.1:3001/api/v1/health
```
Ожидаемо: в `pm2 list` процесс `duel-api` в статусе `online`, curl выводит `{"ok":true,"service":"duel-api"}`.

**2. Если duel-api нет или статус не online — запустить заново:**
```bash
cd /var/www/flags.worldarena.games/duel-api
PORT=3001 pm2 start server.js --name duel-api
pm2 save
```

**3. В nginx есть блок для /api/:**
```bash
grep -A 8 "location.*/api/" /etc/nginx/sites-available/flags.worldarena.games
```
Должны увидеть `location ^~ /api/`, `proxy_pass http://127.0.0.1:3001;` и заголовки.

**4. Проверка через nginx локально (на сервере):**
```bash
# HTTP (порт 80)
curl -s -H "Host: flags.worldarena.games" http://127.0.0.1/api/v1/health
# HTTPS (порт 443) — должен отдавать JSON, не HTML главной
curl -s -k -H "Host: flags.worldarena.games" https://127.0.0.1/api/v1/health
```
Ожидаемо: `{"ok":true,"service":"duel-api"}`.

**Если по HTTPS приходит HTML вместо JSON:** на 443 слушает отдельный блок `server { listen 443 ssl; ... }`. Блок `location ^~ /api/` нужно добавить **и туда** (в тот же файл, в блок с `listen 443` и `server_name ... flags.worldarena.games`). Проверка:
```bash
# В каком файле есть 443 для этого домена
grep -l "flags.worldarena.games" /etc/nginx/sites-enabled/*
# Есть ли /api/ в том же файле и в блоке с 443 (часто два server: 80 и 443)
grep -n "listen.*443\|location.*/api/" /etc/nginx/sites-available/flags.worldarena.games
```
Если `location ... /api/` стоит только рядом с `listen 80`, можно один раз запустить на сервере скрипт (он сделает бэкап, добавит блок в 443 и перезагрузит nginx):
```bash
# с вашей машины: скопировать скрипт на сервер и выполнить
scp Server/fix-nginx-api-443.sh root@157.230.11.51:/root/
ssh root@157.230.11.51 'bash /root/fix-nginx-api-443.sh'
```
Либо вручную добавить блок `location ^~ /api/ { ... }` в блок с `listen 443`, затем `nginx -t && systemctl reload nginx`.

**5. Автозапуск PM2 после перезагрузки сервера (один раз):**
```bash
pm2 startup
```
В конце будет строка вида `sudo env PATH=... pm2 startup systemd -u root --hp /root` — скопируйте и выполните её, затем снова: `pm2 save`.

---

## Быстрый деплой (один скрипт)

Если у вас уже настроен SSH-доступ к серверу (ключ или пароль для root), из папки проекта выполните:

```bash
cd "/Volumes/spilberg/3.Work/9.iOS/Flags.World 06.04.2025/Server"
./deploy-to-server.sh
```

Скрипт создаст каталог на сервере, скопирует файлы, установит зависимости и перезапустит/запустит PM2. Один раз вручную на сервере нужно установить Node.js, PM2 и добавить location в nginx (см. ниже).

---

## 1. Подключение к серверу

```bash
ssh root@157.230.11.51
# или: ssh root@flags.worldarena.games
```

---

## 2. Установка Node.js (если ещё нет)

```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs
node -v   # v20.x
```

---

## 3. Установка PM2 (процесс-менеджер)

```bash
sudo npm install -g pm2
```

---

## 4. Размещение приложения API

На сервере создайте каталог и скопируйте файлы (с вашей машины или через git):

**Вариант A — с локальной машины (из папки проекта):**

```bash
# На вашем Mac (из корня проекта World Arena Flags)
cd "/Volumes/spilberg/3.Work/9.iOS/Flags.World 06.04.2025"
scp -r Server root@157.230.11.51:/var/www/flags.worldarena.games/duel-api
```

**Вариант B — на сервере вручную:**

```bash
sudo mkdir -p /var/www/flags.worldarena.games/duel-api
cd /var/www/flags.worldarena.games/duel-api
sudo nano package.json   # вставьте содержимое Server/package.json
sudo nano server.js      # вставьте содержимое Server/server.js
```

Затем на сервере:

```bash
cd /var/www/flags.worldarena.games/duel-api
npm install
```

---

## 5. Запуск через PM2

```bash
cd /var/www/flags.worldarena.games/duel-api
PORT=3001 pm2 start server.js --name duel-api
pm2 save
pm2 startup   # выполнить предложенную команду для автозапуска после перезагрузки
```

Проверка:

```bash
curl -s http://127.0.0.1:3001/api/v1/health
# {"ok":true,"service":"duel-api"}
```

---

## 6. Nginx: проксирование /api/ на Node

На сервере обычно конфиг nginx для сайта лежит в `/etc/nginx/sites-available/` (или `sites-enabled`). Нужно добавить location для API.

Откройте конфиг для flags.worldarena.games:

```bash
sudo nano /etc/nginx/sites-enabled/flags.worldarena.games
# Важно: nginx читает sites-enabled. Там может быть отдельный файл (не симлинк на sites-available).
# Добавляйте `location ^~ /api/` в блок server с listen 443 в этом файле.
```

В блок `server { ... }` для `flags.worldarena.games` добавьте:

```nginx
# ^~ — приоритет над location / и try_files, чтобы /api/* не отдавал SPA
location ^~ /api/ {
    proxy_pass http://127.0.0.1:3001;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

Проверка и перезагрузка nginx:

```bash
sudo nginx -t
sudo systemctl reload nginx
```

Проверка снаружи:

```bash
curl -s https://flags.worldarena.games/api/v1/health
# {"ok":true,"service":"duel-api"}
```

---

## 7. Обновление API после изменений

```bash
cd /var/www/flags.worldarena.games/duel-api
# обновить server.js (scp или git pull)
pm2 restart duel-api
```

---

## Итог

- API доступен по адресу: **https://flags.worldarena.games/api/v1/**
- Эндпоинты: `POST /api/v1/duel/challenge`, `GET /api/v1/duel/incoming`, `POST /api/v1/duel/accept`, `POST /api/v1/duel/submit`, `POST /api/v1/duel/random-opponent`, `POST /api/v1/users/register`.
- Данные пока в памяти процесса; для постоянного хранения и Push позже добавить БД и APNs/FCM.
