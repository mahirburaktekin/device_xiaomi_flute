# device/xiaomi/flute

Redmi Pad 2 Pro (**flute**) için device tree.
Hedef: **PixelOS, Android 16** (Lineage tabanlı ROM'larda da çalışır).

| | |
|---|---|
| SoC | Qualcomm SM7635 (`volcano`, Snapdragon 7s Gen 4), yalnızca arm64 |
| Kernel | Google GKI `android14-6.1` prebuilt (`prebuilt/gki`, şu an 6.1.176) |
| Vendor | Stock HyperOS **OS3.0.303.0.WPWMIXM** blob'ları, vendor API **34** (Android 14) |
| Bölümler | Virtual A/B (lz4), dinamik bölümler, ayrı `recovery_a/b` |
| Dosya sistemleri | system/vendor/product/odm/vendor_dlkm: EROFS · system_dlkm: ext4 · userdata: F2FS |

Vendor tree: [vendor_xiaomi_flute](https://github.com/mahirburaktekin/vendor_xiaomi_flute)

## Branch'ler

| Branch | Ne için |
|---|---|
| `sixteen` | Ana branch. Derleme düzeltmeleri burada. |
| `bringup` | `sixteen` + **geçici** test ayarları (adb onaysız, SELinux permissive, privapp izinleri log modu) + temiz vendor fstab. İlk test build'leri için. |
| `overlays` | `sixteen` + framework overlay'i (120 Hz, masaüstü modu). Teste bekliyor. |

Vendor tree'de karşılıkları: `main` ve `bringup`.

## Derleme

```bash
# Gerekli: git-lfs, repo sync'ten ÖNCE kurulu olmalı (GMS APK'ları LFS'te)
sudo apt install git-lfs unzip zip && git lfs install

# PixelOS 16 kaynağında:
git clone -b sixteen https://github.com/mahirburaktekin/device_xiaomi_flute device/xiaomi/flute
git clone -b main    https://github.com/mahirburaktekin/vendor_xiaomi_flute vendor/xiaomi/flute

. build/envsetup.sh
lunch custom_flute-bp4a-userdebug
m pixelos -j$(nproc)
```

İlk tam derleme: ~16 çekirdek / 32 GB RAM + swap önerilir (Soong analizi ~29 GB RAM görüyor).

## Yapı

| Ne | Nereden |
|---|---|
| `boot` | GKI `Image` (ramdisk yok) |
| `init_boot` | AOSP generic ramdisk |
| `vendor_boot` | Stock DTB + 330 vendor modülü + first-stage fstab |
| `dtbo` | Stock |
| `system_dlkm` | GKI `system_dlkm.img` (kernel ile aynı build olmalı) |
| `vendor`, `odm`, `vendor_dlkm` | Stock blob'lardan derlenir (vendor tree) |
| VINTF | `vintf/manifest_volcano.xml` (stock) + `vintf/device_framework_matrix.xml` (stock vendor/odm HAL'leri için) |
| Sepolicy | Cihazda **stock vendor politikası** çalışır. Burada sadece etiketleme tipleri ve stock vendor'ın beklediği 49 Qualcomm system_ext tipi var. |
| Props / config.fs | Stock'tan (`vendor.prop`, `odm.prop`, `config.fs`) |

## Bilinmesi gerekenler

- **Vendor 34 ↔ Android 16:** Build vendor'u 202504 sanıyor (`BOARD_SEPOLICY_VERS` zorunlu). Bu yüzden:
  - `manifest_volcano.xml` içinde sepolicy sürümü yazılmaz (build doldurur).
  - Qualcomm system_ext tiplerinin 34.0 eşlemesi device tree'de değil, vendor tree'deki `vendor_sepolicy.cil` sonunda.
- **Lineage'a özel:** `vendor_persist_camera_prop` Lineage sepolicy'sinde tanımlı olduğu için burada yok. Saf AOSP'de geri eklenmeli.
- **Bölüm boyutları onluk** yazılmalı (`check_partition_sizes` onaltılık kabul etmiyor).
- **AVB:** `vbmeta --flags 3` (doğrulama kapalı, bring-up için). Kararlı hale gelince kaldırılacak.
- `BUILD_BROKEN_DUP_RULES` hâlâ açık: stock blob'ların bir kısmı kaynak modüllerle aynı yola kuruluyor. Temizliği yapılacak.

## Kernel güncelleme

```bash
./fetch-gki.sh   # android14-6.1'in en güncel GKI'si: Image + system_dlkm.img
git add prebuilt/gki && git commit -m "flute: GKI güncelle"
```

`Image` ve `system_dlkm.img` aynı build'den olmalı (modül imzası). `vendor_boot` içindeki
`zram.ko`/`zsmalloc.ko` da aynı build'den alınmalı (vendor tree, `bringup`).

GKI dosyaları eksikse build bilerek `$(error ...)` verir.
