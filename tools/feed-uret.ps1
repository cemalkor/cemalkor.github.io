# cemalkor.com.tr — RSS besleme, site haritasi ve okuma suresi ureticisi
#
# Girdi : posts/posts.json  +  posts/*.md
# Cikti : feed.xml  feed.en.xml  sitemap.xml  posts/okuma.json
#
# Yeni yazi ekledikten sonra bir kez calistir; elle XML duzenlemek gerekmez.
#   .\tools\feed-uret.ps1 .
#
# Deterministik: icerik degismediyse birebir ayni dosyalari uretir, git status bos kalir.

param(
  [string]$Kok = ".",
  # ana sayfanin sitemap'teki lastmod degeri. Verilmezse mevcut sitemap.xml'den korunur
  # (yazi eklemek ana sayfayi degistirmez; site metnini elden gecirdiginde bunu ver).
  [string]$AnaSayfaTarih
)

$ErrorActionPreference = "Stop"

# DIKKAT: bu dosya UTF-8 BOM ILE kaydedilmeli. Windows PowerShell 5.1, BOM'suz bir script'i
# ANSI sanip Turkce karakterleri bozuyor ("Kör" -> "KÃ¶r") ve bu metinler dogrudan RSS okuyucuda
# gorunuyor. Duzenleyip kaydederken BOM'u koru.
$SITE    = "https://cemalkor.com.tr"
$BASLIK  = "Cemal Kör — Blog"
$ACIKLA  = @{
  tr = "Gömülü sistemler, akıllı sayaçlar ve sahada öğrendiklerim üzerine yazılar."
  en = "Posts on embedded systems, smart meters and lessons learned in the field."
}

$kokTam   = (Resolve-Path $Kok).Path
$postsDir = Join-Path $kokTam "posts"
$jsonYol  = Join-Path $postsDir "posts.json"
if (-not (Test-Path $jsonYol)) { throw "posts.json bulunamadi: $jsonYol" }

# BOM'suz UTF-8: uretilen dosyalar her calistirmada birebir ayni olsun
$utf8 = New-Object System.Text.UTF8Encoding $false
$inv  = [System.Globalization.CultureInfo]::InvariantCulture

function Yaz($yol, $metin) {
  [System.IO.File]::WriteAllText($yol, $metin, $utf8)
  Write-Host "  yazildi: $(Split-Path $yol -Leaf)"
}

# XML metin kacisi — & ilk sirada olmali, yoksa sonraki kacislari bozar
function Kacir($s) {
  if ($null -eq $s) { return "" }
  $s.Replace("&", "&amp;").Replace("<", "&lt;").Replace(">", "&gt;").Replace('"', "&quot;")
}

# Yazi adresi. Yazilar artik /blog/slug/ altinda gercek dosya (tools/yazi-sayfa-uret.ps1
# uretiyor); eski ?yazi=slug adresleri index.html tarafindan buraya tasiniyor.
# Sorgu parametresi kalmadigi icin XML kacisina da gerek yok.
function YaziUrl($slug, $dil) {
  if ($dil -eq "en") { return "$SITE/blog/$slug/en/" }
  return "$SITE/blog/$slug/"
}

# 2026-07-10 -> Fri, 10 Jul 2026 00:00:00 +0000
# InvariantCulture sart: makinenin dili Turkce oldugunda gun/ay adlari Turkce cikardi.
function Rfc822($tarih) {
  $d = [datetime]::ParseExact($tarih, "yyyy-MM-dd", $inv)
  $d.ToString("ddd, dd MMM yyyy 00:00:00 '+0000'", $inv)
}

# Markdown isaretlerini atip kelime sayar; kod bloklari da metne dahil (okumasi zaman aliyor)
function KelimeSay($md) {
  $t = $md
  $t = [regex]::Replace($t, '(?s)```.*?```', ' ')          # kod bloklari
  $t = [regex]::Replace($t, '`[^`]*`', ' ')                # satir ici kod
  $t = [regex]::Replace($t, '!\[[^\]]*\]\([^)]*\)', ' ')   # resimler
  $t = [regex]::Replace($t, '\[([^\]]*)\]\([^)]*\)', '$1') # linkler -> metni kalsin
  $t = [regex]::Replace($t, '(?m)^[#>\-\*\+\s\|]+', ' ')   # baslik/liste/tablo isaretleri
  $t = [regex]::Replace($t, '[*_~#]', ' ')
  ($t -split '\s+' | Where-Object { $_ -match '\w' }).Count
}

