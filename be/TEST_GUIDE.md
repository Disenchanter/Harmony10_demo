# Music Harmony API 测试指南

这个文档包含了如何测试 Music Harmony API 的两个主要端点的说明和示例。

## 启动服务器

```bash
# 安装依赖
pip install -r requirements.txt

# 启动服务器
python run.py
```

服务器将在 `http://127.0.0.1:8000` 上运行。

你可以访问 `http://127.0.0.1:8000/docs` 查看自动生成的 API 文档。

## API 端点测试

### 1. Harmonize 接口测试

**功能**: 根据输入的旋律事件生成带和声的 MIDI 文件

**cURL 命令**:

```bash
curl -X POST "http://127.0.0.1:8000/api/v1/harmonize" \
     -H "Content-Type: application/json" \
     -d '{
       "version":"1.0",
       "mode":"harmonize",
       "duration_sec":10,
       "quantize":"1s",
       "octave_base":"C4",
       "key":"C major",
       "return_mode":"bytes",
       "events":[
         {"t_sec":0,"note":60},
         {"t_sec":3,"note":64},
         {"t_sec":7,"note":67}
       ]
     }' \
     --output harmony.mid
```

**预期结果**: 生成一个名为 `harmony.mid` 的 MIDI 文件，包含：
- 轨道1: 旋律 (Piano, Channel 1)
- 轨道2: 和声 (String Ensemble, Channel 2)
- 和声模式: C(0-3s) / F(4-6s) / G(7-9s)

### 2. Evaluate 接口测试

**功能**: 评估用户演奏与参考模板的匹配度

**cURL 命令**:

```bash
curl -X POST "http://127.0.0.1:8000/api/v1/evaluate" \
     -H "Content-Type: application/json" \
     -d '{
       "version":"1.0",
       "mode":"evaluate",
       "duration_sec":10,
       "quantize":"1s",
       "octave_base":"C4",
       "key":"C major",
       "reference_id":"exercise_c_major_01",
       "events":[
         {"t_sec":0,"note":60},
         {"t_sec":1,"note":62},
         {"t_sec":2,"note":64}
       ]
     }'
```

**预期结果**: 返回 JSON 评估报告，包含：
```json
{
  "score": 30.0,
  "subscores": {
    "accuracy": 30.0,
    "timing": 30.0
  },
  "mistakes": [
    {
      "time_sec": 3,
      "expected_note": 65,
      "played_note": null,
      "error_type": "missing_note"
    },
    ...
  ],
  "advice": "Don't miss notes - you missed 7 notes. Focus on learning the basic melody pattern first."
}
```

## 错误测试示例

### 1. 测试无效版本

```bash
curl -X POST "http://127.0.0.1:8000/api/v1/harmonize" \
     -H "Content-Type: application/json" \
     -d '{
       "version":"2.0",
       "mode":"harmonize",
       "duration_sec":10,
       "quantize":"1s",
       "octave_base":"C4",
       "key":"C major",
       "return_mode":"bytes",
       "events":[{"t_sec":0,"note":60}]
     }'
```

**预期错误**: `unsupported_version`

### 2. 测试无效音符

```bash
curl -X POST "http://127.0.0.1:8000/api/v1/harmonize" \
     -H "Content-Type: application/json" \
     -d '{
       "version":"1.0",
       "mode":"harmonize",
       "duration_sec":10,
       "quantize":"1s",
       "octave_base":"C4",
       "key":"C major",
       "return_mode":"bytes",
       "events":[{"t_sec":0,"note":61}]
     }'
```

**预期错误**: `invalid_note`

### 3. 测试重复时间段

```bash
curl -X POST "http://127.0.0.1:8000/api/v1/harmonize" \
     -H "Content-Type: application/json" \
     -d '{
       "version":"1.0",
       "mode":"harmonize",
       "duration_sec":10,
       "quantize":"1s",
       "octave_base":"C4",
       "key":"C major",
       "return_mode":"bytes",
       "events":[
         {"t_sec":0,"note":60},
         {"t_sec":0,"note":64}
       ]
     }'
```

**预期错误**: `duplicate_timeslot`

### 4. 测试不存在的参考模板

```bash
curl -X POST "http://127.0.0.1:8000/api/v1/evaluate" \
     -H "Content-Type: application/json" \
     -d '{
       "version":"1.0",
       "mode":"evaluate",
       "duration_sec":10,
       "quantize":"1s",
       "octave_base":"C4",
       "key":"C major",
       "reference_id":"nonexistent_template",
       "events":[{"t_sec":0,"note":60}]
     }'
```

**预期错误**: `reference_not_found`

## 参考模板

### exercise_c_major_01

这是内置的 C 大调练习模板：

```
时间(秒) -> 目标音符
0 -> 60 (C)
1 -> 62 (D)  
2 -> 64 (E)
3 -> 65 (F)
4 -> 67 (G)
5 -> 69 (A)
6 -> 71 (B)
7 -> 60 (C)
8 -> 62 (D)
9 -> 64 (E)
```

## 技术规范

- **量化**: 固定为 1 秒 (t_sec ∈ [0..9])
- **调性**: 固定为 C major
- **白键集合**: {60,62,64,65,67,69,71}
- **同一秒规则**: 只保留最后一次点击
- **默认力度**: vel = 96
- **MIDI 格式**: Type-1 
  - 轨道1: Channel 1, Program 0 (Piano)
  - 轨道2: Channel 2, Program 48 (String Ensemble)

## 和声规律

- 0-3 秒: C major 和弦 (C-E-G: 60,64,67)
- 4-6 秒: F major 和弦 (F-A-C: 65,69,60)  
- 7-9 秒: G major 和弦 (G-B-D: 67,71,62)

## 故障排除

如果遇到问题：

1. 确认服务器正在运行 (`http://127.0.0.1:8000`)
2. 检查请求的 JSON 格式是否正确
3. 验证所有必需字段都已提供
4. 确认音符值在白键集合中
5. 查看服务器日志获取详细错误信息