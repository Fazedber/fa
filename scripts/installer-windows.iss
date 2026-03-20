; Inno Setup 6 - Modern Installer for NexusVPN
; Requires: Inno Setup 6.2+

#ifndef Brand
  #define Brand "Nebula"
#endif
#ifndef BrandLower
  #define BrandLower "nebula"
#endif
#ifndef Version
  #define Version "1.0.0"
#endif
#define Publisher "NexusVPN Team"
#define URL "https://github.com/Fazedber/fa"
#ifndef ExeName
  #define ExeName "Nebula.exe"
#endif
#ifndef AppId
  #define AppId "{{B4A4C4E4-5F4A-4C4E-8B4A-4C4E4F4A4C4E}"
#endif
#define CoreName "nexus-core.exe"

[Setup]
AppId={#AppId}
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
Compression=lzma2/ultra64
SolidCompression=yes
PrivilegesRequired=admin
PrivilegesRequiredOverridesAllowed=dialog
WizardStyle=modern
WizardSizePercent=100,100
SetupIconFile=..\assets\{#BrandLower}.ico
UninstallDisplayIcon={app}\UI\app.ico
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
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: checkedonce
Name: "quicklaunchicon"; Description: "{cm:CreateQuickLaunchIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked; OnlyBelowVersion: 6.1; Check: not IsAdminInstallMode
Name: "startup"; Description: "Start {#Brand} VPN on Windows startup"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Core service
Source: "..\dist\windows\{#Brand}\{#CoreName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\dist\windows\{#Brand}\UI\*"; DestDir: "{app}\UI"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#Brand} VPN"; Filename: "{app}\UI\{#ExeName}"; IconFilename: "{app}\UI\app.ico"; WorkingDir: "{app}\UI"
Name: "{autodesktop}\{#Brand} VPN"; Filename: "{app}\UI\{#ExeName}"; IconFilename: "{app}\UI\app.ico"; WorkingDir: "{app}\UI"; Tasks: desktopicon
Name: "{userappdata}\Microsoft\Internet Explorer\Quick Launch\{#Brand} VPN"; Filename: "{app}\UI\{#ExeName}"; IconFilename: "{app}\UI\app.ico"; WorkingDir: "{app}\UI"; Tasks: quicklaunchicon
Name: "{autostartup}\{#Brand} VPN"; Filename: "{app}\UI\{#ExeName}"; IconFilename: "{app}\UI\app.ico"; WorkingDir: "{app}\UI"; Tasks: startup

[Run]
; Launch application
Filename: "{app}\UI\{#ExeName}"; Description: "Launch {#Brand} VPN"; Flags: postinstall nowait skipifsilent

[Code]
const
  WM_SERVICE_DELAY = 3000; // Wait 3 seconds for service

function ServiceCommand(const Parameters: string; const IgnoreExitCode: Boolean): Boolean;
var
  ResultCode: Integer;
begin
  Result := Exec(ExpandConstant('{sys}\sc.exe'), Parameters, '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  if not Result then
  begin
    if not IgnoreExitCode then
      RaiseException('Failed to run service command: ' + Parameters);
    Exit;
  end;

  if (ResultCode <> 0) and not IgnoreExitCode then
    RaiseException('Service command failed: ' + Parameters + ' (exit code ' + IntToStr(ResultCode) + ')');
end;

function ServiceExists(const ServiceName: string): Boolean;
var
  ResultCode: Integer;
begin
  Result := Exec(ExpandConstant('{sys}\sc.exe'), 'query "' + ServiceName + '"', '', SW_HIDE, ewWaitUntilTerminated, ResultCode) and (ResultCode = 0);
end;

procedure InstallOrUpdateService();
var
  ServiceName: string;
  BinPath: string;
begin
  ServiceName := '{#BrandLower}VPN';
  BinPath := AddQuotes(ExpandConstant('{app}\{#CoreName}'));

  if ServiceExists(ServiceName) then
  begin
    ServiceCommand('stop "' + ServiceName + '"', True);
    Sleep(1500);
    ServiceCommand('config "' + ServiceName + '" binPath= ' + BinPath + ' start= auto displayname= ' + AddQuotes('{#Brand} VPN Service'), False);
  end
  else
  begin
    ServiceCommand('create "' + ServiceName + '" binPath= ' + BinPath + ' start= auto displayname= ' + AddQuotes('{#Brand} VPN Service'), False);
  end;

  ServiceCommand('description "' + ServiceName + '" ' + AddQuotes('NexusVPN Core Service - Manages VPN connections'), False);
  ServiceCommand('start "' + ServiceName + '"', True);
end;

procedure RemoveService();
var
  ServiceName: string;
begin
  ServiceName := '{#BrandLower}VPN';
  ServiceCommand('stop "' + ServiceName + '"', True);
  ServiceCommand('delete "' + ServiceName + '"', True);
end;

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
    ForceDirectories(ExpandConstant('{localappdata}\NexusVPN'));
    InstallOrUpdateService();
    
    // Wait for service to be ready
    Sleep(WM_SERVICE_DELAY);
  end;
end;

function InitializeUninstall(): Boolean;
begin
  // Confirm uninstall
  Result := MsgBox('Are you sure you want to uninstall {#Brand} VPN?', mbConfirmation, MB_YESNO) = IDYES;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usUninstall then
    RemoveService();
end;

[UninstallDelete]
Type: filesandordirs; Name: "{app}"
