# SocksGW
SocksGW - это инструмент, позволяющий превратить обычный компьютер с двумя сетевыми картами в интернет-шлюз SOCKS5. Он является связующим звеном между [XRayGUI](https://github.com/AKotov-dev/XRayGUI) и [DNSCrypt-GUI](https://github.com/AKotov-dev/dnscrypt-gui). Таким образом шлюз состоит из 3 основных деталей/пакетов.

Готовая сборка (флешка), для установки на будущий роутер [находится здесь](https://cloud.mail.ru/public/fVv4/b3Zh1WnaG).

Вы можете настроить шлюз самостоятельно, с нуля. Для этого установите пакеты [dnscrypt-gui](https://github.com/AKotov-dev/dnscrypt-gui/releases), [xraygui](https://github.com/AKotov-dev/XRayGUI/releases) и [socksgw](https://github.com/AKotov-dev/SocksGW/releases)...

Перед настройкой шлюза **SocksGW** сделайте следующее:
  
1. Настройте сетевые карты WAN и LAN средствами ОС: WAN до провайдера, LAN в локальную сеть
2. Проверьте доступ к сети Интернет
3. Запустите DNSCrypt-GUI, укажите порт "2053" и `Старт`: 127.0.0.1:2053
4. Запустите XRayGUI, загрузите конф вашего VPS и `Старт`: 127.0.0.1:1080
 
После этого введите настройки SocksGW и нажмите `APPLY`
![](https://github.com/AKotov-dev/SocksGW/blob/main/Screenshot1.png)

Перезагрузите компьютер клиента, чтобы он принял новые настройки шлюза.

Структурная схема:
---
LAN->DNS->DNSMASQ->DNSCrypt-Proxy->WAN  
LAN->Остальное->IPTABLES+ROUTE->Tun2Socks+Xray->WAN

Всем безопасного вэб-серфинга, друзья.

Использованы материалы:
---
[XRay-Core, Project X](https://github.com/XTLS/Xray-core)  
[tun2socks - powered by gVisor TCP/IP stack. Author: xjasonlyu](https://github.com/xjasonlyu/tun2socks)  
[Wi-Fi через прокси без шума и пыли (почти). Автор: alevor](https://habr.com/ru/articles/697916/)  
[DNSCrypt: первый опыт использования. Автор: kanyck](https://forum.calculate-linux.org/t/dnscrypt/9375)
