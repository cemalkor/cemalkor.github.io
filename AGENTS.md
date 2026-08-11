# AGENTS.md — bu depoda çalışan ajan için

Bu site **cemalkor.com.tr**; Cemal Kör'ün kişisel sitesi ve aynı zamanda özgeçmişi.
Site sadece Cemal ile Claude arasında geliştiriliyor; başka katkıcı yok. Bu dosya
sohbetler arasında kaybolmasın diye yazıldı — yeni bir sohbete başlarken **önce burayı oku**.

Konuşma dili Türkçe. Koddaki yorumlar da Türkçe ve açıklayıcı: *ne* yapıldığını değil
**neden** yapıldığını anlatıyorlar. Yeni yorum yazarken bu tonu koru.

---

## 1. Tek kaynak ve üretilen dosyalar

`index.html` tek kaynaktır. Aşağıdakiler **üretilen** dosyalardır, elle düzenlenmez:

| Üretilen | Kaynak | Üreten |
|---|---|---|
| `en/index.html` | `index.html` + `I18N` sözlüğü | `tools/en-sayfa-uret.ps1` |
| `blog/<slug>/index.html`, `blog/<slug>/en/index.html` | `posts/*.md` + `posts/posts.json` | `tools/yazi-sayfa-uret.ps1` |
| `feed.xml`, `feed.en.xml`, `sitemap.xml`, `posts/okuma.json` | `posts/posts.json` + `posts/*.md` | `tools/feed-uret.ps1` |
| `index.html` içindeki `<div id="blog-list">` bloğu | `posts/posts.json` | `tools/feed-uret.ps1` |

Hepsini tek komut zinciri üretir:

```bash
powershell -File .\tools\feed-uret.ps1 .
```

`feed-uret.ps1` sonunda diğer iki üreteci de çağırır, ayrıca çalıştırmak gerekmez.
Üreteçler **deterministiktir**: içerik değişmediyse birebir aynı dosyaları üretir ve
`git status` boş kalır. Çalıştırdıktan sonra beklenmedik bir diff görürsen bu bir hatadır,
görmezden gelme.

**En sık yapılan hata:** `en/index.html`'i elle düzenlemek. Değişiklik `index.html`'e
(gövde) ve `I18N` sözlüğüne (İngilizcesi) yapılır, sonra üreteç çalıştırılır.

## 2. İki dil

- TR kök adreste (`/`), EN `/en/` altında — ikisi de ayrı statik dosya, JS ile çeviri yok.
- Gövdedeki her çevrilebilir metin `data-i18n="anahtar"` taşır; İngilizcesi `index.html`
  içindeki `const I18N = {...}` sözlüğünde durur.
- **Yeni metin eklerken `data-i18n` vermeyi ve sözlüğe İngilizcesini yazmayı unutma.**
  Üreteç "N eleman I18N'de yok (Türkçe kaldı)" diye uyarır — bu sayı **0 olmalı**.
- Blog kartlarının başlık/özetleri `posts.json`'daki `title_en` / `summary_en` alanlarından
  gelir, I18N'den değil.

## 3. Sayfa aynı zamanda CV

"CV indir" düğmesi `window.print()` çağırıyor; ayrı bir CV dosyası **yok**. Yazdırma düzeni
`@media print` bloğunda ve özgeçmiş ayrıştırıcılarına (ATS) göre kurgulandı:

- Tek kolon. Çok kolonlu düzende ayrıştırıcı iki kolonu birbirine karıştırıyor.
- Bölüm başlıkları gerçek `<h2>` ve ATS'in tanıdığı adlarla ("Deneyim", "Eğitim",
  "Yetkinlikler"). Birbirine çok benzeyen iki başlığı yan yana koyma — ayrıştırıcı
  altındaki kayıtları tek bölüm sanabiliyor. (Bu yüzden "Eğitim" ile "Gönüllü Eğitimler"
  bilerek ayrı yerlerde duruyor.)
- Süs ve tekrar eden bilgi kâğıda gitmiyor (`nav`, terminal, devre yolu ayraçları,
  datasheet kartı, footer).
- Ekrana özel boşluk kuralları `@media screen` içine alınır ki kâğıdı bozmasın.

**Bölüm ekler, taşır veya silersen Ctrl+P çıktısını da kontrol et.**

## 4. Test kuralları — bunlar isteğe bağlı değil

Bir değişikliği "tamam" demeden önce tarayıcıda **gör**. Kullanıcıya "sen bir bak" deme.

Her görsel/davranışsal değişiklik için:

- [ ] **Masaüstü** (1280px) **ve mobil** (375px). Mobili atlama — menü dar ekranda satır
      sarıyor, kartlar tek kolona düşüyor, en çok orada bozuluyor.
