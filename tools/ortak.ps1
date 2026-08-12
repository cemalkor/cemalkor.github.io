# cemalkor.com.tr — uretici script'lerin paylastigi yardimcilar
#
# Kendi basina bir sey yapmaz; dot-source edilir:
#   . (Join-Path $PSScriptRoot "ortak.ps1")
#
# Hem yazi-sayfa-uret.ps1 hem en-sayfa-uret.ps1 index.html'den ayni seyleri okuyor
# (I18N sozlugu, <style> blogu, <nav>, arka plan SVG'si). Iki yerde ayni ayristirici
# durmasin diye burada.
#
# DIKKAT: bu dosya UTF-8 BOM ILE kaydedilmeli (bkz. feed-uret.ps1 icindeki not).

# HTML metin kacisi — & ilk sirada olmali, yoksa sonraki kacislari bozar
function Kacir($s) {
  if ($null -eq $s) { return "" }
  $s.Replace("&", "&amp;").Replace("<", "&lt;").Replace(">", "&gt;").Replace('"', "&quot;")
}

# Yazinin etiketleri, dile gore. EN sayfada tags_en varsa o kullanilir, yoksa TR
# etiketlerine dusuyor. Kural title_en / summary_en ile ayni olsun diye tek yerde:
# eskiden her uretici dogrudan $y.tags okuyordu ve "Saha", "Genel" gibi Turkce etiketler
# Ingilizce sayfada, EN beslemede ve JSON-LD keywords'te oldugu gibi kaliyordu.
function Etiketler($y, $dil) {
  $e = if ($dil -eq "en" -and $y.tags_en) { $y.tags_en } else { $y.tags }
  @($e) | Where-Object { $_ }
}

# index.html'deki 'const I18N = { ... };' blogunu sozluge cevirir.
# Degerler HTML ve kesme isareti icerdigi icin regex yerine karakter karakter taranir;
# tirnak turu ve \ kacislari korunur.
function JsSozlukCoz($blok) {
  $sozluk = [ordered]@{}
  $i = 0
  $n = $blok.Length
  function SonrakiMetin([ref]$idx) {
    $b = $blok
    while ($idx.Value -lt $b.Length -and $b[$idx.Value] -notin @("'", '"')) { $idx.Value++ }
    if ($idx.Value -ge $b.Length) { return $null }
    $tirnak = $b[$idx.Value]
    $idx.Value++
    $sb = New-Object System.Text.StringBuilder
    while ($idx.Value -lt $b.Length) {
      $c = $b[$idx.Value]
      if ($c -eq '\') {
        $idx.Value++
        $k = $b[$idx.Value]
        switch ($k) {
          'n'  { [void]$sb.Append("`n") }
          't'  { [void]$sb.Append("`t") }
          'r'  { }
          default { [void]$sb.Append($k) }
        }
        $idx.Value++
        continue
      }
      if ($c -eq $tirnak) { $idx.Value++; break }
      [void]$sb.Append($c)
      $idx.Value++
    }
    return $sb.ToString()
  }
  while ($i -lt $n) {
    $anahtar = SonrakiMetin ([ref]$i)
    if ($null -eq $anahtar) { break }
    while ($i -lt $n -and $blok[$i] -ne ':') { $i++ }   # anahtar ile deger arasindaki ':'
    $i++
    $deger = SonrakiMetin ([ref]$i)
    if ($null -eq $deger) { break }
    $sozluk[$anahtar] = $deger
    while ($i -lt $n -and $blok[$i] -ne ',') { $i++ }
    $i++
  }
  $sozluk
}

function I18NOku($indexHtml) {
  $m = [regex]::Match($indexHtml, '(?s)const I18N = \{(.*?)\r?\n\};')
  if (-not $m.Success) { throw "index.html icinde 'const I18N = { ... };' blogu bulunamadi" }
  $s = JsSozlukCoz $m.Groups[1].Value
  if ($s.Count -lt 50) { throw "I18N beklenenden az anahtar dondu ($($s.Count)) - bicim degismis olabilir" }
  $s
}

