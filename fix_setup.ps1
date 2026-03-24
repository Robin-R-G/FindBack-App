Write-Host "Installing OpenJDK 21 (for better compatibility with modern Flutter/Gradle)..."
winget install --id Microsoft.OpenJDK.21 -e --accept-package-agreements --accept-source-agreements --silent

Write-Host "Installing Android Studio..."
winget install --id Google.AndroidStudio -e --accept-package-agreements --accept-source-agreements --silent

Write-Host "Verifying installations..."
$javaPath = [Environment]::GetEnvironmentVariable("JAVA_HOME", [EnvironmentVariableTarget]::Machine)
Write-Host "JAVA_HOME: $javaPath"

# Refreshing PATH for this session
$env:PATH += ";C:\src\flutter\bin"
if (Test-Path "C:\Program Files\Microsoft\jdk-21.0.6.7-hotspot\bin") {
    $env:PATH += ";C:\Program Files\Microsoft\jdk-21.0.6.7-hotspot\bin"
}

Write-Host "Checking Java version..."
& java -version

Write-Host "Attempting flutter doctor..."
& flutter.bat doctor
