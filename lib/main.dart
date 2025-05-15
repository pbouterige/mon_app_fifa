import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'screens/add_player_screen.dart';
import 'screens/players_list_screen.dart';
import 'screens/match_list_screen.dart';
import 'screens/stats_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EA FC Match Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme(
          brightness: Brightness.light,
          primary: const Color(0xFF1B5E20), // vert foncé pelouse
          onPrimary: Colors.white,
          secondary: const Color(0xFF1565C0), // bleu FIFA
          onSecondary: Colors.white,
          error: Colors.red,
          onError: Colors.white,
          background: const Color(0xFF0D1B2A), // bleu nuit
          onBackground: Colors.white,
          surface: Colors.white,
          onSurface: Colors.black,
        ),
        scaffoldBackgroundColor: const Color(0xFF0D1B2A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1565C0),
          foregroundColor: Colors.white,
          elevation: 4,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        cardTheme: CardTheme(
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 6,
          shadowColor: Colors.black.withOpacity(0.08),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1B5E20),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: GoogleFonts.bebasNeue(fontSize: 20, letterSpacing: 1.2),
            elevation: 3,
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFFFD700), // doré
          foregroundColor: Colors.black,
        ),
        textTheme: GoogleFonts.bebasNeueTextTheme().copyWith(
          bodyLarge: GoogleFonts.bebasNeue(color: Colors.black, fontSize: 20),
          bodyMedium: GoogleFonts.bebasNeue(color: Colors.black, fontSize: 18),
          bodySmall: GoogleFonts.bebasNeue(color: Colors.black, fontSize: 16),
          titleLarge: GoogleFonts.bebasNeue(color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold),
          titleMedium: GoogleFonts.bebasNeue(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
          titleSmall: GoogleFonts.bebasNeue(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
          labelLarge: GoogleFonts.bebasNeue(color: Colors.black, fontSize: 18),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          labelStyle: const TextStyle(color: Color(0xFF1565C0)),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static final List<String> funMessages = [
    "salut les footix\n ça va se la mettre",
    "svp dites pas c'est moche",
    "on sait tous que\nArthur va prendre le psg",
    "on sait tous que\nAntoine va prendre le Real",
    "Le meilleur 9 de\n l'histoire c'est qui?",
    "on va interdire\nle cheat code Antoine",
    "combien de joueurs Audrey\nsera-t-elle capable de citer ?",
    "on sait tous que\npierre sera dernier",
    "je te vois redémarrer\nl'appli pour les messages",
    "valentin va nous\nla mettre en rentrant",
    "en vrai c'est l'IA qui a\ntout codé pas moi"
  ];

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _msgIndex = 0;
  static const double _shakeThreshold = 35.0;
  DateTime? _lastShakeTime;

  void _nextMessage() {
    setState(() {
      _msgIndex = (_msgIndex + 1) % HomePage.funMessages.length;
    });
  }

  @override
  void initState() {
    super.initState();
    _msgIndex = (DateTime.now().millisecondsSinceEpoch % HomePage.funMessages.length);
    _setupShakeDetection();
  }

  void _setupShakeDetection() {
    accelerometerEvents.listen((AccelerometerEvent event) {
      final double acceleration = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      final DateTime now = DateTime.now();
      
      if (acceleration > _shakeThreshold) {
        if (_lastShakeTime == null || now.difference(_lastShakeTime!).inMilliseconds > 5000) {
          _lastShakeTime = now;
          _nextMessage();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final String funText = HomePage.funMessages[_msgIndex];
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sports_soccer, color: Color(0xFFFFD700)),
            const SizedBox(width: 8),
            Text('EA FC Match Tracker', style: GoogleFonts.bebasNeue(fontSize: 26, color: Colors.white)),
          ],
        ),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1565C0), Color(0xFF1B5E20)],
          ),
        ),
        child: Stack(
          children: [
            SizedBox.expand(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    funText,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.bebasNeue(fontSize: 28, color: Colors.white, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: 220,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PlayersListScreen()),
                        );
                      },
                      icon: const Icon(Icons.people, color: Color(0xFFFFD700)),
                      label: const Text('Joueurs'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 220,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const MatchListScreen()),
                        );
                      },
                      icon: const Icon(Icons.sports_soccer, color: Color(0xFFFFD700)),
                      label: const Text('Matchs'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 220,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const StatsScreen()),
                        );
                      },
                      icon: const Icon(Icons.bar_chart, color: Color(0xFFFFD700)),
                      label: const Text('Statistiques'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
