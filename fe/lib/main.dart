import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'models.dart';
import 'api_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Harmony Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MusicHarmonyPage(),
    );
  }
}

enum AppMode { harmonize, evaluate }

class MusicHarmonyPage extends StatefulWidget {
  const MusicHarmonyPage({super.key});

  @override
  State<MusicHarmonyPage> createState() => _MusicHarmonyPageState();
}

class _MusicHarmonyPageState extends State<MusicHarmonyPage> {
  // 状态变量
  AppMode currentMode = AppMode.harmonize;
  bool isRecording = false;
  bool countdownStarted = false; // 是否已开始倒计时
  int recordingTime = 10;
  Timer? recordingTimer;
  
  // 音符映射 (C4-B4)
  static const Map<String, int> noteMap = {
    'C': 60, // C4
    'D': 62, // D4
    'E': 64, // E4
    'F': 65, // F4
    'G': 67, // G4
    'A': 69, // A4
    'B': 71, // B4
  };
  
  // 录制的事件
  List<MusicEvent> recordedEvents = [];
  
  // 结果数据
  EvaluateResponse? evaluationResult;
  String? midiFilePath;
  bool isLoading = false;
  String? errorMessage;

  @override
  void dispose() {
    recordingTimer?.cancel();
    super.dispose();
  }

  void _startRecording() {
    setState(() {
      isRecording = true;
      countdownStarted = false; // 重置倒计时状态
      recordingTime = 10;
      recordedEvents.clear();
      evaluationResult = null;
      midiFilePath = null;
      errorMessage = null;
    });
  }

