import 'package:flutter/material.dart';

class TestingWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        bool shouldClose = await _showExitConfirmationDialog(context);
        return shouldClose; // If true, the app will close; if false, it won't.
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Your App Title'),
        ),
        body: Center(
          child: Text('Your app content goes here'),
        ),
      ),
    );
  }

  Future<bool> _showExitConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Exit App'),
        content: Text('Are you sure you want to exit the app?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Exit'),
          ),
        ],
      ),
    ) ?? false; // If the user dismisses the dialog, we assume they don't want to exit.
  }

}

void main() {
  runApp(MaterialApp(
    home: TestingWidget(),
  ));
}
