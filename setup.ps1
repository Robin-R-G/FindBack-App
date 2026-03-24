Write-Host "Installing Git..."
winget install --id Git.Git -e --accept-package-agreements --accept-source-agreements --silent

Write-Host "Installing Android Studio..."
winget install --id Google.AndroidStudio -e --accept-package-agreements --accept-source-agreements --silent

Write-Host "Installing OpenJDK 17..."
winget install --id Microsoft.OpenJDK.17 -e --accept-package-agreements --accept-source-agreements --silent

Write-Host "Cloning Flutter SDK..."
mkdir C:\src -ErrorAction SilentlyContinue
cd C:\src
if (-Not (Test-Path "C:\src\flutter")) {
    git clone https://github.com/flutter/flutter.git -b stable
}

Write-Host "Adding Flutter to PATH..."
$userPath = [Environment]::GetEnvironmentVariable("PATH", [EnvironmentVariableTarget]::User)
if ($userPath -notlike "*C:\src\flutter\bin*") {
    [Environment]::SetEnvironmentVariable("PATH", "$userPath;C:\src\flutter\bin", [EnvironmentVariableTarget]::User)
    $env:PATH += ";C:\src\flutter\bin"
}

Write-Host "Running Flutter Doctor to download Dart SDK..."
C:\src\flutter\bin\flutter.bat doctor

Write-Host "Setup Completed."
