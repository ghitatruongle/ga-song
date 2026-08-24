[Setup]
AppName=GA Song
AppVersion=1.0.1-beta
AppPublisher=Ghita
DefaultDirName={autopf}\GA Song
DisableProgramGroupPage=yes
OutputDir=..\build\windows\installer
OutputBaseFilename=GA_Song_v1.0.1-beta_Setup
SetupIconFile=..\assets\pic\app_icon.ico
Compression=lzma
SolidCompression=yes
WizardStyle=modern

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "..\build\windows\x64\runner\Release\ga_song.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\build\windows\x64\runner\Release\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\build\windows\x64\runner\Release\*.dll"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\GA Song"; Filename: "{app}\ga_song.exe"
Name: "{autodesktop}\GA Song"; Filename: "{app}\ga_song.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\ga_song.exe"; Description: "{cm:LaunchProgram,GA Song}"; Flags: nowait postinstall skipifsilent
