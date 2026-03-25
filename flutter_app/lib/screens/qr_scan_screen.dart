import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:go_router/go_router.dart';
import '../config.dart';

class QRScanScreen extends StatefulWidget {
  const QRScanScreen({super.key});

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool _isProcessing = false;

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      if (code != null) {
        setState(() {
          _isProcessing = true;
        });

        try {
          // Increment scan count
          await http.post(
            Uri.parse('${AppConfig.baseUrl}/scan'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'studentId': code}),
          );

          // Fetch student details
          final response = await http.get(Uri.parse('${AppConfig.baseUrl}/student/$code'));
          
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (mounted) {
              context.push('/scan_result', extra: data['student']);
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Student not found!')),
              );
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e')),
            );
          }
        } finally {
          if (mounted) {
            setState(() {
              _isProcessing = false;
            });
            // Give user a moment before next scan is possible
            await Future.delayed(const Duration(seconds: 2));
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const scanAreaSize = 250.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
          ),
          CustomPaint(
            painter: ScannerOverlay(scanAreaSize: scanAreaSize),
            child: Container(),
          ),
          if (_isProcessing)
            const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Processing...'),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ScannerOverlay extends CustomPainter {
  final double scanAreaSize;
  ScannerOverlay({required this.scanAreaSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;

    final scanArea = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: scanAreaSize,
      height: scanAreaSize,
    );

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()
          ..addRRect(RRect.fromRectAndRadius(scanArea, const Radius.circular(16)))
          ..close(),
      ),
      paint,
    );

    // Draw borders
    final borderPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;
      
    final borderRect = RRect.fromRectAndRadius(scanArea, const Radius.circular(16));
    canvas.drawRRect(borderRect, borderPaint);

    // Draw scanning line animation if not processing
    // (Omitted for simplicity, but we can add later if requested)
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
