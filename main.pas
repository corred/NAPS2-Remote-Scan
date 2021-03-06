unit main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, IdContext, IdCustomHTTPServer,
  IdBaseComponent, IdComponent, IdCustomTCPServer, IdHTTPServer, ShellApi,
  Vcl.StdCtrls, Vcl.ExtCtrls, Registry;

type
  TForm1 = class(TForm)
    IdHTTPServer1: TIdHTTPServer;
    Label1: TLabel;
    LabeledEdit1: TLabeledEdit;
    Label2: TLabel;
    TrayIcon1: TTrayIcon;
    LabeledEdit2: TLabeledEdit;
    Label3: TLabel;
    Label4: TLabel;
    Edit1: TEdit;
    Label5: TLabel;
    procedure IdHTTPServer1CommandGet(AContext: TIdContext;
      ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
    procedure FormCreate(Sender: TObject);
    procedure TrayIcon1DblClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    AppPath: string;
    RegFile: TRegIniFile;
    procedure ApplicationMinimize(Sender: TObject);
    procedure apiScan(Params: TStrings; RemoteIP: string);
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.FormCreate(Sender: TObject);
var port: Integer;
begin
 AppPath:=ExtractFilePath(Application.ExeName);
 Application.OnMinimize := ApplicationMinimize;
 RegFile := TRegIniFile.Create('Software\NAPS2RemoteScan');
 LabeledEdit1.Text:=RegFile.ReadString('', 'NAPS2.Console.exe', '');
 port:=RegFile.ReadInteger('', 'Port', 80);
 LabeledEdit2.Text:=IntToStr(port);

 IdHTTPServer1.DefaultPort:=port;
 IdHTTPServer1.Active:=true;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 RegFile.WriteString('', 'NAPS2.Console.exe', LabeledEdit1.Text);
 RegFile.WriteInteger('', 'Port', StrToInt(LabeledEdit2.Text));
end;

procedure TForm1.ApplicationMinimize(Sender: TObject);
begin
 Hide;
end;

procedure TForm1.TrayIcon1DblClick(Sender: TObject);
begin
 Application.MainForm.Visible := True;
 Application.Restore;
 SetForegroundWindow(Application.MainForm.Handle);
end;


procedure TForm1.IdHTTPServer1CommandGet(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
var
 FileStream: TFileStream;
 Document,RemoteIP: string;
begin
 Document:=ARequestInfo.Document;
 RemoteIP:=ARequestInfo.RemoteIP;
 if RemoteIP = '0:0:0:0:0:0:0:1' then
    RemoteIP:='localhost';

 if Document='/scan' then
    begin
    apiScan(ARequestInfo.Params, RemoteIP);
    Exit;
    end;

 if Document='/' then
     begin
     Document:='/index.html'
     end;

 Document:=AppPath+Document;
 if not FileExists(Document) then
    Exit;


 FileStream:=TFileStream.Create(Document, fmOpenRead);
 AResponseInfo.ContentStream:=FileStream;
end;

function RunAndWait(const ExeName, ParamString: string): Integer;
var
 ShellInfo: TShellExecuteInfo;
 ExitCode: DWORD;
begin
 ShellInfo.cbSize := SizeOf(ShellInfo);
 ShellInfo.fMask := SEE_MASK_NOCLOSEPROCESS;
 ShellInfo.Wnd := HWND_DESKTOP;
 ShellInfo.lpVerb := 'open';
 ShellInfo.lpFile := PChar(ExeName);
 ShellInfo.lpParameters := PChar(ParamString);
 ShellInfo.lpDirectory := PChar(ExtractFilePath(ExeName));
 ShellInfo.nShow := SW_HIDE;
 if not ShellExecuteEx(@ShellInfo) then
   RaiseLastOSError;
 if ShellInfo.hProcess <> 0 then
   try
     WaitForSingleObjectEx(ShellInfo.hProcess, INFINITE, false);
     GetExitCodeProcess(ShellInfo.hProcess, ExitCode);
     Result := ExitCode;
   finally
     CloseHandle(ShellInfo.hProcess);
   end
 else
   Result := -1;
end;

procedure TForm1.apiScan(Params: TStrings; RemoteIP: string);
var ScanUserDocumentsDir: string;
begin
 ScanUserDocumentsDir := AppPath+'Scan\'+RemoteIP;

 //scan
 RunAndWait(LabeledEdit1.Text, '-o "'+ScanUserDocumentsDir+'\scanned$(nnn).jpg"')
end;

end.
