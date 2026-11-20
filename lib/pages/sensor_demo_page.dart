
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class SensorDemoPage extends StatefulWidget {
  const SensorDemoPage({super.key});

  @override
  State<SensorDemoPage> createState() => _SensorDemoPageState();
}

class _SensorDemoPageState extends State<SensorDemoPage> {
  StreamSubscription<UserAccelerometerEvent>? _subscription;

  String _reading = 'Gerakkan ponsel secara perlahan.';

  final List<double> _xValues = [];
  final List<double> _yValues = [];
  final List<double> _zValues = [];

  static const int _maxReadings = 30;

  @override
  void initState() {
    super.initState();

    _subscription = userAccelerometerEventStream().listen(
      (event) {
        if (!mounted) return;

        setState(() {
          _reading = 'x: ${event.x.toStringAsFixed(2)} | '
              'y: ${event.y.toStringAsFixed(2)} | '
              'z: ${event.z.toStringAsFixed(2)} m/s²';

          _xValues.add(event.x);
          _yValues.add(event.y);
          _zValues.add(event.z);

          if (_xValues.length > _maxReadings) {
            _xValues.removeAt(0);
            _yValues.removeAt(0);
            _zValues.removeAt(0);
          }
        });
      },
      onError: (Object error) {
        if (mounted) {
          setState(() {
            _reading = 'Sensor tidak tersedia: $error';
          });
        }
      },
      cancelOnError: true,
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demo Accelerometer'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Nilai Accelerometer',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _reading,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Grafik Pergerakan X, Y, dan Z',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              children: const [
                _Legend(color: Colors.blue, label: 'X'),
                _Legend(color: Colors.orange, label: 'Y'),
                _Legend(color: Colors.green, label: 'Z'),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CustomPaint(
                  painter: AccelerometerChartPainter(
                    xValues: _xValues,
                    yValues: _yValues,
                    zValues: _zValues,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Grafik menampilkan 30 pembacaan sensor terakhir. '
              'Gerakkan ponsel untuk melihat perubahan grafik.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(label),
      ],
    );
  }
}

class AccelerometerChartPainter extends CustomPainter {
  final List<double> xValues;
  final List<double> yValues;
  final List<double> zValues;

  AccelerometerChartPainter({
    required this.xValues,
    required this.yValues,
    required this.zValues,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double minValue = -10;
    const double maxValue = 10;

    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.35)
      ..strokeWidth = 1;

    final zeroPaint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 1.5;

    final chartWidth = size.width;
    final chartHeight = size.height;

    // Garis grid horizontal.
    for (int i = 0; i <= 4; i++) {
      final y = chartHeight * i / 4;

      canvas.drawLine(
        Offset(0, y),
        Offset(chartWidth, y),
        i == 2 ? zeroPaint : gridPaint,
      );
    }

    // Garis grid vertikal.
    for (int i = 0; i <= 5; i++) {
      final x = chartWidth * i / 5;

      canvas.drawLine(
        Offset(x, 0),
        Offset(x, chartHeight),
        gridPaint,
      );
    }

    // Menggambar nilai sensor menjadi garis grafik.
    void drawLine(List<double> values, Color color) {
      if (values.length < 2) return;

      final paint = Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final path = Path();

      for (int i = 0; i < values.length; i++) {
        final x = chartWidth *
            i /
            math.max(_SensorDemoPageStateMax.readings - 1, 1);

        final normalized = (values[i] - minValue) /
            (maxValue - minValue);

        final y = chartHeight *
            (1 - normalized.clamp(0.0, 1.0));

        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      canvas.drawPath(path, paint);
    }

    drawLine(xValues, Colors.blue);
    drawLine(yValues, Colors.orange);
    drawLine(zValues, Colors.green);
  }

  @override
  bool shouldRepaint(covariant AccelerometerChartPainter oldDelegate) {
    return true;
  }
}

class _SensorDemoPageStateMax {
  static const int readings = 30;
}
