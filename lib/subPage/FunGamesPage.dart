import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fidel/service/geez_number_generator.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// SHARED COLOR PALETTE  (identical to beginner/advanced quiz pages)
// ═══════════════════════════════════════════════════════════════════════════════

class _C {
  static const Color primary   = Color(0xFF1A1A2E);
  static const Color teal      = Color(0xFF16213E);
  static const Color cardBg    = Color(0xFF0F3460);
  static const Color softWhite = Color(0xFFF5F0E8);
  static const Color gold      = Color(0xFFFFD700);
  static const Color green     = Color(0xFF4CAF50);
  static const Color red       = Color(0xFFE94560);

  // Per-game accent colours
  static const Color matchAccent    = Color(0xFF7C5CBF); // purple  – Memory Match
  static const Color quizAccent     = Color(0xFF00B4D8); // cyan    – Quick Quiz
  static const Color dragAccent     = Color(0xFFFF9A3C); // amber   – Drag & Drop
}

// ═══════════════════════════════════════════════════════════════════════════════
// FUN GAMES PAGE  (host / nav)
// ═══════════════════════════════════════════════════════════════════════════════

class FunGamesPage extends StatefulWidget {
  const FunGamesPage({super.key});

  @override
  State<FunGamesPage> createState() => _FunGamesPageState();
}

class _FunGamesPageState extends State<FunGamesPage>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _fadeController;
  late Animation<double> _fade;

  static const _games = [
    _GameMeta('Memory Match',  Icons.grid_view_rounded,      _C.matchAccent),
    _GameMeta('Quick Quiz',    Icons.bolt_rounded,            _C.quizAccent),
    _GameMeta('Drag & Drop',   Icons.swap_horiz_rounded,      _C.dragAccent),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _fade = CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _switchGame(int index) {
    if (index == _selectedIndex) return;
    _fadeController.forward(from: 0);
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => true,
      child: Scaffold(
        backgroundColor: _C.primary,
        body: Stack(children: [
          // Decorative background blobs
          Positioned(top: -80,  right: -60, child: _blob(220, _games[_selectedIndex].accent.withOpacity(0.07))),
          Positioned(bottom: -100, left: -80, child: _blob(280, _C.cardBg.withOpacity(0.6))),
          Positioned(top: 160, left: -40, child: _blob(140, _games[_selectedIndex].accent.withOpacity(0.04))),
          SafeArea(child: Column(children: [
            _buildTopNav(),
            Expanded(
              child: FadeTransition(
                opacity: _fade,
                child: _selectedIndex == 0
                    ? const MatchGame()
                    : _selectedIndex == 1
                        ? const QuickQuizGame()
                        : const DragDropGame(),
              ),
            ),
          ])),
        ]),
        // Custom bottom nav
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildTopNav() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(children: [
        _backButton(() => Navigator.maybePop(context)),
        const SizedBox(width: 14),
        Text(
          _games[_selectedIndex].label,
          style: const TextStyle(
            color: _C.softWhite, fontSize: 20, fontWeight: FontWeight.w800,
            letterSpacing: -0.3),
        ),
        const Spacer(),
        // Active game accent dot
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _games[_selectedIndex].accent,
            boxShadow: [BoxShadow(
              color: _games[_selectedIndex].accent.withOpacity(0.5),
              blurRadius: 8, spreadRadius: 2)]),
        ),
      ]),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: _C.teal,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06)))),
      child: Row(
        children: List.generate(_games.length, (i) {
          final selected = _selectedIndex == i;
          final g = _games[i];
          return Expanded(
            child: GestureDetector(
              onTap: () => _switchGame(i),
              behavior: HitTestBehavior.opaque,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: selected ? g.accent.withOpacity(0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12)),
                  child: Icon(g.icon,
                    color: selected ? g.accent : _C.softWhite.withOpacity(0.3),
                    size: 22),
                ),
                const SizedBox(height: 2),
                Text(g.label,
                  style: TextStyle(
                    color: selected ? g.accent : _C.softWhite.withOpacity(0.3),
                    fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
              ]),
            ),
          );
        }),
      ),
    );
  }

  Widget _blob(double size, Color color) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color));

  Widget _backButton(VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: _C.teal, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.07))),
      child: const Icon(Icons.arrow_back_ios_new_rounded,
        color: _C.softWhite, size: 16)));
}

