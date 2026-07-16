# Cemal Kör — Portfolyo Sitesi

🔗 **[cemalkor.com.tr](https://cemalkor.com.tr)** — GitHub Pages üzerinde, özel alan adıyla yayında.

Tek dosyalık (`index.html`), derleme ve sunucu gerektirmeyen, blog'u **Markdown dosyalarıyla** çalışan kişisel portfolyo sitesi.

## Özellikler

- **İki dil (TR/EN)** — cihaz dili Türkçe ise TR, değilse EN açılır; nav'daki düğmeyle değiştirilir, tercih `localStorage`'da saklanır
- **Koyu / açık tema** — sistem tercihine uyar, nav'daki ☾/☀ düğmesiyle değiştirilir
- **Mobil uyumlu** — üst menü aşağı kaydırınca gizlenir, yukarı kaydırınca geri gelir
- **Markdown blog** — HTML'e dokunmadan yazı eklenir (aşağıda)
- **İnteraktif mini terminal** — hero'daki terminale komut yazılabiliyor; `help` ile başla
- **Easter egg'ler** 🪲 — bazı komutlar `help` listesinde yok; footer'ın üzerine gel (mobilde dokun), gerisini kendin keşfet

## Klasör yapısı

```
cemalkor.github.io/
├── index.html          → sitenin tamamı (HTML + CSS + JS)
├── CNAME               → özel alan adı (cemalkor.com.tr)
└── posts/
    ├── posts.json      → yazı listesi (başlık, tarih, dosya adı)
    ├── merhaba-dunya.md
    └── merhaba-dunya.en.md
```

## Yeni blog yazısı nasıl eklenir? (HTML'e dokunmadan!)

1. `posts/` klasörüne yeni bir Markdown dosyası koy, örn. `ble-baglanti-sorunlari.md`
2. İngilizcesi de olacaksa `ble-baglanti-sorunlari.en.md` olarak yanına ekle
3. `posts/posts.json` dosyasına en üste şu bloğu ekle (`*_en` alanları isteğe bağlı):

```json
{
  "slug": "ble-baglanti-sorunlari",
  "file": "ble-baglanti-sorunlari.md",
  "file_en": "ble-baglanti-sorunlari.en.md",
  "title": "BLE Bağlantı Sorunları ve Çözümleri",
  "title_en": "BLE Connection Issues and Fixes",
  "date": "2026-08-01",
  "tags": ["BLE", "STM32"],
  "summary": "Sahada karşılaştığım BLE bağlantı kopmalarının kök nedenleri.",
  "summary_en": "Root causes of the BLE disconnects I ran into in the field."
}
```

4. Kaydet, push'la. Bitti — site yazıyı otomatik listeler ve render eder.

Yazılar normal Markdown: başlıklar (`#`), listeler, tablolar, kod blokları (```` ```c ````), resimler hepsi destekleniyor. İngilizce dosya yoksa EN dilinde Türkçe içerik gösterilir.

## Bilgisayarda test etme

Blog, yazıları `fetch` ile yüklediği için dosyaya çift tıklayarak açınca (`file://`) blog kısmı çalışmaz. Test için klasörde:

```bash
python -m http.server
```

çalıştırıp tarayıcıda `http://localhost:8000` adresini aç.

## Özelleştirme

- Renkler ve yazı tipleri `index.html` en üstündeki `:root { ... }` bloğunda; koyu tema renkleri hemen altındaki `[data-theme="dark"] { ... }` bloğunda
- İngilizce çeviriler `index.html` içindeki `I18N` sözlüğünde
- Bölüm içerikleri (hakkımda, deneyim, projeler) düz HTML olarak aynı dosyada, Türkçe yorumlarla işaretli
