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

!define JAVA_REG_KEY "SOFTWARE\AdoptOpenJDK\JRE"
!define DATASHARE_UNINSTALL_KEY "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}"
!define TESSERACT_UNINSTALL_KEY "SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Tesseract-OCR"
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

Function DownloadDatashareJar
    IfFileExists $INSTDIR\app\* PathGood PathNotGood
    PathNotGood:
        DetailPrint "Downloading datashare at : ${DATASHARE_JAR_DOWNLOAD_URL}"
            inetc::get "${DATASHARE_JAR_DOWNLOAD_URL}" "$PROGRAMFILES64\${APPNAME}\${APPNAME}.jar" /end
            Pop $0
            DetailPrint "Download Status: $0"
            ${If} $0 != "OK"
                MessageBox MB_OK "Download Failed: $0"
                Abort
            ${EndIf}
    PathGood:
FunctionEnd

Function InstallDatashareClient
    IfFileExists $INSTDIR\app* PathGood PathNotGood
     PathNotGood:
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
        Goto PathDone

        ; Delete temporary files
        DetailPrint "Remove temporary file : $TEMP\${APPNAME}.tgz"
        Delete "$TEMP\${APPNAME}.tgz"
     PathGood:
        DetailPrint "Datashare already installed"
     PathDone:
FunctionEnd

Function InstallDatashare
  exch $R0
  SetOutPath "$INSTDIR"
  File "datashare.ico"
  File "datashareLight.ps1"
  File /oname=datashareLight.bat "dist/datashareLight.bat"

  # Start Menu
  createDirectory "$SMPROGRAMS\${COMPANYNAME}"
  createShortCut "$SMPROGRAMS\${COMPANYNAME}\${APPNAME}.lnk" "$INSTDIR\datashareLight.bat" "" "$INSTDIR\datashare.ico"

  # Download Jar
  Call DownloadDatashareJar
  # download and unpack client
  Call InstallDatashareClient

  # Data
  createDirectory "$APPDATA\Datashare\models"
  createDirectory "$APPDATA\Datashare\index"
  createDirectory "$APPDATA\Datashare\data"

  # Create symbolic links
  rmDir "$DESKTOP\Datashare Data"
  nsExec::Exec 'cmd /c mklink /d "$DESKTOP\Datashare Data" "$APPDATA\Datashare\data"'
  DetailPrint 'Link created from "$APPDATA\Datashare\data" to "$DESKTOP\Datashare Data"'
  rmDir "$APPDATA\Datashare\app"
  nsExec::Exec 'cmd /c mklink /d $APPDATA\Datashare\app "$INSTDIR\app"'
  DetailPrint 'Link created from "$INSTDIR\app" to "$APPDATA\Datashare\app"'

  writeUninstaller "$INSTDIR\uninstall.exe"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "DisplayName" "${APPNAME}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "UninstallString" "$\"$INSTDIR\uninstall.exe$\""
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "GetWindowsVersion" "$R0"
  pop $R0
FunctionEnd

Function InstallOpenJre64
    #Java lib test
    nsExec::ExecToStack "java -version"
    Pop $0
    Pop $1
    StrCmp $0 "0" JavaFound JavaMissing
    JavaMissing:
        inetc::get "${OPEN_JRE_64_DOWNLOAD_URL}" "${OPEN_JRE_64_PATH}" /end
        Pop $0
        DetailPrint "Download Status: $0"
        ${If} $0 != "OK"
            DetailPrint "Download Failed: $0"
            Abort
        ${EndIf}
        DetailPrint "Installing OpenJRE 8"
        ExecWait 'msiexec.exe /i "${OPEN_JRE_64_PATH}" /QN /L*V "$TEMP\msilog.log"'
        Goto JavaDone
    JavaFound:
        DetailPrint "JRE already installed, version : $1"
    JavaDone:
FunctionEnd

Function InstallTesseractOCR64
    ReadRegStr $0 HKLM "${TESSERACT_UNINSTALL_KEY}" "UninstallString"
    DetailPrint "Tesseract uninstall registry read: $0"
    StrCmp $0 "" TessMissing TessFound
    TessMissing:
        inetc::get "${TESSERACT_OCR_64_DOWNLOAD_URL}" "${TESSERACT_OCR_64_PATH}" /end
        Pop $0
        DetailPrint "Download Status: $0"
        ${If} $0 != "OK"
            MessageBox MB_OK "Download Failed: $0"
            Abort
        ${EndIf}
        DetailPrint "Installing Tesseract"
        ExecWait '"${TESSERACT_OCR_64_PATH}"'
        Goto TessDone
    TessFound:
        DetailPrint "Tesseract already installed"
    TessDone:
FunctionEnd

Function un.installTesseractOCR64
    ReadRegStr $0 HKLM "${TESSERACT_UNINSTALL_KEY}" "QuietUninstallString"
    StrCpy $1 $0
    DetailPrint "Tesseract uninstall registry read: $0"
    StrCmp $0 "" TessUniMissing TessUniFound
    TessUniFound:
        DetailPrint "Uninstalling Tesseract with: $1"
        ExecWait $1
        DetailPrint "Tesseract Uninstalled"
        Goto TessDone
    TessUniMissing:
        DetailPrint "Tesseract uninstaller not found"
    TessDone:
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
  rmDir /r "$APPDATA\Datashare\app"
  MessageBox MB_YESNO|MB_ICONQUESTION "Do you want to remove Datashare data directory ?" IDNO +3
    rmDir /r "$APPDATA\Datashare\data"
    rmDir /r "$DESKTOP\Datashare Data"
  rmDir "$APPDATA\Datashare" # only if empty

  ReadRegStr $0 HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "GetWindowsVersion"
  # Remove uninstaller information from the registry
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}"

  Call un.installTesseractOCR64
SectionEnd
