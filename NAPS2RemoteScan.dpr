program NAPS2RemoteScan;

uses
  Vcl.Forms,
  main in 'main.pas' {Form1};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'NAPS2 Remote Scan server';
  Application.CreateForm(TForm1, Form1);

 if (ParamCount>0) and (ParamStr(1)='hide') then
    Application.Minimize;

  Application.Run;
end.
