import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rise/Components/DialButton.dart';
import 'package:rise/Controllers/ApiController.dart';
import 'package:rise/Resources/Function.dart';
import 'package:rise/Resources/Pallete.dart';

class TestingWidget extends StatefulWidget {
  const TestingWidget({super.key});

  @override
  State<TestingWidget> createState() => _TestingWidgetState();
}

class _TestingWidgetState extends State<TestingWidget> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(onPressed: () async {
            await invoke("detachPlugin");
            // const platform = MethodChannel('com.example.app/call_notification');
            // platform.invokeMethod("sendIncomingCall", {"extension" : "6003"});
          }, child: const Text("TEST"))
        ],
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: TestingWidget(),
  ));
}
