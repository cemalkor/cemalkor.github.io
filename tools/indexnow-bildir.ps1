# cemalkor.com.tr — IndexNow bildirimi
#
# Yeni yazi yayinlandiktan SONRA calistir: arama motorlarina "su adresler degisti" der,
# tarayicinin siteye ugramasini beklemek gerekmez. Bing ve Yandex ayni bildirimi paylasiyor.
#
#   .\tools\indexnow-bildir.ps1              → sitemap.xml'deki tum adresler
#   .\tools\indexnow-bildir.ps1 -Adres "https://cemalkor.com.tr/blog/yeni-yazi/"
#
# Anahtar dogrulamasi: <anahtar>.txt dosyasi sitenin kokunde YAYINDA olmali. Bildirimden
# once push'layip GitHub Pages'in dagitmasini bekle, yoksa istek 403 doner.
#
# DIKKAT: bu dosya UTF-8 BOM ILE kaydedilmeli (bkz. feed-uret.ps1 icindeki not).

param(
  [string]$Kok = ".",
  [string[]]$Adres
)

$ErrorActionPreference = "Stop"

$SITE    = "https://cemalkor.com.tr"
$ANAHTAR = "6d33c09534694df58c9b1753fc22438c"

$kokTam = (Resolve-Path $Kok).Path

# anahtar dosyasi repoda duruyor mu — yayinda olup olmadigini asagida ayrica kontrol ediyoruz
$anahtarDosya = Join-Path $kokTam "$ANAHTAR.txt"
if (-not (Test-Path $anahtarDosya)) { throw "anahtar dosyasi repoda yok: $ANAHTAR.txt" }

# adres verilmediyse site haritasindaki her seyi bildir
if (-not $Adres) {
  $sitemapYol = Join-Path $kokTam "sitemap.xml"
  if (-not (Test-Path $sitemapYol)) { throw "sitemap.xml bulunamadi; once .\tools\feed-uret.ps1 . calistir" }
  $sm = Get-Content -Raw -Encoding UTF8 $sitemapYol
  $Adres = @([regex]::Matches($sm, '<loc>([^<]+)</loc>') | ForEach-Object { $_.Groups[1].Value })
}
if ($Adres.Count -eq 0) { throw "bildirilecek adres yok" }

# anahtar yayinda mi? IndexNow bunu kendisi kontrol ediyor; once biz bakip anlasilir hata verelim
try {
  $y = Invoke-WebRequest -Uri "$SITE/$ANAHTAR.txt" -UseBasicParsing -TimeoutSec 20
  if ($y.Content.Trim() -ne $ANAHTAR) { throw "icerik eslesmiyor" }
} catch {
  throw "anahtar dosyasi yayinda okunamadi ($SITE/$ANAHTAR.txt). Push'ladin mi, GitHub Pages dagitimi bitti mi?"
}

Write-Host "$($Adres.Count) adres bildiriliyor:"
$Adres | ForEach-Object { Write-Host "  $_" }

$govde = @{
  host        = "cemalkor.com.tr"
  key         = $ANAHTAR
  keyLocation = "$SITE/$ANAHTAR.txt"
  urlList     = @($Adres)
} | ConvertTo-Json -Depth 3

$cevap = Invoke-WebRequest -Uri "https://api.indexnow.org/indexnow" -Method Post `
  -ContentType "application/json; charset=utf-8" `
  -Body ([System.Text.Encoding]::UTF8.GetBytes($govde)) -UseBasicParsing -TimeoutSec 30

# 200 = alindi, 202 = alindi ama anahtar dogrulamasi beklemede. Ikisi de basarili.
Write-Host "IndexNow yaniti: $($cevap.StatusCode) $($cevap.StatusDescription)"
if ($cevap.StatusCode -notin @(200, 202)) { throw "beklenmeyen yanit" }
Write-Host "Bitti."
