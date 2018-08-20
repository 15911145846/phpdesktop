unit ufrmMain;

interface

uses
  SysUtils,
  Classes,
  Controls, Forms, SkinData, DynamicSkinForm,
  uCEFChromium,
  StdCtrls, uframeChrome, uCEFv8Handler, uCEFApplication, uCEFConstants;

type
  TfrmMain = class(TForm)
    spSkinData1: TspSkinData;
    frameChrome1: TframeChrome;
    DSF: TspDynamicSkinForm;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  private
    { Private declarations }
    // ������ҳ����Ϊ����ֱ�Ӽ���PHP��
    procedure loadMainConfig();

  protected

  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

procedure CreateGlobalCEFApp;

implementation

uses
  unConfig, ufrmSplash, ufrmModal, unV8Extension;
{$R *.dfm}

// phpf������

procedure create_php_server(); stdcall; external 'server_php.dll';

procedure php_server_start(iPort: Integer); stdcall; external 'server_php.dll';

procedure php_server_stop(); stdcall; external 'server_php.dll';

procedure free_php_server(); stdcall; external 'server_php.dll';

// abs���ݿ������

procedure create_db_server(); stdcall; external 'server_db.dll';

procedure db_server_start(iPort: Integer); stdcall; external 'server_db.dll';

procedure db_server_stop(); stdcall; external 'server_db.dll';

procedure free_db_server(); stdcall; external 'server_db.dll';

procedure GlobalCEFApp_OnWebKitInitializedEvent;
begin
  TCefRTTIExtension.Register('app', TV8Extension);
end;

procedure CreateGlobalCEFApp;
var
  strFlashPath: string;
begin
  GlobalCEFApp := TCefApplication.Create;
  GlobalCEFApp.OnWebKitInitialized := GlobalCEFApp_OnWebKitInitializedEvent;

  GlobalCEFApp.Locale := 'zh-CN';
  strFlashPath := unConfig.FAppPath + 'PepperFlash';
  if DirectoryExists(strFlashPath) then
    GlobalCEFApp.CustomFlashPath := strFlashPath
  else
    GlobalCEFApp.FlashEnabled := True;
  GlobalCEFApp.EnableGPU := False;
  GlobalCEFApp.DisableWebSecurity := True;
//    GlobalCEFApp.MuteAudio := True;//������ᵼ��flash����û������
//  GlobalCEFApp.FastUnload := True;
//  GlobalCEFApp.DisableSafeBrowsing := True;
//  GlobalCEFApp.LogFile := 'log\debug.log';
//  GlobalCEFApp.LogSeverity := LOGSEVERITY_INFO;
  GlobalCEFApp.EnableMediaStream := True;
//  GlobalCEFApp.EnableSpeechInput := False;
//  GlobalCEFApp.NoSandbox := False;
//  GlobalCEFApp.SingleProcess := True;
// GlobalCEFApp.Cookies := 'cookies';
  GlobalCEFApp.Cache := 'cache';
end;



procedure TfrmMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := frameChrome1.FCanClose;

  if not (frameChrome1.FClosing) then
  begin
    frameChrome1.FClosing := True;
    Visible := False;
    frameChrome1.Chromium1.CloseBrowser(True);
  end;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  frmSplash := TfrmSplash.Create(nil);
  try
    frmSplash.Show;

    application.ProcessMessages;
    // 1.��������
    loadMainConfig();
    // 2.����Ƥ��
    if FileExists(unConfig.FSkinFile) then
      spSkinData1.LoadFromCompressedFile(FSkinFile);
    // 3.����������
    create_php_server();
    php_server_start(unConfig.FWebPort);
    create_db_server();
    db_server_start(unConfig.FDataPort);

  finally
    frmSplash.Free;
  end;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  // ֹͣPHP������
  php_server_stop();
  free_php_server();
  // ֹͣAbs���ݷ�����
  db_server_stop();
  free_db_server();

end;

procedure TfrmMain.FormShow(Sender: TObject);
begin
  frameChrome1.setInfo(Self, unConfig.FIndexUrl);
end;

procedure TfrmMain.loadMainConfig;
begin
  Self.Width := unConfig.FWidth;
  Self.Height := unConfig.FHeight;
  Self.Caption := unConfig.FCaption;

end;

initialization

end.

