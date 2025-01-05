# Envanter Yönetim Sistemi

Bu proje, küçük ve orta ölçekli işletmeler için kullanıcı dostu bir **envanter yönetimi** çözümü sunar. Sistem, ürünlerin stok durumunu takip etmeyi, raporlar oluşturmayı ve kullanıcı yönetimini kolaylaştırır.

---

# İçerik
Proje hakkında kısa bir kullanım videosu: https://youtu.be/raD48f5SSd8 

---

## Özellikler

- **Kullanıcı Girişi ve Yönetimi:**
  - Kullanıcılar için giriş ve kayıt seçenekleri.
  - Yönetici ve normal kullanıcı rolleri.
  - Yönetici şifre doğrulama mekanizması.

- **Ürün Yönetimi:**
  - Ürün ekleme, listeleme, güncelleme ve silme.
  - Stok ve fiyat bilgilerini düzenleme.
  - Ürün bazlı detaylı raporlama.

- **Raporlama ve Yedekleme:**
  - Stok seviyesi analizi: Azalan ve fazla stoklu ürünlerin listelenmesi.
  - Sistem dosyalarını yedekleme.
  - Hata kayıtlarının görüntülenmesi.

- **Kullanıcı Dostu Arayüz:**
  - **Zenity** kullanılarak grafiksel kullanıcı arayüzü ile kolay kullanım.
  - Dinamik bilgi ve hata mesajları.

---

## Gereksinimler

Bu projenin çalışması için aşağıdaki bileşenler gereklidir:
- **Linux/Unix Tabanlı İşletim Sistemi**
- **Bash Shell** (4.0+)
- **Zenity**: Kullanıcı arayüzü oluşturmak için gerekli kütüphane.

Zenity kurulumu için:
```bash
sudo apt-get install zenity  # Debian/Ubuntu tabanlı sistemler için
sudo yum install zenity      # CentOS/Fedora tabanlı sistemler için
```

---

## Nasıl Çalıştırılır?

- **Projenin dosyalarını klonlayın**
```bash
git clone https://github.com/MATEXIEL/InventoryManagementBashScript.git
cd envanter-yonetimi
```

- **Script'e çalıştırma izni verin ve çalıştırın**
```bash
chmod +x ./envanter_yonetimi.sh
./envanter_yonetimi.sh
```

---

- **Giriş veya Kayıt İşlemleri:**
  - Kullanıcı adı ve şifre ile giriş yapabilir veya yeni bir kullanıcı kaydedebilirsiniz.
  - Yönetici girişi yapmak için varsayılan şifre: admin123

---

- **Dosya Yapısı**
  - **envanter_yonetimi.sh**: Ana script dosyası.
  - **depo.csv**: Ürün bilgilerinin saklandığı dosya.
  - **kullanici.csv**: Kullanıcı bilgilerini içeren dosya.
  - **log.csv**: Program çalıştırılırken ortaya çıkan hataların kayıtları.

---

- **Örnek Kullanım**
  - Yeni ürün ekleme:
    - Yönetici olarak giriş yapın.
    - Ana menüden "Ürün Ekleme" seçeneğini seçin.
    - Ürün bilgilerini doldurun.
  - Stok seviyesi raporu:
    - Ana menüden "Rapor Al" seçeneğini seçin.
    - Stokta azalan ve stokta fazlaca bulunan ürünleri görüntüleyin.
