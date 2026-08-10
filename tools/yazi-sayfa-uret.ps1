# cemalkor.com.tr — blog yazilari icin statik sayfa ureticisi
#
# Girdi : posts/posts.json + posts/*.md + posts/okuma.json + index.html (<style> blogu)
# Cikti : blog/<slug>/index.html      (TR)
#         blog/<slug>/en/index.html   (EN)
#
# Neden var: index.html tek dosya ve icindeki <link rel="canonical"> statik olarak "/" diyor;
# yazi adresini yalnizca JS duzeltiyordu. Bing JS'i calistirmadan tarayip her ?yazi= adresini
# ana sayfanin kopyasi sayip dizine almiyordu. Artik her yazinin kendi dosyasi ve kendi
# kanonik adresi var; JS'siz tarayici da tam icerigi goruyor.
#
# feed-uret.ps1 sonunda bu script'i cagiriyor, ayrica calistirmak gerekmez:
#   .\tools\feed-uret.ps1 .
#
# Deterministik: icerik degismediyse birebir ayni dosyalari uretir, git status bos kalir.

param([string]$Kok = ".")

$ErrorActionPreference = "Stop"

# DIKKAT: bu dosya UTF-8 BOM ILE kaydedilmeli. Windows PowerShell 5.1 BOM'suz script'i ANSI
# sanip Turkce karakterleri bozuyor ("Kör" -> "KÃ¶r") ve bu metin dogrudan HTML'e basiliyor.
$SITE = "https://cemalkor.com.tr"

# index.html'deki MSG tablosunun karsiligi — iki yerde ayni metin, ikisi de elle guncelleniyor
$MSG = @{
  tr = @{ geri = "← Tüm yazılar"; dk = "dk okuma"; onceki = "← Önceki yazı"; sonraki = "Sonraki yazı →"
          kopyala = "kopyala"; kopyalandi = "kopyalandı ✓"; kopyaHata = "kopyalanamadı"
          tema = "Koyu / açık tema"; digerDil = "EN"; siteAd = "Cemal Kör — Gömülü Yazılım Mühendisi" }
  en = @{ geri = "← All posts"; dk = "min read"; onceki = "← Previous post"; sonraki = "Next post →"
          kopyala = "copy"; kopyalandi = "copied ✓"; kopyaHata = "copy failed"
          tema = "Dark / light theme"; digerDil = "TR"; siteAd = "Cemal Kör — Embedded Software Engineer" }
}

$kokTam   = (Resolve-Path $Kok).Path
$postsDir = Join-Path $kokTam "posts"
$blogDir  = Join-Path $kokTam "blog"

$utf8 = New-Object System.Text.UTF8Encoding $false

function Yaz($yol, $metin) {
  $dizin = Split-Path $yol -Parent
  if (-not (Test-Path $dizin)) { [void](New-Item -ItemType Directory -Force -Path $dizin) }
  [System.IO.File]::WriteAllText($yol, $metin, $utf8)
  Write-Host "  yazildi: $($yol.Substring($kokTam.Length + 1))"
}

. (Join-Path $PSScriptRoot "ortak.ps1")

# Markdown'daki adresler koke gore yazili (posts/gorseller/x.jpg). Yazi sayfasi /blog/slug/
# altinda durdugu icin goreli adres kirilir; kok-mutlak hale getiriyoruz.
function AdresDuzelt($u) {
  if ($u -match '^(https?:|mailto:|tel:|/|#)') { return $u }
  return "/$u"
}

