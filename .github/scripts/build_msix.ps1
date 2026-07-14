# Build MSIX package for LWVM Windows release
$ErrorActionPreference = 'Stop'

Write-Host "Building MSIX package..."

# Ensure the MSIX config exists
if (-not (Test-Path "windows/msix_config.yaml")) {
    Write-Error "MSIX config not found at windows/msix_config.yaml"
    exit 1
}

# Run msix pub build
flutter pub run msix:build

# The msix tool creates the package in the build directory
# Ensure it's in the expected location for artifacts
if (Test-Path "build/windows/runner/Release/LWVM.msix") {
    Write-Host "MSIX package created successfully"
} else {
    Write-Error "MSIX package not found after build"
    exit 1
}