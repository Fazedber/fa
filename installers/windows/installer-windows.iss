; Inno Setup 6 - Modern Installer for NexusVPN
; Requires: Inno Setup 6.2+

#define Brand "Nebula"
#define BrandLower "nebula"
#define Version "1.0.0"
#define Publisher "NexusVPN Team"
#define URL "https://github.com/nexusvpn/nexusvpn"
#define ExeName "Nebula.exe"
#define CoreName "nexus-core.exe"

[Setup]
AppId={{B4A4C4E4-5F4A-4C4E-8B4A-4C4E4F4A4C4E}
AppName={#Brand} VPN
AppVersion={#Version}
AppPublisher={#Publisher}
AppPublisherURL={#URL}
AppSupportURL={#URL}/issues
AppUpdatesURL={#URL}/releases
DefaultDirName={autopf}\{#Brand}VPN
DefaultGroupName={#Brand} VPN
AllowNoIcons=yes
LicenseFile=..\LICENSE
OutputDir=..\dist\windows
OutputBaseFilename={#Brand}VPN-{#Version}-Setup
SetupIconFile=..\assets\icon.ico
Compression=lzma2/ultra64
SolidCompression=yes
PrivilegesRequired=admin
PrivilegesRequiredOverridesAllowed=dialog
WizardStyle=modern
WizardSizePercent=100,100
WizardImageFile=..\assets\installer-wizard.bmp
WizardSmallImageFile=..\assets\installer-small.bmp
UninstallDisplayIcon={app}\{#CoreName}
UninstallDisplayName={#Brand} VPN
UninstallFilesDir={app}\uninstall

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"

[Messages]
; Custom welcome message
WelcomeLabel1=Welcome to {#Brand} VPN Setup
WelcomeLabel2=This will install {#Brand} VPN version {#Version} on your computer.%n%n{#Brand} VPN is a fast and secure VPN client supporting VLESS and Hysteria2 protocols.%n%nIt is recommended that you close all other applications before continuing.

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "quicklaunchicon"; Description: "{cm:CreateQuickLaunchIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked; OnlyBelowVersion: 6.1; Check: not IsAdminInstallMode
Name: "startup"; Description: "Start {#Brand} VPN on Windows startup"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Core service
Source: "..\dist\windows\{#Brand}\{#CoreName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\dist\windows\{#Brand}\UI\{#ExeName}"; DestDir: "{app}\UI"; Flags: ignoreversion
Source: "..\dist\windows\{#Brand}\UI\*.dll"; DestDir: "{app}\UI"; Flags: ignoreversion recursesubdirs
Source: "..\dist\windows\{#Brand}\UI\*.runtimeconfig.json"; DestDir: "{app}\UI"; Flags: ignoreversion

; Assets
Source: "..\assets\icon.ico"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{autoprograms}\{#Brand} VPN"; Filename: "{app}\UI\{#ExeName}"; IconFilename: "{app}\icon.ico"
Name: "{autodesktop}\{#Brand} VPN"; Filename: "{app}\UI\{#ExeName}"; IconFilename: "{app}\icon.ico"; Tasks: desktopicon
Name: "{userappdata}\Microsoft\Internet Explorer\Quick Launch\{#Brand} VPN"; Filename: "{app}\UI\{#ExeName}"; IconFilename: "{app}\icon.ico"; Tasks: quicklaunchicon
Name: "{autostartup}\{#Brand} VPN"; Filename: "{app}\UI\{#ExeName}"; IconFilename: "{app}\icon.ico"; Tasks: startup

[Run]
; Install and start Windows service
Filename: "sc.exe"; Parameters: "create {#BrandLower}VPN binPath= """"{app}\{#CoreName}"""" start= auto displayName= """{#Brand} VPN Service""" "; StatusMsg: "Installing service..."; Flags: runhidden
Filename: "sc.exe"; Parameters: "description {#BrandLower}VPN ""NexusVPN Core Service - Manages VPN connections"""; StatusMsg: "Configuring service..."; Flags: runhidden
Filename: "sc.exe"; Parameters: "start {#BrandLower}VPN"; StatusMsg: "Starting service..."; Flags: runhidden

; Launch application
Filename: "{app}\UI\{#ExeName}"; Description: "Launch {#Brand} VPN"; Flags: postinstall nowait skipifsilent

[UninstallRun]
; Stop and remove service
Filename: "sc.exe"; Parameters: "stop {#BrandLower}VPN"; Flags: runhidden
Filename: "sc.exe"; Parameters: "delete {#BrandLower}VPN"; Flags: runhidden

[Code]
const
  WM_SERVICE_DELAY = 3000; // Wait 3 seconds for service

function InitializeSetup(): Boolean;
var
  Version: String;
begin
  // Check if already installed
  if RegQueryStringValue(HKLM, 'Software\Microsoft\Windows\CurrentVersion\Uninstall\{#SetupSetting("AppId")}_is1', 'DisplayVersion', Version) then
  begin
    if MsgBox('{#Brand} VPN version ' + Version + ' is already installed.' + #13#10 + #13#10 +
              'Do you want to reinstall or update?', mbConfirmation, MB_YESNO) = IDNO then
    begin
      Result := false;
      Exit;
    end;
  end;
  
  Result := true;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    // Create config directory
    ForceDirectories(ExpandConstant('{localappdata}\{#Brand}VPN'));
    
    // Wait for service to be ready
    Sleep(WM_SERVICE_DELAY);
  end;
end;

function InitializeUninstall(): Boolean;
begin
  // Confirm uninstall
  Result := MsgBox('Are you sure you want to uninstall {#Brand} VPN?', mbConfirmation, MB_YESNO) = IDYES;
end;

[UninstallDelete]
Type: filesandordirs; Name: "{app}"
Type: filesandordirs; Name: "{localappdata}\{#Brand}VPN"
