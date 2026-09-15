@echo off
setlocal enabledelayedexpansion
title Ahize Tazeleme Yonetimi
mode con: cols=80 lines=40

set ADB=
where adb >nul 2>&1 && set ADB=adb
if not defined ADB if exist "C:\platform-tools\adb.exe" set ADB=C:\platform-tools\adb.exe
if not defined ADB if exist "%~dp0adb.exe" set ADB=%~dp0adb.exe
if not defined ADB if exist "%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" set ADB=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe
if not defined ADB (
  cls
  echo HATA: adb.exe bulunamadi.
  echo Bu klasore adb.exe koy ya da C:\platform-tools icine kur.
  pause
  exit /b 1
)

:MENU
cls
echo ================================================================
echo                 AHIZE TAZELEME - YONETIM PANELI   v4.5
echo ================================================================
for /f "delims=" %%A in ('"%ADB%" shell "su -c 'P=$(cat /data/local/tmp/ahize.pid 2>/dev/null); kill -0 $P 2>/dev/null ^&^& echo CALISIYOR'" 2^>nul') do set SRV=%%A
if defined SRV (echo   Servis: CALISIYOR) else (echo   Servis: DURMUS ^(veya telefon bagli degil^))
set SRV=
echo ================================================================
echo.
echo    1  -  Canli durum ekrani   ^(ESC ile geri^)
echo    2  -  Kur / guncelle ve baslat
echo    3  -  Servisi baslat
echo    4  -  Servisi durdur
echo    5  -  Simdi bir kez tazele
echo    6  -  Teshis raporu al
echo    7  -  Kaydi temizle
echo    8  -  Servisi tamamen kaldir
echo    9  -  Kayit dosyasini PC'ye indir
echo.
echo    0  -  Cikis
echo.
set SEC=
set /p SEC="  Secim: "
if "%SEC%"=="1" goto CANLI
if "%SEC%"=="2" goto KUR
if "%SEC%"=="3" goto BASLAT
if "%SEC%"=="4" goto DURDUR
if "%SEC%"=="5" goto TAZELE
if "%SEC%"=="6" goto TESHIS
if "%SEC%"=="7" goto TEMIZLE
if "%SEC%"=="8" goto KALDIR
if "%SEC%"=="9" goto INDIR
if "%SEC%"=="0" exit /b 0
goto MENU

:CANLI
cls
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0canli.ps1" -Adb "%ADB%"
goto MENU

:KUR
cls
echo ---- KURULUM ----
echo.
echo [1/6] dosyalar gonderiliyor
"%ADB%" push "%~dp0ahize_tazele.sh" /data/local/tmp/ahize_tazele.sh
"%ADB%" push "%~dp0durdur.sh" /data/local/tmp/durdur.sh
echo [2/6] satir sonlari duzeltiliyor
"%ADB%" shell "su -c 'tr -d \"\\r\" < /data/local/tmp/ahize_tazele.sh > /data/local/tmp/a.tmp; mv /data/local/tmp/a.tmp /data/local/tmp/ahize_tazele.sh'"
"%ADB%" shell "su -c 'tr -d \"\\r\" < /data/local/tmp/durdur.sh > /data/local/tmp/d.tmp; mv /data/local/tmp/d.tmp /data/local/tmp/durdur.sh; chmod 755 /data/local/tmp/durdur.sh'"
echo [3/6] eski kopya durduruluyor
"%ADB%" shell "su -c 'sh /data/local/tmp/durdur.sh'"
echo [4/6] onyukleme klasorune kopyalaniyor
"%ADB%" shell "su -c 'mkdir -p /data/adb/service.d && cp -f /data/local/tmp/ahize_tazele.sh /data/adb/service.d/ahize_tazele.sh && chmod 755 /data/adb/service.d/ahize_tazele.sh && ls -l /data/adb/service.d/ahize_tazele.sh'"
echo [5/6] baslatiliyor
"%ADB%" shell "su -c 'nohup setsid sh /data/adb/service.d/ahize_tazele.sh >/dev/null 2>&1 &'"
timeout /t 3 /nobreak >nul
echo [6/6] dogrulama
"%ADB%" shell "su -c 'ps -A -o PID,ARGS | grep ahize_tazele | grep -v grep'"
"%ADB%" shell "su -c 'cat /data/local/tmp/ahize_durum.txt'"
echo.
echo Kuruldu. Her yeniden baslatmada kendisi acilir.
pause
goto MENU

:BASLAT
cls
"%ADB%" shell "su -c 'sh /data/local/tmp/durdur.sh'" >nul 2>&1
"%ADB%" shell "su -c 'nohup setsid sh /data/adb/service.d/ahize_tazele.sh >/dev/null 2>&1 &'"
timeout /t 3 /nobreak >nul
"%ADB%" shell "su -c 'ps -A -o PID,ARGS | grep ahize_tazele | grep -v grep'"
echo.
echo Baslatildi.
pause
goto MENU

:DURDUR
cls
"%ADB%" shell "su -c 'sh /data/local/tmp/durdur.sh'"
echo.
echo Not: telefon yeniden baslarsa servis yine acilir.
echo Kalici kaldirmak icin 8 numarayi kullan.
pause
goto MENU

:TAZELE
cls
echo Tek seferlik sessiz tazeleme gonderiliyor...
"%ADB%" shell "su -c 'cmd telecom set-audio-route EARPIECE'"
echo.
echo Gonderildi.
pause
goto MENU

:TESHIS
cls
"%ADB%" push "%~dp0tani.sh" /data/local/tmp/tani.sh >nul 2>&1
"%ADB%" shell "su -c 'tr -d \"\\r\" < /data/local/tmp/tani.sh > /data/local/tmp/t.tmp; mv /data/local/tmp/t.tmp /data/local/tmp/tani.sh; chmod 755 /data/local/tmp/tani.sh'"
"%ADB%" shell "su -c 'sh /data/local/tmp/tani.sh'" > "%~dp0tani_cikti.txt" 2>&1
type "%~dp0tani_cikti.txt"
echo.
echo Kaydedildi: %~dp0tani_cikti.txt
pause
goto MENU

:TEMIZLE
cls
"%ADB%" shell "su -c 'rm -f /data/local/tmp/tazeleme.log; echo kayit temizlendi'"
echo.
pause
goto MENU

:KALDIR
cls
echo DIKKAT: servis tamamen kaldirilacak.
set ONAY=
set /p ONAY="Emin misin? (E/H): "
if /i not "%ONAY%"=="E" goto MENU
"%ADB%" shell "su -c 'sh /data/local/tmp/durdur.sh'"
"%ADB%" shell "su -c 'rm -f /data/adb/service.d/ahize_tazele.sh /data/local/tmp/ahize_tazele.sh /data/local/tmp/ahize_durum.txt /data/local/tmp/ahize_sayac.txt; echo silindi'"
echo.
echo Kaldirildi. Yeniden baslatmada artik acilmaz.
pause
goto MENU

:INDIR
cls
"%ADB%" shell "su -c 'cp -f /data/local/tmp/tazeleme.log /data/local/tmp/tz_kopya.log; chmod 666 /data/local/tmp/tz_kopya.log'"
"%ADB%" pull /data/local/tmp/tz_kopya.log "%~dp0tazeleme_kayit.txt"
echo.
echo Indirildi: %~dp0tazeleme_kayit.txt
pause
goto MENU
