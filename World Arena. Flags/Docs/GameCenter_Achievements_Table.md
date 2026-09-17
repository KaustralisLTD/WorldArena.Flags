# Game Center Achievements Table

Справочник для App Store Connect (Achievement ID, points, hidden, repeatable) и локализаций.

## Примечания
- `titleKey/descriptionKey` — это те ключи, которые используются в коде (`LocalizationManager.localizedString`).
- `point value / hidden / repeatable` заданы под нашу механику: `1 звезда = 10 очков`. Для `xp_10000` разрешены повторы: каждые дополнительные `+10.000 XP` дают ещё `+1 звезда`.
- `Properties (key=value)` и `Associated action` — оставлены пустыми, т.к. связки пока не указаны.

| Achievement ID | titleKey | descriptionKey | Point value | Hidden | Repeatable | Properties (key=value) | Associated action |
|---|---|---|---|---|---|---|---|
| streak_5 | Ранняя птица | Достигните серии 5 дней | 10 | нет | да | - | - |
| streak_10 | Стабильность | Серия 10 дней | 20 | нет | да | - | - |
| streak_30 | Железная воля | Серия 30 дней | 30 | нет | да | - | - |
| xp_1000 | Новичок XP | Наберите 1000 XP | 10 | нет | да | - | - |
| xp_5000 | Олимпиец XP | Наберите 5000 XP | 20 | нет | да | - | - |
| xp_10000 | Легенда XP | Наберите 10000 XP | 10 | нет | да | - | - |
| games_20 | Исследователь | Сыграйте 20 игр | 10 | нет | нет | - | - |
| games_100 | Ветеран | Сыграйте 100 игр | 20 | нет | нет | - | - |
| acc_70 | Меткий стрелок | Точность 70% | 10 | нет | нет | - | - |
| acc_85 | Снайпер | Точность 85% | 20 | нет | нет | - | - |
| league_silver | Серебряная лига | Достигните Серебра | 10 | нет | нет | - | - |
| league_gold | Золотая лига | Достигните Золота | 20 | нет | нет | - | - |
| league_platinum | Платиновая лига | Достигните Платины | 30 | нет | нет | - | - |
| league_diamond | Алмазная лига | Достигните Алмаза | 40 | нет | нет | - | - |
| league_master | Мастер лиг | Достигните Мастера | 50 | нет | нет | - | - |
| friends_1 | Первый друг | Добавьте друга | 10 | нет | нет | - | - |
| friends_5 | Своя команда | Добавьте 5 друзей | 20 | нет | да | - | - |
| share_1 | Расскажите друзьям | Поделитесь профилем | 10 | нет | да | - | - |
| games_10_day | Спринтер | Сыграйте 10 игр за день | 10 | нет | да | - | - |
| xp_30000 | Мастер Олимпиец XP | Наберите 30000 XP | 30 | нет | да | - | - |

