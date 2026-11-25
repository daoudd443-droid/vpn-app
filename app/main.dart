import 'package:flutter/material.dart';

void main() => runApp(const VpnApp());

class VpnApp extends StatelessWidget {
  const VpnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mon VPN',
      home: Scaffold(
        appBar: AppBar(title: const Text('Mon VPN')),
        body: const Center(
          child: Text('Abonnez-vous pour vous connecter.'),
        ),
      ),
    );
  }
}
