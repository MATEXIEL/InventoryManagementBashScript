#!/bin/bash

# Kullanıcı yönetici mi değil mi kontrolünün sağlandığı fonksiyon
yetkili_kontrol() {
    ROLE=$(awk -F ',' -v USERNAME="$USERNAME" '$1 == USERNAME {print $4}' kullanici.csv)
    if [ "$ROLE" != "Yönetici" ]; then
        zenity --error --text="Yalnızca yöneticiler bu işlemi yapabilir!" --title="Hata" 2>> log.csv
        main_menu $ROLE
    fi
}

# İstenen dosyaların varlık kontrolü ve yoksa oluşturmak için kullanılan fonksiyon
dosya_kontrol() {
    for file in depo.csv kullanici.csv log.csv; do
        if [ ! -f "$file" ]; then
            touch "$file"
            # Progress bar göster
            (
                echo "0"  # Başlangıç
                sleep 0.5
                echo "25"  # Çeyrek
                sleep 0.5
                echo "50"  # Yarıda
                sleep 0.5
                echo "75"  # Üç çeyrek
                sleep 0.5
                echo "100"  # Tamamlandı
            ) | zenity --progress --title="Dosya Oluşturma" --text="$file oluşturuluyor..." --percentage=0 --auto-close 2>> log.csv
            zenity --info --text="$file başarıyla oluşturuldu!" --title="Başarı" 2>> log.csv
        fi
    done
}

# Kullanıcı Giriş ve Kayıt
kullanici_giris() {
    while true; do
        USERNAME=$(zenity --entry --title="Kullanıcı Girişi" --text="Kullanıcı adını girin:" --extra-button="Çıkış" 2>> log.csv)
        if [ "$?" -eq 1 ]; then
            exit 0  # Çıkış yap
        fi
        if [ -z "$USERNAME" ]; then
            zenity --error --text="Kullanıcı adı boş olamaz!" --title="Hata" 2>> log.csv
            continue
        fi

        PASSWORD=$(zenity --entry --title="Kullanıcı Girişi" --text="Şifreyi girin:" --hide-text --extra-button="Çıkış" 2>> log.csv)
        if [ "$?" -eq 1 ]; then
            exit 0  # Çıkış yap
        fi

        # Kullanıcıyı kontrol et
        PASSWORD_CHECK=$(awk -F ',' -v USERNAME="$USERNAME" '$1 == USERNAME {print $5}' kullanici.csv)
        if [ -n "$PASSWORD_CHECK" ]; then
            # Şifreyi kontrol et
            ATTEMPTS=0
            while [ "$ATTEMPTS" -lt 3 ]; do
                if [ "$PASSWORD" == "$PASSWORD_CHECK" ]; then
                    ROLE=$(awk -F ',' -v USERNAME="$USERNAME" '$1 == USERNAME {print $4}' kullanici.csv)
                    zenity --info --text="Giriş başarılı!" --title="Başarı" 2>> log.csv
                    main_menu $ROLE
                    return
                else
                    ATTEMPTS=$((ATTEMPTS + 1))
                    if [ "$ATTEMPTS" -ge 3 ]; then
                        zenity --error --text="Şifrenizi 3 kez yanlış girdiniz. Hesabınız donduruldu!" --title="Hata" 2>> log.csv
                        grep "$USERNAME" kullanici.csv > dondurulan_kullanicilar.csv && sed -i "/$USERNAME/d" kullanici.csv
                        return
                    fi
                    PASSWORD=$(zenity --entry --title="Kullanıcı Girişi" --text="Şifreyi tekrar girin:" --hide-text --extra-button="Çıkış" 2>> log.csv) 
                    if [ "$?" -eq 1 ]; then
                        exit 0  # Çıkış yap
                    fi
                fi
            done
        else
            zenity --error --text="Kullanıcı bulunamadı. Lütfen kaydınızı yapın." --title="Hata" 2>> log.csv
            kullanici_kayit
        fi
    done
}

