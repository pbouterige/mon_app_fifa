import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../models/match.dart';
import '../models/player.dart';  
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddMatchScreen extends StatefulWidget {
  final Match? match;
  const AddMatchScreen({super.key, this.match});

  @override
  State<AddMatchScreen> createState() => _AddMatchScreenState();
}

class _AddMatchScreenState extends State<AddMatchScreen> {
  String? _player1Id;
  String? _player1Id2;  // Second joueur de l'équipe 1
  String? _player2Id;
  String? _player2Id2;  // Second joueur de l'équipe 2
  String? _equipePlayer1;
  String? _equipePlayer2;
  String? _jeu;
  DateTime _date = DateTime.now();
  File? _photoStats;

  // Contrôleurs pour les stats des deux joueurs
  final Map<String, TextEditingController> _controllersJ1 = {};
  final Map<String, TextEditingController> _controllersJ2 = {};
  bool _isLoading = false;

  int? _scoreJ1;
  int? _scoreJ2;

  final List<String> jeux = ['FC 22', 'FC 23', 'FC 24', 'FC 25'];
  final List<String> equipes = [
    'AC Milan',
    'Allemagne',
    'Angleterre',
    'Arsenal',
    'AS Roma',
    'Atlético Madrid',
    'Autre...',
    'Barcelone',
    'Bayer Leverkusen',
    'Bayern',
    'Belgique',
    'Borussia Dortmund',
    'Chelsea',
    'Espagne',
    'France',
    'Inter Milan',
    'Italie',
    'Juventus',
    'Liverpool',
    'Lyon',
    'Manchester City',
    'Manchester United',
    'Marseille',
    'Monaco',
    'Naples',
    'Paris SG',
    'Pays-Bas',
    'Portugal',
    'RB Leipzig',
    'Real Madrid',
    'Séville',
    'Tottenham',
    'Turquie',
    'Ukraine',
    'Valence',
    'Écosse',
  ];
  final List<String> champsStats = [
    'score',
    'possession',
    'tirs',
    'expected_goals',
    'passes_reussies', 
    'precision_passe',
    'precision_tir',
    'precision_dribble',
    'tacles',
    'tacles_reussis',
    'interceptions',
    'fautes',
  ];

  bool _isGeminiLoading = false;

  @override
  void initState() {
    super.initState();
    for (var champ in champsStats) {
      _controllersJ1[champ] = TextEditingController();
      _controllersJ2[champ] = TextEditingController();
    }
    if (widget.match != null) {
      _player1Id = widget.match!.player1Id;
      _player1Id2 = widget.match!.player1Id2;
      _player2Id = widget.match!.player2Id;
      _player2Id2 = widget.match!.player2Id2;
      _equipePlayer1 = widget.match!.equipePlayer1;
      _equipePlayer2 = widget.match!.equipePlayer2;
      _jeu = widget.match!.jeu;
      _date = widget.match!.date;
      final stats1 = widget.match!.statsPlayer1;
      final stats2 = widget.match!.statsPlayer2;
      _scoreJ1 = stats1.score;
      _scoreJ2 = stats2.score;
      _controllersJ1['score']?.text = stats1.score.toString();
      _controllersJ1['possession']?.text = stats1.possession.toString();
      _controllersJ1['tirs']?.text = stats1.tirs.toString();
      _controllersJ1['expected_goals']?.text = stats1.expected_goals.toString();
      _controllersJ1['passes_reussies']?.text = stats1.passes_reussies.toString();
      _controllersJ1['precision_passe']?.text = stats1.precision_passe.toString();
      _controllersJ1['precision_tir']?.text = stats1.precision_tir.toString();
      _controllersJ1['precision_dribble']?.text = stats1.precision_dribble.toString();
      _controllersJ1['tacles']?.text = stats1.tacles.toString();
      _controllersJ1['tacles_reussis']?.text = stats1.tacles_reussis.toString();
      _controllersJ1['interceptions']?.text = stats1.interceptions.toString();
      _controllersJ1['fautes']?.text = stats1.fautes.toString();
      _controllersJ2['score']?.text = stats2.score.toString();
      _controllersJ2['possession']?.text = stats2.possession.toString();
      _controllersJ2['tirs']?.text = stats2.tirs.toString();
      _controllersJ2['expected_goals']?.text = stats2.expected_goals.toString();
      _controllersJ2['passes_reussies']?.text = stats2.passes_reussies.toString();
      _controllersJ2['precision_passe']?.text = stats2.precision_passe.toString();
      _controllersJ2['precision_tir']?.text = stats2.precision_tir.toString();
      _controllersJ2['precision_dribble']?.text = stats2.precision_dribble.toString();
      _controllersJ2['tacles']?.text = stats2.tacles.toString();
      _controllersJ2['tacles_reussis']?.text = stats2.tacles_reussis.toString();
      _controllersJ2['interceptions']?.text = stats2.interceptions.toString();
      _controllersJ2['fautes']?.text = stats2.fautes.toString();
    }
  }

