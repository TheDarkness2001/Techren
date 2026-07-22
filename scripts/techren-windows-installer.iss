; TechRen EDU Windows installer
; Compiled by scripts/build-release-apps.ps1 via ISCC with:
;   /DAppVersion=x.y.z  /DSourceDir=<flutter build output>  /DOutputDir=<website\downloads>

#ifndef AppVersion
  #define AppVersion "1.0.0"
#endif
#ifndef SourceDir
  #error SourceDir must be passed: /DSourceDir=path\to\build\windows\x64\runner\Release
#endif
#ifndef OutputDir
  #error OutputDir must be passed: /DOutputDir=path\to\website\downloads
#endif

[Setup]
AppId={{8E1F3C86-2E7B-4A48-9B7E-51C2A7D0E4F3}
AppName=TechRen EDU
AppVersion={#AppVersion}
AppPublisher=TechRen
DefaultDirName={localappdata}\Programs\TechRen EDU
DisableProgramGroupPage=yes
; Per-user install: no admin prompt needed.
PrivilegesRequired=lowest
OutputDir={#OutputDir}
OutputBaseFilename=TechRenEDU-setup
#ifdef IconFile
SetupIconFile={#IconFile}
#endif
UninstallDisplayIcon={app}\techren_edu.exe
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
CloseApplications=yes

[Tasks]
Name: "desktopicon"; Description: "Create a &Desktop shortcut"; GroupDescription: "Shortcuts:"

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\TechRen EDU"; Filename: "{app}\techren_edu.exe"
Name: "{autodesktop}\TechRen EDU"; Filename: "{app}\techren_edu.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\techren_edu.exe"; Description: "Launch TechRen EDU"; Flags: nowait postinstall skipifsilent
; In-app auto-update runs the installer with /SILENT — relaunch the app afterwards.
Filename: "{app}\techren_edu.exe"; Flags: nowait; Check: WizardSilent