# ---------- markdown: satir ici ----------
function Satirici($t) {
  $s = Kacir $t

  # Satir ici kodun icindeki *, _ ve [ isaretleri bicimlendirmeye girmesin diye once
  # yer tutucuya aliniyor. Kacis yapildigi icin metinde artik "<" bulunamaz; yer tutucu guvenli.
  $kodlar = New-Object System.Collections.ArrayList
  $s = [regex]::Replace($s, '`([^`]+)`', {
    param($m)
    $i = $kodlar.Add($m.Groups[1].Value)
    "<KOD$i>"
  })

  # gorsel linkten once gelmeli: ![]() deseni []() desenini de karsilar
  $s = [regex]::Replace($s, '!\[([^\]]*)\]\(([^)\s]+)\)', {
    param($m)
    $src = AdresDuzelt $m.Groups[2].Value
    "<img src=`"$src`" alt=`"$($m.Groups[1].Value)`" loading=`"lazy`" decoding=`"async`">"
  })

  $s = [regex]::Replace($s, '\[([^\]]+)\]\(([^)\s]+)\)', {
    param($m)
    $href = AdresDuzelt $m.Groups[2].Value
    $dis = if ($href -match '^https?:') { ' target="_blank" rel="noopener"' } else { '' }
    "<a href=`"$href`"$dis>$($m.Groups[1].Value)</a>"
  })

  $s = [regex]::Replace($s, '\*\*([^*]+)\*\*', '<strong>$1</strong>')
  $s = [regex]::Replace($s, '(?<![\w*])\*([^*\n]+)\*(?![\w*])', '<em>$1</em>')

  for ($i = 0; $i -lt $kodlar.Count; $i++) {
    $s = $s.Replace("<KOD$i>", "<code>$($kodlar[$i])</code>")
  }
  $s
}

# "| a | b |" -> @("a","b"); bastaki ve sondaki bos hucreler atiliyor
function TabloHucre($satir) {
  $s = $satir.Trim() -replace '^\|', '' -replace '\|$', ''
  @($s -split '\|' | ForEach-Object { $_.Trim() })
}

# ---------- markdown: blok ----------
# Once satirlar blok listesine gruplaniyor, sonra bloklar basiliyor. Tek geciste yapilinca
# her gecis noktasinda "birikeni bosalt" kodu tekrar ediyordu; iki asama daha okunur.
function BlokKapat {
  if ($script:tur -eq '') { return }
  [void]$script:bloklar.Add(@{ tur = $script:tur; satir = @($script:buf); dil = $script:kodDil })
  $script:tur    = ''
  $script:buf    = New-Object System.Collections.ArrayList
  $script:kodDil = ''
}

