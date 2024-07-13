

import 'package:flutter/material.dart';

class JanusProvider extends ChangeNotifier{
  bool _isRegistered = false;

  bool get isRegistered => _isRegistered;

  setRegistered(){
    _isRegistered = true;
    notifyListeners();
  }

  setUnRegistered(){
    _isRegistered = false;
    notifyListeners();
  }
}