  void _startCountdown() {
    if (countdownStarted) return; // 防止重复启动
    
    setState(() {
      countdownStarted = true;
    });

    recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        recordingTime--;
      });

      if (recordingTime <= 0) {
        _stopRecording();
      }
    });
  }

  void _stopRecording() {
    recordingTimer?.cancel();
    setState(() {
      isRecording = false;
      countdownStarted = false; // 重置倒计时状态
    });
    
    if (recordedEvents.isNotEmpty) {
      _processRecording();
    } else {
      setState(() {
        errorMessage = '没有录制到任何音符';
      });
    }
  }

  void _onNotePressed(String noteName) {
    if (!isRecording) return;

    // 如果是第一次按下音符，启动倒计时
    if (!countdownStarted) {
      _startCountdown();
    }

    final currentSecond = 10 - recordingTime;
    final noteValue = noteMap[noteName]!;

    setState(() {
      // 移除同一秒的其他事件（同秒最后一次生效）
      recordedEvents.removeWhere((event) => event.tSec == currentSecond);
      
      // 添加新事件
      recordedEvents.add(MusicEvent(
        tSec: currentSecond,
        note: noteValue,
      ));
    });
  }

  Future<void> _processRecording() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      if (currentMode == AppMode.harmonize) {
        await _handleHarmonize();
      } else {
        await _handleEvaluate();
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _handleHarmonize() async {
    final midiData = await ApiService.harmonize(recordedEvents);
    
    // 保存 MIDI 文件到程序同目录下
    final executablePath = Platform.resolvedExecutable;
    final executableDir = Directory(executablePath).parent.path;
    
    // 创建 midi 子文件夹
    final midiDir = Directory('$executableDir/midi');
    if (!await midiDir.exists()) {
      await midiDir.create(recursive: true);
    }
    
    final file = File('${midiDir.path}/harmony_${DateTime.now().millisecondsSinceEpoch}.mid');
    await file.writeAsBytes(midiData);
    
    // 调试信息
    print('可执行文件路径: $executablePath');
    print('程序目录: $executableDir');
    print('MIDI文件保存路径: ${file.path}');
    print('MIDI数据大小: ${midiData.length} bytes');
    print('文件是否存在: ${await file.exists()}');
    
    setState(() {
      midiFilePath = file.path;
    });
  }

  Future<void> _handleEvaluate() async {
    final result = await ApiService.evaluate(recordedEvents);
    
    setState(() {
      evaluationResult = result;
    });
  }

  Future<void> _openMidiFile() async {
    if (midiFilePath == null) {
      setState(() {
        errorMessage = 'MIDI文件路径为空';
      });
      return;
    }
    
    try {
      final file = File(midiFilePath!);
      print('尝试打开文件: $midiFilePath');
      print('文件是否存在: ${await file.exists()}');
      print('文件大小: ${await file.exists() ? await file.length() : 0} bytes');
      
      final uri = Uri.file(midiFilePath!);
      print('文件URI: $uri');
      
      if (await canLaunchUrl(uri)) {
        print('可以启动URL，正在打开...');
        await launchUrl(uri);
      } else {
        print('无法启动URL');
        setState(() {
          errorMessage = '无法打开MIDI文件。请确保系统已安装MIDI播放器。\n文件路径: $midiFilePath';
        });
      }
    } catch (e) {
      print('打开文件时发生错误: $e');
      setState(() {
        errorMessage = '打开文件失败: $e\n文件路径: $midiFilePath';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Music Harmony Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 顶部模式切换
            _buildModeToggle(),
            
            const SizedBox(height: 20),
            
            // 录制状态和倒计时
            _buildRecordingStatus(),
            
            const SizedBox(height: 30),
            
            // 7个白键按钮
            _buildPianoKeys(),
            
            const SizedBox(height: 30),
            
            // 录制控制按钮
            _buildRecordingControls(),
            
            const SizedBox(height: 20),
            
            // 结果展示区域
            Container(
              height: 300, // 固定高度替代Expanded
              child: SingleChildScrollView(
                child: _buildResultArea(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildModeButton('Harmonize', AppMode.harmonize),
          _buildModeButton('Evaluate', AppMode.evaluate),
        ],
      ),
    );
  }

  Widget _buildModeButton(String text, AppMode mode) {
    final isSelected = currentMode == mode;
    return GestureDetector(
      onTap: () => setState(() => currentMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingStatus() {
    return Column(
      children: [
        Text(
          isRecording 
            ? (countdownStarted ? '录制中...' : '等待第一个音符...') 
            : '准备录制',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 10),
        if (isRecording && countdownStarted)
          Text(
            '$recordingTime 秒',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              color: recordingTime <= 3 ? Colors.red : Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
        if (isRecording && !countdownStarted)
          const Text(
            '点击任意白键开始倒计时',
            style: TextStyle(color: Colors.orange, fontSize: 16),
          ),
      ],
    );
  }

  Widget _buildPianoKeys() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: noteMap.keys.map((noteName) => _buildPianoKey(noteName)).toList(),
    );
  }

  Widget _buildPianoKey(String noteName) {
    final isPressed = recordedEvents.any((event) => 
        event.note == noteMap[noteName] && 
        event.tSec == (10 - recordingTime));
    
    return GestureDetector(
      onTap: () => _onNotePressed(noteName),
      child: Container(
        width: 40,
        height: 120,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isPressed ? Colors.blue[300] : Colors.white,
          border: Border.all(color: Colors.black, width: 2),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
        ),
        child: Center(
          child: Text(
            noteName,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isPressed ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingControls() {
    return Center(
      child: ElevatedButton.icon(
        onPressed: isRecording ? null : _startRecording,
        icon: const Icon(Icons.fiber_manual_record),
        label: const Text('开始录制'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildResultArea() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('处理中...'),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              '错误: $errorMessage',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (currentMode == AppMode.harmonize && midiFilePath != null) {
      return _buildHarmonizeResult();
    }

    if (currentMode == AppMode.evaluate && evaluationResult != null) {
      return _buildEvaluateResult();
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            currentMode == AppMode.harmonize ? Icons.music_note : Icons.assessment,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            currentMode == AppMode.harmonize
                ? '录制旋律生成和声'
                : '录制演奏进行评估',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '点击上方的白键按钮录制音符',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildHarmonizeResult() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle, size: 48, color: Colors.green),
        const SizedBox(height: 12),
        const Text(
          'MIDI 文件生成成功！',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          '文件: ${midiFilePath!.split('/').last}',
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 12),
        const Text(
          '包含旋律轨道和和声轨道',
          style: TextStyle(color: Colors.blue, fontSize: 12),
        ),
        const SizedBox(height: 6),
        Text(
          '录制了 ${recordedEvents.length} 个音符',
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 16),
        // 打开MIDI文件按钮
        ElevatedButton.icon(
          onPressed: _openMidiFile,
          icon: const Icon(Icons.music_note),
          label: const Text('打开MIDI文件'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildEvaluateResult() {
    final result = evaluationResult!;
    return SingleChildScrollView(
      child: Column(
        children: [
          // 总分显示
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _getScoreColor(result.score).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _getScoreColor(result.score)),
            ),
            child: Column(
              children: [
                Text(
                  '${result.score.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: _getScoreColor(result.score),
                  ),
                ),
                Text(
                  '总分',
                  style: TextStyle(
                    fontSize: 16,
                    color: _getScoreColor(result.score),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // 子分数
          Row(
            children: [
              Expanded(
                child: _buildSubScore('准确度', result.subscores['accuracy'] ?? 0),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSubScore('时机', result.subscores['timing'] ?? 0),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // 建议
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '建议',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  result.advice,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          
          // 错误详情
          if (result.mistakes.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildMistakesList(result.mistakes),
          ],
        ],
      ),
    );
  }

  Widget _buildSubScore(String label, double score) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            score.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMistakesList(List<Mistake> mistakes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '错误详情 (${mistakes.length})',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...mistakes.take(5).map((mistake) => _buildMistakeItem(mistake)),
        if (mistakes.length > 5)
          Text(
            '... 还有 ${mistakes.length - 5} 个错误',
            style: const TextStyle(color: Colors.grey),
          ),
      ],
    );
  }

  Widget _buildMistakeItem(Mistake mistake) {
    String errorDescription;
    IconData errorIcon;
    Color errorColor;

    switch (mistake.errorType) {
      case 'wrong_note':
        errorDescription = '第${mistake.timeSec}秒: 弹错了音符';
        errorIcon = Icons.music_off;
        errorColor = Colors.orange;
        break;
      case 'missing_note':
        errorDescription = '第${mistake.timeSec}秒: 漏了音符';
        errorIcon = Icons.remove_circle;
        errorColor = Colors.red;
        break;
      case 'extra_note':
        errorDescription = '第${mistake.timeSec}秒: 多余的音符';
        errorIcon = Icons.add_circle;
        errorColor = Colors.purple;
        break;
      default:
        errorDescription = '第${mistake.timeSec}秒: 未知错误';
        errorIcon = Icons.error;
        errorColor = Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(errorIcon, size: 16, color: errorColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              errorDescription,
              style: TextStyle(fontSize: 12, color: errorColor),
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}