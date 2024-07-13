import 'package:flutter/material.dart';
import 'package:rise/Resources/Pallete.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

class MyToast{
  success(context, message){
    showTopSnackBar(Overlay.of(context),  CustomSnackBar.success(message: message,
      icon: const Icon(Icons.check_circle, size: 40, color: Pallete.white,),
      iconPositionLeft: 20,
      iconRotationAngle: 0,
    ));
  }

  error(context, message){
    showTopSnackBar(Overlay.of(context),  CustomSnackBar.error(message: message,
      icon: const Icon(Icons.error_rounded,  size: 40, color: Pallete.white,),
      iconPositionLeft: 20,
      iconRotationAngle: 0,
    ));
  }

  info(context, message){
    showTopSnackBar(Overlay.of(context),  CustomSnackBar.info(message: message,
      icon: const Icon(Icons.error_rounded, size: 40, color: Pallete.white,),
      iconPositionLeft: 20,
      iconRotationAngle: 0,
    ));
  }

  warning(context, message){
    showTopSnackBar(Overlay.of(context),  CustomSnackBar.error(message: message,
      icon: const Icon(Icons.warning,  size: 40, color: Pallete.white,),
      iconPositionLeft: 20,
      iconRotationAngle: 0,
      backgroundColor: const Color(0xffffce52),
      textStyle: const TextStyle(color: Colors.black),
    ));
  }

}

final toast = MyToast();