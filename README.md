# SocksGW
SocksGW - это инструмент, позволяющий превратить обычный компьютер с двумя сетевыми картами в интернет-шлюз Socks5. Он является связующим звеном между [XRayGUI](https://github.com/AKotov-dev/XRayGUI) и [DNSCrypt-GUI](https://github.com/AKotov-dev/dnscrypt-gui). Таким образом шлюз состоит из 3 основных пакетов. Удобнее ставить его в разрыв между существующим роутером и LAN.
  
![](https://github.com/AKotov-dev/SocksGW/blob/main/ScreenShots/SocksGW.png)
  
Готовая сборка (флешка-шлюз) для установки на будущий роутер [находится здесь](https://drive.google.com/drive/folders/1DVoUumM_CQ10da0Vqtu98uvrMbBk9DmM?usp=sharing) (RU/EN).  
+ `v1.0` - Финальное тестирование; релиз стабилен
+ `v0.9` + драйверы rtl8188eu и контроль WiFi (AP)
+ `v0.8.3` + XRayGUI: байпас доменных зон (cn, ru, by, ir, ...)
+ `v0.8.1` + XRayGUI: простой генератор конфигураций `XTLS-Reality` Клиент-Сервер
  
После загрузки с флешки запустите ярлык на Рабочем Столе `Установить на жесткий диск`. После установки/перезагрузки пароль по умолчанию `ghbdtn` (слово `привет` в английской раскладке).

## Самостоятельное изготовление
Вы можете настроить шлюз самостоятельно, с нуля. Для этого установите пакеты [dnscrypt-gui](https://github.com/AKotov-dev/dnscrypt-gui/releases), [xraygui](https://github.com/AKotov-dev/XRayGUI/releases) и [socksgw](https://github.com/AKotov-dev/SocksGW/releases).

**Зависимости:** systemd gtk2 polkit xraygui dnscrypt-gui dnsmasq iptables x11vnc sshd (nm-lite для MATE)  
**Рабочий каталог:** /etc/socksgw; скрипт построения шлюза: /etc/socksgw/tun2socks.sh  
  
Перед настройкой шлюза **SocksGW** сделайте следующее:
  
1. Настройте интерфейсы WAN и LAN через Network Manager (DNS 127.0.0.1)
2. Можно сразу добавить точку WiFi (AP): NM - Добавить Соединение - WiFi
3. Перевключите NM и проверьте доступ к сети Интернет, например: `ping ya.ru`
4. Запустите DNSCrypt-GUI, укажите порт "2053" и `Рестарт`: 127.0.0.1:2053
5. Запустите XRayGUI, загрузите конф вашего VPS и `Старт`: 127.0.0.1:1080
 
После этого введите настройки SocksGW и нажмите `APPLY`  
  
![](https://github.com/AKotov-dev/SocksGW/blob/main/ScreenShots/ScreenShot11.png)  
  
Перезагрузите компьютер клиента, чтобы он принял новые настройки шлюза.  
  
![](https://github.com/AKotov-dev/SocksGW/blob/main/ScreenShots/ScreenShot12.png)  
  
**UPD-v0.2:** Доступ из LAN по VNC:5900, пароль по умолчанию - `socksgw`. Подключение через [TigerVNC](https://sourceforge.net/projects/tigervnc/).  
Если планируется использование SocksGW на компе без монитора, для доступа по VNC без тормозов потребуется [заглушка](https://www.youtube.com/results?search_query=%D1%8D%D0%BC%D1%83%D0%BB%D1%8F%D1%82%D0%BE%D1%80+%D0%BC%D0%BE%D0%BD%D0%B8%D1%82%D0%BE%D1%80%D0%B0).  
  
**UPD-v0.3:** Доступ из LAN по SSH:22; дефолтные логин `marsik`, пароль `ghbdtn`. Подключение через [FileZilla](https://filezilla-project.org/).  
**UPD-v0.4:** Автологин после первого запуска SocksGW (`APPLY`).  
**UPD-v0.5:** Переход на Network Manager, улучшение построителя конфигураций и сервисов запуска.  
**UPD-v0.6:** Исправлено Network Manager + sshd; Версия для финального тестирования.  
**UPD-v0.7:** Релиз в реальной эксплуатации. Полёт нормальный.  
**UPD-v0.8:** Уточнение английского перевода.  
**UPD-v0.9** Контроль WiFi (AP), улучшение конфигурации NetworkManager и запуска x11vnc.  
**UPD-v1.0** Финальное тестирование. Релиз стабилен.  
  
### Структурная схема
LAN->DNS->DNSMASQ->DNSCrypt-Proxy->WAN  
LAN->Остальное->IPTABLES+ROUTE->Tun2Socks+Xray->WAN

#### Примечание
1. Если мини-пк имеет только один ethernet-порт, в настройках SocksGW указываем LAN=WAN. В этом случае мини-пк будет обслуживать LAN через Wi-Fi, т.е. являться точкой доступа (AP) для ваших ПК, смартфонов и т.д.
2. Длина пароля при настройке точки доступа (Wi-Fi AP) должна быть не менее 8 символов
3. Рабочий каталог SocksGW: `/etc/socksgw`; Основной скрипт: `/etc/socksgw/tun2socks.sh`
4. Сервисы запуска SocksGW:
    + /etc/systemd/system/tun2socks.service - запуск основного скрипта
    + /etc/systemd/system/tun2socks-update.service - обновление tun2socks
    + /etc/systemd/system/x11vnc.service - удаленный доступ по VNC
5. При старте `XRayGUI` и `SocksGW` запускается проверка обновлений `xray-core` и `tun2socks` соответственно; обновляйтесь.


Всем безопасного вэб-серфинга, друзья.

#### Использованы материалы
[XRay-Core, Project X](https://github.com/XTLS/Xray-core)  
[tun2socks - powered by gVisor TCP/IP stack. Author: xjasonlyu](https://github.com/xjasonlyu/tun2socks)  
[Wi-Fi через прокси без шума и пыли (почти). Автор: alevor](https://habr.com/ru/articles/697916/)  
[DNSCrypt: первый опыт использования. Автор: kanyck](https://forum.calculate-linux.org/t/dnscrypt/9375)
