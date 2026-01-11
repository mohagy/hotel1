# PowerShell script to deploy Flutter web app to GitHub Pages
# This script builds the Flutter app and prepares it for GitHub Pages

Write-Host "Building Flutter web app for GitHub Pages..." -ForegroundColor Green

# Change to Flutter project directory
Set-Location "$PSScriptRoot"

# Check if Flutter is installed
$flutterVersion = flutter --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Flutter is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

Write-Host "Flutter version:" -ForegroundColor Cyan
flutter --version | Select-Object -First 1

# Get dependencies
Write-Host "`nGetting Flutter dependencies..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to get dependencies" -ForegroundColor Red
    exit 1
}

# Build web app with base href for GitHub Pages
Write-Host "`nBuilding web app (this may take a few minutes)..." -ForegroundColor Yellow
flutter build web --base-href /hotel1/
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Build failed" -ForegroundColor Red
    exit 1
}

Write-Host "`n✓ Build completed successfully!" -ForegroundColor Green
Write-Host "`nBuild output is in: build/web" -ForegroundColor Cyan
Write-Host "`nTo deploy to GitHub Pages:" -ForegroundColor Yellow
Write-Host "1. Push your code to GitHub (git push)" -ForegroundColor White
Write-Host "2. GitHub Actions will automatically build and deploy to GitHub Pages" -ForegroundColor White
Write-Host "3. Or manually copy build/web contents to the 'docs' folder and push" -ForegroundColor White

