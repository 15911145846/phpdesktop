unit unConfig;

interface

uses utils_dvalue, utils_dvalue_json, StrUtils, SysUtils, Messages,
  uCEFConstants, Forms;

const
  // APP��Ӧ��Ϣ
  YS_BROWSER_APP_SHOWDEVTOOLS = WM_APP + $101; // ��ʾ��������
  YS_BROWSER_APP_HIDEDEVTOOLS = WM_APP + $102; // ���ؿ�������
  YS_BROWSER_APP_REFRESH = WM_APP + $103; // ˢ��
  YS_BROWSER_APP_SHOW = WM_APP + $104; // ��ʾ����
  YS_BROWSER_APP_SHOWMODAL = WM_APP + $105; // modal��ʾ����
  YS_BROWSER_APP_PHPERROR = WM_APP + $106; // php�쳣��Ϣ
  YS_BROWSER_APP_PHPLOG = WM_APP + $107; // ��ʾPHP��־

  // �Ҽ��˵�������Ϣ
  YS_BROWSER_CONTEXTMENU_SHOWDEVTOOLS = MENU_ID_USER_FIRST + 1; // ��ʾ��������
  YS_BROWSER_CONTEXTMENU_HIDEDEVTOOLS = MENU_ID_USER_FIRST + 2; // ���ؿ�������
  YS_BROWSER_CONTEXTMENU_REFRESH = MENU_ID_USER_FIRST + 3; // ˢ��
  YS_BROWSER_CONTEXTMENU_PHPLOG = MENU_ID_USER_FIRST + 4; // ��ʾPHP��־

  // ��չ������Ϣ
  YS_BROWSER_EXTENSION_SHOW = 'extension_show'; // ��ʾ����
  YS_BROWSER_EXTENSION_SHOWMODAL = 'extension_showmodal'; // modal��ʾ����

var
  FIndexUrl: string; // ��������ַ
  FAppPath: string; // Ӧ��Ŀ¼
  FSkinFile: string; // Ƥ���ļ�·��
  FDataBaseFile: string; // ���ݿ��ļ�·��
  FDebug: Integer; // �Ƿ�������ģʽ
  FWidth: Integer; // �����ڿ��
  FHeight: Integer; // �����ڸ߶�
  FCaption: string; // �����ڱ���
  FHost: string; // ����IP
  FDataPort: Integer; // ���ݿ�˿�
  FWebPort: Integer; // web�˿�

implementation

const
  jsonFile: string = 'config.json';

function getValue(key: string): string;
var
  lvData, lvTmp: TDValue;
begin
  if not FileExists('config.json') then
  begin
    Result := '';
    Exit;
  end;

  lvData := TDValue.Create();
  try
    JSONParseFromUtf8NoBOMFile('config.json', lvData);
    lvTmp := lvData.FindByPath(key);
    Result := IfThen(Assigned(lvTmp), lvTmp.AsString, '');
  finally
    lvData.Free;
  end;
end;

initialization

FAppPath := ExtractFilePath(Application.ExeName);
FSkinFile := FAppPath + unConfig.getValue('skin');
FDataBaseFile := FAppPath + unConfig.getValue('database');
FDebug := StrToIntDef(unConfig.getValue('debug'), 0);
FWidth := StrToIntDef(unConfig.getValue('width'), 1024);
FHeight := StrToIntDef(unConfig.getValue('height'), 800);
FCaption := unConfig.getValue('title');
FHost := unConfig.getValue('host');
FDataPort := StrToIntDef(unConfig.getValue('data_port'), 46151);
FWebPort := StrToIntDef(unConfig.getValue('web_port'), 46150);
FIndexUrl := Format('http://127.0.0.1:%d/%s',
  [FWebPort, unConfig.getValue('url')]);

finalization

end.