# Kullanıcı Kaydı
kullanici_kayit() {
    while true; do
        USERNAME=$(zenity --entry --title="Kullanıcı Kaydı" --text="Kullanıcı adı girin:" --extra-button="Çıkış" 2>> log.csv)
        if [ "$?" -eq 1 ]; then
            exit 0  # Çıkış yap
        fi
        if [ -z "$USERNAME" ]; then
            zenity --error --text="Kullanıcı adı boş olamaz!" --title="Hata" 2>> log.csv
            continue
        fi

        # Kullanıcı adı kontrol edilir
        USER_EXISTS=$(awk -F ',' -v USERNAME="$USERNAME" '$1 == USERNAME' kullanici.csv)
        if [ -n "$USER_EXISTS" ]; then
            zenity --error --text="Bu kullanıcı adı zaten var. Farklı bir kullanıcı adı seçin." --title="Hata" 2>> log.csv
            continue
        fi

        # İsim ve soyisim istenir
        FIRSTNAME=$(zenity --entry --title="İsim ve Soyisim" --text="İsim girin:" --extra-button="Çıkış" 2>> log.csv)
        if [ "$?" -eq 1 ]; then
            exit 0  # Çıkış yap
        fi
        LASTNAME=$(zenity --entry --title="İsim ve Soyisim" --text="Soyisim girin:" --extra-button="Çıkış" 2>> log.csv)
        if [ "$?" -eq 1 ]; then
            exit 0  # Çıkış yap
        fi

        # Kullanıcı rolü seçilir
        ROLE=$(zenity --list --title="Rol Seçimi" --column="Rol" "Normal Kullanıcı" "Yönetici" --extra-button="Çıkış" 2>> log.csv)
        if [ "$?" -eq 1 ]; then
            exit 0  # Çıkış yap
        fi
        if [ "$ROLE" == "Yönetici" ]; then
            # Yönetici şifrei kontrolü yapılır
            ADMIN_PASSWORD=$(zenity --entry --title="Yönetici Girişi" --text="Yönetici şifresini girin:" --hide-text --extra-button="Çıkış" 2>> log.csv)
            if [ "$?" -eq 1 ]; then
                exit 0  # Çıkış yap
            fi
            ADMIN_PASSWORD_CHECK="admin123"  # Yönetici şifresi :)
            ATTEMPTS=0
            while [ "$ATTEMPTS" -lt 3 ]; do
                if [ "$ADMIN_PASSWORD" == "$ADMIN_PASSWORD_CHECK" ]; then
                    break
                else
                    ATTEMPTS=$((ATTEMPTS + 1))
                    if [ "$ATTEMPTS" -ge 3 ]; then
                        zenity --error --text="Yönetici şifresi 3 kez yanlış girildi. Normal kullanıcı olarak kaydedileceksiniz." --title="Hata" 2>> log.csv
                        ROLE="Normal Kullanıcı"
                        break
                    fi
                    ADMIN_PASSWORD=$(zenity --entry --title="Yönetici Girişi" --text="Yönetici şifresini tekrar girin:" --hide-text --extra-button="Çıkış" 2>> log.csv)
                    if [ "$?" -eq 1 ]; then
                        exit 0  # Çıkış yap
                    fi
                fi
            done
        fi

        # Kullanıcıdan şifre istenir
        PASSWORD=$(zenity --entry --title="Şifre Belirleme" --text="Bir şifre oluşturun:" --hide-text --extra-button="Çıkış" 2>> log.csv)
        if [ "$?" -eq 1 ]; then
            exit 0  # Çıkış yap
        fi

        # Kullanıcı bilgileri kaydedilir
        echo "$USERNAME,$FIRSTNAME,$LASTNAME,$ROLE,$PASSWORD" >> kullanici.csv
        zenity --info --text="Kayıt başarılı. Giriş yapabilirsiniz." --title="Başarı" 2>> log.csv
        break
    done
}

# Ana Menü
main_menu() {
    ROLE=$1
    if [ "$ROLE" == "Yönetici" ]; then
        CHOICE=$(zenity --list --title="Ana Menü" --column="Seçenekler" \
            "Ürün Ekle" "Ürün Listele" "Ürün Güncelle" "Ürün Sil" \
            "Rapor Al" "Kullanıcı Yönetimi" "Program Yönetimi" "Çıkış" 2>> log.csv)
    else
        CHOICE=$(zenity --list --title="Ana Menü" --column="Seçenekler" \
            "Ürün Listele" "Rapor Al" "Çıkış" 2>> log.csv)
    fi

    case $CHOICE in
        "Ürün Ekle") urun_ekle ;;
        "Ürün Listele") urun_listele ;;
        "Ürün Güncelle") urun_guncelle ;;
        "Ürün Sil") urun_sil ;;
        "Rapor Al") rapor_al ;;
        "Kullanıcı Yönetimi") kullanici_yonetimi ;;
        "Program Yönetimi") program_yonetimi ;;
        "Çıkış") cikis ;;
    esac
}

