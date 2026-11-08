# device/xiaomi/flute — saf AOSP 16

Redmi Pad 2 Pro (flute, SM7635/volcano). Vendor API 34 + Android 16 framework + GKI android14-6.1.

## Yapı
- boot: GKI `Image` (fetch-gki.sh), ramdisk yok
- init_boot: AOSP generic ramdisk
- vendor_boot: stock DTB + 330 vendor modülü + first-stage fstab, kaynaktan derlenir
- recovery: ayrı recovery_a/b bölümü (fastbootd burada)
- system_dlkm: Google flatten imajı (stock yerleşimi), kernel ile aynı build
- vendor / odm / vendor_dlkm: stock blob'lardan derlenir (vendor tree)
- sepolicy: çalışma anında stock vendor politikası; device tree'de etiketleme için tip tanımları
  + stock vendor'ın beklediği 50 Qualcomm system_ext tipi ve 34.0 eşlemesi
- config.fs / vendor.prop / odm.prop / vintf: stock'tan üretildi
- dtbo: stock (kırpılmış)

## Derleme
    # AOSP 16 ağacında:
    git clone https://github.com/mahirburaktekin/device_xiaomi_flute device/xiaomi/flute
    git clone https://github.com/mahirburaktekin/vendor_xiaomi_flute vendor/xiaomi/flute
    source build/envsetup.sh
    lunch aosp_flute-bp4a-userdebug   # release tag'inde: ls build/release/release_configs/
    m

## Kernel güncelleme (isteğe bağlı)
    ./fetch-gki.sh      # en güncel android14-6.1 GKI: Image + system_dlkm.img
    git add prebuilt/gki && git commit -m "flute: GKI güncelle" && git push

## Notlar
- vbmeta `--flags 3`: bring-up için verity kapalı. Boot ettikten sonra kaldır.
- Dosyalar eksikse build kasıtlı olarak `$(error ...)` verir.
