import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/player.dart';
import '../utils/secret_code.dart';
import 'add_player_screen.dart';
import 'player_stats_screen.dart';

class PlayersListScreen extends StatelessWidget {
  const PlayersListScreen({super.key});

  Future<void> _deletePlayer(BuildContext context, String playerId) async {
    final confirmed = await SecretCode.verifyCode(context);

    if (confirmed) {
      try {
        await FirebaseFirestore.instance.collection('players').doc(playerId).delete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Joueur supprimé avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la suppression : ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste des joueurs'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('players').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Une erreur est survenue', style: TextStyle(color: Colors.white)));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final players = snapshot.data!.docs
                    .map((doc) => Player.fromMap(doc.id, doc.data() as Map<String, dynamic>))
                    .toList();

                if (players.isEmpty) {
                  return const Center(
                    child: Text(
                      'Aucun joueur enregistré',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: players.length,
                  itemBuilder: (context, index) {
                    final player = players[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(player.name[0].toUpperCase(), style: TextStyle(color: Colors.white)),
                        backgroundColor: Color(0xFF1565C0),
                      ),
                      title: Text(player.name, style: TextStyle(color: Colors.white)),
                      subtitle: Text('Ajouté le ${player.createdAt.toString().split(' ')[0]}', style: TextStyle(color: Colors.white70)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deletePlayer(context, player.id),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => PlayerStatsScreen(player: player)),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddPlayerScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
} 