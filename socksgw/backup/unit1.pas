unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons,
  ComCtrls, ExtCtrls, IniPropStorage, Process, DefaultTranslator;

type

  { TMainForm }

  TMainForm = class(TForm)
    ProgressBar1: TProgressBar;
    WDisplay: TCheckBox;
    VNCPassEdit: TEdit;
    Label3: TLabel;
    LAN: TComboBox;
    StaticText1: TStaticText;
    WAN: TComboBox;
    IPV6: TCheckBox;
    LAN_IP: TEdit;
    IP_RANGE: TEdit;
    IniPropStorage1: TIniPropStorage;
    Label1: TLabel;
    Label2: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Shape1: TShape;
    ApplyBtn: TSpeedButton;
    StopBtn: TSpeedButton;
    procedure ApplyBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure LANChange(Sender: TObject);
    procedure StopBtnClick(Sender: TObject);
  private

  public

  end;

var
  MainForm: TMainForm;

implementation

uses update_trd, portscan_trd, start_trd;

{$R *.lfm}

{ TMainForm }

procedure TMainForm.FormCreate(Sender: TObject);
var
  i: integer;
  s: ansistring;
  SL: TStringList;
begin
  try
    SL := TStringList.Create;

    MainForm.Caption := Application.Title;
    if not DirectoryExists('/etc/socksgw') then MkDir('/etc/socksgw');
    IniPropStorage1.IniFileName := '/etc/socksgw/socksgw.ini';

    //Список интерфейсов
    RunCommand('/bin/bash', ['-c',
      'ip -br a | grep -v -E "lo|tun2socks" | cut -f1 -d" " | tr "\n" ";"'], s);

    //Разделяем два пришедших значения
    SL.Delimiter := ';';
    SL.StrictDelimiter := True;
    SL.DelimitedText := Trim(s);

    for i := 0 to SL.Count - 2 do
      WAN.Items.Append(SL[i]);

    LAN.Items.Assign(WAN.Items);
  finally
    SL.Free;
  end;
end;

//Apply
procedure TMainForm.ApplyBtnClick(Sender: TObject);
var
  k: ansistring;
  S: TStringList;
  FShowLogTRD: TThread;