# Ürün Ekleme
urun_ekle() {
    yetkili_kontrol "urun_ekle_islemi"  # Yönetici kontrolü
    
    while true; do
        # Ürün adı alınır
        PRODUCT_NAME=$(zenity --entry --title="Ürün Ekle" --text="Ürün adını girin:" 2>> log.csv)

        # Ürün adı, depo.csv'de zaten varsa, tekrar ürün adı istenir
        if grep -q "$PRODUCT_NAME" depo.csv; then
            zenity --error --text="Bu ürün zaten mevcut. Farklı bir ürün adı girin." --title="Hata" 2>> log.csv
            continue
        fi

        # Stok miktarı ve birim fiyatı alınır
        STOCK=$(zenity --entry --title="Ürün Ekle" --text="Stok miktarını girin:" --entry-text="0" 2>> log.csv)
        PRICE=$(zenity --entry --title="Ürün Ekle" --text="Birim fiyatını girin:" --entry-text="0" 2>> log.csv)

        # Stok ve fiyat kontrolü yapılır
        if [ "$STOCK" -lt 0 ]; then
            zenity --error --text="Stok miktarı sıfırdan küçük olamaz." --title="Hata" 2>> log.csv
            continue
        fi

        if [ "$PRICE" -lt 0 ]; then
            zenity --error --text="Birim fiyatı sıfırdan küçük olamaz." --title="Hata" 2>> log.csv
            continue
        fi

        # Ürün numarası atanır (son eklenen ürünün numarası alınıp 1 artırılarak)
        LAST_PRODUCT_NUM=$(tail -n 1 depo.csv | cut -d ',' -f1)
        if [ -z "$LAST_PRODUCT_NUM" ]; then
            PRODUCT_NUM=1  # Eğer dosyada hiç ürün yoksa, ilk numara 1 olacak
        else
            PRODUCT_NUM=$((LAST_PRODUCT_NUM + 1))  # Son ürüne 1 ekle
        fi

        # Eklenen ürün dosyaya kaydedilir
        echo "$PRODUCT_NUM,$PRODUCT_NAME,$STOCK,$PRICE" >> depo.csv

        (
            echo "0"  # Başlangıç yüzdesi
            sleep 0.5
            echo "25"  # Yarıya gelindi
            sleep 0.5
            echo "50"  # Yarıda
            sleep 0.5
            echo "75"  # Yarıdan sonra
            sleep 0.5
            echo "100"  # Tamamlandı
        ) | zenity --progress --title="Ürün Ekleme" --text="Ürün ekleniyor..." --percentage=0 --auto-close 2>> log.csv

        zenity --info --text="Ürün başarıyla eklendi!" --title="Başarı" 2>> log.csv

        # İşleme devam edilip edilmeyeceği sorulur
        RESPONSE=$(zenity --question --title="Devam Et" --text="Başka bir ürün eklemek ister misiniz?" --no-wrap 2>> log.csv)
        if [ "$RESPONSE" != "true" ]; then
            break
        fi
    done

    main_menu $ROLE
}


