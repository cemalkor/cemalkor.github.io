# Cemal Kör — Portfolyo Sitesi

Tek dosyalık (index.html), sunucu gerektirmeyen, blog'u **Markdown dosyalarıyla** çalışan kişisel portfolyo sitesi.

## Klasör yapısı

```
portfolio/
├── index.html          → sitenin tamamı (HTML + CSS + JS)
└── posts/
    ├── posts.json      → yazı listesi (başlık, tarih, dosya adı)
    └── merhaba-dunya.md
```

## Yeni blog yazısı nasıl eklenir? (HTML'e dokunmadan!)

1. `posts/` klasörüne yeni bir Markdown dosyası koy, örn. `ble-baglanti-sorunlari.md`
2. `posts/posts.json` dosyasına en üste şu bloğu ekle:

```json
{
  "slug": "ble-baglanti-sorunlari",
  "file": "ble-baglanti-sorunlari.md",
  "title": "BLE Bağlantı Sorunları ve Çözümleri",
  "date": "2026-08-01",
  "tags": ["BLE", "STM32"],
  "summary": "Sahada karşılaştığım BLE bağlantı kopmalarının kök nedenleri."
}
```

3. Kaydet, GitHub'a push'la. Bitti — site yazıyı otomatik listeler ve render eder.

Yazıları normal Markdown ile yazabilirsin: başlıklar (`#`), listeler, tablolar, kod blokları (```c ... ```), resimler hepsi destekleniyor.

## GitHub Pages ile ücretsiz yayınlama

1. GitHub'da `cemalkor.github.io` adında **public** bir repo oluştur
   (bu isimle oluşturursan adresin `https://cemalkor.github.io` olur)
2. Bu klasördeki dosyaları repo'ya yükle:

```bash
git init
git add .
git commit -m "Portfolyo sitesi"
git branch -M main
git remote add origin https://github.com/cemalkor/cemalkor.github.io.git
git push -u origin main
```

3. Repo → **Settings → Pages** → Source: `main` branch seç.
4. 1-2 dakika içinde siten `https://cemalkor.github.io` adresinde yayında.

> Not: İstersen daha sonra kendi alan adını (örn. `cemalkor.dev`) da Pages ayarlarından bağlayabilirsin.

## Bilgisayarında test etme

Blog, yazıları `fetch` ile yüklediği için dosyaya çift tıklayarak açınca (file://) blog kısmı çalışmaz. Test için klasörde:

```bash
python -m http.server
```

çalıştırıp tarayıcıda `http://localhost:8000` adresini aç.

## Özelleştirme

- Renkler ve yazı tipleri `index.html` içinde en üstteki `:root { ... }` bloğunda
- Bölüm içerikleri (hakkımda, deneyim, projeler) düz HTML olarak aynı dosyada, Türkçe yorumlarla işaretli