  Future<void> _pickPhoto({bool fromCamera = false}) async {
    final picked = await ImagePicker().pickImage(source: fromCamera ? ImageSource.camera : ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _photoStats = File(picked.path);
      });
    }
  }

  PlayerStats _buildStats(Map<String, TextEditingController> ctrls, bool isJ1) {
    // Les statistiques sont les mêmes pour tous les joueurs d'une même équipe
    ctrls['score']?.text = isJ1 ? (_scoreJ1?.toString() ?? '') : (_scoreJ2?.toString() ?? '');
    return PlayerStats(
      score: int.tryParse(ctrls['score']?.text ?? '0') ?? 0,
      possession: double.tryParse(ctrls['possession']?.text ?? '0') ?? 0,
      tirs: int.tryParse(ctrls['tirs']?.text ?? '0') ?? 0,
      expected_goals: double.tryParse(ctrls['expected_goals']?.text ?? '0') ?? 0,
      passes_reussies: int.tryParse(ctrls['passes_reussies']?.text ?? '0') ?? 0,
      precision_passe: double.tryParse(ctrls['precision_passe']?.text ?? '0') ?? 0,
      precision_tir: double.tryParse(ctrls['precision_tir']?.text ?? '0') ?? 0,
      precision_dribble: double.tryParse(ctrls['precision_dribble']?.text ?? '0') ?? 0,
      tacles: int.tryParse(ctrls['tacles']?.text ?? '0') ?? 0,
      tacles_reussis: int.tryParse(ctrls['tacles_reussis']?.text ?? '0') ?? 0,
      interceptions: int.tryParse(ctrls['interceptions']?.text ?? '0') ?? 0,
      fautes: int.tryParse(ctrls['fautes']?.text ?? '0') ?? 0,
    );
  }

  Future<void> _saveMatch() async {
    if (_player1Id == null || _player2Id == null || _equipePlayer1 == null || _equipePlayer2 == null || _jeu == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs obligatoires'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      // Créer les statistiques une seule fois par équipe
      final statsEquipe1 = _buildStats(_controllersJ1, true);
      final statsEquipe2 = _buildStats(_controllersJ2, false);

      final match = Match(
        id: widget.match?.id ?? '',
        player1Id: _player1Id!,
        player1Id2: _player1Id2,
        player2Id: _player2Id!,
        player2Id2: _player2Id2,
        equipePlayer1: _equipePlayer1!,
        equipePlayer2: _equipePlayer2!,
        jeu: _jeu!,
        photoStatsUrl: null,
        statsPlayer1: statsEquipe1,
        statsPlayer2: statsEquipe2,
        date: _date,
      );
      if (widget.match == null) {
        await FirebaseFirestore.instance.collection('matches').add(match.toMap());
      } else {
        await FirebaseFirestore.instance.collection('matches').doc(match.id).update(match.toMap());
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.match == null ? 'Match ajouté avec succès' : 'Match modifié avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<List<Map<String, dynamic>>?> _callGeminiAPIWithImage(File imageFile) async {
    print('[_callGeminiAPIWithImage] Début de l\'appel API.');
    final apiKey = 'demande moi';
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    final prompt = """
  Voici une capture d'écran d'un match FIFA. Peux-tu extraire pour chaque équipe les statistiques suivantes et me retourner un JSON contenant exactement ces clés (respecte l'orthographe, la casse, les underscores, et n'ajoute rien d'autre) :
  
  - equipe
  - score
  - possession
  - tirs
  - expected_goals
  - passes_reussies
  - precision_passe
  - precision_tir
  - precision_dribble
  - tacles
  - tacles_reussis
  - interceptions
  - fautes
  
  Le JSON doit être une liste de deux objets (un par équipe), chaque objet contenant exactement ces clés. N'ajoute aucun texte autour, uniquement le JSON.
  """;
    // Si vous utilisez le modèle 1.5 Flash, assurez-vous que l'URL est correcte aussi, par exemple:
    final url = Uri.parse('https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent?key=$apiKey');

    final body = jsonEncode({
      "contents": [
        {
          "parts": [
            {"text": prompt},
            {
              "inline_data": {
                "mime_type": "image/png", // Assurez-vous que c'est le bon type MIME (png ou jpeg)
                "data": base64Image,
              }
            }
          ]
        }
      ]
    });

    try {
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: body,
    );

    print('[_callGeminiAPIWithImage] Réponse API reçue.');
    print('[_callGeminiAPIWithImage] Code de statut: ${response.statusCode}');
    print('[_callGeminiAPIWithImage] Corps de la réponse brut: ${response.body}');


    if (response.statusCode == 200) {
      print('[_callGeminiAPIWithImage] Statut 200 OK, tentative de parsing JSON.');
      try {
          final data = jsonDecode(response.body);
          final text = data['candidates'][0]['content']['parts'][0]['text'];
          print('[_callGeminiAPIWithImage] Texte extrait de la réponse: "$text"');

          // --- NOUVELLE LOGIQUE DE PARSING ---

          // 1. Nettoyer le texte retourné par l'API (retirer ```json\n et ```)
          String cleanedText = text.trim(); // Retirer les espaces blancs au début/fin
          if (cleanedText.startsWith('```json')) {
            cleanedText = cleanedText.substring('```json'.length).trim();
          }
          if (cleanedText.endsWith('```')) {
            cleanedText = cleanedText.substring(0, cleanedText.length - '```'.length).trim();
          }
          print('[_callGeminiAPIWithImage] Texte nettoyé pour parsing: "$cleanedText"');

          // 2. Parser le texte nettoyé comme un objet JSON (Map)
          final List<dynamic> responseList = jsonDecode(cleanedText);
          print('[_callGeminiAPIWithImage] Parsing de la liste JSON réussi.');

          // 3. Extraire les objets statistiques de la liste
          final List<Map<String, dynamic>> resultList = [];
          for (var item in responseList) {
            if (item is Map<String, dynamic>) {
              resultList.add(item);
            } else {
              print('[_callGeminiAPIWithImage] Avertissement: Un élément de la liste n\'est pas un objet JSON.');
            }
          }

          print('[_callGeminiAPIWithImage] Extraction des objets statistiques terminée. Nombre d\'équipes trouvées: ${resultList.length}');

          // 4. Retourner la liste des objets statistiques (qui devrait en contenir 2)
          return resultList.length == 2 ? resultList : null;


          // --- FIN NOUVELLE LOGIQUE ---

        } catch (e) {
          print('[_callGeminiAPIWithImage] ERREUR lors du parsing ou traitement de la réponse: $e');
          if (context.mounted) {
            await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Erreur Traitement Réponse Gemini'),
                content: Text('Erreur: ${e.toString()}\nCorps reçu: ${response.body}'),
                actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
              ),
            );
          }
          return null;
        }
      } else {
        print('[_callGeminiAPIWithImage] Statut de réponse non 200.');
        if (context.mounted) {
            await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Erreur Gemini API'),
                content: Text('Erreur HTTP ${response.statusCode}: ${response.body}'),
                actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
              ),
            );
        }
        return null;
      }
    } catch (e) {
      print('[_callGeminiAPIWithImage] ERREUR lors de l\'appel HTTP: $e');
        if (context.mounted) {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Erreur HTTP ou Réseau'),
              content: Text('Erreur lors de l\'appel API: ${e.toString()}'),
              actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
            ),
          );
      }
      return null;
    }
  }

  Future<void> _autoFillFromGemini() async {
    setState(() => _isGeminiLoading = true);
    print('[_autoFillFromGemini] Fonction démarrée.');
    if (_photoStats == null) {
      print('[_autoFillFromGemini] _photoStats est null, sortie.');
      setState(() => _isGeminiLoading = false);
      return;
    }
    print('[_autoFillFromGemini] Appel de _callGeminiAPIWithImage avec fichier: \\${_photoStats!.path}');
    final result = await _callGeminiAPIWithImage(_photoStats!);

    print('[_autoFillFromGemini] Résultat de l\'API Gemini: $result');

    if (result != null && result.length == 2) {
      print('[_autoFillFromGemini] Résultat API non null et contient 2 éléments.');
      // J1 = équipe de gauche, J2 = équipe de droite
      final j1 = result[0];
      final j2 = result[1];

      print('[_autoFillFromGemini] Données J1: $j1');
      print('[_autoFillFromGemini] Données J2: $j2');

      // Champs principaux
      _equipePlayer1 = j1['equipe']?.toString();
      _equipePlayer2 = j2['equipe']?.toString();

      // Vérifier si les équipes extraites sont dans la liste des équipes disponibles
      if (_equipePlayer1 != null) {
        final match = equipes.firstWhere(
          (equipe) => equipe.toLowerCase() == _equipePlayer1!.toLowerCase(),
          orElse: () => equipes.first,
        );
        _equipePlayer1 = match;
      }

      if (_equipePlayer2 != null) {
        final match = equipes.firstWhere(
          (equipe) => equipe.toLowerCase() == _equipePlayer2!.toLowerCase(),
          orElse: () => equipes.first,
        );
        _equipePlayer2 = match;
      }

      _scoreJ1 = int.tryParse(j1['score'].toString());
      _scoreJ2 = int.tryParse(j2['score'].toString());

      print('[_autoFillFromGemini] Équipe J1 extraite: $_equipePlayer1');
      print('[_autoFillFromGemini] Équipe J2 extraite: $_equipePlayer2');
      print('[_autoFillFromGemini] Score J1 extrait: $_scoreJ1');
      print('[_autoFillFromGemini] Score J2 extrait: $_scoreJ2');

      print('[_autoFillFromGemini] Liste des clés de _controllersJ1:');
      _controllersJ1.keys.forEach((key) {
        print('  - $key');
      });

      // Champs stats
      final List<String> champsStats = [
        'possession',
        'tirs',
        'expected_goals',
        'passes_reussies',
        'precision_passe',
        'precision_tir',
        'precision_dribble',
        'tacles',
        'tacles_reussis',
        'interceptions',
        'fautes',
      ];

      print('[_autoFillFromGemini] Début de l\'application des stats aux contrôleurs.');
      for (var champ in champsStats) {
        final valueJ1 = j1[champ]?.toString() ?? '';
        final valueJ2 = j2[champ]?.toString() ?? '';

        print('[_autoFillFromGemini] Traitement du champ "${champ}"');
        print('[_autoFillFromGemini]   Valeur J1: "$valueJ1"');
        print('[_autoFillFromGemini]   Valeur J2: "$valueJ2"');

        if (_controllersJ1.containsKey(champ)) {
          _controllersJ1[champ]!.text = valueJ1;
        } else {
          print('[_autoFillFromGemini] ERREUR: Clé de contrôleur J1 "${champ}" non trouvée dans _controllersJ1.');
        }
        if (_controllersJ2.containsKey(champ)) {
          _controllersJ2[champ]!.text = valueJ2;
        } else {
          print('[_autoFillFromGemini] ERREUR: Clé de contrôleur J2 "${champ}" non trouvée dans _controllersJ2.');
        }
      }
      print('[_autoFillFromGemini] Fin de l\'application des stats aux contrôleurs.');

      setState(() {});
      print('[_autoFillFromGemini] setState appelé.');

    } else {
      print('[_autoFillFromGemini] Résultat API est null OU sa longueur n\'est pas 2. Résultat: $result');
      // La pop-up d'erreur est gérée dans _callGeminiAPIWithImage si le statut n'est pas 200
      // Si result est null ici, c'est que _callGeminiAPIWithImage a retourné null (probablement après avoir affiché une erreur)
    }
    setState(() => _isGeminiLoading = false);
    print('[_autoFillFromGemini] Fonction terminée.');
  }

  Widget _buildStatsSection(String title, Map<String, TextEditingController> ctrls, {bool hideScore = false}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Wrap(
              runSpacing: 8,
              spacing: 8,
              children: champsStats.where((champ) => hideScore ? !(champ == 'score' || champ == 'scoreAdverse') : true).map((champ) {
                return SizedBox(
                  width: 140,
                  child: TextField(
                    controller: ctrls[champ],
                    decoration: InputDecoration(
                      labelText: champ,
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: champ.contains('precision') || champ == 'possession' || champ == 'expectedGoals'
                        ? TextInputType.numberWithOptions(decimal: true)
                        : TextInputType.number,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (var c in _controllersJ1.values) {
      c.dispose();
    }
    for (var c in _controllersJ2.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.match == null ? 'Ajouter un match' : 'Modifier le match'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Boutons photo tout en haut
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _pickPhoto(fromCamera: true),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Prendre une photo'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _pickPhoto(fromCamera: false),
                    icon: const Icon(Icons.photo),
                    label: const Text('Charger'),
                  ),
                ],
              ),
              if (_photoStats != null) ...[
                const SizedBox(height: 12),
                Center(
                  child: SizedBox(
                    width: 120,
                    height: 120,
                    child: Image.file(_photoStats!),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: _isGeminiLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton.icon(
                          onPressed: _autoFillFromGemini,
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text('Analyse IA (Gemini)'),
                        ),
                ),
              ],
              const SizedBox(height: 16),
              // Champ score global
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 64,
                    child: TextField(
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: (_scoreJ1 == null || _scoreJ1.toString().isEmpty) ? 'Score E1' : null,
                        labelStyle: const TextStyle(fontSize: 18),
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => setState(() => _scoreJ1 = int.tryParse(v)),
                      controller: TextEditingController(text: _scoreJ1?.toString() ?? '')
                        ..selection = TextSelection.collapsed(offset: (_scoreJ1?.toString() ?? '').length),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('-', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 120,
                    height: 64,
                    child: TextField(
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: (_scoreJ2 == null || _scoreJ2.toString().isEmpty) ? 'Score E2' : null,
                        labelStyle: const TextStyle(fontSize: 18),
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => setState(() => _scoreJ2 = int.tryParse(v)),
                      controller: TextEditingController(text: _scoreJ2?.toString() ?? '')
                        ..selection = TextSelection.collapsed(offset: (_scoreJ2?.toString() ?? '').length),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Section infos générales
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('players').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Text('Une erreur est survenue');
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }

                  final players = snapshot.data!.docs
                      .map((doc) => Player.fromMap(doc.id, doc.data() as Map<String, dynamic>))
                      .toList();

                  return Column(
                    children: [
                      // Équipe 1
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Équipe 1', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                                value: _player1Id,
                                decoration: const InputDecoration(
                                  labelText: 'Joueur 1 *',
                                  border: OutlineInputBorder(),
                        ),
                        items: players.map((player) {
                          return DropdownMenuItem(
                            value: player.id,
                            child: Text(player.name),
                          );
                        }).toList(),
                                onChanged: (value) => setState(() => _player1Id = value),
                      ),
                              const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                                value: _player1Id2,
                                decoration: const InputDecoration(
                                  labelText: 'Joueur 2 (optionnel)',
                                  border: OutlineInputBorder(),
                        ),
                                items: [
                                  const DropdownMenuItem(
                                    value: null,
                                    child: Text('Aucun'),
                                  ),
                                  ...players.map((player) {
                          return DropdownMenuItem(
                            value: player.id,
                            child: Text(player.name),
                          );
                        }).toList(),
                                ],
                                onChanged: (value) => setState(() => _player1Id2 = value),
                      ),
                              const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                                value: _equipePlayer1,
                                decoration: const InputDecoration(
                                  labelText: 'Équipe *',
                                  border: OutlineInputBorder(),
                        ),
                        items: equipes.map((equipe) {
                          return DropdownMenuItem(
                            value: equipe,
                            child: Text(equipe),
                          );
                        }).toList(),
                                onChanged: (value) => setState(() => _equipePlayer1 = value),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Équipe 2
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Équipe 2', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _player2Id,
                                decoration: const InputDecoration(
                                  labelText: 'Joueur 1 *',
                                  border: OutlineInputBorder(),
                                ),
                                items: players.map((player) {
                                  return DropdownMenuItem(
                                    value: player.id,
                                    child: Text(player.name),
                                  );
                                }).toList(),
                                onChanged: (value) => setState(() => _player2Id = value),
                              ),
                              const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                                value: _player2Id2,
                                decoration: const InputDecoration(
                                  labelText: 'Joueur 2 (optionnel)',
                                  border: OutlineInputBorder(),
                                ),
                                items: [
                                  const DropdownMenuItem(
                                    value: null,
                                    child: Text('Aucun'),
                                  ),
                                  ...players.map((player) {
                                    return DropdownMenuItem(
                                      value: player.id,
                                      child: Text(player.name),
                                    );
                                  }).toList(),
                                ],
                                onChanged: (value) => setState(() => _player2Id2 = value),
                        ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                        value: _equipePlayer2,
                                decoration: const InputDecoration(
                                  labelText: 'Équipe *',
                                  border: OutlineInputBorder(),
                                ),
                        items: equipes.map((equipe) {
                          return DropdownMenuItem(
                            value: equipe,
                            child: Text(equipe),
                          );
                        }).toList(),
                                onChanged: (value) => setState(() => _equipePlayer2 = value),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: _jeu == null ? 'Jeu' : null,
                          border: const OutlineInputBorder(),
                        ),
                        value: _jeu,
                        items: jeux.map((jeu) {
                          return DropdownMenuItem(
                            value: jeu,
                            child: Text(jeu),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _jeu = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Date : ${_date.day}/${_date.month}/${_date.year}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.calendar_today,
                              color: Colors.white,
                            ),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _date,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() => _date = picked);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildStatsSection('Statistiques Equipe 1', _controllersJ1, hideScore: true),
              _buildStatsSection('Statistiques Equipe 2', _controllersJ2, hideScore: true),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveMatch,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(widget.match == null ? 'Ajouter le match' : 'Modifier le match'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 
