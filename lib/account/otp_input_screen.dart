import 'dart:async';

import 'package:flutter/material.dart';
import 'package:livraisonb2b/global_utils/utils.dart';

class OtpInputScreen extends StatefulWidget {
  const OtpInputScreen({
    super.key,
    required this.validateConfirmationCode,
    required this.resendCode,
  });

  static const String idScreen = "otp_screen";
  final Future<void> Function(BuildContext context, String? smsCode)
  validateConfirmationCode;
  final VoidCallback resendCode;

  @override
  State<OtpInputScreen> createState() => _OtpInputScreenState();
}

class _OtpInputScreenState extends State<OtpInputScreen> {
  final TextEditingController _controller = TextEditingController();
  late Timer _timer;
  int _timeLeft = Utils.expireTimer; // 2 minutes in seconds
  bool _isExpired = false;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          _isExpired = true;
          _timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _controller.dispose();
    super.dispose();
  }

  String get timerText {
    if (_isExpired) return "Code expiré";
    int minutes = _timeLeft ~/ 60;
    int seconds = _timeLeft % 60;
    return "Expire dans ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  void resetTimer() {
    setState(() {
      _timeLeft = Utils.expireTimer;
      _isExpired = false;
    });
    startTimer();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _isExpired,
      onPopInvoked: (didPop) {
        displayMessage("Patienter que le code expire", context, true);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text("Code Vérification")),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 24.0,
              horizontal: 16.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Entrer le code de confirmation",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Divider(height: 24.0, thickness: 2.0),
                Icon(
                  Icons.phonelink_lock_outlined,
                  size: 52.0,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: 300.0,
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Code de Confirmation",
                      prefixIcon: const Icon(Icons.phonelink_lock_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8.0),
                ElevatedButton(
                  onPressed:
                      _isExpired
                          ? () {
                            widget.resendCode();
                            resetTimer();
                          }
                          : null,
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(
                      _isExpired
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                    ),
                  ),
                  child: Text(
                    "Renvoyer le code",
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16.0),
                Text(
                  timerText,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _isExpired ? Colors.red : Colors.green,
                  ),
                ),
                const SizedBox(height: 8.0),
                ElevatedButton(
                  onPressed:
                      _isExpired
                          ? null
                          : () async {
                            if (_controller.text.isEmpty) {
                              displayMessage(
                                "Entrez le code de confirmation",
                                context,
                                true,
                              );
                              return;
                            }
                            String code = _controller.text;
                            widget.validateConfirmationCode(context, code);

                            _controller.clear();
                          },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(
                      _isExpired
                          ? Colors.grey
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  child: Text(
                    "Confirmer",
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
