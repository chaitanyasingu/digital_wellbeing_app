# Digital Mindfulness - Quick Deploy Script
# This script helps you quickly test on your phone

Write-Host "=== Digital Mindfulness - Phone Deployment ===" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check Flutter
Write-Host "[1/4] Checking Flutter installation..." -ForegroundColor Yellow
flutter --version
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Flutter not found! Please install Flutter SDK." -ForegroundColor Red
    exit 1
}
Write-Host "✅ Flutter OK" -ForegroundColor Green
Write-Host ""

# Step 2: Check device connection
Write-Host "[2/4] Checking for connected devices..." -ForegroundColor Yellow
$devices = flutter devices --device-timeout 10
Write-Host $devices
if ($devices -match "No devices found") {
    Write-Host "❌ No devices found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Make sure:" -ForegroundColor Yellow
    Write-Host "  1. USB debugging is enabled on your phone"
    Write-Host "  2. Phone is connected via USB cable"
    Write-Host "  3. You allowed USB debugging popup on phone"
    Write-Host ""
    Write-Host "Run this script again after connecting your device."
    exit 1
}
Write-Host "✅ Device connected" -ForegroundColor Green
Write-Host ""

# Step 3: Clean build
Write-Host "[3/4] Cleaning previous builds..." -ForegroundColor Yellow
flutter clean
flutter pub get
Write-Host "✅ Clean complete" -ForegroundColor Green
Write-Host ""

# Step 4: Build and run
Write-Host "[4/4] Building and installing app..." -ForegroundColor Yellow
Write-Host ""
Write-Host "Starting app on your device..." -ForegroundColor Cyan
Write-Host "This will take 1-3 minutes..." -ForegroundColor Gray
Write-Host ""

flutter run

# End
Write-Host ""
Write-Host "=== Deployment Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "📱 App should now be running on your phone!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Grant notification permission"
Write-Host "  2. Configure your restriction times"
Write-Host "  3. Select allowed apps"
Write-Host "  4. Enable enforcement"
Write-Host "  5. Grant accessibility permission"
Write-Host ""
Write-Host "See DEPLOYMENT_GUIDE.md for full instructions." -ForegroundColor Cyan
