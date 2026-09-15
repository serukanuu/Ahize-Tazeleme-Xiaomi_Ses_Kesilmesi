#!/system/bin/sh
# Ahize durdurucu v4.4 - artik hicbir kopya hayatta kalmiyor
DIR=/data/local/tmp
STATUS=$DIR/ahize_durum.txt
PIDF=$DIR/ahize.pid
BOOT=/data/adb/service.d/ahize_tazele.sh

liste() {
  ps -A -o PID,ARGS 2>/dev/null | grep ahize_tazele | grep -v grep | awk '{print $1}'
}

# 1) kayitli surec grubu
P=$(cat "$PIDF" 2>/dev/null)
[ -n "$P" ] && kill -TERM "-$P" 2>/dev/null

# 2) ad ile TERM
for X in $(liste); do kill -TERM "$X" 2>/dev/null; done
sleep 1

# 3) inatci olanlara KILL (uc tur)
T=0
while [ $T -lt 3 ]; do
  KALAN=$(liste)
  [ -z "$KALAN" ] && break
  for X in $KALAN; do kill -KILL "$X" 2>/dev/null; done
  sleep 1
  T=$((T + 1))
done

# 4) yetim logcat sureclerini supur
for L in $(ps -A -o PID,ARGS 2>/dev/null | grep 'logcat -T 1' | grep -v grep | awk '{print $1}'); do
  kill -KILL "$L" 2>/dev/null
done

rm -f "$PIDF"
sed -i 's/^ALIVE=1/ALIVE=0/' "$STATUS" 2>/dev/null

KALAN=$(liste)
if [ -n "$KALAN" ]; then
  echo "HATA: hala ayakta ->"
  ps -A -o PID,ARGS 2>/dev/null | grep ahize_tazele | grep -v grep
  exit 1
fi
echo "TEMIZ: hicbir kopya kalmadi"
exit 0
