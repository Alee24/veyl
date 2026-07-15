# Veyl Web and Landing Page Compilation Script

Write-Host "1. Building Flutter Web Client..."
cd frontend
& "C:\Users\Metto\Desktop\Flutter\bin\flutter.bat" build web

Write-Host "2. Preparing backend/public directory..."
cd ..
if (Test-Path "backend/public") {
    Remove-Item "backend/public" -Recurse -Force
}
New-Item -ItemType Directory -Path "backend/public" -Force

Write-Host "3. Copying Web Client files to backend/public..."
Copy-Item -Path "frontend/build/web/*" -Destination "backend/public/" -Recurse -Force

Write-Host "4. Setting up app.html (Web App) and index.html (Landing Page)..."
if (Test-Path "backend/public/index.html") {
    Move-Item -Path "backend/public/index.html" -Destination "backend/public/app.html" -Force
}

# Copy custom landing page as root index.html
Copy-Item -Path "backend/landing.html" -Destination "backend/public/index.html" -Force

# Copy App Logo to public directory for the landing page
if (Test-Path "frontend/assets/icon/app_icon.png") {
    Copy-Item -Path "frontend/assets/icon/app_icon.png" -Destination "backend/public/app_icon.png" -Force
}

Write-Host "=========================================================="
Write-Host "Web client build and landing page configuration completed!"
Write-Host "=========================================================="
