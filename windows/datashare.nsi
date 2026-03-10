!include LogicLib.nsh
!include x64.nsh
!include GetWindowsVersion.nsh
!include "MUI2.nsh"
!include StrFunc.nsh
${StrStr}
!define MUI_ICON "${NSISDIR}\Contrib\Graphics\Icons\modern-install-colorful.ico"
!define MUI_WELCOMEFINISHPAGE_BITMAP "welcome.bmp"
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_LANGUAGE "English"

!define VERSION "$%VERSION%"
!define COMPANYNAME "ICIJ"
!define APPNAME "$%APPNAME%"

Name "${APPNAME} ${VERSION}"
Icon "datashare.ico"

!define JAVA_REG_KEY "SOFTWARE\AdoptOpenJDK\JRE"
!define DATASHARE_UNINSTALL_KEY "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}"
!define TESSERACT_UNINSTALL_KEY "SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Tesseract-OCR"
!define TESSERACT_OCR_64_DOWNLOAD_URL "https://digi.bib.uni-mannheim.de/tesseract/tesseract-ocr-w64-setup-v4.0.0.20181030.exe"
!define TESSERACT_OCR_64_PATH "$TEMP\tesseract-ocr-setup-4.exe"
!define OPEN_JRE_64_DOWNLOAD_URL "https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.5%2B11/OpenJDK21U-jre_x64_windows_hotspot_21.0.5_11.msi"
!define OPEN_JRE_64_PATH "$TEMP\openjdk-jre-x64-windows-hotspot-21.msi"
!define DATASHARE_JAR_FILENAME "datashare-dist-${VERSION}-all.jar"
!define DATASHARE_JAR_DOWNLOAD_URL "https://github.com/ICIJ/datashare/releases/download/${VERSION}/${DATASHARE_JAR_FILENAME}"
!define ELASTICSEARCH_VERSION "8.19.8"
!define ELASTICSEARCH_ARCH "x86_64"
!define ELASTICSEARCH_ARCHIVE "elasticsearch-${ELASTICSEARCH_VERSION}-windows-${ELASTICSEARCH_ARCH}.zip"
!define ELASTICSEARCH_ARCHIVE_DIR "elasticsearch-${ELASTICSEARCH_VERSION}-windows-${ELASTICSEARCH_ARCH}"
!define ELASTICSEARCH_DOWNLOAD_URL "https://artifacts.elastic.co/downloads/elasticsearch/${ELASTICSEARCH_ARCHIVE}"
!define ELASTICSEARCH_MODULES "aggregations|analysis-common|apm|constant-keyword|ingest-attachment|ingest-common|ingest-geoip|ingest-user-agent|lang-painless|parent-join|reindex|rest-root|transport-netty4|x-pack-core|x-pack-geoip-enterprise-downloader|x-pack-security"


OutFile "dist/datashare-${VERSION}.exe"
InstallDir "$APPDATA\Datashare"

!macro GetParent UN
Function ${UN}GetParent
  Exch $R0
  Push $R1
  Push $R2
  Push $R3

  StrCpy $R1 0
  StrLen $R2 $R0
  loop:
    IntOp $R1 $R1 + 1
    IntCmp $R1 $R2 get 0 get
    StrCpy $R3 $R0 1 -$R1
    StrCmp $R3 "\" get
  Goto loop
  get:
    StrCpy $R0 $R0 -$R1

    Pop $R3
    Pop $R2
    Pop $R1
    Exch $R0
FunctionEnd
!macroend
!insertmacro GetParent ""
!insertmacro GetParent "un."

Function IsModuleInList
  # Stack: module_name, list_string (pipe-separated)
  Exch $R0  # list_string
  Exch
  Exch $R1  # module_name
  Push $R2
  Push $R3

  StrCpy $R2 "|$R0|"  # Add delimiters
  StrCpy $R3 "|$R1|"  # Add delimiters to search

  ${StrStr} $R2 $R2 $R3
  StrCmp $R2 "" not_found found

  found:
    StrCpy $R0 "1"
    Goto done
  not_found:
    StrCpy $R0 "0"

  done:
  Pop $R3
  Pop $R2
  Pop $R1
  Exch $R0
FunctionEnd

Function .onInit
  System::Call 'kernel32::CreateMutex(p 0, i 0, t "dsMutex") p .r1 ?e'
  Pop $R0
  ${If} $R0 != "0"
    MessageBox MB_OK|MB_ICONEXCLAMATION "The installer is already running."
    Abort
  ${EndIf}
