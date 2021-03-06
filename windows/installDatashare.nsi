!include LogicLib.nsh
!include GetWindowsVersion.nsh
!include "MUI2.nsh"
!define MUI_ICON "${NSISDIR}\Contrib\Graphics\Icons\modern-install-colorful.ico"
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_LANGUAGE "English"

!define VERSION "$%VERSION%"
!define COMPANYNAME "ICIJ"
!define APPNAME "$%APPNAME%"

Name "${COMPANYNAME} - ${APPNAME}"
Icon "datashare.ico"

!define DOCKER_FOR_WINDOWS_URL "https://desktop.docker.com/win/stable/Docker%20Desktop%20Installer.exe"
!define DOCKER_FOR_WINDOWS_PATH "$TEMP\docker_desktop.exe"
!define WSL_URL "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi"
!define WSL_PATH "$TEMP\wsl_update_x64.msi"
!define DOCKER_TOOLBOX_URL " https://github.com/docker/toolbox/releases/download/v19.03.1/DockerToolbox-19.03.1.exe"
!define DOCKER_TOOLBOX_PATH "$TEMP\docker_toolbox.exe"
!define DOCKER_UNINSTALL_KEY "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Docker Desktop"
!define DATASHARE_UNINSTALL_KEY "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}"
Var shouldReboot

OutFile dist/installDatashare.exe
InstallDir "$PROGRAMFILES64\${APPNAME}"

Function .onInit
  System::Call 'kernel32::CreateMutex(p 0, i 0, t "dsMutex") p .r1 ?e'
  Pop $R0
  ${If} $R0 != "0"
    MessageBox MB_OK|MB_ICONEXCLAMATION "The installer is already running."
    Abort
  ${EndIf}
FunctionEnd

Function InstallDockerToolbox
  DetailPrint "Installing docker toolbox desktop"
  inetc::get "${DOCKER_TOOLBOX_URL}" "${DOCKER_TOOLBOX_PATH}" /end
    Pop $0
    DetailPrint "Download Status: $0"
    ${If} $0 != "OK"
      MessageBox MB_OK "Download Failed: $0"
      Abort
    ${EndIf}
    ExecWait '"${DOCKER_TOOLBOX_PATH}" install --quiet'
FunctionEnd

Function InstallWSL
  DetailPrint "Windows 10 Home needs Windows Subsystem for Linux (WSL)"
  inetc::get "${WSL_URL}" "${WSL_PATH}" /end
  Pop $0
  DetailPrint "Download Status: $0"
  ${If} $0 != "OK"
    MessageBox MB_OK "Download Failed: $0"
    Abort
  ${EndIf}
  ExecWait '"${WSL_PATH}" install --quiet'
FunctionEnd

Function InstallDockerDesktop
  DetailPrint "Datashare uses Docker, downloading and installing docker desktop"
  inetc::get "${DOCKER_FOR_WINDOWS_URL}" "${DOCKER_FOR_WINDOWS_PATH}" /end
  Pop $0
  DetailPrint "Download Status: $0"
  ${If} $0 != "OK"
    MessageBox MB_OK "Download Failed: $0"
    Abort
  ${EndIf}
  ExecWait '"${DOCKER_FOR_WINDOWS_PATH}" install --quiet'
FunctionEnd

Function un.InstallDockerDesktop
  MessageBox MB_YESNO|MB_ICONQUESTION "Do you wish to remove docker desktop ?" IDNO +6
    SetRegView 64
    ReadRegStr $0 HKLM "${DOCKER_UNINSTALL_KEY}" "UninstallString"
    SetRegView 32
    DetailPrint "removing docker with $0"
    nsExec::Exec "$0 --quiet"
FunctionEnd

Function un.InstallDockerToolbox
FunctionEnd

Function InstallDatashare
  exch $R0
  SetOutPath "$INSTDIR"
  file "datashare.ico"
  File "datashare.bat"
  File "PortQry.exe"
  File /oname=docker-compose.yml "dist/docker-compose.yml"

  # Start Menu
  createDirectory "$SMPROGRAMS\${COMPANYNAME}"
  createShortCut "$SMPROGRAMS\${COMPANYNAME}\${APPNAME}.lnk" "$INSTDIR\datashare.bat" "" "$INSTDIR\logo.ico"

  # Data
  createDirectory "$APPDATA\Datashare\dist"
  createDirectory "$APPDATA\Datashare\index"
  createDirectory "$APPDATA\Datashare\data"
  createDirectory "$APPDATA\Datashare\plugins"
  createDirectory "$APPDATA\Datashare\extensions"
  CreateShortcut "$DESKTOP\Datashare Data.lnk" "$APPDATA\Datashare\data"

  writeUninstaller "$INSTDIR\uninstall.exe"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "DisplayName" "${APPNAME}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "UninstallString" "$\"$INSTDIR\uninstall.exe$\""
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "GetWindowsVersion" "$R0"
  pop $R0
FunctionEnd

Section "install"
  StrCpy $shouldReboot "false"
  ${GetWindowsVersion} $R0
  DetailPrint "Detected Windows $R0"

  nsExec::Exec "docker --version"
  Pop $0
  ${If} $0 == "0"
     DetailPrint "Nice! Docker is already installed"
  ${ElseIf} $R0 == "10.0 Pro"
     Call InstallDockerDesktop
     StrCpy $shouldReboot "true"
  ${ElseIf} $R0 == "10.0"
     Call InstallDockerDesktop
     Call InstallWSL
     StrCpy $shouldReboot "true"
  ${Else}
     Call InstallDockerToolbox
     StrCpy $shouldReboot "true"
  ${EndIf}

  Push $R0
  Call InstallDatashare

  ${If} $shouldReboot == "true"
    MessageBox MB_YESNO|MB_ICONQUESTION "System needs to reboot. Do you wish to reboot now ?" IDNO +2
    Reboot
  ${EndIf}
SectionEnd

section "uninstall"
  delete "$SMPROGRAMS\${COMPANYNAME}\${APPNAME}.lnk"
  rmDir "$SMPROGRAMS\${COMPANYNAME}" # only if empty
  rmDir /r $INSTDIR # recursive

  # data
  rmDir /r "$APPDATA\Datashare\dist"
  rmDir /r "$APPDATA\Datashare\index"
  rmDir /r "$APPDATA\Datashare\plugins"
  rmDir /r "$APPDATA\Datashare\extensions"
  MessageBox MB_YESNO|MB_ICONQUESTION "Do you want to remove Datashare data directory ?" IDNO +3
    rmDir /r "$APPDATA\Datashare\data"
    delete "$DESKTOP\Datashare Data.lnk"
  rmDir "$APPDATA\Datashare" # only if empty

  ReadRegStr $0 HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "GetWindowsVersion"
  # Remove uninstaller information from the registry
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}"

  ${If} $0 == "10.0 Pro"
    Call un.InstallDockerDesktop
  ${ElseIf} $0 == "10.0"
    Call un.InstallDockerDesktop
  ${Else}
    Call un.InstallDockerToolbox
  ${EndIf}
SectionEnd
