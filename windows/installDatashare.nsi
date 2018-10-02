!include LogicLib.nsh
!include Registry.nsh
!include GetWindowsVersion.nsh
!include "MUI2.nsh"
!define MUI_ICON "${NSISDIR}\Contrib\Graphics\Icons\modern-install-colorful.ico"
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_LANGUAGE "English"

!define VERSION "0.31"
!define COMPANYNAME "ICIJ"
!define APPNAME "Datashare ${VERSION}"

Name "${COMPANYNAME} - ${APPNAME}"
Icon "icij.ico"

!define DOCKER_FOR_WINDOWS_URL "https://download.docker.com/win/stable/Docker%20for%20Windows%20Installer.exe"
!define DOCKER_FOR_WINDOWS_PATH "$TEMP\docker_for_windows.exe"
!define DOCKER_TOOLBOX_URL "https://download.docker.com/win/stable/DockerToolbox.exe"
!define DOCKER_TOOLBOX_PATH "$TEMP\docker_toolbox.exe"
!define DOCKER_UNINSTALL_KEY "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Docker for Windows"
!define DATASHARE_UNINSTALL_KEY "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}"
Var shouldReboot

OutFile installDatashare.exe
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
  DetailPrint "Installing docker toolbox for windows"
  inetc::get "${DOCKER_TOOLBOX_URL}" "${DOCKER_TOOLBOX_PATH}" /end
    Pop $0
    DetailPrint "Download Status: $0"
    ${If} $0 != "OK"
      MessageBox MB_OK "Download Failed: $0"
      Abort
    ${EndIf}
    ExecWait '"${DOCKER_TOOLBOX_PATH}" install --quiet'
FunctionEnd

Function InstallDockerForWindows
  DetailPrint "Datashare uses Docker, downloading and installing docker for windows"
  inetc::get "${DOCKER_FOR_WINDOWS_URL}" "${DOCKER_FOR_WINDOWS_PATH}" /end
  Pop $0
  DetailPrint "Download Status: $0"
  ${If} $0 != "OK"
    MessageBox MB_OK "Download Failed: $0"
    Abort
  ${EndIf}
  ExecWait '"${DOCKER_FOR_WINDOWS_PATH}" install --quiet'
FunctionEnd

Function un.InstallDockerForWindows
  MessageBox MB_YESNO|MB_ICONQUESTION "Do you wish to remove docker for windows ?" IDNO +6
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
  file "icij.ico"
  File "datashare.bat"
  File "docker-compose.yml"

  # Start Menu
  createDirectory "$SMPROGRAMS\${COMPANYNAME}"
  createShortCut "$SMPROGRAMS\${COMPANYNAME}\${APPNAME}.lnk" "$INSTDIR\datashare.bat" "" "$INSTDIR\logo.ico"

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
  ${ElseIf} $R0 == "10.0"
     Call InstallDockerForWindows
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
  # this will only happen if it is empty
  rmDir "$SMPROGRAMS\${COMPANYNAME}"

  delete $INSTDIR\datashare.bat
  delete $INSTDIR\docker-compose.yml
  delete $INSTDIR\icij.ico
  delete $INSTDIR\uninstall.exe
  # this will only happen if it is empty
  rmDir $INSTDIR

  ReadRegStr $0 HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "GetWindowsVersion"
  # Remove uninstaller information from the registry
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}"

  ${If} $0 == "10.0"
    Call un.InstallDockerForWindows
  ${Else}
    Call un.InstallDockerToolbox
  ${EndIf}
SectionEnd