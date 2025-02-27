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
      home: WhacAMoleGame(), // Sets home screen to the WhacAMoleGame widget
    );
  }
}

class WhacAMoleGame extends StatefulWidget {
  const WhacAMoleGame({super.key});

  @override
  _WhacAMoleGameState createState() => _WhacAMoleGameState();
}

// _WhacAMoleGameState is the state class for the WhacAMoleGame widget
class _WhacAMoleGameState extends State<WhacAMoleGame> {
  List<Color> _backgroundColors = [];
  late WebSocketChannel _channel;
  int _score = 0;
  int _highScore = 0;
  int _clientIndex = 1; // Start client index from 1

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
    print('Attempting to connect to WebSocket server...');
    _channel = IOWebSocketChannel.connect('ws://localhost:4000');
    _channel.stream.listen((message) {
      final gameState = jsonDecode(message);
      setState(() {
        _backgroundColors.clear();
        _backgroundColors.addAll(
            List<Color>.from(gameState['backgroundColors'].map((color) => _colorFromString(color))));
        _score = gameState['score'];
        _highScore = gameState['highScore'];
        _clientIndex = gameState['clientIndex'] ?? _clientIndex;
      });
      print('Game state updated: $gameState');
    }, onError: (error) {
      print('WebSocket error: $error');
    }, onDone: () {
      print('WebSocket connection closed');
    });
  }

  // Convert string to color
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

  // Handle tap event
  void _handleTap() {
    if (_clientIndex != -1 && _clientIndex <= _backgroundColors.length) {
      // Check if the button is green
      if (_backgroundColors[_clientIndex - 1] == Colors.green) { // Adjust index to match array position
        _channel.sink.add(jsonEncode({'index': _clientIndex}));
        print('Button $_clientIndex tapped');
      }
    } else {
      print('Invalid client index: $_clientIndex');
    }
  }

  // Load the high score from shared preferences
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
          color:
              (_clientIndex != -1 && _clientIndex <= _backgroundColors.length)
                  ? _backgroundColors[_clientIndex - 1] // Adjust index to match array position
                  : Colors.red, // Fallback to red if something is wrong
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Score: $_score', // Display the score
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'High Score: $_highScore', // Display the high score
                  style: const TextStyle(
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