FunctionEnd

Function DownloadDatashareJar
    IfFileExists "$INSTDIR\${DATASHARE_JAR_FILENAME}" PathGood PathNotGood
    PathNotGood:
        DetailPrint "Downloading Datashare from: ${DATASHARE_JAR_DOWNLOAD_URL}"
        inetc::get "${DATASHARE_JAR_DOWNLOAD_URL}" "$INSTDIR\${DATASHARE_JAR_FILENAME}" /end
        Pop $0
        DetailPrint "Download Status: $0"
        ${If} $0 != "OK"
            MessageBox MB_OK "Download Failed: $0"
            Abort
        ${EndIf}
    PathGood:
FunctionEnd

Function InstallDatashare
  exch $R0
  SetOutPath "$INSTDIR"
  File "datashare.ico"
  File /oname=datashare.bat "dist/datashare.bat"

  # Start Menu
  createDirectory "$SMPROGRAMS\${COMPANYNAME}"
  createShortCut "$SMPROGRAMS\${COMPANYNAME}\${APPNAME}.lnk" "$INSTDIR\datashare.bat" "" "$INSTDIR\datashare.ico"

  # Download Jar
  Call DownloadDatashareJar

  # Data
  createDirectory "$APPDATA\Datashare\dist"
  createDirectory "$APPDATA\Datashare\index"
  createDirectory "$APPDATA\Datashare\data"
  createDirectory "$APPDATA\Datashare\plugins"
  createDirectory "$APPDATA\Datashare\extensions"
  createDirectory "$APPDATA\Datashare\downloads"

  # Create symbolic links
  rmDir "$DESKTOP\Datashare Data"
  nsExec::Exec 'cmd /c mklink /d "$DESKTOP\Datashare Data" "$APPDATA\Datashare\data"'
  DetailPrint 'Link created from "$APPDATA\Datashare\data" to "$DESKTOP\Datashare Data"'

  writeUninstaller "$INSTDIR\uninstall.exe"
  WriteRegStr HKLM "${DATASHARE_UNINSTALL_KEY}" "DisplayName" "${APPNAME}"
  WriteRegStr HKLM "${DATASHARE_UNINSTALL_KEY}" "UninstallString" "$\"$INSTDIR\uninstall.exe$\""
  WriteRegStr HKLM "${DATASHARE_UNINSTALL_KEY}" "GetWindowsVersion" "$R0"
  pop $R0
FunctionEnd

Function UninstallPreviousDatashare
  ClearErrors
  FindFirst $0 $1 "$PROGRAMFILES64\Datashare*"
  loop:
    IfErrors done
    DetailPrint "Found previous datashare $1 calling uninstall"
    ExecWait "$PROGRAMFILES64\$1\uninstall.exe /S"
    IfErrors 0 +2
    DetailPrint "Uninstall of $1 failed"
    FindNext $0 $1
    Goto loop
  done:
    FindClose $0
FunctionEnd

Function InstallOpenJre64
    #Java lib test
    nsExec::ExecToStack '"$SYSDIR\cmd.exe" /c where -f java | findstr -R "[jdk|jre]-" | findstr -R -v "[jdk|jre]-[0-9]\. [jdk|jre]-1[0-6]"'
    Pop $0
    Pop $1
    StrCmp $0 1 JavaMissing JavaFound
    JavaMissing:
        DetailPrint "Downloading OpenJRE from: ${OPEN_JRE_64_DOWNLOAD_URL}"
        inetc::get "${OPEN_JRE_64_DOWNLOAD_URL}" "${OPEN_JRE_64_PATH}" /end
        Pop $0
        DetailPrint "Download Status: $0"
        ${If} $0 != "OK"
            DetailPrint "Download Failed: $0"
            Abort
        ${EndIf}
        DetailPrint "Installing OpenJRE"
        ExecWait 'msiexec.exe /i "${OPEN_JRE_64_PATH}" /QN /L*V "$TEMP\msilog.log"'
        Goto JavaDone
    JavaFound:
        DetailPrint "Java already installed"
    JavaDone:
FunctionEnd

