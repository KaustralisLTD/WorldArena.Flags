#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Вставка ключей profile_crop_* / profile_upload_photo во все Localizable.strings после «Редактировать аватар»."""

import pathlib

RES = pathlib.Path(__file__).resolve().parent.parent / "Resources"

# (upload, title, subtitle, zoom_label, cancel, done)
T = {
    "de": (
        "Foto hochladen",
        "Foto anpassen",
        "Zum Zoomen kneifen · zum Verschieben ziehen",
        "Zoom",
        "Abbrechen",
        "Fertig",
    ),
    "es": (
        "Subir foto",
        "Ajustar foto",
        "Pellizca para ampliar · arrastra para mover",
        "Zoom",
        "Cancelar",
        "Hecho",
    ),
    "fr": (
        "Importer une photo",
        "Ajuster la photo",
        "Pincer pour zoomer · glisser pour déplacer",
        "Zoom",
        "Annuler",
        "OK",
    ),
    "it": (
        "Carica foto",
        "Regola foto",
        "Pizzica per ingrandire · trascina per spostare",
        "Zoom",
        "Annulla",
        "Fine",
    ),
    "nl": (
        "Foto uploaden",
        "Foto aanpassen",
        "Knijp om te zoomen · sleep om te verplaatsen",
        "Zoom",
        "Annuleren",
        "Gereed",
    ),
    "pl": (
        "Prześlij zdjęcie",
        "Dostosuj zdjęcie",
        "Uszczypnij, aby powiększyć · przeciągnij, aby przesunąć",
        "Powiększenie",
        "Anuluj",
        "Gotowe",
    ),
    "pt-BR": (
        "Enviar foto",
        "Ajustar foto",
        "Belisque para ampliar · arraste para mover",
        "Zoom",
        "Cancelar",
        "Concluído",
    ),
    "ro": (
        "Încarcă fotografia",
        "Ajustează fotografia",
        "Ciupiți pentru zoom · trageți pentru a muta",
        "Zoom",
        "Renunță",
        "Gata",
    ),
    "sv": (
        "Ladda upp foto",
        "Justera foto",
        "Nyp för att zooma · dra för att flytta",
        "Zoom",
        "Avbryt",
        "Klar",
    ),
    "tr": (
        "Fotoğraf yükle",
        "Fotoğrafı ayarla",
        "Yakınlaştırmak için sıkıştır · taşımak için sürükle",
        "Yakınlaştırma",
        "İptal",
        "Bitti",
    ),
    "id": (
        "Unggah foto",
        "Sesuaikan foto",
        "Cubit untuk memperbesar · seret untuk memindahkan",
        "Zoom",
        "Batal",
        "Selesai",
    ),
    "hi": (
        "फ़ोटो अपलोड करें",
        "फ़ोटो समायोजित करें",
        "ज़ूम के लिए पिंच करें · खींचकर स्थान बदलें",
        "ज़ूम",
        "रद्द करें",
        "पूर्ण",
    ),
    "bn": (
        "ছবি আপলোড করুন",
        "ছবি মিল করুন",
        "জুম করতে চিমটি করুন · সরাতে টানুন",
        "জুম",
        "বাতিল",
        "সম্পন্ন",
    ),
    "ar": (
        "رفع صورة",
        "ضبط الصورة",
        "قرص للتكبير · اسحب للتحريك",
        "تكبير",
        "إلغاء",
        "تم",
    ),
    "el": (
        "Μεταφόρτωση φωτογραφίας",
        "Προσαρμογή φωτογραφίας",
        "Τσίμπημα για ζουμ · σύρετε για μετακίνηση",
        "Εστίαση",
        "Ακύρωση",
        "Τέλος",
    ),
    "cs": (
        "Nahrát fotografii",
        "Upravit fotografii",
        "Štipnutím přiblížíte · tažením posunete",
        "Přiblížení",
        "Zrušit",
        "Hotovo",
    ),
    "hu": (
        "Fénykép feltöltése",
        "Fénykép módosítása",
        "Csípés a nagyításhoz · húzd a mozgatáshoz",
        "Nagyítás",
        "Mégse",
        "Kész",
    ),
    "vi": (
        "Tải ảnh lên",
        "Chỉnh ảnh",
        "Chụm để phóng to · kéo để di chuyển",
        "Thu phóng",
        "Hủy",
        "Xong",
    ),
    "ta": (
        "புகைப்படத்தைப் பதிவேற்று",
        "புகைப்படத்தைச் சரிசெய்",
        "பெரிதாக்க இழுக்கவும் · நகர்த இழுக்கவும்",
        "பெரிதாக்கம்",
        "ரத்துசெய்",
        "முடிந்தது",
    ),
    "te": (
        "ఫోటో అప్‌లోడ్ చేయండి",
        "ఫోటో సర్దుబాటు చేయండి",
        "జూమ్ కోసం పించ్ · కదలికకు లాగండి",
        "జూమ్",
        "రద్దు",
        "పూర్తయింది",
    ),
    "th": (
        "อัปโหลดรูป",
        "ปรับรูป",
        "หยิกเพื่อซูม · ลากเพื่อเลื่อน",
        "ซูม",
        "ยกเลิก",
        "เสร็จสิ้น",
    ),
    "ko": (
        "사진 업로드",
        "사진 조정",
        "손가락으로 오므려 확대 · 드래그해 이동",
        "확대",
        "취소",
        "완료",
    ),
    "ja": (
        "写真をアップロード",
        "写真を調整",
        "ピンチで拡大 · ドラッグで移動",
        "ズーム",
        "キャンセル",
        "完了",
    ),
    "zh": (
        "上传照片",
        "调整照片",
        "双指捏合缩放 · 拖动移动",
        "缩放",
        "取消",
        "完成",
    ),
    "zh-Hant": (
        "上傳照片",
        "調整照片",
        "雙指捏合縮放 · 拖曳移動",
        "縮放",
        "取消",
        "完成",
    ),
    "fil": (
        "Mag-upload ng larawan",
        "Ayusin ang larawan",
        "I-pinch para mag-zoom · i-drag para ilipat",
        "Zoom",
        "Kanselahin",
        "Tapos na",
    ),
    "ca": (
        "Penjar foto",
        "Ajustar la foto",
        "Pessiga per fer zoom · arrossega per moure",
        "Zoom",
        "Cancel·la",
        "Fet",
    ),
}