class _GameMeta {
  final String label;
  final IconData icon;
  final Color accent;
  const _GameMeta(this.label, this.icon, this.accent);
}

// ═══════════════════════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

Widget _statPill(String value, String label, IconData icon, Color accent) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: accent.withOpacity(0.12),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: accent.withOpacity(0.2))),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: accent, size: 16),
      const SizedBox(height: 3),
      Text(value, style: TextStyle(
        color: accent, fontSize: 16, fontWeight: FontWeight.w800)),
      Text(label, style: TextStyle(
        color: accent.withOpacity(0.7), fontSize: 9,
        fontWeight: FontWeight.w500, letterSpacing: 0.4)),
    ]),
  );
}

Widget _gameCompletionDialog(
  BuildContext context, {
  required String title,
  required String subtitle,
  required int score,
  required bool isHighScore,
  required Color accent,
  required VoidCallback onPlayAgain,
}) {
  return Dialog(
    backgroundColor: Colors.transparent,
    child: Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _C.teal,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: accent.withOpacity(0.35), width: 1.5)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [accent.withOpacity(0.85), _C.cardBg])),
          child: const Center(
            child: Text('🎉', style: TextStyle(fontSize: 36)))),
        const SizedBox(height: 20),
        Text(title, style: const TextStyle(
          color: _C.softWhite, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(subtitle, style: TextStyle(
          color: _C.softWhite.withOpacity(0.5), fontSize: 13)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: _C.primary, borderRadius: BorderRadius.circular(16)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.star_rounded, color: _C.gold, size: 20),
            const SizedBox(width: 8),
            Text('$score pts', style: const TextStyle(
              color: _C.softWhite, fontSize: 28, fontWeight: FontWeight.w800)),
          ])),
        if (isHighScore) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _C.gold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _C.gold.withOpacity(0.4))),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.emoji_events_rounded, color: _C.gold, size: 16),
              SizedBox(width: 6),
              Text('New High Score!', style: TextStyle(
                color: _C.gold, fontWeight: FontWeight.w700, fontSize: 13)),
            ])),
        ],
        const SizedBox(height: 28),
        Row(children: [
          Expanded(child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: _C.softWhite,
              side: BorderSide(color: Colors.white.withOpacity(0.2)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 12)),
            child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w600)))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(
            onPressed: () { Navigator.pop(context); onPlayAgain(); },
            style: ElevatedButton.styleFrom(
              backgroundColor: accent, foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 12)),
            child: const Text('Play Again',
              style: TextStyle(fontWeight: FontWeight.w700)))),
        ]),
      ]),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// GAME 1 — MEMORY MATCH
// ═══════════════════════════════════════════════════════════════════════════════

class MatchGame extends StatefulWidget {
  const MatchGame({super.key});

  @override
  State<MatchGame> createState() => _MatchGameState();
}

class _MatchGameState extends State<MatchGame> with TickerProviderStateMixin {
  List<GameCard> _cards = [];
  int _score = 0;
  int _matchesFound = 0;
  int _attempts = 0;
  int? _firstSelectedIndex;
  bool _isProcessing = false;
  int _highScore = 0;

  late AnimationController _shakeController;
  late AnimationController _successController;
  late Animation<double> _successScale;

  static const _accent = _C.matchAccent;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _successController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _successScale = Tween<double>(begin: 1.0, end: 1.12).animate(
        CurvedAnimation(parent: _successController, curve: Curves.elasticOut));
    _loadHighScore();
    _initializeGame();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _successController.dispose();
    super.dispose();
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _highScore = prefs.getInt('match_game_highscore') ?? 0);
  }

  Future<void> _saveHighScore() async {
    if (_score > _highScore) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('match_game_highscore', _score);
      setState(() => _highScore = _score);
    }
  }

  void _initializeGame() {
    final numbers = GeezNumberService.generateRange(1, 6);
    final newCards = <GameCard>[];
    for (var n in numbers) {
      newCards.add(GameCard(id: n.number, value: n.symbol,       type: 'symbol', isMatched: false, isFlipped: false));
      newCards.add(GameCard(id: n.number, value: n.number.toString(), type: 'number', isMatched: false, isFlipped: false));
    }
    newCards.shuffle();
    setState(() {
      _cards = newCards;
      _score = 0; _matchesFound = 0; _attempts = 0;
      _firstSelectedIndex = null; _isProcessing = false;
    });
  }

  void _onCardTapped(int index) {
    if (_isProcessing) return;
    if (_cards[index].isMatched) return;
    if (_cards[index].isFlipped && _firstSelectedIndex == index) return;

    setState(() {
      _cards[index].isFlipped = true;
      if (_firstSelectedIndex == null) {
        _firstSelectedIndex = index;
      } else {
        _attempts++;
        _checkMatch(_firstSelectedIndex!, index);
        _firstSelectedIndex = null;
      }
    });
  }

  void _checkMatch(int a, int b) {
    final c1 = _cards[a]; final c2 = _cards[b];
    final isMatch = c1.id == c2.id && c1.type != c2.type;

    setState(() => _isProcessing = true);

    if (isMatch) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        setState(() {
          _cards[a].isMatched = true;
          _cards[b].isMatched = true;
          _matchesFound++;
          _score += 10;
        });
        _successController.forward(from: 0);
        if (_matchesFound == 6) {
          _saveHighScore();
          Future.delayed(const Duration(milliseconds: 400), _showCompletion);
        }
        setState(() => _isProcessing = false);
      });
    } else {
      _shakeController.forward(from: 0);
      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        setState(() {
          _cards[a].isFlipped = false;
          _cards[b].isFlipped = false;
          _isProcessing = false;
        });
      });
    }
  }

  void _showCompletion() {
    showDialog(
      context: context, barrierDismissible: false,
      builder: (_) => _gameCompletionDialog(context,
        title: 'All Matched!',
        subtitle: 'You matched all Ge\'ez symbols',
        score: _score, isHighScore: _score >= _highScore,
        accent: _accent, onPlayAgain: _initializeGame));
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Stats bar
      _statsBar(),
      const SizedBox(height: 12),
      // Board hint
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text('Match each Ge\'ez symbol with its number',
          style: TextStyle(color: _C.softWhite.withOpacity(0.4),
            fontSize: 12, letterSpacing: 0.3)),
      ),
      const SizedBox(height: 12),
      Expanded(
        child: GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, childAspectRatio: 0.88,
            crossAxisSpacing: 12, mainAxisSpacing: 12),
          itemCount: _cards.length,
          itemBuilder: (_, i) => _buildCard(_cards[i], i)),
      ),
    ]);
  }

  Widget _statsBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(children: [
        _statPill('$_score',     'Score',    Icons.star_rounded,        _accent),
        const SizedBox(width: 8),
        _statPill('$_highScore', 'Best',     Icons.emoji_events_rounded, _C.gold),
        const SizedBox(width: 8),
        _statPill('$_attempts',  'Flips',    Icons.touch_app_rounded,   _C.softWhite.withOpacity(0.6)),
        const Spacer(),
        GestureDetector(
          onTap: _initializeGame,
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: _C.teal, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.07))),
            child: Icon(Icons.refresh_rounded, color: _accent, size: 20))),
      ]),
    );
  }

  Widget _buildCard(GameCard card, int index) {
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (_, child) {
        double dx = 0;
        if (_shakeController.isAnimating && card.isFlipped && !card.isMatched) {
          dx = sin(_shakeController.value * pi * 5) * 6;
        }
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: GestureDetector(
        onTap: () => _onCardTapped(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: card.isMatched
                ? _C.green.withOpacity(0.15)
                : card.isFlipped
                    ? _C.teal
                    : _C.cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: card.isMatched
                  ? _C.green.withOpacity(0.5)
                  : card.isFlipped
                      ? _accent.withOpacity(0.5)
                      : Colors.white.withOpacity(0.06),
              width: 1.5),
            boxShadow: card.isFlipped && !card.isMatched
                ? [BoxShadow(
                    color: _accent.withOpacity(0.2),
                    blurRadius: 12, spreadRadius: 1)]
                : [],
          ),
          child: Center(
            child: card.isFlipped || card.isMatched
                ? Text(card.value, style: TextStyle(
                    fontSize: card.type == 'symbol' ? 34 : 26,
                    fontWeight: FontWeight.w800,
                    color: card.isMatched ? _C.green : _C.softWhite))
                : Icon(Icons.question_mark_rounded,
                    color: _C.softWhite.withOpacity(0.2), size: 28),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// GAME 2 — QUICK QUIZ
// ═══════════════════════════════════════════════════════════════════════════════

class QuickQuizGame extends StatefulWidget {
  const QuickQuizGame({super.key});

  @override
  State<QuickQuizGame> createState() => _QuickQuizGameState();
}

class _QuickQuizGameState extends State<QuickQuizGame>
    with TickerProviderStateMixin {
  int _score = 0;
  int _questionCount = 0;
  int _highScore = 0;
  String? _selectedAnswer;
  bool _answered = false;
  List<GeezNumber> _numbers = [];
  GeezNumber? _currentQuestion;
  List<String> _options = [];
  int _timeRemaining = 10;
  Timer? _timer;
  bool _gameActive = false;
  bool _gameStarted = false;

  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<Offset> _slideAnim;
  late Animation<double> _pulseAnim;

  static const _accent = _C.quizAccent;
  static const _totalQuestions = 10;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _slideAnim = Tween<Offset>(begin: const Offset(0.25, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.05)
        .animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _loadHighScore();
    _numbers = GeezNumberService.generateRange(1, 20);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _highScore = prefs.getInt('quickquiz_highscore') ?? 0);
  }

  Future<void> _saveHighScore() async {
    if (_score > _highScore) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('quickquiz_highscore', _score);
      setState(() => _highScore = _score);
    }
  }

  void _startGame() {
    setState(() {
      _score = 0; _questionCount = 0;
      _gameActive = true; _gameStarted = true;
    });
    _nextQuestion();
  }

  void _nextQuestion() {
    if (_questionCount >= _totalQuestions) { _endGame(); return; }
    setState(() {
      _selectedAnswer = null; _answered = false; _timeRemaining = 10;
    });
    _timer?.cancel();
    _startTimer();
    final random = Random();
    _currentQuestion = _numbers[random.nextInt(_numbers.length)];
    _generateOptions();
    _slideController.forward(from: 0);
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_timeRemaining > 0 && !_answered && _gameActive) {
        setState(() => _timeRemaining--);
      } else if (_timeRemaining == 0 && !_answered && _gameActive) {
        t.cancel();
        _handleTimeout();
      }
    });
  }

  void _handleTimeout() {
    setState(() { _answered = true; _questionCount++; });
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      if (_questionCount < _totalQuestions) _nextQuestion(); else _endGame();
    });
  }

  void _generateOptions() {
    final random = Random();
    final Set<String> opts = {_currentQuestion!.symbol};
    while (opts.length < 4) {
      opts.add(_numbers[random.nextInt(_numbers.length)].symbol);
    }
    setState(() => _options = opts.toList()..shuffle(random));
  }

  void _checkAnswer(String answer) {
    if (_answered) return;
    _timer?.cancel();
    final isCorrect = answer == _currentQuestion!.symbol;
    setState(() {
      _answered = true; _selectedAnswer = answer; _questionCount++;
      if (isCorrect) _score += _timeRemaining + 5;
    });
    Future.delayed(const Duration(milliseconds: 1100), () {
      if (!mounted) return;
      if (_questionCount < _totalQuestions) _nextQuestion(); else _endGame();
    });
  }

  void _endGame() {
    _timer?.cancel();
    _saveHighScore();
    setState(() => _gameActive = false);
    showDialog(
      context: context, barrierDismissible: false,
      builder: (_) => _gameCompletionDialog(context,
        title: 'Round Complete!',
        subtitle: '$_totalQuestions questions answered',
        score: _score, isHighScore: _score >= _highScore,
        accent: _accent, onPlayAgain: _startGame));
  }

  @override
  Widget build(BuildContext context) {
    if (!_gameStarted) return _buildStartScreen();
    return Column(children: [
      _statsBar(),
      const SizedBox(height: 16),
      Expanded(child: SlideTransition(
        position: _slideAnim,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(children: [
            // Number display
            ScaleTransition(
              scale: _pulseAnim,
              child: Container(
                width: 150, height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle, color: _C.teal,
                  border: Border.all(color: _accent.withOpacity(0.5), width: 2),
                  boxShadow: [BoxShadow(
                    color: _accent.withOpacity(0.25),
                    blurRadius: 32, spreadRadius: 4)]),
                child: Center(child: Text(
                  _currentQuestion?.number.toString() ?? '?',
                  style: const TextStyle(
                    fontSize: 56, fontWeight: FontWeight.w900, color: _C.softWhite))))),
            const SizedBox(height: 20),
            Text('What is the Ge\'ez symbol?',
              style: TextStyle(
                color: _C.softWhite.withOpacity(0.5), fontSize: 14, letterSpacing: 0.3)),
            const SizedBox(height: 20),
            // 2×2 grid options
            GridView.count(
              crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12,
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.5,
              children: _options.map(_buildOption).toList()),
          ]),
        ),
      )),
    ]);
  }

  Widget _buildStartScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          ScaleTransition(
            scale: _pulseAnim,
            child: Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_accent.withOpacity(0.9), _C.cardBg]),
                boxShadow: [BoxShadow(
                  color: _accent.withOpacity(0.3), blurRadius: 36, spreadRadius: 6)]),
              child: const Center(
                child: Icon(Icons.bolt_rounded, size: 56, color: Colors.white)))),
          const SizedBox(height: 28),
          const Text('Quick Quiz', style: TextStyle(
            color: _C.softWhite, fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('10 questions · 10s per question\nScore more by answering fast!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _C.softWhite.withOpacity(0.45), fontSize: 14, height: 1.6)),
          const SizedBox(height: 32),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _statPill('$_highScore', 'Best', Icons.emoji_events_rounded, _C.gold),
          ]),
          const SizedBox(height: 32),
          SizedBox(width: double.infinity, height: 54,
            child: ElevatedButton(
              onPressed: _startGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent, foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16))),
              child: const Text('Start Game', style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w700)))),
        ]),
      ),
    );
  }

  Widget _statsBar() {
    final timerDanger = _timeRemaining <= 4;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(children: [
        _statPill('$_score', 'Score', Icons.star_rounded, _accent),
        const SizedBox(width: 8),
        _statPill('$_highScore', 'Best', Icons.emoji_events_rounded, _C.gold),
        const SizedBox(width: 8),
        _statPill('${_questionCount + 1}/$_totalQuestions', 'Q', Icons.quiz_rounded,
          _C.softWhite.withOpacity(0.6)),
        const Spacer(),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: timerDanger ? _C.red.withOpacity(0.2) : _C.teal,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: timerDanger ? _C.red.withOpacity(0.5) : Colors.transparent)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.timer_rounded,
              color: timerDanger ? _C.red : _C.softWhite.withOpacity(0.5), size: 14),
            const SizedBox(width: 4),
            Text('${_timeRemaining}s', style: TextStyle(
              color: timerDanger ? _C.red : _C.softWhite,
              fontWeight: FontWeight.w700, fontSize: 14)),
          ])),
      ]),
    );
  }

  Widget _buildOption(String option) {
    final isSelected = _selectedAnswer == option;
    final isCorrect  = option == _currentQuestion?.symbol;
    Color bg = _C.teal;
    Color border = Colors.white.withOpacity(0.07);
    Color text = _C.softWhite;
    Widget? badge;

    if (_answered) {
      if (isSelected && isCorrect)  {
        bg = _C.green.withOpacity(0.15); border = _C.green; text = _C.green;
        badge = Icon(Icons.check_circle_rounded, color: _C.green, size: 18);
      } else if (isSelected) {
        bg = _C.red.withOpacity(0.15); border = _C.red; text = _C.red;
        badge = Icon(Icons.cancel_rounded, color: _C.red, size: 18);
      } else if (isCorrect) {
        bg = _C.green.withOpacity(0.08); border = _C.green.withOpacity(0.4);
        text = _C.green.withOpacity(0.8);
      }
    }

    return GestureDetector(
      onTap: _answered ? null : () => _checkAnswer(option),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border, width: 1.5),
          boxShadow: isSelected ? [BoxShadow(
            color: border.withOpacity(0.3), blurRadius: 12, spreadRadius: 1)] : []),
        child: Stack(children: [
          Center(child: Text(option, style: TextStyle(
            fontSize: 32, fontWeight: FontWeight.w700, color: text))),
          if (badge != null) Positioned(top: 8, right: 8, child: badge),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// GAME 3 — DRAG & DROP
// ═══════════════════════════════════════════════════════════════════════════════

class DragDropGame extends StatefulWidget {
  const DragDropGame({super.key});

  @override
  State<DragDropGame> createState() => _DragDropGameState();
}

class _DragDropGameState extends State<DragDropGame>
    with SingleTickerProviderStateMixin {
  List<DragItem> _items = [];
  List<DropZone> _dropZones = [];
  int _score = 0;
  int _highScore = 0;
  int _completedItems = 0;
  int? _wrongAttemptZone; // flash wrong zone red

  late AnimationController _wrongController;

  static const _accent = _C.dragAccent;

  @override
  void initState() {
    super.initState();
    _wrongController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _loadHighScore();
    _initializeGame();
  }

  @override
  void dispose() { _wrongController.dispose(); super.dispose(); }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _highScore = prefs.getInt('dragdrop_highscore') ?? 0);
  }

  Future<void> _saveHighScore() async {
    if (_score > _highScore) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('dragdrop_highscore', _score);
      setState(() => _highScore = _score);
    }
  }

  void _initializeGame() {
    final numbers = GeezNumberService.generateRange(1, 6);
    _items = numbers.map((n) => DragItem(
      id: n.number, value: n.symbol, matched: false, position: Offset.zero)).toList()
      ..shuffle();
    _dropZones = numbers.map((n) => DropZone(
      id: n.number, value: n.number.toString(), isFilled: false)).toList();
    _score = 0; _completedItems = 0; _wrongAttemptZone = null;
    setState(() {});
  }

  void _onDrop(int itemId, int zoneId) {
    final item = _items.firstWhere((i) => i.id == itemId);
    final zoneIdx = _dropZones.indexWhere((z) => z.id == zoneId);
    if (zoneIdx == -1 || item.matched || _dropZones[zoneIdx].isFilled) return;

    if (item.id == zoneId) {
      setState(() {
        item.matched = true;
        _dropZones[zoneIdx].isFilled = true;
        _completedItems++;
        _score += 10;
      });
      if (_completedItems == _items.length) {
        _saveHighScore();
        Future.delayed(const Duration(milliseconds: 300), _showCompletion);
      }
    } else {
      // Wrong drop flash
      setState(() => _wrongAttemptZone = zoneIdx);
      _wrongController.forward(from: 0).then((_) {
        setState(() => _wrongAttemptZone = null);
      });
    }
  }

  void _showCompletion() {
    showDialog(
      context: context, barrierDismissible: false,
      builder: (_) => _gameCompletionDialog(context,
        title: 'Perfect Match!',
        subtitle: 'All symbols placed correctly',
        score: _score, isHighScore: _score >= _highScore,
        accent: _accent, onPlayAgain: _initializeGame));
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _statsBar(),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
        child: Text('Drag each Ge\'ez symbol to its matching number',
          style: TextStyle(color: _C.softWhite.withOpacity(0.4),
            fontSize: 12, letterSpacing: 0.3))),
      Expanded(
        child: Row(children: [
          // ── Draggable symbols (left) ──────────────────────────────
          Expanded(child: _panel(
            label: 'Symbols',
            icon: Icons.translate_rounded,
            accent: _accent,
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, childAspectRatio: 1,
                crossAxisSpacing: 10, mainAxisSpacing: 10),
              itemCount: _items.length,
              itemBuilder: (_, i) {
                final item = _items[i];
                if (item.matched) return _matchedTile();
                return Draggable<int>(
                  data: item.id,
                  feedback: Material(color: Colors.transparent,
                    child: _dragFeedback(item.value)),
                  childWhenDragging: _ghostTile(),
                  child: _draggableTile(item.value));
              }),
          )),

          // ── Drop zones (right) ─────────────────────────────────────
          Expanded(child: _panel(
            label: 'Numbers',
            icon: Icons.pin_rounded,
            accent: _accent,
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, childAspectRatio: 1,
                crossAxisSpacing: 10, mainAxisSpacing: 10),
              itemCount: _dropZones.length,
              itemBuilder: (_, i) {
                final zone = _dropZones[i];
                final isWrong = _wrongAttemptZone == i;
                return DragTarget<int>(
                  onWillAccept: (data) {
                    if (data == null) return false;
                    final item = _items.firstWhere((x) => x.id == data);
                    return !item.matched && !zone.isFilled;
                  },
                  onAccept: (data) => _onDrop(data, zone.id),
                  builder: (_, candidates, __) {
                    final hovering = candidates.isNotEmpty;
                    return AnimatedBuilder(
                      animation: _wrongController,
                      builder: (_, child) {
                        Color bg, border;
                        if (zone.isFilled) {
                          bg = _C.green.withOpacity(0.15);
                          border = _C.green.withOpacity(0.5);
                        } else if (isWrong) {
                          final t = sin(_wrongController.value * pi);
                          bg = Color.lerp(_C.teal, _C.red.withOpacity(0.2), t)!;
                          border = Color.lerp(
                            Colors.white.withOpacity(0.07),
                            _C.red.withOpacity(0.6), t)!;
                        } else if (hovering) {
                          bg = _accent.withOpacity(0.15);
                          border = _accent.withOpacity(0.5);
                        } else {
                          bg = _C.teal;
                          border = Colors.white.withOpacity(0.07);
                        }

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: bg, borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: border, width: 1.5),
                            boxShadow: hovering ? [BoxShadow(
                              color: _accent.withOpacity(0.2),
                              blurRadius: 12, spreadRadius: 1)] : []),
                          child: Center(child: zone.isFilled
                            ? const Icon(Icons.check_rounded,
                                color: _C.green, size: 32)
                            : Text(zone.value, style: TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w800,
                                color: hovering
                                    ? _accent
                                    : _C.softWhite.withOpacity(0.7)))));
                      });
                  });
              }),
          )),
        ]),
      ),
    ]);
  }

  Widget _statsBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(children: [
        _statPill('$_score',     'Score',   Icons.star_rounded,         _accent),
        const SizedBox(width: 8),
        _statPill('$_highScore', 'Best',    Icons.emoji_events_rounded,  _C.gold),
        const SizedBox(width: 8),
        _statPill('$_completedItems/${_items.length}', 'Done',
          Icons.check_circle_outline_rounded, _C.green),
        const Spacer(),
        GestureDetector(
          onTap: _initializeGame,
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: _C.teal, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.07))),
            child: Icon(Icons.refresh_rounded, color: _accent, size: 20))),
      ]),
    );
  }

  Widget _panel({
    required String label, required IconData icon,
    required Color accent, required Widget child}) {
    return Container(
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _C.teal, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06))),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: accent.withOpacity(0.7), size: 14),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(
              color: _C.softWhite.withOpacity(0.4), fontSize: 11,
              fontWeight: FontWeight.w600, letterSpacing: 1)),
          ])),
        Expanded(child: child),
      ]),
    );
  }

  Widget _draggableTile(String value) => Container(
    decoration: BoxDecoration(
      color: _C.cardBg, borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _accent.withOpacity(0.25), width: 1.5),
      boxShadow: [BoxShadow(
        color: _accent.withOpacity(0.1), blurRadius: 8, spreadRadius: 0)]),
    child: Center(child: Text(value,
      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700,
        color: _C.softWhite))));

  Widget _dragFeedback(String value) => Container(
    width: 72, height: 72,
    decoration: BoxDecoration(
      color: _C.cardBg, borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _accent, width: 2),
      boxShadow: [BoxShadow(
        color: _accent.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)]),
    child: Center(child: Text(value,
      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700,
        color: _C.softWhite))));

  Widget _ghostTile() => Container(
    decoration: BoxDecoration(
      color: _C.primary.withOpacity(0.5),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white.withOpacity(0.05))));

  Widget _matchedTile() => Container(
    decoration: BoxDecoration(
      color: _C.green.withOpacity(0.12),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _C.green.withOpacity(0.35))),
    child: const Center(
      child: Icon(Icons.check_rounded, color: _C.green, size: 32)));
}

// ═══════════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════════

class GameCard {
  final int id;
  final String value;
  final String type;
  bool isMatched;
  bool isFlipped;

  GameCard({
    required this.id, required this.value, required this.type,
    required this.isMatched, required this.isFlipped,
  });
}

class DragItem {
  final int id;
  final String value;
  bool matched;
  Offset position;

  DragItem({
    required this.id, required this.value,
    required this.matched, required this.position,
  });
}

class DropZone {
  final int id;
  final String value;
  bool isFilled;

  DropZone({required this.id, required this.value, required this.isFilled});
}