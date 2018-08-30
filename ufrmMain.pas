unit ufrmMain;

interface

uses
  SysUtils, Windows,
  Classes,
  Controls, Forms, SkinData, DynamicSkinForm,
  uCEFChromium,
  uframeChrome,
  Dialogs;

type
  TfrmMain = class(TForm)
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

implementation

uses
  unConfig, ufrmSplash, ufrmPHPLog, unMoudle, unChromeMessage, unCmdCli;

{$R *.dfm}


procedure TfrmMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := frameChrome1.FCanClose;

  if not(frameChrome1.FClosing) then
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

    if unConfig.FDebug = 1 then
      frmPHPLog := TfrmPHPLog.Create(Application);

    Application.ProcessMessages;
    // 1.��������
    loadMainConfig();
    // 2.����Ƥ��
    if FileExists(unConfig.FSkinFile) then
      dbMoudle.spSkinData1.LoadFromCompressedFile(FSkinFile);
    // 3.����������
    create_php_server();
    php_server_start(unConfig.FWebPort, frmPHPLog.Handle);
    create_db_server();
    db_server_start(unConfig.FDataPort);
    // 4.����workerman����
//    cmdCli := TCmdCli.Create;

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
  // ֹͣworkerman����
//  cmdCli.Free;
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
