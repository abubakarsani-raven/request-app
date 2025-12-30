import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_toast.dart';
import 'ict_request_detail_page.dart';
import 'store_fulfillment_page.dart';
import 'request_detail_page.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool isScanning = true;

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (!isScanning) return;
      
      setState(() {
        isScanning = false;
      });

      _handleQRCode(scanData.code ?? '');
    });
  }

  Future<void> _handleQRCode(String qrData) async {
    try {
      // Parse QR code data
      // Format: REQUESTTYPE-REQUESTID-TIMESTAMP
      final parts = qrData.split('-');
      if (parts.length < 2) {
        CustomToast.error('Invalid QR code format');
        _resetScanner();
        return;
      }

      final requestType = parts[0].toUpperCase();
      final requestId = parts[1];

      // Validate request ID
      if (requestId.isEmpty || requestId.length < 24) {
        CustomToast.error('Invalid request ID in QR code');
        _resetScanner();
        return;
      }

      // Navigate to appropriate page based on request type
      switch (requestType) {
        case 'ICT':
          Get.off(() => ICTRequestDetailPage(requestId: requestId));
          break;
        case 'STORE':
          Get.off(() => StoreFulfillmentPage(requestId: requestId));
          break;
        case 'VEHICLE':
          Get.off(() => RequestDetailPage(requestId: requestId));
          break;
        default:
          CustomToast.error('Unknown request type: $requestType');
          _resetScanner();
      }
    } catch (e) {
      CustomToast.error('Error processing QR code: ${e.toString()}');
      _resetScanner();
    }
  }

  void _resetScanner() {
    setState(() {
      isScanning = true;
    });
    controller?.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: AppColors.primary,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: 250,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black87,
            child: Column(
              children: [
                const Text(
                  'Position the QR code within the frame',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        controller?.toggleFlash();
                      },
                      icon: const Icon(Icons.flash_on),
                      label: const Text('Toggle Flash'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        controller?.flipCamera();
                      },
                      icon: const Icon(Icons.flip_camera_android),
                      label: const Text('Flip Camera'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                if (!isScanning) ...[
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _resetScanner,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Scan Again'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