## Titles (локализованные)
| Achievement ID | en | ru | uk | es | ca | zh | de | fr | it | pt-BR | pl | nl |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| streak_5 | Early Bird | Ранняя птица | Рання пташка | Madrugador | Ocella matiner | 早起的鸟儿 | Frühaufsteher | Lève-tôt | Mattiniero | Madrugador | Wczesny ptak | Vroege vogel |
| streak_10 | Consistency | Стабильность | Стабільність | Constancia | Constància | 持之以恒 | Konsistenz | Cohérence | Coerenza | Consistência | Konsystencja | Samenhang |
| streak_30 | Iron Will | Железная воля | Залізна воля | Voluntad de hierro | Voluntat de ferro | 钢铁意志 | Eiserner Wille | Volonté de fer | Volontà di ferro | Vontade de Ferro | Żelazna Wola | Ijzeren wil |
| xp_1000 | XP Beginner | Новичок XP | Новачок XP | Principiante XP | Principiant XP | XP新手 | XP-Anfänger | XP Débutant | Principiante XP | XP Iniciante | Początkujący XP | XP-beginner |
| xp_5000 | XP Olympian | Олимпиец XP | Олімпієць XP | Olimpico de XP | Olimpic XP | XP奥运 | XP-Olympiasieger | Olympien XP | XP olimpico | XP Olímpico | Olimpijczyk XP | XP Olympiër |
| xp_10000 | XP Legend | Легенда XP | Легенда XP | Leyenda de XP | Llegenda XP | XP传奇 | XP-Legende | Légende XP | Leggenda XP | Lenda XP | Legenda XP | XP-legende |
| games_20 | Quest Explorer | Исследователь | Дослідник | Explorador | Explorador | 探索者 | Quest-Explorer | Explorateur de quête | Esploratore di missioni | Explorador de Missões | Eksplorator Zadań | Zoektochtverkenner |
| games_100 | Veteran | Ветеран | Ветеран | Veterano | Veterà | 老将 | Veteran | Vétéran | Veterano | Veterano | Weteran | Veteraan |
| acc_70 | Sharpshooter | Меткий стрелок | Влучний стрілець | Tirador | Bon tirador | 神枪手 | Scharfschütze | Tireur d'élite | Tiratore scelto | Atirador de elite | Strzelec wyborowy | Scherpschutter |
| acc_85 | Sniper | Снайпер | Снайпер | Francotirador | Franctirador | 狙击手 | Scharfschütze | Tireur isolé | Cecchino | Atirador | Snajper | Sluipschutter |
| league_silver | Silver League | Серебряная лига | Срібна ліга | Liga de plata | Lliga de plata | 白银联赛 | Silberliga | Ligue d'argent | Lega d'Argento | Liga de Prata | Srebrna Liga | Zilveren Liga |
| league_gold | Gold League | Золотая лига | Золота ліга | Liga de oro | Lliga d'or | 黄金联赛 | Goldliga | Ligue d'Or | Lega d'Oro | Liga de Ouro | Złota Liga | Gouden Liga |
| league_platinum | Platinum League | Платиновая лига | Платинова ліга | Liga de platino | Lliga de platí | 铂金联赛 | Platin-Liga | Ligue Platine | Lega di platino | Liga Platina | Platynowa Liga | Platina Liga |
| league_diamond | Diamond League | Алмазная лига | Алмазна ліга | Liga de diamante | Lliga Diamant | 钻石联赛 | Diamantliga | Ligue de Diamant | Lega dei Diamanti | Liga Diamante | Diamentowa Liga | Diamant Liga |
| league_master | League Master | Мастер лиг | Майстер ліг | Maestro de liga | Mestre de la Lliga | 大师联赛 | Ligameister | Maître de la Ligue | Maestro della Lega | Mestre da Liga | Mistrz ligi | Liga Meester |
| friends_1 | First Friend | Первый друг | Перший друг | Primer amigo | Primer amic | 第一个好友 | Erster Freund | Premier ami | Primo amico | Primeiro amigo | Pierwszy Przyjaciel | Eerste vriend |
| friends_5 | Your Team | Своя команда | Власна команда | Tu equipo | El teu equip | 自己的队伍 | Ihr Team | Votre équipe | La tua squadra | Sua equipe | Twój zespół | Jouw team |
| share_1 | Spread the word | Расскажите друзьям | Розкажіть друзям | Comparte con amigos | Corre la veu | 告诉朋友们 | Verbreiten Sie es weiter | Faites passer le mot | Spargi la voce | Espalhe a palavra | Rozpowszechniaj informacje | Verspreid het woord |
| games_10_day | Speed Racer | Спринтер | Спринтер | Velocista | Esprintador | 冲刺者 | Speed-Racer | Coureur de vitesse | Corridore di velocità | Corredor de velocidade | Szybki wyścigowiec | Snelheidsracer |
| xp_30000 | Master XP Olympian | Мастер Олимпиец XP | Майстер Олімпієць XP | Maestro Olimpico XP | Mestre Olímpic XP | XP奥运大师 | Meister-XP-Olympiasieger | Maître Olympien XP | Maestro Olimpico XP | Mestre Olímpico XP | Mistrz Olimpijczyk XP | Meester XP Olympiër |

