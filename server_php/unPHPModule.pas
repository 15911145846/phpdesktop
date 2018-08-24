unit unPHPModule;

interface

uses
  SysUtils, Classes, Windows, diocp_ex_httpServer, Contnrs, PHPCommon,
  php4delphi,
  zendAPI,
  phpAPI, PHPCustomLibrary, utils_strings, diocp_ex_httpClient,
  CnIni, CnCommon, utils_dvalue, Dialogs, PHPTypes, utils_dvalue_json;

const
  PHP_SESSIONID = 'PHPSESSID';

type
  TPHPModule = class(TDataModule)
    FPHPEngine: TPHPEngine;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    procedure FPHPEngineScriptError(Sender: TObject; AText: AnsiString;
      AType: TPHPErrorType; AFileName: AnsiString; ALineNo: Integer);
  private
    { Private declarations }

    FHttpServer: TDiocpHttpServer;
    FLogHandle: HWND;

    // ������Ӧ
    procedure OnHttpSvrRequest(pvRequest: TDiocpHttpRequest);
    procedure parseParams(psvPhpOne: TpsvPHP; pvRequest: TDiocpHttpRequest);
    procedure parseSessionID(psvPhpOne: TpsvPHP; pvRequest: TDiocpHttpRequest);

    // ����PHP��ʱ�ļ��У�����session�ļ�
    procedure createTmpPath();

  public
    { Public declarations }

    procedure start(iPort: Integer; logHandle: HWND);
    procedure stop();
  end;

var
  phpServer: TPHPModule;

implementation

{$R *.dfm}
{ TDataModule1 }

uses unConfig;

procedure TPHPModule.createTmpPath;
var
  reg: TCnIniFile;
  tmpPath: string;
