import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/match.dart';
import '../models/player.dart';
import 'add_match_screen.dart';

class MatchListScreen extends StatelessWidget {
  const MatchListScreen({super.key});

  Future<Player?> _getPlayer(String playerId) async {
    final doc = await FirebaseFirestore.instance.collection('players').doc(playerId).get();
    if (doc.exists) {
      return Player.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  Future<void> _deleteMatch(BuildContext context, String matchId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le match'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce match ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance.collection('matches').doc(matchId).delete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Match supprimé avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la suppression: $e'),
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
        title: const Text('Liste des matchs'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('matches')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Une erreur est survenue'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final matches = snapshot.data!.docs
              .map((doc) => Match.fromMap(doc.id, doc.data() as Map<String, dynamic>))
              .toList();

          if (matches.isEmpty) {
            return const Center(
              child: Text(
                'Aucun match enregistré',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            );
          }

          return ListView.builder(
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index];
              return FutureBuilder<List<Player?>>(
                future: Future.wait([
                  _getPlayer(match.player1Id),
                  match.player1Id2 != null ? _getPlayer(match.player1Id2!) : Future.value(null),
                  _getPlayer(match.player2Id),
                  match.player2Id2 != null ? _getPlayer(match.player2Id2!) : Future.value(null),
                ]),
                builder: (context, playersSnapshot) {
                  if (playersSnapshot.connectionState == ConnectionState.waiting) {
                    return const ListTile(
                      title: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final players = playersSnapshot.data ?? [null, null, null, null];
                  final player1 = players[0];
                  final player1_2 = players[1];
                  final player2 = players[2];
                  final player2_2 = players[3];

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddMatchScreen(match: match),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                    if (player1 != null) Text(
                                      player1!.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Roboto'),
                                    ),
                                    if (player1_2 != null) Text(
                                      player1_2!.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Roboto'),
                                      ),
                                    Text(match.equipePlayer1, style: const TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'Roboto')),
                                    ],
                                ),
                                Column(
                                  children: [
                                    Text(
                                    '${match.statsPlayer1.score} - ${match.statsPlayer2.score}',
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Roboto'),
                                    ),
                                    const Text(
                                      '(Stats par équipe)',
                                      style: TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'Roboto'),
                                  ),
                                  ],
                                ),
                                Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                    if (player2 != null) Text(
                                      player2!.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Roboto'),
                                    ),
                                    if (player2_2 != null) Text(
                                      player2_2!.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Roboto'),
                                      ),
                                    Text(match.equipePlayer2, style: const TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'Roboto')),
                                    ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Date: ${match.date.day}/${match.date.month}/${match.date.year}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontFamily: 'Roboto',
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteMatch(context, match.id),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddMatchScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
} 