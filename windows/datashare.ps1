function WaitDockerIsUp {
    Write-Host "Waiting for docker to be up" -NoNewLine
    foreach ($nb in 1..60) {
        docker info 2>($tmpFile=New-TemporaryFile)
        if ($LASTEXITCODE -eq 0) { return 0 }
        Write-Host "." -NoNewLine
        Start-Sleep 1
    }
}

# Test-NetConnection needs PWSH >= 3
function IsPortOpen {
    param([string]$h, [int]$p)

    $socket = new-object Net.Sockets.TcpClient

    $ErrorActionPreference = 'SilentlyContinue'
    $connection = $socket.Connect($h, $p)
    $ErrorActionPreference = 'Continue'

    if($socket.Connected) {
        $socket.Close()
        return $true
    }
    return $false
}

function WaitDatashareIsUp {
    Write-Host "Waiting for datashare to be up." -NoNewLine
    foreach ($nb in 1..60) {
        if ((& IsPortOpen "localhost" 8080) -eq $true) {
            Write-Host "OK"
            Start-Sleep 2 # else page is blank :(
            return
        }
        Write-Host "." -NoNewLine
    }
}


docker info 2>($tmpFile=New-TemporaryFile)
if ($LASTEXITCODE -ne 0) {
    Start-Process 'C:\Program Files\Docker\Docker\Docker for Windows.exe'
    & WaitDockerIsUp
}

$datashare_id = iex "docker-compose -p datashare ps -q datashare"
$datashare_status=""
if ($datashare_id) {
    $datashare_status = iex 'docker inspect $datashare_id -f "{{.State.Status}}"'
}
$mem_size = (Get-WmiObject -Class Win32_ComputerSystem | out-string -stream |Select-String 'TotalPhysicalMemory').toString().split(':')[1].trim()
$mem_allocated = [Int]($mem_size/(2*1024*1024))
$env:DS_JAVA_OPTS = -join("-Xmx", $mem_allocated, "m")

if ($datashare_status -eq "running") {
    docker-compose -p datashare restart datashare
} else {
    docker-compose -p datashare up -d
}

& WaitDatashareIsUp

if ($LASTEXITCODE -eq 0) {
    start "http://localhost:8080"
}
