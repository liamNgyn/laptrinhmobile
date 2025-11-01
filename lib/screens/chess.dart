import 'package:flutter/material.dart';

// --- Định nghĩa Cấu trúc Dữ liệu cho Quân cờ ---
class ChessPiece {
  final String type; // Ví dụ: 'P', 'R', 'N', 'K', 'Q', 'B'
  final String color; // 'W', 'B'

  ChessPiece(this.type, this.color);

  // Trả về đường dẫn ảnh
  String get imagePath {
    // Tên file phải theo định dạng [color][type].png (ví dụ: wP.png)
    final fileName = '$color$type.png';
    return 'assets/images/chess/$fileName';
  }
}

// --- Lớp Trạng thái Trò chơi ---
class ChessPage extends StatefulWidget {
  const ChessPage({super.key});

  @override
  State<ChessPage> createState() => _ChessPageState();
}

class _ChessPageState extends State<ChessPage> {

  final int boardSize = 8;
  late List<List<ChessPiece?>> _board;
  Offset? _selectedPiecePos;
  List<Offset> _validMoves = [];
  bool _isWhiteTurn = true;



  // Trạng thái cho En Passant
  Offset? _enPassantTarget;

  // Trạng thái cho Nhập Thành: [W_King, W_Rook_Qside, W_Rook_Kside, B_King, B_Rook_Qside, B_Rook_Kside]
  late List<bool> _canCastle;

  // Trạng thái Chiếu
  bool _isCheck = false;
  // Trạng thái Kết thúc
  bool _gameOver = false;

  // Hàm hiển thị hộp thoại kết thúc ván đấu
  void _showEndGameDialog(String result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('KẾT THÚC'),
          content: Text(result, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          actions: <Widget>[
            TextButton(
              child: const Text('Chơi Lại', style: TextStyle(fontSize: 18)),
              onPressed: () {
                Navigator.of(context).pop();
                _initializeGame();
              },
            ),
          ],
        );
      },
    );
  }

  // Kiểm tra xem có nước đi hợp lệ nào cho phe hiện tại không.
  bool _canCurrentPlayerMove(String color) {
    for (int r = 0; r < boardSize; r++) {
      for (int c = 0; c < boardSize; c++) {
        final piece = _board[r][c];
        if (piece != null && piece.color == color) {
          // Lấy tất cả nước đi hợp lệ (đã kiểm tra an toàn)
          final moves = _getValidMovesForPiece(r, c, checkSafety: true);
          if (moves.isNotEmpty) {
            return true; // Tìm thấy ít nhất một nước đi hợp lệ
          }
        }
      }
    }
    return false; // Không có nước đi hợp lệ nào
  }

