# Installs the Godot CEF native binaries (Windows x86_64) into addons/godot_cef/bin.
# The addon's .gdextension/config files are committed; only bin/ is gitignored (~430 MB).
# Usage (repo root): pwsh tools/install_godot_cef.ps1 [-Version 2.2.0]
param([string]$Version = "2.2.0")
$ErrorActionPreference = "Stop"

$target = "x86_64-pc-windows-msvc"
$url = "https://github.com/dsh0416/godot-cef/releases/download/v$Version/godot_cef-v$Version.zip"
$zip = Join-Path $env:TEMP "godot_cef-v$Version.zip"
$dest = Join-Path $PSScriptRoot "..\addons\godot_cef"
$prefix = "dist/addons/godot_cef/bin/$target/"

if (-not (Test-Path $zip)) {
	Write-Host "Downloading $url (~1 GB, all platforms)"
	Invoke-WebRequest -Uri $url -OutFile $zip
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [IO.Compression.ZipFile]::OpenRead($zip)
$count = 0
try {
	foreach ($entry in $archive.Entries) {
		$path = $entry.FullName -replace '\\', '/'
		if (-not $path.StartsWith($prefix) -or $path.EndsWith('/')) { continue }
		$out = Join-Path $dest ($path.Substring('dist/addons/godot_cef/'.Length))
		New-Item -ItemType Directory -Force (Split-Path $out) | Out-Null
		[IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $out, $true)
		$count++
	}
} finally {
	$archive.Dispose()
}
Write-Host "Installed $count files into addons/godot_cef/bin/$target. Restart the Godot editor."