## Descriptions (достижение НЕ получено) (локализованные)
| Achievement ID | en | ru | uk | es | ca | zh | de | fr | it | pt-BR | pl | nl |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| streak_5 | Reach a 5-day streak | Достигните серии 5 дней | Досягніть серії 5 днів | Alcanza una racha de 5 días | Assoleix una ratxa de 5 dies | 达到5天连续 | Erreichen Sie eine 5-Tage-Strecke | Atteignez une séquence de 5 jours | Raggiungi una serie di 5 giorni | Alcance uma sequência de 5 dias | Osiągnij 5-dniową passę | Bereik een streak van 5 dagen |
| streak_10 | 10-day streak | Серия 10 дней | Серия 10 днів | Racha de 10 días | Ratxa de 10 dies | 10 天连续 | 10-Tage-Serie | séquence de 10 jours | Serie di 10 giorni | Sequência de 10 dias | Seria 10 dni | 10-daagse reeks |
| streak_30 | 30-day streak | Серия 30 дней | Серія 30 днів | Racha de 30 días | Ratxa de 30 dies | 30天连续 | 30-Tage-Serie | 30 jours consécutifs | Serie di 30 giorni | Sequência de 30 dias | Seria 30 dni | 30-dagenreeks |
| xp_1000 | Earn 1000 XP | Наберите 1000 XP | Наберіть 1000 XP | Consigue 1000 XP | Guanya 1000 XP | 获得1000 XP | Verdiene 1000 XP | Gagnez 1000 XP | Guadagna 1000 XP | Ganhe 1000 XP | Zdobądź 1000 PD | Verdien 1000 XP |
| xp_5000 | Earn 5000 XP | Наберите 5000 XP | Наберіть 5000 XP | Consigue 5000 XP | Guanya 5000 XP | 获得5000 XP | Verdiene 5000 XP | Gagnez 5 000 XP | Guadagna 5000 XP | Ganhe 5.000 XP | Zdobądź 5000 PD | Verdien 5000 XP |
| xp_10000 | Earn 10000 XP | Наберите 10000 XP | Наберіть 10000 XP | Consigue 10000 XP | Guanya 10000 XP | 获得10000 XP | Verdiene 10.000 XP | Gagnez 10 000 XP | Guadagna 10.000 XP | Ganhe 10.000 XP | Zdobądź 10000 PD | Verdien 10.000 XP |
| games_20 | Play 20 games | Сыграйте 20 игр | Зіграйте 20 ігор | Juega 20 partidas | Juga 20 partides | 进行20局游戏 | Spielen Sie 20 Spiele | Jouez à 20 jeux | Gioca 20 partite | Jogue 20 partidas | Zagraj w 20 gier | Speel 20 spellen |
| games_100 | Play 100 games | Сыграйте 100 игр | Зіграйте 100 ігор | Juega 100 partidas | Juga 100 partides | 进行100局游戏 | Spielen Sie 100 Spiele | Jouez à 100 jeux | Gioca a 100 giochi | Jogue 100 jogos | Graj 100 gier | Speel 100 spellen |
| acc_70 | Reach 70% accuracy | Точность 70% | Точність 70% | Precisión del 70% | Assoleix 70% de precisió | 达到70%准确率 | Erreichen Sie eine Genauigkeit von 70 % | Atteindre 70 % de précision | Raggiungi una precisione del 70%. | Alcance 70% de precisão | Osiągnij 70% dokładności | Bereik een nauwkeurigheid van 70% |
| acc_85 | Reach 85% accuracy | Точность 85% | Точність 85% | Precisión del 85% | Assoleix 85% de precisió | 达到85%准确率 | Erreichen Sie eine Genauigkeit von 85 % | Atteignez une précision de 85 % | Raggiungi l'85% di precisione | Alcance 85% de precisão | Osiągnij 85% dokładności | Bereik een nauwkeurigheid van 85% |
| league_silver | Reach Silver | Достигните Серебра | Досягніть Срібла | Alcanza la Plata | Assoleix la Plata | 达到白银 | Erreiche Silber | Atteignez l'Argent | Raggiungi l'Argento | Alcance a Prata | Osiągnij Srebro | Bereik Zilver |
| league_gold | Reach Gold | Достигните Золота | Досягніть Золота | Alcanza el Oro | Assoleix l'Or | 达到黄金 | Erreiche Gold | Atteignez l'Or | Raggiungi l'Oro | Alcance o Ouro | Osiągnij Złoto | Bereik Goud |
| league_platinum | Reach Platinum | Достигните Платины | Досягніть Платини | Alcanza el Platino | Assoleix el Platí | 达到铂金 | Erreiche Platin | Atteignez le Platine | Raggiungi il Platino | Alcance a Platina | Osiągnij Platynę | Bereik Platina |
| league_diamond | Reach Diamond | Достигните Алмаза | Досягніть Алмазу | Alcanza el Diamante | Assoleix el Diamant | 达到钻石 | Erreiche Diamant | Atteignez le Diamant | Raggiungi il Diamante | Alcance o Diamante | Osiągnij Diament | Bereik Diamant |
| league_master | Reach Master | Достигните Мастера | Досягніть Майстра | Alcanza el Maestro | Assoleix el Mestre | 达到大师 | Erreiche Meister | Atteignez le Maître | Raggiungi il Maestro | Alcance o Mestre | Osiągnij Mistrza | Bereik Meester |
| friends_1 | Add a friend | Добавьте друга | Додайте друга | Añade un amigo | Afegeix un amic | 添加一位好友 | Fügen Sie einen Freund hinzu | Ajouter un ami | Aggiungi un amico | Adicione um amigo | Dodaj znajomego | Voeg een vriend toe |
| friends_5 | Add 5 friends | Добавьте 5 друзей | Додайте 5 друзів | Añade 5 amigos | Afegeix 5 amics | 添加5位好友 | Füge 5 Freunde hinzu | Ajouter 5 amis | Aggiungi 5 amici | Adicione 5 amigos | Dodaj 5 znajomych | Voeg 5 vrienden toe |
| share_1 | Share your profile | Поделитесь профилем | Поділіться профілем | Comparte tu perfil | Comparteix el perfil | 分享个人资料 | Teilen Sie Ihr Profil | Partagez votre profil | Condividi il tuo profilo | Compartilhe seu perfil | Udostępnij swój profil | Deel uw profiel |
| games_10_day | Play 10 games in a day | Сыграйте 10 игр за день | Зіграйте 10 ігор за день | Juega 10 partidas en un día | Juga 10 partides en un dia | 一天内进行10局游戏 | Spielen Sie 10 Spiele an einem Tag | Jouez à 10 jeux par jour | Gioca 10 partite in un giorno | Jogue 10 partidas por dia | Graj 10 gier dziennie | Speel 10 spellen op een dag |
| xp_30000 | Earn 30000 XP | Наберите 30000 XP | Наберіть 30000 XP | Consigue 30000 XP | Guanya 30000 XP | 获得30000 XP | Verdiene 30.000 XP | Gagnez 30 000 XP | Guadagna 30000 XP | Ganhe 30.000 XP | Zdobądź 30000 PD | Verdien 30.000 XP |

