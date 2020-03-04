@echo off

set mem_size=
for /f "skip=1" %%a in ('wmic os get totalvirtualmemorysize') do (
    set mem_size=%%a
    goto :done
)
:done
set /a mem_allocated=mem_size/(2*1024)
set DS_JAVA_OPTS=-Xmx%mem_allocated%m

"\Program Files\AdoptOpenJDK\jre-8.0.242.08-hotspot\bin\java.exe" -cp "\Program Files\Datashare-5.8.2\Datashare-5.8.2.jar:%APPDATA%\Datashare\data" org.icij.datashare.Main -d "%APPDATA%\Datashare\data" --queueType memory --busType memory --mode EMBEDDED
