
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:provider/provider.dart';
import 'package:rise/Resources/MyAudio.dart';
import 'package:rise/Resources/MyVibration.dart';
import 'package:rise/Resources/Provider/NavigationProvider.dart';


class FireWidget extends StatefulWidget{
  const FireWidget({super.key});

  @override
  State<FireWidget> createState() => _FireWidgetState();
}

class _FireWidgetState extends State<FireWidget> {
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navPro = Provider.of<NavigationProvider>(context);
    return Scaffold(
      backgroundColor: Colors.red[800],
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min, // Center content vertically
          children: [
            GestureDetector(
              onTap: () {
                final navigationProvider = Provider.of<NavigationProvider>(context, listen: false);
                myAudio.stop();
                FlutterBackgroundService().invoke('stopVibration');
                navigationProvider.hideFireAlarmWidget();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                child: Image.asset(
                  "assets/images/fire.png",
                  width: 200.0, // Set image size
                  height: 200.0,
                ),
              ),
            ),
            const SizedBox(height: 20.0),
            Text(
              navPro.extension,
              style: const TextStyle(color: Colors.white, fontSize: 50.0),
            ),
            const Text(
              "Tap on the icon to stop!",
              style: TextStyle(color: Colors.white, fontSize: 30.0),
            ),
          ],
        ),
      ),
    );
  }

}