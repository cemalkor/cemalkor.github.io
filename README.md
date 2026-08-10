# Cemal Kör — Portfolyo Sitesi

🔗 **[cemalkor.com.tr](https://cemalkor.com.tr)** — GitHub Pages üzerinde, özel alan adıyla yayında.

Tek dosyalık (`index.html`), derleme ve sunucu gerektirmeyen, blog'u **Markdown dosyalarıyla** çalışan kişisel portfolyo sitesi.

> Bu depoda bir yapay zekâ ajanıyla çalışıyorsan: kuralları ve tuzakları [AGENTS.md](AGENTS.md) topluyor.

## Özellikler

- **İki dil (TR/EN)** — dil adresten okunur: kök adres TR, `?lang=en` EN. Nav'daki düğmeyle değiştirilir, tercih `localStorage`'da saklanır ve sonraki ziyarette adres ona göre düzeltilir
- **SEO** — her dil ve her blog yazısı kendi adresinde (aşağıdaki tabloya bak); canonical + hreflang, Open Graph/Twitter paylaşım kartı, JSON-LD yapısal veri (`Person`, `WebSite`, `ProfilePage`, yazılarda `BlogPosting`), `robots.txt`, `sitemap.xml`, özel `404.html`
- **Koyu / açık tema** — sistem tercihine uyar, nav'daki ☾/☀ düğmesiyle değiştirilir
- **Mobil uyumlu** — üst menü aşağı kaydırınca gizlenir, yukarı kaydırınca geri gelir
- **Yazdırılabilir CV (ATS uyumlu)** — hero'daki "CV indir" düğmesi `window.print()` çağırıyor; sayfa
  `@media print` ile özgeçmiş olarak diziliyor. **Ayrı bir CV dosyası yok** — CV siteyle birlikte
  güncelleniyor, ikisi ayrışmıyor. Özgeçmiş ayrıştırıcılarının (ATS) doğru okuyabilmesi için:
  - **tek kolon** (çok kolonlu düzende ayrıştırıcı iki kolonu birbirine karıştırır — CV'nin en sık bozulma sebebi)
  - etiket/beceri kutucukları düz virgüllü listeye dönüyor, ayraçlar yazdırma anında **gerçek metin** olarak
    ekleniyor (`beforeprint`), CSS `::after` sadece yedek
  - standart bölüm başlıkları: Özet, Deneyim, Projeler, Yetkinlikler, **Eğitim**, Gönüllü Eğitimler
  - süs (devre izi, terminal, zaman çizelgesi, kart çerçeveleri) ve tekrar eden bilgi (datasheet kartı,
    footer iletişim) kâğıda gitmiyor; koyu tema seçili olsa bile açık palet basılıyor
- **Markdown blog** — HTML'e dokunmadan yazı eklenir (aşağıda). Yazı listesinde okuma süresi ve tıklanabilir
  etiket filtresi, yazı altında önceki/sonraki geçişi, kod bloklarında kopyala düğmesi var
- **RSS** — `feed.xml` (TR) ve `feed.en.xml` (EN); `posts.json`'dan üretiliyor, head'den ve footer'dan keşfedilebiliyor
- **İnteraktif mini terminal** — hero'daki terminale komut yazılabiliyor; `help` ile başla
- **Easter egg'ler** 🪲 — sayfada gizli 10 easter egg var (F12 konsol mesajı hariç); buldukça sağ altta birkaç saniyeliğine `X/10` sayacı belirir, hepsini bulunca kutlama ekranı açılır (üzerinde "benimle başarını paylaş" tuşuyla). `help`'te görünmeyen terminal komutlarını, konami kodunu (mobilde de bir dokunma jesti var) ve footer'ı kurcala — sayaç her yenilemede sıfırlanır, gerisi sana kalmış. Egg sayılmayan keyif komutları (`credits`, `fortune`, `spock`, `panic`, `towel`) `help` çıktısında "keyfine" başlığı altında listeleniyor
- **404 sayfasında mini oyun** — "sinyali kilitle": tarama ibresi bandı süpürerken boşluk tuşu ya da dokunuşla kilitleniyor, her isabette bant daralıp tarama hızlanıyor. Rekor `localStorage`'da tutuluyor, metinler TR + altında EN

## Adres şeması

| Sayfa | Adres |
|---|---|
| Ana sayfa (TR) | `https://cemalkor.com.tr/` |
| Ana sayfa (EN) | `https://cemalkor.com.tr/en/` |
| Yazı (TR) | `https://cemalkor.com.tr/blog/merhaba-dunya/` |
| Yazı (EN) | `https://cemalkor.com.tr/blog/merhaba-dunya/en/` |

Yazılar `blog/` altında **kendi HTML dosyasında** — `tools/yazi-sayfa-uret.ps1` üretiyor. Kendi
`canonical`, `title`, açıklama ve JSON-LD etiketlerini taşıyorlar, içerik JS'siz de görünüyor.

Bu böyle olmak zorunda: site tek bir `index.html` ve içindeki `<link rel="canonical">` statik olarak
`/` diyor; yazı adresini yalnızca JS düzeltiyordu. Google JS'i render ettiği için sorun görünmüyordu ama
Bing sayfayı JS'siz tarayıp her `?yazi=` adresini ana sayfanın kopyası sayıyor ve dizine almıyordu
("Bu sayfa kurallı sayfanın alternatif sürümü olduğundan dizini oluşturulmadı").

Ana sayfanın İngilizcesi de aynı sebeple `en/index.html` olarak üretiliyor —
`tools/en-sayfa-uret.ps1` `index.html`'i alıp `data-i18n` taşıyan her elemanın içeriğini `I18N`
sözlüğündeki karşılığıyla değiştiriyor. Yani İngilizce CV artık JS'siz de görünüyor ve kendi
canonical'ı var. **İngilizce metni `I18N` sözlüğünde düzenle**, sonra üreteci çalıştır.

Dil değiştirme düğmesi artık yerinde çeviri değil, sayfa geçişi yapıyor (`/` ↔ `/en/`) — iki dil iki
ayrı dosya olduğu için içeriğin gelmesi gerçek sayfa yüklemesi istiyor.

Eski adresler kırılmıyor: `#yazi/slug`, `?yazi=slug` ve `?lang=en` açılışta yeni adrese taşınıyor.
GitHub Pages sunucu tarafında 301 veremediği için taşıma istemci tarafında (`location.replace`); hedef
sayfanın kendi canonical'ı doğru olduğundan arama motoru sonunda doğru adresi görüyor. `#hakkimda`,
`#blog` gibi bölüm çıpaları eskisi gibi çalışıyor.

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
├── sitemap.xml         → ÜRETİLEN: indekslenecek adresler
├── feed.xml            → ÜRETİLEN: RSS beslemesi (TR)
├── feed.en.xml         → ÜRETİLEN: RSS beslemesi (EN)
├── favicon.svg         → sekme ikonu (modern tarayıcılar bunu seçer)
├── favicon.ico         → yedek ikon (16/32/48), Google ve eski istemciler için
├── favicon-96x96.png   → yedek ikon (96x96)
├── apple-touch-icon.png→ iOS ana ekran ikonu (180x180)
├── og.png              → sosyal medya paylaşım kartı (1200x630)
├── googled09dd...html  → Google Search Console doğrulama dosyası (SİLME!)
├── yandex_892a...html  → Yandex Webmaster doğrulama dosyası (SİLME!)
├── 6d33c095....txt     → IndexNow anahtar dosyası (SİLME! içeriği anahtarın kendisi)
├── blog/               → ÜRETİLEN: yazı başına statik sayfa
│   └── <slug>/index.html      (TR)  ve  <slug>/en/index.html  (EN)
├── en/index.html       → ÜRETİLEN: İngilizce ana sayfa
├── tools/              → üretici script'ler (siteye dahil değil)
│   ├── og-kart-uret.ps1
│   ├── favicon-uret.ps1
│   ├── feed-uret.ps1   → feed.xml, feed.en.xml, sitemap.xml, posts/okuma.json
│   ├── ortak.ps1           → iki üreticinin paylaştığı yardımcılar (I18N, blok çıkarma)
│   ├── yazi-sayfa-uret.ps1 → blog/<slug>/ sayfaları (feed-uret.ps1 sonunda çağırıyor)
│   ├── en-sayfa-uret.ps1   → en/index.html          (feed-uret.ps1 sonunda çağırıyor)
│   └── indexnow-bildir.ps1 → Bing/Yandex'e "adres değişti" bildirimi (elle çalıştırılır)
└── posts/
    ├── posts.json      → yazı listesi (başlık, tarih, dosya adı) — ELLE yazılır
    ├── okuma.json      → ÜRETİLEN: yazı başına okuma süresi (dakika)
    ├── gorseller/      → yazılarda kullanılan fotoğraflar
    ├── merhaba-dunya.md
    └── merhaba-dunya.en.md
```

Yazıların ham hâli (düzenlenmemiş metin, işlenmemiş fotoğraf) `Blog hazırlık dosyaları/` altında tutuluyor;
`.gitignore` ile repoya girmiyor.

**ÜRETİLEN** işaretli dosyaları elle düzenleme — `tools/feed-uret.ps1` her çalıştığında üzerlerine yazıyor.

## Üretilen dosyalar

### Besleme ve site haritası

```powershell
.\tools\feed-uret.ps1 .
```

Tek komut hepsini üretir: `feed.xml`, `feed.en.xml`, `sitemap.xml`, `posts/okuma.json`,
`blog/<slug>/` sayfaları, `en/index.html` ve **ana sayfadaki yazı listesi**.
`feed-uret.ps1` son adımda `yazi-sayfa-uret.ps1` ile `en-sayfa-uret.ps1` çağırıyor, onları
ayrıca çalıştırmak gerekmez.

Ana sayfadaki yazı kartları (`index.html` içindeki `<div id="blog-list">` bloğu ve EN karşılığı)
JS ile değil, üretim anında HTML'e gömülüyor: JS çalıştırmayan tarayıcılar ve tarayıcı botları da
yazıları ana sayfadan görsün diye. Sayfadaki `renderList()` yalnızca etiket filtresinde devreye
giriyor ve aynı biçimi üretiyor — biri değişirse diğeri de değişmeli
(`tools/ortak.ps1` → `BlogKartlariHtml`).

**Site metnini `index.html` içinde değiştirdiysen de bu komutu çalıştır** — yoksa `en/index.html`
eski metinde kalır. Aynı şekilde tema/renk/menü değişikliğinden sonra da: yazı sayfaları
`index.html`'den **CSS'i, üst menüyü ve arka plandaki devre yollarını** olduğu gibi alıyor, tek
kaynak orası. Menü çıpaları yazı sayfasında ana sayfaya çevriliyor (`#projeler` → `/#projeler`).

⚠️ `index.html`'in CSS'inde veya JS'inde **yorum içine `<nav>` gibi düz etiket yazma** — üreteç
menüyü ve arka plan SVG'sini metin araması ile buluyor, yoruma takılıp yanlış yeri kesiyor. Bir kez
oldu, CSS'in yarısı yazı sayfasına metin olarak basıldı. Üreteçte buna karşı boyut kontrolü var ama
en iyisi yorumda etiket adını düz yazmamak.

`en-sayfa-uret.ps1` head'i çevirirken birebir eşleşme arıyor; `index.html`'in head'ini değiştirirsen
script sessizce bozuk sayfa üretmek yerine **hata verip durur**. Hata mesajı hangi satırın
eşleşmediğini söylüyor, script'teki karşılığını güncelle.

`posts.json`'dan bir yazıyı çıkarırsan üreteç `blog/<slug>/` klasörünü **silmez**, uyarı basar;
yayında kalmasın diye elle silmen gerekir.

### Arama motorlarına haber verme (IndexNow)

```powershell
.\tools\indexnow-bildir.ps1
```

Bing ve Yandex'e "şu adresler değişti" der; tarayıcının siteye kendiliğinden uğramasını beklemezsin.
**Push'ladıktan ve GitHub Pages dağıtımı bittikten sonra** çalıştır — script anahtar dosyasının
yayında olduğunu doğruluyor, olmazsa anlaşılır hata veriyor.

Argümansız çalışınca `sitemap.xml`'deki tüm adresleri bildirir. Tek adres için:
`.\tools\indexnow-bildir.ps1 -Adres "https://cemalkor.com.tr/blog/yeni-yazi/"`.
Google IndexNow kullanmıyor; orası için Search Console'dan sitemap yeniden gönderilir.

### Görselleri yeniden üretme

`og.png`, `apple-touch-icon.png`, `favicon.ico` ve `favicon-96x96.png` elle çizilmedi — `tools/`
altındaki PowerShell script'leri üretiyor. Renkler, yazılar ve devre izi motifi script'lerin içinde;
değiştirip tekrar çalıştırman yeterli. Windows'ta, ek kurulum gerektirmez (System.Drawing kullanıyor):

```powershell
.\tools\og-kart-uret.ps1 .
.\tools\favicon-uret.ps1 .
```

Script'ler deterministik: içeriği değiştirmezsen aynı dosyaları birebir üretir, `git status` boş kalır.
Bu `feed-uret.ps1` için de geçerli. `favicon.svg` elle yazılmış — ikon motifini değiştirirsen hem onu hem
`favicon-uret.ps1`'i güncelle, ikisi aynı çizimi paylaşıyor.

> **`tools/*.ps1` dosyalarını UTF-8 BOM ile kaydet.** Windows PowerShell 5.1 (Windows'ta varsayılan olan
> `powershell.exe`) BOM'suz bir script'i ANSI sanıyor ve içindeki Türkçe karakterleri bozuyor. BOM'suzken
> `og-kart-uret.ps1` paylaşım kartına "Cemal Kör" yerine "Cemal KÃ¶r" basıyordu. Editörün dosyayı
> "UTF-8 (BOM'suz)" olarak kaydediyorsa bu hata sessizce geri gelir — çalıştırdıktan sonra `git diff`'e bak.

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

4. **Üretici script'i çalıştır** — site haritasını, RSS beslemelerini ve okuma süresini günceller:

```powershell
.\tools\feed-uret.ps1 .
```

   Bu komut `sitemap.xml`, `feed.xml`, `feed.en.xml` ve `posts/okuma.json` dosyalarını `posts.json` ile
   markdown dosyalarından baştan üretiyor — elle XML yapıştırmak gerekmiyor. Çalıştırmayı unutursan yazı
   sitede yine görünür ama Google'a bildirilmez, RSS'e düşmez ve okuma süresi yazmaz.

5. Kaydet, push'la. Bitti — site yazıyı otomatik listeler ve render eder.

Site metnini (hakkımda, deneyim, projeler...) elden geçirdiysen ana sayfanın site haritasındaki tarihini de
bumplamak için: `.\tools\feed-uret.ps1 . -AnaSayfaTarih 2026-08-06`. Vermezsen mevcut değer korunuyor
(yazı eklemek ana sayfayı değiştirmediği için varsayılan bu).

Yazılar normal Markdown: başlıklar (`#`), listeler, tablolar, kod blokları (```` ```c ````), resimler hepsi destekleniyor. İngilizce dosya yoksa EN dilinde Türkçe içerik gösterilir.

**Görseller:** dosyayı `posts/gorseller/` altına koy ve markdown içinde **`posts/gorseller/ad.jpg`** diye
yaz — sadece `gorseller/ad.jpg` yazma. Yazı `?yazi=slug` adresinde, yani kök dizinde render ediliyor;
göreli adres markdown dosyasına değil sayfaya göre çözülüyor ve resim kırık çıkar.

## Bilgisayarda test etme

Blog, yazıları `fetch` ile yüklediği için dosyaya çift tıklayarak açınca (`file://`) blog kısmı çalışmaz. Test için klasörde:

```bash
python -m http.server
```

çalıştırıp tarayıcıda `http://localhost:8000` adresini aç.

## CV'yi değiştirmek

CV'nin içeriği sayfanın kendisi — bölümleri düzenlersen CV de değişir. Tek istisna, `index.html` içinde
`print-only` sınıfıyla işaretli, **yalnızca kâğıtta** görünen blok:

- **künye** (`.print-head`) — ad, unvan, iletişim satırı. Nav ve terminal kâğıda gitmediği için burada duruyor

**Eğitim bölümü** (`#egitim`) hem sitede hem CV'de görünür, Deneyim'in hemen altında duruyor
(Gazi Üniversitesi 2012—2022, Selçuklu Teknik Lise 2008—2012). ATS'ler diploma bilgisini kendi başlığı
altında aradığı için "Hakkımda" metnindeki cümleden ayrı bir bölüm olarak duruyor.

Yazdırma düzenini denemek için Ctrl+P yeter; tarayıcının önizlemesi son hâli gösteriyor.

## Özelleştirme

- Renkler ve yazı tipleri `index.html` en üstündeki `:root { ... }` bloğunda; koyu tema renkleri hemen altındaki `[data-theme="dark"] { ... }` bloğunda
- İngilizce çeviriler `index.html` içindeki `I18N` sözlüğünde
- Bölüm içerikleri (hakkımda, deneyim, projeler) düz HTML olarak aynı dosyada, Türkçe yorumlarla işaretli
