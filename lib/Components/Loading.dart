import 'package:flutter/cupertino.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:rise/Resources/Pallete.dart';

class Loading extends StatelessWidget{
  const Loading({super.key});

  @override
  Widget build(BuildContext context){
    return Center( // Center the content horizontally and vertically
      child: Column(
        mainAxisSize: MainAxisSize.min, // Wrap the content tightly
        mainAxisAlignment: MainAxisAlignment.center, // Center vertically
        crossAxisAlignment: CrossAxisAlignment.center, // Center horizontally
        children: [
          LoadingAnimationWidget.waveDots(
            color: Pallete.gradient1,
            size: 100,
          ),
        ],
      ),
    );
  }
}