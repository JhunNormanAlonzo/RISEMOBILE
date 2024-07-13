


import 'package:flutter/foundation.dart';

class NavigationProvider extends ChangeNotifier{
  int _selectedIndex = 0;
  bool _showOnCall = false;
  bool _showFireAlarm = false;
  late String _extension;

  int get selectedIndex => _selectedIndex;
  bool get showOnCall => _showOnCall;
  bool get showFireAlarm => _showFireAlarm;
  String get extension => _extension;

  void setExtension(extension){
    _extension = extension;
    notifyListeners();
  }

  void setIndex(int index){
    _selectedIndex = index;
    debugPrint("Switching widget it index $_selectedIndex via provider");
    notifyListeners();
  }

  void showOnCallWidget() {
    _showOnCall = true;
    _selectedIndex = 3;
    notifyListeners();
  }

  void showFireAlarmWidget() {
    _showFireAlarm = true;
    _selectedIndex = 3;
    notifyListeners();
  }


  void hideFireAlarmWidget() {
    _showFireAlarm = false;
    if (_selectedIndex == 3) {
      _selectedIndex = 0;
    }
    notifyListeners();
  }



  void hideOnCallWidget() {
    _showOnCall = false;
    if (_selectedIndex == 3) {
      _selectedIndex = 0;
    }
    notifyListeners();
  }

}