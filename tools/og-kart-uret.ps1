# cemalkor.com.tr — paylasim karti (og.png) ve apple-touch-icon uretici
# Sitenin PCB / terminal estetigini System.Drawing ile ciziyor.
Add-Type -AssemblyName System.Drawing

$out = $args[0]
if (-not $out) { throw "Cikti klasoru gerekli" }

# --- site paleti ---
$bg      = [System.Drawing.Color]::FromArgb(255, 14, 27, 21)    # --term-bg  #0E1B15
$green   = [System.Drawing.Color]::FromArgb(255, 111, 220, 168) # --term-green #6FDCA8
$copper  = [System.Drawing.Color]::FromArgb(255, 184, 115, 51)  # --copper #B87333
$light   = [System.Drawing.Color]::FromArgb(255, 228, 236, 231) # --ink (dark tema) #E4ECE7
$soft    = [System.Drawing.Color]::FromArgb(255, 157, 176, 166) # --ink-soft #9DB0A6
$pcbDim  = [System.Drawing.Color]::FromArgb(95,  30, 110, 82)   # iz yesili, soluk
$cuDim   = [System.Drawing.Color]::FromArgb(80,  184, 115, 51)  # bakir iz, soluk

function New-G($bmp) {
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode     = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAlias
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  return $g
}

# harfleri tek tek cizerek harf araligi (letter-spacing) verir — teknik/etiket gorunumu icin
function Draw-Tracked($g, $text, $font, $brush, $x, $y, $extra) {
  $cx = [float]$x
  foreach ($ch in $text.ToCharArray()) {
    $s = [string]$ch
    $g.DrawString($s, $font, $brush, $cx, [float]$y)
    $w = $g.MeasureString($s, $font, [System.Drawing.PointF]::new(0,0),
         [System.Drawing.StringFormat]::GenericTypographic).Width
    $cx += $w + $extra
  }
}

# =====================  og.png  (1200 x 630)  =====================
$W = 1200; $H = 630
$bmp = New-Object System.Drawing.Bitmap $W, $H, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = New-G $bmp
$g.Clear($bg)

# --- arka plan: devre izleri (sagda yogun, solda birkac tane) ---
$penG = New-Object System.Drawing.Pen $pcbDim, 3
$penC = New-Object System.Drawing.Pen $cuDim, 3
$penG.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
$penC.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round

# duz koordinat dizisi alir: x1,y1,x2,y2,... (ic ice dizi PowerShell arguman modunda sorun cikariyor)
function Draw-Trace($g, $pen, [double[]]$c) {
  $arr = @()
  for ($i = 0; $i -lt $c.Length; $i += 2) {
    $arr += [System.Drawing.PointF]::new([float]$c[$i], [float]$c[$i+1])
  }
  $g.DrawLines($pen, [System.Drawing.PointF[]]$arr)
}
function Draw-Via($g, $pen, $x, $y, $r) {
  $g.DrawEllipse($pen, [float]($x-$r), [float]($y-$r), [float]($r*2), [float]($r*2))
}

# sag bolge
Draw-Trace $g $penG (1220,90, 1080,90, 1030,140, 1030,205)
Draw-Trace $g $penG (1220,300, 1120,300, 1070,250, 1070,190)
Draw-Trace $g $penG (1220,470, 1090,470, 1040,520, 1040,590)
Draw-Trace $g $penC (1220,180, 1150,180, 1100,230, 1100,330)
Draw-Trace $g $penC (1160,-20, 1160,60, 1110,110, 1000,110)
Draw-Trace $g $penC (1220,390, 1130,390, 1080,440, 980,440)
Draw-Via $g $penG 1030 205 6
Draw-Via $g $penG 1070 190 6
Draw-Via $g $penG 1040 590 6
Draw-Via $g $penC 1100 330 6
Draw-Via $g $penC 1000 110 6
Draw-Via $g $penC 980  440 6
# sol kenar
Draw-Trace $g $penG (-20,540, 60,540, 110,590, 110,650)
Draw-Trace $g $penC (-20,120, 40,120, 90,70, 90,-20)
Draw-Via $g $penG 60 540 6

# --- sol kenarda dikey vurgu cizgisi ---
$brGreen = New-Object System.Drawing.SolidBrush $green
$g.FillRectangle($brGreen, 0, 0, 10, $H)

$PAD = 88

