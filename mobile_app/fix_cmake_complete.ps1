# Script to properly replace Visual Studio's CMake with the new version
# This needs to be run as Administrator

$vsCMakeDir = "C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake"
$newCMakeDir = "C:\Program Files\CMake"

Write-Host "Backing up Visual Studio's CMake installation..." -ForegroundColor Yellow
if (Test-Path "$vsCMakeDir\bin\cmake.exe") {
    $backupDir = "$vsCMakeDir.old.backup"
    if (Test-Path $backupDir) {
        Remove-Item $backupDir -Recurse -Force
    }
    Rename-Item $vsCMakeDir $backupDir -Force
    Write-Host "Old CMake backed up to: $backupDir" -ForegroundColor Green
}

Write-Host "Creating symbolic link to new CMake..." -ForegroundColor Yellow
New-Item -ItemType SymbolicLink -Path $vsCMakeDir -Target $newCMakeDir -Force

Write-Host "CMake updated successfully!" -ForegroundColor Green
Write-Host "Visual Studio will now use CMake 4.1.2" -ForegroundColor Cyan
