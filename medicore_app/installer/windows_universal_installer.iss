; MediCore Universal Installer
; Works on Windows 7-11, both 32-bit and 64-bit

#define MyAppName "MediCore"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "MediCore Team"
#define MyAppURL "https://github.com/ilyesthen/medicore"
#define MyAppExeName "medicore_app.exe"

[Setup]
AppId={{8F3A2B1C-4D5E-6F7A-8B9C-0D1E2F3A4B5C}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir=..\build\installer
OutputBaseFilename=MediCore-Setup-Universal
SetupIconFile=..\assets\images\logos\icon.ico
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
MinVersion=6.1sp1
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "french"; MessagesFile: "compiler:Languages\French.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Install the 64-bit version on 64-bit Windows
Source: "..\build\windows\x64\runner\Release\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion; Check: Is64BitInstallMode
Source: "..\build\windows\x64\runner\Release\*.dll"; DestDir: "{app}"; Flags: ignoreversion; Check: Is64BitInstallMode
Source: "..\build\windows\x64\runner\Release\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs; Check: Is64BitInstallMode

; VC++ Redistributables (both versions included)
Source: "vcredist\vc_redist.x64.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall; Check: Is64BitInstallMode
Source: "vcredist\vc_redist.x86.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
; Install VC++ Redistributables silently
Filename: "{tmp}\vc_redist.x64.exe"; Parameters: "/install /quiet /norestart"; StatusMsg: "Installation des composants Visual C++ (64-bit)..."; Flags: waituntilterminated; Check: Is64BitInstallMode and VCRedist64Needed
Filename: "{tmp}\vc_redist.x86.exe"; Parameters: "/install /quiet /norestart"; StatusMsg: "Installation des composants Visual C++ (32-bit)..."; Flags: waituntilterminated; Check: VCRedist86Needed
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Code]
function VCRedist64Needed(): Boolean;
var
  Version: String;
begin
  // Check if Visual C++ 2015-2022 x64 is installed
  Result := not RegQueryStringValue(HKLM64, 'SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64', 'Version', Version);
end;

function VCRedist86Needed(): Boolean;
var
  Version: String;
begin
  // Check if Visual C++ 2015-2022 x86 is installed
  Result := not RegQueryStringValue(HKLM, 'SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x86', 'Version', Version);
end;

procedure InitializeWizard();
begin
  WizardForm.WelcomeLabel2.Caption := 
    'Cet assistant va installer MediCore sur votre ordinateur.' + #13#10 + #13#10 +
    'MediCore est compatible avec:' + #13#10 +
    '• Windows 7, 8, 8.1, 10, 11' + #13#10 +
    '• Systèmes 32-bit et 64-bit' + #13#10 + #13#10 +
    'Les composants requis seront installés automatiquement.';
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    // Create a desktop shortcut for easier access
    SaveStringToFile(ExpandConstant('{app}\README.txt'), 
      'MediCore - Système de Gestion Médicale' + #13#10 +
      '=======================================' + #13#10 + #13#10 +
      'Première utilisation:' + #13#10 +
      '-------------------' + #13#10 +
      'Au premier démarrage, choisissez:' + #13#10 + #13#10 +
      'ADMIN (Ordinateur Principal):' + #13#10 +
      '  - Sélectionnez cette option sur UN seul ordinateur' + #13#10 +
      '  - Importez votre base de données (.db)' + #13#10 +
      '  - Cet ordinateur diffusera sur le réseau' + #13#10 + #13#10 +
      'CLIENT (Autres Ordinateurs):' + #13#10 +
      '  - Sélectionnez cette option sur tous les autres ordinateurs' + #13#10 +
      '  - L''ordinateur Admin sera détecté automatiquement' + #13#10 +
      '  - Cliquez dessus pour vous connecter' + #13#10 + #13#10 +
      'Dépannage:' + #13#10 +
      '----------' + #13#10 +
      '- Le client ne trouve pas l''admin?' + #13#10 +
      '  * Vérifiez que les deux ordinateurs sont sur le même réseau' + #13#10 +
      '  * Autorisez medicore_app.exe dans le pare-feu Windows' + #13#10 + #13#10 +
      '- Erreur au démarrage?' + #13#10 +
      '  * Exécutez le programme en tant qu''administrateur' + #13#10 +
      '  * Redémarrez l''ordinateur après l''installation' + #13#10 + #13#10 +
      'Support: https://github.com/ilyesthen/medicore' + #13#10, 
      False);
  end;
end;
