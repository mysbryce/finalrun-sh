# Starts 1 headless server and N windowed clients for a local smoke test.
# Usage (repo root): pwsh tools/smoke_local.ps1 [-Clients 3] [-UiDev] [-Stop]
param([int]$Clients = 3, [switch]$UiDev, [switch]$Stop)
$ErrorActionPreference = "Stop"

$root = Resolve-Path (Join-Path $PSScriptRoot "..")
$logDir = Join-Path $root ".smoke"
$pidFile = Join-Path $logDir "pids.txt"
$readyLine = "[Main] Dedicated server on port"
New-Item -ItemType Directory -Force $logDir | Out-Null

function Stop-SmokeProcesses {
	if (-not (Test-Path $pidFile)) { return }
	foreach ($line in Get-Content $pidFile) {
		$id = 0
		if (-not [int]::TryParse($line.Trim(), [ref]$id)) { continue }
		$proc = Get-Process -Id $id -ErrorAction SilentlyContinue
		if ($proc) {
			Stop-Process -Id $id -Force -ErrorAction SilentlyContinue
			Write-Host "Stopped PID $id"
		}
	}
	Remove-Item $pidFile -Force
}

if ($Stop) {
	Stop-SmokeProcesses
	exit 0
}

Stop-SmokeProcesses

$serverLog = Join-Path $logDir "server.log"
$serverErr = Join-Path $logDir "server.err.log"
$server = Start-Process -FilePath "godot_console" `
	-ArgumentList @("--headless", "--path", "`"$root`"", "--", "--server") `
	-RedirectStandardOutput $serverLog -RedirectStandardError $serverErr `
	-WindowStyle Hidden -PassThru
$pids = @($server.Id)
Set-Content -Path $pidFile -Value $pids

$deadline = (Get-Date).AddSeconds(15)
$ready = $false
while ((Get-Date) -lt $deadline) {
	if ((Test-Path $serverLog) -and (Select-String -Path $serverLog -SimpleMatch $readyLine -Quiet)) {
		$ready = $true
		break
	}
	Start-Sleep -Milliseconds 250
}
if (-not $ready) {
	Write-Host "Server not ready after 15 s. Last 20 lines of ${serverLog}:"
	if (Test-Path $serverLog) { Get-Content $serverLog -Tail 20 }
	exit 1
}
Write-Host "Server ready (PID $($server.Id))"

$positions = @("0,0", "980,0", "0,580", "980,580")
for ($i = 1; $i -le $Clients; $i++) {
	$clientArgs = @("--path", "`"$root`"", "--position", $positions[($i - 1) % $positions.Count], "--resolution", "960x540")
	if ($UiDev) { $clientArgs += @("--", "--ui-dev") }
	$client = Start-Process -FilePath "godot" -ArgumentList $clientArgs `
		-RedirectStandardOutput (Join-Path $logDir "client$i.log") `
		-RedirectStandardError (Join-Path $logDir "client$i.err.log") `
		-PassThru
	$pids += $client.Id
	Write-Host "Client $i started (PID $($client.Id))"
}

Set-Content -Path $pidFile -Value $pids
Write-Host "PIDs: $($pids -join ', ')"
Write-Host "Logs: $logDir"
Write-Host "Stop: pwsh tools/smoke_local.ps1 -Stop"