# dakikaya cevir — dakikada 200 kelime, en az 1 dakika
function OkumaDk($md) {
  $k = KelimeSay $md
  [math]::Max(1, [math]::Ceiling($k / 200.0))
}

function MdOku($dosya) {
  if ([string]::IsNullOrWhiteSpace($dosya)) { return $null }
  $yol = Join-Path $postsDir $dosya
  if (-not (Test-Path $yol)) {
    Write-Warning "  markdown bulunamadi, atlandi: $dosya"
    return $null
  }
  Get-Content -Raw -Encoding UTF8 $yol
}

# ---------- yazilari oku ----------
# PS 5.1'de ConvertFrom-Json, JSON dizisini tek bir Object[] olarak dondurur ve @() bunu acmaz;
# elemanlara ayirmak icin boru hattindan gecirmek gerekiyor (tek yazi varken fark edilmiyor).
$ham = Get-Content -Raw -Encoding UTF8 $jsonYol
$yazilar = @((ConvertFrom-Json $ham) | ForEach-Object { $_ })
if ($yazilar.Count -eq 0) { throw "posts.json bos" }

# yeniden eskiye — hem RSS hem site haritasi bu sirayi bekliyor
$yazilar = @($yazilar | Sort-Object -Property date -Descending)

Write-Host "$($yazilar.Count) yazi bulundu."

# ---------- okuma sureleri: posts/okuma.json ----------
# posts.json elle duzenlenen dosya, ona dokunmuyoruz; okuma sureleri ayri ve uretilen dosyada.
$okumaSatir = @()
foreach ($y in $yazilar) {
  $trMd = MdOku $y.file
  $enMd = MdOku $y.file_en
  $tr = if ($trMd) { OkumaDk $trMd } else { 1 }
  $en = if ($enMd) { OkumaDk $enMd } else { $tr }   # EN dosyasi yoksa site TR icerigi gosteriyor
  $okumaSatir += '  "' + $y.slug + '": {"tr": ' + $tr + ', "en": ' + $en + '}'
}
$okumaJson = "{" + "`n" + ($okumaSatir -join ",`n") + "`n" + "}" + "`n"
Yaz (Join-Path $postsDir "okuma.json") $okumaJson

