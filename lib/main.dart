import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

void main() => runApp(const MemoryMonitorApp());

class MemoryMonitorApp extends StatelessWidget {
  const MemoryMonitorApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '内存监控', debugShowCheckedModeBanner: false,
    theme: ThemeData(colorSchemeSeed: Colors.cyan, useMaterial3: true, brightness: Brightness.light),
    darkTheme: ThemeData(colorSchemeSeed: Colors.cyan, useMaterial3: true, brightness: Brightness.dark),
    home: const MemoryHomePage(),
  );
}

class MemoryHomePage extends StatefulWidget {
  const MemoryHomePage({super.key});
  @override
  State<MemoryHomePage> createState() => _MemoryHomePageState();
}

class _MemoryHomePageState extends State<MemoryHomePage> {
  double _usedGB = 8.2, _totalGB = 16.0;
  double _swapUsed = 2.1, _swapTotal = 8.0;
  List<double> _history = [];
  Timer? _timer;
  final _rng = Random();

  final _processes = [
    {'name': 'chrome', 'icon': '🌐', 'mem': '2.1GB', 'pct': 13.1},
    {'name': 'flutter_app', 'icon': '📱', 'mem': '856MB', 'pct': 5.2},
    {'name': 'vscode', 'icon': '💻', 'mem': '680MB', 'pct': 4.1},
    {'name': 'docker', 'icon': '🐳', 'mem': '1.2GB', 'pct': 7.5},
    {'name': 'spotify', 'icon': '🎵', 'mem': '320MB', 'pct': 2.0},
    {'name': 'slack', 'icon': '💬', 'mem': '450MB', 'pct': 2.8},
  ];

  @override
  void initState() { super.initState(); _startMonitoring(); }

  void _startMonitoring() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _usedGB = 7.0 + _rng.nextDouble() * 4;
        _history.add(_usedGB);
        if (_history.length > 60) _history.removeAt(0);
      });
    });
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final pct = _usedGB / _totalGB;
    final swapPct = _swapUsed / _swapTotal;
    return Scaffold(
      appBar: AppBar(title: const Text('🧠 内存监控'), centerTitle: true, actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: () => setState(() { _usedGB = 8.2; _history.clear(); }), tooltip: '刷新'),
      ]),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
        // 内存使用率
        Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
          SizedBox(width: 160, height: 160, child: Stack(alignment: Alignment.center, children: [
            SizedBox(width: 160, height: 160, child: CircularProgressIndicator(value: pct, strokeWidth: 12, backgroundColor: Colors.grey.shade200, color: pct > 0.8 ? Colors.red : Colors.cyan)),
            Column(mainAxisSize: MainAxisSize.min, children: [
              Text('${(pct * 100).toInt()}%', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: pct > 0.8 ? Colors.red : Colors.cyan)),
              Text('${_usedGB.toStringAsFixed(1)} / ${_totalGB.toInt()} GB', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ]),
          ])),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _buildInfo('已使用', '${_usedGB.toStringAsFixed(1)} GB', Colors.orange),
            _buildInfo('可用', '${(_totalGB - _usedGB).toStringAsFixed(1)} GB', Colors.green),
            _buildInfo('总量', '${_totalGB.toInt()} GB', Colors.blue),
          ]),
        ]))),
        const SizedBox(height: 16),
        // Swap
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [const Text('Swap 虚拟内存', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const Spacer(), Text('${_swapUsed.toStringAsFixed(1)} / ${_swapTotal.toInt()} GB', style: const TextStyle(color: Colors.grey))]),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: swapPct, backgroundColor: Colors.grey.shade200, color: swapPct > 0.8 ? Colors.red : Colors.teal),
        ]))),
        const SizedBox(height: 16),
        // 使用率曲线
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('内存使用曲线 (60秒)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          SizedBox(height: 120, child: CustomPaint(painter: _ChartPainter(_history, _totalGB), size: Size.infinite)),
        ]))),
        const SizedBox(height: 16),
        // 内存占用进程
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('内存占用 Top 进程', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ..._processes.map((p) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [
            Text(p['icon'] as String, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(p['mem'] as String, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ])),
            SizedBox(width: 60, child: Text('${p['pct']}%', style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
            SizedBox(width: 80, child: LinearProgressIndicator(value: (p['pct'] as double) / 100, backgroundColor: Colors.grey.shade200)),
          ]))),
        ]))),
      ])),
    );
  }

  Widget _buildInfo(String label, String value, Color color) {
    return Column(children: [Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)), Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey))]);
  }
}

class _ChartPainter extends CustomPainter {
  final List<double> data;
  final double total;
  _ChartPainter(this.data, this.total);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = Colors.cyan;
    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = i * size.width / 60;
      final y = size.height - (data[i] / total * size.height);
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