begin
  if not FileExists('php.ini') then
    Exit;

  reg := TCnIniFile.Create('php.ini');
  try
    tmpPath := reg.ReadString('Session', 'session.save_path', './tmp');
    // "./tmp"
    tmpPath := AnsiDequotedStr(tmpPath, '"');
    tmpPath := AppPath + tmpPath;
    tmpPath := StringReplace(tmpPath, '/', '\', [rfReplaceAll]);
    if not DirectoryExists(tmpPath) then
      ForceDirectories(tmpPath);
  finally
    reg.Free;
  end;
end;

procedure TPHPModule.DataModuleCreate(Sender: TObject);
begin
  FPHPEngine.DLLFolder := AppPath + 'php_5.3.5\';
  FPHPEngine.IniPath := AppPath + 'php_5.3.5\';
  FPHPEngine.StartupEngine;

  createTmpPath;

  FHttpServer := TDiocpHttpServer.Create(nil);
  FHttpServer.Name := 'web_server';
  FHttpServer.OnDiocpHttpRequest := OnHttpSvrRequest;
  FHttpServer.DisableSession := True;
end;

procedure TPHPModule.DataModuleDestroy(Sender: TObject);
begin
  FHttpServer.SafeStop();
  FHttpServer.Free;

  FPHPEngine.ShutdownAndWaitFor;

end;

procedure TPHPModule.FPHPEngineScriptError(Sender: TObject; AText: AnsiString;
  AType: TPHPErrorType; AFileName: AnsiString; ALineNo: Integer);
var
  strTmp: string;
  dvTmp: TDValue;
begin
  dvTmp := TDValue.Create(vntObject);
  try
    dvTmp.AddVar('AFileName', AFileName);
    dvTmp.AddVar('ALineNo', ALineNo);
    dvTmp.AddVar('AText', AText);
    dvTmp.AddVar('AType', Ord(AType));
    strTmp := JSONEncode(dvTmp);
    PostMessage(Self.FLogHandle, YS_BROWSER_APP_PHPERROR, Integer((strTmp)), 0);
  finally
    dvTmp.Free;
  end;
end;

procedure TPHPModule.OnHttpSvrRequest(pvRequest: TDiocpHttpRequest);
var
  PHPFileName: string;
  psvPhpOne: TpsvPHP;
  i: Integer;

  strUrl: string;

  strHtml, sessionID: AnsiString;
begin
  if pvRequest.RequestURI = '/' then
    strUrl := '/index.php'
  else
    strUrl := pvRequest.RequestURI;

  if strUrl = '/favicon.ico' then
    Exit;

  PHPFileName := FAppPath + 'app' + strUrl;
  PHPFileName := StringReplace(PHPFileName, '/', '\', [rfReplaceAll]);

  // ��PHP�ļ�,ֱ�ӷ��ظ��ļ�
  if LowerCase(ExtractFileExt(PHPFileName)) <> '.php' then
  begin
    pvRequest.Response.ResponseCode := 200;
    if FileExists(PHPFileName) then
      pvRequest.Response.LoadFromFile(PHPFileName);
    pvRequest.ResponseEnd();
    Exit;
  end;

  psvPhpOne := TpsvPHP.Create(nil);
  try
    if pvRequest.RequestMethod = 'GET' then
      psvPhpOne.RequestType := prtGet
    else
      psvPhpOne.RequestType := prtPost;

    // PHP_SELF����
    with psvPhpOne.Variables.Add do
    begin
      Name := 'PHP_SELF';
      Value := UTF8Encode(PHPFileName);
    end;
    // 1.��������
    parseParams(psvPhpOne, pvRequest);
    try
      // 2.ִ��PHP�ļ�
      strHtml := psvPhpOne.Execute(PHPFileName);
      // 3.��ȡִ����ɽ��
      parseSessionID(psvPhpOne, pvRequest);
    finally
      psvPhpOne.Free;
    end;

    pvRequest.Response.ResponseCode := 200;
    pvRequest.Response.WriteString(UTF8Decode(strHtml)); //
    pvRequest.ResponseEnd();
  except
    pvRequest.Response.ResponseCode := 200;
    pvRequest.Response.WriteString('ִ���쳣'); //
    pvRequest.ResponseEnd();
  end;

end;

procedure TPHPModule.parseParams(psvPhpOne: TpsvPHP;
  pvRequest: TDiocpHttpRequest);
var
  iCount: Integer;
  i: Integer;
  dItem: TDValue;
begin
{$IFDEF UNICODE}
  pvRequest.DecodePostDataParam(TEncoding.UTF8);
  pvRequest.DecodeURLParam(TEncoding.UTF8);
{$ELSE}
  // ʹ��UTF8��ʽ����
  pvRequest.DecodePostDataParam(True);
  pvRequest.DecodeURLParam(True);
{$ENDIF}
  // ��ȡdelphi��PHPSESSID��PHP
  with psvPhpOne.Variables.Add do
  begin
    Name := PHP_SESSIONID;
    Value := pvRequest.GetCookie(PHP_SESSIONID);
  end;
  // SCRIPT_NAME����
  with psvPhpOne.Variables.Add do
  begin
    Name := 'SCRIPT_NAME';
    Value := pvRequest.RequestURI;
  end;

  // ���в���������PHP
  iCount := pvRequest.RequestParamsList.Count;
  for i := 0 to iCount - 1 do
  begin
    dItem := pvRequest.RequestParamsList.Items[i];
    with psvPhpOne.Variables.Add do
    begin
      Name := UTF8Encode(dItem.Name.AsStringW);
      Value := UTF8Encode(dItem.Value.AsStringW);
    end;
  end;

end;

procedure TPHPModule.parseSessionID(psvPhpOne: TpsvPHP;
  pvRequest: TDiocpHttpRequest);
var
  i: Integer;
  sessionID: string;
begin
  for i := 0 to psvPhpOne.Headers.Count - 1 do // psvPHP1.Headers.GetHeaders
  begin
    if InStr('Set-Cookie', psvPhpOne.Headers[i].Header) then
    begin
      // 2. ��ȡ��PHP�е�sessionID����ͨ��delphi�������
      sessionID := psvPhpOne.Headers[i].Header;
      sessionID := GetStrValueOfName(sessionID, 'Set-Cookie', [':', ' '],
        [' ']); // ��ȡ����ֵ
      sessionID := GetStrValueOfName(sessionID, 'PHPSESSID', ['=', ' '],
        [';', ' ']);

      // 3. ��sessionIDֵ���õ������
      with pvRequest.Response.AddCookie do
      begin
        Name := PHP_SESSIONID;
        Value := sessionID;
      end;
      Break;
    end;
  end;

end;

procedure TPHPModule.start(iPort: Integer; logHandle: HWND);
begin
  FHttpServer.DefaultListenAddress := FHost;
  FHttpServer.Port := iPort;
  Self.FHttpServer.Active := True;
  Self.FLogHandle := logHandle;
end;

procedure TPHPModule.stop;
begin
  Self.FHttpServer.SafeStop;
end;

end.
