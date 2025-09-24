# Music Harmony Demo - 完整项目

一个完整的 **Flutter + Python FastAPI** 音乐 demo 项目，实现旋律和声生成与演奏评估功能。

## 项目架构

```
Harmony10_demo/
├── 后端 (Python FastAPI)
│   ├── main.py              # FastAPI 主应用
│   ├── models.py            # Pydantic 数据模型  
│   ├── midi_utils.py        # MIDI 生成和评估逻辑
│   ├── run.py              # 服务启动脚本
│   ├── requirements.txt    # Python 依赖
│   └── TEST_GUIDE.md       # API 测试指南
│
└── 前端 (Flutter)
    ├── lib/
    │   ├── main.dart          # Flutter 主应用
    │   ├── models.dart        # 数据模型
    │   └── api_service.dart   # HTTP 客户端
    ├── pubspec.yaml           # Flutter 依赖
    └── README.md              # Flutter 使用说明
```

## 功能特性

### 🎵 双模式操作
- **Harmonize 模式**: 录制旋律 → 生成带和声的 MIDI 文件
- **Evaluate 模式**: 录制演奏 → 与参考模板对比评分

### 🎹 用户界面
- 顶部模式切换 (Harmonize/Evaluate)
- 7 个白键按钮 (C-D-E-F-G-A-B，默认 C4-B4)
- 10 秒录制倒计时，每秒最多 1 个事件
- 同秒最后一次点击生效

### 🔄 后端处理
- **Harmonize**: POST `/api/v1/harmonize` → 返回 MIDI 文件 (bytes)
- **Evaluate**: POST `/api/v1/evaluate` → 返回 `{score, subscores, mistakes, advice}`

### 🌐 局域网部署
- FastAPI 后端: `http://<局域网IP>:8000`
- Flutter 前端: 移动设备或桌面应用

## 快速开始

### 1. 启动后端服务

```bash
# 进入项目根目录
cd Harmony10_demo

# 安装 Python 依赖
pip install -r requirements.txt

# 启动 FastAPI 服务器
python run.py
```

服务器将运行在 `http://127.0.0.1:8000`

### 2. 配置和运行前端

```bash
# 进入 Flutter 目录
cd flutter_app

# 安装 Flutter 依赖  
flutter pub get

# 修改 lib/api_service.dart 中的 IP 地址
# static const String baseUrl = 'http://192.168.1.100:8000';

# 运行 Flutter 应用
flutter run
```

## 技术规范

### 音乐参数
- **Quantization**: 固定为 1s (t_sec ∈ [0..9])
- **Key**: 固定 C major
- **白键集合**: {60,62,64,65,67,69,71} (C,D,E,F,G,A,B)
- **冲突处理**: 同一秒只保留最后一次点击
- **默认力度**: vel = 96

### MIDI 输出规范
- **格式**: Type-1 MIDI 文件
- **轨道1**: 旋律 (Channel 1, Program 0 - Piano)
- **轨道2**: 和声 (Channel 2, Program 48 - String Ensemble)  
- **和声规律**: C(0-3s) / F(4-6s) / G(7-9s)

### API 错误码
- `unsupported_version` - 不支持的版本号
- `invalid_mode` - 无效的模式
- `invalid_duration` - 无效的时长
- `invalid_quantize` - 无效的量化设置
- `empty_sequence` - 空的事件序列
- `duplicate_timeslot` - 重复的时间段
- `invalid_note` - 无效的音符
- `reference_not_found` - 参考模板未找到

## 使用流程

### Harmonize 模式
1. 切换到 "Harmonize" 模式
2. 点击"开始录制"，10秒倒计时开始
3. 在倒计时期间点击白键录制旋律
4. 录制结束自动调用后端生成 MIDI 文件
5. 显示文件保存成功信息

### Evaluate 模式  
1. 切换到 "Evaluate" 模式
2. 点击"开始录制"，10秒倒计时开始
3. 按照参考模板 (exercise_c_major_01) 演奏
4. 录制结束自动调用后端进行评估
5. 显示评分结果和改进建议

## 内置参考模板

### exercise_c_major_01 (C大调练习)
```
0s -> C(60)    1s -> D(62)    2s -> E(64)    3s -> F(65)    4s -> G(67)
5s -> A(69)    6s -> B(71)    7s -> C(60)    8s -> D(62)    9s -> E(64)
```

## 测试示例

### 测试 Harmonize 接口
```bash
curl -X POST "http://127.0.0.1:8000/api/v1/harmonize" \
     -H "Content-Type: application/json" \
     -d '{
       "version":"1.0","mode":"harmonize","duration_sec":10,"quantize":"1s",
       "octave_base":"C4","key":"C major","return_mode":"bytes",
       "events":[{"t_sec":0,"note":60},{"t_sec":3,"note":64},{"t_sec":7,"note":67}]
     }' \
     --output harmony.mid
```

### 测试 Evaluate 接口
```bash
curl -X POST "http://127.0.0.1:8000/api/v1/evaluate" \
     -H "Content-Type: application/json" \
     -d '{
       "version":"1.0","mode":"evaluate","duration_sec":10,"quantize":"1s",
       "octave_base":"C4","key":"C major","reference_id":"exercise_c_major_01",
       "events":[{"t_sec":0,"note":60},{"t_sec":1,"note":62},{"t_sec":2,"note":64}]
     }'
```

## 部署说明

### 局域网部署

1. **后端部署**
   - 在服务器或主机上运行 `python run.py`
   - 确保端口 8000 在防火墙中开放
   - 记录服务器的局域网 IP 地址

2. **前端配置**  
   - 修改 `flutter_app/lib/api_service.dart` 中的 `baseUrl`
   - 将 IP 地址改为后端服务器的局域网 IP
   - 确保移动设备与服务器在同一局域网

### 生产环境建议

- **HTTPS**: 配置 SSL 证书
- **反向代理**: 使用 Nginx 或 Apache
- **域名**: 配置域名解析
- **监控**: 添加日志监控和错误跟踪

## 故障排除

### 常见问题

1. **网络连接失败**
   - 检查后端服务是否运行
   - 确认 IP 地址配置正确
   - 检查防火墙设置

2. **MIDI 文件生成失败**
   - 确认录制了有效音符
   - 检查文件系统权限

3. **评估功能异常**
   - 验证参考模板存在
   - 确认音符在有效范围内

### 调试工具

- **后端日志**: `python run.py` 终端输出
- **API 文档**: `http://<IP>:8000/docs`
- **Flutter 日志**: `flutter logs`
- **网络测试**: 浏览器访问后端健康检查接口

## 技术栈

### 后端
- **FastAPI**: 现代 Python Web 框架
- **Pydantic**: 数据验证和序列化  
- **Mido**: MIDI 文件处理
- **Uvicorn**: ASGI 服务器

### 前端
- **Flutter**: 跨平台 UI 框架
- **Dart**: 编程语言
- **HTTP**: 网络请求库
- **Path Provider**: 文件路径管理

## 贡献指南

欢迎提交问题报告、功能请求和代码贡献。

### 开发环境
- Python 3.8+
- Flutter 3.0+
- 推荐使用 VS Code 或 Android Studio

### 提交规范  
- 遵循代码风格指南
- 添加必要的测试用例
- 更新相关文档

## 许可证

MIT License - 详见 LICENSE 文件。