# [data-i18n] tasiyan elemanlarin ic HTML'ini sozlukteki karsiligiyla degistirir.
# Ayni etiketin ic ice gectigi bir data-i18n elemani yok (index.html'de kontrol edildi),
# bu yuzden ilk kapanis etiketine kadar olan kisim guvenle ic HTML sayilabiliyor.
# Metin uzunlugu degistigi icin sondan basa gidiliyor, indeksler kaymasin diye.
function I18NUygula($html, $sozluk) {
  $eslesmeler = @([regex]::Matches($html, '<(\w+)[^>]*\sdata-i18n="([^"]+)"[^>]*>'))
  [array]::Reverse($eslesmeler)
  $sonuc = $html
  $sayac = 0
  foreach ($m in $eslesmeler) {
    $etiket  = $m.Groups[1].Value
    $anahtar = $m.Groups[2].Value
    if (-not $sozluk.Contains($anahtar)) { continue }
    $icBas = $m.Index + $m.Length
    $icSon = $sonuc.IndexOf("</$etiket>", $icBas)
    if ($icSon -lt 0) { throw "kapanis etiketi bulunamadi: <$etiket data-i18n=`"$anahtar`">" }
    $sonuc = $sonuc.Substring(0, $icBas) + $sozluk[$anahtar] + $sonuc.Substring($icSon)
    $sayac++
  }
  @{ html = $sonuc; sayac = $sayac; toplam = $eslesmeler.Count }
}

# ---------- ana sayfadaki blog listesi ----------
# Liste JS ile basiliyordu, yani sunucudan gelen HTML'de <div id="blog-list"> bombostu:
# JS calistirmayan tarayicilar ve tarayici botlari ana sayfadan yazilara ulasamiyordu
# (sitemap ve RSS keşfi cozuyordu ama ana sayfadaki ic bag yoktu). Kartlar artik uretim
# aninda gomuluyor; JS yalnizca etiket filtresi icin yeniden basiyor.
#
# DIKKAT: uretilen bicim index.html icindeki renderList() ile birebir ayni olmali. Ayni
# degilse sayfa yuklendiginde JS kartlari kendi surumuyle degistirir ve gorunum oynar.
function BlogKartlariHtml($yazilar, $okuma, $dil) {
  $dkAd = if ($dil -eq "en") { "min read" } else { "dk okuma" }
  $sb = New-Object System.Text.StringBuilder
  foreach ($y in $yazilar) {
    $baslik = if ($dil -eq "en" -and $y.title_en)   { $y.title_en }   else { $y.title }
    $ozet   = if ($dil -eq "en" -and $y.summary_en) { $y.summary_en } else { $y.summary }
    $url    = "/blog/" + $y.slug + $(if ($dil -eq "en") { "/en/" } else { "/" })

    # meta satiri: tarih · etiketler · okuma suresi (bos olanlar atlanir)
    $parca  = @($y.date)
    $etiket = (Etiketler $y $dil) -join " · "
    if ($etiket) { $parca += $etiket }
    $o = $okuma[$y.slug]
    if ($o) {
      $dk = if ($dil -eq "en" -and $o.en) { $o.en } else { $o.tr }
      if ($dk) { $parca += "$dk $dkAd" }
    }
    $meta = (@($parca) | Where-Object { $_ }) -join " · "

    [void]$sb.Append("`n    <a class=`"post-card`" href=`"$url`">")
    [void]$sb.Append("`n      <div class=`"meta`">$(Kacir $meta)</div>")
    [void]$sb.Append("`n      <h3>$(Kacir $baslik)</h3>")
    [void]$sb.Append("`n      <p>$(Kacir $ozet)</p>")
    [void]$sb.Append("`n    </a>")
  }
  $sb.ToString()
}

# <div id="blog-list"> ... </div> icini kartlarla degistirir.
# Kartlarin kendi icinde </div> gectigi icin regex yerine: acilistan sonraki ilk </section>
# bulunur, ondan geriye dogru en son </div> blog-list'in kapanisidir. Tekrar calistirmaya
# dayanikli — her seferinde ic icerigin tamami degisir.
function BlogListesiGom($html, $kartlar) {
  $bas = $html.IndexOf('<div id="blog-list"')
  if ($bas -lt 0) { throw "index.html icinde <div id=`"blog-list`"> bulunamadi" }
  $icBas = $html.IndexOf('>', $bas) + 1
  $sec = $html.IndexOf('</section>', $icBas)
  if ($sec -lt 0) { throw "blog-list'ten sonra </section> bulunamadi" }
  $icSon = $html.LastIndexOf('</div>', $sec)
  if ($icSon -lt $icBas) { throw "blog-list'in kapanis </div>'i bulunamadi" }
  $html.Substring(0, $icBas) + $kartlar + "`n  " + $html.Substring($icSon)
}

# posts.json -> yeniden eskiye sirali dizi. PS 5.1'de ConvertFrom-Json bir JSON dizisini tek
# bir Object[] olarak dondurur ve @() bunu acmaz; elemanlara ayirmak icin boru hatti gerekiyor.
function YazilariOku($postsDir) {
  $yol = Join-Path $postsDir "posts.json"
  if (-not (Test-Path $yol)) { throw "posts.json bulunamadi: $yol" }
  $ham = Get-Content -Raw -Encoding UTF8 $yol
  $liste = @((ConvertFrom-Json $ham) | ForEach-Object { $_ })
  if ($liste.Count -eq 0) { throw "posts.json bos" }
  @($liste | Sort-Object -Property date -Descending)
}

# okuma.json -> slug'a gore hashtable. Dosya yoksa bos doner; sureler zaten istege bagli.
function OkumaOku($postsDir) {
  $yol = Join-Path $postsDir "okuma.json"
  $tablo = @{}
  if (-not (Test-Path $yol)) { return $tablo }
  $o = ConvertFrom-Json (Get-Content -Raw -Encoding UTF8 $yol)
  foreach ($p in $o.PSObject.Properties) { $tablo[$p.Name] = $p.Value }
  $tablo
}

# index.html'den bir blogu oldugu gibi cikarir — CSS, ust menu ve arka plan devre yollari
# tek kaynaktan gelsin diye. Bulamazsa hata: sessizce eksik sayfa uretmektense dursun.
function BlokAl($indexHtml, $desen, $ad) {
  $m = [regex]::Match($indexHtml, $desen)
  if (-not $m.Success) { throw "index.html icinde $ad bulunamadi (desen: $desen)" }
  if ($m.Groups.Count -gt 1 -and $m.Groups[1].Success) { return $m.Groups[1].Value }
  $m.Value
}
