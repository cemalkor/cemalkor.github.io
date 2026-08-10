# cemalkor.com.tr — Ingilizce ana sayfa ureticisi
#
# Girdi : index.html  (govde + I18N sozlugu + MSG.en basliklari)
# Cikti : en/index.html
#
# Neden var: Ingilizce icerik calisma zamaninda applyLang() ile yerine konuyordu, yani
# JS'siz tarayici Turkce govde goruyordu. Ustelik /?lang=en sorgu adresi index.html'in
# statik canonical'i ("/") yuzunden Bing tarafindan "kurallı sayfanin alternatifi" sayilip
# dizine alinmiyordu. Artik Ingilizce sayfa kendi dosyasinda, kendi canonical'iyla.
#
# Calisma sekli: index.html'i alir, [data-i18n] tasiyan her elemanin ic HTML'ini I18N
# sozlugundeki karsiligiyla degistirir, head'i Ingilizceye cevirir. Govdenin geri kalani
# (script'ler, stil, SVG) oldugu gibi kopyalanir — tek kaynak index.html.
#
# feed-uret.ps1 sonunda bu script'i cagiriyor, ayrica calistirmak gerekmez.
#
# Deterministik: index.html degismediyse birebir ayni dosyayi uretir.

param([string]$Kok = ".")

$ErrorActionPreference = "Stop"

# DIKKAT: bu dosya UTF-8 BOM ILE kaydedilmeli (bkz. feed-uret.ps1 icindeki not).
$SITE = "https://cemalkor.com.tr"

$kokTam    = (Resolve-Path $Kok).Path
$indexYol  = Join-Path $kokTam "index.html"
$cikisYol  = Join-Path $kokTam "en\index.html"

$utf8 = New-Object System.Text.UTF8Encoding $false
$html = [System.IO.File]::ReadAllText($indexYol, [System.Text.Encoding]::UTF8)

# ---------- I18N sozlugunu oku ----------
# JS nesne sabiti: 'anahtar':'deger' ciftleri. Deger HTML ve kesme isareti icerdigi icin
# regex yerine karakter karakter taraniyor; tirnak turu ve \ kacislari korunuyor.
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
    # anahtar ile deger arasindaki ':' atlanir
    while ($i -lt $n -and $blok[$i] -ne ':') { $i++ }
    $i++
    $deger = SonrakiMetin ([ref]$i)
    if ($null -eq $deger) { break }
    $sozluk[$anahtar] = $deger
    while ($i -lt $n -and $blok[$i] -ne ',') { $i++ }
    $i++
  }
  $sozluk
}

$i18nBlok = [regex]::Match($html, '(?s)const I18N = \{(.*?)\r?\n\};')
if (-not $i18nBlok.Success) { throw "index.html icinde 'const I18N = { ... };' blogu bulunamadi" }
$I18N = JsSozlukCoz $i18nBlok.Groups[1].Value
Write-Host "  I18N: $($I18N.Count) anahtar okundu."
if ($I18N.Count -lt 50) { throw "I18N beklenenden az anahtar dondu ($($I18N.Count)) - bicim degismis olabilir" }

# MSG.en icindeki sayfa basligi ve aciklamasi
$msgEn = [regex]::Match($html, "(?s)\ben:\{(.*?)\n  \}")
if (-not $msgEn.Success) { throw "index.html icinde MSG.en blogu bulunamadi" }
$enBaslik  = [regex]::Match($msgEn.Groups[1].Value, "docTitle:'([^']*)'").Groups[1].Value
$enAciklama = [regex]::Match($msgEn.Groups[1].Value, "desc:'([^']*)'").Groups[1].Value
if (-not $enBaslik -or -not $enAciklama) { throw "MSG.en icinde docTitle/desc okunamadi" }

# ---------- govde: [data-i18n] elemanlarini cevir ----------
# Ayni etiketin ic ice gectigi bir data-i18n elemani yok (tools/ notu: 109 elemanda kontrol
# edildi), bu yuzden ilk kapanis etiketine kadar olan kisim guvenle ic HTML sayilabiliyor.
$cevrilen = 0
$atlanan  = New-Object System.Collections.ArrayList

