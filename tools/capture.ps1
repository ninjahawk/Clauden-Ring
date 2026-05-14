# Screenshot capture tool for Clauden Ring
# Patches DebugCapture, launches game, waits for exit, screenshot is at:
# C:\Users\jedin\AppData\Roaming\Godot\app_userdata\Clauden Ring\debug_screenshot.png

$projectPath = "C:\Users\jedin\Desktop\Clauden Ring"
$godotExe = "$env:LOCALAPPDATA\Programs\Godot\Godot_v4.6.2-stable_win64.exe"
$captureScript = "$projectPath\scripts\DebugCapture.gd"
$screenshotPath = "C:\Users\jedin\AppData\Roaming\Godot\app_userdata\Clauden Ring\debug_screenshot.png"

# Patch ENABLED=true and QUIT_AFTER=true
$original = Get-Content $captureScript -Raw
$patched = $original -replace "const ENABLED := false", "const ENABLED := true"
$patched = $patched -replace "const QUIT_AFTER := false", "const QUIT_AFTER := true"
Set-Content $captureScript $patched -Encoding UTF8

Write-Host "Launching game for screenshot capture..."
$proc = Start-Process -FilePath $godotExe -ArgumentList "--path `"$projectPath`"" -PassThru
$proc.WaitForExit(15000)

# Always restore ENABLED=false regardless of outcome
$restored = Get-Content $captureScript -Raw
$restored = $restored -replace "const ENABLED := true", "const ENABLED := false"
$restored = $restored -replace "const QUIT_AFTER := true", "const QUIT_AFTER := false"
Set-Content $captureScript $restored -Encoding UTF8

Write-Host "DebugCapture restored to ENABLED=false"

if (Test-Path $screenshotPath) {
    Write-Host "Screenshot ready: $screenshotPath"
} else {
    Write-Host "WARNING: Screenshot not found at expected path."
}
