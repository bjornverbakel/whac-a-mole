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
  int _clientIndex = -1; // Default to -1 until received from server

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
    _channel = IOWebSocketChannel.connect('ws://192.168.131.182:4000');

    _channel.stream.listen((message) {
      final gameState = jsonDecode(message);

      setState(() {
        _clientIndex = gameState['clientIndex'] ?? _clientIndex;
        _score = gameState['score'];
        _highScore = gameState['highScore'];

        // Ensure `_backgroundColors` has the correct number of elements
        _backgroundColors = List<Color>.from(
            gameState['backgroundColors'].map((color) => _colorFromString(color)));
      });
    }, onError: (error) {
      print('WebSocket error: $error');
    }, onDone: () {
      print('WebSocket connection closed');
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
    if (_clientIndex != -1 && _clientIndex < _backgroundColors.length) {
      if (_backgroundColors[_clientIndex] == Colors.green) {
        _channel.sink.add(jsonEncode({'index': _clientIndex}));
        print('👆 Button $_clientIndex tapped');
      } else {
        print('❌ Button $_clientIndex is NOT green, tap ignored.');
      }
    } else {
      print('⚠️ Invalid client index: $_clientIndex');
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
          color: (_clientIndex != -1 && _clientIndex < _backgroundColors.length)
              ? _backgroundColors[_clientIndex]
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
