import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:provider/provider.dart';
import 'package:rise/Components/DialButton.dart';
import 'package:rise/Components/InputField.dart';
import 'package:rise/Controllers/ApiController.dart';
import 'package:rise/Controllers/StorageController.dart';
import 'package:rise/Resources/Pallete.dart';
import 'package:rise/Resources/Provider/CallProvider.dart';
import 'package:vibration/vibration.dart';

class DialpadWidget extends StatefulWidget {
  const DialpadWidget({super.key});

  @override
  _DialpadWidgetState createState() => _DialpadWidgetState();
}

class _DialpadWidgetState extends State<DialpadWidget> {
  final List<String> dialPadNumbers = [
    '1', '2', '3',
    '4', '5', '6',
    '7', '8', '9',
    '*', '0', '#'
  ];

  String inputNumber = '';

  @override
  void initState() {
    super.initState();
  }


  @override
  void dispose(){
    super.dispose();
  }


  final TextEditingController _controller = TextEditingController();
  void _onButtonPressed(String number) {
    Vibration.vibrate(duration: 100);
    setState(() {
      inputNumber += number;
      _controller.text = inputNumber;
    });
    FlutterBackgroundService().invoke('dtmf',{
      'inputNumber' : inputNumber
    });
    // janus.sendDtmf(inputNumber);
  }
  void _onBackspacePressed() {
    Vibration.vibrate(duration: 100);
    setState(() {
      if (inputNumber.isNotEmpty) {
        inputNumber = inputNumber.substring(0, inputNumber.length - 1);
        _controller.text = inputNumber;
      }
    });
  }
  void _onDialPressed() async{
    Vibration.vibrate(duration: 100);
    final androidHost = await storageController.getData("androidHost");
    if (androidHost == null && androidHost.isEmpty) {
      await api.getAndroidHost();
    }
    debugPrint("calling : $inputNumber");
    // janus.makeCall(inputNumber, androidHost);
    await storageController.storeData("caller", inputNumber);
    FlutterBackgroundService().invoke('makeCall',{
      'inputNumber' : inputNumber,
      'androidHost' : androidHost,
    });

    setState(() {
      inputNumber = "";
      _controller.clear();
    });

  }
  void _onClearPressed() async{
    Vibration.vibrate(duration: 100);
    setState(() {
      inputNumber = "";
      _controller.clear();
    });
    debugPrint("input value : $inputNumber");
    debugPrint("controller value : ${_controller.text}");
  }
  @override
  Widget build(BuildContext context) {
    final callProvider = Provider.of<CallProvider>(context, listen: false);
    final width = MediaQuery.sizeOf(context).width;
    final padding = (width * 0.6/ 3.5).ceil();

    // Calculate the width of the buttons including the spacing between them
    double buttonWidth = 56.0; // Width of FloatingActionButton by default
    double spacing = 16.0; // Spacing between buttons
    double totalWidth = (buttonWidth * 3) + (spacing * 2); // 3 buttons, 2 spaces

    return Scaffold(
      bottomNavigationBar: Stack(
        clipBehavior: Clip.none, // Allows overflow of the floating buttons
        children: [
          Column(
            children: [
              InputField(
                placeholder: "",
                controller: _controller,
                showBorder: false,
                fontSize: 20,
                isEnabled: false,
              ),
              Expanded(
                child: Center(
                  child: FractionallySizedBox(
                    widthFactor: 1, // Adjust as needed
                    heightFactor: 1, // Adjust as needed
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: padding.toDouble()),
                      child: GridView.builder(
                        itemCount: dialPadNumbers.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 10.0,
                          mainAxisSpacing: 10.0,
                          childAspectRatio: 1,
                        ),
                        itemBuilder: (context, index) {
                          String number = dialPadNumbers[index];
                          return DialButton(
                            number: number,
                            onPressed: () => _onButtonPressed(number),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 10.0, // Adjust to control how much the buttons overlap
            left: (MediaQuery.of(context).size.width - totalWidth) / 2, // Center the row of buttons
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton(
                  onPressed: () {
                    callProvider.setOut();
                    _onDialPressed();
                  },
                  backgroundColor: Colors.green,
                  shape: const CircleBorder(),
                  child: const Icon(Icons.phone, color: Colors.white),
                ),
                SizedBox(width: spacing),
                FloatingActionButton(
                  onPressed: _onClearPressed,
                  backgroundColor: Pallete.gradient3,
                  shape: const CircleBorder(),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                SizedBox(width: spacing),
                FloatingActionButton(
                  onPressed: _onBackspacePressed,
                  backgroundColor: Colors.red,
                  shape: const CircleBorder(),
                  child: const Icon(Icons.backspace, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


