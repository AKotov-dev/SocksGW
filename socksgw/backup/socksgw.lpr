program socksgw;

{$mode objfpc}{$H+}

uses
 {$IFDEF UNIX}
  cthreads,
     {$ENDIF} {$IFDEF HASAMIGA}
  athreads,
     {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms,
  Unit1,
  update_trd,
  portscan_trd;

{$R *.res}

begin
  RequireDerivedFormResource := True;
  Application.Title:='SocksGW v0.9';
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