# Ürün Listeleme
urun_listele() {

    # Dosya yolu belirtilmesi: Depo dosyasının bulunduğu yolu doğru belirttiğimizden emin olalım
    DEPO_PATH="./depo.csv"

    # Depo dosyasıurun_listelendaki tüm ürünleri al ve metin formatında göster
    if [ ! -f "$DEPO_PATH" ]; then
        zenity --error --text="Depo dosyası bulunamadı: $DEPO_PATH" --title="Hata" 2>> log.csv
        return
    fi

    # Geçici bir dosya oluşturun
    TEMP_FILE=$(mktemp)

    # Dosyadaki verileri oku ve geçici dosyaya yaz
    while read -r line; do
        PRODUCT_NUM=$(echo "$line" | cut -d',' -f1)
        PRODUCT_NAME=$(echo "$line" | cut -d',' -f2)
        STOCK=$(echo "$line" | cut -d',' -f3)
        PRICE=$(echo "$line" | cut -d',' -f4)

        # Eğer herhangi bir alan eksikse, bu satırı atla
        if [ -z "$PRODUCT_NUM" ] || [ -z "$PRODUCT_NAME" ] || [ -z "$STOCK" ] || [ -z "$PRICE" ]; then
            continue
        fi

        # Geçici dosyaya yaz
        echo -e "Ürün No: $PRODUCT_NUM" >> "$TEMP_FILE"
        echo -e "Adı: $PRODUCT_NAME" >> "$TEMP_FILE"
        echo -e "Stok Miktarı: $STOCK" >> "$TEMP_FILE"
        echo -e "Birim Fiyatı: $PRICE" >> "$TEMP_FILE"
        echo -e "--------------------------------------" >> "$TEMP_FILE"
    done < "$DEPO_PATH"

    # Eğer ürün listesi boşsa, kullanıcıya uyarı göster
    if [ ! -s "$TEMP_FILE" ]; then
        zenity --info --text="Depo dosyasındaki ürünler listelenemedi veya dosya boş." --title="Bilgi" 2>> log.csv
        rm -f "$TEMP_FILE"  # Geçici dosyayı sil
        main_menu $ROLE
    fi

    # Ürünleri Zenity penceresinde göster
    zenity --text-info --title="Ürün Listeleme" --filename="$TEMP_FILE" 2>> log.csv

    rm -f "$TEMP_FILE"

    main_menu $ROLE
}
# Ürün Güncelleme
urun_guncelle() {
    yetkili_kontrol "urun_guncelle_islemi"  # Yönetici kontrolü

    while true; do
        # Ürün adı ya da numarası istenir
        PRODUCT_SEARCH=$(zenity --entry --title="Ürün Güncelle" --text="Güncellemek istediğiniz ürünün adını ya da numarasını girin:" 2>> log.csv)

        # Ürünü aranır
        PRODUCT_LINE=$(grep -E "^$PRODUCT_SEARCH," depo.csv)
        if [ -z "$PRODUCT_LINE" ]; then
            zenity --error --text="Ürün bulunamadı. Lütfen doğru bir ürün adı veya numarası girin." --title="Hata" 2>> log.csv
            continue
        fi

        # Ürün bilgileri alınır
        PRODUCT_NUM=$(echo $PRODUCT_LINE | cut -d ',' -f1)
        PRODUCT_NAME=$(echo $PRODUCT_LINE | cut -d ',' -f2)
        STOCK=$(echo $PRODUCT_LINE | cut -d ',' -f3)
        PRICE=$(echo $PRODUCT_LINE | cut -d ',' -f4)

        # Yeni stok ve fiyat bilgileri istenir
        NEW_STOCK=$(zenity --entry --title="Ürün Güncelle" --text="Yeni stok miktarını girin (mevcut stok: $STOCK):" --entry-text="$STOCK" 2>> log.csv)
        NEW_PRICE=$(zenity --entry --title="Ürün Güncelle" --text="Yeni birim fiyatını girin (mevcut fiyat: $PRICE):" --entry-text="$PRICE" 2>> log.csv)

        # Yeni stok ve fiyat kontrolü
        if [ "$NEW_STOCK" -lt 0 ] || [ "$NEW_PRICE" -lt 0 ]; then
            zenity --error --text="Stok ve fiyat sıfırdan küçük olamaz." --title="Hata" 2>> log.csv
            continue
        fi

        # Ürün güncellenir
        sed -i "s/^$PRODUCT_NUM,$PRODUCT_NAME,$STOCK,$PRICE$/$PRODUCT_NUM,$PRODUCT_NAME,$NEW_STOCK,$NEW_PRICE/" depo.csv

        (
            echo "0"  # Başlangıç
            sleep 0.5
            echo "25"  # İlk adım
            sleep 0.5
            echo "50"  # Yarıya gelindi
            sleep 0.5
            echo "75"  # Neredeyse tamam
            sleep 0.5
            echo "100"  # Tamamlandı
        ) | zenity --progress --title="Ürün Güncelleme" --text="Ürün güncelleniyor..." --percentage=0 --auto-close 2>> log.csv

        zenity --info --text="Ürün başarıyla güncellendi!" --title="Başarı" 2>> log.csv

        # İşleme devam edilip edilmeyeceği sorulur
        RESPONSE=$(zenity --question --title="Devam Et" --text="Başka bir ürün güncellemek ister misiniz?" --no-wrap 2>> log.csv)
        if [ "$RESPONSE" != "true" ]; then
            break
        fi
    done

    main_menu $ROLE
}


