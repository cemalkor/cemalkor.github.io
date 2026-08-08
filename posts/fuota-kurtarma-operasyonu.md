# Mührü Bozmadan: Bir Güvenlik Açığını FUOTA ile Kapatmak

Dün, günün son molasındaydık. Çalışma arkadaşım Semi Avcı'yla kahve alıp muhabbet ediyorduk. Konu yine işti ama masa başında değildik; o mola kafasıyla konuşuyorduk — cümleler daha gevşek, sorular daha "acaba".

Derken aklıma bir şey takıldı ve Semi'ye sordum. Soruyu bitirmeden onun da yüzü değişti. İkimiz aynı anda anladık.

Bir su ve kanalizasyon işletmesi için geliştirdiğimiz uzaktan okumalı su sayacı modülünde bir güvenlik açığı vardı. Ve o modülden 1900 tane çoktan sevk edilmişti.

O an insanın kafasından ne geçiyor, tarif edeyim. Sırasıyla: "yok artık", "acaba yanılıyor muyum", "keşke yanılıyor olsam".

Şunu da not düşeyim: o açığı ne bir test yakaladı, ne bir analiz aracı. İki kişi kahve içerken yakaladı. Molaları küçümsemeyin derim — bazen ekrandan kalkmak, ekrana bakmaktan daha çok iş görüyor.

İyi haber: cihazların hiçbiri henüz kurulmamıştı. Kötü haber: geri çağırdığımızda gelen cihazların yarısına yakını çoktan kutulanmış ve mühürlenmişti.

Bugün öğleden sonra güncellemeye başladık. Akşama kadar tek başıma 160 cihaza FUOTA yaptım ve tek bir mührü bile bozmadım.

## En sevmediğim kod, en çok işime yarayan kod çıktı

Bu projede yazarken içimin en rahat olmadığı kod FUOTA (Firmware Update Over The Air) koduydu.

Sebebi basit: bir güncelleme yarıda kalırsa elinde açılmayan bir cihaz kalır. Tuğla. Üstelik o cihaz artık senin yazılımınla konuşamadığı için ikinci bir şans da yok — kurtarma mekanizmasının kendisi kurtarılmaya muhtaç hale gelir. En çok korktuğum, en çok test ettiğim, en az güvendiğim fonksiyonlar bunlardı.

Dün akşam anladım ki o tereddütlü haftalar, projedeki en kârlı yatırımmış.

Çünkü mühürlü kutu şu demek: elinde kablo var, takacak yer yok. Mührü bozarsan cihaz müşteriye "hiç açılmamış" olarak gidemez; yeniden paketleme, yeniden mühürleme, yeniden sevkiyat ve her adımda taze bir hata ihtimali. FUOTA olmasaydı bu iş şuna dönüşecekti: 1900 kutuyu tek tek aç, tek tek kablola, tek tek geri koy. Onun yerine kutular kapalı kaldı; biz sadece kapağın öbür tarafındaki radyoyla konuştuk.

Henüz kutulanmamış cihazlara ise, üretim programımıza eklediğimiz yeni özelliklerle birlikte güncel firmware'i kablodan yükledik.

![Geri çekilen kutular ve güncellenmeyi bekleyen modüllerin durduğu kasa](posts/gorseller/fuota-kutular.jpg)

## Aynı yazılım, iki bilgisayar, iki ayrı karakter

Bugün beni en çok şaşırtan şey teknik bir tutarsızlık oldu. Aynı uygulama, aynı cihazlar, iki farklı bilgisayar:

- **Harici Bluetooth adaptörü takılı masaüstü** — aktarım gözle görülür şekilde yavaş, ama bağlantı kopması yok denecek kadar az.
- **Dahili Bluetooth'lu dizüstü** — aktarım çok daha hızlı, ama kopma sıklığı masaüstünün açık ara üstünde.

Aynı firmware, aynı oda, aynı mesafe. Değişen tek şey karşı taraftaki radyo ve onu süren yığın.

Nedenini henüz ölçmedim. İlk şüphelim dizüstündeki birleşik Wi-Fi/Bluetooth yongası: 2.4 GHz bandını, çoğu tasarımda da anteni Wi-Fi ile paylaşıyor, ikisi havaya sırayla çıkıyor. Harici adaptörde ise radyo da anten de yalnız çalışıyor. Ama bu şimdilik sadece bir hipotez — dizüstünde Wi-Fi'ı kapatıp aynı testi tekrarlamadan bir şey iddia etmeyeceğim. Ölçtüğümde buraya yazacağım.

![İki ekranda paralel yürüyen FUOTA oturumları; her iki uygulama da "Aygıt yazılımı güncelleniyor" ekranında](posts/gorseller/fuota-masaustu.jpg)

Ofisteki testle sahadaki işin farkı da tam olarak burada ortaya çıkıyor. Bir bağlantının karakterini yalnız senin ürettiğin cihaz belirlemiyor; karşısına oturttuğun her donanım onu yeniden şekillendiriyor.

## Hata ve insan

Mola bitip masaya döndüğümüzdeki ilk hissim korkuydu. Onu bastıran şey teknik bir çözüm değil, genel müdürümüz Tahsin Önkol'un tepkisi oldu: hataya odaklanıp öfkelenmek yerine çözüme odaklanmamız için önümüzü açtı. Bir hatanın en hızlı kapanma yolu, onu bulan kişinin söylemekten çekinmemesidir. Dün bunu yaşayarak gördüm.

İkinci şey, Semi'nin geliştirdiği üretim ve FUOTA uygulamasıydı. Semi'nin yazdığı yazılımların ortak bir özelliği var: hızlı olurlar. Bunu sonradan bakılacak bir detay olarak değil, baştan konulan bir tasarım hedefi olarak görüyor. Bu uygulamada da firmware'i olabildiğince hızlı yükleyebilmek için epey uğraştı — ve bugün o uğraşın karşılığını aldık. 160 cihazı tek başıma güncelleyebildiysem sebebi, cihaz başına düşen saniyelerin aylar önce kısılmış olması. Bir aracın gerçekten iyi olup olmadığını sekiz saat üst üste kullanınca anlıyorsun; akşam elimde kalan tek şikâyet bel ağrısıydı.

## Çıkardığım ders

Gömülü sistem mühendisliği kusursuz kod yazmak değil. Kusursuzu hedefleyip, hata çıktığında onu telafi edecek yolu sistemin içine baştan koymak.

FUOTA bizim için bir özellik değildi, bir sigortaydı. Dün akşama kadar hiç kullanmamıştık. Bugün ilk kez gerçekten kullandık ve ödedi.

Operasyon devam ediyor. Toplam sayacı ben tutmuyorum ama bugünlük 160'tayım. O 1900 cihaz başka bir şehirde; haftaya oraya gidip onları da yerinde güncelleyeceğiz.