begin
  try
    //Создаём пускач /etc/socksgw/socksgw.sh
    S := TStringList.Create;
    S.Add('#!/bin/bash');
    S.Add('');
    S.Add('#Интерфейсы; tun2socks - gw');
    S.Add('wan=' + WAN.Text);
    S.Add('lan=' + LAN.Text);
    S.Add('#-----------------//----------------');
    S.Add('');
    S.Add('#Протокол IPv6 On/Off');
    if IPV6.Checked then
    begin
      S.Add('sysctl -w net.ipv6.conf.all.disable_ipv6=0');
      S.Add('sysctl -w net.ipv6.conf.default.disable_ipv6=0');
      S.Add('sysctl -w net.ipv6.conf.lo.disable_ipv6=0');
    end
    else
    begin
      S.Add('sysctl -w net.ipv6.conf.all.disable_ipv6=1');
      S.Add('sysctl -w net.ipv6.conf.default.disable_ipv6=1');
      S.Add('sysctl -w net.ipv6.conf.lo.disable_ipv6=1');
    end;
    S.Add('');
    S.Add('#Включаем форвардинг пакетов IPv4');
    S.Add('sysctl -w net.ipv4.ip_forward=1');
    S.Add('sysctl -w net.ipv4.conf.all.rp_filter=1');
    S.Add('');
    S.Add('#Очистка iptables');
    S.Add('iptables -F; iptables -X');
    S.Add('iptables -t nat -F; iptables -t nat -X');
    S.Add('iptables -t mangle -F; iptables -t mangle -X');
    S.Add('');
    S.Add('#Очищаем таблицу с дефолтным маршрутом для tun2socks');
    S.Add('ip rule del fwmark 3 lookup 300 &> /dev/null');
    S.Add('#Удаляем интерфейс tun2socks');
    S.Add('ip link delete dev tun2socks &> /dev/null');
    S.Add('');
    S.Add('#Всё в ACCEPT');
    S.Add('iptables -P INPUT ACCEPT; iptables -P OUTPUT ACCEPT; iptables -P FORWARD ACCEPT');
    S.Add('');
    S.Add('#Разрешаем lo и уже установленные соединения');
    S.Add('iptables -A INPUT -i lo -j ACCEPT');
    S.Add('iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT');
    S.Add('');
    S.Add('#Секция маскардинга');
    S.Add('iptables -A FORWARD -i $wan -o $lan -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT');
    S.Add('iptables -A FORWARD -i $lan -o $wan -j ACCEPT');
    S.Add('iptables -t nat -A POSTROUTING -o $wan -j MASQUERADE');
    S.Add('');
    S.Add('if [ "$1" != "stop" ]; then');
    S.Add('#Создаём интерфейс tun2socks с привязкой к серверу socks5');
    S.Add('tun2socks-linux-amd64 -device tun://tun2socks -proxy socks5://127.0.0.1:1080 &');
    S.Add('#Ждём появления tun2socks (5 сек)');
    S.Add('i=0; while [[ -z $(ip -br a | grep tun2socks) ]]; do sleep 1');
    S.Add('((i++)); if [[ $i == 5 ]]; then echo "tun2socks: Interface error!"; exit 1; fi; done');
    S.Add('#Поднимаем tun2socks и даём ip/mask');
    S.Add('ip link set tun2socks up');
    S.Add('i=0; while [[ $(ip -br a | grep tun2socks | awk ' + '''' +
      '{print $2}' + '''' + ') == DOWN ]]; do sleep 1');
    S.Add('((i++)); if [[ $i == 5 ]]; then echo "tun2socks: Interface error!"; exit 1; fi; done');
    S.Add('ip addr add 10.2.0.2/32 dev tun2socks');
    S.Add('');
    S.Add('#Создаём цепочку для марков');
    S.Add('iptables -t mangle -N tun2socks');
    S.Add('#Отправляем в неё всё, кроме DNS из $lan в прокси/tun2socks');
    S.Add('#iptables -t mangle -I PREROUTING -i $lan -j MARK --set-mark 3');
    S.Add('iptables -t mangle -I PREROUTING -i $lan -p udp -m multiport ! --dport 53,5900 -j MARK --set-mark 3');
    S.Add('iptables -t mangle -I PREROUTING -i $lan -p tcp -m multiport ! --dport 53,5900 -j MARK --set-mark 3');
    S.Add('');
    S.Add('#Отправляем https трафик в прокси');
    S.Add('#iptables -t mangle -A OUTPUT -p tcp --dport 80 -j MARK --set-mark 3');
    S.Add('#iptables -t mangle -A OUTPUT -p tcp -m multiport --dport 443 -j MARK --set-mark 3');
    S.Add('');
    S.Add('#Создаём таблицу маршрутизации');
    S.Add('ip route add default dev tun2socks table 300');
    S.Add('ip rule add fwmark 3 lookup 300');
    S.Add('  else');
    S.Add('#Очищаем таблицу с дефолтным маршрутом');
    S.Add('ip rule del fwmark 3 lookup 300 &> /dev/null');
    S.Add('#Удаляем интерфейс SOCKS5');
    S.Add('ip link delete dev tun2socks &> /dev/null');
    S.Add('fi');

    S.SaveToFile('/etc/socksgw/tun2socks.sh');
    RunCommand('/bin/bash', ['-c', 'chmod +x /etc/socksgw/tun2socks.sh'], k);

    // /etc/dnsmasq.conf
    S.Clear;

    S.Add('#Авторитетный DHCP сервер');
    S.Add('dhcp-authoritative');
    S.Add('');
    S.Add('#Слушать на интерфейсах lan+lo');
    S.Add('interface=' + LAN.Text);
    S.Add('listen-address=127.0.0.1,' + LAN_IP.Text);
    S.Add('#Привязать интерфейс, другим не отвечать');
    S.Add('bind-interfaces');
    S.Add('');
    S.Add('#Не использовать /etc/resolv.conf');
    S.Add('no-resolv');
    S.Add('');
    S.Add('#Форвардинг DNS-запросов на DNSCrypt-Proxy: 127.0.0.1:2053');
    S.Add('server=127.0.0.1#2053');
    S.Add('');
    S.Add('#Отдать параметры клиенту');
    S.Add('dhcp-option=option:router,' + LAN_IP.Text);
    S.Add('dhcp-option=option:dns-server,' + LAN_IP.Text);
    S.Add('');
    S.Add('#DHCP: Диапазон выдачи IP-адресов');
    S.Add('dhcp-range=' + IP_RANGE.Text);
    S.Add('');
    S.Add('#Отключить DHCP_INFO-PROXY для Windows 7+');
    S.Add('dhcp-option=252,"\n"');
    S.Add('');
    S.Add('#Настройки кеша DNS');
    S.Add('cache-size=10000');
    S.Add('no-negcache');

    S.SaveToFile('/etc/dnsmasq.conf');

    //VNC /etc/systemd/system/x11vnc.service
    if Trim(VNCPassEdit.Text) = '' then VNCPassEdit.Text := 'socksgw';

    S.Clear;
    S.Add('[Unit]');
    S.Add('Description=Start x11vnc at startup');
    S.Add('After=graphical.target multi-user.target');
    S.Add('');
    S.Add('[Service]');
    S.Add('Type=simple');
    S.Add('ExecStart=/usr/bin/x11vnc -auth guess -forever -loop -noxdamage -repeat -passwdfile /etc/socksgw/x11vnc.pass -rfbport 5900 -shared -listen ' + LAN_IP.Text);
    S.Add('');
    S.Add('[Install]');
    S.Add('WantedBy=multi-user.target');

    S.SaveToFile('/etc/systemd/system/x11vnc.service');

    //---Отключить дисплей (экспериментальная опция, нужен тест работы с VNC!)
    RunCommand('/bin/bash', ['-c', 'grep "nokmsboot" /etc/default/grub'], k);
    if WDisplay.Checked then
    begin
      if Trim(k) = '' then
      begin
        RunCommand('/bin/bash', ['-c', 'sed -i ' + '''' +
          's/noiswmd/noiswmd nokmsboot/g' + '''' + ' /etc/default/grub'], k);
        FShowLogTRD := ShowLogTRD.Create(False);
        FShowLogTRD.Priority := tpNormal;
      end;
    end
    else
    begin
      if Trim(k) <> '' then
      begin
        RunCommand('/bin/bash', ['-c', 'sed -i ' + '''' +
          's/noiswmd nokmsboot/noiswmd/g' + '''' + ' /etc/default/grub'], k);
        FShowLogTRD := ShowLogTRD.Create(False);
        FShowLogTRD.Priority := tpNormal;
      end;
    end;

    if WDisplay.Checked then
    begin
      S.Clear;
      S.Add('Section "Device"');
      S.Add('      Identifier      "Configured Video Device"');
      S.Add('      Driver          "vesa"');
      S.Add('      Option "ConnectedMonitor" "CRT,CRT"');
      S.Add('EndSection');
      S.Add('');
      S.Add('Section "Monitor"');
      S.Add('      Identifier      "Configured Monitor"');
      S.Add('EndSection');
      S.Add('');
      S.Add('Section "Screen"');
      S.Add('      Identifier      "Default Screen"');
      S.Add('      Monitor         "Configured Monitor"');
      S.Add('      Device          "Configured Video Device"');
      S.Add('EndSection');
      S.Add('');
      S.SaveToFile('/etc/X11/xorg.conf');
    end
    else
      DeleteFile('/etc/X11/xorg.conf');

    //--------

    //Старт dnamsq/tun2socks/x11vnc
    Application.ProcessMessages;
    RunCommand('/bin/bash', ['-c', 'echo "' + VNCPassEdit.Text +
      '"> /etc/socksgw/x11vnc.pass; systemctl enable dnsmasq tun2socks x11vnc; systemctl restart dnsmasq tun2socks x11vnc'], k);
  finally
    S.Free;
  end;
end;

procedure TMainForm.FormShow(Sender: TObject);
var
  S: ansistring;
  FUpdateThread: TThread;
  FPortScanThread: TThread;
begin
  IniPropStorage1.Restore;

  //Ширина-Высота формы
  MainForm.Width := 10 + Label5.Width + 100 + ApplyBtn.Width + 10;
  MainForm.Height := 10 + IP_RANGE.Top + IP_RANGE.Height + 5 +
    ProgressBar1.Height + StaticText1.Height;

  //Читаем параметры из конфигов
  //LAN
  if RunCommand('/bin/bash', ['-c',
    'grep "^lan=" /etc/socksgw/tun2socks.sh | cut -f2 -d"="'], S) then
    LAN.Text := Trim(S);
  //WAN
  if RunCommand('/bin/bash', ['-c',
    'grep "^wan=" /etc/socksgw/tun2socks.sh | cut -f2 -d"="'], S) then
    WAN.Text := Trim(S);

  //LAN_IP
  if RunCommand('/bin/bash', ['-c',
    'grep "^listen-address=" /etc/dnsmasq.conf | cut -f2 -d","'], S) then
    LAN_IP.Text := Trim(S);

  //IP_RANGE
  if RunCommand('/bin/bash', ['-c',
    'grep "^dhcp-range=" /etc/dnsmasq.conf | cut -f2 -d"="'], S) then
    IP_RANGE.Text := Trim(S);

  //IPv6 (On/Off)
  if RunCommand('/bin/bash', ['-c',
    'grep "net.ipv6.conf.all" /etc/socksgw/tun2socks.sh | cut -f2 -d"="'], S) then
    if Trim(S) = '0' then
      IPV6.Checked := True
    else
      IPV6.Checked := False;

  //Withot Display (Experimental)
  if RunCommand('/bin/bash', ['-c', 'grep "nokmsboot" /etc/default/grub'], S) then
    if Trim(S) <> '' then
      WDisplay.Checked := True
    else
      WDisplay.Checked := False;

  {if FileExists('/etc/X11/xorg.conf') then WDisplay.Checked := True
  else
    WDisplay.Checked := False;}

  //VNC_PASSWORD
  if RunCommand('/bin/bash', ['-c', 'cat /etc/socksgw/x11vnc.pass'], S) then
    VNCPassEdit.Text := Trim(S);

  //Запуск потока проверки состояния tun2socks
  FPortScanThread := PortScan.Create(False);
  FPortScanThread.Priority := tpNormal;

  //Поток проверки обновлений tun2socks
  FUpdateThread := CheckUpdate.Create(False);
  FUpdateThread.Priority := tpNormal;
end;

procedure TMainForm.LANChange(Sender: TObject);
var
  s: ansistring;
begin
  //Список интерфейсов
  RunCommand('/bin/bash', ['-c',
    // 'ip a | grep ^[[:digit:]] | cut -f2 -d":" | tr -d " " | tr "\n" ";"'], s);
    'ip -br a | grep ' + LAN.Text + ' | awk ' + '''' + '{print $3}' +
    '''' + '| cut -f1 -d"/"'], s);
  LAN_IP.Text := Trim(S);
end;

//Stop tun2socks GW
procedure TMainForm.StopBtnClick(Sender: TObject);
var
  k: ansistring;
begin
  Application.ProcessMessages;
  RunCommand('/bin/bash', ['-c',
    'systemctl disable tun2socks; systemctl stop tun2socks'], k);
end;


end.