Function InstallTesseractOCR64
    ReadRegStr $0 HKLM "${TESSERACT_UNINSTALL_KEY}" "UninstallString"
    DetailPrint "Tesseract uninstall registry read: $0"
    StrCmp $0 "" TessMissing TessFound
    TessMissing:
        DetailPrint "Downloading Tesseract from: ${TESSERACT_OCR_64_DOWNLOAD_URL}"
        inetc::get "${TESSERACT_OCR_64_DOWNLOAD_URL}" "${TESSERACT_OCR_64_PATH}" /end
        Pop $0
        DetailPrint "Download Status: $0"
        ${If} $0 != "OK"
            MessageBox MB_OK "Download Failed: $0"
            Abort
        ${EndIf}
        DetailPrint "Installing Tesseract"
        ExecWait '"${TESSERACT_OCR_64_PATH}"'

        # Check and add to PATH
        ReadRegStr $1 HKLM "${TESSERACT_UNINSTALL_KEY}" "UninstallString"
        Push $1
        Call GetParent
        Pop $R0
        EnVar::Check "Path" $R0
        Pop $0
        ${If} $0 != 0
           DetailPrint "Adding Tesseract to Environment Variable Path : $R0"
           EnVar::AddValue "Path" $R0
           Pop $0
           DetailPrint "Tesseract added to PATH"
        ${Else}
           DetailPrint "Tesseract already in PATH"
        ${EndIf}
        Goto TessDone
    TessFound:
        DetailPrint "Tesseract already installed"
    TessDone:
FunctionEnd

Function InstallElasticsearch
    # Define Elasticsearch home directory
    StrCpy $R9 "$APPDATA\Datashare\elasticsearch"

    DetailPrint "Detected platform: windows-${ELASTICSEARCH_ARCH}"

    # Check if Elasticsearch is already installed
    IfFileExists "$R9\elasticsearch-${ELASTICSEARCH_VERSION}\*.*" ESAlreadyInstalled ESNotInstalled

    ESNotInstalled:
        DetailPrint "Downloading Elasticsearch ${ELASTICSEARCH_VERSION}..."
        CreateDirectory "$R9"

        # Check if archive already downloaded
        IfFileExists "$R9\${ELASTICSEARCH_ARCHIVE}" ESExtract ESDownload

        ESDownload:
            inetc::get "${ELASTICSEARCH_DOWNLOAD_URL}" "$R9\${ELASTICSEARCH_ARCHIVE}" /end
            Pop $0
            DetailPrint "Download Status: $0"
            ${If} $0 != "OK"
                DetailPrint "Warning: Elasticsearch download failed: $0"
                Goto ESDone
            ${EndIf}
            DetailPrint "Download complete"

        ESExtract:
            DetailPrint "Extracting Elasticsearch..."

            # Remove old installation if exists
            RMDir /r "$R9\elasticsearch-${ELASTICSEARCH_VERSION}"

            # Extract using PowerShell
            nsExec::ExecToLog 'powershell -Command "& {Expand-Archive -Path \"$R9\${ELASTICSEARCH_ARCHIVE}\" -DestinationPath \"$R9\" -Force}"'
            Pop $0
            ${If} $0 != 0
                DetailPrint "Warning: Elasticsearch extraction failed with code $0"
                Goto ESDone
            ${EndIf}

            DetailPrint "Extraction complete"

            DetailPrint "Moving Elasticsearch directory to $R9\elasticsearch-${ELASTICSEARCH_VERSION}..."

            Rename "$R9\${ELASTICSEARCH_ARCHIVE_DIR}" "$R9\elasticsearch-${ELASTICSEARCH_VERSION}"
            delete "$R9\${ELASTICSEARCH_ARCHIVE}"
            RMDir /r "$R9\${ELASTICSEARCH_ARCHIVE_DIR}"

            DetailPrint "Cleaning unnecessary modules..."
            DetailPrint "Module directory: $R9\elasticsearch-${ELASTICSEARCH_VERSION}\modules"
            # Keep only required modules defined in ELASTICSEARCH_MODULES
            ClearErrors
            FindFirst $0 $1 "$R9\elasticsearch-${ELASTICSEARCH_VERSION}\modules\*.*"
            module_loop:
                DetailPrint "FindFirst/Next result - handle: $0 | item: $1"
                IfErrors module_done
                DetailPrint "Found item: $1"
                # Skip . and ..
                StrCmp $1 "." module_next
                StrCmp $1 ".." module_next
                # Check if it's a directory
                DetailPrint "Testing if directory: $R9\elasticsearch-${ELASTICSEARCH_VERSION}\modules\$1"
                IfFileExists "$R9\elasticsearch-${ELASTICSEARCH_VERSION}\modules\$1\*.*" 0 module_next
                # Check if module is in the keep list
                DetailPrint "Checking module: $1"
                Push $1
                Push "${ELASTICSEARCH_MODULES}"
                Call IsModuleInList
                Pop $2
                DetailPrint "IsModuleInList returned: $2 for module: $1"
                ${If} $2 == "0"
                    # Module not in the keep list, delete it
                    DetailPrint "Removing module: $1"
                    nsExec::ExecToLog 'cmd /c rmdir /s /q "$R9\elasticsearch-${ELASTICSEARCH_VERSION}\modules\$1"'
                    Pop $3
                    DetailPrint "Delete returned: $3"
                    ${If} $3 != 0
                        DetailPrint "Warning: Failed to remove module $1 (error code: $3)"
                    ${EndIf}
                ${EndIf}
                module_next:
                FindNext $0 $1
                Goto module_loop
            module_done:
            FindClose $0
            DetailPrint "Module cleanup complete"

            # Create symbolic links
            nsExec::Exec 'cmd /c mklink /d "$R9\current" "$R9\elasticsearch-${ELASTICSEARCH_VERSION}"'
            DetailPrint 'Link created from "$R9\elasticsearch-${ELASTICSEARCH_VERSION}" to "$R9\current"'

            DetailPrint "Elasticsearch ${ELASTICSEARCH_VERSION} installed successfully at $R9"
            Goto ESComplete

    ESAlreadyInstalled:
        DetailPrint "Elasticsearch ${ELASTICSEARCH_VERSION} already installed at $R9"
        DetailPrint "Skipping download and extraction"
        Goto ESComplete

    ESComplete:
        DetailPrint "Installation complete"
        DetailPrint "Note: Configuration will be handled by Datashare at runtime"

    ESDone:
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

        # Check and delete to PATH
        ReadRegStr $0 HKLM "${TESSERACT_UNINSTALL_KEY}" "UninstallString"
        Push $0
        Call un.GetParent
        Pop $R0
        EnVar::Check "Path" $R0
        Pop $0
        ${If} $0 == 0
           DetailPrint "Deleting Tesseract to Environment Variable Path : $R0"
           EnVar::DeleteValue "Path" $R0
           DetailPrint "Tesseract deleted from Path"
        ${EndIf}
        Goto TessDone
    TessUniMissing:
        DetailPrint "Tesseract uninstaller not found"
    TessDone:
