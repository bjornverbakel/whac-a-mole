import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  runApp(const MainApp());
}

// Root
class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: WhacAMoleGame(), // Sets the home screen to the WhacAMoleGame widget
    );
  }
}

// Manages state of the Whac-a-mole game
class WhacAMoleGame extends StatefulWidget {
  const WhacAMoleGame({super.key});

  @override
  _WhacAMoleGameState createState() => _WhacAMoleGameState();
}

// _WhacAMoleGameState is the state class for the WhacAMoleGame widget
class _WhacAMoleGameState extends State<WhacAMoleGame> {
  final List<Color> _backgroundColors = [Colors.red, Colors.red, Colors.red];
  late WebSocketChannel _channel;
  int _score = 0;
  int _highScore = 0;
  int _deviceIndex = 0; // Index of the button this device controls
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _loadHighScore();
    _connectToServer();
  }

  @override
  void dispose() {
    _channel.sink.close();
    super.dispose();
  }

  void _connectToServer() {
    _channel = IOWebSocketChannel.connect('ws://192.168.1.100:4000');
    _channel.stream.listen((message) {
      final gameState = jsonDecode(message);
      setState(() {
        _backgroundColors[0] =
            _colorFromString(gameState['backgroundColors'][0]);
        _backgroundColors[1] =
            _colorFromString(gameState['backgroundColors'][1]);
        _backgroundColors[2] =
            _colorFromString(gameState['backgroundColors'][2]);
        _score = gameState['score'];
        _highScore = gameState['highScore'];
      });
      print('Game state updated: $gameState');
    });
  }

  Color _colorFromString(String colorString) {
    switch (colorString) {
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      default:
        return Colors.red;
    }
  }

  void _handleTap() {
    if (_backgroundColors[_deviceIndex] == Colors.green) {
      _channel.sink.add(jsonEncode({'index': _deviceIndex}));
      print('Button $_deviceIndex tapped');
    }
  }

  // Function to load the high score from shared preferences
  void _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _highScore = prefs.getInt('highScore') ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: _handleTap,
        child: Container(
          color: _backgroundColors[_deviceIndex],
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Score: $_score', // Display the score
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'High Score: $_highScore', // Display the high score
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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