# Ürün Silme
urun_sil() {
    yetkili_kontrol "urun_silme_islemi"  # Yönetici kontrolü

    while true; do
        # Ürün numarası ya da adı istenir
        PRODUCT_SEARCH=$(zenity --entry --title="Ürün Silme" --text="Silmek istediğiniz ürünün adını ya da numarasını girin:" 2>> log.csv)

        # Ürünü aranır
        PRODUCT_LINE=$(grep -E "^$PRODUCT_SEARCH," depo.csv)
        if [ -z "$PRODUCT_LINE" ]; then
            zenity --error --text="Ürün bulunamadı. Lütfen doğru bir ürün adı veya numarası girin." --title="Hata" 2>> log.csv
            continue
        fi

        # Ürün bilgileri alınır
        PRODUCT_NUM=$(echo $PRODUCT_LINE | cut -d ',' -f1)
        PRODUCT_NAME=$(echo $PRODUCT_LINE | cut -d ',' -f2)

        # Silme onayı istenir
        zenity --question --title="Silme Onayı" --text="Ürün $PRODUCT_NAME (Ürün Numarası: $PRODUCT_NUM) silinsin mi?" --no-wrap 2>> log.csv
        RESPONSE=$?

        if [ "$RESPONSE" -ne 0 ]; then
            zenity --info --text="Silme işlemi iptal edildi." --title="İptal" 2>> log.csv
            continue
        fi

        # Ürün silinir
        sed -i "/^$PRODUCT_NUM,$PRODUCT_NAME/d" depo.csv

        (
            echo "0"  # Başlangıç
            sleep 0.5
            echo "25"  # İlk adım
            sleep 0.5
            echo "50"  # Yarıya gelindi
            sleep 0.5
            echo "75"  # Neredeyse tamam
            sleep 0.5
            echo "100"  # Tamamlandı
        ) | zenity --progress --title="Ürün Silme" --text="Ürün siliniyor..." --percentage=0 --auto-close 2>> log.csv

        zenity --info --text="Ürün başarıyla silindi!" --title="Başarı" 2>> log.csv

        # İşleme devam edilip edilmeyeceği sorulur
        zenity --question --title="Devam Et" --text="Başka bir ürün silmek ister misiniz?" --no-wrap 2>> log.csv
        RESPONSE=$?

        if [ "$RESPONSE" -ne 0 ]; then
            break
        fi
    done

    main_menu $ROLE
}



# Rapor Al
rapor_al() {
    # Stokta azalan ürünler belirlenir
    STOCK_LOW=$(awk -F ',' '$3 < 10' depo.csv)
    STOCK_HIGH=$(awk -F ',' '$3 > 75' depo.csv)

    # Eğer stokta azalan ürün varsa
    if [ ! -z "$STOCK_LOW" ]; then
        LOW_STOCK_PRODUCTS=$(echo "$STOCK_LOW" | while IFS=, read NUM NAME STOCK PRICE CATEGORY; do
            echo "$NAME (Ürün Numarası: $NUM) - Stok Miktarı: $STOCK"
        done)
    else
        LOW_STOCK_PRODUCTS="Stokta azalan ürün bulunmamaktadır."
    fi

    # Eğer stoğu çok olan ürün varsa
    if [ ! -z "$STOCK_HIGH" ]; then
        HIGH_STOCK_PRODUCTS=$(echo "$STOCK_HIGH" | while IFS=, read NUM NAME STOCK PRICE CATEGORY; do
            echo "$NAME (Ürün Numarası: $NUM) - Stok Miktarı: $STOCK"
        done)
    else
        HIGH_STOCK_PRODUCTS="Stokta çok bulunan ürün bulunmamaktadır."
    fi

    # Rapor kullanıcıya gösterilir
    zenity --info --title="Stok Raporu" --text=" 
    Stokta Azalan Ürünler:
    $LOW_STOCK_PRODUCTS

    Stokta Çok Bulunan Ürünler:
    $HIGH_STOCK_PRODUCTS" --width=400 --height=300 2>> log.csv

    main_menu $ROLE
}


