; MediCore Ophthalmology - Windows Installer Script
; Inno Setup Script for Professional Medical Software

#ifndef MyAppVersion
  #define MyAppVersion "1.0.0"
#endif

#ifndef MyAppArch
  #define MyAppArch "x64"
#endif

#define MyAppName "MediCore Ophthalmology"
#define MyAppPublisher "MediCore Solutions"
#define MyAppURL "https://github.com/ilyesthen/medicore"
#define MyAppExeName "medicore_app.exe"

[Setup]
; Application info
AppId={{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}

; Installation directories
DefaultDirName={autopf}\MediCore
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes

; Output settings
OutputDir=Output
OutputBaseFilename=MediCore_Setup_{#MyAppVersion}_{#MyAppArch}
SetupIconFile=..\medicore_app\windows\runner\resources\app_icon.ico
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern

; Privileges
PrivilegesRequired=admin
PrivilegesRequiredOverridesAllowed=dialog

; Architecture
#if MyAppArch == "x64"
  ArchitecturesAllowed=x64
  ArchitecturesInstallIn64BitMode=x64
#endif

; License
LicenseFile=..\LICENSE
InfoBeforeFile=..\README.md

[Languages]
Name: "french"; MessagesFile: "compiler:Languages\French.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "quicklaunchicon"; Description: "{cm:CreateQuickLaunchIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked; OnlyBelowVersion: 6.1; Check: not IsAdminInstallMode
Name: "servermode"; Description: "Installer en mode Serveur (Admin/Réseau)"; GroupDescription: "Mode d'installation:"; Flags: exclusive
Name: "clientmode"; Description: "Installer en mode Client (Connexion LAN)"; GroupDescription: "Mode d'installation:"; Flags: exclusive unchecked

[Files]
; Main application files
Source: "..\medicore_app\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

; Server executable
Source: "..\medicore_server\medicore_server_amd64.exe"; DestDir: "{app}\server"; DestName: "medicore_server.exe"; Flags: ignoreversion; Tasks: servermode

; Database schema
Source: "..\medicore_server\database\schema.sql"; DestDir: "{app}\server\database"; Flags: ignoreversion; Tasks: servermode

; Configuration templates
Source: "config\server.example.env"; DestDir: "{app}\server"; DestName: "server.env"; Flags: ignoreversion; Tasks: servermode
Source: "config\client.example.env"; DestDir: "{app}"; DestName: "client.env"; Flags: ignoreversion; Tasks: clientmode

[Dirs]
Name: "{app}\data"; Permissions: everyone-full; Tasks: servermode
Name: "{app}\logs"; Permissions: everyone-full

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{group}\MediCore Server"; Filename: "{app}\server\medicore_server.exe"; Tasks: servermode
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon
Name: "{userappdata}\Microsoft\Internet Explorer\Quick Launch\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: quicklaunchicon

[Run]
; Post-installation setup
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

; Initialize database for server mode
Filename: "{cmd}"; Parameters: "/c echo Initializing MediCore Server..."; Tasks: servermode; StatusMsg: "Configuration du serveur..."

[Registry]
; Register application
Root: HKLM; Subkey: "Software\MediCore"; ValueType: string; ValueName: "InstallPath"; ValueData: "{app}"; Flags: uninsdeletekey
Root: HKLM; Subkey: "Software\MediCore"; ValueType: string; ValueName: "Version"; ValueData: "{#MyAppVersion}"
Root: HKLM; Subkey: "Software\MediCore"; ValueType: string; ValueName: "Mode"; ValueData: "server"; Tasks: servermode
Root: HKLM; Subkey: "Software\MediCore"; ValueType: string; ValueName: "Mode"; ValueData: "client"; Tasks: clientmode

[Code]
var
  ServerIPPage: TInputQueryWizardPage;
  DatabasePage: TInputDirWizardPage;

procedure InitializeWizard;
begin
  // Server IP configuration page for client mode
  ServerIPPage := CreateInputQueryPage(wpSelectTasks,
    'Configuration Réseau',
    'Configurer la connexion au serveur MediCore',
    'Entrez l''adresse IP du serveur MediCore sur votre réseau local:');
  ServerIPPage.Add('Adresse IP du serveur:', False);
  ServerIPPage.Values[0] := '192.168.1.100';

  // Database location for server mode
  DatabasePage := CreateInputDirPage(wpSelectTasks,
    'Emplacement Base de Données',
    'Choisir l''emplacement de la base de données',
    'La base de données sera stockée dans ce dossier. Assurez-vous d''avoir les droits d''écriture.',
    False, '');
  DatabasePage.Add('');
  DatabasePage.Values[0] := ExpandConstant('{app}\data');
end;

function ShouldSkipPage(PageID: Integer): Boolean;
begin
  Result := False;
  
  // Skip server IP page if server mode selected
  if PageID = ServerIPPage.ID then
    Result := WizardIsTaskSelected('servermode');
    
  // Skip database page if client mode selected
  if PageID = DatabasePage.ID then
    Result := WizardIsTaskSelected('clientmode');
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  ConfigFile: String;
  ServerIP: String;
  DataPath: String;
begin
  if CurStep = ssPostInstall then
  begin
    // Save configuration based on mode
    if WizardIsTaskSelected('clientmode') then
    begin
      ServerIP := ServerIPPage.Values[0];
      ConfigFile := ExpandConstant('{app}\client.env');
      SaveStringToFile(ConfigFile, 'SERVER_IP=' + ServerIP + #13#10 + 'SERVER_PORT=8080' + #13#10, False);
    end
    else if WizardIsTaskSelected('servermode') then
    begin
      DataPath := DatabasePage.Values[0];
      ConfigFile := ExpandConstant('{app}\server\server.env');
      SaveStringToFile(ConfigFile, 
        'DATABASE_PATH=' + DataPath + '\medicore.db' + #13#10 +
        'SERVER_PORT=8080' + #13#10 +
        'ADMIN_MODE=true' + #13#10 +
        'ALLOW_LAN=true' + #13#10, False);
    end;
  end;
end;

function GetServerIP(Param: String): String;
begin
  Result := ServerIPPage.Values[0];
end;

function GetDataPath(Param: String): String;
begin
  Result := DatabasePage.Values[0];
end;
