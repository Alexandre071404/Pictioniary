import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
                  children: [
            // Text
            Text("PICTION.IA.RY", style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
            )),
            SizedBox(
              height: 50,
            ),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Email',
              ),
            ),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Se connecter'),
            ),
                  ],
                ),
          ),
        ));
  }
}