FunctionEnd

Section "install"
  ${GetWindowsVersion} $R0
  DetailPrint "Detected Windows $R0"
  Call UninstallPreviousDatashare

  ${If} ${RunningX64}
    Call InstallOpenJre64
    Call InstallTesseractOCR64
    Call InstallElasticsearch

  ${Else}
    MessageBox MB_OK "Datashare can only be installed on a 64 bits machine"
    Abort
  ${EndIf}

  Push $R0
  Call InstallDatashare
SectionEnd

section "uninstall"
  delete "$SMPROGRAMS\${COMPANYNAME}\${APPNAME}.lnk"
  rmDir "$SMPROGRAMS\${COMPANYNAME}" # only if empty

  # delete files of installation directory (except folders)
  FindFirst $0 $1 "$INSTDIR\*.*"
  loop:
    IfErrors done
    IfFileExists "$INSTDIR\$1\*" skip_file
      Delete "$INSTDIR\$1"
    skip_file:
    FindNext $0 $1
    Goto loop
  done:
  FindClose $0
  rmDir "$INSTDIR" # only if empty

  # data
  IfSilent +12
    rmDir /r "$APPDATA\Datashare\dist"
    rmDir /r "$APPDATA\Datashare\index"
    rmDir /r "$APPDATA\Datashare\plugins"
    rmDir /r "$APPDATA\Datashare\extensions"

    MessageBox MB_YESNO|MB_ICONQUESTION "Do you want to remove Elasticsearch installation ?" IDNO +2
      rmDir /r "$APPDATA\Datashare\elasticsearch"

    MessageBox MB_YESNO|MB_ICONQUESTION "Do you want to remove Datashare data directory ?" IDNO +3
      rmDir /r "$APPDATA\Datashare\data"
      rmDir /r "$DESKTOP\Datashare Data"
    rmDir "$APPDATA\Datashare" # only if empty

  ReadRegStr $0 HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "GetWindowsVersion"
  # Remove uninstaller information from the registry
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}"
  IfSilent +2
    Call un.installTesseractOCR64
SectionEnd
