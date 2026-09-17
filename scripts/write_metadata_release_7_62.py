#!/usr/bin/env python3
"""Записывает release_notes.txt и whats_new.txt для релиза 7.62 (без promotional_text)."""
from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
META = ROOT / "fastlane" / "metadata"

# Тексты «Что нового» (одинаковое содержание в release_notes и whats_new)
WHATS_NEW: dict[str, str] = {
    "ar-SA": """الإصدار 7.62

1) إصلاح أخطاء وحالات جعلت السلوك أقل توقّعًا.
2) تحسينات بسيطة على الشاشات والواجهة لسهولة الاستخدام.
3) تحديث نصوص الواجهة بعدة لغات.
4) تحسين السلاسة وسرعة الاستجابة في أجزاء من التطبيق.""",
    "ca": """Versió 7.62

1) S'han corregit errors i casos amb comportament imprevisible.
2) S'han afinat pantalles i detalls de la interfície per facilitar-ne l'ús.
3) S'han actualitzat els textos de la interfície en diversos idiomes.
4) S'ha millorat la fluïdesa i la resposta en algunes zones de l'aplicació.""",
    "cs": """Verze 7.62

1) Opravy chyb a situací, kdy se aplikace chovala nepředvídatelně.
2) Doladění obrazovek a drobností rozhraní pro přehlednější používání.
3) Aktualizované texty rozhraní v různých jazycích.
4) Lepší plynulost a odezva v částech aplikace.""",
    "de-DE": """Version 7.62

1) Fehler und Randfälle behoben, in denen die App sich unvorhersehbar verhalten konnte.
2) Bildschirme und kleine UI-Details für klarere Nutzung überarbeitet.
3) Aktualisierte Oberflächentexte in mehreren Sprachen.
4) Verbesserte Flüssigkeit und Reaktionsgeschwindigkeit in Teilen der App.""",
    "el": """Έκδοση 7.62

1) Διορθώθηκαν σφάλματα και περιπτώσεις με απρόβλεπτη συμπεριφορά.
2) Βελτιώθηκαν οι οθόνες και λεπτομέρειες της διεπαφής για σαφέστερη χρήση.
3) Ενημερώθηκαν κείμενα διεπαφής σε διάφορες γλώσσες.
4) Καλύτερη ομαλότητα και χρόνος απόκρισης σε σημεία της εφαρμογής.""",
    "en-US": """Version 7.62

1) Fixed bugs and edge cases where behavior could be unpredictable.
2) Refined screens and small UI details for clearer use.
3) Updated interface strings across languages.
4) Improved smoothness and responsiveness in parts of the app.""",
    "es-ES": """Versión 7.62

1) Corregidos errores y situaciones con comportamiento impredecible.
2) Ajustes en pantallas y detalles de la interfaz para un uso más claro.
3) Textos de interfaz actualizados en varios idiomas.
4) Mayor fluidez y tiempo de respuesta en distintas partes de la app.""",
    "fr-FR": """Version 7.62

1) Correction de bugs et de cas où l’app pouvait se comporter de façon imprévisible.
2) Ajustements d’écrans et de petits détails d’interface pour plus de clarté.
3) Textes d’interface mis à jour dans plusieurs langues.
4) Fluidité et réactivité améliorées à certains endroits de l’application.""",
    "hi": """संस्करण 7.62

1) ऐसी त्रुटियाँ और स्थितियाँ ठीक की गईं जिनमें व्यवहार अनपेक्षित हो सकता था।
2) स्पष्ट उपयोग के लिए स्क्रीन और इंटरफ़ेस की छोटी बारीकियाँ संवारी गईं।
3) विभिन्न भाषाओं में इंटरफ़ेस पाठ अद्यतन किए गए।
4) ऐप के कुछ हिस्सों में चिकनापन और प्रतिक्रिया समय बेहतर किया गया।""",
    "hu": """7.62-es verzió

1) Javítottuk a hibákat és az előre nem látható viselkedésű eseteket.
2) Finomhangoltuk a képernyőket és a felület apró részleteit az átláthatóbb használatért.
3) Frissítettük a felület szövegeit több nyelven.
4) Gördülékenyebb működés és gyorsabb visszajelzés az alkalmazás egyes részein.""",
    "id": """Versi 7.62

1) Memperbaiki bug dan skenario dengan perilaku yang tidak menentu.
2) Menyesuaikan layar dan detail UI agar lebih jelas.
3) Memperbarui teks antarmuka di berbagai bahasa.
4) Kelancaran dan respons lebih baik di beberapa bagian aplikasi.""",
    "it": """Versione 7.62

1) Correzioni di bug e casi con comportamento imprevisto.
2) Migliorie a schermate e dettagli dell’interfaccia per un uso più chiaro.
3) Testi dell’interfaccia aggiornati in più lingue.
4) Fluidità e reattività migliorate in alcune parti dell’app.""",
    "ja": """バージョン 7.62

1) 挙動が不安定になり得る不具合やケースを修正しました。
2) 画面とUIの細部を調整し、より分かりやすくしました。
3) 各言語の画面上の文言を更新しました。
4) アプリの一部で滑らかさと応答性を改善しました。""",
    "ko": """버전 7.62

1) 예측하기 어려운 동작을 일으키던 오류와 상황을 수정했습니다.
2) 화면과 작은 UI 요소를 다듬어 사용하기 쉽게 만들었습니다.
3) 여러 언어의 인터페이스 문구를 최신화했습니다.
4) 앱 일부에서 부드러움과 반응 속도를 개선했습니다.""",
    "nl-NL": """Versie 7.62

1) Fouten en situaties waarin gedrag onvoorspelbaar kon zijn, opgelost.
2) Schermen en kleine interface-details verfijnd voor duidelijker gebruik.
3) Interface­teksten in meerdere talen bijgewerkt.
4) Vloeiender werking en snellere respons in delen van de app.""",
    "pl": """Wersja 7.62

1) Naprawiono błędy i sytuacje, w których zachowanie było nieprzewidywalne.
2) Dopracowano ekrany i drobne elementy interfejsu dla czytelniejszej obsługi.
3) Zaktualizowano teksty interfejsu w wielu językach.
4) Lepsza płynność i czas reakcji w częściach aplikacji.""",
    "pt-BR": """Versão 7.62

1) Corrigimos bugs e situações em que o comportamento podia ser imprevisível.
2) Ajustamos telas e pequenos detalhes da interface para uso mais claro.
3) Textos da interface atualizados em vários idiomas.
4) Mais fluidez e resposta em partes do app.""",
    "ro": """Versiunea 7.62

1) Corecții pentru erori și scenarii cu comportament imprevizibil.
2) Rafinări la ecrane și detalii UI pentru o utilizare mai clară.
3) Texte de interfață actualizate în mai multe limbi.
4) Funcționare mai fluidă și timp de răspuns mai bun în anumite zone ale aplicației.""",
    "ru": """Версия 7.62

1) Исправлены ошибки и сценарии, из‑за которых что‑то могло вести себя непредсказуемо.
2) Подправлены экраны и мелочи интерфейса для более понятного использования.
3) Актуализированы строки интерфейса на разных языках.
4) Улучшена плавность и время отклика в отдельных местах приложения.""",
    "sv": """Version 7.62

1) Vi har åtgärdat buggar och situationer där beteendet kunde bli oförutsägbart.
2) Finjusterade skärmar och små gränssnittsdetaljer för tydligare användning.
3) Uppdaterade gränssnittstexter på flera språk.
4) Bättre flyt och svarstid i delar av appen.""",
    "th": """เวอร์ชัน 7.62

1) แก้ข้อผิดพลาดและกรณีที่พฤติกรรมอาจคาดเดายาก
2) ปรับแต่งหน้าจอและรายละเอียด UI เล็กน้อยให้ใช้งานชัดเจนขึ้น
3) อัปเดตข้อความอินเทอร์เฟซในหลายภาษา
4) การทำงานลื่นไหลและตอบสนองเร็วขึ้นในบางส่วนของแอป""",
    "tr": """Sürüm 7.62

1) Davranışın öngörülemez olabildiği hatalar ve senaryolar giderildi.
2) Daha anlaşılır kullanım için ekranlar ve küçük arayüz ayrıntıları iyileştirildi.
3) Birden çok dilde arayüz metinleri güncellendi.
4) Uygulamanın bazı bölümlerinde akıcılık ve yanıt süresi iyileştirildi.""",
    "uk": """Версія 7.62

1) Виправлено помилки та сценарії з непередбачуваною поведінкою.
2) Підлаштовано екрани й дрібниці інтерфейсу для зрозумілішого користування.
3) Оновлено рядки інтерфейсу різними мовами.
4) Краща плавність і час відгуку в окремих місцях застосунку.""",
    "vi": """Phiên bản 7.62

1) Sửa lỗi và các trường hợp có thể khiến ứng dụng hoạt động khó đoán.
2) Tinh chỉnh màn hình và chi tiết giao diện để dễ dùng hơn.
3) Cập nhật chữ trên giao diện cho nhiều ngôn ngữ.
4) Mượt và phản hồi nhanh hơn ở một số phần trong app.""",
    "zh-Hans": """版本 7.62

1) 修复可能导致表现不稳定的错误与场景。
2) 优化界面与细节，让操作更清晰。
3) 更新多语言界面文案。
4) 提升部分场景的流畅度与响应速度。""",
    "zh-Hant": """版本 7.62

1) 修正可能導致行為不穩定的錯誤與情境。
2) 微調畫面與介面細節，使用更清楚。
3) 更新多語介面文字。
4) 提升部分區域的流暢度與回應速度。""",
}


def main() -> None:
    for loc, body in WHATS_NEW.items():
        d = META / loc
        if not d.is_dir():
            raise SystemExit(f"Missing metadata folder: {d}")
        text = body.strip() + "\n"
        for name in ("release_notes.txt", "whats_new.txt"):
            (d / name).write_text(text, encoding="utf-8")

    print("OK: wrote release_notes + whats_new for", len(WHATS_NEW), "locales (promotional_text not modified)")


if __name__ == "__main__":
    main()
