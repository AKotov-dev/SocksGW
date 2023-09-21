unit start_trd;

{$mode objfpc}{$H+}

interface

uses
  Classes, Process, ComCtrls;

type
  ShowLogTRD = class(TThread)
  private

    { Private declarations }
  protected
  var
    Result: TStringList;

    procedure Execute; override;

    procedure StartTrd;
    procedure StopTrd;

  end;

implementation

uses Unit1;

{ TRD }

procedure ShowLogTRD.Execute;
var
  ExProcess: TProcess;
begin
  try //Старт процесса
    Synchronize(@StartTRD);

    FreeOnTerminate := True; //Уничтожить по завершении
    Result := TStringList.Create;

    //Рабочий процесс
    ExProcess := TProcess.Create(nil);

    ExProcess.Executable := 'bash';
    ExProcess.Parameters.Add('-c');

    ExProcess.Parameters.Add('update-grub');

    ExProcess.Options := [poWaitOnExit];
    //, poWaitOnExit (синхронный вывод)

    ExProcess.Execute;

   finally
    Synchronize(@StopTRD);
    Result.Free;
    ExProcess.Free;
    Terminate;
  end;
end;

{ БЛОК ОТОБРАЖЕНИЯ ЛОГА }

//Старт вывода
procedure ShowLogTRD.StartTRD;
begin
  MainForm.ProgressBar1.Visible:=True;
  MainForm.ProgressBar1.Style:=pbstMarquee;
end;

//Стоп вывода
procedure ShowLogTRD.StopTRD;
begin
   MainForm.ProgressBar1.Style:=pbstNormal;
   MainForm.ProgressBar1.Visible:=False;
end;

end.
