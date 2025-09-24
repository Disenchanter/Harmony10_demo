# Harmony Demo FastAPI Server Startup Script
Write-Host "Starting Harmony Demo FastAPI Server..." -ForegroundColor Green
Write-Host "Using conda environment: harmony_demo" -ForegroundColor Yellow
Write-Host ""

Set-Location "D:\Share_D\Internship\Harmony10_demo\be"

# Check if the environment exists
if (Test-Path "C:\Users\LZ\anaconda3\envs\harmony_demo\python.exe") {
    Write-Host "Environment found. Starting server..." -ForegroundColor Green
    & "C:\Users\LZ\anaconda3\envs\harmony_demo\python.exe" run.py
} else {
    Write-Host "ERROR: conda environment 'harmony_demo' not found!" -ForegroundColor Red
    Write-Host "Please run the following command to create it:" -ForegroundColor Yellow
    Write-Host "conda create -n harmony_demo python=3.9 -y" -ForegroundColor White
    Read-Host "Press Enter to exit"
}