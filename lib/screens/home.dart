// lib/screens/home.dart
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  final Color _buttonColor = Colors.teal;
  final Color _titleColor = Colors.teal;

  // Đường dẫn đến hình ảnh nền đã thêm
  final String _backgroundImagePath = 'assets/bg.jpg';

  void _navigateToGamePage(BuildContext context, String routeName) {
    Navigator.pushNamed(context, routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cờ Tổng Hợp',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: _titleColor,
        foregroundColor: Colors.white,
      ),
      // Thay vì sử dụng 'body' trực tiếp, ta dùng Stack để xếp lớp nền và nội dung
      body: Stack(
        children: <Widget>[
          // Lớp 1: Hình ảnh nền (Background Image)
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(_backgroundImagePath),
                fit: BoxFit.cover, // Đảm bảo hình ảnh phủ kín toàn bộ khu vực
              ),
            ),
          ),

          // Lớp 2: Nội dung trang chủ (Các nút trò chơi)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _buildGameButton(
                    context,
                    'Cờ Caro',
                    Icons.grid_on,
                    '/tictactoe',
                  ),
                  const SizedBox(height: 25),

                  _buildGameButton(
                    context,
                    'Cờ Lật',
                    Icons.flip_to_front,
                    '/reversi',
                  ),
                  const SizedBox(height: 25),

                  _buildGameButton(
                    context,
                    'Cờ Vua',
                    Icons.casino,
                    '/chess',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameButton(
      BuildContext context,
      String title,
      IconData icon,
      String routeName,
      ) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 28),
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18.0),
        child: Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      onPressed: () => _navigateToGamePage(context, routeName),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: _buttonColor.withOpacity(0.85), // Dùng độ trong suốt để hình nền vẫn thấy rõ
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 8,
      ),
    );
  }
}