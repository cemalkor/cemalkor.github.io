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

# index.html'den bir blogu oldugu gibi cikarir — CSS, ust menu ve arka plan devre yollari
# tek kaynaktan gelsin diye. Bulamazsa hata: sessizce eksik sayfa uretmektense dursun.
function BlokAl($indexHtml, $desen, $ad) {
  $m = [regex]::Match($indexHtml, $desen)
  if (-not $m.Success) { throw "index.html icinde $ad bulunamadi (desen: $desen)" }
  if ($m.Groups.Count -gt 1 -and $m.Groups[1].Success) { return $m.Groups[1].Value }
  $m.Value
}
