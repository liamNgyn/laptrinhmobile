// lib/screens/tictactoe.dart
import 'package:flutter/material.dart';

class TicTacToePage extends StatefulWidget {
  const TicTacToePage({super.key});

  @override
  State<TicTacToePage> createState() => _TicTacToePageState();
}

class _TicTacToePageState extends State<TicTacToePage> {
  // --------------------------------------------------
  // 1. Dữ liệu Trò chơi (Game Data)
  // --------------------------------------------------

  // Mảng 9 phần tử đại diện cho 9 ô cờ (null: trống, 'X', 'O')
  late List<String?> _board;
  // Lượt đi hiện tại
  late bool _isTurnX;
  // Số lần đi đã thực hiện (để kiểm tra hòa)
  late int _moveCount;
  // Người chiến thắng (null: đang chơi, 'X', 'O', 'Draw')
  String? _winner;

  // Khởi tạo trạng thái trò chơi
  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  // Hàm thiết lập lại trò chơi
  void _initializeGame() {
    setState(() {
      _board = List.filled(9, null); // Tạo 9 ô trống
      _isTurnX = true; // 'X' đi trước
      _moveCount = 0;
      _winner = null;
    });
  }

  // --------------------------------------------------
  // 2. Logic Trò chơi (Game Logic)
  // --------------------------------------------------

  void _onCellTapped(int index) {
    // Chỉ xử lý nếu ô chưa được đánh và chưa có người thắng
    if (_board[index] == null && _winner == null) {
      setState(() {
        // Đánh dấu ô bằng 'X' hoặc 'O'
        _board[index] = _isTurnX ? 'X' : 'O';
        _moveCount++;

        // Kiểm tra chiến thắng sau khi đi
        _checkWinner();

        // Chuyển lượt
        if (_winner == null) {
          _isTurnX = !_isTurnX;
        }
      });
    }
  }

  void _checkWinner() {
    // Các trường hợp chiến thắng (8 trường hợp: 3 hàng, 3 cột, 2 đường chéo)
    final winConditions = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8], // Hàng
      [0, 3, 6], [1, 4, 7], [2, 5, 8], // Cột
      [0, 4, 8], [2, 4, 6], // Đường chéo
    ];

    for (var condition in winConditions) {
      final a = _board[condition[0]];
      final b = _board[condition[1]];
      final c = _board[condition[2]];

      // Nếu 3 ô cùng một ký tự và không phải null
      if (a != null && a == b && a == c) {
        _winner = a;
        _showWinnerDialog();
        return;
      }
    }

    // Kiểm tra Hòa
    if (_moveCount == 9 && _winner == null) {
      _winner = 'Draw';
      _showWinnerDialog();
    }
  }

  // --------------------------------------------------
  // 3. Giao diện (UI)
  // --------------------------------------------------

  // Hiển thị hộp thoại khi trò chơi kết thúc
  void _showWinnerDialog() {
    String message;
    if (_winner == 'Draw') {
      message = 'Trò chơi HÒA!';
    } else {
      message = 'Người chiến thắng là ${_winner}!';
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false, // Không cho tắt khi chạm ra ngoài
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Kết Thúc Trò Chơi'),
            content: Text(message, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            actions: <Widget>[
              TextButton(
                child: const Text('Chơi lại', style: TextStyle(fontSize: 18, color: Colors.teal)),
                onPressed: () {
                  Navigator.of(context).pop();
                  _initializeGame();
                },
              ),
            ],
          );
        },
      );
    });
  }

  // Widget hiển thị ô cờ
  Widget _buildCell(int index) {
    final symbol = _board[index];

    // Chọn màu cho 'X' (xanh lá) và 'O' (vàng cam)
    final color = symbol == 'X' ? Colors.green.shade700 : Colors.deepOrange.shade700;

    return GestureDetector(
      onTap: () => _onCellTapped(index),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400, width: 2),
          color: Colors.white,
        ),
        child: Center(
          child: Text(
            symbol ?? '',
            style: TextStyle(
              fontSize: 60,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cờ Caro', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: <Widget>[
          // --------------------------------------------------
          // 4. Khu vực Trạng thái Trò chơi
          // --------------------------------------------------
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              _winner == null
                  ? 'Lượt đi của: ${_isTurnX ? 'X' : 'O'}'
                  : _winner == 'Draw'
                  ? 'Trò chơi Hòa!'
                  : 'Chiến thắng: $_winner!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: _winner != null ? Colors.red : Colors.teal,
              ),
            ),
          ),

          // --------------------------------------------------
          // 5. Bảng cờ 3x3
          // --------------------------------------------------
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(), // Vô hiệu hóa cuộn
                itemCount: 9,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, // 3 cột
                  crossAxisSpacing: 8.0, // Khoảng cách ngang giữa các ô
                  mainAxisSpacing: 8.0, // Khoảng cách dọc giữa các ô
                ),
                itemBuilder: (BuildContext context, int index) {
                  return _buildCell(index);
                },
              ),
            ),
          ),

          // --------------------------------------------------
          // 6. Nút Chơi Lại
          // --------------------------------------------------
          Padding(
            padding: const EdgeInsets.only(bottom: 30.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Chơi Lại', style: TextStyle(fontSize: 20)),
              onPressed: _initializeGame,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}