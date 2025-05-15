import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/player.dart';
import '../models/match.dart';
import 'stats_screen.dart';

class PlayerStatsScreen extends StatefulWidget {
  final Player player;
  const PlayerStatsScreen({super.key, required this.player});

  @override
  State<PlayerStatsScreen> createState() => _PlayerStatsScreenState();
}

class _PlayerStatsScreenState extends State<PlayerStatsScreen> {
  String? _matchType = 'all'; // 'all', 'face-a-face', '2v1', '2v2'
  String? _selectedTeam;
  String? _selectedGameMode;
  Set<String> _teams = {};
  Set<String> _gameModes = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Stats de ${widget.player.name}'),
      ),
      body: Column(
        children: [
          FutureBuilder<List<Match>>(
            future: _fetchPlayerMatches(widget.player.id),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final matches = snapshot.data!;
                _teams = {};
                _gameModes = {};
                for (final match in matches) {
                  if (match.player1Id == widget.player.id || match.player1Id2 == widget.player.id) {
                    _teams.add(match.equipePlayer1);
                  }
                  if (match.player2Id == widget.player.id || match.player2Id2 == widget.player.id) {
                    _teams.add(match.equipePlayer2);
                  }
                  if (match.jeu.isNotEmpty) {
                    _gameModes.add(match.jeu);
                  }
                }
              }
              return PlayerStatsFilter(
                key: const ValueKey('player_stats_filter'),
                matchType: _matchType,
                onMatchTypeChanged: (value) => setState(() => _matchType = value),
                selectedTeam: _selectedTeam,
                onTeamChanged: (value) => setState(() => _selectedTeam = value),
                selectedGameMode: _selectedGameMode,
                onGameModeChanged: (value) => setState(() => _selectedGameMode = value),
                teams: _teams.toList(),
                gameModes: _gameModes.toList(),
              );
            },
          ),
          Expanded(
            child: FutureBuilder<List<Match>>(
              future: _fetchPlayerMatches(widget.player.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Erreur: ${snapshot.error}'));
                }
                var matches = snapshot.data!;
                
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

                if (_selectedTeam != null) {
                  matches = matches.where((m) {
                    final isInTeam1 = m.player1Id == widget.player.id || m.player1Id2 == widget.player.id;
                    return isInTeam1 ? m.equipePlayer1 == _selectedTeam : m.equipePlayer2 == _selectedTeam;
                  }).toList();
                }

                if (_selectedGameMode != null) {
                  matches = matches.where((m) => m.jeu == _selectedGameMode).toList();
                }

                if (matches.isEmpty) {
                  return const Center(child: Text('Aucun match trouvé pour ce joueur.', style: TextStyle(color: Colors.white)));
                }

                final stats = _PlayerAggregatedStats(widget.player);
                final Map<String, int> equipes = {};
                for (final match in matches) {
                  final isInTeam1 = match.player1Id == widget.player.id || match.player1Id2 == widget.player.id;
                  if (isInTeam1) {
                    stats.addMatch(match.statsPlayer1, match.statsPlayer2);
                    equipes[match.equipePlayer1] = (equipes[match.equipePlayer1] ?? 0) + 1;
                  } else {
                    stats.addMatch(match.statsPlayer2, match.statsPlayer1);
                    equipes[match.equipePlayer2] = (equipes[match.equipePlayer2] ?? 0) + 1;
                  }
                }
                final List<_ClassementConfig> classements = [
                  _ClassementConfig(
                    titre: 'Nombre de matches',
                    getValue: (s) => s.nbMatches.toDouble(),
                    format: (v) => v.toStringAsFixed(0),
                  ),
                  _ClassementConfig(
                    titre: 'Pourcentage de victoire',
                    getValue: (s) => s.nbMatches > 0 ? (s.nbVictoires / s.nbMatches * 100) : 0,
                    format: (v) => '${v.toStringAsFixed(1)} %',
                  ),
                  _ClassementConfig(
                    titre: 'Buts marqués / match',
                    getValue: (s) => s.nbMatches > 0 ? (s.butsMarques / s.nbMatches) : 0,
                    format: (v) => v.toStringAsFixed(2),
                  ),
                  _ClassementConfig(
                    titre: 'Buts encaissés / match',
                    getValue: (s) => s.nbMatches > 0 ? (s.butsEncaisses / s.nbMatches) : 0,
                    format: (v) => v.toStringAsFixed(2),
                  ),
                  _ClassementConfig(
                    titre: 'Buts marqués (total)',
                    getValue: (s) => s.butsMarques.toDouble(),
                    format: (v) => v.toStringAsFixed(0),
                  ),
                  _ClassementConfig(
                    titre: 'Buts encaissés (total)',
                    getValue: (s) => s.butsEncaisses.toDouble(),
                    format: (v) => v.toStringAsFixed(0),
                  ),
                  _ClassementConfig(
                    titre: 'Possession moyenne',
                    getValue: (s) => s.nbMatches > 0 ? (s.possession / s.nbMatches) : 0,
                    format: (v) => '${v.toStringAsFixed(1)} %',
                  ),
                  _ClassementConfig(
                    titre: 'Tirs / match',
                    getValue: (s) => s.nbMatches > 0 ? (s.tirs / s.nbMatches) : 0,
                    format: (v) => v.toStringAsFixed(2),
                  ),
                  _ClassementConfig(
                    titre: 'Expected goals / match',
                    getValue: (s) => s.nbMatches > 0 ? (s.expectedGoals / s.nbMatches) : 0,
                    format: (v) => v.toStringAsFixed(2),
                  ),
                  _ClassementConfig(
                    titre: 'Passes réussies / match',
                    getValue: (s) => s.nbMatches > 0 ? (s.passesReussies / s.nbMatches) : 0,
                    format: (v) => v.toStringAsFixed(2),
                  ),
                  _ClassementConfig(
                    titre: 'Précision passe moyenne',
                    getValue: (s) => s.nbMatches > 0 ? (s.precisionPasse / s.nbMatches) : 0,
                    format: (v) => '${v.toStringAsFixed(1)} %',
                  ),
                  _ClassementConfig(
                    titre: 'Précision tir moyenne',
                    getValue: (s) => s.nbMatches > 0 ? (s.precisionTir / s.nbMatches) : 0,
                    format: (v) => '${v.toStringAsFixed(1)} %',
                  ),
                  _ClassementConfig(
                    titre: 'Précision dribble moyenne',
                    getValue: (s) => s.nbMatches > 0 ? (s.precisionDribble / s.nbMatches) : 0,
                    format: (v) => '${v.toStringAsFixed(1)} %',
                  ),
                  _ClassementConfig(
                    titre: 'Tacles / match',
                    getValue: (s) => s.nbMatches > 0 ? (s.tacles / s.nbMatches) : 0,
                    format: (v) => v.toStringAsFixed(2),
                  ),
                  _ClassementConfig(
                    titre: 'Tacles réussis / match',
                    getValue: (s) => s.nbMatches > 0 ? (s.taclesReussis / s.nbMatches) : 0,
                    format: (v) => v.toStringAsFixed(2),
                  ),
                  _ClassementConfig(
                    titre: 'Interceptions / match',
                    getValue: (s) => s.nbMatches > 0 ? (s.interceptions / s.nbMatches) : 0,
                    format: (v) => v.toStringAsFixed(2),
                  ),
                  _ClassementConfig(
                    titre: 'Fautes / match',
                    getValue: (s) => s.nbMatches > 0 ? (s.fautes / s.nbMatches) : 0,
                    format: (v) => v.toStringAsFixed(2),
                  ),
                ];
                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  children: [
                    for (final classement in classements)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 200,
                              child: Text(classement.titre, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Roboto', fontSize: 14)),
                            ),
                            Expanded(
                              child: Text(classement.format(classement.getValue(stats)), textAlign: TextAlign.right, style: const TextStyle(color: Colors.white, fontFamily: 'Roboto', fontSize: 14)),
                            ),
                          ],
                        ),
                      ),
                    const Divider(height: 32, color: Colors.white),
                    Row(
                      children: [
                        const SizedBox(
                          width: 200,
                          child: Text('Équipe la plus jouée', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Roboto', fontSize: 14)),
                        ),
                        Expanded(
                          child: Text(_getMostPlayedTeam(equipes), textAlign: TextAlign.right, style: const TextStyle(color: Colors.white, fontFamily: 'Roboto', fontSize: 14)),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<List<Match>> _fetchPlayerMatches(String playerId) async {
    final snap = await FirebaseFirestore.instance.collection('matches').get();
    return snap.docs
        .map((doc) => Match.fromMap(doc.id, doc.data()))
        .where((m) => m.player1Id == playerId || m.player1Id2 == playerId || m.player2Id == playerId || m.player2Id2 == playerId)
        .toList();
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
    butsMarques += stats.score ?? 0;
    butsEncaisses += statsAdverse.score ?? 0;
    if ((stats.score ?? 0) > (statsAdverse.score ?? 0)) nbVictoires++;
    possession += stats.possession ?? 0;
    tirs += stats.tirs ?? 0;
    expectedGoals += stats.expected_goals ?? 0;
    passesReussies += stats.passes_reussies ?? 0;
    precisionPasse += stats.precision_passe ?? 0;
    precisionTir += stats.precision_tir ?? 0;
    precisionDribble += stats.precision_dribble ?? 0;
    tacles += stats.tacles ?? 0;
    taclesReussis += stats.tacles_reussis ?? 0;
    interceptions += stats.interceptions ?? 0;
    fautes += stats.fautes ?? 0;
  }
}

class _ClassementConfig {
  final String titre;
  final double Function(_PlayerAggregatedStats) getValue;
  final String Function(double) format;
  _ClassementConfig({required this.titre, required this.getValue, required this.format});
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

class PlayerStatsFilter extends StatefulWidget {
  final String? matchType;
  final Function(String?) onMatchTypeChanged;
  final String? selectedTeam;
  final Function(String?) onTeamChanged;
  final List<String> teams;
  final String? selectedGameMode;
  final Function(String?) onGameModeChanged;
  final List<String> gameModes;

  const PlayerStatsFilter({
    super.key,
    required this.matchType,
    required this.onMatchTypeChanged,
    this.selectedTeam,
    required this.onTeamChanged,
    required this.teams,
    this.selectedGameMode,
    required this.onGameModeChanged,
    required this.gameModes,
  });

  @override
  State<PlayerStatsFilter> createState() => _PlayerStatsFilterState();
}

class _PlayerStatsFilterState extends State<PlayerStatsFilter> {
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
                      DropdownMenuItem<String>(
                        value: 'all',
                        child: Text('Tout type de match', style: TextStyle(color: Colors.black87)),
                      ),
                      DropdownMenuItem<String>(
                        value: 'face-a-face',
                        child: Text('Face-à-face', style: TextStyle(color: Colors.black87)),
                      ),
                      DropdownMenuItem<String>(
                        value: '2v1',
                        child: Text('Deux contre un', style: TextStyle(color: Colors.black87)),
                      ),
                      DropdownMenuItem<String>(
                        value: '2v2',
                        child: Text('Deux contre deux', style: TextStyle(color: Colors.black87)),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        widget.onMatchTypeChanged(value);
                      }
                    },
                    style: const TextStyle(color: Colors.black87),
                    decoration: const InputDecoration(
                      labelText: 'Type de match',
                      labelStyle: TextStyle(color: Colors.black87),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black87),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black87),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: widget.selectedTeam,
                    hint: const Text('Toutes les équipes', style: TextStyle(color: Colors.black87)),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Toutes les équipes', style: TextStyle(color: Colors.black87)),
                      ),
                      ...widget.teams.map((team) => DropdownMenuItem<String>(
                        value: team,
                        child: Text(team, style: const TextStyle(color: Colors.black87)),
                      )),
                    ],
                    onChanged: widget.onTeamChanged,
                    style: const TextStyle(color: Colors.black87),
                    decoration: const InputDecoration(
                      labelText: 'Filtrer par équipe',
                      labelStyle: TextStyle(color: Colors.black87),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black87),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black87),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: widget.selectedGameMode,
                    hint: const Text('Tous les jeux', style: TextStyle(color: Colors.black87)),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Tous les jeux', style: TextStyle(color: Colors.black87)),
                      ),
                      ...widget.gameModes.map((mode) => DropdownMenuItem<String>(
                        value: mode,
                        child: Text(mode, style: const TextStyle(color: Colors.black87)),
                      )),
                    ],
                    onChanged: widget.onGameModeChanged,
                    style: const TextStyle(color: Colors.black87),
                    decoration: const InputDecoration(
                      labelText: 'Filtrer par jeu',
                      labelStyle: TextStyle(color: Colors.black87),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black87),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black87),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
} 