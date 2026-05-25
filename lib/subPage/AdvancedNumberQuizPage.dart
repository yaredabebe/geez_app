import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fidel/service/geez_number_generator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AdvancedNumberQuizPage extends StatefulWidget {
  const AdvancedNumberQuizPage({super.key});

  @override
  State<AdvancedNumberQuizPage> createState() => _AdvancedNumberQuizPageState();
}

class _AdvancedNumberQuizPageState extends State<AdvancedNumberQuizPage>
    with TickerProviderStateMixin {
  List<GeezNumber> _geezNumbers = [];
  List<AdvancedQuizQuestion> _questions = [];
  List<UserAnswer> _userAnswers = [];

  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _quizCompleted = false;
  String? _selectedAnswer;
  bool _answered = false;

  late AnimationController _animationController;
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late AnimationController _timerController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _timerAnimation;

  int _totalQuestions = 10;
  String _difficulty = 'Medium';
  String _questionType = 'Mixed';
  bool _quizStarted = false;
  int _timePerQuestion = 30;
  int _timeRemaining = 30;
  Timer? _timer;
  bool _isTimeUp = false;

  final List<String> _difficultyLevels = ['Easy', 'Medium', 'Hard', 'Expert'];
  final List<String> _questionTypes = [
    'Symbol to Number',
    'Number to Symbol',
    'Mixed',
    'Audio Challenge',
  ];

  // ── Color palette (same base as beginner, amber accent for advanced) ─────────
  static const Color _primary   = Color(0xFF1A1A2E);
  static const Color _accent    = Color(0xFFFF9A3C); // warm amber — advanced tier
  static const Color _accentAlt = Color(0xFFFF6B35); // deeper orange highlight
  static const Color _gold      = Color(0xFFFFD700);
  static const Color _teal      = Color(0xFF16213E);
  static const Color _cardBg    = Color(0xFF0F3460);
  static const Color _softWhite = Color(0xFFF5F0E8);
  static const Color _green     = Color(0xFF4CAF50);
  static const Color _red       = Color(0xFFE94560);

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600));
    _pulseController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _slideController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 500));
    _timerController = AnimationController(vsync: this);

    _fadeAnimation  = CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06)
        .animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _slideAnimation = Tween<Offset>(begin: const Offset(0.3, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    _timerAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(_timerController);

    _loadGeezNumbers();
    _animationController.forward();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    _pulseController.dispose();
    _slideController.dispose();
    _timerController.dispose();
    super.dispose();
  }

  void _loadGeezNumbers() {
    _geezNumbers = GeezNumberService.generateRange(1, 1000);
  }

  // ── Quiz lifecycle ────────────────────────────────────────────────────────────

  void _startQuiz() {
    setState(() {
      _quizStarted = true;
      _generateQuestions();
      _currentQuestionIndex = 0;
      _score = 0;
      _quizCompleted = false;
      _userAnswers.clear();
    });
    _animationController.forward(from: 0);
    _slideController.forward(from: 0);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timeRemaining = _timePerQuestion;
    _isTimeUp = false;
    _timerController.duration = Duration(seconds: _timePerQuestion);
    _timerController.forward(from: 0);

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_timeRemaining > 0 && !_answered && !_quizCompleted) {
        setState(() => _timeRemaining--);
      } else if (_timeRemaining == 0 && !_answered && !_quizCompleted) {
        _isTimeUp = true;
        t.cancel();
        _handleTimeUp();
      }
    });
  }

  void _handleTimeUp() {
    if (_answered || _quizCompleted) return;
    setState(() { _answered = true; _isTimeUp = true; });

    _userAnswers.add(UserAnswer(
      questionNumber: _questions[_currentQuestionIndex].number,
      userAnswer: 'Time Up',
      correctAnswer: _questions[_currentQuestionIndex].correctAnswer,
      isCorrect: false,
      geezName: _questions[_currentQuestionIndex].geezName,
    ));

    Future.delayed(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      if (_currentQuestionIndex + 1 < _questions.length) {
        _nextQuestion();
      } else {
        _completeQuiz();
      }
    });
  }

  void _generateQuestions() {
    _questions.clear();
    final random = Random();
    final List<GeezNumber> shuffled = List.from(_geezNumbers)..shuffle(random);
    final List<GeezNumber> selected = [];

    for (int i = 0; selected.length < _totalQuestions && i < shuffled.length * 3; i++) {
      final n = shuffled[random.nextInt(shuffled.length)];
      bool keep = false;
      switch (_difficulty) {
        case 'Easy':   keep = n.number <= 100; break;
        case 'Medium': keep = n.number <= 500; break;
        case 'Hard':   keep = n.number >= 100 && n.number <= 1000; break;
        case 'Expert': keep = n.number >= 500; break;
        default:       keep = true;
      }
      if (keep && !selected.any((s) => s.number == n.number)) selected.add(n);
    }

    for (var number in selected) {
      String type = _questionType;
      if (type == 'Mixed') {
        const types = ['Symbol to Number', 'Number to Symbol', 'Audio Challenge'];
        type = types[random.nextInt(types.length)];
      }
      _questions.add(_createQuestion(number, type, random));
    }
  }

  AdvancedQuizQuestion _createQuestion(GeezNumber number, String type, Random random) {
    switch (type) {
      case 'Symbol to Number':
        return AdvancedQuizQuestion(
          questionText: 'What number is this Ge\'ez symbol?',
          number: number.number,
          correctAnswer: number.number.toString(),
          options: _generateNumberOptions(number.number, random),
          geezSymbol: number.symbol,
          geezName: number.name,
          questionType: type,
        );
      case 'Number to Symbol':
        return AdvancedQuizQuestion(
          questionText: 'Select the Ge\'ez symbol for ${number.number}',
          number: number.number,
          correctAnswer: number.symbol,
          options: _generateSymbolOptions(number.symbol, random),
          geezSymbol: number.symbol,
          geezName: number.name,
          questionType: type,
        );
      case 'Audio Challenge':
        return AdvancedQuizQuestion(
          questionText: 'Tap the speaker, then choose the symbol',
          number: number.number,
          correctAnswer: number.symbol,
          options: _generateSymbolOptions(number.symbol, random),
          geezSymbol: number.symbol,
          geezName: number.name,
          questionType: type,
        );
      default:
        return AdvancedQuizQuestion(
          questionText: 'Select the correct answer',
          number: number.number,
          correctAnswer: number.symbol,
          options: _generateSymbolOptions(number.symbol, random),
          geezSymbol: number.symbol,
          geezName: number.name,
          questionType: 'Number to Symbol',
        );
    }
  }

  List<String> _generateNumberOptions(int correct, Random random) {
  final Set<int> opts = {correct};

  while (opts.length < 4) {
    int off = random.nextInt(50) + 1;
    int w = correct + (random.nextBool() ? off : -off);
    w = w.clamp(1, 1000);
    opts.add(w);
  }

  return opts
      .map((e) => e.toString())
      .toList()
    ..shuffle(random);
}

  List<String> _generateSymbolOptions(String correct, Random random) {
    final allSymbols = _geezNumbers.map((e) => e.symbol).toList();
    final Set<String> opts = {correct};
    while (opts.length < 4) {
      opts.add(allSymbols[random.nextInt(allSymbols.length)]);
    }
    return opts.toList()..shuffle(random);
  }

  void _checkAnswer(String selected) {
    if (_answered) return;
    _timer?.cancel();
    _timerController.stop();

    final isCorrect = selected == _questions[_currentQuestionIndex].correctAnswer;
    setState(() {
      _answered = true;
      _selectedAnswer = selected;
      if (isCorrect) _score++;
      _userAnswers.add(UserAnswer(
        questionNumber: _questions[_currentQuestionIndex].number,
        userAnswer: selected,
        correctAnswer: _questions[_currentQuestionIndex].correctAnswer,
        isCorrect: isCorrect,
        geezName: _questions[_currentQuestionIndex].geezName,
      ));
    });

    Future.delayed(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      if (_currentQuestionIndex + 1 < _questions.length) {
        _nextQuestion();
      } else {
        _completeQuiz();
      }
    });
  }

  void _nextQuestion() {
    setState(() {
      _currentQuestionIndex++;
      _selectedAnswer = null;
      _answered = false;
      _isTimeUp = false;
    });
    _animationController.forward(from: 0);
    _slideController.forward(from: 0);
    _startTimer();
  }

  Future<void> _completeQuiz() async {
    _timer?.cancel();
    final pct = (_score / _totalQuestions) * 100;
    setState(() => _quizCompleted = true);
    await _saveQuizResult(pct, pct >= 70);
    _animationController.forward(from: 0);
  }

  Future<void> _saveQuizResult(double pct, bool passed) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final result = AdvancedQuizResult(
        date: DateTime.now(), score: _score, totalQuestions: _totalQuestions,
        percentage: pct, passed: passed, difficulty: _difficulty,
        questionType: _questionType, answers: List.from(_userAnswers),
      );

      List<String> existing = prefs.getStringList('advanced_quiz_results') ?? [];
      existing.add(jsonEncode(result.toJson()));
      if (existing.length > 20) existing = existing.sublist(existing.length - 20);
      await prefs.setStringList('advanced_quiz_results', existing);

      final best = prefs.getDouble('advanced_best_score') ?? 0.0;
      if (pct > best) await prefs.setDouble('advanced_best_score', pct);
      final total = prefs.getInt('advanced_total_quizzes') ?? 0;
      await prefs.setInt('advanced_total_quizzes', total + 1);
    } catch (e) {
      debugPrint('Error saving: $e');
    }
  }

  void _resetQuiz() {
    _timer?.cancel();
    setState(() {
      _quizStarted = false;
      _quizCompleted = false;
      _currentQuestionIndex = 0;
      _score = 0;
      _selectedAnswer = null;
      _answered = false;
      _userAnswers.clear();
      _isTimeUp = false;
    });
    _animationController.forward(from: 0);
  }

  // ── Back navigation ───────────────────────────────────────────────────────────

  Future<bool> _onWillPop() async {
    if (_quizStarted && !_quizCompleted) {
      final exit = await _showExitDialog();
      if (exit == true) _timer?.cancel();
      return exit ?? false;
    }
    if (_quizCompleted) { _resetQuiz(); return false; }
    return true;
  }

  Future<bool?> _showExitDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: _teal,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _accent.withOpacity(0.4), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, color: _gold, size: 48),
              const SizedBox(height: 16),
              const Text('Leave Quiz?', style: TextStyle(
                color: _softWhite, fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Text('Your current progress will be lost.',
                style: TextStyle(color: _softWhite.withOpacity(0.6), fontSize: 14),
                textAlign: TextAlign.center),
              const SizedBox(height: 28),
              Row(children: [
                Expanded(child: _outlineBtn('Keep Going', Colors.white38,
                    () => Navigator.pop(ctx, false))),
                const SizedBox(width: 12),
                Expanded(child: _solidBtn('Exit', _red,
                    () => Navigator.pop(ctx, true))),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: _primary,
        body: Stack(
          children: [
            Positioned(top: -80, right: -60,
              child: _bgCircle(220, _accent.withOpacity(0.06))),
            Positioned(bottom: -100, left: -80,
              child: _bgCircle(280, _cardBg.withOpacity(0.6))),
            Positioned(top: 160, left: -40,
              child: _bgCircle(140, _accentAlt.withOpacity(0.04))),
            SafeArea(
              child: !_quizStarted
                  ? _buildStartScreen()
                  : _quizCompleted
                      ? _buildResultScreen()
                      : _buildQuizScreen(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bgCircle(double size, Color color) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color));

  // ── Start screen ──────────────────────────────────────────────────────────────

  Widget _buildStartScreen() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              _backBtn(() => Navigator.maybePop(context)),
              const Spacer(),
              _difficultyBadge(),
            ]),
            const SizedBox(height: 36),

            // Hero icon
            Center(
              child: ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 140, height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [_accent.withOpacity(0.9), _cardBg]),
                    boxShadow: [BoxShadow(
                      color: _accent.withOpacity(0.35), blurRadius: 40, spreadRadius: 8)],
                  ),
                  child: const Center(
                    child: Icon(Icons.auto_awesome_rounded,
                      size: 60, color: Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            const Text('Geez Numbers', style: TextStyle(
              color: _softWhite, fontSize: 34, fontWeight: FontWeight.w800,
              letterSpacing: -0.5, height: 1.1)),
            Text('Advanced Quiz', style: TextStyle(
              color: _accent, fontSize: 20, fontWeight: FontWeight.w600,
              letterSpacing: 1.5)),
            const SizedBox(height: 10),
            Text('Numbers 1–1000 · Timed · $_questionType',
              style: TextStyle(
                color: _softWhite.withOpacity(0.55), fontSize: 15, height: 1.6)),
            const SizedBox(height: 32),

            // Stat cards
            Row(children: [
              Expanded(child: _statCard(Icons.format_list_numbered_rounded,
                '$_totalQuestions', 'Questions', _gold)),
              const SizedBox(width: 12),
              Expanded(child: _statCard(Icons.timer_rounded,
                '${_timePerQuestion}s', 'Per Q', _accent)),
              const SizedBox(width: 12),
              Expanded(child: _statCard(Icons.emoji_events_rounded,
                '70%', 'To Pass', const Color(0xFF4ECDC4))),
            ]),
            const SizedBox(height: 36),

            // Start button
            SizedBox(
              width: double.infinity, height: 58,
              child: ElevatedButton(
                onPressed: _startQuiz,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent, foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18))),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Begin Advanced Quiz', style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Center(
              child: TextButton.icon(
                onPressed: _showSettings,
                icon: Icon(Icons.tune_rounded,
                  color: _softWhite.withOpacity(0.5), size: 18),
                label: Text('Customize Quiz',
                  style: TextStyle(color: _softWhite.withOpacity(0.5), fontSize: 13)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _statCard(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: _teal,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1)),
      child: Column(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(
          color: color, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(
          color: _softWhite.withOpacity(0.45), fontSize: 11, letterSpacing: 0.5)),
      ]),
    );
  }

  Widget _difficultyBadge() {
    final colors = {
      'Easy': const Color(0xFF4ECDC4),
      'Medium': _accent,
      'Hard': _accentAlt,
      'Expert': _red,
    };
    final c = colors[_difficulty] ?? _accent;
    return GestureDetector(
      onTap: _showSettings,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: c.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.withOpacity(0.4))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 7, height: 7,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(_difficulty, style: TextStyle(
            color: c, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  // ── Quiz screen ───────────────────────────────────────────────────────────────

  Widget _buildQuizScreen() {
    final question = _questions[_currentQuestionIndex];
    final timerDanger = _timeRemaining <= 10;

    return Column(children: [
      // Top bar
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Row(children: [
          _backBtn(() async {
            final exit = await _showExitDialog();
            if (exit == true && mounted) Navigator.pop(context);
          }),
          const Spacer(),
          // Timer pill
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: timerDanger ? _red.withOpacity(0.2) : _cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: timerDanger ? _red.withOpacity(0.6) : Colors.transparent)),
            child: Row(children: [
              Icon(Icons.timer_rounded,
                color: timerDanger ? _red : _softWhite.withOpacity(0.6), size: 15),
              const SizedBox(width: 5),
              Text('$_timeRemaining s',
                style: TextStyle(
                  color: timerDanger ? _red : _softWhite,
                  fontWeight: FontWeight.w700, fontSize: 14)),
            ]),
          ),
          const SizedBox(width: 10),
          // Score pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _cardBg, borderRadius: BorderRadius.circular(20)),
            child: Row(children: [
              const Icon(Icons.star_rounded, color: _gold, size: 15),
              const SizedBox(width: 5),
              Text('$_score pts', style: const TextStyle(
                color: _softWhite, fontWeight: FontWeight.w700, fontSize: 14)),
            ]),
          ),
        ]),
      ),

      // Progress
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Question ${_currentQuestionIndex + 1}',
              style: TextStyle(
                color: _softWhite.withOpacity(0.5), fontSize: 13, fontWeight: FontWeight.w500)),
            Text('${_currentQuestionIndex + 1} / ${_questions.length}',
              style: TextStyle(color: _softWhite.withOpacity(0.5), fontSize: 13)),
          ]),
          const SizedBox(height: 10),
          // Quiz progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / _questions.length,
              backgroundColor: _cardBg,
              valueColor: AlwaysStoppedAnimation<Color>(_accent),
              minHeight: 6)),
          const SizedBox(height: 6),
          // Timer progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: AnimatedBuilder(
              animation: _timerAnimation,
              builder: (_, __) => LinearProgressIndicator(
                value: _timeRemaining / _timePerQuestion,
                backgroundColor: _cardBg,
                valueColor: AlwaysStoppedAnimation<Color>(
                  timerDanger ? _red : _accent.withOpacity(0.5)),
                minHeight: 3))),
        ]),
      ),

      const SizedBox(height: 20),

      // Content
      Expanded(
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(children: [
                // Question card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                  decoration: BoxDecoration(
                    color: _teal,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: _accent.withOpacity(0.2), width: 1)),
                  child: Column(children: [
                    // Type badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: _accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12)),
                      child: Text(question.questionType,
                        style: TextStyle(color: _accent, fontSize: 11,
                          fontWeight: FontWeight.w600, letterSpacing: 0.5))),
                    const SizedBox(height: 16),
                    Text(question.questionText,
                      style: TextStyle(color: _softWhite.withOpacity(0.6),
                        fontSize: 14, letterSpacing: 0.2),
                      textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    _buildQuestionDisplay(question),
                  ]),
                ),
                const SizedBox(height: 20),

                // Time-up banner
                if (_isTimeUp)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    decoration: BoxDecoration(
                      color: _red.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _red.withOpacity(0.4))),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.timer_off_rounded, color: _red, size: 18),
                      const SizedBox(width: 8),
                      Text("Time's up!", style: TextStyle(
                        color: _red, fontWeight: FontWeight.w700, fontSize: 14)),
                    ])),

                // Options
                _buildOptions(question),
              ]),
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _buildQuestionDisplay(AdvancedQuizQuestion question) {
    switch (question.questionType) {
      case 'Symbol to Number':
        return _questionCircle(
          child: Text(question.geezSymbol,
            style: const TextStyle(
              fontSize: 42, fontWeight: FontWeight.w700, color: Colors.white)));

      case 'Number to Symbol':
        return _questionCircle(
          child: Text(question.number.toString(),
            style: const TextStyle(
              fontSize: 42, fontWeight: FontWeight.w900, color: Colors.white)));

      case 'Audio Challenge':
        return Column(children: [
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('🔊 ${question.geezName}'),
                backgroundColor: _cardBg,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              ));
            },
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_accent.withOpacity(0.9), _accentAlt]),
                boxShadow: [BoxShadow(
                  color: _accent.withOpacity(0.3), blurRadius: 24, spreadRadius: 4)]),
              child: const Icon(Icons.volume_up_rounded,
                size: 44, color: Colors.white))),
          const SizedBox(height: 10),
          Text('Tap to hear the pronunciation',
            style: TextStyle(color: _softWhite.withOpacity(0.45), fontSize: 12)),
        ]);

      default:
        return _questionCircle(
          child: Text(question.number.toString(),
            style: const TextStyle(
              fontSize: 42, fontWeight: FontWeight.w900, color: Colors.white)));
    }
  }

  Widget _questionCircle({required Widget child}) {
    return Container(
      width: 110, height: 110,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _primary,
        border: Border.all(color: _accent.withOpacity(0.5), width: 2),
        boxShadow: [BoxShadow(
          color: _accent.withOpacity(0.2), blurRadius: 24, spreadRadius: 4)]),
      child: Center(child: child));
  }

  Widget _buildOptions(AdvancedQuizQuestion question) {
    final isSymbolAnswer = question.questionType != 'Symbol to Number';
    if (isSymbolAnswer) {
      // 2×2 grid for symbol answers
      return GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 14, mainAxisSpacing: 14,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.4,
        children: question.options.map((o) => _optionTile(o, question)).toList());
    } else {
      // Vertical list for number answers
      return Column(
        children: question.options.map((o) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _numberOptionTile(o, question))).toList());
    }
  }

  Widget _optionTile(String option, AdvancedQuizQuestion question) {
    final isSelected = _selectedAnswer == option;
    final isCorrect  = option == question.correctAnswer;
    Color bg = _teal;
    Color border = Colors.white.withOpacity(0.08);
    Color text = _softWhite;
    Widget? badge;

    if (_answered || _isTimeUp) {
      if (isSelected && isCorrect) {
        bg = const Color(0xFF1A3A2A); border = _green; text = _green;
        badge = Icon(Icons.check_circle_rounded, color: _green, size: 20);
      } else if (isSelected && !isCorrect) {
        bg = const Color(0xFF3A1A1A); border = _red; text = _red;
        badge = Icon(Icons.cancel_rounded, color: _red, size: 20);
      } else if (!isSelected && isCorrect) {
        bg = const Color(0xFF1A3A2A).withOpacity(0.6);
        border = _green.withOpacity(0.5); text = _green.withOpacity(0.8);
      }
    }

    return GestureDetector(
      onTap: (_answered || _isTimeUp) ? null : () => _checkAnswer(option),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border, width: 1.5),
          boxShadow: isSelected ? [BoxShadow(
            color: border.withOpacity(0.3), blurRadius: 16, spreadRadius: 2)] : []),
        child: Stack(children: [
          Center(child: Text(option,
            style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: text))),
          if (badge != null) Positioned(top: 10, right: 10, child: badge),
        ]),
      ),
    );
  }

  Widget _numberOptionTile(String option, AdvancedQuizQuestion question) {
    final isSelected = _selectedAnswer == option;
    final isCorrect  = option == question.correctAnswer;
    Color bg = _teal;
    Color border = Colors.white.withOpacity(0.08);
    Color text = _softWhite;

    if (_answered || _isTimeUp) {
      if (isSelected && isCorrect)  { bg = const Color(0xFF1A3A2A); border = _green; text = _green; }
      else if (isSelected)           { bg = const Color(0xFF3A1A1A); border = _red;   text = _red;   }
      else if (isCorrect)            { bg = const Color(0xFF1A3A2A).withOpacity(0.6);
                                       border = _green.withOpacity(0.5); text = _green.withOpacity(0.8); }
    }

    return GestureDetector(
      onTap: (_answered || _isTimeUp) ? null : () => _checkAnswer(option),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        height: 58,
        decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: 1.5),
          boxShadow: isSelected ? [BoxShadow(
            color: border.withOpacity(0.3), blurRadius: 12, spreadRadius: 1)] : []),
        child: Row(children: [
          const SizedBox(width: 20),
          Text(option, style: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w700, color: text)),
          const Spacer(),
          if ((_answered || _isTimeUp) && isCorrect)
            Padding(padding: const EdgeInsets.only(right: 16),
              child: Icon(Icons.check_circle_rounded, color: _green, size: 20)),
          if ((_answered || _isTimeUp) && isSelected && !isCorrect)
            Padding(padding: const EdgeInsets.only(right: 16),
              child: Icon(Icons.cancel_rounded, color: _red, size: 20)),
        ]),
      ),
    );
  }

  // ── Result screen ─────────────────────────────────────────────────────────────

  Widget _buildResultScreen() {
    final pct    = (_score / _totalQuestions) * 100;
    final passed = pct >= 70;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(children: [
          Align(alignment: Alignment.centerLeft,
            child: _backBtn(_resetQuiz)),
          const SizedBox(height: 24),

          // Trophy
          Center(
            child: Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: passed
                  ? [_gold.withOpacity(0.9), _cardBg]
                  : [_accent.withOpacity(0.7), _cardBg]),
                boxShadow: [BoxShadow(
                  color: passed ? _gold.withOpacity(0.3) : _accent.withOpacity(0.3),
                  blurRadius: 40, spreadRadius: 8)]),
              child: Icon(passed ? Icons.emoji_events_rounded : Icons.psychology_rounded,
                size: 56, color: Colors.white))),
          const SizedBox(height: 24),

          Text(passed ? 'Excellent Work!' : 'Keep Practicing!',
            style: const TextStyle(color: _softWhite, fontSize: 28,
              fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          const SizedBox(height: 6),
          Text('Advanced Level · $_difficulty · $_questionType',
            style: TextStyle(color: _softWhite.withOpacity(0.45), fontSize: 13),
            textAlign: TextAlign.center),
          const SizedBox(height: 28),

          // Score card
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: _teal,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: (passed ? _gold : _accent).withOpacity(0.25), width: 1)),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _resultStat('$_score', 'Correct',
                  Icons.check_circle_outline_rounded, _green),
                Container(width: 1, height: 50, color: Colors.white.withOpacity(0.1)),
                _resultStat('${_totalQuestions - _score}', 'Wrong',
                  Icons.highlight_off_rounded, _red),
                Container(width: 1, height: 50, color: Colors.white.withOpacity(0.1)),
                _resultStat('${pct.toStringAsFixed(0)}%', 'Score',
                  Icons.trending_up_rounded, _gold),
              ]),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: pct / 100,
                  backgroundColor: _primary,
                  valueColor: AlwaysStoppedAnimation<Color>(passed ? _gold : _accent),
                  minHeight: 10)),
              const SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: passed ? _green.withOpacity(0.15) : _red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12)),
                  child: Text(passed ? '✓ PASSED' : '✗ FAILED',
                    style: TextStyle(
                      color: passed ? _green : _red,
                      fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 1))),
              ]),
            ]),
          ),
          const SizedBox(height: 20),

          // Answer review
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _teal, borderRadius: BorderRadius.circular(24)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Review', style: TextStyle(
                color: _softWhite.withOpacity(0.5), fontSize: 12,
                fontWeight: FontWeight.w600, letterSpacing: 1.5)),
              const SizedBox(height: 12),
              ..._userAnswers.map((a) => _reviewRow(a)),
            ]),
          ),
          const SizedBox(height: 24),

          Row(children: [
            Expanded(child: _solidBtn('Try Again', _accent, _resetQuiz)),
            const SizedBox(width: 14),
            Expanded(child: _outlineBtn('View Progress', Colors.white24, _viewProgress)),
          ]),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  Widget _reviewRow(UserAnswer ans) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(shape: BoxShape.circle,
            color: ans.isCorrect ? _green.withOpacity(0.15) : _red.withOpacity(0.15)),
          child: Icon(ans.isCorrect ? Icons.check_rounded : Icons.close_rounded,
            color: ans.isCorrect ? _green : _red, size: 16)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Number ${ans.questionNumber}',
            style: const TextStyle(color: _softWhite, fontSize: 13)),
          if (ans.userAnswer == 'Time Up')
            Text('⏱ Timed out',
              style: TextStyle(color: _red.withOpacity(0.7), fontSize: 11)),
        ])),
        Text(ans.isCorrect ? ans.userAnswer : ans.correctAnswer,
          style: TextStyle(
            color: ans.isCorrect ? _green : _red,
            fontSize: 18, fontWeight: FontWeight.w700)),
        if (!ans.isCorrect && ans.userAnswer != 'Time Up') ...[
          const SizedBox(width: 6),
          Icon(Icons.arrow_forward_rounded, color: Colors.white30, size: 12),
          const SizedBox(width: 6),
          Text(ans.correctAnswer,
            style: const TextStyle(color: _green, fontSize: 18, fontWeight: FontWeight.w700)),
        ],
      ]),
    );
  }

  Widget _resultStat(String value, String label, IconData icon, Color color) {
    return Column(children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(height: 6),
      Text(value, style: TextStyle(
        color: color, fontSize: 24, fontWeight: FontWeight.w800)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(
        color: _softWhite.withOpacity(0.4), fontSize: 11, letterSpacing: 0.5)),
    ]);
  }

  // ── Settings dialog ───────────────────────────────────────────────────────────

  void _showSettings() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _teal,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.08), width: 1)),
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Quiz Settings', style: TextStyle(
                  color: _softWhite, fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 20),

                // Difficulty
                Text('Difficulty', style: TextStyle(
                  color: _softWhite.withOpacity(0.5), fontSize: 12,
                  fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                const SizedBox(height: 10),
                ..._difficultyLevels.map((d) {
                  final colors = {
                    'Easy': const Color(0xFF4ECDC4), 'Medium': _accent,
                    'Hard': _accentAlt, 'Expert': _red };
                  final c = colors[d] ?? _accent;
                  final sel = _difficulty == d;
                  return GestureDetector(
                    onTap: () {
                      setS(() { _difficulty = d; });
                      setState(() {
                        _difficulty = d;
                        switch (d) {
                          case 'Easy':   _totalQuestions = 10; _timePerQuestion = 45; break;
                          case 'Medium': _totalQuestions = 15; _timePerQuestion = 30; break;
                          case 'Hard':   _totalQuestions = 20; _timePerQuestion = 20; break;
                          case 'Expert': _totalQuestions = 25; _timePerQuestion = 15; break;
                        }
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: sel ? c.withOpacity(0.15) : _primary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: sel ? c : Colors.white.withOpacity(0.07), width: 1.5)),
                      child: Row(children: [
                        Container(width: 8, height: 8,
                          decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
                        const SizedBox(width: 10),
                        Text(d, style: TextStyle(
                          color: sel ? c : _softWhite.withOpacity(0.7),
                          fontWeight: sel ? FontWeight.w700 : FontWeight.w500, fontSize: 14)),
                        const Spacer(),
                        Text('${_diffQs(d)}Q · ${_diffTime(d)}s',
                          style: TextStyle(color: _softWhite.withOpacity(0.3), fontSize: 11)),
                        if (sel) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.check_rounded, color: c, size: 16)],
                      ])));
                }),

                const SizedBox(height: 20),
                Text('Question Type', style: TextStyle(
                  color: _softWhite.withOpacity(0.5), fontSize: 12,
                  fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                const SizedBox(height: 10),
                ..._questionTypes.map((t) {
                  final sel = _questionType == t;
                  return GestureDetector(
                    onTap: () { setS(() => _questionType = t);
                                setState(() => _questionType = t); },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: sel ? _accent.withOpacity(0.15) : _primary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: sel ? _accent : Colors.white.withOpacity(0.07), width: 1.5)),
                      child: Row(children: [
                        Icon(_typeIcon(t), color: sel ? _accent : _softWhite.withOpacity(0.4), size: 18),
                        const SizedBox(width: 10),
                        Text(t, style: TextStyle(
                          color: sel ? _accent : _softWhite.withOpacity(0.7),
                          fontWeight: sel ? FontWeight.w700 : FontWeight.w500, fontSize: 14)),
                        if (sel) ...[const Spacer(),
                          Icon(Icons.check_rounded, color: _accent, size: 16)],
                      ])));
                }),

                const SizedBox(height: 20),
                SizedBox(width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent, foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text('Apply', style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15)))),
              ]),
            ),
          ),
        );
      }),
    );
  }

  int _diffQs(String d) {
    switch (d) {
      case 'Easy': return 10; case 'Medium': return 15;
      case 'Hard': return 20; case 'Expert': return 25; default: return 10; }
  }
  int _diffTime(String d) {
    switch (d) {
      case 'Easy': return 45; case 'Medium': return 30;
      case 'Hard': return 20; case 'Expert': return 15; default: return 30; }
  }
  IconData _typeIcon(String t) {
    switch (t) {
      case 'Symbol to Number': return Icons.translate_rounded;
      case 'Number to Symbol': return Icons.text_fields_rounded;
      case 'Mixed':            return Icons.shuffle_rounded;
      case 'Audio Challenge':  return Icons.volume_up_rounded;
      default:                 return Icons.quiz_rounded;
    }
  }

  // ── Shared button widgets ─────────────────────────────────────────────────────

  Widget _backBtn(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42, height: 42,
        decoration: BoxDecoration(
          color: _teal,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: Colors.white.withOpacity(0.08), width: 1)),
        child: const Icon(Icons.arrow_back_ios_new_rounded,
          color: _softWhite, size: 18)));
  }

  Widget _solidBtn(String label, Color color, VoidCallback onPressed) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color, foregroundColor: Colors.white, elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        child: Text(label, style: const TextStyle(
          fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.3))));
  }

  Widget _outlineBtn(String label, Color borderColor, VoidCallback onPressed) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: _softWhite,
          side: BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        child: Text(label, style: const TextStyle(
          fontWeight: FontWeight.w600, fontSize: 15, letterSpacing: 0.3))));
  }

  void _viewProgress() {
    Navigator.push(context,
      MaterialPageRoute(builder: (_) => const AdvancedQuizProgressPage()));
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════════

class AdvancedQuizQuestion {
  final String questionText;
  final int number;
  final String correctAnswer;
  final List<String> options;
  final String geezSymbol;
  final String geezName;
  final String questionType;

  AdvancedQuizQuestion({
    required this.questionText, required this.number,
    required this.correctAnswer, required this.options,
    required this.geezSymbol, required this.geezName,
    required this.questionType,
  });
}

class UserAnswer {
  final int questionNumber;
  final String userAnswer;
  final String correctAnswer;
  final bool isCorrect;
  final String geezName;

  UserAnswer({
    required this.questionNumber, required this.userAnswer,
    required this.correctAnswer, required this.isCorrect,
    required this.geezName,
  });

  Map<String, dynamic> toJson() => {
    'questionNumber': questionNumber, 'userAnswer': userAnswer,
    'correctAnswer': correctAnswer, 'isCorrect': isCorrect, 'geezName': geezName,
  };

  factory UserAnswer.fromJson(Map<String, dynamic> json) => UserAnswer(
    questionNumber: json['questionNumber'], userAnswer: json['userAnswer'],
    correctAnswer: json['correctAnswer'], isCorrect: json['isCorrect'],
    geezName: json['geezName'],
  );
}

class AdvancedQuizResult {
  final DateTime date;
  final int score;
  final int totalQuestions;
  final double percentage;
  final bool passed;
  final String difficulty;
  final String questionType;
  final List<UserAnswer> answers;

  AdvancedQuizResult({
    required this.date, required this.score, required this.totalQuestions,
    required this.percentage, required this.passed, required this.difficulty,
    required this.questionType, required this.answers,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(), 'score': score,
    'totalQuestions': totalQuestions, 'percentage': percentage,
    'passed': passed, 'difficulty': difficulty,
    'questionType': questionType,
    'answers': answers.map((a) => a.toJson()).toList(),
  };

  factory AdvancedQuizResult.fromJson(Map<String, dynamic> json) =>
    AdvancedQuizResult(
      date: DateTime.parse(json['date']), score: json['score'],
      totalQuestions: json['totalQuestions'], percentage: json['percentage'],
      passed: json['passed'], difficulty: json['difficulty'],
      questionType: json['questionType'],
      answers: (json['answers'] as List).map((a) => UserAnswer.fromJson(a)).toList(),
    );
}

// ═══════════════════════════════════════════════════════════════════════════════
// PROGRESS PAGE
// ═══════════════════════════════════════════════════════════════════════════════

class AdvancedQuizProgressPage extends StatefulWidget {
  const AdvancedQuizProgressPage({super.key});

  @override
  State<AdvancedQuizProgressPage> createState() => _AdvancedQuizProgressPageState();
}

class _AdvancedQuizProgressPageState extends State<AdvancedQuizProgressPage> {
  List<AdvancedQuizResult> _results = [];
  double _bestScore = 0;
  int _totalQuizzes = 0;
  bool _isLoading = true;

  static const Color _primary   = Color(0xFF1A1A2E);
  static const Color _accent    = Color(0xFFFF9A3C);
  static const Color _gold      = Color(0xFFFFD700);
  static const Color _teal      = Color(0xFF16213E);
  static const Color _cardBg    = Color(0xFF0F3460);
  static const Color _softWhite = Color(0xFFF5F0E8);
  static const Color _green     = Color(0xFF4CAF50);
  static const Color _red       = Color(0xFFE94560);

  @override
  void initState() { super.initState(); _loadProgress(); }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _bestScore   = prefs.getDouble('advanced_best_score') ?? 0;
      _totalQuizzes = prefs.getInt('advanced_total_quizzes') ?? 0;
    });
    final json = prefs.getStringList('advanced_quiz_results') ?? [];
    setState(() {
      _results = json
        .map((j) => AdvancedQuizResult.fromJson(jsonDecode(j)))
        .toList().reversed.toList();
      _isLoading = false;
    });
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _teal, borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.08), width: 1)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.delete_forever_rounded, color: _red, size: 48),
            const SizedBox(height: 16),
            const Text('Clear All History?', style: TextStyle(
              color: _softWhite, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('This cannot be undone.',
              style: TextStyle(color: _softWhite.withOpacity(0.5), fontSize: 13)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx, false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _softWhite,
                  side: BorderSide(color: Colors.white.withOpacity(0.2)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
                child: const Text('Cancel'))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _red, foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
                child: const Text('Clear'))),
            ]),
          ]),
        ),
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('advanced_quiz_results');
      await prefs.remove('advanced_best_score');
      await prefs.remove('advanced_total_quizzes');
      await _loadProgress();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('History cleared!'),
          backgroundColor: _cardBg,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primary,
      appBar: AppBar(
        backgroundColor: _primary, elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _teal, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _softWhite, size: 16))),
        title: const Text('Advanced Progress', style: TextStyle(
          color: _softWhite, fontWeight: FontWeight.w700, fontSize: 18)),
        actions: [
          if (_results.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: _red),
              onPressed: _clearHistory),
        ],
      ),
      body: _isLoading
        ? Center(child: CircularProgressIndicator(color: _accent))
        : _results.isEmpty
            ? _buildEmptyState()
            : Column(children: [
                _buildStatsSummary(),
                Expanded(child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: _results.length,
                  itemBuilder: (_, i) => _buildResultCard(_results[i]))),
              ]),
    );
  }

  Widget _buildEmptyState() {
    return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.auto_awesome_rounded, size: 72, color: _teal),
        const SizedBox(height: 20),
        const Text('No results yet', style: TextStyle(
          color: _softWhite, fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('Complete the advanced quiz to track progress.',
          style: TextStyle(color: _softWhite.withOpacity(0.4))),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: _accent, foregroundColor: Colors.white, elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          child: const Text('Take a Quiz',
            style: TextStyle(fontWeight: FontWeight.w700))),
      ],
    ));
  }

  Widget _buildStatsSummary() {
    final avg = _results.isNotEmpty
      ? _results.map((r) => r.percentage).reduce((a, b) => a + b) / _results.length
      : 0.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _teal, borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.06), width: 1)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _statItem('${_bestScore.toStringAsFixed(0)}%', 'Best',
          Icons.emoji_events_rounded, _gold),
        Container(width: 1, height: 40, color: Colors.white12),
        _statItem(_totalQuizzes.toString(), 'Total',
          Icons.quiz_rounded, _accent),
        Container(width: 1, height: 40, color: Colors.white12),
        _statItem('${avg.toStringAsFixed(0)}%', 'Average',
          Icons.trending_up_rounded, const Color(0xFF4ECDC4)),
      ]),
    );
  }

  Widget _statItem(String value, String label, IconData icon, Color color) {
    return Column(children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(height: 6),
      Text(value, style: TextStyle(
        color: color, fontSize: 22, fontWeight: FontWeight.w800)),
      Text(label, style: TextStyle(
        color: _softWhite.withOpacity(0.4), fontSize: 11, letterSpacing: 0.5)),
    ]);
  }

  Widget _buildResultCard(AdvancedQuizResult result) {
    final diffColors = {
      'Easy': const Color(0xFF4ECDC4), 'Medium': _accent,
      'Hard': const Color(0xFFFF6B35), 'Expert': _red };
    final dc = diffColors[result.difficulty] ?? _accent;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _teal, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06), width: 1)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(shape: BoxShape.circle,
              color: result.passed ? _green.withOpacity(0.15) : _red.withOpacity(0.15)),
            child: Icon(result.passed ? Icons.check_rounded : Icons.close_rounded,
              color: result.passed ? _green : _red, size: 20)),
          title: Text(
            '${result.date.day}/${result.date.month}/${result.date.year}',
            style: const TextStyle(
              color: _softWhite, fontWeight: FontWeight.w600, fontSize: 14)),
          subtitle: Text(
            '${result.score}/${result.totalQuestions} · ${result.percentage.toStringAsFixed(0)}% · ${result.questionType}',
            style: TextStyle(color: _softWhite.withOpacity(0.4), fontSize: 11)),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: dc.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: dc.withOpacity(0.3))),
            child: Text(result.difficulty, style: TextStyle(
              color: dc, fontSize: 11, fontWeight: FontWeight.w700))),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(children: [
                Divider(color: Colors.white.withOpacity(0.06)),
                const SizedBox(height: 4),
                ...result.answers.map((ans) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(children: [
                    Icon(ans.isCorrect
                      ? Icons.check_circle_outline_rounded
                      : Icons.highlight_off_rounded,
                      color: ans.isCorrect ? _green : _red, size: 16),
                    const SizedBox(width: 10),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Number ${ans.questionNumber}',
                        style: TextStyle(
                          color: _softWhite.withOpacity(0.7), fontSize: 13)),
                      if (ans.userAnswer == 'Time Up')
                        Text('Timed out',
                          style: TextStyle(
                            color: _red.withOpacity(0.7), fontSize: 10)),
                    ])),
                    Text(ans.isCorrect ? ans.userAnswer : ans.correctAnswer,
                      style: TextStyle(
                        color: ans.isCorrect ? _green : _red,
                        fontSize: 18, fontWeight: FontWeight.w700)),
                    if (!ans.isCorrect && ans.userAnswer != 'Time Up') ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_rounded,
                        color: Colors.white24, size: 12),
                      const SizedBox(width: 6),
                      Text(ans.correctAnswer,
                        style: const TextStyle(
                          color: _green, fontSize: 18, fontWeight: FontWeight.w700)),
                    ],
                  ]))),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}