# Kullanıcı Yönetimi
yeni_kullanici_ekle() {
    while true; do
        # Kullanıcı bilgileri alınır
        USERNAME=$(zenity --entry --title="Yeni Kullanıcı Ekleme" --text="Kullanıcı Adı:" --width=400 2>> log.csv)
        # Eğer çıkmak istediyse
        if [ -z "$USERNAME" ]; then
            main_menu $ROLE
            return
        fi

        # Kullanıcı adı kontrolü yapılır
        if grep -q "$USERNAME" kullanici.csv; then
            zenity --error --text="Bu kullanıcı adı zaten mevcut. Lütfen farklı bir kullanıcı adı seçin." 2>> log.csv
        else
            NAME=$(zenity --entry --title="Yeni Kullanıcı Ekleme" --text="İsim:" --width=400 2>> log.csv)
            LASTNAME=$(zenity --entry --title="Yeni Kullanıcı Ekleme" --text="Soyisim:" --width=400 2>> log.csv)
            ROLE=$(zenity --list --title="Yeni Kullanıcı Ekleme" --text="Rol Seçin" --radiolist --column="Seç" \
            		  --column="Rol" TRUE "Normal Kullanıcı" FALSE "Yönetici" --width=400 2>> log.csv)
            PASSWORD=$(zenity --entry --title="Yeni Kullanıcı Ekleme" --text="Parola:" --hide-text --width=400 2>> log.csv)

            # Yeni kullanıcı bilgileri dosyaya eklenir
            echo "$USERNAME,$NAME,$LASTNAME,$ROLE,$PASSWORD" >> kullanici.csv
            (
                echo "0"  # Başlangıç
                sleep 0.5
                echo "25"  # İlk adım
                sleep 0.5
                echo "50"  # Yarıya gelindi
                sleep 0.5
                echo "75"  # Neredeyse tamam
                sleep 0.5
                echo "100"  # Tamamlandı
            ) | zenity --progress --title="Kullanıcı Ekleme" --text="Kullanıcı ekleniyor..." --percentage=0 --auto-close 2>> log.csv

            zenity --info --text="Kullanıcı başarıyla eklendi!" 2>> log.csv

            # İşleme devam edilip edilmeyeceği sorulur
            ADD_MORE=$(zenity --question --text="Yeni kullanıcı eklemek ister misiniz?" --width=400 --height=200 2>> log.csv)
            if [ $? -eq 1 ]; then
                break
            fi
        fi
    done
    kullanici_yonetimi
}

kullanicilari_listele() {
    # Kullanıcılar listelenir
    zenity --text-info --title="Kullanıcılar" --filename=kullanici.csv 2>> log.csv

    kullanici_yonetimi
}

kullanici_guncelle() {
    while true; do
        # Kullanıcı adı alınır
        USERNAME=$(zenity --entry --title="Kullanıcı Güncelleme" --text="Güncellenecek Kullanıcı Adı:" --width=400 2>> log.csv)
        
        # Kullanıcı adı bulunmuyorsa:
        if ! grep -q "$USERNAME" kullanici.csv; then
            zenity --error --text="Kullanıcı bulunamadı. Lütfen geçerli bir kullanıcı adı girin." 2>> log.csv
        else
            # Kullanıcı varsa, yeni bilgileri istenir
            NEW_NAME=$(zenity --entry --title="Kullanıcı Güncelleme" --text="Yeni İsim:" --width=400 2>> log.csv)
            NEW_LASTNAME=$(zenity --entry --title="Kullanıcı Güncelleme" --text="Yeni Soyisim:" --width=400 2>> log.csv)
            NEW_ROLE=$(zenity --list --title="Kullanıcı Güncelleme" --text="Yeni Rol Seçin" --radiolist --column="Seç" \ 
            		      --column="Rol" TRUE "Normal Kullanıcı" FALSE "Yönetici" --width=400 2>> log.csv)
            NEW_PASSWORD=$(zenity --entry --title="Kullanıcı Güncelleme" --text="Yeni Parola:" --hide-text --width=400 2>> log.csv)

            # Kullanıcı bilgileri güncellenir
            sed -i "/^$USERNAME,/c\\$USERNAME,$NEW_NAME,$NEW_LASTNAME,$NEW_ROLE,$NEW_PASSWORD" kullanici.csv
            
	    (
                echo "0"  # Başlangıç
                sleep 0.5
                echo "25"  # İlk adım
                sleep 0.5
                echo "50"  # Yarıya gelindi
                sleep 0.5
                echo "75"  # Neredeyse tamam
                sleep 0.5
                echo "100"  # Tamamlandı
            ) | zenity --progress --title="Kullanıcı Güncelleme" --text="Kullanıcı güncelleniyor..." --percentage=0 --auto-close 2>> log.csv

            zenity --info --text="Kullanıcı başarıyla güncellendi!" 2>> log.csv

            # İşlemin tekrar edilip edilmeyeceği sorulur
            UPDATE_MORE=$(zenity --question --text="Başka bir kullanıcı güncellemek ister misiniz?" --width=400 --height=200 2>> log.csv)
            if [ $? -eq 1 ]; then
                break
            fi
        fi
    done
    kullanici_yonetimi
}

