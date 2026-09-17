#!/usr/bin/env python3
import os
from pathlib import Path
import sys

VERSION = sys.argv[1] if len(sys.argv) > 1 else "7.6"
_REPO_ROOT = Path(__file__).resolve().parent.parent
ROOT = Path(os.environ["FLAGS_WORLD_ROOT"]).expanduser().resolve() if os.environ.get("FLAGS_WORLD_ROOT") else _REPO_ROOT
META = ROOT / "fastlane" / "metadata"

def asc_locale(locale: str):
    mapping = {
        "ar": "ar-SA",
        "de": "de-DE",
        "es": "es-ES",
        "fr": "fr-FR",
        "nl": "nl-NL",
        "en": "en-US",
        "zh": "zh-Hans",
    }
    unsupported = {"bn", "fil", "ta", "te"}
    if locale in unsupported:
        return None
    return mapping.get(locale, locale)

PROMO = {
    "ar": "تعلّم أعلام العالم بطريقة ممتعة: +30 لغة، مواجهات مع الأصدقاء، سلاسل إنجازات وتقدّم واضح. درّب ذاكرتك يوميًا وتقدّم في التصنيف!",
    "bn": "গেমের ছন্দে বিশ্বের পতাকা শিখুন: ৩০+ ভাষা, বন্ধুদের সাথে ডুয়েল, স্ট্রিক ও অর্জন। প্রতিদিন মেমোরি ট্রেন করুন এবং র‌্যাঙ্কে এগিয়ে যান!",
    "ca": "Aprèn les banderes del món jugant: més de 30 idiomes, duels amb amics, ratxes i assoliments. Entrena la memòria cada dia i puja al rànquing!",
    "cs": "Učte se vlajky světa hrou: 30+ jazyků, duely s přáteli, série a úspěchy. Trénujte paměť každý den a stoupejte v žebříčku!",
    "de": "Lerne Weltflaggen spielerisch: 30+ Sprachen, Duelle mit Freunden, Serien und Erfolge. Trainiere täglich dein Gedächtnis und steige im Ranking auf!",
    "el": "Μάθε τις σημαίες του κόσμου παίζοντας: 30+ γλώσσες, μονομαχίες με φίλους, σερί και επιτεύγματα. Εξάσκησε τη μνήμη σου κάθε μέρα και ανέβα στην κατάταξη!",
    "en-US": "Learn world flags through play: 30+ languages, friend duels, streaks, and achievements. Train your memory daily and climb the leaderboard!",
    "es": "Aprende las banderas del mundo jugando: más de 30 idiomas, duelos con amigos, rachas y logros. Entrena tu memoria cada día y sube en el ranking.",
    "fil": "Matuto ng mga bandila ng mundo sa masayang laro: 30+ wika, duels kasama ang kaibigan, streaks at achievements. Sanayin ang memorya araw-araw at umangat sa ranking!",
    "fr": "Apprenez les drapeaux du monde en jouant : 30+ langues, duels entre amis, séries et succès. Entraînez votre mémoire chaque jour et grimpez au classement !",
    "hi": "दुनिया के झंडे खेल-खेल में सीखें: 30+ भाषाएं, दोस्तों के साथ ड्यूल, स्ट्रीक और अचीवमेंट्स। रोज़ याददाश्त ट्रेन करें और रैंकिंग में ऊपर बढ़ें!",
    "hu": "Tanuld a világ zászlóit játékosan: 30+ nyelv, párbajok barátokkal, sorozatok és achievementek. Fejleszd a memóriád naponta és lépj feljebb a ranglistán!",
    "id": "Pelajari bendera dunia sambil bermain: 30+ bahasa, duel dengan teman, streak, dan pencapaian. Latih memori setiap hari dan naik peringkat!",
    "it": "Impara le bandiere del mondo giocando: oltre 30 lingue, duelli con gli amici, serie e obiettivi. Allena la memoria ogni giorno e scala la classifica!",
    "ja": "ゲーム感覚で世界の国旗を学ぼう。30以上の言語、友だちとのデュエル、連続記録、実績に対応。毎日記憶力を鍛えてランキング上位へ！",
    "ko": "게임처럼 세계 국기를 배우세요: 30개+ 언어, 친구와의 듀얼, 연속 기록, 업적 지원. 매일 기억력을 훈련하고 랭킹을 올려보세요!",
    "nl": "Leer wereldvlaggen spelenderwijs: 30+ talen, duels met vrienden, streaks en achievements. Train dagelijks je geheugen en stijg in de ranking!",
    "pl": "Ucz się flag świata przez zabawę: 30+ języków, pojedynki ze znajomymi, serie i osiągnięcia. Trenuj pamięć codziennie i wspinaj się w rankingu!",
    "pt-BR": "Aprenda as bandeiras do mundo jogando: mais de 30 idiomas, duelos com amigos, sequências e conquistas. Treine a memória todos os dias e suba no ranking!",
    "ro": "Învață steagurile lumii jucând: peste 30 de limbi, dueluri cu prietenii, serii și realizări. Antrenează-ți memoria zilnic și urcă în clasament!",
    "ru": "Изучайте флаги мира в игре: 30+ языков, дуэли с друзьями, серии и достижения. Тренируйте память каждый день и поднимайтесь в рейтинге!",
    "sv": "Lär dig världens flaggor genom spel: 30+ språk, dueller med vänner, streaks och achievements. Träna minnet varje dag och klättra i rankingen!",
    "ta": "விளையாட்டு முறையில் உலகக் கொடிகளை கற்றுக்கொள்ளுங்கள்: 30+ மொழிகள், நண்பர்களுடன் டூயல்கள், தொடர்ச்சிகள் மற்றும் சாதனைகள். தினமும் நினைவாற்றலைப் பயிற்சி செய்து தரவரிசையில் உயருங்கள்!",
    "te": "ఆటలా ప్రపంచ దేశాల జెండాలను నేర్చుకోండి: 30+ భాషలు, స్నేహితులతో డ్యూయెల్స్, స్ట్రీక్స్ మరియు అచీవ్‌మెంట్స్. ప్రతి రోజు జ్ఞాపకశక్తిని మెరుగుపరచి ర్యాంకింగ్లో పైకి ఎగబాకండి!",
    "th": "เรียนรู้ธงประเทศทั่วโลกแบบสนุก: รองรับกว่า 30 ภาษา, ดวลกับเพื่อน, สะสมสตรีคและความสำเร็จ ฝึกความจำทุกวันและไต่อันดับให้สูงขึ้น!",
    "tr": "Dünya bayraklarını oyunla öğrenin: 30+ dil, arkadaşlarla düello, seri ve başarımlar. Hafızanızı her gün geliştirin ve sıralamada yükselin!",
    "uk": "Вивчайте прапори світу у форматі гри: 30+ мов, дуелі з друзями, серії та досягнення. Тренуйте пам’ять щодня й піднімайтесь у рейтингу!",
    "vi": "Học cờ các nước qua lối chơi thú vị: hơn 30 ngôn ngữ, đấu tay đôi với bạn bè, chuỗi thành tích và phần thưởng. Luyện trí nhớ mỗi ngày và thăng hạng!",
    "zh-Hans": "用游戏方式学习世界国旗：支持30+种语言、与好友对决、连胜与成就系统。每天训练记忆力，冲击排行榜！",
    "zh-Hant": "用遊戲方式學習世界國旗：支援30+種語言、與好友對決、連勝與成就系統。每天訓練記憶力，衝上排行榜！",
}

