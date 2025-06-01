
// ignore_for_file: unused_import
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRview extends StatefulWidget {
  const QRview({super.key});

  @override
  State<QRview> createState() => _QRView();
}

class _QRView extends State<QRview> {
  String? result;
  bool _isTorchOn = false;
  bool _isFrontCamera = false;
  double _zoom = 0.0;

  MobileScannerController controller = MobileScannerController(
    facing: CameraFacing.back,
    detectionSpeed: DetectionSpeed.normal,
    torchEnabled: false,
  );

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Bus QR'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              final barcode = capture.barcodes.first;
              if (result == null && barcode.rawValue != null) {
                final code = barcode.rawValue!;
                result = code;
                final res = extractBusFromUPI(code);
                log("$res");
                Navigator.of(context).pop(res);
              }
            },
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black54,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          _isTorchOn ? Icons.flashlight_on : Icons.flashlight_off,
                          color: Colors.white,
                        ),
                        onPressed: () async {
                          await controller.toggleTorch();
                          setState(() => _isTorchOn = !_isTorchOn);
                        },
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: Icon(
                          _isFrontCamera ? Icons.camera_front : Icons.camera_rear,
                          color: Colors.white,
                        ),
                        onPressed: () async {
                          await controller.switchCamera();
                          setState(() => _isFrontCamera = !_isFrontCamera);
                        },
                      ),
                    ],
                  ),
                  Slider(
                    value: _zoom,
                    min: 0.0,
                    max: 1.0,
                    divisions: 10,
                    label: '${(_zoom * 100).toInt()}%',
                    onChanged: (value) {
                      setState(() => _zoom = value);
                      controller.setZoomScale(value);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String extractBusFromUPI(String upiLink) {
    final uri = Uri.tryParse(upiLink);
    final pa = uri?.queryParameters['pa'];
    if (pa == null) return '';
    return pa.split('@').first.toUpperCase();
  }
}
