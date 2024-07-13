
import 'package:flutter/material.dart';

class CallProvider extends ChangeNotifier{
  bool _inOut = false;

  bool get inOut => _inOut;

  void setIn(){
    _inOut = true;
    debugPrint("setting the incoming to true");
    notifyListeners();
  }

  void setOut(){
    _inOut = false;
    debugPrint("setting the incoming to false");
    notifyListeners();
  }

  bool incoming(){
    return true;
  }

  bool outgoing(){
    return false;
  }
}