## Descriptions (достижение получено) (локализованные)
Пример формата: `<Открыто> • <Title>` (коротко, обычно до ~120 символов).
| Achievement ID | en | ru | uk | es | ca | zh | de | fr | it | pt-BR | pl | nl |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| streak_5 | Unlocked • Early Bird | Открыто • Ранняя птица | Відкрито • Рання пташка | Desbloqueado • Madrugador | Desblocat • Ocella matiner | 已解锁 • 早起的鸟儿 | Entsperrt • Frühaufsteher | Débloqué • Lève-tôt | Sbloccato • Mattiniero | Desbloqueado • Madrugador | Odblokowany • Wczesny ptak | Ontgrendeld • Vroege vogel |
| streak_10 | Unlocked • Consistency | Открыто • Стабильность | Відкрито • Стабільність | Desbloqueado • Constancia | Desblocat • Constància | 已解锁 • 持之以恒 | Entsperrt • Konsistenz | Débloqué • Cohérence | Sbloccato • Coerenza | Desbloqueado • Consistência | Odblokowany • Konsystencja | Ontgrendeld • Samenhang |
| streak_30 | Unlocked • Iron Will | Открыто • Железная воля | Відкрито • Залізна воля | Desbloqueado • Voluntad de hierro | Desblocat • Voluntat de ferro | 已解锁 • 钢铁意志 | Entsperrt • Eiserner Wille | Débloqué • Volonté de fer | Sbloccato • Volontà di ferro | Desbloqueado • Vontade de Ferro | Odblokowany • Żelazna Wola | Ontgrendeld • Ijzeren wil |
| xp_1000 | Unlocked • XP Beginner | Открыто • Новичок XP | Відкрито • Новачок XP | Desbloqueado • Principiante XP | Desblocat • Principiant XP | 已解锁 • XP新手 | Entsperrt • XP-Anfänger | Débloqué • XP Débutant | Sbloccato • Principiante XP | Desbloqueado • XP Iniciante | Odblokowany • Początkujący XP | Ontgrendeld • XP-beginner |
| xp_5000 | Unlocked • XP Olympian | Открыто • Олимпиец XP | Відкрито • Олімпієць XP | Desbloqueado • Olimpico de XP | Desblocat • Olimpic XP | 已解锁 • XP奥运 | Entsperrt • XP-Olympiasieger | Débloqué • Olympien XP | Sbloccato • XP olimpico | Desbloqueado • XP Olímpico | Odblokowany • Olimpijczyk XP | Ontgrendeld • XP Olympiër |
| xp_10000 | Unlocked • XP Legend | Открыто • Легенда XP | Відкрито • Легенда XP | Desbloqueado • Leyenda de XP | Desblocat • Llegenda XP | 已解锁 • XP传奇 | Entsperrt • XP-Legende | Débloqué • Légende XP | Sbloccato • Leggenda XP | Desbloqueado • Lenda XP | Odblokowany • Legenda XP | Ontgrendeld • XP-legende |
| games_20 | Unlocked • Quest Explorer | Открыто • Исследователь | Відкрито • Дослідник | Desbloqueado • Explorador | Desblocat • Explorador | 已解锁 • 探索者 | Entsperrt • Quest-Explorer | Débloqué • Explorateur de quête | Sbloccato • Esploratore di missioni | Desbloqueado • Explorador de Missões | Odblokowany • Eksplorator Zadań | Ontgrendeld • Zoektochtverkenner |
| games_100 | Unlocked • Veteran | Открыто • Ветеран | Відкрито • Ветеран | Desbloqueado • Veterano | Desblocat • Veterà | 已解锁 • 老将 | Entsperrt • Veteran | Débloqué • Vétéran | Sbloccato • Veterano | Desbloqueado • Veterano | Odblokowany • Weteran | Ontgrendeld • Veteraan |
| acc_70 | Unlocked • Sharpshooter | Открыто • Меткий стрелок | Відкрито • Влучний стрілець | Desbloqueado • Tirador | Desblocat • Bon tirador | 已解锁 • 神枪手 | Entsperrt • Scharfschütze | Débloqué • Tireur d'élite | Sbloccato • Tiratore scelto | Desbloqueado • Atirador de elite | Odblokowany • Strzelec wyborowy | Ontgrendeld • Scherpschutter |
| acc_85 | Unlocked • Sniper | Открыто • Снайпер | Відкрито • Снайпер | Desbloqueado • Francotirador | Desblocat • Franctirador | 已解锁 • 狙击手 | Entsperrt • Scharfschütze | Débloqué • Tireur isolé | Sbloccato • Cecchino | Desbloqueado • Atirador | Odblokowany • Snajper | Ontgrendeld • Sluipschutter |
| league_silver | Unlocked • Silver League | Открыто • Серебряная лига | Відкрито • Срібна ліга | Desbloqueado • Liga de plata | Desblocat • Lliga de plata | 已解锁 • 白银联赛 | Entsperrt • Silberliga | Débloqué • Ligue d'argent | Sbloccato • Lega d'Argento | Desbloqueado • Liga de Prata | Odblokowany • Srebrna Liga | Ontgrendeld • Zilveren Liga |
| league_gold | Unlocked • Gold League | Открыто • Золотая лига | Відкрито • Золота ліга | Desbloqueado • Liga de oro | Desblocat • Lliga d'or | 已解锁 • 黄金联赛 | Entsperrt • Goldliga | Débloqué • Ligue d'Or | Sbloccato • Lega d'Oro | Desbloqueado • Liga de Ouro | Odblokowany • Złota Liga | Ontgrendeld • Gouden Liga |
| league_platinum | Unlocked • Platinum League | Открыто • Платиновая лига | Відкрито • Платинова ліга | Desbloqueado • Liga de platino | Desblocat • Lliga de platí | 已解锁 • 铂金联赛 | Entsperrt • Platin-Liga | Débloqué • Ligue Platine | Sbloccato • Lega di platino | Desbloqueado • Liga Platina | Odblokowany • Platynowa Liga | Ontgrendeld • Platina Liga |
| league_diamond | Unlocked • Diamond League | Открыто • Алмазная лига | Відкрито • Алмазна ліга | Desbloqueado • Liga de diamante | Desblocat • Lliga Diamant | 已解锁 • 钻石联赛 | Entsperrt • Diamantliga | Débloqué • Ligue de Diamant | Sbloccato • Lega dei Diamanti | Desbloqueado • Liga Diamante | Odblokowany • Diamentowa Liga | Ontgrendeld • Diamant Liga |
| league_master | Unlocked • League Master | Открыто • Мастер лиг | Відкрито • Майстер ліг | Desbloqueado • Maestro de liga | Desblocat • Mestre de la Lliga | 已解锁 • 大师联赛 | Entsperrt • Ligameister | Débloqué • Maître de la Ligue | Sbloccato • Maestro della Lega | Desbloqueado • Mestre da Liga | Odblokowany • Mistrz ligi | Ontgrendeld • Liga Meester |
| friends_1 | Unlocked • First Friend | Открыто • Первый друг | Відкрито • Перший друг | Desbloqueado • Primer amigo | Desblocat • Primer amic | 已解锁 • 第一个好友 | Entsperrt • Erster Freund | Débloqué • Premier ami | Sbloccato • Primo amico | Desbloqueado • Primeiro amigo | Odblokowany • Pierwszy Przyjaciel | Ontgrendeld • Eerste vriend |
| friends_5 | Unlocked • Your Team | Открыто • Своя команда | Відкрито • Власна команда | Desbloqueado • Tu equipo | Desblocat • El teu equip | 已解锁 • 自己的队伍 | Entsperrt • Ihr Team | Débloqué • Votre équipe | Sbloccato • La tua squadra | Desbloqueado • Sua equipe | Odblokowany • Twój zespół | Ontgrendeld • Jouw team |
| share_1 | Unlocked • Spread the word | Открыто • Расскажите друзьям | Відкрито • Розкажіть друзям | Desbloqueado • Comparte con amigos | Desblocat • Corre la veu | 已解锁 • 告诉朋友们 | Entsperrt • Verbreiten Sie es weiter | Débloqué • Faites passer le mot | Sbloccato • Spargi la voce | Desbloqueado • Espalhe a palavra | Odblokowany • Rozpowszechniaj informacje | Ontgrendeld • Verspreid het woord |
| games_10_day | Unlocked • Speed Racer | Открыто • Спринтер | Відкрито • Спринтер | Desbloqueado • Velocista | Desblocat • Esprintador | 已解锁 • 冲刺者 | Entsperrt • Speed-Racer | Débloqué • Coureur de vitesse | Sbloccato • Corridore di velocità | Desbloqueado • Corredor de velocidade | Odblokowany • Szybki wyścigowiec | Ontgrendeld • Snelheidsracer |
| xp_30000 | Unlocked • Master XP Olympian | Открыто • Мастер Олимпиец XP | Відкрито • Майстер Олімпієць XP | Desbloqueado • Maestro Olimpico XP | Desblocat • Mestre Olímpic XP | 已解锁 • XP奥运大师 | Entsperrt • Meister-XP-Olympiasieger | Débloqué • Maître Olympien XP | Sbloccato • Maestro Olimpico XP | Desbloqueado • Mestre Olímpico XP | Odblokowany • Mistrz Olimpijczyk XP | Ontgrendeld • Meester XP Olympiër |

