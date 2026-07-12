# STM32'de Düşük Güç Tüketimi: uA Avına Nereden Başlamalı?

Pille yıllarca çalışması gereken bir cihazda (örneğin bir akıllı su sayacında) güç tüketimi bir "optimizasyon" değil, tasarımın kendisidir. Bu yazıda kendi kullandığım temel yaklaşımı özetliyorum.

## 1. Önce güç bütçesi çıkar

Kod yazmadan önce bir tabloya şunları dök:

| Durum | Akım | Süre / gün |
|---|---|---|
| Stop mode | ~2 uA | %99.9 |
| Ölçüm (ADC + RTC) | ~1 mA | saniyeler |
| Radyo iletimi | 40–120 mA | milisaniyeler |

Toplam pil ömrünü belirleyen şey neredeyse her zaman **uyku akımı** ve **iletim sıklığıdır**, CPU hızı değil.

## 2. Stop mode'da akımı yükselten klasik hatalar

- Yüzer (floating) bırakılan GPIO pinleri — kullanılmayan pinleri analog moda alın
- Uyumadan önce kapatılmayan çevre birimleri (ADC, UART, timer clock'ları)
- Harici sensörlerin pull-up dirençleri üzerinden sızan akım
- Debug (SWD) bağlantısı takılıyken ölçüm yapmak — gerçek değeri asla göstermez

## 3. Ölçmeden inanma

```c
// Uyumadan önceki tipik temizlik
HAL_ADC_DeInit(&hadc);
__HAL_RCC_GPIOA_CLK_DISABLE();
HAL_PWR_EnterSTOPMode(PWR_LOWPOWERREGULATOR_ON, PWR_STOPENTRY_WFI);
```

Kod ne kadar doğru görünürse görünsün, son söz her zaman ampermetrenindir. Ben ölçümleri güç profili çıkarabilen bir kaynak/analizör ile yapıyorum; ani radyo darbelerini multimetre yakalayamaz.

Sorularınız olursa iletişim bölümünden yazabilirsiniz.
