unit wifi_scan_trd;

{$mode objfpc}{$H+}

interface

uses
  Classes, Forms, Controls, SysUtils, Process, Graphics;

type
  WiFiScan = class(TThread)
  private

    { Private declarations }
  protected
  var
    ResultStr: TStringList;

    procedure Execute; override;
    procedure ShowStatus;

  end;

implementation

uses unit1;

{ TRD }

procedure WiFiScan.Execute;
var
  ScanProcess: TProcess;
begin
  FreeOnTerminate := True; //Уничтожать по завершении

  while not Terminated do
    try
      ResultStr := TStringList.Create;

      ScanProcess := TProcess.Create(nil);

      ScanProcess.Executable := 'bash';
      ScanProcess.Parameters.Add('-c');
      ScanProcess.Options := [poUsePipes, poWaitOnExit];

      ScanProcess.Parameters.Add(
        'nmcli con show --active | grep wifi | awk ' + '''' + '{print $NF}' + '''');

      ScanProcess.Execute;

      ResultStr.LoadFromStream(ScanProcess.Output);
      Synchronize(@ShowStatus);

      Sleep(1000);
    finally
      ResultStr.Free;
      ScanProcess.Free;
    end;
end;

//Отображение статуса
procedure WiFiScan.ShowStatus;
begin
  with MainForm do
  begin
    if ResultStr.Count <> 0 then
      Shape2.Brush.Color := clAqua
    else
      Shape2.Brush.Color := clSilver;

    Shape2.Repaint;
  end;
end;

end.
