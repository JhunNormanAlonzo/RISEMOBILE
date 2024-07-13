import 'dart:io';

import 'package:flutter/material.dart';
import 'package:rise/Components/Button.dart';
import 'package:rise/Components/InputField.dart';
import 'package:rise/Controllers/ApiController.dart';
import 'package:rise/Controllers/CoreController.dart';
import 'package:rise/Controllers/StorageController.dart';
import 'package:rise/Resources/MyHttpOverrides.dart';
import 'package:rise/Views/Master/MainFrame.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

class QRInput extends StatefulWidget {
  const QRInput({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _QRInputState createState() => _QRInputState();
}

class _QRInputState extends State<QRInput> {
  final TextEditingController qrCode = TextEditingController();
  bool isHaveAccessToken = false;
  @override
  void initState() {
    super.initState();
    HttpOverrides.global = MyHttpOverrides();
    gettingAccessToken();
  }

  void gettingAccessToken() async{
    dynamic accessToken = await storageController.getData("accessToken");
    if(accessToken.isNotEmpty){
      setState(() {
        isHaveAccessToken = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return isHaveAccessToken ? const MainFrame() : Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 40),
              Image.asset('assets/images/diavox.jpg'),
              const SizedBox(height: 40),
              const Text(
                'Sign In',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 50
                ),
              ),
              const SizedBox(height: 15),
              InputField(
                placeholder: 'QR CODE',
                controller: qrCode,
              ),
              const SizedBox(height: 15),
              Button(
                  label: 'Validate',
                  onPressed: () async {
                    final code  = qrCode.text;
                    if (code.isEmpty) {
                      showTopSnackBar(
                        Overlay.of(context),
                        const CustomSnackBar.error(
                          message:
                          'QR code is required!',
                        ),
                      );
                      return; // Exit the function if fields are empty
                    }
                  }
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }


}
