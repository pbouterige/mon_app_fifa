import 'package:cloud_firestore/cloud_firestore.dart';

class PlayerStats {
  final int score;
  final double possession;
  final int tirs;
  final double expected_goals;
  final int passes_reussies;
  final double precision_passe;
  final double precision_tir;
  final double precision_dribble;
  final int tacles;
  final int tacles_reussis;
  final int interceptions;
  final int fautes;

  PlayerStats({
    required this.score,
    required this.possession,
    required this.tirs,
    required this.expected_goals,
    required this.passes_reussies,
    required this.precision_passe,
    required this.precision_tir,
    required this.precision_dribble,
    required this.tacles,
    required this.tacles_reussis,
    required this.interceptions,
    required this.fautes,
  });

  Map<String, dynamic> toMap() {
    return {
      'score': score,
      'possession': possession,
      'tirs': tirs,
      'expected_goals': expected_goals,
      'passes_reussies': passes_reussies,
      'precision_passe': precision_passe,
      'precision_tir': precision_tir,
      'precision_dribble': precision_dribble,
      'tacles': tacles,
      'tacles_reussis': tacles_reussis,
      'interceptions': interceptions,
      'fautes': fautes,
    };
  }

  factory PlayerStats.fromMap(Map<String, dynamic> map) {
    return PlayerStats(
      score: map['score'] ?? 0,
      possession: (map['possession'] ?? 0).toDouble(),
      tirs: map['tirs'] ?? 0,
      expected_goals: (map['expected_goals'] ?? 0).toDouble(),
      passes_reussies: map['passes_reussies'] ?? 0,
      precision_passe: (map['precision_passe'] ?? 0).toDouble(),
      precision_tir: (map['precision_tir'] ?? 0).toDouble(),
      precision_dribble: (map['precision_dribble'] ?? 0).toDouble(),
      tacles: map['tacles'] ?? 0,
      tacles_reussis: map['tacles_reussis'] ?? 0,
      interceptions: map['interceptions'] ?? 0,
      fautes: map['fautes'] ?? 0,
    );
  }
}

class Match {
  final String id;
  final String player1Id;
  final String? player1Id2;
  final String player2Id;
  final String? player2Id2;
  final String equipePlayer1;
  final String equipePlayer2;
  final String jeu;
  final String? photoStatsUrl;
  final PlayerStats statsPlayer1;
  final PlayerStats statsPlayer2;
  final DateTime date;

  Match({
    required this.id,
    required this.player1Id,
    this.player1Id2,
    required this.player2Id,
    this.player2Id2,
    required this.equipePlayer1,
    required this.equipePlayer2,
    required this.jeu,
    required this.statsPlayer1,
    required this.statsPlayer2,
    required this.date,
    this.photoStatsUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'player1Id': player1Id,
      'player1Id2': player1Id2,
      'player2Id': player2Id,
      'player2Id2': player2Id2,
      'equipePlayer1': equipePlayer1,
      'equipePlayer2': equipePlayer2,
      'jeu': jeu,
      'photoStatsUrl': photoStatsUrl,
      'statsPlayer1': statsPlayer1.toMap(),
      'statsPlayer2': statsPlayer2.toMap(),
      'date': Timestamp.fromDate(date),
    };
  }

  factory Match.fromMap(String id, Map<String, dynamic> map) {
    return Match(
      id: id,
      player1Id: map['player1Id'] ?? '',
      player1Id2: map['player1Id2'],
      player2Id: map['player2Id'] ?? '',
      player2Id2: map['player2Id2'],
      equipePlayer1: map['equipePlayer1'] ?? '',
      equipePlayer2: map['equipePlayer2'] ?? '',
      jeu: map['jeu'] ?? '',
      photoStatsUrl: map['photoStatsUrl'],
      statsPlayer1: PlayerStats.fromMap(Map<String, dynamic>.from(map['statsPlayer1'] ?? {})),
      statsPlayer2: PlayerStats.fromMap(Map<String, dynamic>.from(map['statsPlayer2'] ?? {})),
      date: (map['date'] as Timestamp).toDate(),
    );
  }
} 