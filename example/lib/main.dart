import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:hardware_rsa_generator/hardware_rsa_generator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _plublicKey = 'Unknown';
  String _signature = 'Unknown';
  final _hardwareRsaGeneratorPlugin = HardwareRsaGenerator();

  @override
  void initState() {
    super.initState();
    generateRsaKeys();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> generateRsaKeys() async {
    String plublicKey;
    String signature;
    // generate rsa key pairs
    try {
      final keyPairStatus = await _hardwareRsaGeneratorPlugin.generateKeyPair();
      debugPrint("the key pair status is $keyPairStatus");
    } on PlatformException catch (e) {
      throw 'Failed to generate key pair: ${e.message}';
    }

    // get public key
    try {
      plublicKey = await _hardwareRsaGeneratorPlugin.getPublicKey() ??
          "failed to get public key";
    } on PlatformException catch (e) {
      throw 'Failed to get public key: ${e.message}';
    }

    // generate signature
    try {
      final data = Uint8List.fromList('Hello, World!'.codeUnits);
      signature = await _hardwareRsaGeneratorPlugin.signData(data) ??
          "Failed to sign data";
    } on PlatformException catch (e) {
      throw 'Failed to sign data: ${e.message}';
    }
    if (!mounted) return;

    setState(() {
      _plublicKey = plublicKey;
      _signature = signature;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Hardware rsa generator app'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('public key is: $_plublicKey\n'),
              Text('signature is: $_signature\n'),
            ],
          ),
        ),
      ),
    );
  }
}
