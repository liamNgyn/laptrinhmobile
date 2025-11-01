// lib/screens/reversi.dart
import 'package:flutter/material.dart';
import 'dart:math';

class ReversiPage extends StatefulWidget {
  const ReversiPage({super.key});

  @override
  State<ReversiPage> createState() => _ReversiPageState();
}

class _ReversiPageState extends State<ReversiPage> {
  // --------------------------------------------------
  // 1. Dữ liệu Trò chơi (Game Data)
  // --------------------------------------------------

  // Kích thước bàn cờ
  static const int boardSize = 8;
  // Bảng cờ: 0 = Trống, 1 = Đen, 2 = Trắng
  late List<List<int>> _board;
  // Lượt đi hiện tại: 1 = Đen, 2 = Trắng
  late int _currentPlayer;
  // Điểm số (index 1 cho Đen, index 2 cho Trắng)
  late List<int> _scores;
  // Các vị trí có thể đi được
  late List<Point> _validMoves;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  // Hàm khởi tạo/thiết lập lại trò chơi
  void _initializeGame() {
    setState(() {
      // Khởi tạo bảng 8x8 với giá trị 0 (trống)
      _board = List.generate(boardSize, (_) => List.filled(boardSize, 0));

      // Thiết lập 4 quân cờ ban đầu
      _board[3][3] = 2; // Trắng
      _board[3][4] = 1; // Đen
      _board[4][3] = 1; // Đen
      _board[4][4] = 2; // Trắng

      _currentPlayer = 1; // Đen đi trước
      _updateScores();
      _validMoves = _getValidMoves(_currentPlayer);
    });
  }

  // Cập nhật điểm số dựa trên số lượng quân trên bàn cờ
  void _updateScores() {
    int black = 0;
    int white = 0;
    for (int r = 0; r < boardSize; r++) {
      for (int c = 0; c < boardSize; c++) {
        if (_board[r][c] == 1) black++;
        if (_board[r][c] == 2) white++;
      }
    }
    _scores = [0, black, white];
  }

  // --------------------------------------------------
  // 2. Logic Trò chơi (Game Logic)
  // --------------------------------------------------

  // Hàm kiểm tra và thực hiện lật quân
  bool _makeMove(int r, int c) {
    // 1. Kiểm tra xem ô có hợp lệ không (trong danh sách _validMoves)
    final move = Point(r, c);
    if (!_validMoves.contains(move)) {
      return false; // Lượt đi không hợp lệ
    }

    // 2. Tìm các quân cần lật
    List<Point> flippedStones = [];
    final opponent = _currentPlayer == 1 ? 2 : 1;

    // 8 hướng di chuyển: (dr, dc)
    const directions = [
      [-1, 0], [1, 0], [0, -1], [0, 1], // Ngang, Dọc
      [-1, -1], [-1, 1], [1, -1], [1, 1] // Chéo
    ];

    for (var dir in directions) {
      final dr = dir[0];
      final dc = dir[1];
      List<Point> currentLine = [];
      int nr = r + dr;
      int nc = c + dc;

      // Duyệt theo hướng cho đến khi ra ngoài hoặc gặp quân cùng màu/ô trống
      while (nr >= 0 && nr < boardSize && nc >= 0 && nc < boardSize && _board[nr][nc] == opponent) {
        currentLine.add(Point(nr, nc));
        nr += dr;
        nc += dc;
      }

      // Nếu điểm dừng là một quân cùng màu VÀ có ít nhất 1 quân đối thủ bị kẹp
      if (nr >= 0 && nr < boardSize && nc >= 0 && nc < boardSize && _board[nr][nc] == _currentPlayer) {
        flippedStones.addAll(currentLine);
      }
    }

    // 3. Nếu không có quân nào bị lật, thì đây không phải là nước đi hợp lệ
    if (flippedStones.isEmpty) {
      return false;
    }

    // 4. Thực hiện đi và lật quân
    setState(() {
      _board[r][c] = _currentPlayer;
      for (var stone in flippedStones) {
        _board[stone.x.toInt()][stone.y.toInt()] = _currentPlayer;
      }

      // 5. Cập nhật điểm số
      _updateScores();

      // 6. Chuyển lượt và kiểm tra trạng thái game
      _nextTurn();
    });

    return true;
  }

  // Lấy tất cả các nước đi hợp lệ cho người chơi hiện tại
  List<Point> _getValidMoves(int player) {
    List<Point> moves = [];
    final opponent = player == 1 ? 2 : 1;

    // Duyệt qua toàn bộ bàn cờ
    for (int r = 0; r < boardSize; r++) {
      for (int c = 0; c < boardSize; c++) {
        // Chỉ kiểm tra ô trống
        if (_board[r][c] == 0) {

          // Kiểm tra xem có quân nào bị lật nếu đặt quân ở (r, c)
          if (_canFlipAnyStone(r, c, player, opponent)) {
            moves.add(Point(r, c));
          }
        }
      }
    }
    return moves;
  }