// Kiểm tra Chiếu Hết / Hòa sau mỗi nước đi
  void _checkForEndGame(String nextPlayerColor) {
    if (_canCurrentPlayerMove(nextPlayerColor)) {
      return; // Vẫn còn nước đi, trò chơi tiếp tục
    }

    // Không có nước đi hợp lệ nào:
    _gameOver = true;
    final winnerColor = nextPlayerColor == 'W' ? 'Đen' : 'Trắng';

    if (_isKingInCheck(nextPlayerColor)) {
      // Chiếu Hết (Checkmate)
      _showEndGameDialog('CHIẾU HẾT! Người thắng: $winnerColor');
    } else {
      // Hòa (Stalemate)
      _showEndGameDialog('HÒA! (Stalemate)');
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    setState(() {
      _board = List.generate(boardSize, (_) => List.filled(boardSize, null));
      _isWhiteTurn = true;
      _selectedPiecePos = null;
      _validMoves = [];
      _enPassantTarget = null;
      _canCastle = [true, true, true, true, true, true];
      _isCheck = false;

      // Thiết lập quân cờ
      _setupPlayer('B', 0, 1);
      _setupPlayer('W', 7, 6);
    });
  }

  void _setupPlayer(String color, int rankRow, int pawnRow) {
    _board[rankRow][0] = ChessPiece('R', color);
    _board[rankRow][1] = ChessPiece('N', color);
    _board[rankRow][2] = ChessPiece('B', color);
    _board[rankRow][3] = ChessPiece('Q', color);
    _board[rankRow][4] = ChessPiece('K', color);
    _board[rankRow][5] = ChessPiece('B', color);
    _board[rankRow][6] = ChessPiece('N', color);
    _board[rankRow][7] = ChessPiece('R', color);

    for (int i = 0; i < boardSize; i++) {
      _board[pawnRow][i] = ChessPiece('P', color);
    }
  }

  // --------------------------------------------------
  // LOGIC TRÒ CHƠI CHÍNH
  // --------------------------------------------------

  void _onCellTapped(int r, int c) {
    setState(() {
      final tappedPos = Offset(r.toDouble(), c.toDouble());
      final piece = _board[r][c];
      final requiredColor = _isWhiteTurn ? 'W' : 'B';

      if (_selectedPiecePos != null) {
        // Có quân đã chọn -> Xử lý nước đi
        if (_validMoves.contains(tappedPos)) {
          _executeMove(_selectedPiecePos!, tappedPos);
        }

        // Bỏ chọn
        _selectedPiecePos = null;
        _validMoves = [];

      } else if (piece != null) {
        // Chưa có quân nào được chọn -> Chọn quân
        if (piece.color == requiredColor) {
          _selectedPiecePos = tappedPos;
          // Lấy nước đi hợp lệ đã kiểm tra Chiếu
          _validMoves = _getValidMovesForPiece(r, c, checkSafety: true);
        }
      }
    });
  }

  void _executeMove(Offset from, Offset to) {
    final fromR = from.dx.toInt();
    final fromC = from.dy.toInt();
    final toR = to.dx.toInt();
    final toC = to.dy.toInt();
    final piece = _board[fromR][fromC]!;

    // 1. Reset trạng thái En Passant
    _enPassantTarget = null;

    // 2. Xử lý nước đi đặc biệt
    if (piece.type == 'P') {
      // En Passant Capture
      if (toC != fromC && _board[toR][toC] == null && (fromR - toR).abs() == 1) {
        _board[fromR][toC] = null; // Xóa Tốt bị bắt
      }
      // Thiết lập En Passant Target
      if ((fromR - toR).abs() == 2) {
        // Mục tiêu là ô trống được đi qua: (fromR + toR) / 2
        final targetR = (fromR + toR) ~/ 2;
        _enPassantTarget = Offset(targetR.toDouble(), toC.toDouble());
      }
      // Phong Cấp (TODO: Cần hộp thoại chọn quân)
      if (toR == 0 || toR == 7) {
        //_board[toR][toC] = ChessPiece('Q', piece.color);
      }

    } else if (piece.type == 'K' && (fromC - toC).abs() == 2) {
      // Nhập Thành (Castle)
      final rookCol = toC == 6 ? 7 : 0;
      final newRookCol = toC == 6 ? 5 : 3;
      _board[toR][newRookCol] = _board[toR][rookCol];
      _board[toR][rookCol] = null;
    }

    // 3. Cập nhật trạng thái Nhập Thành
    _updateCastleStatus(piece.type, fromR, fromC);

    // 4. Di chuyển quân cờ và chuyển lượt
    _board[toR][toC] = _board[fromR][fromC];
    _board[fromR][fromC] = null;
    _isWhiteTurn = !_isWhiteTurn;

    // 5. Kiểm tra Chiếu cho lượt tiếp theo
    final nextPlayerColor = _isWhiteTurn ? 'W' : 'B';
    _isCheck = _isKingInCheck(nextPlayerColor);

    // 6. Kiểm tra kết thúc ván đấu (Checkmate/Stalemate)
    _checkForEndGame(nextPlayerColor);

    _validMoves = [];
  }

  void _updateCastleStatus(String type, int r, int c) {
    final isWhite = r == 7;
    if (type == 'K') {
      _canCastle[isWhite ? 0 : 3] = false;
    }
    if (type == 'R') {
      if (c == 0) {
        _canCastle[isWhite ? 1 : 4] = false;
      } else if (c == 7) {
        _canCastle[isWhite ? 2 : 5] = false;
      }
    }
  }

  // --------------------------------------------------
  // LOGIC KIỂM TRA CHIẾU (CHECK) VÀ HỢP LỆ
  // --------------------------------------------------

  // Lấy tất cả nước đi HỢP LỆ (đã kiểm tra an toàn)
  List<Offset> _getValidMovesForPiece(int r, int c, {bool checkSafety = true}) {
    final List<Offset> moves = [];
    final piece = _board[r][c]!;
    final opponentColor = piece.color == 'W' ? 'B' : 'W';

    List<Offset> rawMoves = [];

    switch (piece.type) {
      case 'P': rawMoves = _getPawnMoves(r, c, piece.color, opponentColor); break;
      case 'R': rawMoves = _getSlidingMoves(r, c, opponentColor, straight: true); break;
      case 'B': rawMoves = _getSlidingMoves(r, c, opponentColor, diagonal: true); break;
      case 'Q': rawMoves = _getSlidingMoves(r, c, opponentColor, straight: true, diagonal: true); break;
      case 'N': rawMoves = _getKnightMoves(r, c, opponentColor); break;
      case 'K':
        rawMoves = _getKingMoves(r, c, opponentColor);
        // Thêm Nhập Thành
        if (checkSafety) rawMoves.addAll(_getCastleMoves(r, c, piece.color));
        break;
    }

    // Lọc nước đi: Vua không được bị chiếu sau nước đi
    if (checkSafety) {
      for (var move in rawMoves) {
        if (!_leavesKingInCheck(r, c, move.dx.toInt(), move.dy.toInt())) {
          moves.add(move);
        }
      }
    } else {
      // Nếu không cần kiểm tra an toàn (dùng để kiểm tra Chiếu)
      moves.addAll(rawMoves);
    }

    return moves;
  }

  // Lấy vị trí Vua
  Offset? _findKingPosition(String color) {
    for (int r = 0; r < boardSize; r++) {
      for (int c = 0; c < boardSize; c++) {
        final piece = _board[r][c];
        if (piece != null && piece.type == 'K' && piece.color == color) {
          return Offset(r.toDouble(), c.toDouble());
        }
      }
    }
    return null;
  }

  // Kiểm tra Vua có bị chiếu sau khi thực hiện nước đi này không
  bool _leavesKingInCheck(int fromR, int fromC, int toR, int toC) {
    final originalPiece = _board[fromR][fromC]!;
    final capturedPiece = _board[toR][toC];
    final originalKingPos = _findKingPosition(originalPiece.color)!;

    // Giả định thực hiện nước đi
    _board[toR][toC] = originalPiece;
    _board[fromR][fromC] = null;

    // Vị trí Vua sau nước đi
    final kingPos = (originalPiece.type == 'K') ? Offset(toR.toDouble(), toC.toDouble()) : originalKingPos;

    // Kiểm tra Chiếu
    final isChecked = _isPositionUnderAttack(kingPos.dx.toInt(), kingPos.dy.toInt(), originalPiece.color);

    // Hoàn tác nước đi giả định
    _board[fromR][fromC] = originalPiece;
    _board[toR][toC] = capturedPiece;

    return isChecked;
  }

  // Kiểm tra Vua có bị chiếu không (tại trạng thái bàn cờ hiện tại)
  bool _isKingInCheck(String kingColor) {
    final kingPos = _findKingPosition(kingColor);
    if (kingPos == null) return false;
    return _isPositionUnderAttack(kingPos.dx.toInt(), kingPos.dy.toInt(), kingColor);
  }

  // Kiểm tra ô (r, c) có đang bị quân đối phương tấn công không
  bool _isPositionUnderAttack(int r, int c, String targetColor) {
    final opponentColor = targetColor == 'W' ? 'B' : 'W';

    for (int pr = 0; pr < boardSize; pr++) {
      for (int pc = 0; pc < boardSize; pc++) {
        final piece = _board[pr][pc];
        if (piece != null && piece.color == opponentColor) {
          // Lấy tất cả nước đi có thể của quân đối phương (KHÔNG kiểm tra an toàn)
          final moves = _getValidMovesForPiece(pr, pc, checkSafety: false);

          // Kiểm tra xem ô (r, c) có nằm trong danh sách tấn công không
          if (moves.contains(Offset(r.toDouble(), c.toDouble()))) {
            return true;
          }
        }
      }
    }
    return false;
  }

  // --------------------------------------------------
  // LOGIC NƯỚC ĐI CỦA CÁC QUÂN CỜ
  // --------------------------------------------------

  // Đã bao gồm logic En Passant Capture và thiết lập Target
  List<Offset> _getPawnMoves(int r, int c, String color, String opponentColor) {
    final List<Offset> moves = [];
    final direction = (color == 'W') ? -1 : 1;
    final startRank = (color == 'W') ? 6 : 1;

    // 1. Đi một bước
    if (_isSafe(r + direction, c) && _board[r + direction][c] == null) {
      moves.add(Offset((r + direction).toDouble(), c.toDouble()));

      // 2. Đi hai bước
      if (r == startRank && _board[r + direction * 2][c] == null) {
        moves.add(Offset((r + direction * 2).toDouble(), c.toDouble()));
      }
    }

    // 3. Tấn công chéo
    final attackCols = [c - 1, c + 1];
    for (var col in attackCols) {
      if (_isSafe(r + direction, col)) {
        final targetPiece = _board[r + direction][col];
        if (targetPiece != null && targetPiece.color == opponentColor) {
          moves.add(Offset((r + direction).toDouble(), col.toDouble()));
        }
      }
    }

    // 4. Bắt Tốt Qua Đường (En Passant)
    if (_enPassantTarget != null && r == _enPassantTarget!.dx.toInt() - direction) {
      final targetC = _enPassantTarget!.dy.toInt();
      if (c == targetC - 1 || c == targetC + 1) {
        moves.add(Offset((r + direction).toDouble(), targetC.toDouble()));
      }
    }

    return moves;
  }

  // Tượng, Xe, Hậu
  List<Offset> _getSlidingMoves(int r, int c, String opponentColor, {bool straight = false, bool diagonal = false}) {
    final List<Offset> moves = [];
    const allDirections = [
      [-1, 0], [1, 0], [0, -1], [0, 1], // Thẳng
      [-1, -1], [-1, 1], [1, -1], [1, 1] // Chéo
    ];

    final directions = allDirections.where((dir) {
      final isStraight = dir[0] == 0 || dir[1] == 0;
      return (straight && isStraight) || (diagonal && !isStraight);
    }).toList();

    for (var dir in directions) {
      int dr = dir[0];
      int dc = dir[1];
      int nr = r + dr;
      int nc = c + dc;

      while (_isSafe(nr, nc)) {
        final targetPiece = _board[nr][nc];

        if (targetPiece == null) {
          moves.add(Offset(nr.toDouble(), nc.toDouble()));
        } else if (targetPiece.color == opponentColor) {
          moves.add(Offset(nr.toDouble(), nc.toDouble()));
          break;
        } else {
          break;
        }
        nr += dr;
        nc += dc;
      }
    }
    return moves;
  }

  // Mã
  List<Offset> _getKnightMoves(int r, int c, String opponentColor) {
    final List<Offset> moves = [];
    final offsets = [
      [-2, -1], [-2, 1], [-1, -2], [-1, 2],
      [ 2, -1], [ 2, 1], [ 1, -2], [ 1, 2]
    ];

    for (var offset in offsets) {
      final nr = r + offset[0];
      final nc = c + offset[1];

      if (_isSafe(nr, nc)) {
        final targetPiece = _board[nr][nc];
        if (targetPiece == null || targetPiece.color == opponentColor) {
          moves.add(Offset(nr.toDouble(), nc.toDouble()));
        }
      }
    }
    return moves;
  }

  // Vua
  List<Offset> _getKingMoves(int r, int c, String opponentColor) {
    final List<Offset> moves = [];
    final offsets = [
      [-1, -1], [-1, 0], [-1, 1], [0, -1],
      [0, 1], [1, -1], [1, 0], [1, 1]
    ];

    for (var offset in offsets) {
      final nr = r + offset[0];
      final nc = c + offset[1];

      if (_isSafe(nr, nc)) {
        final targetPiece = _board[nr][nc];
        if (targetPiece == null || targetPiece.color == opponentColor) {
          // Không kiểm tra Chiếu ở đây, sẽ được kiểm tra ở _getValidMovesForPiece
          moves.add(Offset(nr.toDouble(), nc.toDouble()));
        }
      }
    }
    return moves;
  }

  // Nhập Thành
  List<Offset> _getCastleMoves(int r, int c, String color) {
    final List<Offset> moves = [];
    final isWhite = color == 'W';
    final rank = isWhite ? 7 : 0;
    final kingIndex = isWhite ? 0 : 3;
    final qRookIndex = isWhite ? 1 : 4;
    final kRookIndex = isWhite ? 2 : 5;

    // Nếu Vua đang bị chiếu thì không thể nhập thành
    if (_isKingInCheck(color)) return moves;

    // 1. Nhập Thành Ngắn (Vua sang g-file, Cột 6)
    if (_canCastle[kingIndex] && _canCastle[kRookIndex] && r == rank && c == 4) {
      // Ô f (5) và g (6) trống & không bị chiếu
      if (_board[rank][5] == null && _board[rank][6] == null &&
          !_isPositionUnderAttack(rank, 5, color) && !_isPositionUnderAttack(rank, 6, color)) {
        moves.add(Offset(rank.toDouble(), 6.0));
      }
    }

    // 2. Nhập Thành Dài (Vua sang c-file, Cột 2)
    if (_canCastle[kingIndex] && _canCastle[qRookIndex] && r == rank && c == 4) {
      // Ô d (3), c (2), b (1) trống & d (3), c (2) không bị chiếu
      if (_board[rank][3] == null && _board[rank][2] == null && _board[rank][1] == null &&
          !_isPositionUnderAttack(rank, 3, color) && !_isPositionUnderAttack(rank, 2, color)) {
        moves.add(Offset(rank.toDouble(), 2.0));
      }
    }

    return moves;
  }

  // Kiểm tra tọa độ an toàn
  bool _isSafe(int r, int c) {
    return r >= 0 && r < boardSize && c >= 0 && c < boardSize;
  }

  // --------------------------------------------------
  // GIAO DIỆN (UI)
  // --------------------------------------------------

  Widget _buildCell(int r, int c) {
    final isWhiteCell = (r + c) % 2 == 0;
    final baseColor = isWhiteCell ? const Color(0xFFF0D9B5) : const Color(0xFFB58863);

    final isSelected = _selectedPiecePos == Offset(r.toDouble(), c.toDouble());
    final isHint = _validMoves.contains(Offset(r.toDouble(), c.toDouble()));

    Color cellColor = baseColor;
    if (isSelected) {
      cellColor = Colors.yellow.shade300.withOpacity(0.8);
    } else if (isHint) {
      cellColor = baseColor.withOpacity(0.8);
    }

    final piece = _board[r][c];

    return GestureDetector(
      onTap: () => _onCellTapped(r, c),
      child: Container(
        color: cellColor,
        child: Stack(
          children: [
            // Hiển thị Chiếu Vua (nếu là ô của Vua đang bị chiếu)
            if (_isCheck && piece != null && piece.type == 'K' && piece.color == (_isWhiteTurn ? 'W' : 'B'))
              Container(color: Colors.red.withOpacity(0.4)),

            // Hiển thị gợi ý nước đi
            if (isHint)
              Center(
                child: Container(
                  width: piece != null ? 35 : 15,
                  height: piece != null ? 35 : 15,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade700.withOpacity(piece != null ? 0.4 : 0.6),
                    borderRadius: BorderRadius.circular(piece != null ? 0 : 7.5),
                    border: piece != null ? Border.all(color: Colors.blue.shade700, width: 2) : null,
                  ),
                ),
              ),

            // Hiển thị quân cờ
            // Hiển thị quân cờ bằng hình ảnh
            if (piece != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(4.0), // Padding nhẹ cho hình ảnh
                  child: Image.asset(
                    piece.imagePath, // <-- Sử dụng đường dẫn ảnh mới
                    width: 44, // Điều chỉnh kích thước hình ảnh
                    height: 44,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cờ Vua', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: <Widget>[
          // Khu vực Trạng thái
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _isCheck
                  ? 'CHIẾU! Lượt: ${_isWhiteTurn ? 'Trắng' : 'Đen'}'
                  : 'Lượt đi của: ${_isWhiteTurn ? 'Trắng (White)' : 'Đen (Black)'}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _isCheck ? Colors.red.shade900 : (_isWhiteTurn ? Colors.red.shade700 : Colors.black),
              ),
            ),
          ),

          // Bàn cờ 8x8
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: AspectRatio(
                aspectRatio: 1.0,
                child: GridView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: boardSize * boardSize,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8, // boardSize là 8
                    crossAxisSpacing: 0,
                    mainAxisSpacing: 0,
                  ),
                  itemBuilder: (BuildContext context, int index) {
                    final r = index ~/ boardSize;
                    final c = index % boardSize;
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
                backgroundColor: Colors.red.shade700,
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