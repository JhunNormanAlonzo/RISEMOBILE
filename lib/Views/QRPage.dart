
import 'dart:convert';
import 'dart:io';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_encrypt_plus/flutter_encrypt_plus.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:rise/Components/Loading.dart';
import 'package:rise/Controllers/StorageController.dart';
import 'package:rise/Resources/GeneralConfiguration.dart';
import 'package:rise/Resources/MyToast.dart';
import 'package:rise/Views/Login.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';


class QRPage extends StatefulWidget {
  const QRPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _QRPageState createState() => _QRPageState();
}

class _QRPageState extends State<QRPage> {
  final TextEditingController qrText = TextEditingController();
  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  bool isScanning = true;
  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: isScanning
                ? _buildQrView(context) // Only show QR view if scanning is active
                : const Loading()
          ),
        ],
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
        MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 300.0;
    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller
    return Scaffold(
      appBar: AppBar(
        title: const Text("Qr code scanner"),
      ),
      body: QRView(
        key: qrKey,
        onQRViewCreated: _onQRViewCreated,
        overlay: QrScannerOverlayShape(
            borderColor: Colors.red,
            borderRadius: 10,
            borderLength: 30,
            borderWidth: 10,
            cutOutSize: scanArea),
        onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
      ),
    );


  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;

        if (result?.code?.isNotEmpty ?? false) {
          isScanning = false;
          final storageController = StorageController();
          dynamic qrResponse = result!.code;
          try{
            dynamic decodedResponse = encrypt.decodeString(qrResponse, GeneralConfiguration().getSalt);
            Map<String, dynamic> data = jsonDecode(decodedResponse);
            String appId = data['app_id'];
            String appKey = data['app_key'];
            String base = data['base'];
            String gateway = data['gateway'];
            storageController.storeData("appId", appId);
            storageController.storeData("appKey", appKey);
            storageController.storeData("base", base);
            storageController.storeData("gateway", gateway);
            toast.success(context, 'QR successfully validated.');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Login()),
            );
          }catch(e){
            isScanning = true;
            toast.error(context, "Wrong QR detected.");
          }
        }
      });
    });
  }


  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('no Permission')),
      );
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}