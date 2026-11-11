#!/usr/bin/env bash
# Stok kernel'in GKI build'inden system_dlkm.img'yi indirir (Image zaten commit'li).
# Image ve system_dlkm aynı build'den olmak zorunda (modül imzası).
# Bağımsız çalışır (AOSP ağacı gerekmez). Yeni kernel istediğinde bir kere çalıştır,
# prebuilt/gki/ içeriğini commit'le. Build sırasında çalıştırılmaz.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$HERE/prebuilt/gki" && cd "$HERE/prebuilt/gki"
AVBTOOL="$(mktemp -d)/avbtool.py"
curl -fsSL "https://android.googlesource.com/platform/external/avb/+/refs/heads/main/avbtool.py?format=TEXT" | base64 -d > "$AVBTOOL"

# Stok kernel ile aynı GKI build'i (OS3.0.303.0.WPWMIXM boot.img: 6.1.138-android14-11-g0c3d559bcd85-ab14529422).
# prebuilt/gki/Image stok boot.img'den çıkarıldı; system_dlkm aynı build'den Google CI'dan indirilir.
# Başka bir build kullanma: vendor modülleri ve stok system_dlkm bu kernel'e göre.
BID=14529422
STOCK_SHA=97b2c53022e8c0bd0b279c4c592a196126a6eb0a93647c2957b39dcd5f2dc1c9
TAG="6.1.138-android14-11-g0c3d559bcd85-ab$BID"

BASE=https://ci.android.com/builds/submitted/$BID/kernel_aarch64/latest/raw
curl -fL -o /tmp/gki-Image "$BASE/Image"
[ "$(sha256sum /tmp/gki-Image | cut -d' ' -f1)" = "$STOCK_SHA" ] || { echo "HATA: CI Image stok kernel ile aynı değil"; exit 1; }
cmp -s /tmp/gki-Image Image || { echo "HATA: prebuilt/gki/Image stok kernel değil"; exit 1; }
curl -fL -o system_dlkm.img "$BASE/system_dlkm.img"

# vbmeta'ya girebilmesi için hashtree footer (imzasız, descriptor vbmeta'da)
python3 "$AVBTOOL" add_hashtree_footer --image system_dlkm.img \
    --partition_name system_dlkm --hash_algorithm sha256 --do_not_generate_fec

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
