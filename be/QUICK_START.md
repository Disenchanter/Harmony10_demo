# Music Harmony Demo - 快速启动指南

## 项目概览

这是一个完整的音乐和声 demo 项目，包含：
- **Python FastAPI 后端**: 提供 MIDI 和声生成和演奏评估 API
- **Flutter 前端**: 提供用户交互界面和录制功能

## 快速启动

### 第一步：启动后端服务

```bash
# 1. 进入项目根目录
cd Harmony10_demo

# 2. 安装 Python 依赖
pip install -r requirements.txt

# 3. 启动 FastAPI 服务器
python run.py
```

✅ 后端服务将运行在 `http://127.0.0.1:8000`
✅ 访问 `http://127.0.0.1:8000/docs` 查看 API 文档

### 第二步：配置前端网络

1. **查找局域网 IP**

   **Windows:**
   ```cmd
   ipconfig
   ```
   
   **macOS/Linux:**
   ```bash
   ifconfig
   ```
   
   记录你的局域网 IP 地址 (例如: 192.168.1.100)

2. **修改前端配置**

   编辑 `flutter_app/lib/api_service.dart`:
   ```dart
   // 第 6 行，修改为你的实际 IP 地址
   static const String baseUrl = 'http://192.168.1.100:8000';
   ```

### 第三步：运行 Flutter 应用

```bash
# 1. 进入 Flutter 目录
cd flutter_app

# 2. 安装 Flutter 依赖
flutter pub get

# 3. 运行应用 (连接设备或启动模拟器)
flutter run
```

## 使用说明

### 界面操作

1. **模式选择**: 点击顶部的 "Harmonize" 或 "Evaluate" 切换模式
2. **开始录制**: 点击红色"开始录制"按钮
3. **录制音符**: 在 10 秒倒计时内点击白键 (C, D, E, F, G, A, B)
4. **查看结果**: 录制结束后自动处理并显示结果

### 两种模式

**🎵 Harmonize 模式**
- 录制旋律
- 生成带和声的 MIDI 文件
- 文件保存到应用文档目录

**📊 Evaluate 模式**
- 录制演奏
- 与 C 大调音阶模板对比
- 显示评分、错误详情和改进建议

## 测试验证

### 后端 API 测试

**测试 Harmonize:**
```bash
curl -X POST "http://127.0.0.1:8000/api/v1/harmonize" \
     -H "Content-Type: application/json" \
     -d '{"version":"1.0","mode":"harmonize","duration_sec":10,"quantize":"1s","octave_base":"C4","key":"C major","return_mode":"bytes","events":[{"t_sec":0,"note":60},{"t_sec":3,"note":64},{"t_sec":7,"note":67}]}' \
     --output test_harmony.mid
```

**测试 Evaluate:**
```bash
curl -X POST "http://127.0.0.1:8000/api/v1/evaluate" \
     -H "Content-Type: application/json" \
     -d '{"version":"1.0","mode":"evaluate","duration_sec":10,"quantize":"1s","octave_base":"C4","key":"C major","reference_id":"exercise_c_major_01","events":[{"t_sec":0,"note":60},{"t_sec":1,"note":62},{"t_sec":2,"note":64}]}'
```

### 前端连接测试

在 Flutter 应用中：
1. 确保后端服务正在运行
2. 尝试录制一个简单的旋律
3. 检查是否能正常显示结果

## 故障排除

### 常见问题

❌ **"Network error" 错误**
- 检查后端是否正在运行
- 确认 IP 地址配置正确
- 确保移动设备与电脑在同一 WiFi 网络

❌ **"No route to host" 错误**
- 检查防火墙设置
- 确认端口 8000 没有被阻止

❌ **Flutter 编译错误**
- 运行 `flutter doctor` 检查环境
- 确认 Flutter 版本 >= 2.19.0

### 调试技巧

1. **查看后端日志**
   - 后端终端会显示所有 API 请求日志

2. **查看 Flutter 日志**
   ```bash
   flutter logs
   ```

3. **测试网络连接**
   - 在手机浏览器访问 `http://<你的IP>:8000`
   - 应该看到 API 欢迎信息

## 项目结构

```
Harmony10_demo/
├── 🐍 Python 后端
│   ├── main.py              # FastAPI 主应用
│   ├── models.py            # 数据模型
│   ├── midi_utils.py        # MIDI 处理
│   ├── run.py              # 启动脚本
│   └── requirements.txt    # 依赖列表
│
├── 📱 Flutter 前端  
│   ├── lib/
│   │   ├── main.dart          # 主应用界面
│   │   ├── models.dart        # 数据模型
│   │   └── api_service.dart   # API 客户端
│   ├── pubspec.yaml           # 依赖配置
│   └── README.md              # 前端说明
│
├── README.md                # 项目总体说明
├── TEST_GUIDE.md           # API 测试指南
└── QUICK_START.md          # 本快速启动指南
```

## 技术参数

- **录制时长**: 10 秒固定
- **音符范围**: C4-B4 白键 (60,62,64,65,67,69,71)
- **量化精度**: 1 秒
- **和声规律**: C(0-3s) / F(4-6s) / G(7-9s)
- **MIDI 格式**: Type-1，双轨道

## 成功标志

✅ 后端启动成功 - 终端显示 "Uvicorn running on..."
✅ 前端连接成功 - 应用界面正常显示
✅ 录制功能正常 - 倒计时和按键响应正常
✅ 结果显示正常 - Harmonize 显示文件生成，Evaluate 显示评分

现在你的音乐和声 demo 应该已经完全可以使用了！🎵