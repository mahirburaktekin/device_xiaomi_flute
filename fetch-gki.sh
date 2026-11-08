#!/usr/bin/env bash
# android14-6.1 dalının en güncel GKI release'ini indirir.
# Image ve system_dlkm aynı build'den olmak zorunda (modül imzası).
# Bağımsız çalışır (AOSP ağacı gerekmez). Yeni kernel istediğinde bir kere çalıştır,
# prebuilt/gki/ içeriğini commit'le. Build sırasında çalıştırılmaz.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$HERE/prebuilt/gki" && cd "$HERE/prebuilt/gki"
AVBTOOL="$(mktemp -d)/avbtool.py"
curl -fsSL "https://android.googlesource.com/platform/external/avb/+/refs/heads/main/avbtool.py?format=TEXT" | base64 -d > "$AVBTOOL"

JSON=https://source.android.com/static/docs/core/architecture/kernel/gki-android14-6_1-release-builds.json
RAW="$(mktemp)"
curl -fsSL "$JSON" -o "$RAW"
read -r BID TAG < <(python3 - "$RAW" <<'PY'
import json,sys,html
t=html.unescape(open(sys.argv[1],encoding="utf-8",errors="replace").read())
i=t.find('{'); dec=json.JSONDecoder()
while i!=-1:
    try:
        d,_=dec.raw_decode(t,i)
        if isinstance(d,dict) and "branches" in d: break
    except ValueError: pass
    i=t.find('{',i+1)
else:
    sys.exit("JSON bulunamadı")
# En yeni dal (adı tarih içerir: android14-6.1-YYYY-MM), sonra o dalın en son sürümü
br=[b for b in d["branches"] if any(x.get("kernel_bid") for x in b.get("releases",[]))]
b=max(br,key=lambda b:b["name"])
x=max((x for x in b["releases"] if x.get("kernel_bid")),key=lambda x:(x["date"],int(x["kernel_bid"])))
print(x["kernel_bid"],x["tag"])
PY
)
[ -n "${BID:-}" ] || { echo "HATA: release bilgisi okunamadı"; exit 1; }
echo "En güncel: $TAG (BID $BID)"

BASE=https://ci.android.com/builds/submitted/$BID/kernel_aarch64/latest/raw
curl -fL -o Image "$BASE/Image"
curl -fL -o system_dlkm.img "$BASE/system_dlkm.img"

# vbmeta'ya girebilmesi için hashtree footer (imzasız, descriptor vbmeta'da)
python3 "$AVBTOOL" add_hashtree_footer --image system_dlkm.img \
    --partition_name system_dlkm --hash_algorithm sha256 --do_not_generate_fec

echo "$TAG $BID" > VERSION
grep -a -m1 -o 'Linux version [^ ]*' Image || true
# Vendor (system_dlkm_modprobe.sh) modülleri /system_dlkm/lib/modules/*/modules.load'dan yükler
fs="?"; [ "$(od -An -tx1 -j1024 -N4 system_dlkm.img | tr -d ' ')" = "e2e1f5e0" ] && fs=erofs
[ "$(od -An -tx1 -j1080 -N2 system_dlkm.img | tr -d ' ')" = "53ef" ] && fs=ext4
echo "system_dlkm dosya sistemi: $fs"
if [ "$fs" = ext4 ] && command -v debugfs >/dev/null; then
  dls() { debugfs -R "ls -p $1" system_dlkm.img 2>/dev/null | awk -F/ 'NF>6 && $6!="." && $6!=".." {print $6}'; }
  kv=$(dls /lib/modules | grep -m1 'android' || true)
  [ -n "$kv" ] || { echo "HATA: /lib/modules/<sürüm> yok"; exit 1; }
  nl=$(debugfs -R "cat /lib/modules/$kv/modules.load" system_dlkm.img 2>/dev/null | grep -c '\.ko' || true)
  echo "system_dlkm: lib/modules/$kv/modules.load -> $nl modül"
  [ "$nl" -gt 0 ] || { echo "HATA: modules.load boş ya da yok"; exit 1; }
elif [ "$fs" = erofs ] && command -v fsck.erofs >/dev/null; then
  T=$(mktemp -d); fsck.erofs --extract="$T/x" system_dlkm.img >/dev/null
  nl=$(cat "$T"/x/lib/modules/*/modules.load 2>/dev/null | grep -c '\.ko' || true); rm -rf "$T"
  echo "system_dlkm: modules.load -> $nl modül"
  [ "$nl" -gt 0 ] || { echo "HATA: modules.load boş ya da yok"; exit 1; }
else
  echo "UYARI: içerik kontrol edilemedi (debugfs/fsck.erofs yok)"
fi
