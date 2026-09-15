param([string]$Adb = "adb")
$ErrorActionPreference = "SilentlyContinue"

$remote = 'echo "___ALIVE___"; P=$(cat /data/local/tmp/ahize.pid 2>/dev/null); kill -0 "$P" 2>/dev/null && echo CALISIYOR; echo "___ST___"; cat /data/local/tmp/ahize_durum.txt 2>/dev/null; echo "___PS___"; ps -A -o PID,ARGS | grep ahize_tazele | grep -v grep; echo "___LOG___"; tail -n 14 /data/local/tmp/tazeleme.log 2>/dev/null'

function Get-Section($text, $name) {
	$m = [regex]::Match($text, "___$name___\r?\n([\s\S]*?)(?=___[A-Z]+___|$)")
	if ($m.Success) { return $m.Groups[1].Value.TrimEnd() }
	return ""
}

function Get-Field($block, $key) {
	$m = [regex]::Match($block, "(?m)^$key=(.*)$")
	if ($m.Success) { return $m.Groups[1].Value.Trim() }
	return ""
}

$tur = 0
while ($true) {
	$tur++
	$raw = (& $Adb shell "su -c '$remote'" 2>&1) -join "`n"

	$st   = Get-Section $raw "ST"
	$proc = Get-Section $raw "PS"
	$log  = Get-Section $raw "LOG"

	$inCall = (Get-Field $st "IN_CALL") -eq "1"
	$onEar  = (Get-Field $st "EARPIECE") -eq "1"
	$cnt    = Get-Field $st "COUNT"
	$mode   = Get-Field $st "MODE"
	$stamp  = Get-Field $st "TIME"
	# ayakta mi? kayitli PID'e kill -0 ile bakiliyor.
	# ps|grep boru hatti bazen bos donuyordu, o yuzden ikisi de kontrol ediliyor.
	$alive  = ((Get-Section $raw "ALIVE") -match "CALISIYOR") -or ($proc -match "ahize_tazele")
	$kopya  = (($proc -split "`n") | Where-Object { $_ -match "ahize_tazele" }).Count
	if (-not $cnt) { $cnt = "0" }

	Clear-Host
	Write-Host "=================================================================" -ForegroundColor DarkGray
	Write-Host "  CANLI DURUM        " -NoNewline
	Write-Host (Get-Date -Format "HH:mm:ss") -ForegroundColor White -NoNewline
	Write-Host "        cikmak icin ESC" -ForegroundColor DarkGray
	Write-Host "=================================================================" -ForegroundColor DarkGray

	Write-Host "  SERVIS   : " -NoNewline
	if ($alive) {
		Write-Host "CALISIYOR" -ForegroundColor Green -NoNewline
		if ($kopya -gt 2) {
			Write-Host "   !!! $kopya SATIR - COKLU KOPYA, menu 2 ile duzelt" -ForegroundColor Red
		} else {
			Write-Host "   (tek ornek)" -ForegroundColor DarkGray
		}
	} else {
		Write-Host "DURMUS (veya telefon bagli degil)" -ForegroundColor Red
	}

	Write-Host "  GORUSME  : " -NoNewline
	if ($inCall) { Write-Host "AKTIF (MODE_IN_CALL)" -ForegroundColor Green } else { Write-Host "yok" -ForegroundColor DarkGray }

	Write-Host "  CIKIS    : " -NoNewline
	if ($onEar) { Write-Host "AHIZE" -ForegroundColor Green } else { Write-Host "ahize disi (hoparlor/BT)" -ForegroundColor Yellow }

	Write-Host "  TAZELEME : " -NoNewline
	Write-Host "$cnt kez (toplam)" -ForegroundColor White
	Write-Host "  DURUM    : " -NoNewline
	Write-Host "$mode   (son yazim: $stamp)" -ForegroundColor DarkGray

	if ($inCall -and $onEar) {
		Write-Host "  >>> TAZELEME DEVREDE - 2 saniyede bir <<<" -ForegroundColor Black -BackgroundColor Green
	} elseif ($inCall) {
		Write-Host "  >>> GORUSME VAR, AHIZE DISI - beklemede <<<" -ForegroundColor Black -BackgroundColor Yellow
	} else {
		Write-Host "  --- bosta, zil bekleniyor ---" -ForegroundColor DarkGray
	}

	Write-Host "----------------- KAYIT AKISI (son 14 satir) --------------------" -ForegroundColor DarkGray
	foreach ($l in ($log -split "`n")) {
		if ($l -match "BASLADI")              { Write-Host "  $l" -ForegroundColor Cyan }
		elseif ($l -match "BITTI")            { Write-Host "  $l" -ForegroundColor Magenta }
		elseif ($l -match "koptu")            { Write-Host "  $l" -ForegroundColor Red }
		elseif ($l -match "Ahize Disi")       { Write-Host "  $l" -ForegroundColor Yellow }
		elseif ($l -match "Tazeleme Devrede") { Write-Host "  $l" -ForegroundColor Green }
		elseif ($l -match "baslangic")        { Write-Host "  $l" -ForegroundColor White }
		elseif ($l -match "^\S+ \S+ OK ")     { Write-Host "  $l" -ForegroundColor Green }
		else                                  { Write-Host "  $l" }
	}
	Write-Host "=================================================================" -ForegroundColor DarkGray
	Write-Host "  yenileme #$tur   -   ESC = geri" -ForegroundColor DarkGray

	$sw = [Diagnostics.Stopwatch]::StartNew()
	while ($sw.ElapsedMilliseconds -lt 2000) {
		if ([Console]::KeyAvailable) {
			$k = [Console]::ReadKey($true)
			if ($k.Key -eq "Escape") { return }
		}
		Start-Sleep -Milliseconds 60
	}
}