# ---------- RSS ----------
function FeedUret($dil) {
  $sb = New-Object System.Text.StringBuilder
  $kendi = if ($dil -eq "en") { "$SITE/feed.en.xml" } else { "$SITE/feed.xml" }
  $anaLink = if ($dil -eq "en") { "$SITE/en/" } else { "$SITE/" }
  $baslik = if ($dil -eq "en") { "$BASLIK (EN)" } else { $BASLIK }

  [void]$sb.Append("<?xml version=`"1.0`" encoding=`"UTF-8`"?>`n")
  [void]$sb.Append("<!-- Uretilen dosya - elle duzenleme. Kaynak: posts/posts.json + tools/feed-uret.ps1 -->`n")
  [void]$sb.Append("<rss version=`"2.0`" xmlns:atom=`"http://www.w3.org/2005/Atom`">`n")
  [void]$sb.Append("  <channel>`n")
  [void]$sb.Append("    <title>$(Kacir $baslik)</title>`n")
  [void]$sb.Append("    <link>$(Kacir $anaLink)</link>`n")
  [void]$sb.Append("    <description>$(Kacir $ACIKLA[$dil])</description>`n")
  [void]$sb.Append("    <language>$dil</language>`n")
  [void]$sb.Append("    <atom:link href=`"$kendi`" rel=`"self`" type=`"application/rss+xml`"/>`n")

  foreach ($y in $yazilar) {
    $b = if ($dil -eq "en" -and $y.title_en)   { $y.title_en }   else { $y.title }
    $o = if ($dil -eq "en" -and $y.summary_en) { $y.summary_en } else { $y.summary }
    $u = YaziUrl $y.slug $dil
    [void]$sb.Append("    <item>`n")
    [void]$sb.Append("      <title>$(Kacir $b)</title>`n")
    [void]$sb.Append("      <link>$u</link>`n")
    [void]$sb.Append("      <guid isPermaLink=`"true`">$u</guid>`n")
    [void]$sb.Append("      <pubDate>$(Rfc822 $y.date)</pubDate>`n")
    [void]$sb.Append("      <description>$(Kacir $o)</description>`n")
    foreach ($e in @($y.tags)) {
      if ($e) { [void]$sb.Append("      <category>$(Kacir $e)</category>`n") }
    }
    [void]$sb.Append("    </item>`n")
  }

  [void]$sb.Append("  </channel>`n")
  [void]$sb.Append("</rss>`n")
  $sb.ToString()
}

Yaz (Join-Path $kokTam "feed.xml")    (FeedUret "tr")
Yaz (Join-Path $kokTam "feed.en.xml") (FeedUret "en")

# ---------- sitemap.xml ----------
$sitemapYol = Join-Path $kokTam "sitemap.xml"

# ana sayfanin tarihi: parametre > mevcut sitemap'teki deger > en yeni yazi
if (-not $AnaSayfaTarih) {
  if (Test-Path $sitemapYol) {
    $eski = Get-Content -Raw -Encoding UTF8 $sitemapYol
    $m = [regex]::Match($eski, '<loc>https://cemalkor\.com\.tr/</loc>.*?<lastmod>(\d{4}-\d{2}-\d{2})</lastmod>', 'Singleline')
    if ($m.Success) { $AnaSayfaTarih = $m.Groups[1].Value }
  }
}
if (-not $AnaSayfaTarih) { $AnaSayfaTarih = $yazilar[0].date }

# her adres icin ayni hreflang uclusu yazilir (Google her iki surumde de tam liste bekliyor)
function Alternatifler($slug) {
  $tr = if ($slug) { YaziUrl $slug "tr" } else { "$SITE/" }
  $en = if ($slug) { YaziUrl $slug "en" } else { "$SITE/en/" }
  "    <xhtml:link rel=`"alternate`" hreflang=`"tr`" href=`"$tr`"/>`n" +
  "    <xhtml:link rel=`"alternate`" hreflang=`"en`" href=`"$en`"/>`n" +
  "    <xhtml:link rel=`"alternate`" hreflang=`"x-default`" href=`"$tr`"/>`n"
}

function Adres($loc, $slug, $tarih, $oncelik, $siklik) {
  $s = "  <url>`n    <loc>$loc</loc>`n" + (Alternatifler $slug) + "    <lastmod>$tarih</lastmod>`n"
  if ($siklik) { $s += "    <changefreq>$siklik</changefreq>`n" }
  $s + "    <priority>$oncelik</priority>`n  </url>`n"
}

$sm = New-Object System.Text.StringBuilder
[void]$sm.Append("<?xml version=`"1.0`" encoding=`"UTF-8`"?>`n")
[void]$sm.Append("<!-- Uretilen dosya - elle duzenleme. Yazi ekledikten sonra: .\tools\feed-uret.ps1 . -->`n")
[void]$sm.Append("<urlset xmlns=`"http://www.sitemaps.org/schemas/sitemap/0.9`"`n")
[void]$sm.Append("        xmlns:xhtml=`"http://www.w3.org/1999/xhtml`">`n`n")
[void]$sm.Append("  <!-- ana sayfa -->`n")
[void]$sm.Append((Adres "$SITE/"          "" $AnaSayfaTarih "1.0" "monthly"))
[void]$sm.Append((Adres "$SITE/en/"  "" $AnaSayfaTarih "0.9" "monthly"))
[void]$sm.Append("`n  <!-- blog yazilari -->`n")
foreach ($y in $yazilar) {
  [void]$sm.Append((Adres (YaziUrl $y.slug "tr") $y.slug $y.date "0.8" $null))
  [void]$sm.Append((Adres (YaziUrl $y.slug "en") $y.slug $y.date "0.7" $null))
}
[void]$sm.Append("`n</urlset>`n")

Yaz $sitemapYol $sm.ToString()

# ---------- statik sayfalar ----------
# okuma.json bu script'te uretildigi icin sayfa ureticileri en sonda cagriliyor.
& (Join-Path $PSScriptRoot "yazi-sayfa-uret.ps1") -Kok $kokTam
& (Join-Path $PSScriptRoot "en-sayfa-uret.ps1")   -Kok $kokTam

Write-Host "Bitti."
