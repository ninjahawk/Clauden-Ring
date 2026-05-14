# Runs TestScene, captures console output + screenshots, then reports results.
$projectPath = "C:\Users\jedin\Desktop\Clauden Ring"
$godotExe = "$env:LOCALAPPDATA\Programs\Godot\Godot_v4.6.2-stable_win64.exe"
$logPath = "$env:TEMP\clauden_ring_test.log"

Write-Host "Running tests..."
& $godotExe --path "$projectPath" --scene "res://scenes/TestScene.tscn" 2>&1 | Tee-Object -FilePath $logPath

Write-Host ""
Write-Host "=== Test Screenshots ==="
$screenshotDir = "C:\Users\jedin\AppData\Roaming\Godot\app_userdata\Clauden Ring"
Get-ChildItem "$screenshotDir\test_*.png" -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Host "  $($_.FullName)"
}

Write-Host ""
Write-Host "=== Results ==="
Select-String "PASS:|FAIL:|Passed:|Failed:" $logPath | ForEach-Object { Write-Host $_.Line }