kullanici_sil() {
    while true; do
        # Silinecek kullanıcı adı alınır
        USERNAME=$(zenity --entry --title="Kullanıcı Silme" --text="Silinecek Kullanıcı Adı:" --width=400 2>> log.csv)
        
        # Öyle bir kullanıcı bulunmuyorsa:
        if ! grep -q "$USERNAME" kullanici.csv; then
            zenity --error --text="Kullanıcı bulunamadı. Lütfen geçerli bir kullanıcı adı girin." 2>> log.csv
        else
            # Kullanıcı bulunduysa, onay almak için sorulur
            zenity --question --title="Kullanıcı Silme" --text="Bu kullanıcıyı silmek istediğinizden emin misiniz?" --width=400 --height=200 2>> log.csv
            if [ $? -eq 0 ]; then
                # Silme işlemi yapılır
                sed -i "/^$USERNAME,/d" kullanici.csv
                
	        (
            	    echo "0"  # Başlangıç
            	    sleep 0.5
            	    echo "25"  # İlk adım
            	    sleep 0.5
            	    echo "50"  # Yarıya gelindi
            	    sleep 0.5
            	    echo "75"  # Neredeyse tamam
            	    sleep 0.5
            	    echo "100"  # Tamamlandı
                ) | zenity --progress --title="Kullanıcı Silme" --text="Kullanıcı siliniyor..." --percentage=0 --auto-close 2>> log.csv

                zenity --info --text="Kullanıcı başarıyla silindi!" 2>> log.csv

                # İşlemin tekrar edilip edilmeyeceği sorulur
                DELETE_MORE=$(zenity --question --text="Başka bir kullanıcı silmek ister misiniz?" --width=400 --height=200 2>> log.csv)
                if [ $? -eq 1 ]; then
                    break
                fi
            fi
        fi
    done
    kullanici_yonetimi
}

# Kullanıcıyı kurtarma fonksiyonu
kullanici_kurtar() {
  # dondurulan_kullanicilar.csv dosyasındaki kullanıcılar listelenir
  kullanicilar=$(zenity --list --title="Hesabı Dondurulmuş Kullanıcılar" --column="Kullanıcılar" $(cut -d, -f1 dondurulan_kullanicilar.csv 2>> log.csv) 2>> log.csv)
  
  if [ -z "$kullanicilar" ]; then
    zenity --info --text="Hiç kullanıcı seçilmedi." 2>> log.csv
    return
  fi

  # Kullanıcı adı sorulur
  kullanici_ad=$(zenity --entry --title="Kullanıcı Adı" --text="Kurtarmak istediğiniz kullanıcı adını girin:" 2>> log.csv)

  if [ -z "$kullanici_ad" ]; then
    zenity --info --text="Kullanıcı adı girilmedi." 2>> log.csv
    kullanici_kurtar
  fi

  # dondurulan_kullanicilar.csv dosyasında kullanıcı kontrol edilir
  kullanici_bulundu=$(grep "^$kullanici_ad," dondurulan_kullanicilar.csv 2>> log.csv)

  if [ -z "$kullanici_bulundu" ]; then
    zenity --error --text="Kullanıcı bulunamadı: $kullanici_ad" 2>> log.csv
    kullanici_kurtar
  fi

  # Kullanıcı bilgileri görüntülenir
  kullanici_bilgileri=$(echo "$kullanici_bulundu" | cut -d, -f1- 2>> log.csv)
  
  # Kurtarma işlemi için onay alınır
  onay=$(zenity --question --title="Onay" --text="Aşağıdaki kullanıcıyı kurtarmak istediğinizden emin misiniz?\n\n$kullanici_bilgileri" 2>> log.csv)

  if [ $? -eq 0 ]; then
    # Kullanıcı kurtarılır, dondurulan_kullanicilar.csv'den silinir
    sed -i "/^$kullanici_ad,/d" dondurulan_kullanicilar.csv
    
    # Kullanıcı bilgileri kullanici.csv dosyasına eklenir
    echo "$kullanici_bilgileri" >> kullanici.csv

    # Başarı mesajı
    zenity --info --text="Kullanıcı başarıyla kurtarıldı ve 'kullanici.csv' dosyasına eklendi." 2>> log.csv
  else
    zenity --info --text="İşlem iptal edildi." 2>> log.csv
    kullanici_kurtar
  fi
  
  kullanici_yonetimi
}