# --- eyebrow: mono, bakir, harf aralikli ---
$fMonoSm = New-Object System.Drawing.Font "Cascadia Mono", 19, ([System.Drawing.FontStyle]::Regular), ([System.Drawing.GraphicsUnit]::Pixel)
$brCopper = New-Object System.Drawing.SolidBrush $copper
Draw-Tracked $g "GÖMÜLÜ YAZILIM MÜHENDİSİ · ANKARA" $fMonoSm $brCopper $PAD 128 3.0

# --- isim: buyuk, kalin ---
$fName = New-Object System.Drawing.Font "Segoe UI", 112, ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel)
$brLight = New-Object System.Drawing.SolidBrush $light
$g.DrawString("Cemal Kör", $fName, $brLight, [float]($PAD - 7), 172)

# --- tanitim satiri ---
$fSub = New-Object System.Drawing.Font "Segoe UI", 34, ([System.Drawing.FontStyle]::Regular), ([System.Drawing.GraphicsUnit]::Pixel)
$brSoft = New-Object System.Drawing.SolidBrush $soft
$g.DrawString("IoT cihazları için uçtan uca gömülü yazılım", $fSub, $brSoft, [float]($PAD - 4), 322)

# --- teknoloji satiri: mono, yesil ---
$fMonoMd = New-Object System.Drawing.Font "Cascadia Mono", 25, ([System.Drawing.FontStyle]::Regular), ([System.Drawing.GraphicsUnit]::Pixel)
$g.DrawString("Sigfox · NB-IoT · BLE · NFC · STM32 · Low-Power", $fMonoMd, $brGreen, [float]$PAD, 386)

# --- ayirici (kare dalga: sitedeki sq-divider motifi) ---
$penDiv = New-Object System.Drawing.Pen $cuDim, 3
$dv = @($PAD,470, ($PAD+120),470, ($PAD+120),458, ($PAD+240),458, ($PAD+240),470, ($PAD+420),470, ($PAD+420),458, ($PAD+520),458)
Draw-Trace $g $penDiv $dv

# --- alt satir: terminal prompt + alan adi ---
$fMonoLg = New-Object System.Drawing.Font "Cascadia Mono", 30, ([System.Drawing.FontStyle]::Regular), ([System.Drawing.GraphicsUnit]::Pixel)
$prompt = "cemal@kor:~$"
$g.DrawString($prompt, $fMonoLg, $brGreen, [float]$PAD, 520)
# MeasureString sondaki bosluklari kirpiyor — bosluk genisligini ayrica olcup ekliyoruz
$fmt = [System.Drawing.StringFormat]::GenericTypographic
$pw = $g.MeasureString($prompt, $fMonoLg, [System.Drawing.PointF]::new(0,0), $fmt).Width
$sp = $g.MeasureString("mm", $fMonoLg, [System.Drawing.PointF]::new(0,0), $fmt).Width / 2
$g.DrawString("cemalkor.com.tr", $fMonoLg, $brLight, [float]($PAD + $pw + $sp), 520)

$g.Dispose()
$bmp.Save((Join-Path $out "og.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

# =====================  apple-touch-icon.png  (180 x 180)  =====================
# favicon.svg ile ayni motif: terminal zemini + yesil chevron + bakir alt cizgi
$S = 180
$k = $S / 32.0
$ico = New-Object System.Drawing.Bitmap $S, $S, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$gi = New-G $ico
$gi.Clear($bg)

$penChev = New-Object System.Drawing.Pen $green, ([float](3.2 * $k))
$penChev.StartCap  = [System.Drawing.Drawing2D.LineCap]::Round
$penChev.EndCap    = [System.Drawing.Drawing2D.LineCap]::Round
$penChev.LineJoin  = [System.Drawing.Drawing2D.LineJoin]::Round
$cv = @((8*$k), (10*$k), (14.5*$k), (16*$k), (8*$k), (22*$k))
Draw-Trace $gi $penChev $cv

# alt cizgi: yuvarlak uclu tek cizgi (rounded rect yerine — 3 birim yukseklikte dejenere oluyordu)
$penUnd = New-Object System.Drawing.Pen $copper, ([float](3.2 * $k))
$penUnd.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
$penUnd.EndCap   = [System.Drawing.Drawing2D.LineCap]::Round
$gi.DrawLine($penUnd, [float](18*$k), [float](21.5*$k), [float](24*$k), [float](21.5*$k))

$gi.Dispose()
$ico.Save((Join-Path $out "apple-touch-icon.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$ico.Dispose()

Write-Output "og.png ve apple-touch-icon.png yazildi -> $out"
