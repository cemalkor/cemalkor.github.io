# Cemal Kör — Portfolyo Sitesi

🔗 **[cemalkor.com.tr](https://cemalkor.com.tr)** — GitHub Pages üzerinde, özel alan adıyla yayında.

Tek dosyalık (`index.html`), derleme ve sunucu gerektirmeyen, blog'u **Markdown dosyalarıyla** çalışan kişisel portfolyo sitesi.

## Özellikler

- **İki dil (TR/EN)** — dil adresten okunur: kök adres TR, `?lang=en` EN. Nav'daki düğmeyle değiştirilir, tercih `localStorage`'da saklanır ve sonraki ziyarette adres ona göre düzeltilir
- **SEO** — her dil ve her blog yazısı kendi adresinde (aşağıdaki tabloya bak); canonical + hreflang, Open Graph/Twitter paylaşım kartı, JSON-LD yapısal veri (`Person`, `WebSite`, `ProfilePage`, yazılarda `BlogPosting`), `robots.txt`, `sitemap.xml`, özel `404.html`
- **Koyu / açık tema** — sistem tercihine uyar, nav'daki ☾/☀ düğmesiyle değiştirilir
- **Mobil uyumlu** — üst menü aşağı kaydırınca gizlenir, yukarı kaydırınca geri gelir
- **Markdown blog** — HTML'e dokunmadan yazı eklenir (aşağıda)
- **İnteraktif mini terminal** — hero'daki terminale komut yazılabiliyor; `help` ile başla
- **Easter egg'ler** 🪲 — sayfada gizli 7 easter egg var (F12 konsol mesajı hariç); buldukça sağ altta birkaç saniyeliğine `X/7` sayacı belirir, hepsini bulunca kutlama ekranı açılır (üzerinde "benimle başarını paylaş" tuşuyla). `help`'te görünmeyen terminal komutlarını, konami kodunu (mobilde de bir dokunma jesti var) ve footer'ı kurcala — sayaç her yenilemede sıfırlanır, gerisi sana kalmış

## Adres şeması

| Sayfa | Adres |
|---|---|
| Ana sayfa (TR) | `https://cemalkor.com.tr/` |
| Ana sayfa (EN) | `https://cemalkor.com.tr/?lang=en` |
| Yazı (TR) | `https://cemalkor.com.tr/?yazi=merhaba-dunya` |
| Yazı (EN) | `https://cemalkor.com.tr/?yazi=merhaba-dunya&lang=en` |

Linkler gerçek `<a href>` — arama motorları takip edebiliyor; tıklamayı JS yakalayıp sayfa yenilemeden
render ediyor (`history.pushState`). Eski `#yazi/slug` linkleri açılışta otomatik yeni adrese taşınıyor,
kırılmıyor. `#hakkimda`, `#blog` gibi bölüm çıpaları eskisi gibi çalışıyor.

**Not:** Dil artık tarayıcı diline göre otomatik seçilmiyor — kök adres herkes için Türkçe açılıyor.
Sebebi SEO: Googlebot'un tarayıcı dili `en-US` olduğu için otomatik seçim varken kök adres İngilizce
indeksleniyor, Türkçe sürüm aramaya hiç çıkmıyordu. İngilizce ziyaretçi nav'daki `EN` düğmesine bir kez
basıyor, tercihi saklanıyor.

## Klasör yapısı

```
cemalkor.github.io/
├── index.html          → sitenin tamamı (HTML + CSS + JS)
├── 404.html            → özel hata sayfası (site temasında)
├── CNAME               → özel alan adı (cemalkor.com.tr)
├── robots.txt          → tarayıcılara izin + sitemap adresi
├── sitemap.xml         → indekslenecek adresler (yazı eklerken güncellenir!)
├── favicon.svg         → sekme ikonu
├── apple-touch-icon.png→ iOS ana ekran ikonu (180x180)
├── og.png              → sosyal medya paylaşım kartı (1200x630)
└── posts/
    ├── posts.json      → yazı listesi (başlık, tarih, dosya adı)
    ├── merhaba-dunya.md
    └── merhaba-dunya.en.md
```

İkonların kaynak motifi `favicon.svg`'de (terminal prompt'u: yeşil `>` + bakır `_`); `og.png` de aynı
paletle çizilmiş 1200×630 bir karttan ibaret. Değiştirmek istersen ikisini de elden geçirmen yeterli.

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

4. **`sitemap.xml`'e yazının iki adresini ekle** — Google'ın yazıyı bulması için gerekli.
   `</urlset>` satırından hemen önce şu bloğu yapıştır, `SLUG` ve `TARİH` yerlerini doldur:

```xml
  <url>
    <loc>https://cemalkor.com.tr/?yazi=SLUG</loc>
    <xhtml:link rel="alternate" hreflang="tr" href="https://cemalkor.com.tr/?yazi=SLUG"/>
    <xhtml:link rel="alternate" hreflang="en" href="https://cemalkor.com.tr/?yazi=SLUG&amp;lang=en"/>
    <xhtml:link rel="alternate" hreflang="x-default" href="https://cemalkor.com.tr/?yazi=SLUG"/>
    <lastmod>TARİH</lastmod>
    <priority>0.8</priority>
  </url>
  <url>
    <loc>https://cemalkor.com.tr/?yazi=SLUG&amp;lang=en</loc>
    <xhtml:link rel="alternate" hreflang="tr" href="https://cemalkor.com.tr/?yazi=SLUG"/>
    <xhtml:link rel="alternate" hreflang="en" href="https://cemalkor.com.tr/?yazi=SLUG&amp;lang=en"/>
    <xhtml:link rel="alternate" hreflang="x-default" href="https://cemalkor.com.tr/?yazi=SLUG"/>
    <lastmod>TARİH</lastmod>
    <priority>0.7</priority>
  </url>
```

   (XML'de `&` yerine `&amp;` yazılmak zorunda — kopyalarken bozma. İngilizcesi yoksa ikinci bloğu atla.)

5. Kaydet, push'la. Bitti — site yazıyı otomatik listeler ve render eder.

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