KEYS = [
    "profile_upload_photo",
    "profile_crop_photo_title",
    "profile_crop_photo_subtitle",
    "profile_crop_zoom_label",
    "profile_crop_cancel",
    "profile_crop_done",
]

MARKER = '"Редактировать аватар"'


def esc(s: str) -> str:
    return s.replace("\\", "\\\\").replace('"', '\\"')


def block_for(lang: str) -> str:
    vals = T[lang]
    lines = [f'"{k}" = "{esc(v)}";\n' for k, v in zip(KEYS, vals)]
    return "".join(lines)


def main() -> None:
    for folder in sorted(RES.glob("*.lproj")):
        lang = folder.name.replace(".lproj", "")
        path = folder / "Localizable.strings"
        if not path.is_file():
            continue
        if lang in ("en", "uk", "ru"):
            continue
        if lang not in T:
            print("SKIP no dict:", lang)
            continue
        text = path.read_text(encoding="utf-8")
        if "profile_upload_photo" in text:
            print("OK already:", lang)
            continue
        if MARKER not in text:
            print("FAIL marker:", path)
            continue
        needle = MARKER
        idx = text.find(needle)
        line_end = text.find("\n", idx)
        if line_end < 0:
            print("FAIL newline:", path)
            continue
        insert_at = line_end + 1
        new_text = text[:insert_at] + block_for(lang) + text[insert_at:]
        path.write_text(new_text, encoding="utf-8")
        print("PATCH:", lang)


if __name__ == "__main__":
    main()