kullanici_yonetimi() {
    ACTION=$(zenity --list --title="Kullanıcı Yönetimi" --column="İşlem Seç" \
        "Yeni Kullanıcı Ekle" \
        "Kullanıcıları Listele" \
        "Kullanıcı Güncelle" \
        "Kullanıcı Sil" \
        "Kullanıcı Kurtarma" \
        --width=400 --height=300 2>> log.csv)

    case $ACTION in
        "Yeni Kullanıcı Ekle")
            yeni_kullanici_ekle
            ;;
        "Kullanıcıları Listele")
            kullanicilari_listele
            ;;
        "Kullanıcı Güncelle")
            kullanici_guncelle
            ;;
        "Kullanıcı Sil")
            kullanici_sil
            ;;
        "Kullanıcı Kurtarma")
            kullanici_kurtar
            ;;
        *)
            main_menu $ROLE
            ;;
    esac
}

# Program Yönetimi
diskteki_alani_goster() {
    # Dosyaların script dosyasıyla aynı PATH'te (dosya yolu) olduğuna emin olun. Aynı yerde değilse her biri için gerekli dosya yolunu yazın.
    SCRIPT_PATH="./$0"  # Eğer betik aynı dizindeyse
    DEPO_PATH="./depo.csv"
    KULLANICI_PATH="./kullanici.csv"
    LOG_PATH="./log.csv"

    # Dosyaların boyutları alınır.
    SCRIPT_SIZE=$(du -sh "$SCRIPT_PATH" 2>/dev/null | cut -f1)  # Betik dosyasının boyutu
    DEPO_SIZE=$(du -sh "$DEPO_PATH" 2>/dev/null | cut -f1)  # depo.csv dosyasının boyutu
    KULLANICI_SIZE=$(du -sh "$KULLANICI_PATH" 2>/dev/null | cut -f1)  # kullanici.csv dosyasının boyutu
    LOG_SIZE=$(du -sh "$LOG_PATH" 2>/dev/null | cut -f1)  # log.csv dosyasının boyutu

    # Kaplanılan alanlar gösterilir
    TEXT="Script Dosyası: $SCRIPT_SIZE\nDepo Dosyası: $DEPO_SIZE\nKullanıcı Dosyası: $KULLANICI_SIZE\nLog Dosyası: $LOG_SIZE"
    
    zenity --info --title="Diskteki Alanlar" --text="$TEXT" --width=600 --height=400 2>> log.csv

    program_yonetimi
}


diske_yedekle() {
    # Yedekleme işlemi için dosyalar kopyalanır
    {
        cp depo.csv depo_yedek.csv
        sleep 0.5  
        echo "25%" 
        cp kullanici.csv kullanici_yedek.csv
        sleep 0.5
        echo "50%" 
        cp log.csv log_yedek.csv
        sleep 0.5
        echo "75%" 
        sleep 0.5  # Son işlem
        echo "100%" 
    } | zenity --progress --title="Diske Yedekleme" --text="Yedekleme işlemi devam ediyor..." --percentage=0 --auto-close --width=400 --height=200 2>> log.csv

    zenity --info --text="Yedekleme işlemi tamamlandı!" 2>> log.csv

    program_yonetimi
}

hata_kayitlarini_goster() {
    # log.csv dosyasındaki veriler gösterilir
    zenity --text-info --title="Hata Kayıtları" --filename=log.csv 2>> log.csv

    program_yonetimi
}


program_yonetimi() {
    ACTION=$(zenity --list --title="Program Yönetimi" --column="İşlem Seç" \
        "Diskteki Alanı Göster" \
        "Diske Yedekle" \
        "Hata Kayıtlarını Göster" \
        --width=400 --height=300 2>> log.csv)

    case $ACTION in
        "Diskteki Alanı Göster")
            diskteki_alani_goster
            ;;
        "Diske Yedekle")
            diske_yedekle
            ;;
        "Hata Kayıtlarını Göster")
            hata_kayitlarini_goster
            ;;
        *)
            main_menu $ROLE
            ;;
    esac
}

# Çıkış
cikis() {
    zenity --question --title="Çıkış" --text="Çıkmak istediğinize emin misiniz?" --no-wrap 2>> log.csv
    if [ $? -eq 0 ]; then
        exit 0
    else
        main_menu $ROLE
    fi
}

# Başlangıç
dosya_kontrol
while true; do
    KAYIT_OPTION=$(zenity --list --title="Kayıt Olma ve Giriş Yapma" --column="Seçenekler" \
        "Kayıt Ol" "Giriş Yap" "Çıkış" 2>> log.csv)
    
    case $KAYIT_OPTION in
        "Kayıt Ol") kullanici_kayit ;;
        "Giriş Yap") kullanici_giris ;;
        "Çıkış") exit 0 ;;
    esac
done
