# Environment Setup and Check Script for Harmony Demo
Write-Host "=== Harmony Demo Environment Setup ===" -ForegroundColor Cyan
Write-Host ""

# Check if conda is available
try {
    $condaPath = "C:\Users\LZ\anaconda3\Scripts\conda.exe"
    if (Test-Path $condaPath) {
        Write-Host "✓ Conda found at: $condaPath" -ForegroundColor Green
    } else {
        Write-Host "✗ Conda not found!" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "✗ Error checking conda: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Check if harmony_demo environment exists
$envPath = "C:\Users\LZ\anaconda3\envs\harmony_demo"
if (Test-Path $envPath) {
    Write-Host "✓ Environment 'harmony_demo' exists" -ForegroundColor Green
    
    # Check Python version
    $pythonPath = "$envPath\python.exe"
    if (Test-Path $pythonPath) {
        $version = & $pythonPath --version
        Write-Host "✓ Python version: $version" -ForegroundColor Green
    }
    
    # Check if dependencies are installed
    Set-Location "D:\Share_D\Internship\Harmony10_demo\be"
    Write-Host "Checking dependencies..." -ForegroundColor Yellow
    
    try {
        & $pythonPath -c "import fastapi, uvicorn, pydantic, mido; print('✓ All main dependencies installed')"
        Write-Host "✓ Dependencies check passed" -ForegroundColor Green
    } catch {
        Write-Host "✗ Some dependencies missing. Installing..." -ForegroundColor Yellow
        & $pythonPath -m pip install -r requirements.txt
    }
    
} else {
    Write-Host "✗ Environment 'harmony_demo' does not exist" -ForegroundColor Red
    Write-Host "Creating environment..." -ForegroundColor Yellow
    
    try {
        & $condaPath create -n harmony_demo python=3.9 -y
        Write-Host "✓ Environment created successfully" -ForegroundColor Green
        
        # Install dependencies
        Write-Host "Installing dependencies..." -ForegroundColor Yellow
        Set-Location "D:\Share_D\Internship\Harmony10_demo\be"
        & "$envPath\python.exe" -m pip install -r requirements.txt
        Write-Host "✓ Dependencies installed" -ForegroundColor Green
        
    } catch {
        Write-Host "✗ Error creating environment: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "=== Setup Complete ===" -ForegroundColor Cyan
Write-Host "You can now run the server using:" -ForegroundColor White
Write-Host "  .\start_server.ps1" -ForegroundColor Yellow
Write-Host "  or" -ForegroundColor White  
Write-Host "  .\start_server.bat" -ForegroundColor Yellow
Write-Host ""
Write-Host "Server will be available at: http://127.0.0.1:8000" -ForegroundColor Green
Write-Host "API Documentation: http://127.0.0.1:8000/docs" -ForegroundColor Green

Read-Host "Press Enter to exit"