import 'package:flutter/material.dart';
import 'package:rise/Components/DialButton.dart';
import 'package:rise/Resources/Pallete.dart';

class TestingWidget extends StatefulWidget {
  @override
  State<TestingWidget> createState() => _TestingWidgetState();
}

class _TestingWidgetState extends State<TestingWidget> {
  @override
  Widget build(BuildContext context) {
    double buttonWidth = 56.0; // Width of FloatingActionButton by default
    double spacing = 16.0; // Spacing between buttons
    int numberOfButtons = 3; // Number of FloatingActionButtons

    // Calculate total width for all buttons and spacing
    double totalWidth = (buttonWidth * numberOfButtons) + (spacing * (numberOfButtons - 1));

    final List<String> dialPadNumbers = [
      '1', '2', '3',
      '4', '5', '6',
      '7', '8', '9',
      '*', '0', '#'
    ];

    int _selectedIndex = 0;

    void _onItemTapped(int index) {
      setState(() {
        _selectedIndex = index;
      });
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 50),
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
              onPressed: () => (){}
          );
        },
      ),
    );

    return Scaffold(
      body: Center(
        child: Text('Selected Index: $_selectedIndex'),
      ),
      bottomNavigationBar: Stack(
        clipBehavior: Clip.none, // Allows overflow of the floating buttons
        children: [
          BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            selectedItemColor: Colors.orange,
            unselectedItemColor: Colors.grey,
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.swap_horiz),
                label: 'Pay/Transfer',
              ),
              BottomNavigationBarItem(
                icon: SizedBox.shrink(), // Empty space for the floating buttons
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.credit_card),
                label: 'Cards',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Me',
              ),
            ],
          ),
          Positioned(
            bottom: -10.0, // Adjust to control how much the buttons overlap
            left: (MediaQuery.of(context).size.width - totalWidth) / 2, // Center the row of buttons
            child: Row(
              children: [
                FloatingActionButton(
                  backgroundColor: Colors.orange,
                  child: const Icon(Icons.qr_code_scanner, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _selectedIndex = 2; // Select the Scan & Pay tab
                    });
                  },
                ),
                SizedBox(width: spacing), // Space between buttons
                FloatingActionButton(
                  backgroundColor: Colors.orange,
                  child: const Icon(Icons.qr_code_scanner, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _selectedIndex = 2; // Select the Scan & Pay tab
                    });
                  },
                ),
                SizedBox(width: spacing), // Space between buttons
                FloatingActionButton(
                  backgroundColor: Colors.orange,
                  child: const Icon(Icons.qr_code_scanner, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _selectedIndex = 2; // Select the Scan & Pay tab
                    });
                  },
                ),
              ],
            ),
          ),
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