  // Hàm phụ trợ để kiểm tra khả năng lật quân tại (r, c)
  bool _canFlipAnyStone(int r, int c, int player, int opponent) {
    const directions = [
      [-1, 0], [1, 0], [0, -1], [0, 1],
      [-1, -1], [-1, 1], [1, -1], [1, 1]
    ];

    for (var dir in directions) {
      final dr = dir[0];
      final dc = dir[1];
      int nr = r + dr;
      int nc = c + dc;
      int count = 0;

      // 1. Phải có ít nhất 1 quân đối thủ liền kề
      if (nr >= 0 && nr < boardSize && nc >= 0 && nc < boardSize && _board[nr][nc] == opponent) {
        count++;
        nr += dr;
        nc += dc;

        // 2. Tiếp tục đi cho đến khi gặp quân cùng màu hoặc hết bảng
        while (nr >= 0 && nr < boardSize && nc >= 0 && nc < boardSize && _board[nr][nc] == opponent) {
          count++;
          nr += dr;
          nc += dc;
        }

        // 3. Phải dừng lại ở quân cùng màu (sau ít nhất 1 quân đối thủ)
        if (nr >= 0 && nr < boardSize && nc >= 0 && nc < boardSize && _board[nr][nc] == player) {
          return true;
        }
      }
    }
    return false;
  }


  // Chuyển lượt và kiểm tra kết thúc trò chơi
  void _nextTurn() {
    _currentPlayer = _currentPlayer == 1 ? 2 : 1;
    _validMoves = _getValidMoves(_currentPlayer);

    // Nếu người chơi hiện tại không thể đi, chuyển sang người chơi kia
    if (_validMoves.isEmpty) {
      int otherPlayer = _currentPlayer == 1 ? 2 : 1;
      List<Point> otherValidMoves = _getValidMoves(otherPlayer);

      if (otherValidMoves.isNotEmpty) {
        // Người chơi kia có thể đi, chuyển lượt lại
        _currentPlayer = otherPlayer;
        _validMoves = otherValidMoves;
        _showPassDialog(_currentPlayer == 1 ? 'Đen' : 'Trắng');
      } else {
        // Cả hai đều không thể đi, trò chơi kết thúc
        _checkGameOver();
      }
    }
  }

  // Kiểm tra kết thúc trò chơi (bảng đầy hoặc không ai đi được)
  void _checkGameOver() {
    _updateScores();
    String winner;
    if (_scores[1] > _scores[2]) {
      winner = 'Đen (Black)';
    } else if (_scores[2] > _scores[1]) {
      winner = 'Trắng (White)';
    } else {
      winner = 'Hòa';
    }

    // Đảm bảo hộp thoại xuất hiện sau khi build xong
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('KẾT THÚC!'),
            content: Text(
              winner == 'Hòa' ? 'Trò chơi Hòa!' : 'Người chiến thắng: $winner!',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
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

  // Hộp thoại thông báo bỏ lượt
  void _showPassDialog(String nextPlayer) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Không có nước đi cho người chơi hiện tại. Lượt cho $nextPlayer.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // --------------------------------------------------
  // 3. Giao diện (UI)
  // --------------------------------------------------

  // Widget hiển thị quân cờ
  Widget _buildStone(int value) {
    Color color;
    if (value == 1) {
      color = Colors.black;
    } else if (value == 2) {
      color = Colors.white;
    } else {
      return Container(); // Ô trống
    }

    return Center(
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade400, width: 0.5),
        ),
      ),
    );
  }

  // Widget hiển thị ô cờ
  Widget _buildCell(int r, int c) {
    final move = Point(r, c);
    final isHint = _validMoves.contains(move);

    return GestureDetector(
      onTap: () => _makeMove(r, c),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF006400), // Màu xanh đậm cho bàn cờ Othello
          border: Border.all(color: Colors.grey.shade700, width: 0.5),
        ),
        child: Stack(
          children: [
            // Gợi ý nước đi
            if (isHint)
              Center(
                child: Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    color: _currentPlayer == 1 ? Colors.grey.shade700.withOpacity(0.5) : Colors.grey.shade300.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                ),
              ),

            // Quân cờ
            _buildStone(_board[r][c]),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playerColor = _currentPlayer == 1 ? Colors.black : Colors.white;
    final playerName = _currentPlayer == 1 ? 'Đen' : 'Trắng';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cờ Lật', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: <Widget>[
          // Khu vực Thông tin và Điểm số
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                _buildScoreText('Đen (Black): ${_scores[1]}', Colors.black),

                // Lượt đi hiện tại
                Row(
                  children: [
                    const Text('Lượt đi: ', style: TextStyle(fontSize: 18)),
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: playerColor,
                      child: Text(playerName[0], style: TextStyle(color: playerName == 'Đen' ? Colors.white : Colors.black, fontSize: 10)),
                    ),
                  ],
                ),

                _buildScoreText('Trắng (White): ${_scores[2]}', Colors.white),
              ],
            ),
          ),

          // Bàn cờ 8x8
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: AspectRatio(
                aspectRatio: 1.0,
                child: GridView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: boardSize * boardSize,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: boardSize,
                    crossAxisSpacing: 0,
                    mainAxisSpacing: 0,
                  ),
                  itemBuilder: (BuildContext context, int index) {
                    final r = index ~/ boardSize; // Hàng
                    final c = index % boardSize; // Cột
                    return _buildCell(r, c);
                  },
                ),
              ),
            ),
          ),

          // Nút Chơi Lại
          Padding(
            padding: const EdgeInsets.only(bottom: 30.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Chơi Lại', style: TextStyle(fontSize: 20)),
              onPressed: _initializeGame,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue.shade700,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreText(String text, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color == Colors.black ? Colors.black : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: color == Colors.black ? Colors.white : Colors.black,
        ),
      ),
    );
  }
}