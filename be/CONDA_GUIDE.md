# Conda Virtual Environment Guide

## 🎯 Environment Overview

The conda virtual environment named `harmony_demo` has been created and configured for the Harmony Demo FastAPI backend service. It is set up to use the official PyPI index by default:

```powershell
# Install dependencies from the official PyPI index
C:\Users\LZ\anaconda3\envs\harmony_demo\python.exe -m pip install -r requirements.txt
```

When you need to temporarily switch to a different mirror (for example, the Tsinghua mirror):

```powershell
C:\Users\LZ\anaconda3\envs\harmony_demo\python.exe -m pip install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple/
```

### Environment Details
- **Environment name**: `harmony_demo`
- **Python version**: 3.9.23
- **Location**: `C:\Users\LZ\anaconda3\envs\harmony_demo`
- **Installed packages**: FastAPI, Uvicorn, Pydantic, Mido, python-multipart

## 🚀 Quick Start

### Option 1: Use the startup scripts (recommended)

**PowerShell script**

```powershell
.\start_server.ps1
```

**Batch script**

```cmd
start_server.bat
```

### Option 2: Start the server manually

```powershell
# Navigate to the project directory
cd "D:\Share_D\Internship\Harmony10_demo\be"

# Run the server with the virtual environment
C:\Users\LZ\anaconda3\envs\harmony_demo\python.exe run.py
```

## 🔧 Environment Management

### Check environment status

```powershell
# List all environments
C:\Users\LZ\anaconda3\Scripts\conda.exe env list

# Check the Python version in this environment
C:\Users\LZ\anaconda3\envs\harmony_demo\python.exe --version

# List installed packages
C:\Users\LZ\anaconda3\envs\harmony_demo\python.exe -m pip list
```

### Install a new dependency

```powershell
C:\Users\LZ\anaconda3\envs\harmony_demo\python.exe -m pip install <package-name>
```

### Reinstall dependencies from the lock file

```powershell
cd "D:\Share_D\Internship\Harmony10_demo\be"
C:\Users\LZ\anaconda3\envs\harmony_demo\python.exe -m pip install -r requirements.txt
```

## 🛠️ Troubleshooting

### Issue: `conda activate` does not work in PowerShell

**Cause**: Conda activation hooks are not available in the current PowerShell session.

**Solution**: Use the Python executable inside the environment directly.

```powershell
# Avoid: conda activate harmony_demo
# Instead run scripts with:
C:\Users\LZ\anaconda3\envs\harmony_demo\python.exe <script-name>
```

### Issue: Dependency installation fails

**Solution**: Retry with a specific index.

```powershell
# Use the default PyPI index
C:\Users\LZ\anaconda3\envs\harmony_demo\python.exe -m pip install -r requirements.txt --index-url https://pypi.org/simple/

# Or use the Tsinghua mirror
C:\Users\LZ\anaconda3\envs\harmony_demo\python.exe -m pip install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple/
```

### Issue: The server fails to start

1. Confirm you're in the correct directory: `D:\Share_D\Internship\Harmony10_demo\be`
2. Ensure dependencies are installed: run `setup_environment.ps1`
3. Check whether port 8000 is in use: `netstat -ano | findstr :8000`

## 📍 Important Paths

- **Environment path**: `C:\Users\LZ\anaconda3\envs\harmony_demo`
- **Python executable**: `C:\Users\LZ\anaconda3\envs\harmony_demo\python.exe`
- **Project directory**: `D:\Share_D\Internship\Harmony10_demo\be`
- **Server address**: `http://127.0.0.1:8000`
- **API docs**: `http://127.0.0.1:8000/docs`

## 🎵 Server Health Checks

### Quick checks

```powershell
# Verify the server is running
curl http://127.0.0.1:8000

# Open the interactive API docs
start http://127.0.0.1:8000/docs
```

### Test API endpoints

```powershell
# Test the harmonize endpoint
curl -X POST "http://127.0.0.1:8000/api/v1/harmonize" -H "Content-Type: application/json" -d '{"version":"1.0","mode":"harmonize","duration_sec":10,"quantize":"1s","octave_base":"C4","key":"C major","return_mode":"bytes","events":[{"t_sec":0,"note":60}]}' --output test.mid

# Test the evaluate endpoint
curl -X POST "http://127.0.0.1:8000/api/v1/evaluate" -H "Content-Type: application/json" -d '{"version":"1.0","mode":"evaluate","duration_sec":10,"quantize":"1s","octave_base":"C4","key":"C major","reference_id":"exercise_c_major_01","events":[{"t_sec":0,"note":60}]}'
```

## 📋 Quick Command Reference

```powershell
# Initial environment setup
.\setup_environment.ps1

# Start the server
.\start_server.ps1

# Manually start the server
C:\Users\LZ\anaconda3\envs\harmony_demo\python.exe run.py

# Check server status
curl http://127.0.0.1:8000

# Open the API documentation
start http://127.0.0.1:8000/docs
```

Your conda environment is ready to go! 🎉