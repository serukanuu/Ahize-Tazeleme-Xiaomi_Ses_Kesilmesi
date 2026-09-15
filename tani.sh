#!/system/bin/sh
echo "=================================================="
echo "TANI  $(date '+%d-%m-%Y %H:%M:%S')"
echo "=================================================="
echo "--- 1. SES MODU ---"
dumpsys audio 2>/dev/null | grep -i "mode =" | head -n 6
echo "--- 2. AKTIF ILETISIM CIHAZI ---"
dumpsys audio 2>/dev/null | grep -i "communication device" | head -n 6
echo "--- 3. SERVIS SURECI ---"
ps -A -o PID,ARGS 2>/dev/null | grep ahize_tazele | grep -v grep
echo "    kayitli PID: $(cat /data/local/tmp/ahize.pid 2>/dev/null)"
echo "--- 4. YETIM LOGCAT SURECLERI (servis durmusken bos olmali) ---"
ps -A -o PID,ARGS 2>/dev/null | grep "logcat -T 1" | grep -v grep
echo "--- 5. ONYUKLEME DOSYASI ---"
ls -l /data/adb/service.d/ahize_tazele.sh 2>&1
echo "--- 6. DURUM DOSYASI ---"
cat /data/local/tmp/ahize_durum.txt 2>&1
echo "--- 7. GORUSME BASLA/BIT + KOPMA SATIRLARI ---"
grep -E "GORUSME|baslangic|koptu|Tazeleme Devrede" /data/local/tmp/tazeleme.log 2>/dev/null | tail -n 20
echo "--- 8. LOG SON 15 SATIR ---"
tail -n 15 /data/local/tmp/tazeleme.log 2>/dev/null
echo "--- 9. TOPLAM TAZELEME (sayac dosyasi) ---"
cat /data/local/tmp/ahize_sayac.txt 2>/dev/null
echo "--- SON ---"