function MdHtml($md) {
  $script:bloklar = New-Object System.Collections.ArrayList
  $script:tur     = ''
  $script:buf     = New-Object System.Collections.ArrayList
  $script:kodDil  = ''

  foreach ($ham in ($md -replace "`r`n", "`n") -split "`n") {
    $s = $ham.TrimEnd()

    # kod blogunun icinde hicbir markdown kurali islemez, kapanis fence'ine kadar aynen alinir
    if ($script:tur -eq 'kod') {
      if ($s -match '^\s*```\s*$') { BlokKapat } else { [void]$script:buf.Add($ham) }
      continue
    }
    if ($s -match '^\s*```\s*([\w+#-]*)\s*$') {
      BlokKapat; $script:tur = 'kod'; $script:kodDil = $Matches[1]; continue
    }
    if ($s -match '^\s*$')                    { BlokKapat; continue }
    if ($s -match '^(#{1,6})\s+(.*)$')        { BlokKapat; $script:tur = 'baslik'; [void]$script:buf.Add($s); BlokKapat; continue }
    if ($s -match '^\s*(-{3,}|\*{3,}|_{3,})\s*$') { BlokKapat; $script:tur = 'hr'; BlokKapat; continue }
    if ($s -match '^\s*>\s?(.*)$') {
      if ($script:tur -ne 'alinti') { BlokKapat; $script:tur = 'alinti' }
      [void]$script:buf.Add($Matches[1]); continue
    }
    if ($s -match '^\s*[-*+]\s+(.*)$') {
      if ($script:tur -ne 'ul') { BlokKapat; $script:tur = 'ul' }
      [void]$script:buf.Add($Matches[1]); continue
    }
    if ($s -match '^\s*\d+\.\s+(.*)$') {
      if ($script:tur -ne 'ol') { BlokKapat; $script:tur = 'ol' }
      [void]$script:buf.Add($Matches[1]); continue
    }
    if ($s -match '^\s*\|') {
      if ($script:tur -ne 'tablo') { BlokKapat; $script:tur = 'tablo' }
      [void]$script:buf.Add($s.Trim()); continue
    }
    if ($script:tur -ne 'p') { BlokKapat; $script:tur = 'p' }
    [void]$script:buf.Add($s)
  }
  BlokKapat

  $h = New-Object System.Text.StringBuilder
  foreach ($b in $script:bloklar) {
    switch ($b.tur) {
      'kod' {
        $sinif = if ($b.dil) { " class=`"language-$($b.dil)`"" } else { '' }
        [void]$h.Append("<pre><code$sinif>" + (Kacir ($b.satir -join "`n")) + "</code></pre>`n")
      }
      'baslik' {
        [void]($b.satir[0] -match '^(#{1,6})\s+(.*)$')
        $n = $Matches[1].Length
        [void]$h.Append("<h$n>" + (Satirici $Matches[2]) + "</h$n>`n")
      }
      'hr'     { [void]$h.Append("<hr>`n") }
      'alinti' { [void]$h.Append("<blockquote><p>" + (Satirici ($b.satir -join " ")) + "</p></blockquote>`n") }
      'ul'     { [void]$h.Append("<ul>`n" + (($b.satir | ForEach-Object { "  <li>" + (Satirici $_) + "</li>" }) -join "`n") + "`n</ul>`n") }
      'ol'     { [void]$h.Append("<ol>`n" + (($b.satir | ForEach-Object { "  <li>" + (Satirici $_) + "</li>" }) -join "`n") + "`n</ol>`n") }
      'p'      { [void]$h.Append("<p>" + (Satirici ($b.satir -join " ")) + "</p>`n") }
      'tablo'  {
        $sat = @($b.satir)
        # GFM: ikinci satir |---|:--:| ise ilk satir baslik. Ayirici yoksa tumu govde.
        $basliklı = ($sat.Count -ge 2 -and $sat[1] -match '^\|?[\s:|-]+\|[\s:|-]*$')
        [void]$h.Append("<table>`n")
        if ($basliklı) {
          [void]$h.Append("<thead><tr>" + (((TabloHucre $sat[0]) | ForEach-Object { "<th>" + (Satirici $_) + "</th>" }) -join '') + "</tr></thead>`n")
          $govdeSat = if ($sat.Count -gt 2) { $sat[2..($sat.Count - 1)] } else { @() }
        } else {
          $govdeSat = $sat
        }
        [void]$h.Append("<tbody>`n")
        foreach ($r in $govdeSat) {
          [void]$h.Append("<tr>" + (((TabloHucre $r) | ForEach-Object { "<td>" + (Satirici $_) + "</td>" }) -join '') + "</tr>`n")
        }
        [void]$h.Append("</tbody>`n</table>`n")
      }
    }
  }
  $h.ToString()
}

# ---------- girdi ----------
$jsonYol = Join-Path $postsDir "posts.json"
if (-not (Test-Path $jsonYol)) { throw "posts.json bulunamadi: $jsonYol" }

# PS 5.1'de ConvertFrom-Json diziyi tek Object[] dondurur; elemanlara ayirmak icin boru hatti sart
$yazilar = @((ConvertFrom-Json (Get-Content -Raw -Encoding UTF8 $jsonYol)) | ForEach-Object { $_ })
if ($yazilar.Count -eq 0) { throw "posts.json bos" }
$yazilar = @($yazilar | Sort-Object -Property date -Descending)

$okuma = @{}
$okumaYol = Join-Path $postsDir "okuma.json"
if (Test-Path $okumaYol) {
  $o = ConvertFrom-Json (Get-Content -Raw -Encoding UTF8 $okumaYol)
  $o.PSObject.Properties | ForEach-Object { $okuma[$_.Name] = $_.Value }
}

# CSS, ust menu ve arka plan devre yollari tek kaynaktan gelsin: index.html'den oldugu gibi
# aliniyor. Boylece ana sayfada rengi ya da menuyu degistirince yazi sayfalari da ayni oluyor.
$indexYol = Join-Path $kokTam "index.html"
$indexHtml = Get-Content -Raw -Encoding UTF8 $indexYol

# Desenler govdedeki gercek etikete demirlenmis: CSS yorumunda ya da JS metninde gecen
# bir etiket adina takilip yanlis yeri kesmesin diye (bir kez oldu, CSS'in yarisi gitti).
$CSS     = (BlokAl $indexHtml '(?sm)^<style>(.*?)\r?\n</style>' '<style> blogu').Trim()
$DEVRE   = BlokAl $indexHtml '(?sm)^<svg class="bg-circuit".*?\r?\n</svg>' 'arka plan SVG''si'
$NAV_HAM = BlokAl $indexHtml '(?sm)^<nav>\r?\n\s*<div class="nav-in">.*?\r?\n</nav>' 'ust menu'
$I18N    = I18NOku $indexHtml

# Yanlis yeri kesmek sessizce bozuk sayfa uretiyor; boyut sinirlari bunu erken yakalasin.
if ($DEVRE   -match '</style>') { throw "arka plan SVG'si stil blogunu da kesmis - desen bozuk" }
if ($NAV_HAM -match '</style>') { throw "ust menu stil blogunu da kesmis - desen bozuk" }
if ($NAV_HAM.Length -gt 4000)   { throw "ust menu beklenenden buyuk ($($NAV_HAM.Length)) - desen bozuk" }

# Ust menu capalari ana sayfanin bolumlerine gidiyor; yazi sayfasinda o bolumler yok,
# bu yuzden kok adrese cevriliyor (#projeler -> /#projeler).
function NavUret($dil) {
  $n = $NAV_HAM
  if ($dil -eq "en") { $n = (I18NUygula $n $I18N).html }
  $kok = if ($dil -eq "en") { "/en/" } else { "/" }
  $n = $n -replace 'href="#top"', "href=`"$kok`""
  $n = [regex]::Replace($n, 'href="#([a-z]+)"', "href=`"$kok#`$1`"")
  # dugme etiketi gidilecek dili gosteriyor: TR sayfada "EN", EN sayfada "TR".
  # Dugmenin kendisi <button> kaliyor, hedefi sayfa sonundaki JS bagliyor (ana sayfadaki gibi).
  if ($dil -eq "en") { $n = $n -replace '(<button id="lang-btn"[^>]*>)EN(</button>)', '$1TR$2' }
  $n
}

Write-Host "$($yazilar.Count) yazi, $($CSS.Length) karakter CSS, $($I18N.Count) ceviri anahtari."

# ---------- sayfa ----------
function YaziYolu($slug, $dil) {
  if ($dil -eq "en") { return "/blog/$slug/en/" }
  return "/blog/$slug/"
}

function SayfaUret($y, $dil, $indeks) {
  $t = $MSG[$dil]
  $baslik = if ($dil -eq "en" -and $y.title_en)   { $y.title_en }   else { $y.title }
  $ozet   = if ($dil -eq "en" -and $y.summary_en) { $y.summary_en } else { $y.summary }
  $dosya  = if ($dil -eq "en" -and $y.file_en)    { $y.file_en }    else { $y.file }

  $mdYol = Join-Path $postsDir $dosya
  if (-not (Test-Path $mdYol)) { Write-Warning "  markdown yok, atlandi: $dosya"; return $null }
  $govde = MdHtml (Get-Content -Raw -Encoding UTF8 $mdYol)

  $trUrl = "$SITE$(YaziYolu $y.slug 'tr')"
  $enUrl = "$SITE$(YaziYolu $y.slug 'en')"
  $url   = if ($dil -eq "en") { $enUrl } else { $trUrl }

  # okuma suresi: EN dosyasi yoksa site TR icerigini gosteriyor, sure de TR'ninki
  $dk = ''
  if ($okuma.ContainsKey($y.slug)) {
    $kayit = $okuma[$y.slug]
    $d = if ($dil -eq "en") { if ($kayit.en) { $kayit.en } else { $kayit.tr } } else { $kayit.tr }
    if ($d) { $dk = "$d $($t.dk)" }
  }
  $meta = (@($y.date, (@($y.tags) -join ' · '), $dk) | Where-Object { $_ }) -join ' · '

  # onceki/sonraki: liste yeniden eskiye sirali, once = daha eski (sonraki indeks)
  $yeni = if ($indeks -gt 0) { $yazilar[$indeks - 1] } else { $null }
  $eski = if ($indeks -lt $yazilar.Count - 1) { $yazilar[$indeks + 1] } else { $null }
  $navKart = {
    param($p, $sinif, $yon)
    if (-not $p) { return "" }
    $ad = if ($dil -eq "en" -and $p.title_en) { $p.title_en } else { $p.title }
    "<a class=`"post-nav-link $sinif`" href=`"$(YaziYolu $p.slug $dil)`">" +
    "<span class=`"yon`">$(Kacir $yon)</span><span class=`"ad`">$(Kacir $ad)</span></a>"
  }
  $nav = ""
  if ($yeni -or $eski) {
    $nav = "`n    <nav class=`"post-nav`">" +
           (& $navKart $eski 'onceki' $t.onceki) + (& $navKart $yeni 'sonraki' $t.sonraki) + "</nav>"
  }

  # [ordered] sart: siradan hashtable'da anahtar sirasi her calistirmada degisiyor, uretilen
  # JSON-LD de oyle. Icerik ayni kalsa bile dosya degisik gorunup git'i gereksiz kirletiyordu.
  $ld = [ordered]@{
    '@context' = 'https://schema.org'
    '@type'    = 'BlogPosting'
    headline   = $baslik
    description = $ozet
    datePublished = $y.date
    dateModified  = $y.date
    inLanguage = if ($dil -eq "en") { 'en' } else { 'tr-TR' }
    keywords   = (@($y.tags) -join ', ')
    url        = $url
    mainEntityOfPage = [ordered]@{ '@type' = 'WebPage'; '@id' = $url }
    author     = @{ '@id' = "$SITE/#cemalkor" }
    publisher  = @{ '@id' = "$SITE/#cemalkor" }
    image      = "$SITE/og.png"
  } | ConvertTo-Json -Depth 5 -Compress

  $htmlDil    = if ($dil -eq "en") { "en" } else { "tr" }
  $ogLocale   = if ($dil -eq "en") { "en_US" } else { "tr_TR" }
  $ogAlt      = if ($dil -eq "en") { "tr_TR" } else { "en_US" }
  $feed       = if ($dil -eq "en") { "/feed.en.xml" } else { "/feed.xml" }
  $digerDil   = if ($dil -eq "en") { "tr" } else { "en" }
  $digerUrl   = YaziYolu $y.slug $digerDil

  @"
<!DOCTYPE html>
<html lang="$htmlDil">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>$(Kacir $baslik) — Cemal Kör</title>
<meta name="description" content="$(Kacir $ozet)">
<meta name="author" content="Cemal Kör">

<!-- Uretilen dosya - elle duzenleme. Kaynak: posts/ + tools/yazi-sayfa-uret.ps1 -->
<link rel="canonical" href="$url">
<link rel="alternate" hreflang="tr" href="$trUrl">
<link rel="alternate" hreflang="en" href="$enUrl">
<link rel="alternate" hreflang="x-default" href="$trUrl">

<link rel="alternate" type="application/rss+xml" title="Cemal Kör — Blog (TR)" href="/feed.xml">
<link rel="alternate" type="application/rss+xml" title="Cemal Kör — Blog (EN)" href="/feed.en.xml">

<meta property="og:type" content="article">
<meta property="og:site_name" content="Cemal Kör">
<meta property="og:locale" content="$ogLocale">
<meta property="og:locale:alternate" content="$ogAlt">
<meta property="og:title" content="$(Kacir $baslik) — Cemal Kör">
<meta property="og:description" content="$(Kacir $ozet)">
<meta property="og:url" content="$url">
<meta property="og:image" content="$SITE/og.png">
<meta property="og:image:width" content="1200">
<meta property="og:image:height" content="630">
<meta property="article:published_time" content="$($y.date)">
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="$(Kacir $baslik) — Cemal Kör">
<meta name="twitter:description" content="$(Kacir $ozet)">
<meta name="twitter:image" content="$SITE/og.png">

<link rel="icon" href="/favicon.ico" sizes="32x32">
<link rel="icon" href="/favicon.svg" type="image/svg+xml">
<link rel="icon" href="/favicon-96x96.png" type="image/png" sizes="96x96">
<link rel="apple-touch-icon" href="/apple-touch-icon.png">

<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@600;700&family=IBM+Plex+Sans:wght@400;500;600&family=IBM+Plex+Mono:wght@400;600&display=swap" rel="stylesheet">
<style>
$CSS
/* index.html'de #post-view baslangicta gizli (SPA aciyordu); burada tek gorunum o */
#post-view{display:block}
/* ust menuden sonra yazinin ustunde bu kadar bosluk yeter — ana sayfadaki hero yok */
#blog{padding-top:40px}
</style>
<meta name="theme-color" content="#F7F8F6" media="(prefers-color-scheme: light)">
<meta name="theme-color" content="#0F1712" media="(prefers-color-scheme: dark)">
<script>
/* koyu mod: kayitli tercih yoksa sistem tercihi; body cizilmeden uygulanir (flash onlemi) */
(function(){
  const t = localStorage.getItem('tema');
  if(t === 'dark' || (!t && matchMedia('(prefers-color-scheme: dark)').matches))
    document.documentElement.dataset.theme = 'dark';
})();
</script>
<script>
window.goatcounter = { path: function(p){ return location.pathname + location.search + location.hash } };
</script>
<script data-goatcounter="https://cemalkor.goatcounter.com/count" async src="https://gc.zgo.at/count.js"></script>
<script type="application/ld+json">$ld</script>
</head>
<body>

$DEVRE

$(NavUret $dil)

<main>
<section id="blog">
  <div id="post-view">
    <a class="back-btn" href="$(if ($dil -eq 'en') { '/en/#blog' } else { '/#blog' })">$(Kacir $t.geri)</a>
    <article id="post-content">
<div class="post-meta">$(Kacir $meta)</div>
$govde</article>$nav
  </div>
</section>
</main>

<footer id="iletisim">
  <div class="foot-in">
    <div class="foot-links">
      <a href="mailto:cemalkor94@gmail.com">cemalkor94@gmail.com</a>
      <a href="https://www.linkedin.com/in/cemalkor/" target="_blank" rel="me noopener">LinkedIn</a>
      <a href="https://github.com/cemalkor" target="_blank" rel="me noopener">GitHub</a>
      <a href="$feed">RSS</a>
    </div>
  </div>
</footer>

<script>
/* tema, dil, menu ve kod kopyalama — ana sayfadaki karsiliklarinin sade hali */
document.getElementById('tema-btn').addEventListener('click', ()=>{
  const koyu = document.documentElement.dataset.theme === 'dark';
  if(koyu) delete document.documentElement.dataset.theme;
  else document.documentElement.dataset.theme = 'dark';
  localStorage.setItem('tema', koyu ? 'light' : 'dark');
});
/* dil dugmesi: yazinin oteki dildeki surumune git, tercihi de kaydet ki ana sayfa uysun */
document.getElementById('lang-btn').addEventListener('click', ()=>{
  localStorage.setItem('lang', '$digerDil');
  location.href = '$digerUrl';
});
/* mobilde asagi kaydirirken menu gizlensin — ana sayfadakiyle ayni davranis */
const navEl = document.querySelector('body > nav');
const navMobil = matchMedia('(max-width:840px)');
let sonScrollY = window.scrollY;
window.addEventListener('scroll', () => {
  const y = window.scrollY;
  if(navMobil.matches && y > sonScrollY && y > 80) navEl.classList.add('nav-hidden');
  else navEl.classList.remove('nav-hidden');
  sonScrollY = y;
}, {passive:true});
document.querySelectorAll('#post-content pre').forEach(pre => {
  const sar = document.createElement('div');
  sar.className = 'kod-sar';
  pre.parentNode.insertBefore(sar, pre);
  sar.appendChild(pre);
  const btn = document.createElement('button');
  btn.type = 'button';
  btn.className = 'kod-kopyala';
  btn.textContent = '$($t.kopyala)';
  btn.addEventListener('click', async () => {
    let oldu = false;
    try{ await navigator.clipboard.writeText(pre.innerText); oldu = true; }catch(e){}
    btn.textContent = oldu ? '$($t.kopyalandi)' : '$($t.kopyaHata)';
    btn.classList.toggle('ok', oldu);
    setTimeout(() => { btn.textContent = '$($t.kopyala)'; btn.classList.remove('ok'); }, 1600);
  });
  sar.appendChild(btn);
});
</script>
</body>
</html>
"@
}

# ---------- uret ----------
for ($i = 0; $i -lt $yazilar.Count; $i++) {
  $y = $yazilar[$i]
  foreach ($dil in @("tr", "en")) {
    $sayfa = SayfaUret $y $dil $i
    if ($null -eq $sayfa) { continue }
    $yol = if ($dil -eq "en") { Join-Path $blogDir "$($y.slug)\en\index.html" }
           else               { Join-Path $blogDir "$($y.slug)\index.html" }
    Yaz $yol $sayfa
  }
}

# posts.json'dan cikarilan yazinin klasoru yayinda kalmasin diye uyariyoruz.
# Silmiyoruz: uretilmemis bir sey de o klasorde durabilir, karari insan versin.
if (Test-Path $blogDir) {
  $gecerli = $yazilar | ForEach-Object { $_.slug }
  Get-ChildItem -Path $blogDir -Directory | Where-Object { $gecerli -notcontains $_.Name } | ForEach-Object {
    Write-Warning "  posts.json'da olmayan klasor duruyor: blog/$($_.Name)  (elle sil)"
  }
}
