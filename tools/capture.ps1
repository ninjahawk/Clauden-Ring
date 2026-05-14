# Screenshot capture tool for Clauden Ring
# Usage: capture.ps1 [-scene <res://path>]
# Default scene: res://scenes/world/Main.tscn (skips main menu)
# Screenshot path: C:\Users\jedin\AppData\Roaming\Godot\app_userdata\Clauden Ring\debug_screenshot.png

param(
    [string]$scene = "res://scenes/world/Main.tscn"
)

$projectPath = "C:\Users\jedin\Desktop\Clauden Ring"
$godotExe = "$env:LOCALAPPDATA\Programs\Godot\Godot_v4.6.2-stable_win64.exe"
$captureScript = "$projectPath\scripts\DebugCapture.gd"
$screenshotPath = "C:\Users\jedin\AppData\Roaming\Godot\app_userdata\Clauden Ring\debug_screenshot.png"

$original = Get-Content $captureScript -Raw
$patched = $original -replace "const ENABLED := false", "const ENABLED := true"
$patched = $patched -replace "const QUIT_AFTER := false", "const QUIT_AFTER := true"
Set-Content $captureScript $patched -Encoding UTF8

Write-Host "Launching game for screenshot capture ($scene)..."
$args = "--path `"$projectPath`" --scene `"$scene`""
$proc = Start-Process -FilePath $godotExe -ArgumentList $args -PassThru
$proc.WaitForExit(20000)

$restored = Get-Content $captureScript -Raw
$restored = $restored -replace "const ENABLED := true", "const ENABLED := false"
$restored = $restored -replace "const QUIT_AFTER := true", "const QUIT_AFTER := false"
Set-Content $captureScript $restored -Encoding UTF8

Write-Host "DebugCapture restored to ENABLED=false"
if (Test-Path $screenshotPath) { Write-Host "Screenshot ready: $screenshotPath" }
else { Write-Host "WARNING: Screenshot not found." }
