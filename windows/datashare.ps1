$ret = iex "docker info"
if ($?) { $ret }
else {
    "docker is not running, launching it"
    iex "& C:\Program Files\Docker\Docker\Docker for Windows.exe"
}

function WaitDatashareIsUp {
    foreach ($nb in 1..60) {
        $ret = Test-NetConnection -ComputerName "localhost" -Port 8080
        $ret
    }
}

$datashare_id = iex "docker-compose -p datashare ps -q datashare"
$datashare_status=""
if ($datashare_id) {
    docker inspect $datashare_id -f "{{.State.Status}}"
}
$mem_size = (systeminfo | Select-String 'Total Physical Memory:').ToString().Split(':')[1].Trim()
$mem_allocated = $mem_size/(2*1024)
$env:DS_JAVA_OPTS = "-Xmx$mem_allocated"

if ($datashare_status -eq "running") {
    iex "docker-compose -p datashare restart datashare"
} else {
    iex "docker-compose -p datashare up -d"
}

& WaitDatashareIsUp

if ($LASTEXITCODE -eq 0) {
    start "http://localhost:8080"
}
