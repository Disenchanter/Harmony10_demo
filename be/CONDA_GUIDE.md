# Conda 虚拟环境使用指南

## 🎯 环境概述

已成功创建并配置了名为 `harmony_demo` 的 conda 虚拟环境，用于**解决方案**: 使用不同的PyPI源
```powershell
# 默认使用配置的PyPI官方源
C:\Users\LZ\anaconda3\envs\harmony_demo\python.exe -m pip install -r requirements.txt

# 如果需要临时使用其他源
C:\Users\LZ\anaconda3\envs\harmony_demo\python.exe -m pip install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple/
```ny Demo FastAPI 后端服务。

### 环境信息
- **环境名称**: harmony_demo  
- **Python 版本**: 3.9.23
- **位置**: `C:\Users\LZ\anaconda3\envs\harmony_demo`
- **已安装依赖**: FastAPI, Uvicorn, Pydantic, Mido, Python-multipart

## 🚀 快速启动

### 方法一：使用启动脚本（推荐）

**PowerShell 脚本**:
```powershell
.\start_server.ps1
```

**批处理脚本**:
```cmd
start_server.bat
```

### 方法二：手动启动

```powershell
# 进入项目目录
cd "D:\Share_D\Internship\Harmony10_demo\be"

# 使用虚拟环境运行服务器
C:\Users\LZ\anaconda3\envs\harmony_demo\python.exe run.py
```

## 🔧 环境管理

### 检查环境状态
```powershell
# 查看所有环境
C:\Users\LZ\anaconda3\Scripts\conda.exe env list

# 检查环境中的 Python 版本
C:\Users\LZ\anaconda3\envs\harmony_demo\python.exe --version

# 查看已安装的包
C:\Users\LZ\anaconda3\envs\harmony_demo\python.exe -m pip list
```

### 安装新依赖
```powershell
C:\Users\LZ\anaconda3\envs\harmony_demo\python.exe -m pip install <包名>
```

### 重新安装依赖
```powershell
cd "D:\Share_D\Internship\Harmony10_demo\be"
C:\Users\LZ\anaconda3\envs\harmony_demo\python.exe -m pip install -r requirements.txt
```

## 🛠️ 故障排除

### 问题：Conda 激活命令无效

**原因**: PowerShell 中 conda 环境激活有问题

**解决方案**: 直接使用虚拟环境的 Python 路径
```powershell
# 不要使用: conda activate harmony_demo
# 而是使用: 
C:\Users\LZ\anaconda3\envs\harmony_demo\python.exe <脚本名>
```

### 问题：依赖安装失败

**解决方案**: 使用不同的 PyPI 源
```powershell
# 使用默认源
C:\Users\LZ\anaconda3\envs\harmony_demo\python.exe -m pip install -r requirements.txt --index-url https://pypi.org/simple/

# 或使用清华源
C:\Users\LZ\anaconda3\envs\harmony_demo\python.exe -m pip install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple/
```

### 问题：服务器无法启动

**检查步骤**:
1. 确认在正确目录: `D:\Share_D\Internship\Harmony10_demo\be`
2. 确认依赖已安装: 运行 `setup_environment.ps1`
3. 检查端口占用: `netstat -ano | findstr :8000`

## 📍 重要路径

- **环境路径**: `C:\Users\LZ\anaconda3\envs\harmony_demo`
- **Python 执行文件**: `C:\Users\LZ\anaconda3\envs\harmony_demo\python.exe`
- **项目目录**: `D:\Share_D\Internship\Harmony10_demo\be`
- **服务器地址**: `http://127.0.0.1:8000`
- **API 文档**: `http://127.0.0.1:8000/docs`

## 🎵 服务器状态验证

### 健康检查
```powershell
# 检查服务器是否运行
curl http://127.0.0.1:8000

# 查看API文档
start http://127.0.0.1:8000/docs
```

### 测试 API 端点
```powershell
# 测试 harmonize 接口
curl -X POST "http://127.0.0.1:8000/api/v1/harmonize" -H "Content-Type: application/json" -d '{"version":"1.0","mode":"harmonize","duration_sec":10,"quantize":"1s","octave_base":"C4","key":"C major","return_mode":"bytes","events":[{"t_sec":0,"note":60}]}' --output test.mid

# 测试 evaluate 接口  
curl -X POST "http://127.0.0.1:8000/api/v1/evaluate" -H "Content-Type: application/json" -d '{"version":"1.0","mode":"evaluate","duration_sec":10,"quantize":"1s","octave_base":"C4","key":"C major","reference_id":"exercise_c_major_01","events":[{"t_sec":0,"note":60}]}'
```

## 📋 快速命令参考

```powershell
# 环境设置（首次使用）
.\setup_environment.ps1

# 启动服务器
.\start_server.ps1

# 手动启动服务器
C:\Users\LZ\anaconda3\envs\harmony_demo\python.exe run.py

# 检查服务器状态
curl http://127.0.0.1:8000

# 查看API文档
start http://127.0.0.1:8000/docs
```

现在你的 conda 虚拟环境已经完全配置好了！🎉