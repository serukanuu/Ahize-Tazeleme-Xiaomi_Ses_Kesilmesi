#!/system/bin/sh
# Ahize Tazeleme v5.1 - olay tabanli, tek ornek garantili, busybox uyumlu
ARALIK=2
DEBOUNCE=3
MAXLOG=2000000

# --- busybox kacisi ---
# KernelSU service.d script'leri busybox sh ile ve busybox standalone
# modda calisir. O modda grep/ps/awk cagrilari busybox appletlerine
# gider; busybox grep --line-buffered secenegini TANIMIYOR ve aninda
# hata verip cikiyor, logcat de SIGPIPE alip oluyordu (5 saniyede bir
# "logcat koptu" satirinin sebebi buydu). Cozum: sistem kabuguna gecip
# tum araclari tam yol ile cagirmak.
if [ -z "$AHIZE_SYSSH" ] && [ -x /system/bin/sh ]; then
  AHIZE_SYSSH=1
  export AHIZE_SYSSH
  exec /system/bin/sh "$0" "$@"
fi
export PATH=/system/bin:/system/xbin:$PATH

SH=/system/bin/sh
PS=/system/bin/ps
GREP=/system/bin/grep
AWK=/system/bin/awk
LOGCAT=/system/bin/logcat
DUMPSYS=/system/bin/dumpsys
CMD=/system/bin/cmd
DATE=/system/bin/date
[ -x "$PS" ] || PS=ps
[ -x "$GREP" ] || GREP=grep
[ -x "$AWK" ] || AWK=awk
[ -x "$LOGCAT" ] || LOGCAT=logcat
[ -x "$DUMPSYS" ] || DUMPSYS=dumpsys
[ -x "$CMD" ] || CMD=cmd
[ -x "$DATE" ] || DATE=date

# --line-buffered destekleniyor mu? desteklenmiyorsa bos birakilir.
LB="--line-buffered"
"$GREP" $LB -qE x /dev/null 2>/dev/null || LB=""

DIR=/data/local/tmp
LOG=$DIR/tazeleme.log
STATUS=$DIR/ahize_durum.txt
PIDF=$DIR/ahize.pid
CNTF=$DIR/ahize_sayac.txt
ERRF=$DIR/ahize_logcat_hata.txt
mkdir -p "$DIR"

MYPID=$$
FILTRE="MODE_IN_CALL|CALL_STATE|onCallStateChanged|PreciseCallState"

zaman() { "$DATE" '+%m-%d %H:%M:%S'; }

# Kendisi disindaki tum kopyalari ve yetim logcat sureclerini temizler.
# awk filtresi: kendi PID'imiz ve kendi cocuk kabuklarimiz haric tutulur.
baskalarini_oldur() {
  for P in $("$PS" -A -o PID,PPID,ARGS 2>/dev/null | "$GREP" ahize_tazele | "$GREP" -v grep | "$AWK" -v me="$MYPID" '$1!=me && $2!=me {print $1}'); do
    kill -TERM "$P" 2>/dev/null
  done
  sleep 1
  for P in $("$PS" -A -o PID,PPID,ARGS 2>/dev/null | "$GREP" ahize_tazele | "$GREP" -v grep | "$AWK" -v me="$MYPID" '$1!=me && $2!=me {print $1}'); do
    kill -KILL "$P" 2>/dev/null
  done
  for L in $("$PS" -A -o PID,ARGS 2>/dev/null | "$GREP" 'logcat -T 1' | "$GREP" -v grep | "$AWK" '{print $1}'); do
    kill -KILL "$L" 2>/dev/null
  done
}

if [ "$1" = "--stop" ]; then
  baskalarini_oldur
  rm -f "$PIDF"
  sed -i 's/^ALIVE=1/ALIVE=0/' "$STATUS" 2>/dev/null
  echo "durduruldu"
  exit 0
fi

# --- tek ornek kilidi ---
baskalarini_oldur
echo "$MYPID" > "$PIDF"
trap 'rm -f "$PIDF"; kill 0' TERM INT HUP
[ -f "$CNTF" ] || echo 0 > "$CNTF"

write_status() {
  {
    echo "ALIVE=1"
    echo "PID=$MYPID"
    echo "TIME=$("$DATE" '+%Y-%m-%d %H:%M:%S')"
    echo "IN_CALL=$1"
    echo "EARPIECE=$2"
    echo "MODE=$3"
    echo "COUNT=$(cat "$CNTF" 2>/dev/null)"
  } > "$STATUS.tmp" && mv "$STATUS.tmp" "$STATUS"
}

