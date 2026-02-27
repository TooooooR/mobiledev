import 'package:flutter/material.dart';

void main() {
  runApp(const PCMonitor());
}

class PCMonitor extends StatelessWidget {
  const PCMonitor({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PC Monitor',
      theme: ThemeData.dark(),
      home: const CoolingScreen(),
    );
  }
}

class CoolingScreen extends StatefulWidget {
  const CoolingScreen({super.key});

  @override
  State<CoolingScreen> createState() => _CoolingScreenState();
}

// SingleTickerProviderStateMixin потрібен для плавної роботи анімації
class _CoolingScreenState extends State<CoolingScreen> with SingleTickerProviderStateMixin {
  int _fanSpeed = 30;
  final _controller = TextEditingController();
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  void _updateSpeed() {
    final text = _controller.text.trim().toLowerCase();

    setState(() {
      if (text == "ddr5 is very expensive") {
        _fanSpeed = 0;
        _showAlert("Magic Detected", "System killed by a curse!");
      } else {
        final value = int.tryParse(text);
        if (value != null) {
          _fanSpeed = (_fanSpeed + value).clamp(0, 150);
          if (_fanSpeed > 100) {
            _showAlert("Warning", "Overclocking detected!");
          }
        }
      }
      
      if (_fanSpeed > 0) {
        _animController.duration = Duration(milliseconds: (2000 / (_fanSpeed / 20 + 1)).round());
        _animController.repeat();
      } else {
        _animController.stop();
      }
    });
    _controller.clear();
  }

  void _showAlert(String title, String msg) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(title),
          content: Text(msg),
          actions: [
            TextButton(
              onPressed: () { Navigator.pop(ctx); },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Cooling System",
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)
          ),
        centerTitle: true
        ),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          children: [
            const Spacer(),
            RotationTransition(
              turns: _animController,
              child: Icon(
                Icons.cyclone,
                size: 130,
                color: _fanSpeed > 100 ? Colors.redAccent : Colors.blueAccent,
              ),
            ),
            const SizedBox(
              height: 20
              ),
            Text("$_fanSpeed%", style: const TextStyle(fontSize: 70, fontWeight: FontWeight.bold)),
            const Text("CURRENT FAN LOAD"),
            const Spacer(),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: "Boost speed or enter command",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: () { _updateSpeed(); },
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: const Text("APPLY CHANGES"),
            ),
          ],
        ),
      ),
    );
  }
}
