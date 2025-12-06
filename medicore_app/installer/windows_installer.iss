; MediCore Windows Installer Script
; Inno Setup Script for creating professional Windows installer

#define MyAppName "MediCore"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Thaziri Medical"
#define MyAppExeName "medicore_app.exe"
#define MyAppURL "https://github.com/ilyesthen/medicore"

[Setup]
; Basic info
AppId={{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}

; Installation settings
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir=Output
OutputBaseFilename=MediCore-Setup-{#MyAppVersion}
SetupIconFile=..\assets\logos\app_icon.ico
Compression=lzma2/ultra64
SolidCompression=yes
LZMAUseSeparateProcess=yes

; Windows version compatibility (Windows 7+)
MinVersion=6.1
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

; Visual settings
WizardStyle=modern
WizardSizePercent=120
DisableWelcomePage=no

; Privileges
PrivilegesRequired=admin
PrivilegesRequiredOverridesAllowed=dialog

[Languages]
Name: "french"; MessagesFile: "compiler:Languages\French.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "quicklaunchicon"; Description: "{cm:CreateQuickLaunchIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked; OnlyBelowVersion: 6.1; Check: not IsAdminInstallMode

[Files]
; Main application files
Source: "..\build\windows\x64\runner\Release\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\build\windows\x64\runner\Release\*.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\build\windows\x64\runner\Release\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

; Assets (images, logos, sounds for PDF printing etc.)
Source: "..\assets\images\*"; DestDir: "{app}\data\flutter_assets\assets\images"; Flags: ignoreversion recursesubdirs createallsubdirs; Check: DirExists(ExpandConstant('..\assets\images'))
Source: "..\assets\logos\*"; DestDir: "{app}\data\flutter_assets\assets\logos"; Flags: ignoreversion recursesubdirs createallsubdirs; Check: DirExists(ExpandConstant('..\assets\logos'))
Source: "..\assets\sounds\*"; DestDir: "{app}\data\flutter_assets\assets\sounds"; Flags: ignoreversion recursesubdirs createallsubdirs; Check: DirExists(ExpandConstant('..\assets\sounds'))

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon
Name: "{userappdata}\Microsoft\Internet Explorer\Quick Launch\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: quicklaunchicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Code]
// Check for Visual C++ Redistributable
function NeedsVCRedist: Boolean;
var
  Version: String;
begin
  Result := True;
  if RegQueryStringValue(HKLM, 'SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64', 'Version', Version) then
    Result := False;
end;

// Custom initialization
function InitializeSetup(): Boolean;
begin
  Result := True;
  // Check Windows version
  if not IsWindows7 then
  begin
    if MsgBox('Ce programme nécessite Windows 7 ou supérieur. Voulez-vous continuer?', mbConfirmation, MB_YESNO) = IDNO then
      Result := False;
  end;
end;

function IsWindows7: Boolean;
begin
  Result := (GetWindowsVersion >= $06010000);
end;
