import 'package:flutter/material.dart';

class SecretCode {
  static const String _code = '3008';

  static Future<bool> verifyCode(BuildContext context) async {
    final codeController = TextEditingController();
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Code de confirmation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Entrez le code de confirmation :'),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: 'Code de confirmation',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              if (codeController.text == _code) {
                Navigator.pop(context, true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Code incorrect'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }
} 