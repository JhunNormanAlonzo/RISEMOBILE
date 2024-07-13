


import 'package:flutter/material.dart';

class SipRegistrationProvider extends ChangeNotifier{
  bool _registered = false;

  bool get registered => _registered;

  void setRegistered(){
    _registered = true;
    notifyListeners();
  }

  void setUnRegistered(){
    _registered = false;
    notifyListeners();
  }
}

