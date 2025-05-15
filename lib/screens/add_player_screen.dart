import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/player.dart';
import '../utils/secret_code.dart';

class AddPlayerScreen extends StatefulWidget {
  const AddPlayerScreen({super.key});

  @override
  State<AddPlayerScreen> createState() => _AddPlayerScreenState();
}

class _AddPlayerScreenState extends State<AddPlayerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  Future<void> _addPlayer() async {
    if (!_formKey.currentState!.validate()) return;

    final confirmed = await SecretCode.verifyCode(context);
    if (!confirmed) return;

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final player = Player(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        createdAt: now,
        updatedAt: now,
      );

      await FirebaseFirestore.instance
          .collection('players')
          .doc(player.id)
          .set(player.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Joueur ajouté avec succès')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un joueur'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom du joueur',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez entrer un nom';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _addPlayer,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Ajouter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 