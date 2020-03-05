!include LogicLib.nsh
!include x64.nsh
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

!define DATASHARE_UNINSTALL_KEY "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}"
!define TESSERACT_UNINSTALL_KEY "Computer\HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Tesseract-OCR"
!define TESSERACT_OCR_64_DOWNLOAD_URL "http://digi.bib.uni-mannheim.de/tesseract/tesseract-ocr-setup-4.00.00dev.exe"
!define TESSERACT_OCR_64_PATH "$TEMP\tesseract-ocr-setup.exe"
!define OPEN_JRE_64_DOWNLOAD_URL "https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/jdk8u242-b08/OpenJDK8U-jre_x64_windows_hotspot_8u242b08.msi"
!define OPEN_JRE_64_PATH "$TEMP\OpenJDK8U-jre_x64_windows_hotspot_8u242b08.msi"
!define DATASHARE_JAR_DOWNLOAD_URL "https://github.com/ICIJ/datashare/releases/download/${VERSION}/datashare-dist-${VERSION}.jar"
!define DATASHARE_FRONT_DOWNLOAD_URL "https://github.com/ICIJ/datashare-client/releases/download/${VERSION}/datashare-client-${VERSION}.tgz"
Var shouldReboot

OutFile dist/installDatashareLight.exe
InstallDir "$PROGRAMFILES64\${APPNAME}"

Function .onInit
  System::Call 'kernel32::CreateMutex(p 0, i 0, t "dsMutex") p .r1 ?e'
  Pop $R0
  ${If} $R0 != "0"
    MessageBox MB_OK|MB_ICONEXCLAMATION "The installer is already running."
    Abort
  ${EndIf}
FunctionEnd

Function un.InstallDockerToolbox
FunctionEnd

Function DownloadDatashareJar
    DetailPrint "Downloading datashare at : ${DATASHARE_JAR_DOWNLOAD_URL}"
    inetc::get "${DATASHARE_JAR_DOWNLOAD_URL}" "$PROGRAMFILES64\${APPNAME}\${APPNAME}.jar" /end
    Pop $0
    DetailPrint "Download Status: $0"
    ${If} $0 != "OK"
        MessageBox MB_OK "Download Failed: $0"
        Abort
    ${EndIf}
FunctionEnd

Function InstallDatashareClient
    DetailPrint "Downloading datashare at : ${DATASHARE_FRONT_DOWNLOAD_URL}"
    inetc::get "${DATASHARE_FRONT_DOWNLOAD_URL}" "$TEMP\${APPNAME}.tgz" /end
    Pop $0
    DetailPrint "Download Status: $0"
    ${If} $0 != "OK"
        MessageBox MB_OK "Download Failed: $0"
        Abort
    ${EndIf}

    DetailPrint "Create directory : $INSTDIR\app"
    createDirectory "$INSTDIR\app"

    DetailPrint "Unpack datashare client in : $INSTDIR\app"
    untgz::extract "-d" "$INSTDIR\app" "$TEMP\${APPNAME}.tgz"
    StrCmp $R0 "success" +4
    	DetailPrint "Failed to extract $TEMP\${APPNAME}.tgz"
    	MessageBox MB_OK|MB_ICONEXCLAMATION|MB_DEFBUTTON1 "Failed to extract $TEMP\${APPNAME}.tgz"
    	Abort

    ; Delete temporary files
    DetailPrint "Remove temporary file : $TEMP\${APPNAME}.tgz"
    Delete "$TEMP\${APPNAME}.tgz"
FunctionEnd

Function InstallDatashare
  exch $R0
  SetOutPath "$INSTDIR"
  File "datashare.ico"
  File "datashareLight.bat"
  File "PortQry.exe"

  # Start Menu
  createDirectory "$SMPROGRAMS\${COMPANYNAME}"
  createShortCut "$SMPROGRAMS\${COMPANYNAME}\${APPNAME}.lnk" "$INSTDIR\datashareLight.bat" "" "$INSTDIR\logo.ico"

  # Download Jar
  Call DownloadDatashareJar
  # download and unpack client
  Call InstallDatashareClient

  # Data
  createDirectory "$APPDATA\Datashare\models"
  createDirectory "$APPDATA\Datashare\index"
  createDirectory "$APPDATA\Datashare\data"
  CreateShortcut "$DESKTOP\Datashare Data.lnk" "$APPDATA\Datashare\data"

  writeUninstaller "$INSTDIR\uninstall.exe"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "DisplayName" "${APPNAME}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "UninstallString" "$\"$INSTDIR\uninstall.exe$\""
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "GetWindowsVersion" "$R0"
  pop $R0
FunctionEnd

Function InstallOpenJre64
    inetc::get "${OPEN_JRE_64_DOWNLOAD_URL}" "${OPEN_JRE_64_PATH}" /end
    Pop $0
    DetailPrint "Download Status: $0"
    ${If} $0 != "OK"
        MessageBox MB_OK "Download Failed: $0"
        Abort
    ${EndIf}
    DetailPrint "Installing OpenJRE 8"
    ExecWait 'msiexec.exe /i "${OPEN_JRE_64_PATH}" /QN /L*V "$TEMP\msilog.log"'
FunctionEnd

Function InstallTesseractOCR64
    ReadRegStr $0 HKLM "${TESSERACT_UNINSTALL_KEY}" "QuietUninstallString"
    DetailPrint "Tesseract uninstall registry read: $0"
    ${If} $0 != "OK"
        inetc::get "${TESSERACT_OCR_64_DOWNLOAD_URL}" "${TESSERACT_OCR_64_PATH}" /end
        Pop $0
        DetailPrint "Download Status: $0"
        ${If} $0 != "OK"
            MessageBox MB_OK "Download Failed: $0"
            Abort
        ${EndIf}
        DetailPrint "Installing Tesseract"
        ExecWait '"${TESSERACT_OCR_64_PATH}"'
    ${EndIf}
FunctionEnd

Function un.InstallTesseractOCR64
# TODO
FunctionEnd

Section "install"
  StrCpy $shouldReboot "false"
  ${GetWindowsVersion} $R0
  DetailPrint "Detected Windows $R0"

  ${If} ${RunningX64}
    Call InstallOpenJre64
    Call InstallTesseractOCR64

  ${Else}
    MessageBox MB_OK "Sorry, datashare can only be installed on a 64 bits machine"
    Abort
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
  rmDir /r "$APPDATA\Datashare\models"
  rmDir /r "$APPDATA\Datashare\index"
  MessageBox MB_YESNO|MB_ICONQUESTION "Do you want to remove Datashare data directory ?" IDNO +3
    rmDir /r "$APPDATA\Datashare\data"
    delete "$DESKTOP\Datashare Data.lnk"
  rmDir "$APPDATA\Datashare" # only if empty

  ReadRegStr $0 HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "GetWindowsVersion"
  # Remove uninstaller information from the registry
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}"

  Call un.InstallTesseractOCR64
SectionEnd