- [ ] **Koyu ve açık tema** (nav'daki ☾/☀ düğmesi).
- [ ] **TR ve EN** sayfa.
- [ ] Konsolda hata var mı.
- [ ] Yerel sunucu: `.claude/launch.json` içindeki `site` yapılandırması (port 8123).

Ölçmen gereken bir şey varsa JS ile ölç, göz kararı verme (`getBoundingClientRect`,
`offsetHeight`). Ekran görüntüsü alırken sayfa yumuşak kaydırma (`scroll-behavior:smooth`)
yüzünden hâlâ hareket hâlinde olabilir — ölçmeden önce oturmasını bekle.

Tarayıcı panelinde iki tuzak var, ikisine de yakalandım:

- **Viewport'u yeniden boyutlandırdıktan sonra sayfayı yeniden yükle.** Yoksa `innerWidth`
  yeni değeri, düzen ise eskisini gösteriyor; ölçümler ve çıpa kaydırması saçmalıyor.
  Ölçümle ekran görüntüsü çelişiyorsa sebebi budur — sayfayı değil paneli suçla.
- **Sunucu içeriği önbelleğe alıyor.** Üreteci çalıştırdıktan sonra sayfa eski hâlini
  gösteriyorsa adrese `?v=<zaman>` ekleyip yeniden yükle.

## 5. Commit ve push

- **İstenmedikçe commit atma, istenmedikçe push etme.** Bir seferlik izin sonraki
  değişikliği kapsamaz; her seferinde sor.
- Dal: doğrudan `main`. Push GitHub Pages'e deploy demektir.
- Commit mesajı Türkçe ama **ASCII** (başlıkta ve gövdede Türkçe karakter yok) — depodaki
  geçmiş böyle. Gövdede *neden* yapıldığını anlat.
- Mesaj sonuna: `Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>`
- Üreteçleri çalıştırmayı unutma; yoksa üretilen dosyalar kaynakla tutarsız gider.

## 6. Ortam tuzakları

- **PowerShell 5.1**: `&&` ve `||` yok, `;` ve `if ($?)` kullan.
- `git commit -m @'...'@` here-string'i bu kabukta bozuluyor. Çok satırlı mesaj için
  mesajı bir dosyaya yaz ve `git commit -F <dosya>` kullan.
- **Kodlama**: `tools/*.ps1` dosyaları **UTF-8 BOM İLE** kaydedilmeli — BOM'suz script'i
  PowerShell 5.1 ANSI sanıp Türkçe karakterleri bozuyor ("Kör" → "KÃ¶r") ve bu metin
  doğrudan RSS/HTML çıktısına gidiyor. `index.html` ve üretilen HTML/XML ise **BOM'suz**.
  Bir script'i düzenledikten sonra BOM'un yerinde olduğunu doğrula.
- Depo CRLF ile checkout ediliyor, üreteçler LF yazıyor. `git status` üretilen dosyaları
  "değişmiş" gösterebilir ama `git diff` boşsa gerçek bir değişiklik yoktur.

## 7. Sitenin kendine has yerleri

- **Yapışkan nav**: bağlantıyla bölüme atlarken başlık menünün altında kalmasın diye
  `html { scroll-padding-top: var(--nav-h) }`. `--nav-h`'yi JS nav'ın ölçülen
  yüksekliğinden hesaplıyor, çünkü menü dar ekranda iki-üç satıra sarıyor. Sabit bir
  piksel değeri yazma.
- **Menüye yeni bağlantı eklemek bedava değil**: dokuz Türkçe etiket 1080px'lik menü
  şeridine ancak sığıyor (`.nav-links` boşluğu bu yüzden 22px değil 16px, ~37px pay kalıyor).
  Ekledikten sonra 1280px'te menünün tek satır kaldığını **ölçerek** doğrula.
- **"Eğitim" ile "Seminerler" ayrı şeyler**: `#egitim` aldığı öğrenim (okullar),
  `#seminerler` verdiği gönüllü seminerler. Menüde "Eğitim/Eğitimler" yan yana durunca
  kimse ayırt edemiyordu; adları bilerek birbirinden uzaklaştırıldı.
- **Devre yolu ayraçları** (`.sq-divider`) bölümler arasında yeşil/bakır (`.pulse` /
  `.pulse.cu`) sırayla gidiyor. Bölüm ekler veya kaldırırsan sırayı düzelt.
- **Deneyim → Eğitim** arasında bilerek ayraç yok; boşluk kayıt arası ölçekte tutuldu ki
  ikisi tek bir zaman çizelgesi gibi okunsun.
- **Blog listesi** `index.html`'e gömülü geliyor (JS çalıştırmayan botlar da görsün diye).
  Sayfadaki `renderList()` yalnızca etiket filtresinde devreye giriyor ve **birebir aynı
  biçimi** üretmeli — `tools/ortak.ps1` içindeki `BlogKartlariHtml` ile senkron kalmalı,
  yoksa sayfa yüklenince görünüm oynar.
- **Footer tek kaynaktan**: yazı sayfaları `<footer id="iletisim">` bloğunu `index.html`'den
  olduğu gibi alıyor (eskiden elle yazılmış, sadece bağlantılardan oluşan ayrı bir sürümü
  vardı). Footer'ı `index.html`'de düzenle, üreteci çalıştır; her sayfada aynı olur.
- **Terminal** (hero'daki `#term-in`) gerçek bir komut satırı; `about`, `help`, easter
  egg'ler var. Sitedeki bilgiyi değiştirirsen terminaldeki karşılığını da güncelle.
  Yeni bir egg komutu eklersen `EGG_KOMUTLARI` kümesine de yaz: dokunmatik cihazda o
  komutlarda sanal klavye indiriliyor, yoksa animasyonu ve sağ alttaki keşif rozetini
  klavye kapatıyor. Sıradan komutlarda klavye bilerek açık kalıyor.
- Sitede easter egg'ler var (konami, pil/uyku modu, keşif rozeti). Bilmeden kırma.

## 8. Yeni blog yazısı ekleme

1. `posts/<slug>.md` ve `posts/<slug>.en.md` yaz.
2. `posts/posts.json`'a bir kayıt ekle (`slug`, `file`, `file_en`, `title`, `title_en`,
   `date`, `tags`, `summary`, `summary_en`).
3. `.\tools\feed-uret.ps1 .` çalıştır — yazı sayfaları, feed, sitemap, okuma süreleri ve
   ana sayfadaki kart listesi kendiliğinden güncellenir.
4. Yayına aldıktan sonra `tools/indexnow-bildir.ps1` ile arama motorlarına haber verilebilir.
