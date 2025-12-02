# Flutter Web Build Script
# این اسکریپت برای build گرفتن از پروژه Flutter Web استفاده می‌شود

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Flutter Web Build Script" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Step 1: Cleaning Flutter project..." -ForegroundColor Yellow
flutter clean

Write-Host "`nStep 2: Removing old web build folder..." -ForegroundColor Yellow
if (Test-Path "build\web") {
    Remove-Item -Recurse -Force "build\web"
    Write-Host "Old build folder removed!" -ForegroundColor Green
} else {
    Write-Host "No old build folder found." -ForegroundColor Gray
}

Write-Host "`nStep 3: Getting dependencies..." -ForegroundColor Yellow
flutter pub get

Write-Host "`nStep 4: Building web release..." -ForegroundColor Green
flutter build web --release

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Build completed successfully!" -ForegroundColor Green
Write-Host "Output: build\web" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan

