import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';

void main() {
  runApp(const TicTacToeApp());
}

class TicTacToeApp extends StatefulWidget {
  const TicTacToeApp({super.key});

  @override
  State<TicTacToeApp> createState() => _TicTacToeAppState();
}

class _TicTacToeAppState extends State<TicTacToeApp> {
  bool isDarkMode = false;

  void _toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tic Tac Toe',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: GameScreen(
        onToggleTheme: _toggleTheme,
        isDarkMode: isDarkMode,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class GameScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;
  const GameScreen({super.key, required this.onToggleTheme, required this.isDarkMode});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int boardSize = 3;
  List<String> board = List.filled(9, '');
  bool isXTurn = true;
  String winner = '';
  bool gameOver = false;

  int xWins = 0;
  int oWins = 0;
  int draws = 0;

  String playerX = 'Player X';
  String playerO = 'Player O';

  String playerXEmoji = '❌';
  String playerOEmoji = '⭕';

  final List<String> emojiOptions = [
    '❌', '⭕', '😃', '😎', '🐱', '🐶', '🍕', '🌟', '🔥', '🎲', '👾', '🦄', '🚀', '🍀', '💎', '🎉', '🥇', '🏆', '🧠', '🤖'
  ];

  final AudioPlayer _audioPlayer = AudioPlayer();
  final ConfettiController _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  bool playWithAI = false;

  List<List<String>> boardHistory = [];
  List<bool> turnHistory = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _promptForNames());
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _promptForNames() async {
    final names = await showDialog<List<String>>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final xController = TextEditingController(text: playerX);
        final oController = TextEditingController(text: playerO);
        return AlertDialog(
          title: const Text('Enter Player Names'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: xController,
                decoration: const InputDecoration(labelText: 'Player X'),
              ),
              TextField(
                controller: oController,
                decoration: const InputDecoration(labelText: 'Player O'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop([
                  xController.text.trim().isEmpty ? 'Player X' : xController.text.trim(),
                  oController.text.trim().isEmpty ? 'Player O' : oController.text.trim(),
                ]);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    if (names != null && names.length == 2) {
      setState(() {
        playerX = names[0];
        playerO = names[1];
      });
    }
  }

  void _playSound(String sound) async {
    await _audioPlayer.play(AssetSource('sounds/$sound'));
  }

  void _handleTap(int index) {
    if (board[index] == '' && !gameOver) {
      // Save current state to history
      boardHistory.add(List.from(board));
      turnHistory.add(isXTurn);
      setState(() {
        board[index] = isXTurn ? 'X' : 'O';
        isXTurn = !isXTurn;
        _playSound('move.mp3');
        _checkWinner();
      });
      if (playWithAI && !isXTurn && !gameOver) {
        Future.delayed(const Duration(milliseconds: 500), _aiMove);
      }
    }
  }

  void _aiMove() {
    // Simple AI: pick a random empty cell
    final emptyIndices = <int>[];
    for (int i = 0; i < board.length; i++) {
      if (board[i] == '') emptyIndices.add(i);
    }
    if (emptyIndices.isNotEmpty && !gameOver) {
      final aiIndex = (emptyIndices..shuffle()).first;
      setState(() {
        board[aiIndex] = 'O';
        isXTurn = !isXTurn;
        _playSound('move.mp3');
        _checkWinner();
      });
    }
  }

  void _changeBoardSize(int size) {
    setState(() {
      boardSize = size;
      board = List.filled(size * size, '');
      isXTurn = true;
      winner = '';
      gameOver = false;
      xWins = 0;
      oWins = 0;
      draws = 0;
      boardHistory.clear();
      turnHistory.clear();
    });
  }

  void _checkWinner() {
    // Generalized win check for NxN board
    int n = boardSize;
    // Check rows
    for (int i = 0; i < n * n; i += n) {
      String first = board[i];
      if (first != '' && List.generate(n, (j) => board[i + j]).every((cell) => cell == first)) {
        _setWinner(first);
        return;
      }
    }
    // Check columns
    for (int i = 0; i < n; i++) {
      String first = board[i];
      if (first != '' && List.generate(n, (j) => board[i + j * n]).every((cell) => cell == first)) {
        _setWinner(first);
        return;
      }
    }
    // Check main diagonal
    String firstDiag = board[0];
    if (firstDiag != '' && List.generate(n, (j) => board[j * (n + 1)]).every((cell) => cell == firstDiag)) {
      _setWinner(firstDiag);
      return;
    }
    // Check anti-diagonal
    String firstAntiDiag = board[n - 1];
    if (firstAntiDiag != '' && List.generate(n, (j) => board[(j + 1) * (n - 1)]).every((cell) => cell == firstAntiDiag)) {
      _setWinner(firstAntiDiag);
      return;
    }
    // Check for draw
    if (!board.contains('')) {
      setState(() {
        gameOver = true;
        winner = 'Draw';
        draws++;
        _playSound('draw.mp3');
      });
    }
  }

  void _setWinner(String player) {
    setState(() {
      gameOver = true;
      winner = player;
      if (player == 'X') {
        xWins++;
      } else if (player == 'O') {
        oWins++;
      }
      _playSound('win.mp3');
      _confettiController.play();
    });
  }

  void _undoMove() {
    if (boardHistory.isNotEmpty && turnHistory.isNotEmpty && !gameOver) {
      setState(() {
        board = boardHistory.removeLast();
        isXTurn = turnHistory.removeLast();
      });
    }
  }

  void _resetGame() {
    setState(() {
      board = List.filled(board.length, '');
      isXTurn = true;
      winner = '';
      gameOver = false;
      boardHistory.clear();
      turnHistory.clear();
    });
    if (playWithAI && !isXTurn) {
      Future.delayed(const Duration(milliseconds: 500), _aiMove);
    }
  }

  void _resetScore() {
    setState(() {
      xWins = 0;
      oWins = 0;
      draws = 0;
    });
  }

  void _pickEmoji(bool isX) async {
    String? selected = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Pick Emoji for ${isX ? playerX : playerO}'),
          content: SizedBox(
            width: 300,
            height: 200,
            child: GridView.count(
              crossAxisCount: 5,
              children: emojiOptions.map((emoji) {
                return GestureDetector(
                  onTap: () => Navigator.of(context).pop(emoji),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 28),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
    if (selected != null) {
      setState(() {
        if (isX) {
          playerXEmoji = selected;
        } else {
          playerOEmoji = selected;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tic Tac Toe'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            tooltip: widget.isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            onPressed: widget.onToggleTheme,
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Player Names',
            onPressed: _promptForNames,
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    children: [
                      Text(
                        'Scoreboard',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _scoreBox('X', xWins, Colors.blue),
                          const SizedBox(width: 16),
                          _scoreBox('O', oWins, Colors.red),
                          const SizedBox(width: 16),
                          _scoreBox('Draw', draws, Colors.grey),
                        ],
                      ),
                      TextButton(
                        onPressed: _resetScore,
                        child: const Text('Reset Score'),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                    child: Text(
                      gameOver
                          ? winner == 'Draw'
                              ? 'Game Draw!'
                              : 'Player ${winner == 'X' ? playerX : playerO} Wins!'
                          : 'Turn: ${isXTurn ? playerX : playerO}',
                      key: ValueKey<String>(gameOver ? (winner == 'Draw' ? 'draw' : winner) : (isXTurn ? playerX : playerO)),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Switch(
                        value: playWithAI,
                        onChanged: (val) {
                          setState(() {
                            playWithAI = val;
                          });
                          _resetGame();
                        },
                      ),
                      Text(playWithAI ? 'Play vs AI' : '2 Players'),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Board Size: '),
                      DropdownButton<int>(
                        value: boardSize,
                        items: const [
                          DropdownMenuItem(value: 3, child: Text('3x3')),
                          DropdownMenuItem(value: 4, child: Text('4x4')),
                          DropdownMenuItem(value: 5, child: Text('5x5')),
                        ],
                        onChanged: (val) {
                          if (val != null) _changeBoardSize(val);
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: () => _pickEmoji(true),
                        icon: Text(playerXEmoji, style: const TextStyle(fontSize: 24)),
                        label: Text(playerX),
                      ),
                      const SizedBox(width: 16),
                      TextButton.icon(
                        onPressed: () => _pickEmoji(false),
                        icon: Text(playerOEmoji, style: const TextStyle(fontSize: 24)),
                        label: Text(playerO),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: GridView.builder(
                      shrinkWrap: true,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: boardSize,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: board.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () => _handleTap(index),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                                child: Text(
                                  board[index] == 'X'
                                      ? playerXEmoji
                                      : board[index] == 'O'
                                          ? playerOEmoji
                                          : '',
                                  key: ValueKey<String>(board[index] + index.toString()),
                                  style: const TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _resetGame,
                        child: const Text('Reset Game'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: boardHistory.isNotEmpty && !gameOver ? _undoMove : null,
                        child: const Text('Undo'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  Colors.blue,
                  Colors.red,
                  Colors.green,
                  Colors.orange,
                  Colors.purple,
                  Colors.amber,
                ],
                numberOfParticles: 30,
                maxBlastForce: 20,
                minBlastForce: 8,
                emissionFrequency: 0.05,
                gravity: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scoreBox(String label, int count, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ],
    );
  }
} 