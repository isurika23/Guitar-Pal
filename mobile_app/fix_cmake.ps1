# Script to replace Visual Studio's old CMake with the new version
# This needs to be run as Administrator

$oldCMakePath = "C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin"
$newCMakePath = "C:\Program Files\CMake\bin"

Write-Host "Backing up old CMake..." -ForegroundColor Yellow
if (Test-Path "$oldCMakePath\cmake.exe") {
    Rename-Item "$oldCMakePath\cmake.exe" "cmake.exe.old.backup" -Force
    Write-Host "Old CMake backed up to cmake.exe.old.backup" -ForegroundColor Green
}

Write-Host "Copying new CMake 4.1.2 to Visual Studio directory..." -ForegroundColor Yellow
Copy-Item "$newCMakePath\cmake.exe" "$oldCMakePath\cmake.exe" -Force
Copy-Item "$newCMakePath\*.dll" "$oldCMakePath\" -Force -ErrorAction SilentlyContinue

Write-Host "CMake updated successfully!" -ForegroundColor Green
Write-Host "You can now run your Flutter app on Windows." -ForegroundColor Cyan
