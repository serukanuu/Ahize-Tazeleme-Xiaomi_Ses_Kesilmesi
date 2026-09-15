# Ahize Tazeleme Sistemi (Earpiece Audio Fix & Monitor)

Android cihazlarda (özellikle agresif arka plan yönetimine sahip sistemlerde) VoLTE veya normal telefon görüşmeleri sırasında ahize sesinin aniden kesilmesi, hoparlöre düşmesi veya sessize alınması sorununu çözen **otonom, kendi kendini iyileştiren (self-healing)** bir ses yönlendirme servisidir.

Proje, gücünü doğrudan KernelSU / Magisk altyapısından alır. İhtiyacınıza göre **Windows üzerinden çalışan komut satırı arayüzü (CLI)** ile veya **doğrudan cihaz üzerinden kontrol edilebilen Rootlu APK** ile yönetilebilir.

## 🚀 Öne Çıkan Özellikler

* **Rootlu APK Desteği:** Sistemin "ölümsüz" çekirdek mantığıyla birebir aynı çalışan, bilgisayara ihtiyaç duymadan doğrudan telefon üzerinden tek tuşla servisi yönetebileceğiniz, kayıtları izleyebileceğiniz yerleşik Android uygulaması (Root yetkisi gerektirir).
* **Watchdog (Ölümsüz Motor):** İster script ister APK üzerinden çalışsın; sistemdeki `logd` servisi çökse, log tamponu sıfırlansa veya cihaz düşük bellek (LMK) durumuna düşse bile dış sarmal koruması devreye girer. Servis asla ölmez, saniyeler içinde kendini yeniden ayağa kaldırır.
* **Sıfır Batarya Tüketimi:** "Blocking I/O" mantığıyla çalışır. Telefon boşta veya beklemedeyken CPU kullanmaz (%0). Sadece arama geldiğinde logcat üzerinden uyanıp devreye girer.
* **Akıllı Algılama:** Görüşme ahize dışına (Bluetooth kulaklık veya hoparlör) aktarıldığında durumu algılar, zorunlu yönlendirmeyi durdurup uykuya geçer.
* **Gelişmiş Windows Paneli:** Bilgisayar başındayken kurulum, kaldırma ve pürüzsüz canlı izleme işlemlerini tek bir `.bat` dosyasından yapmanızı sağlayan profesyonel arayüz.

## 📂 Dosya Yapısı

* `AhizeTazeleme.apk` - Cihaz üzerinden bilgisayarsız yönetim sağlayan root yetkili Android uygulaması.
* `AHIZE.bat` - Tüm sistemi bilgisayar üzerinden yöneten ana Windows kontrol paneli.
* `ahize_tazele.sh` - Cihazın arka planında (veya APK içinde) çalışan çekirdek kabuk betiği.
* `canli.ps1` - PowerShell tabanlı, sistemi ve çağrı durumunu anlık (2 saniyede bir) renkli olarak raporlayan canlı izleme monitörü.
* `tani.sh` & `durdur.sh` - Anlık ses durumu/süreç raporlarını toplayan ve sistemi güvenle uyutan teşhis/yönetim araçları.

## 🛠️ Gereksinimler

1. **Root Erişimi:** Cihazda KernelSU (KSU) veya Magisk kurulu olmalıdır (Script sürümü `/data/adb/service.d/` dizinini, APK sürümü ise doğrudan root kabuğunu kullanır).
2. **Platform Tools (Sadece PC Sürümü İçin):** Windows üzerinden kullanım için bilgisayarınızda ADB kurulu ve USB Hata Ayıklama aktif olmalıdır.

## ⚙️ Kurulum ve Kullanım

Kullanım senaryonuza göre iki farklı yöntemden birini seçebilirsiniz:

### Yöntem 1: Rootlu APK ile (Önerilen / Bağımsız Kullanım)
1. Paketteki `AhizeTazeleme.apk` dosyasını cihazınıza kopyalayıp kurun.
2. Uygulamayı açtığınızda ekrana gelen **Root (Superuser) izni** isteğini onaylayın.
3. Uygulama arayüzü üzerinden servisi başlatabilir, durdurabilir ve sistem loglarını canlı olarak cihazınızın ekranından takip edebilirsiniz.

### Yöntem 2: Windows Paneli ile (Geliştirici / PC Üzerinden)
1. Cihazınızı USB kablosuyla bilgisayara bağlayın.
2. Klasör içindeki `AHIZE.bat` dosyasını çalıştırın.
3. Menüden **[2] Kur / güncelle ve başlat** seçeneğini tuşlayarak ölümsüz servisi cihazınıza entegre edin.
4. **[1] Canlı Durum Ekranı**'na girerek cihazdaki görüşmeleri, servisin anlık durumunu ve tazeleme kayıtlarını ESC tuşuyla çıkılabilen profesyonel bir ekrandan izleyebilirsiniz.

## ⚠️ Önemli Notlar / Optimizasyon
* **Pil Tasarrufu:** Sistem kök yetkilerle çalışsa da, Xiaomi/HyperOS gibi agresif arayüzlerde APK'nın veya terminal süreçlerinin pil optimizasyonundan muaf tutulması (Kısıtlanmadı / Unrestricted) önerilir.
* **Log Rotasyonu:** Betik, kendi ürettiği log dosyasının şişmesini engellemek için her 60 döngüde bir dosyayı otomatik kırparak disk alanını korur.

---
*Endüstriyel seviyede kararlılık hedeflenerek tasarlanmıştır.*
