# Script to clean build files and rebuild Flutter web
# This will remove all build artifacts but keep source files

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Flutter Web Clean & Rebuild" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "`nStep 1: Cleaning Flutter project..." -ForegroundColor Yellow
flutter clean

Write-Host "`nStep 2: Removing build folder..." -ForegroundColor Yellow
if (Test-Path "build") {
    Remove-Item -Recurse -Force "build"
    Write-Host "Build folder removed!" -ForegroundColor Green
} else {
    Write-Host "No build folder found." -ForegroundColor Gray
}

Write-Host "`nStep 3: Cleaning web build artifacts (keeping source files)..." -ForegroundColor Yellow
# Remove only build-generated files from web folder, keep source files
$filesToRemove = @(
    "web\main.dart.js",
    "web\flutter_service_worker.js",
    "web\flutter_bootstrap.js",
    "web\flutter.js",
    "web\version.json",
    "web\assets",
    "web\canvaskit"
)

foreach ($file in $filesToRemove) {
    if (Test-Path $file) {
        Remove-Item -Recurse -Force $file
        Write-Host "Removed: $file" -ForegroundColor Gray
    }
}

Write-Host "`nSource files kept:" -ForegroundColor Green
Write-Host "  - web\index.html" -ForegroundColor White
Write-Host "  - web\manifest.json" -ForegroundColor White
Write-Host "  - web\favicon.png" -ForegroundColor White
Write-Host "  - web\icons\" -ForegroundColor White

Write-Host "`nStep 4: Getting dependencies..." -ForegroundColor Yellow
flutter pub get

Write-Host "`nStep 5: Building web release..." -ForegroundColor Green
flutter build web --release

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Clean & Rebuild completed!" -ForegroundColor Green
Write-Host "Output: build\web" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "`nAll build artifacts have been removed and rebuilt." -ForegroundColor Yellow
Write-Host "This should fix any caching issues!" -ForegroundColor Yellow



