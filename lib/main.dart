// lib/main.dart
import 'package:flutter/material.dart';
import 'screens/home.dart';
import 'screens/tictactoe.dart';
import 'screens/reversi.dart';
import 'screens/chess.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cờ Tổng Hợp',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      // Định tuyến (Routes) để dễ dàng điều hướng giữa các màn hình
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/tictactoe': (context) => const TicTacToePage(),
        '/reversi': (context) => const ReversiPage(),
        '/chess': (context) => const ChessPage(),
      },
    );
  }
}