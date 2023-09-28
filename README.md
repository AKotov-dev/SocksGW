# SocksGW
SocksGW - это инструмент, позволяющий превратить обычный компьютер с двумя сетевыми картами в интернет-шлюз Socks5. Он является связующим звеном между [XRayGUI](https://github.com/AKotov-dev/XRayGUI) и [DNSCrypt-GUI](https://github.com/AKotov-dev/dnscrypt-gui). Таким образом шлюз состоит из 3 основных пакетов. Удобнее ставить его в разрыв между существующим роутером и LAN.
  
![](https://github.com/AKotov-dev/SocksGW/blob/main/ScreenShots/SocksGW.png)
  
Готовая сборка (флешка-шлюз) для установки на будущий роутер [находится здесь](https://drive.google.com/drive/folders/1DVoUumM_CQ10da0Vqtu98uvrMbBk9DmM?usp=sharing) (RU/EN).  
После загрузки с флешки запустите ярлык на Рабочем Столе `Установить на жесткий диск`. После установки/перезагрузки пароль по умолчанию `ghbdtn` (слово `привет` в английской раскладке).

Вы можете настроить шлюз самостоятельно, с нуля. Для этого установите пакеты [dnscrypt-gui](https://github.com/AKotov-dev/dnscrypt-gui/releases), [xraygui](https://github.com/AKotov-dev/XRayGUI/releases) и [socksgw](https://github.com/AKotov-dev/SocksGW/releases). Обсуждение [здесь](https://linuxforum.ru/viewtopic.php?pid=471777#p471777).

**Зависимости:** systemd gtk2 polkit xraygui dnscrypt-gui dnsmasq iptables x11vnc sshd (nm-lite для MATE)  
**Рабочий каталог:** /etc/socksgw; скрипт построения шлюза: /etc/socksgw/tun2socks.sh  
  
Перед настройкой шлюза **SocksGW** сделайте следующее:
  
1. Настройте сетевые карты WAN и LAN средствами ОС: WAN до провайдера, LAN в локальную сеть
2. Проверьте доступ к сети Интернет
3. Запустите DNSCrypt-GUI, укажите порт "2053" и `Рестарт`: 127.0.0.1:2053
4. Запустите XRayGUI, загрузите конф вашего VPS и `Старт`: 127.0.0.1:1080
 
После этого введите настройки SocksGW и нажмите `APPLY`  
  
![](https://github.com/AKotov-dev/SocksGW/blob/main/ScreenShots/Screenshot1.png)  
  
Перезагрузите компьютер клиента, чтобы он принял новые настройки шлюза.  
  
![](https://github.com/AKotov-dev/SocksGW/blob/main/ScreenShots/SocksGW-Control.png)  
  
**UPD-v0.2:** Доступ из LAN по VNC:5900, пароль по умолчанию - `socksgw`. Подключение через [TigerVNC](https://sourceforge.net/projects/tigervnc/).  
Если планируется использование SocksGW на компе без монитора, для доступа по VNC без тормозов потребуется [заглушка](https://www.youtube.com/results?search_query=%D1%8D%D0%BC%D1%83%D0%BB%D1%8F%D1%82%D0%BE%D1%80+%D0%BC%D0%BE%D0%BD%D0%B8%D1%82%D0%BE%D1%80%D0%B0).  
  
**UPD-v0.3:** Доступ из LAN по SSH:22; дефолтные логин `marsik`, пароль `ghbdtn`. Подключение через [FileZilla](https://filezilla-project.org/).  
  
**UPD-v0.4:** Автологин после первого запуска SocksGW (`APPLY`).  
  
**UPD-v0.5:** Переход на Network Manager, улучшение построителя конфигураций и сервисов запуска.  
  
**UPD-v0.6:** Исправлено Network Manager + sshd; Версия для финального тестирования.  
  
**UPD-v0.7:** Релиз в реальной эксплуатации. Полёт нормальный.
  
### Структурная схема:
LAN->DNS->DNSMASQ->DNSCrypt-Proxy->WAN  
LAN->Остальное->IPTABLES+ROUTE->Tun2Socks+Xray->WAN

Всем безопасного вэб-серфинга, друзья.

### Использованы материалы:
[XRay-Core, Project X](https://github.com/XTLS/Xray-core)  
[tun2socks - powered by gVisor TCP/IP stack. Author: xjasonlyu](https://github.com/xjasonlyu/tun2socks)  
[Wi-Fi через прокси без шума и пыли (почти). Автор: alevor](https://habr.com/ru/articles/697916/)  
[DNSCrypt: первый опыт использования. Автор: kanyck](https://forum.calculate-linux.org/t/dnscrypt/9375)