echo "$(zaman) === baslangic PID $MYPID v5.1 Olay Tabanli (kabuk $0, lb='$LB') ===" >> "$LOG"
write_status 0 0 IDLE

# logd hazir olana kadar bekle - onyuklemede logcat bir sure calismiyor.
HAZIR=0
T=0
while [ $T -lt 60 ]; do
  if "$LOGCAT" -d -t 1 >/dev/null 2>&1; then HAZIR=1; break; fi
  T=$((T + 1))
  sleep 2
done
[ "$HAZIR" = "1" ] || echo "$(zaman) UYARI: logcat 120 saniyede hazir olmadi, yine de deneniyor" >> "$LOG"

BEKLE=5
LAST=""
while true; do
  BASLANGIC=$("$DATE" +%s)

  "$LOGCAT" -T 1 2>"$ERRF" | "$GREP" -E $LB -i "$FILTRE" 2>>"$ERRF" | while read -r line; do
    # olay firtinasini bastir
    NOW=$("$DATE" +%s)
    if [ -n "$LAST" ] && [ $((NOW - LAST)) -lt "$DEBOUNCE" ]; then continue; fi
    LAST=$NOW

    D=$("$DUMPSYS" audio 2>/dev/null)
    echo "$D" | "$GREP" -q "Actual mode = MODE_IN_CALL" || continue
    echo "$D" | "$GREP" -q "Active communication device.*type:earpiece" || continue

    echo "$(zaman) --- GORUSME BASLADI (Ahize) ---" >> "$LOG"
    echo "$(zaman) Ahize - Tazeleme Devrede" >> "$LOG"
    write_status 1 1 IN_CALL
    ONCEKI=ahize

    while true; do
      D2=$("$DUMPSYS" audio 2>/dev/null)
      echo "$D2" | "$GREP" -q "Actual mode = MODE_IN_CALL" || {
        echo "$(zaman) --- GORUSME BITTI ---" >> "$LOG"
        write_status 0 0 IDLE
        break
      }

      if echo "$D2" | "$GREP" -q "Active communication device.*type:earpiece"; then
        if [ "$ONCEKI" != "ahize" ]; then
          echo "$(zaman) Ahize - Tazeleme Devrede" >> "$LOG"
          ONCEKI=ahize
        fi
        "$CMD" telecom set-audio-route EARPIECE >/dev/null 2>&1
        C=$(cat "$CNTF" 2>/dev/null)
        [ -z "$C" ] && C=0
        C=$((C + 1))
        echo "$C" > "$CNTF"
        write_status 1 1 IN_CALL
        if [ $((C % 30)) -eq 0 ]; then
          echo "$(zaman) OK $C" >> "$LOG"
          SZ=$(wc -c < "$LOG" 2>/dev/null)
          [ -n "$SZ" ] && [ "$SZ" -gt "$MAXLOG" ] && tail -n 2000 "$LOG" > "$LOG.tmp" 2>/dev/null && mv "$LOG.tmp" "$LOG"
        fi
      else
        if [ "$ONCEKI" != "disi" ]; then
          echo "$(zaman) Ahize Disi - Beklemede" >> "$LOG"
          ONCEKI=disi
        fi
        write_status 1 0 NON_EARPIECE
      fi
      sleep "$ARALIK"
    done
  done

  # buraya dusuldugune gore boru hatti oldu. sebebi log'a yazilsin.
  SURE=$(("$("$DATE" +%s)" - BASLANGIC))
  HATA=$(head -c 200 "$ERRF" 2>/dev/null | tr '\n' ' ')
  if [ -n "$HATA" ]; then
    echo "$(zaman) !!! logcat koptu ($SURE sn sonra) - hata: $HATA" >> "$LOG"
  else
    echo "$(zaman) !!! logcat koptu ($SURE sn sonra), yeniden baglaniyor !!!" >> "$LOG"
  fi
  : > "$ERRF"
  write_status 0 0 RECONNECT

  # artan bekleme: uzun yasadiysa sifirla, kisa yasadiysa geri cekil.
  if [ "$SURE" -ge 60 ]; then
    BEKLE=5
  else
    BEKLE=$((BEKLE * 2))
    [ "$BEKLE" -gt 300 ] && BEKLE=300
  fi
  sleep "$BEKLE"
done
