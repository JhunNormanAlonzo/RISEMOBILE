import 'package:flutter/material.dart';
import 'package:rise/Resources/Pallete.dart';

class InputField extends StatefulWidget {
   InputField({
    super.key,
    required this.placeholder,
    required this.controller,
    this.showBorder = true, // Add a new parameter with default value true
    this.fontSize = 16.0, // Add a new parameter for font size with default value
    this.isEnabled = true, // Add a new parameter to enable/disable typing
    this.inputType = TextInputType.text,
    this.isPassword = false
  });

  final String placeholder;
  final TextEditingController controller;
  final bool showBorder; // Parameter to enable/disable borders
  final double fontSize; // Parameter for font size
  final bool isEnabled; // Parameter to enable/disable typing
  final TextInputType inputType;
  bool isPassword;

  @override
  // ignore: library_private_types_in_public_api
  _InputFieldState createState() => _InputFieldState();
}

class _InputFieldState extends State<InputField> {
  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 300,
      ),
      child: TextFormField(
        controller: widget.controller,
        enabled: widget.isEnabled,
        textAlign: TextAlign.center,
        keyboardType: widget.inputType,
        obscureText: widget.isPassword,
        style: TextStyle(fontSize: widget.fontSize, color: Pallete.white),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.all(27),
          enabledBorder: widget.showBorder ? OutlineInputBorder(
            borderSide: const BorderSide(
              color: Pallete.borderColor,
              width: 3,
            ),
            borderRadius: BorderRadius.circular(10),
          ) : const UnderlineInputBorder(
            borderSide: BorderSide.none,
          ),
          focusedBorder: widget.showBorder
              ? OutlineInputBorder(
            borderSide: const BorderSide(
              color: Pallete.gradient1,
              width: 3,
            ),
            borderRadius: BorderRadius.circular(10),
          )
              :  const UnderlineInputBorder(
            borderSide: BorderSide.none,
          ),
          hintText: widget.placeholder,
          hintStyle: TextStyle( // Add hintStyle property
            fontSize: widget.fontSize,
            color: Pallete.gradient4,
          ),
        ),
      ),
    );
  }
}