WHATS_NEW = {
    "ar": f"""الإصدار {VERSION}

حدّثنا شاشة F-Bucks: العنصر الرئيسي يعرض شعار العملة ورصيدك دون خلفية مستطيلة؛ حسّنا صياغة المكافأة اليومية والترجمة الأوكرانية.

عند نفاد المحاولات، تُغلق اللعبة والطبقة العائمة بشكل صحيح، وأصبح الانتقال إلى Premium أكثر وضوحًا — بما في ذلك على iPad.

على iOS يمكنك مشاركة نتيجة اللعب ببطاقة أغنى تتضمن لقطة شاشة ونصًا؛ حسّنا أيضًا تحميل بعض الأعلام النادرة وثبات التطبيق بشكل عام.""",
    "bn": f"""সংস্করণ {VERSION}

আমরা F-Bucks স্ক্রিন আপডেট করেছি: হিরো ব্লকে এখন মুদ্রার লোগো ও ব্যালেন্স আছে, আর কোনো আয়তাকার ব্যাকড্রপ নেই; দৈনিক বোনাসের টেক্সট ও ইউক্রেনীয় লোকালাইজেশন পরিষ্কার করা হয়েছে।

জীবন শেষ হলে গেম ও ওভারলে নির্ভরযোগ্যভাবে বন্ধ হয়, Premium-এ যাওয়া আরও স্পষ্ট — iPad-সহ।

iOS-এ আপনি স্ক্রিনশট ও টেক্সটসহ সমৃদ্ধ কার্ড দিয়ে ফলাফল শেয়ার করতে পারেন; বিরল কিছু পতাকা লোডিং ও সামগ্রিক স্থিতিশীলতাও উন্নত করা হয়েছে।""",
    "ca": f"""Versió {VERSION}

Hem actualitzat la pantalla F-Bucks: el bloc principal mostra el logotip de la moneda i el saldo sense un fons rectangular; hem aclarit els textos del bonus diari i la localització en ucraïnès.

Quan es gasteu les vides, el joc i la superposició es tanquen correctament i el pas a Premium és més previsible, també a l’iPad.

A iOS podeu compartir el resultat amb una targeta més completa amb captura de pantalla i text; també hem millorat la càrrega d’algunes banderes rares i l’estabilitat general.""",
    "cs": f"""Verze {VERSION}

Obnovili jsme obrazovku F-Bucks: hlavní blok ukazuje logo měny a zůstatek bez obdélníkového podkladu; upřesnili jsme texty denního bonusu a ukrajinštinu.

Když vám dojdou životy, hra a překrytí se spolehlivě zavřou a přechod k Premium je předvídatelnější — včetně iPadu.

Na iOS můžete sdílet výsledek bohatší kartou se snímkem obrazovky a textem; vylepšili jsme načítání některých vzácných vlajek a celkovou stabilitu.""",
    "de": f"""Version {VERSION}

Wir haben den F-Bucks-Bildschirm überarbeitet: Im Mittelpunkt stehen Logo der Währung und Kontostand ohne rechteckige Unterlage; Formulierungen zum Tagesbonus und die ukrainische Lokalisierung sind klarer.

Wenn die Leben aufgebraucht sind, schließen sich Spiel und Overlay zuverlässig, der Weg zu Premium ist vorhersehbarer — auch auf dem iPad.

Auf iOS können Sie Ihr Ergebnis mit einer reichhaltigeren Karte inkl. Screenshot und Text teilen; zudem haben wir das Laden seltener Flaggen und die allgemeine Stabilität verbessert.""",
    "el": f"""Έκδοση {VERSION}

Ανανεώσαμε την οθόνη F-Bucks: το κύριο στοιχείο δείχνει το λογότυπο του νομίσματος και το υπόλοιπό σας χωρίς ορθογώνιο φόντο· διευκρινίσαμε τα κείμενα της ημερήσιας ανταμοιβής και την ουκρανική τοπικοποίηση.

Όταν τελειώσουν οι ζωές, το παιχνίδι και το overlay κλείνουν σωστά και η μετάβαση στο Premium είναι πιο προβλέψιμη — συμπεριλαμβανομένου iPad.

Στο iOS μπορείτε να μοιραστείτε το αποτέλεσμα με πλουσιότερη κάρτα που περιλαμβάνει στιγμιότυπο και κείμενο· βελτιώσαμε επίσης τη φόρτωση σπάνιων σημαιών και τη γενική σταθερότητα.""",
    "en-US": f"""Version {VERSION}

1) We refreshed the F-Bucks screen: the hero shows the currency logo and your balance without a rectangular backdrop; daily bonus wording and Ukrainian localization are clearer.

2) When you run out of lives, the game and overlay close reliably, and moving on to Premium is more predictable—including on iPad.

3) On iOS you can share your game result with a richer card that includes a screenshot and text; we also improved loading for some rare flags and overall app stability.""",
    "es": f"""Versión {VERSION}

Renovamos la pantalla F-Bucks: el bloque principal muestra el logo de la moneda y tu saldo sin un fondo rectangular; afinamos los textos del bono diario y la localización al ucraniano.

Cuando se acaban las vidas, el juego y la superposición se cierran correctamente y el paso a Premium es más predecible, también en iPad.

En iOS puedes compartir tu resultado con una tarjeta más completa con captura y texto; además mejoramos la carga de algunas banderas raras y la estabilidad general.""",
    "fil": f"""Bersyon {VERSION}

Na-update namin ang F-Bucks screen: ang hero ay nagpapakita ng logo ng currency at balance nang walang rectangular backdrop; mas malinaw na ang daily bonus text at Ukrainian localization.

Kapag naubos ang lives, maaasahang nagsasara ang game at overlay, at mas predictable ang pagpunta sa Premium — kasama ang iPad.

Sa iOS maaari mong i-share ang resulta gamit ang mas mayamang card na may screenshot at text; pinahusay din namin ang pag-load ng ilang bihirang watawat at overall stability.""",
    "fr": f"""Version {VERSION}

Nous avons rafraîchi l’écran F-Bucks : l’élément principal affiche le logo de la devise et votre solde sans fond rectangulaire ; les libellés du bonus quotidien et la localisation ukrainienne sont plus clairs.

Quand il n’y a plus de vies, le jeu et la superposition se ferment correctement et le passage à Premium est plus prévisible — y compris sur iPad.

Sur iOS, partagez votre résultat avec une carte plus riche incluant une capture d’écran et du texte ; nous avons aussi amélioré le chargement de certains drapeaux rares et la stabilité globale.""",
    "hi": f"""संस्करण {VERSION}

हमने F-Bucks स्क्रीन को अपडेट किया: हीरो ब्लॉक में मुद्रा लोगो और बैलेंस बिना आयताकार पृष्ठभूमि के दिखता है; दैनिक बोनस के टेक्स्ट और यूक्रेनी स्थानीयकरण स्पष्ट किए गए।

जब जीवन समाप्त होते हैं, गेम और ओवरले भरोसेमंद रूप से बंद होते हैं और Premium पर जाना अधिक पूर्वानुमेय है — iPad सहित।

iOS पर आप स्क्रीनशॉट और टेक्स्ट के साथ समृद्ध कार्ड से परिणाम साझा कर सकते हैं; कुछ दुर्लभ झंडों के लोडिंग और कुल स्थिरता में भी सुधार किया गया।""",
    "hu": f"""{VERSION} verzió

Frissítettük az F-Bucks képernyőt: a fő blokk a pénznem logóját és egyenlegét mutatja téglalap alakú háttér nélkül; pontosítottuk a napi bónusz szövegeit és az ukrán lokalizációt.

Ha elfogynak az életek, a játék és az átfedés megbízhatóan bezáródik, a Premium felé vezető út kiszámíthatóbb — iPaden is.

iOS-en megoszthatod az eredményt képernyőképpel és szöveggel gazdagabb kártyával; javítottunk néhány ritka zászló betöltését és az általános stabilitást is.""",
    "id": f"""Versi {VERSION}

Kami memperbarui layar F-Bucks: blok utama menampilkan logo mata uang dan saldo tanpa latar persegi panjang; teks bonus harian dan lokalisasi Ukraina lebih jelas.

Saat nyawa habis, game dan overlay tertutup dengan andal, dan lanjut ke Premium lebih terduga — termasuk di iPad.

Di iOS Anda bisa membagikan hasil dengan kartu yang lebih kaya berisi tangkapan layar dan teks; kami juga memperbaiki pemuatan beberapa bendera langka dan stabilitas aplikasi secara keseluruhan.""",
    "it": f"""Versione {VERSION}

Abbiamo rinnovato la schermata F-Bucks: l’elemento principale mostra il logo della valuta e il saldo senza sfondo rettangolare; testi del bonus giornaliero e localizzazione ucraina più chiari.

Quando finiscono le vite, gioco e overlay si chiudono in modo affidabile e il passaggio a Premium è più prevedibile — anche su iPad.

Su iOS puoi condividere il risultato con una scheda più ricca con screenshot e testo; migliorato anche il caricamento di alcune bandiere rare e la stabilità generale.""",
    "ja": f"""バージョン {VERSION}

F-Bucks画面を刷新しました。メイン表示は通貨ロゴと残高を、長方形の下地なしで表示。デイリーボーナスの文言とウクライナ語ローカライズを明確にしました。

ライフが尽きたとき、ゲームとオーバーレイが確実に閉じ、Premiumへの移行がより予測しやすくなりました（iPadも含む）。

iOSではスクリーンショットとテキストを含むリッチなカードで結果を共有できます。一部のレアな国旗の読み込みと全体的な安定性も改善しました。""",
    "ko": f"""버전 {VERSION}

F-Bucks 화면을 새롭게 정비했습니다. 메인 영역에 사각 배경 없이 통화 로고와 잔액이 표시되고, 일일 보너스 문구와 우크라이나어 현지화가 더 명확해졌습니다.

생명이 끝나면 게임과 오버레이가 안정적으로 닫히고 Premium으로의 전환이 더 예측 가능해졌습니다(iPad 포함).

iOS에서는 스크린샷과 텍스트가 포함된 더 풍부한 카드로 결과를 공유할 수 있으며, 일부 희귀 국기 로딩과 전반적인 안정성도 개선했습니다.""",
    "nl": f"""Versie {VERSION}

We hebben het F-Bucks-scherm vernieuwd: het middelpunt toont het valutalogo en je saldo zonder rechthoekige achtergrond; teksten voor de dagelijkse bonus en de Oekraïense lokalisatie zijn duidelijker.

Als je levens op zijn, sluiten het spel en de overlay betrouwbaar en is de overstap naar Premium voorspelbaarder — ook op iPad.

Op iOS kun je je resultaat delen met een rijkere kaart met screenshot en tekst; we verbeterden ook het laden van sommige zeldzame vlaggen en de algemene stabiliteit.""",
    "pl": f"""Wersja {VERSION}

Odświeżyliśmy ekran F-Bucks: główny blok pokazuje logo waluty i saldo bez prostokątnego tła; doprecyzowaliśmy teksty dziennego bonusu i ukraińską lokalizację.

Gdy skończą się życia, gra i nakładka zamykają się niezawodnie, a przejście do Premium jest bardziej przewidywalne — także na iPadzie.

Na iOS możesz udostępnić wynik bogatszą kartą ze zrzutem ekranu i tekstem; poprawiliśmy też ładowanie niektórych rzadkich flag i ogólną stabilność.""",
    "pt-BR": f"""Versão {VERSION}

Renovamos a tela F-Bucks: o destaque mostra o logo da moeda e seu saldo sem fundo retangular; textos do bônus diário e a localização em ucraniano ficaram mais claros.

Quando as vidas acabam, o jogo e o overlay fecham de forma confiável e ir para o Premium ficou mais previsível — inclusive no iPad.

No iOS você pode compartilhar o resultado com um cartão mais rico com captura de tela e texto; também melhoramos o carregamento de algumas bandeiras raras e a estabilidade geral.""",
    "ro": f"""Versiunea {VERSION}

Am reîmprospătat ecranul F-Bucks: elementul principal arată sigla monedei și soldul fără fundal dreptunghiular; am clarificat textele bonusului zilnic și localizarea în ucraineană.

Când se termină viețile, jocul și overlay-ul se închid corect, iar trecerea la Premium este mai previzibilă — inclusiv pe iPad.

Pe iOS poți partaja rezultatul cu o carte mai bogată, cu captură de ecran și text; am îmbunătățit și încărcarea unor steaguri rare și stabilitatea generală.""",
    "ru": f"""Версия {VERSION}

1) Обновили экран F-Bucks: главный блок показывает логотип валюты и баланс без прямоугольной подложки; уточнили тексты ежедневного бонуса и украинскую локализацию.

2) Когда заканчиваются жизни, игра и оверлей закрываются корректно, переход к оформлению Premium стал предсказуемее — в том числе на iPad.

3) На iOS после партии можно поделиться результатом расширенной карточкой со снимком экрана и текстом; улучшена подгрузка отдельных флагов и общая стабильность приложения.""",
    "sv": f"""Version {VERSION}

Vi har uppdaterat F-Bucks-skärmen: hjälteblocket visar valutalogotyp och saldo utan rektangulär bakgrund; texterna för dagbonus och ukrainsk lokalisering är tydligare.

När liv tar slut stängs spelet och överlagret pålitligt och vägen till Premium blir mer förutsägbar — även på iPad.

På iOS kan du dela resultatet med ett rikare kort med skärmdump och text; vi har också förbättrat inläsning av vissa sällsynta flaggor och den allmänna stabiliteten.""",
    "ta": f"""பதிப்பு {VERSION}

F-Bucks திரையை புதுப்பித்தோம்: முக்கியப் பகுதி நாணய லோகோ மற்றும் இருப்புடன், செவ்வக பின்னணி இல்லாமல்; தினசரி போனஸ் உரைகள் மற்றும் உக்ரைனிய மொழிபெயர்ப்பு தெளிவாக்கப்பட்டது.

வாழ்க்கைகள் முடிந்ததும் விளையாட்டும் ஓவர்லேயும் நம்பகமாக மூடுகிறது, Premium-க்குச் செல்லுதல் முன்கணிக்கத்தக்கது — iPad உட்பட.

iOS-ல் ஸ்கிரீன்ஷாட் மற்றும் உரையுடன் வளமான அட்டையில் முடிவை பகிரலாம்; அரிய கொடிகளின் ஏற்றுதல் மற்றும் ஒட்டுமொத்த நிலைப்புத்தன்மையும் மேம்படுத்தப்பட்டது.""",
    "te": f"""వెర్షన్ {VERSION}

మేము F-Bucks స్క్రీన్‌ను రిఫ్రెష్ చేశాం: హీరో బ్లాక్ కరెన్సీ లోగో మరియు బ్యాలెన్స్‌ను దీర్ఘచతురస్రాకార బ్యాక్‌డ్రాప్ లేకుండా చూపుతుంది; రోజువారీ బోనస్ టెక్స్ట్ మరియు ఉక్రేనియన్ లోకలైజేషన్ స్పష్టమైంది.

లైఫ్‌లు అయిపోతే గేమ్ మరియు ఓవర్‌లే నమ్మకంగా మూసివేయబడతాయి, Premiumకు వెళ్లడం మరింత అంచనా వేయదగినది — iPadతో సహా.

iOSలో స్క్రీన్‌షాట్ మరియు టెక్స్ట్‌తో సమృద్ధ కార్డ్‌తో ఫలితాన్ని షేర్ చేయవచ్చు; అరుదైన కొన్ని జెండాల లోడింగ్ మరియు మొత్తం స్థిరత్వం కూడా మెరుగైంది.""",
    "th": f"""เวอร์ชัน {VERSION}

เราปรับหน้าจอ F-Bucks: ส่วนหลักแสดงโลโก้สกุลเงินและยอดคงเหลือโดยไม่มีพื้นหลังสี่เหลี่ยม; ข้อความโบนัสรายวันและภาษายูเครนชัดเจนขึ้น

เมื่อหมดชีวิต เกมและโอเวอร์เลย์จะปิดได้อย่างน่าเชื่อถือ และการไป Premium คาดการณ์ได้ง่ายขึ้น — รวมบน iPad

บน iOS แชร์ผลลัพธ์ด้วยการ์ดที่สมบูรณ์ขึ้นพร้อมภาพหน้าจอและข้อความ; ปรับปรุงการโหลดธงหายากบางอันและความเสถียรโดยรวม""",
    "tr": f"""Sürüm {VERSION}

F-Bucks ekranını yeniledik: ana bölüm para birimi logosunu ve bakiyenizi dikdörtgen bir arka plan olmadan gösteriyor; günlük bonus metinleri ve Ukraynaca yerelleştirme daha net.

Canlar bittiğinde oyun ve katman güvenilir şekilde kapanıyor, Premium’a geçiş daha öngörülebilir — iPad dahil.

iOS’ta ekran görüntüsü ve metin içeren daha zengin bir kartla sonucunuzu paylaşabilirsiniz; bazı nadir bayrakların yüklenmesini ve genel kararlılığı da iyileştirdik.""",
    "uk": f"""Версія {VERSION}

1) Оновили екран F-Bucks: головний блок показує логотип валюти та баланс без прямокутної підкладки; уточнили тексти щоденного бонусу та українську локалізацію.

2) Коли закінчуються життя, гра та оверлей коректно закриваються, перехід до оформлення Premium став передбачуванішим — зокрема на iPad.

3) На iOS після партії можна поділитися результатом розширеною карткою зі знімком екрана та текстом; покращено підвантаження окремих прапорів і загальну стабільність застосунку.""",
    "vi": f"""Phiên bản {VERSION}

Chúng tôi làm mới màn hình F-Bucks: khối chính hiển thị logo tiền tệ và số dư không nền hình chữ nhật; làm rõ nội dung thưởng hằng ngày và bản địa hóa tiếng Ukraina.

Khi hết mạng, trò chơi và lớp phủ đóng ổn định, chuyển sang Premium dễ đoán hơn — kể cả trên iPad.

Trên iOS bạn có thể chia sẻ kết quả bằng thẻ phong phú hơn kèm ảnh chụp màn hình và chữ; cải thiện tải một số lá cờ hiếm và độ ổn định chung.""",
    "zh-Hans": f"""版本 {VERSION}

我们更新了 F-Bucks 界面：主区域以货币标志和余额呈现，无矩形衬底；每日奖励文案与乌克兰语本地化更清晰。

生命用尽时，游戏与遮罩层会可靠关闭，前往 Premium 的流程更可预期（含 iPad）。

在 iOS 上可用包含截图与文字的更丰富卡片分享对局结果；并改进了部分稀有旗帜的加载与整体稳定性。""",
    "zh-Hant": f"""版本 {VERSION}

我們更新了 F-Bucks 畫面：主區塊顯示貨幣標誌與餘額，無矩形襯底；每日獎勵文案與烏克蘭語在地化更清晰。

生命用盡時，遊戲與覆蓋層會可靠關閉，前往 Premium 的流程更可預期（含 iPad）。

在 iOS 上可用包含截圖與文字的更豐富卡片分享對局結果；並改進了部分稀有旗幟的載入與整體穩定性。""",

}

for locale, promo in PROMO.items():
    target_locale = asc_locale(locale)
    if not target_locale:
        continue
    folder = META / target_locale
    folder.mkdir(parents=True, exist_ok=True)
    (folder / "promotional_text.txt").write_text(promo + "\n", encoding="utf-8")
    wn = WHATS_NEW.get(locale, WHATS_NEW["en-US"])
    (folder / "whats_new.txt").write_text(wn + "\n", encoding="utf-8")
    (folder / "release_notes.txt").write_text(wn + "\n", encoding="utf-8")

print(f"Translated metadata written to {META}")