# Acilis etiketlerini tek tek gezip ic HTML'i degistiriyoruz. Metin uzunlugu degistigi icin
# sondan basa gidiliyor, boylece onceki eslesmelerin indeksleri kaymiyor.
$eslesmeler = @([regex]::Matches($html, '<(\w+)[^>]*\sdata-i18n="([^"]+)"[^>]*>'))
[array]::Reverse($eslesmeler)
$sonuc = $html
foreach ($m in $eslesmeler) {
  $etiket  = $m.Groups[1].Value
  $anahtar = $m.Groups[2].Value
  if (-not $I18N.Contains($anahtar)) { [void]$atlanan.Add($anahtar); continue }
  $icBas  = $m.Index + $m.Length
  $icSon  = $sonuc.IndexOf("</$etiket>", $icBas)
  if ($icSon -lt 0) { throw "kapanis etiketi bulunamadi: <$etiket data-i18n=`"$anahtar`">" }
  $sonuc = $sonuc.Substring(0, $icBas) + $I18N[$anahtar] + $sonuc.Substring($icSon)
  $cevrilen++
}
Write-Host "  govde: $cevrilen eleman cevrildi, $($atlanan.Count) eleman I18N'de yok (Turkce kaldi)."

# ---------- head: Ingilizceye cevir ----------
# Her degisiklik birebir eslesmeli; eslesmezse index.html degismis demektir ve sessizce
# bozuk bir EN sayfasi uretmektense hata verip durmak dogru.
function Degistir($metin, $eski, $yeni, $ad) {
  if ($metin -notlike "*$eski*") { throw "head degisikligi eslesmedi ($ad). index.html degismis olabilir: $eski" }
  $metin.Replace($eski, $yeni)
}

$trBaslik = [regex]::Match($html, '<title>([^<]*)</title>').Groups[1].Value
$trAciklama = [regex]::Match($html, '<meta name="description" content="([^"]*)"').Groups[1].Value

$sonuc = Degistir $sonuc '<html lang="tr">' '<html lang="en">' 'html lang'
$sonuc = Degistir $sonuc "<title>$trBaslik</title>" "<title>$enBaslik</title>" 'title'
$sonuc = $sonuc.Replace("content=`"$trAciklama`"", "content=`"$enAciklama`"")   # description + og + twitter
$sonuc = Degistir $sonuc "<link rel=`"canonical`" href=`"$SITE/`">" "<link rel=`"canonical`" href=`"$SITE/en/`">" 'canonical'
$sonuc = Degistir $sonuc "<meta property=`"og:url`" content=`"$SITE/`">" "<meta property=`"og:url`" content=`"$SITE/en/`">" 'og:url'
$sonuc = Degistir $sonuc '<meta property="og:locale" content="tr_TR">' '<meta property="og:locale" content="en_US">' 'og:locale'
$sonuc = Degistir $sonuc '<meta property="og:locale:alternate" content="en_US">' '<meta property="og:locale:alternate" content="tr_TR">' 'og:locale:alternate'
$sonuc = Degistir $sonuc "<meta property=`"og:title`" content=`"$trBaslik`">" "<meta property=`"og:title`" content=`"$enBaslik`">" 'og:title'
$sonuc = Degistir $sonuc "<meta name=`"twitter:title`" content=`"$trBaslik`">" "<meta name=`"twitter:title`" content=`"$enBaslik`">" 'twitter:title'
$sonuc = Degistir $sonuc "<meta property=`"og:image:alt`" content=`"$trBaslik · cemalkor.com.tr`">" "<meta property=`"og:image:alt`" content=`"$enBaslik · cemalkor.com.tr`">" 'og:image:alt'

# yapisal veri: Person ayni kisi oldugu icin @id degismiyor, yalnizca insan okuyacak alanlar
# ceviriliyor. ProfilePage ise ayri bir sayfa, kendi @id ve url'sini aliyor.
$sonuc = Degistir $sonuc '"jobTitle": "Gömülü Yazılım Mühendisi"' '"jobTitle": "Embedded Software Engineer"' 'ld jobTitle'
# yapisal veridekiaciklama meta description'dan farkli (isim ve sehir eki yok), ayri tutuluyor
$ldAciklamaTr = [regex]::Match($html, '"description": "([^"]*)"').Groups[1].Value
if (-not $ldAciklamaTr) { throw "yapisal veride description bulunamadi" }
$sonuc = Degistir $sonuc "`"description`": `"$ldAciklamaTr`"" '"description": "Embedded software engineer specializing in smart meters, low-power IoT devices, Sigfox, BLE and NB-IoT."' 'ld description'
$sonuc = Degistir $sonuc @"
      "@type": "ProfilePage",
      "@id": "$SITE/#profilepage",
      "url": "$SITE/",
      "name": "$trBaslik",
"@ @"
      "@type": "ProfilePage",
      "@id": "$SITE/#profilepage-en",
      "url": "$SITE/en/",
      "inLanguage": "en",
      "name": "$enBaslik",
"@ 'ld ProfilePage'

# uretilen dosya oldugunu belli et
$sonuc = Degistir $sonuc '<html lang="en">' @"
<html lang="en">
<!-- URETILEN DOSYA - elle duzenleme. Kaynak: index.html + tools/en-sayfa-uret.ps1
     Icerik degisikligi index.html icinde (govde) ve I18N sozlugunde (Ingilizcesi) yapilir,
     sonra .\tools\feed-uret.ps1 . calistirilir. -->
"@ 'uretildi notu'

$dizin = Split-Path $cikisYol -Parent
if (-not (Test-Path $dizin)) { [void](New-Item -ItemType Directory -Force -Path $dizin) }
[System.IO.File]::WriteAllText($cikisYol, $sonuc, $utf8)
Write-Host "  yazildi: en\index.html"
