# favicon.ico uretici — favicon.svg ile ayni motif, 16/32/48 boyutlarinda cok katmanli ICO
Add-Type -AssemblyName System.Drawing

$out = $args[0]
if (-not $out) { throw "Cikti klasoru gerekli" }

$bg     = [System.Drawing.Color]::FromArgb(255, 14, 27, 21)
$green  = [System.Drawing.Color]::FromArgb(255, 111, 220, 168)
$copper = [System.Drawing.Color]::FromArgb(255, 184, 115, 51)

function New-Ikon([int]$S) {
  $k = $S / 32.0
  $bmp = New-Object System.Drawing.Bitmap $S, $S, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.Clear($bg)

  # kucuk boyutlarda cizgi orantili olarak kalinlastiriliyor, yoksa 16px'te kayboluyor
  $kalinlik = if ($S -le 16) { 4.2 } elseif ($S -le 32) { 3.6 } else { 3.2 }

  $penC = New-Object System.Drawing.Pen $green, ([float]($kalinlik * $k))
  $penC.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
  $penC.EndCap   = [System.Drawing.Drawing2D.LineCap]::Round
  $penC.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
  $pts = [System.Drawing.PointF[]]@(
    [System.Drawing.PointF]::new([float](8*$k),    [float](10*$k)),
    [System.Drawing.PointF]::new([float](14.5*$k), [float](16*$k)),
    [System.Drawing.PointF]::new([float](8*$k),    [float](22*$k))
  )
  $g.DrawLines($penC, $pts)

  $penU = New-Object System.Drawing.Pen $copper, ([float]($kalinlik * $k))
  $penU.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
  $penU.EndCap   = [System.Drawing.Drawing2D.LineCap]::Round
  $g.DrawLine($penU, [float](18*$k), [float](21.5*$k), [float](24*$k), [float](21.5*$k))

  $g.Dispose()
  return $bmp
}

# her boyutu PNG olarak kodla
$boyutlar = @(16, 32, 48)
$pngler = @()
foreach ($s in $boyutlar) {
  $b = New-Ikon $s
  $ms = New-Object System.IO.MemoryStream
  $b.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
  $pngler += ,@($s, $ms.ToArray())
  $ms.Dispose(); $b.Dispose()
}

# ICO konteyneri: 6 bayt basslik + her katman icin 16 baytlik dizin girisi + PNG verileri
$n = $pngler.Count
$ms = New-Object System.IO.MemoryStream
$bw = New-Object System.IO.BinaryWriter $ms
$bw.Write([UInt16]0)   # reserved
$bw.Write([UInt16]1)   # tur: 1 = ikon
$bw.Write([UInt16]$n)  # katman sayisi

$ofset = 6 + (16 * $n)
foreach ($p in $pngler) {
  $s = $p[0]; $veri = $p[1]
  $bw.Write([Byte]$s)            # genislik
  $bw.Write([Byte]$s)            # yukseklik
  $bw.Write([Byte]0)             # palet rengi yok
  $bw.Write([Byte]0)             # reserved
  $bw.Write([UInt16]1)           # duzlem
  $bw.Write([UInt16]32)          # bit derinligi
  $bw.Write([UInt32]$veri.Length)
  $bw.Write([UInt32]$ofset)
  $ofset += $veri.Length
}
foreach ($p in $pngler) { $bw.Write($p[1]) }

$bw.Flush()
[System.IO.File]::WriteAllBytes((Join-Path $out "favicon.ico"), $ms.ToArray())
$bw.Dispose(); $ms.Dispose()

# 96x96 PNG: Google favicon'lari 48'in kati kare olarak istiyor
$b96 = New-Ikon 96
$b96.Save((Join-Path $out "favicon-96x96.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$b96.Dispose()

Write-Output "favicon.ico (16/32/48) ve favicon-96x96.png yazildi -> $out"
