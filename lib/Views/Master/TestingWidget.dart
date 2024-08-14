import 'package:flutter/material.dart';
import 'package:rise/Components/DialButton.dart';
import 'package:rise/Controllers/ApiController.dart';
import 'package:rise/Resources/Pallete.dart';

class TestingWidget extends StatefulWidget {
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
            final result = await api.checkSipRegistration();
            debugPrint(result);
          }, child: const Text("Test"))
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
