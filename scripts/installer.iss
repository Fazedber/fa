; Inno Setup Installer for NexusVPN
#define Brand "Nebula"
#define Version "1.0.0"

[Setup]
AppName={#Brand} VPN
AppVersion={#Version}
DefaultDirName={autopf}\{#Brand}
DefaultGroupName={#Brand} VPN
OutputDir=..\dist\windows
OutputBaseFilename={#Brand}-Setup
Compression=lzma2
SolidCompression=yes
PrivilegesRequired=admin

[Files]
Source: "..\dist\windows\{#Brand}\nexus-core.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\dist\windows\{#Brand}\UI\*"; DestDir: "{app}\UI"; Flags: ignoreversion recursesubdirs

[Icons]
Name: "{group}\{#Brand} VPN"; Filename: "{app}\UI\{#Brand}.exe"
Name: "{autodesktop}\{#Brand} VPN"; Filename: "{app}\UI\{#Brand}.exe"

[Run]
Filename: "{app}\nexus-core.exe"; Parameters: "install"; StatusMsg: "Installing service..."; Flags: runhidden
Filename: "{app}\UI\{#Brand}.exe"; Description: "Launch {#Brand} VPN"; Flags: postinstall skipifsilent

[UninstallRun]
Filename: "{app}\nexus-core.exe"; Parameters: "uninstall"; Flags: runhidden

[UninstallDelete]
Type: filesandordirs; Name: "{app}"
