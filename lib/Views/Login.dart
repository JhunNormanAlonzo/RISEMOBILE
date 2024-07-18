import 'dart:io';

import 'package:flutter/material.dart';
import 'package:rise/Components/Button.dart';
import 'package:rise/Components/InputField.dart';
import 'package:rise/Controllers/ApiController.dart';
import 'package:rise/Controllers/CoreController.dart';
import 'package:rise/Controllers/StorageController.dart';
import 'package:rise/Resources/MyHttpOverrides.dart';
import 'package:rise/Resources/MyToast.dart';
import 'package:rise/Resources/Pallete.dart';
import 'package:rise/Views/Master/MainFrame.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  late TextEditingController mailboxController = TextEditingController();
  late TextEditingController passwordController = TextEditingController();

  bool isHaveAccessToken = false;
  @override
  void initState() {
    super.initState();
    HttpOverrides.global = MyHttpOverrides();
    gettingAccessToken();
    Future(()async{
      passwordController = TextEditingController(text: "Diavox123!");
    });
  }

  void gettingAccessToken() async{
    dynamic accessToken = await storageController.getData("accessToken");
    if(accessToken.isNotEmpty){
      setState(() {
        isHaveAccessToken = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return isHaveAccessToken ? const MainFrame() : loginWidget();
  }


   loginWidget(){
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 40),
              Image.asset('assets/images/diavox.jpg'),
              const SizedBox(height: 40),
              const Center(
                child:  Text(
                  "SIP Registration",
                  style: TextStyle(
                      color: Pallete.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold
                  ),
                ),
              ),
              const SizedBox(height: 25),
              InputField(
                placeholder: 'Mailbox Number',
                controller: mailboxController,
              ),
              const SizedBox(height: 15),
              InputField(
                placeholder: 'Password',
                controller: passwordController,
              ),
              const SizedBox(height: 30),
              Button(
                  label: 'Login',
                  onPressed: () async {
                    final username = mailboxController.text;
                    final password = passwordController.text;
                    print("username : $username");
                    print("password : $password");
                    if (username.isEmpty || password.isEmpty) {
                      toast.warning(context, 'Please enter username and password.');
                      return; // Exit the function if fields are empty
                    }
                    // start storing access token and mailbox number of 200 outside.
                    final status = await coreController.generateAccessToken(username, password);
                    // end storing access token and mailbox number of 200 outside.
                    if (status == 200) {
                      await api.getUserData();
                      Navigator.push(
                        // ignore: use_build_context_synchronously
                        context,
                        MaterialPageRoute(builder: (context) => const MainFrame()),
                      );
                    } else {
                      toast.error(context, 'Username or Password incorrect.');
                    }
                  }
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }


}