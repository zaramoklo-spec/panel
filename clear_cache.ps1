# Script to clear all browser cache and service workers
# Run this before testing your web app

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Browser Cache Cleaner" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "`nThis script will help you clear browser cache." -ForegroundColor Yellow
Write-Host "Please follow these steps:" -ForegroundColor Yellow

Write-Host "`n1. Open your browser (Chrome/Edge)" -ForegroundColor White
Write-Host "2. Press F12 to open DevTools" -ForegroundColor White
Write-Host "3. Go to 'Application' tab" -ForegroundColor White
Write-Host "4. Click 'Clear storage' in the left sidebar" -ForegroundColor White
Write-Host "5. Check all boxes and click 'Clear site data'" -ForegroundColor White
Write-Host "6. Go to 'Service Workers' and click 'Unregister' for each" -ForegroundColor White
Write-Host "7. Go to 'Cache Storage' and delete all caches" -ForegroundColor White
Write-Host "8. Close DevTools and press Ctrl+Shift+R (Hard Refresh)" -ForegroundColor White

Write-Host "`nOr use Incognito/Private mode:" -ForegroundColor Green
Write-Host "   Press Ctrl+Shift+N (Chrome) or Ctrl+Shift+P (Edge)" -ForegroundColor Green

Write-Host "`n========================================" -ForegroundColor Cyan

# Try to open browser DevTools guide
$openGuide = Read-Host "`nOpen browser DevTools now? (Y/N)"
if ($openGuide -eq "Y" -or $openGuide -eq "y") {
    Write-Host "Opening Chrome DevTools guide..." -ForegroundColor Yellow
    Start-Process "https://developer.chrome.com/docs/devtools/application/manage-data/local-storage"
}



