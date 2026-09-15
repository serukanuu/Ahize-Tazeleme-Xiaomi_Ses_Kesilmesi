# ahize-tazeleme_sesinizkesilmesin
# Ahize Tazeleme Sistemi (Earpiece Audio Fix & Monitor)

Android cihazlarda (özellikle agresif arka plan yönetimine sahip sistemlerde) VoLTE veya normal telefon görüşmeleri sırasında ahize sesinin aniden kesilmesi, hoparlöre düşmesi veya sessize alınması sorununu çözen **otonom, kendi kendini iyileştiren (self-healing)** bir ses yönlendirme servisidir.

Proje, gücünü doğrudan KernelSU / Magisk altyapısından alır ve Windows üzerinden çalışan gelişmiş bir komut satırı arayüzü (CLI) ile anlık olarak izlenip yönetilebilir.

## 🚀 Öne Çıkan Özellikler

* **Watchdog (Ölümsüz Motor):** Sistemdeki `logd` servisi çökse, log tamponu sıfırlansa veya sistem düşük bellek durumuna (LMK) düşse bile dış sarmal koruması sayesinde betik asla ölmez, saniyeler içinde kendini yeniden ayağa kaldırır.
* **Sıfır Batarya Tüketimi:** "Blocking I/O" mantığıyla çalışır. Telefon boşta veya beklemedeyken CPU kullanmaz (%0). Sadece arama geldiğinde logcat üzerinden uyanıp devreye girer.
* **Akıllı Algılama:** Görüşme ahize dışına (Bluetooth kulaklık veya hoparlör) aktarıldığında durumu algılar, zorunlu yönlendirmeyi durdurup uykuya geçer.
* **Windows Yönetim Paneli:** Kurulum, kaldırma, tek seferlik teşhis raporu alma ve pürüzsüz canlı izleme işlemlerini tek bir `.bat` dosyasından yapmanızı sağlayan profesyonel arayüz.

## 📂 Dosya Yapısı

* `AHIZE.bat` - Tüm sistemi yöneten ana Windows kontrol paneli.
* `ahize_tazele.sh` - Cihazın `service.d` dizininde çalışan çekirdek (watchdog korumalı) kabuk betiği.
* `canli.ps1` - PowerShell tabanlı, sistemi ve çağrı durumunu anlık (2 saniyede bir) renkli olarak raporlayan canlı izleme monitörü.
* `tani.sh` - Cihaz üzerinden anlık ses durumu ve süreç raporlarını toplayan teşhis aracı.
* `durdur.sh` - Cihazdaki arka plan sürecini güvenle uyutan yardımcı betik.

## 🛠️ Gereksinimler

1. **Root Erişimi:** Cihazda KernelSU (KSU) veya Magisk kurulu olmalıdır (`/data/adb/service.d/` dizini kullanılır).
2. **Platform Tools:** Windows bilgisayarınızda ADB (Android Debug Bridge) kurulu olmalıdır.
3. **USB Hata Ayıklama:** Geliştirici seçeneklerinden aktif edilmiş olmalıdır.

## ⚙️ Kurulum ve Kullanım

1. Cihazınızı USB kablosuyla bilgisayara bağlayın.
2. Klasör içindeki `AHIZE.bat` dosyasını çalıştırın.
3. Menüden **[2] Kur / güncelle ve başlat** seçeneğini tuşlayın.
4. Sistem `ahize_tazele.sh` betiğini otomatik olarak cihazın başlangıç dizinine yükleyecek ve arka planda başlatacaktır (Cihaz her yeniden başladığında servis otomatik devreye girer).

### Kontrol Paneli Seçenekleri:
Paneli kullanarak **[1] Canlı Durum Ekranı**'na girebilir, cihazdaki görüşmeleri, servisin anlık durumunu ve tazeleme kayıtlarını (log akışını) ESC tuşuyla çıkılabilen profesyonel bir ekrandan izleyebilirsiniz. Olası sorunlarda **[6] Teşhis raporu al** seçeneği ile sistemin röntgenini çekebilirsiniz.

## ⚠️ Önemli Notlar / Optimizasyon
* **Pil Tasarrufu:** Sistem modifikasyonu olduğu için cihazınızdaki pil tasarrufu kısıtlamalarına takılmamasına rağmen, terminal/shell süreçlerinin optimizasyon harici (Unrestricted) bırakıldığından emin olmanız önerilir.
* **Log Rotasyonu:** Betik, kendi ürettiği `/data/local/tmp/tazeleme.log` dosyasının şişmesini engellemek için her 60 döngüde bir dosyayı otomatik kırparak disk alanını korur. Dilerseniz `.bat` menüsünden **[7]** ile logları manuel olarak da silebilirsiniz.

---
*Endüstriyel seviyede kararlılık hedeflenerek tasarlanmıştır.*
