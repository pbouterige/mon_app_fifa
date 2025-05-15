import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/player.dart';
import '../models/match.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => setState(() => _selectedIndex = 0),
                icon: const Icon(Icons.person),
                label: const Text('Stats de joueurs'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedIndex == 0 ? Colors.blue : Colors.grey[300],
                  foregroundColor: _selectedIndex == 0 ? Colors.white : Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => setState(() => _selectedIndex = 1),
                icon: const Icon(Icons.people),
                label: const Text('Confrontation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedIndex == 1 ? Colors.blue : Colors.grey[300],
                  foregroundColor: _selectedIndex == 1 ? Colors.white : Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: _selectedIndex == 0
                ? const PlayerStatsRankingView()
                : const ConfrontationView(),
          ),
        ],
      ),
    );
  }
}

class PlayerStatsRankingView extends StatefulWidget {
  const PlayerStatsRankingView({super.key});

  @override
  State<PlayerStatsRankingView> createState() => _PlayerStatsRankingViewState();
}

class _PlayerStatsRankingViewState extends State<PlayerStatsRankingView> {
  String? _matchType = 'all';
  String? _selectedGameMode;
  Set<String> _gameModes = {};

  @override
  Widget build(BuildContext context) {
    return Column(
        children: [
          FutureBuilder<List<dynamic>>(
            future: _fetchPlayersAndMatches(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final matches = snapshot.data![1] as List<Match>;
                _gameModes = {};
                for (final match in matches) {
                  if (match.jeu.isNotEmpty) {
                    _gameModes.add(match.jeu);
                  }
                }
              }
              return RankingFilter(
                key: const ValueKey('stats_filter'),
                matchType: _matchType,              // _matchType est maintenant String? ('all','face-a-face',...)
                onMatchTypeChanged: (value) => setState(() => _matchType = value),
                selectedGameMode: _selectedGameMode,
                onGameModeChanged: (value) => setState(() => _selectedGameMode = value),
                gameModes: _gameModes.toList(),
              );
            },
          ),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: _fetchPlayersAndMatches(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Erreur: ${snapshot.error}'));
              }
              final players = snapshot.data![0] as List<Player>;
              var matches = snapshot.data![1] as List<Match>;
              
              // Filtrage par type de match
              matches = matches.where((m) {
                switch (_matchType) {
                  case 'face-a-face':
                    return m.player1Id2 == null && m.player2Id2 == null;
                  case '2v1':
                    return (m.player1Id2 != null && m.player2Id2 == null) || (m.player1Id2 == null && m.player2Id2 != null);
                  case '2v2':
                    return m.player1Id2 != null && m.player2Id2 != null;
                  default: // 'all'
                    return true;
                }
              }).toList();

              if (_selectedGameMode != null) {
                matches = matches.where((m) => m.jeu == _selectedGameMode).toList();
              }
              if (players.isEmpty) {
                return const Center(child: Text('Aucun joueur enregistré', style: TextStyle(color: Colors.white)));
              }
              if (matches.isEmpty) {
                return const Center(child: Text('Aucun match enregistré', style: TextStyle(color: Colors.white)));
              }
              // Calcul des stats pour chaque joueur
              final statsByPlayer = <String, _PlayerAggregatedStats>{};
              for (final player in players) {
                statsByPlayer[player.id] = _PlayerAggregatedStats(player);
              }
              for (final match in matches) {
                // Équipe 1
                final p1 = statsByPlayer[match.player1Id];
                final p1_2 = match.player1Id2 != null ? statsByPlayer[match.player1Id2] : null;
                if (p1 != null) p1.addMatch(match.statsPlayer1, match.statsPlayer2);
                if (p1_2 != null) p1_2.addMatch(match.statsPlayer1, match.statsPlayer2);

                // Équipe 2
                final p2 = statsByPlayer[match.player2Id];
                final p2_2 = match.player2Id2 != null ? statsByPlayer[match.player2Id2] : null;
                if (p2 != null) p2.addMatch(match.statsPlayer2, match.statsPlayer1);
                if (p2_2 != null) p2_2.addMatch(match.statsPlayer2, match.statsPlayer1);
              }
              // Liste des classements à afficher
              final List<_ClassementConfig> classements = [
                _ClassementConfig(
                  titre: 'Pourcentage de victoire',
                  getValue: (s) => s.nbMatches > 0 ? (s.nbVictoires / s.nbMatches * 100) : 0,
                  format: (v) => '${v.toStringAsFixed(1)} %',
                  desc: true,
                ),
                _ClassementConfig(
                  titre: 'Nombre de matches',
                  getValue: (s) => s.nbMatches.toDouble(),
                  format: (v) => v.toStringAsFixed(0),
                  desc: true,
                ),
                _ClassementConfig(
                  titre: 'Buts marqués / match',
                  getValue: (s) => s.nbMatches > 0 ? (s.butsMarques / s.nbMatches) : 0,
                  format: (v) => v.toStringAsFixed(2),
                  desc: true,
                ),
                _ClassementConfig(
                  titre: 'Buts encaissés / match',
                  getValue: (s) => s.nbMatches > 0 ? (s.butsEncaisses / s.nbMatches) : 0,
                  format: (v) => v.toStringAsFixed(2),
                  desc: false,
                ),
                _ClassementConfig(
                  titre: 'Buts marqués (total)',
                  getValue: (s) => s.butsMarques.toDouble(),
                  format: (v) => v.toStringAsFixed(0),
                  desc: true,
                ),
                _ClassementConfig(
                  titre: 'Buts encaissés (total)',
                  getValue: (s) => s.butsEncaisses.toDouble(),
                  format: (v) => v.toStringAsFixed(0),
                  desc: false,
                ),
                _ClassementConfig(
                  titre: 'Possession moyenne',
                  getValue: (s) => s.nbMatches > 0 ? (s.possession / s.nbMatches) : 0,
                  format: (v) => '${v.toStringAsFixed(1)} %',
                  desc: true,
                ),
                _ClassementConfig(
                  titre: 'Tirs / match',
                  getValue: (s) => s.nbMatches > 0 ? (s.tirs / s.nbMatches) : 0,
                  format: (v) => v.toStringAsFixed(2),
                  desc: true,
                ),
                _ClassementConfig(
                  titre: 'Expected goals / match',
                  getValue: (s) => s.nbMatches > 0 ? (s.expectedGoals / s.nbMatches) : 0,
                  format: (v) => v.toStringAsFixed(2),
                  desc: true,
                ),
                _ClassementConfig(
                  titre: 'Passes réussies / match',
                  getValue: (s) => s.nbMatches > 0 ? (s.passesReussies / s.nbMatches) : 0,
                  format: (v) => v.toStringAsFixed(2),
                  desc: true,
                ),
                _ClassementConfig(
                  titre: 'Précision passe moyenne',
                  getValue: (s) => s.nbMatches > 0 ? (s.precisionPasse / s.nbMatches) : 0,
                  format: (v) => '${v.toStringAsFixed(1)} %',
                  desc: true,
                ),
                _ClassementConfig(
                  titre: 'Précision tir moyenne',
                  getValue: (s) => s.nbMatches > 0 ? (s.precisionTir / s.nbMatches) : 0,
                  format: (v) => '${v.toStringAsFixed(1)} %',
                  desc: true,
                ),
                _ClassementConfig(
                  titre: 'Précision dribble moyenne',
                  getValue: (s) => s.nbMatches > 0 ? (s.precisionDribble / s.nbMatches) : 0,
                  format: (v) => '${v.toStringAsFixed(1)} %',
                  desc: true,
                ),
                _ClassementConfig(
                  titre: 'Tacles / match',
                  getValue: (s) => s.nbMatches > 0 ? (s.tacles / s.nbMatches) : 0,
                  format: (v) => v.toStringAsFixed(2),
                  desc: true,
                ),
                _ClassementConfig(
                  titre: 'Tacles réussis / match',
                  getValue: (s) => s.nbMatches > 0 ? (s.taclesReussis / s.nbMatches) : 0,
                  format: (v) => v.toStringAsFixed(2),
                  desc: true,
                ),
                _ClassementConfig(
                  titre: 'Interceptions / match',
                  getValue: (s) => s.nbMatches > 0 ? (s.interceptions / s.nbMatches) : 0,
                  format: (v) => v.toStringAsFixed(2),
                  desc: true,
                ),
                _ClassementConfig(
                  titre: 'Fautes / match',
                  getValue: (s) => s.nbMatches > 0 ? (s.fautes / s.nbMatches) : 0,
                  format: (v) => v.toStringAsFixed(2),
                  desc: false,
                ),
              ];
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: classements.length + 1,
                separatorBuilder: (context, i) => const Divider(height: 32, color: Colors.white),
                itemBuilder: (context, i) {
                  if (i < classements.length) {
                    final classement = classements[i];
                    final joueursTries = statsByPlayer.values.toList()
                      ..sort((a, b) => classement.desc
                          ? classement.getValue(b).compareTo(classement.getValue(a))
                          : classement.getValue(a).compareTo(classement.getValue(b)));
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 180,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              classement.titre,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (int idx = 0; idx < joueursTries.length; idx++)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Row(
                                    children: [
                                      if (idx == 0)
                                        const Text('🥇 ', style: TextStyle(fontSize: 16, color: Colors.white))
                                      else if (idx == 1)
                                        const Text('🥈 ', style: TextStyle(fontSize: 16, color: Colors.white))
                                      else if (idx == 2)
                                        const Text('🥉 ', style: TextStyle(fontSize: 16, color: Colors.white))
                                      else
                                        const SizedBox(width: 24),
                                      Text(
                                        '${joueursTries[idx].player.name} : ${classement.format(classement.getValue(joueursTries[idx]))}',
                                        style: const TextStyle(fontSize: 15, color: Colors.white, fontFamily: 'Roboto'),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    );
                  } else {
                    // Section équipe la plus jouée
                    // Pour chaque joueur, on compte les équipes jouées
                    final Map<String, Map<String, int>> equipesParJoueur = {};
                    for (final match in matches) {
                      // Équipe 1
                      equipesParJoueur.putIfAbsent(match.player1Id, () => {});
                      equipesParJoueur[match.player1Id]![match.equipePlayer1] = (equipesParJoueur[match.player1Id]![match.equipePlayer1] ?? 0) + 1;
                      if (match.player1Id2 != null) {
                        equipesParJoueur.putIfAbsent(match.player1Id2!, () => {});
                        equipesParJoueur[match.player1Id2!]![match.equipePlayer1] = (equipesParJoueur[match.player1Id2!]![match.equipePlayer1] ?? 0) + 1;
                      }

                      // Équipe 2
                      equipesParJoueur.putIfAbsent(match.player2Id, () => {});
                      equipesParJoueur[match.player2Id]![match.equipePlayer2] = (equipesParJoueur[match.player2Id]![match.equipePlayer2] ?? 0) + 1;
                      if (match.player2Id2 != null) {
                        equipesParJoueur.putIfAbsent(match.player2Id2!, () => {});
                        equipesParJoueur[match.player2Id2!]![match.equipePlayer2] = (equipesParJoueur[match.player2Id2!]![match.equipePlayer2] ?? 0) + 1;
                      }
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 180,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              "Équipe la plus jouée",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final stats in statsByPlayer.values)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Text(
                                    '${stats.player.name} : '
                                    '${_getMostPlayedTeam(equipesParJoueur[stats.player.id] ?? {})}',
                                    style: const TextStyle(fontSize: 15, color: Colors.white, fontFamily: 'Roboto'),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<List<dynamic>> _fetchPlayersAndMatches() async {
    final playersSnap = await FirebaseFirestore.instance.collection('players').get();
    final matchesSnap = await FirebaseFirestore.instance.collection('matches').get();
    final players = playersSnap.docs.map((doc) => Player.fromMap(doc.id, doc.data())).toList();
    final matches = matchesSnap.docs.map((doc) => Match.fromMap(doc.id, doc.data())).toList();
    return [players, matches];
  }
}

class ConfrontationView extends StatefulWidget {
  const ConfrontationView({super.key});

  @override
  State<ConfrontationView> createState() => _ConfrontationViewState();
}

class _ConfrontationViewState extends State<ConfrontationView> {
  String? _player1Id;
  String? _player2Id;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Player>>(
      future: _fetchPlayers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }
        final players = snapshot.data!..sort((a, b) => a.name.compareTo(b.name));
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<String>(
                    value: _player1Id,
                    hint: const Text('Joueur 1'),
                    items: players.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                    onChanged: (v) => setState(() => _player1Id = v),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<String>(
                    value: _player2Id,
                    hint: const Text('Joueur 2'),
                    items: players.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                    onChanged: (v) => setState(() => _player2Id = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const ConfrontationFilter(),
            if (_player1Id != null && _player2Id != null && _player1Id != _player2Id)
              Expanded(
                child: _ConfrontationResult(
                  player1Id: _player1Id!,
                  player2Id: _player2Id!,
                ),
              ),
          ],
        );
      },
    );
  }

  Future<List<Player>> _fetchPlayers() async {
    final snap = await FirebaseFirestore.instance.collection('players').get();
    return snap.docs.map((doc) => Player.fromMap(doc.id, doc.data())).toList();
  }
}

class ConfrontationFilter extends StatefulWidget {
  static String? matchType = 'all';
  static final ValueNotifier<String?> matchTypeNotifier = ValueNotifier<String?>('all');
  static String? selectedGameMode;
  static final ValueNotifier<String?> gameModeNotifier = ValueNotifier<String?>(null);

  const ConfrontationFilter({super.key});
  @override
  State<ConfrontationFilter> createState() => _ConfrontationFilterState();
}


class _ConfrontationFilterState extends State<ConfrontationFilter> {
  bool _isExpanded = false;
  Set<String> _gameModes = {};

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            title: const Text(
              'Filtres',
              style: TextStyle(
                color: Colors.black87,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            trailing: Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
              color: Colors.black87,
              size: 20,
            ),
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                children: [
                  // Champ "Type de match" au lieu de la checkbox
                  DropdownButtonFormField<String>(
                    value: ConfrontationFilter.matchType,
                    items: const [
                      DropdownMenuItem(value: 'all',        child: Text('Tout type de match', style: TextStyle(color: Colors.black87))),
                      DropdownMenuItem(value: 'face-a-face', child: Text('Face-à-face',      style: TextStyle(color: Colors.black87))),
                      DropdownMenuItem(value: '2v1',         child: Text('Deux contre un',   style: TextStyle(color: Colors.black87))),
                      DropdownMenuItem(value: '2v2',         child: Text('Deux contre deux', style: TextStyle(color: Colors.black87))),
                    ],
                    onChanged: (value) {
                      setState(() {
                        ConfrontationFilter.matchType = value;
                        ConfrontationFilter.matchTypeNotifier.value = value;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Type de match',
                      labelStyle: TextStyle(color: Colors.black87),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black87)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black87)),
                    ),
                    style: const TextStyle(color: Colors.black87),
                  ),
                  const SizedBox(height: 8),

                  // Filtre par jeu
                  FutureBuilder<List<Match>>(
                    future: _fetchMatches(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        _gameModes = { for (var m in snapshot.data!) if (m.jeu.isNotEmpty) m.jeu };
                      }
                      return DropdownButtonFormField<String>(
                        value: ConfrontationFilter.selectedGameMode,
                        hint: const Text('Tous les jeux', style: TextStyle(color: Colors.black87)),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('Tous les jeux', style: TextStyle(color: Colors.black87)),
                          ),
                          ..._gameModes.map((mode) => DropdownMenuItem<String>(
                            value: mode,
                            child: Text(mode, style: const TextStyle(color: Colors.black87)),
                          )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            ConfrontationFilter.selectedGameMode = value;
                            ConfrontationFilter.gameModeNotifier.value = value;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Filtrer par jeu',
                          labelStyle: TextStyle(color: Colors.black87),
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black87)),
                          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black87)),
                        ),
                        style: const TextStyle(color: Colors.black87),
                      );
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<List<Match>> _fetchMatches() async {
    final snap = await FirebaseFirestore.instance.collection('matches').get();
    return snap.docs.map((doc) => Match.fromMap(doc.id, doc.data())).toList();
  }
}


class _ConfrontationResult extends StatefulWidget {
  final String player1Id;
  final String player2Id;
  const _ConfrontationResult({
    required this.player1Id,
    required this.player2Id,
  });

  @override
  State<_ConfrontationResult> createState() => _ConfrontationResultState();
}

class _ConfrontationResultState extends State<_ConfrontationResult> {
  bool _showHistory = false;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: ConfrontationFilter.matchTypeNotifier,
      builder: (context, matchType, _) {
        return ValueListenableBuilder<String?>(
          valueListenable: ConfrontationFilter.gameModeNotifier,
          builder: (context, selectedGameMode, _) {
            return FutureBuilder<List<Match>>(
              future: _fetchMatchesBetween(widget.player1Id, widget.player2Id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Erreur: ${snapshot.error}'));
                }
                var matches = snapshot.data!;

                // Filtre par type de match
                if (matchType != null && matchType != 'all') {
                  matches = matches.where((m) {
                    switch (matchType) {
                      case 'face-a-face':
                        return m.player1Id2 == null && m.player2Id2 == null;
                      case '2v1':
                        return (m.player1Id2 != null && m.player2Id2 == null)
                            || (m.player1Id2 == null && m.player2Id2 != null);
                      case '2v2':
                        return m.player1Id2 != null && m.player2Id2 != null;
                      default:
                        return true;
                    }
                  }).toList();
                }

                // Filtre par jeu
                if (selectedGameMode != null) {
                  matches = matches.where((m) => m.jeu == selectedGameMode).toList();
                }

                if (matches.isEmpty) {
                  return const Center(
                    child: Text(
                      'Aucune confrontation trouvée entre ces deux joueurs.',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }
            // Récupérer les infos joueurs
            final playerNames = <String, String>{};
            for (final m in matches) {
              playerNames[m.player1Id] = '';
              playerNames[m.player2Id] = '';
            }
            // On suppose que les noms sont identiques pour tous les matchs
            return FutureBuilder<List<Player>>(
              future: _fetchPlayersByIds([widget.player1Id, widget.player2Id]),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final players = {for (var p in snap.data ?? []) p.id: p};
                final p1 = players[widget.player1Id];
                final p2 = players[widget.player2Id];
                if (p1 == null || p2 == null) {
                  return const Center(child: Text('Erreur lors de la récupération des joueurs.'));
                }
                // Calcul des stats sur les confrontations
                final stats1 = _PlayerAggregatedStats(p1);
                final stats2 = _PlayerAggregatedStats(p2);
                final Map<String, int> equipes1 = {};
                final Map<String, int> equipes2 = {};
                for (final match in matches) {
                  if (match.player1Id == widget.player1Id) {
                    stats1.addMatch(match.statsPlayer1, match.statsPlayer2);
                    stats2.addMatch(match.statsPlayer2, match.statsPlayer1);
                    equipes1[match.equipePlayer1] = (equipes1[match.equipePlayer1] ?? 0) + 1;
                    equipes2[match.equipePlayer2] = (equipes2[match.equipePlayer2] ?? 0) + 1;
                  } else {
                    stats1.addMatch(match.statsPlayer2, match.statsPlayer1);
                    stats2.addMatch(match.statsPlayer1, match.statsPlayer2);
                    equipes1[match.equipePlayer2] = (equipes1[match.equipePlayer2] ?? 0) + 1;
                    equipes2[match.equipePlayer1] = (equipes2[match.equipePlayer1] ?? 0) + 1;
                  }
                }
                // Liste des stats à comparer
                final List<_ClassementConfig> classements = [
                  _ClassementConfig(
                    titre: 'Pourcentage de victoire',
                    getValue: (s) => s.nbMatches > 0 ? (s.nbVictoires / s.nbMatches * 100) : 0,
                    format: (v) => '${v.toStringAsFixed(1)} %',
                    desc: true,
                  ),
                  _ClassementConfig(
                    titre: 'Buts marqués / match',
                    getValue: (s) => s.nbMatches > 0 ? (s.butsMarques / s.nbMatches) : 0,
                    format: (v) => v.toStringAsFixed(2),
                    desc: true,
                  ),
                  _ClassementConfig(
                    titre: 'Buts encaissés / match',
                    getValue: (s) => s.nbMatches > 0 ? (s.butsEncaisses / s.nbMatches) : 0,
                    format: (v) => v.toStringAsFixed(2),
                    desc: false,
                  ),
                  _ClassementConfig(
                    titre: 'Buts marqués (total)',
                    getValue: (s) => s.butsMarques.toDouble(),
                    format: (v) => v.toStringAsFixed(0),
                    desc: true,
                  ),
                  _ClassementConfig(
                    titre: 'Buts encaissés (total)',
                    getValue: (s) => s.butsEncaisses.toDouble(),
                    format: (v) => v.toStringAsFixed(0),
                    desc: false,
                  ),
                  _ClassementConfig(
                    titre: 'Possession moyenne',
                    getValue: (s) => s.nbMatches > 0 ? (s.possession / s.nbMatches) : 0,
                    format: (v) => '${v.toStringAsFixed(1)} %',
                    desc: true,
                  ),
                  _ClassementConfig(
                    titre: 'Tirs / match',
                    getValue: (s) => s.nbMatches > 0 ? (s.tirs / s.nbMatches) : 0,
                    format: (v) => v.toStringAsFixed(2),
                    desc: true,
                  ),
                  _ClassementConfig(
                    titre: 'Expected goals / match',
                    getValue: (s) => s.nbMatches > 0 ? (s.expectedGoals / s.nbMatches) : 0,
                    format: (v) => v.toStringAsFixed(2),
                    desc: true,
                  ),
                  _ClassementConfig(
                    titre: 'Passes réussies / match',
                    getValue: (s) => s.nbMatches > 0 ? (s.passesReussies / s.nbMatches) : 0,
                    format: (v) => v.toStringAsFixed(2),
                    desc: true,
                  ),
                  _ClassementConfig(
                    titre: 'Précision passe moyenne',
                    getValue: (s) => s.nbMatches > 0 ? (s.precisionPasse / s.nbMatches) : 0,
                    format: (v) => '${v.toStringAsFixed(1)} %',
                    desc: true,
                  ),
                  _ClassementConfig(
                    titre: 'Précision tir moyenne',
                    getValue: (s) => s.nbMatches > 0 ? (s.precisionTir / s.nbMatches) : 0,
                    format: (v) => '${v.toStringAsFixed(1)} %',
                    desc: true,
                  ),
                  _ClassementConfig(
                    titre: 'Précision dribble moyenne',
                    getValue: (s) => s.nbMatches > 0 ? (s.precisionDribble / s.nbMatches) : 0,
                    format: (v) => '${v.toStringAsFixed(1)} %',
                    desc: true,
                  ),
                  _ClassementConfig(
                    titre: 'Tacles / match',
                    getValue: (s) => s.nbMatches > 0 ? (s.tacles / s.nbMatches) : 0,
                    format: (v) => v.toStringAsFixed(2),
                    desc: true,
                  ),
                  _ClassementConfig(
                    titre: 'Tacles réussis / match',
                    getValue: (s) => s.nbMatches > 0 ? (s.taclesReussis / s.nbMatches) : 0,
                    format: (v) => v.toStringAsFixed(2),
                    desc: true,
                  ),
                  _ClassementConfig(
                    titre: 'Interceptions / match',
                    getValue: (s) => s.nbMatches > 0 ? (s.interceptions / s.nbMatches) : 0,
                    format: (v) => v.toStringAsFixed(2),
                    desc: true,
                  ),
                  _ClassementConfig(
                    titre: 'Fautes / match',
                    getValue: (s) => s.nbMatches > 0 ? (s.fautes / s.nbMatches) : 0,
                    format: (v) => v.toStringAsFixed(2),
                    desc: false,
                  ),
                ];
                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 180),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(p1.name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                              ),
                              Expanded(
                                child: Text(p2.name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 180,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              "Nombre de rencontres",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Text(
                                    matches.length.toString(),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    for (final classement in classements)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 180,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                classement.titre,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    color: _getColor(
                                      classement.getValue(stats1),
                                      classement.getValue(stats2),
                                      classement.desc,
                                      true,
                                    ),
                                    child: Text(
                                      classement.format(classement.getValue(stats1)),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    color: _getColor(
                                      classement.getValue(stats2),
                                      classement.getValue(stats1),
                                      classement.desc,
                                      false,
                                    ),
                                    child: Text(
                                      classement.format(classement.getValue(stats2)),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    const Divider(height: 32),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 180,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              "Équipe la plus jouée",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Text(
                                    _getMostPlayedTeam(equipes1),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Text(
                                    _getMostPlayedTeam(equipes2),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ConfrontationHistoryScreen(
                                matches: matches,
                                player1: p1,
                                player2: p2,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.history),
                        label: const Text('Voir l\'historique des matchs'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                  ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Future<List<Match>> _fetchMatchesBetween(String id1, String id2) async {
    final snap = await FirebaseFirestore.instance.collection('matches').get();
    return snap.docs
        .map((doc) => Match.fromMap(doc.id, doc.data()))
        .where((m) {
          // Vérifie si les deux joueurs sont dans le même match
          final p1InTeam1 = m.player1Id == id1 || m.player1Id2 == id1;
          final p1InTeam2 = m.player2Id == id1 || m.player2Id2 == id1;
          final p2InTeam1 = m.player1Id == id2 || m.player1Id2 == id2;
          final p2InTeam2 = m.player2Id == id2 || m.player2Id2 == id2;
          
          // Les joueurs doivent être dans des équipes différentes
          return (p1InTeam1 && p2InTeam2) || (p1InTeam2 && p2InTeam1);
        })
        .toList();
  }

  Future<List<Player>> _fetchPlayersByIds(List<String> ids) async {
    final snap = await FirebaseFirestore.instance.collection('players').where(FieldPath.documentId, whereIn: ids).get();
    return snap.docs.map((doc) => Player.fromMap(doc.id, doc.data())).toList();
  }

  Color _getColor(double v1, double v2, bool desc, bool isLeft) {
    if (v1 == v2) return Colors.transparent;
    final bool isWinner = desc ? v1 > v2 : v1 < v2;
    if (isWinner) {
      return Colors.green.withOpacity(0.15);
    } else {
      return Colors.red.withOpacity(0.15);
    }
  }
}

class ConfrontationHistoryScreen extends StatelessWidget {
  final List<Match> matches;
  final Player player1;
  final Player player2;
  const ConfrontationHistoryScreen({super.key, required this.matches, required this.player1, required this.player2});

  @override
  Widget build(BuildContext context) {
    final sortedMatches = [...matches]..sort((a, b) => b.date.compareTo(a.date));
    return Scaffold(
      appBar: AppBar(
        title: Text('Historique : ${player1.name} vs ${player2.name}'),
      ),
      body: sortedMatches.isEmpty
          ? const Center(child: Text('Aucune rencontre enregistrée.'))
          : ListView.builder(
              itemCount: sortedMatches.length,
              itemBuilder: (context, index) {
                final m = sortedMatches[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FutureBuilder<Player?>(
                                  future: _getPlayer(m.player1Id),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData && snapshot.data != null) {
                                      return Text(snapshot.data!.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Roboto'));
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                                if (m.player1Id2 != null)
                                  FutureBuilder<Player?>(
                                    future: _getPlayer(m.player1Id2),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData && snapshot.data != null) {
                                        return Text(snapshot.data!.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Roboto'));
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                Text(m.equipePlayer1, style: const TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'Roboto')),
                              ],
                            ),
                            Text('${m.statsPlayer1.score} - ${m.statsPlayer2.score}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Roboto')),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                FutureBuilder<Player?>(
                                  future: _getPlayer(m.player2Id),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData && snapshot.data != null) {
                                      return Text(snapshot.data!.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Roboto'));
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                                if (m.player2Id2 != null)
                                  FutureBuilder<Player?>(
                                    future: _getPlayer(m.player2Id2),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData && snapshot.data != null) {
                                        return Text(snapshot.data!.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Roboto'));
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                Text(m.equipePlayer2, style: const TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'Roboto')),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Date : ${m.date.day}/${m.date.month}/${m.date.year}', style: TextStyle(color: Colors.grey[600], fontFamily: 'Roboto')),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<Player?> _getPlayer(String? id) async {
    if (id == null) return null;
    final snap = await FirebaseFirestore.instance.collection('players').doc(id).get();
    if (!snap.exists || snap.data() == null) return null;
    return Player.fromMap(snap.id, snap.data()!);
  }
}

class _PlayerAggregatedStats {
  final Player player;
  int nbMatches = 0;
  int nbVictoires = 0;
  int butsMarques = 0;
  int butsEncaisses = 0;
  double possession = 0;
  int tirs = 0;
  double expectedGoals = 0;
  int passesReussies = 0;
  double precisionPasse = 0;
  double precisionTir = 0;
  double precisionDribble = 0;
  int tacles = 0;
  int taclesReussis = 0;
  int interceptions = 0;
  int fautes = 0;

  _PlayerAggregatedStats(this.player);

  void addMatch(PlayerStats stats, PlayerStats statsAdverse) {
    nbMatches++;
    butsMarques += stats.score;
    butsEncaisses += statsAdverse.score;
    if (stats.score > statsAdverse.score) nbVictoires++;
    possession += stats.possession;
    tirs += stats.tirs;
    expectedGoals += stats.expected_goals;
    passesReussies += stats.passes_reussies;
    precisionPasse += stats.precision_passe;
    precisionTir += stats.precision_tir;
    precisionDribble += stats.precision_dribble;
    tacles += stats.tacles;
    taclesReussis += stats.tacles_reussis;
    interceptions += stats.interceptions;
    fautes += stats.fautes;
  }
}

class _ClassementConfig {
  final String titre;
  final double Function(_PlayerAggregatedStats) getValue;
  final String Function(double) format;
  final bool desc;
  _ClassementConfig({required this.titre, required this.getValue, required this.format, required this.desc});
}

String _getMostPlayedTeam(Map<String, int> equipes) {
  if (equipes.isEmpty) return '-';
  String maxEquipe = equipes.keys.first;
  int maxCount = equipes[maxEquipe]!;
  equipes.forEach((equipe, count) {
    if (count > maxCount) {
      maxEquipe = equipe;
      maxCount = count;
    }
  });
  return maxEquipe;
}


// Filtre pour le classement des statistiques entre tous les joueurs
class RankingFilter extends StatefulWidget {
  final String? matchType;
  final Function(String?) onMatchTypeChanged;
  final String? selectedGameMode;
  final Function(String?) onGameModeChanged;
  final List<String> gameModes;

  const RankingFilter({
    super.key,
    required this.matchType,
    required this.onMatchTypeChanged,
    this.selectedGameMode,
    required this.onGameModeChanged,
    required this.gameModes,
  });

  @override
  State<RankingFilter> createState() => _RankingFilterState();
}

class _RankingFilterState extends State<RankingFilter> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            title: const Text(
              'Filtres',
              style: TextStyle(
                color: Colors.black87,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            trailing: Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
              color: Colors.black87,
              size: 20,
            ),
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: widget.matchType,
                    items: const [
                      DropdownMenuItem(value: 'all',        child: Text('Tout type de match', style: TextStyle(color: Colors.black87))),
                      DropdownMenuItem(value: 'face-a-face', child: Text('Face-à-face', style: TextStyle(color: Colors.black87))),
                      DropdownMenuItem(value: '2v1',         child: Text('Deux contre un', style: TextStyle(color: Colors.black87))),
                      DropdownMenuItem(value: '2v2',         child: Text('Deux contre deux', style: TextStyle(color: Colors.black87))),
                    ],
                    onChanged: widget.onMatchTypeChanged,
                    decoration: const InputDecoration(
                      labelText: 'Type de match',
                      labelStyle: TextStyle(color: Colors.black87),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black87)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black87)),
                    ),
                    style: const TextStyle(color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: widget.selectedGameMode,
                    hint: const Text('Tous les jeux', style: TextStyle(color: Colors.black87)),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Tous les jeux', style: TextStyle(color: Colors.black87))),
                      ...widget.gameModes.map((mode) => DropdownMenuItem(value: mode, child: Text(mode, style: const TextStyle(color: Colors.black87)))),
                    ],
                    onChanged: widget.onGameModeChanged,
                    decoration: const InputDecoration(
                      labelText: 'Filtrer par jeu',
                      labelStyle: TextStyle(color: Colors.black87),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black87)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black87)),
                    ),
                    style: const TextStyle(color: Colors.black87),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
