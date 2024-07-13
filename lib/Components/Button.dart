
import 'package:flutter/material.dart';
import 'package:rise/Resources/Pallete.dart';

class Button extends StatelessWidget{
  const Button({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context){
    return Container(
      decoration:  BoxDecoration(
        gradient: const LinearGradient(colors: [
          Pallete.gradient1,
          Pallete.gradient4,
          Pallete.gradient1
        ],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight
        ),
        borderRadius: BorderRadius.circular(7)
      ),
      child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            fixedSize: const Size(300, 55),
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 17,
              color: Pallete.white
            ),
          ),
      ),
    );
  }

}