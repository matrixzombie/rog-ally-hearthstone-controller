; ROG Ally Hearthstone Controller Mapper - Inno Setup installer
; Build with Inno Setup 6.x on Windows.
;
; Expected files next to this script before compiling:
;   RogAlly_Hearthstone_Controller.exe        required
;   readme.html                              recommended; should contain the latest release notes
;   LICENSE                                  recommended
;   Controller_Diagnostic.exe                optional, if you compile the diagnostic too
;
; Output:
;   dist\rog-ally-hearthstone-controller-setup.exe

#define MyAppName "ROG Ally Hearthstone Controller Mapper"
#define MyAppShortName "rog-ally-hearthstone-controller"
#define MyAppVersion "1.1"
#define MyAppPublisher "KingZombie"
#define MyAppURL "https://github.com/matrixzombie/rog-ally-hearthstone-controller"
#define MyAppExeName "RogAlly_Hearthstone_Controller.exe"
#define MyDiagnosticExeName "Controller_Diagnostic.exe"

[Setup]
AppId={{7DE35914-7B81-4D02-ACEA-F675836F9406}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}/issues
AppUpdatesURL={#MyAppURL}/releases/latest
AppContact={#MyAppURL}/issues
AppComments=Controller mapper for accessible Hearthstone play on ROG Ally, ROG Ally X, and Xbox/XInput-style controllers.
DefaultDirName={localappdata}\Programs\{#MyAppShortName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=no
AllowNoIcons=yes
#ifexist "LICENSE"
LicenseFile=LICENSE
#endif
#ifexist "readme.html"
InfoAfterFile=readme.html
#endif
UninstallDisplayIcon={app}\{#MyAppExeName}
UninstallDisplayName={#MyAppName}
PrivilegesRequired=lowest
MinVersion=10.0
OutputDir=dist
OutputBaseFilename={#MyAppShortName}-setup
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
SetupLogging=yes
CloseApplications=no
RestartApplications=no

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "launchatstartup"; Description: "Start the mapper when I sign in to Windows"; GroupDescription: "Startup:"; Flags: unchecked

[Files]
Source: "{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "LICENSE"; DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist
Source: "readme.html"; DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist
Source: "README.md"; DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist
Source: "{#MyDiagnosticExeName}"; DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"
Name: "{group}\Controller Diagnostic"; Filename: "{app}\{#MyDiagnosticExeName}"; WorkingDir: "{app}"; Check: DiagnosticInstalled
Name: "{group}\README"; Filename: "{app}\readme.html"; WorkingDir: "{app}"; Check: ReadmeInstalled
Name: "{group}\Uninstall {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"; Tasks: desktopicon
Name: "{userstartup}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"; Tasks: launchatstartup

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Launch {#MyAppName}"; Flags: nowait postinstall skipifsilent unchecked

[InstallDelete]
; Remove older installed documentation if filenames change between builds.
Type: files; Name: "{app}\HearthstoneAccess_RogAlly.ahk"

[UninstallDelete]
; Remove the optional startup shortcut even if it was edited after install.
Type: files; Name: "{userstartup}\{#MyAppName}.lnk"
; User settings are intentionally left in %APPDATA%\RogAllyHearthstoneController.
; Delete that folder manually if a complete reset is desired.

[Code]
function DiagnosticInstalled: Boolean;
begin
  Result := FileExists(ExpandConstant('{app}\{#MyDiagnosticExeName}'));
end;

function ReadmeInstalled: Boolean;
begin
  Result := FileExists(ExpandConstant('{app}\readme.html'));
end;
