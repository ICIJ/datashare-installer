!include LogicLib.nsh
!include GetWindowsVersion.nsh
!include "MUI2.nsh"
!define MUI_ICON "${NSISDIR}\Contrib\Graphics\Icons\modern-install-colorful.ico"
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_LANGUAGE "English"

!define VERSION "0.30"
Name "Datashare ${VERSION}"

!define DOCKER_FOR_WINDOWS_URL "https://download.docker.com/win/stable/Docker%20for%20Windows%20Installer.exe"
!define DOCKER_FOR_WINDOWS_PATH "$TEMP\docker_for_windows.exe"

OutFile installDatashare.exe

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
FunctionEnd

Function InstallDockerForWindows
  DetailPrint "Datashare uses Docker, downloading and installing docker for windows"
  inetc::get "${DOCKER_FOR_WINDOWS_URL}" "${DOCKER_FOR_WINDOWS_PATH}" /end
  Pop $0
  Pop $1
  Pop $2
  DetailPrint "Download Status: $0, $1, $2"
  ExecWait '"${DOCKER_FOR_WINDOWS_PATH}" install --quiet'
FunctionEnd

Section
  ${GetWindowsVersion} $R0
  DetailPrint "Detected Windows $R0"

  nsExec::Exec "docker --version"
  Pop $0
  ${If} $0 == "0"
     DetailPrint "Nice! Docker is already installed"
  ${ElseIf} $R0 == "10.0"
     Call InstallDockerForWindows
  ${Else}
     Call InstallDockerToolbox
  ${EndIf}
SectionEnd