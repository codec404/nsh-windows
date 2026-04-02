; nsh-setup.iss — Inno Setup installer script for nsh on Windows
;
; Prerequisites:
;   1. Run windows/build.sh inside MSYS2 first — it produces windows/dist/
;   2. Install Inno Setup 6:  https://jrsoftware.org/isinfo.php
;   3. Open this file in Inno Setup and click Build > Compile
;
; Output: windows/installer/nsh-setup.exe

#define AppName      "nsh"
#define AppVersion   "1.0.0"
#define AppPublisher "nsh contributors"
#define AppURL       "https://github.com/your-org/nsh"
#define AppExeName   "mintty.exe"
#define DistDir      "dist"

[Setup]
AppId={{E3F2A1B4-7C8D-4E9F-A0B1-2C3D4E5F6A7B}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisherURL={#AppURL}
AppSupportURL={#AppURL}
AppUpdatesURL={#AppURL}
DefaultDirName={autopf}\nsh
DefaultGroupName={#AppName}
AllowNoIcons=yes
LicenseFile=..\nsh\LICENSE
OutputDir=installer
OutputBaseFilename=nsh-setup
SetupIconFile=nsh.ico
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon";   Description: "{cm:CreateDesktopIcon}";   GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "addtopath";     Description: "Add nsh to system PATH (lets you run nsh from any terminal)"; GroupDescription: "System integration:"

[Files]
; All binaries and DLLs collected by build.sh
Source: "{#DistDir}\bin\*"; DestDir: "{app}\bin"; Flags: ignoreversion recursesubdirs

[Icons]
; Start Menu shortcut — opens MinTTY running nsh
Name: "{group}\nsh Terminal";          Filename: "{app}\bin\mintty.exe"; Parameters: "--title nsh -e {app}\bin\nsh.exe"; WorkingDir: "{userdocs}"
Name: "{group}\{cm:UninstallProgram,{#AppName}}"; Filename: "{uninstallexe}"
Name: "{commondesktop}\nsh Terminal";  Filename: "{app}\bin\mintty.exe"; Parameters: "--title nsh -e {app}\bin\nsh.exe"; WorkingDir: "{userdocs}"; Tasks: desktopicon

[Registry]
; Add to PATH when the user selects the task
Root: HKLM; Subkey: "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"; \
    ValueType: expandsz; ValueName: "Path"; \
    ValueData: "{olddata};{app}\bin"; \
    Check: PathNotAlreadyAdded('{app}\bin'); \
    Tasks: addtopath; Flags: preservestringtype

[Code]
{ Helper: only add to PATH if not already present }
function PathNotAlreadyAdded(const NewPath: string): Boolean;
var
  CurrentPath: string;
begin
  if not RegQueryStringValue(HKLM,
      'SYSTEM\CurrentControlSet\Control\Session Manager\Environment',
      'Path', CurrentPath) then
    CurrentPath := '';
  Result := Pos(LowerCase(NewPath), LowerCase(CurrentPath)) = 0;
end;

[Run]
; Offer to launch nsh after install
Filename: "{app}\bin\mintty.exe"; Parameters: "--title nsh -e {app}\bin\nsh.exe"; \
    Description: "Launch nsh Terminal"; Flags: postinstall nowait skipifsilent

[UninstallRun]
; Nothing special needed on uninstall — files and registry entries are cleaned
; up automatically by Inno Setup.
