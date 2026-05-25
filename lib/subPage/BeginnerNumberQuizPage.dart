import 'package:flutter/material.dart';
import 'package:fidel/service/geez_number_generator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';

class BeginnerNumberQuizPage extends StatefulWidget {
  const BeginnerNumberQuizPage({super.key});

  @override
  State<BeginnerNumberQuizPage> createState() => _BeginnerNumberQuizPageState();
}

class _BeginnerNumberQuizPageState extends State<BeginnerNumberQuizPage>
    with TickerProviderStateMixin {
  final List<GeezNumber> _geezNumbers = [];
  final List<QuizQuestion> _questions = [];
  final List<UserAnswer> _userAnswers = [];

  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _quizCompleted = false;
  String? _selectedAnswer;
  bool _answered = false;
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  int _totalQuestions = 5;
  String _difficulty = 'Easy';
  bool _quizStarted = false;

  // Color palette
  static const Color _primary = Color(0xFF1A1A2E);
  static const Color _accent = Color(0xFFE94560);
  static const Color _gold = Color(0xFFFFD700);
  static const Color _teal = Color(0xFF16213E);
  static const Color _cardBg = Color(0xFF0F3460);
  static const Color _softWhite = Color(0xFFF5F0E8);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _loadGeezNumbers();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _loadGeezNumbers() {
    _geezNumbers.addAll(GeezNumberService.generateRange(1, 10));
  }

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
  }

  void _generateQuestions() {
    _questions.clear();
    final random = Random();
    final List<GeezNumber> shuffledNumbers = List.from(_geezNumbers);
    shuffledNumbers.shuffle(random);

    for (int i = 0; i < _totalQuestions && i < shuffledNumbers.length; i++) {
      final correctNumber = shuffledNumbers[i];
      final List<String> wrongAnswers = [];
      final List<GeezNumber> otherNumbers =
          _geezNumbers.where((n) => n.number != correctNumber.number).toList();

      otherNumbers.shuffle(random);
      for (int j = 0; j < 3 && j < otherNumbers.length; j++) {
        wrongAnswers.add(otherNumbers[j].symbol);
      }
      while (wrongAnswers.length < 3) {
        wrongAnswers.add('፩');
      }

      final options = [correctNumber.symbol, ...wrongAnswers];
      options.shuffle(random);

      _questions.add(QuizQuestion(
        questionNumber: correctNumber.number,
        correctAnswer: correctNumber.symbol,
        options: options,
        geezName: correctNumber.name,
      ));
    }
  }

  void _checkAnswer(String selectedOption) {
    if (_answered) return;

    setState(() {
      _answered = true;
      _selectedAnswer = selectedOption;
      final isCorrect =
          selectedOption == _questions[_currentQuestionIndex].correctAnswer;
      if (isCorrect) _score++;

      _userAnswers.add(UserAnswer(
        questionNumber: _questions[_currentQuestionIndex].questionNumber,
        userAnswer: selectedOption,
        correctAnswer: _questions[_currentQuestionIndex].correctAnswer,
        isCorrect: isCorrect,
        geezName: _questions[_currentQuestionIndex].geezName,
      ));
    });

    Future.delayed(const Duration(milliseconds: 1600), () {
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
    });
    _animationController.forward(from: 0);
    _slideController.forward(from: 0);
  }

  Future<void> _completeQuiz() async {
    final percentage = (_score / _totalQuestions) * 100;
    final passed = percentage >= 60;
    setState(() => _quizCompleted = true);
    await _saveQuizResult(percentage, passed);
    _animationController.forward(from: 0);
  }

  Future<void> _saveQuizResult(double percentage, bool passed) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final quizResult = QuizResult(
        date: now,
        score: _score,
        totalQuestions: _totalQuestions,
        percentage: percentage,
        passed: passed,
        difficulty: _difficulty,
        answers: List.from(_userAnswers),
      );

      List<String> existingResults =
          prefs.getStringList('quiz_results') ?? [];
      existingResults.add(jsonEncode(quizResult.toJson()));
      if (existingResults.length > 20) {
        existingResults =
            existingResults.sublist(existingResults.length - 20);
      }
      await prefs.setStringList('quiz_results', existingResults);

      final bestScore = prefs.getDouble('best_score') ?? 0.0;
      if (percentage > bestScore) {
        await prefs.setDouble('best_score', percentage);
      }
      final totalQuizzes = prefs.getInt('total_quizzes') ?? 0;
      await prefs.setInt('total_quizzes', totalQuizzes + 1);
    } catch (e) {
      debugPrint('Error saving quiz result: $e');
    }
  }

  void _resetQuiz() {
    setState(() {
      _quizStarted = false;
      _quizCompleted = false;
      _currentQuestionIndex = 0;
      _score = 0;
      _selectedAnswer = null;
      _answered = false;
      _userAnswers.clear();
    });
    _animationController.forward(from: 0);
  }

  // ─── BACK NAVIGATION ────────────────────────────────────────────────────────

  /// Called when user presses the system/hardware back button or our custom back.
  Future<bool> _onWillPop() async {
    if (_quizStarted && !_quizCompleted) {
      // Mid-quiz → confirm exit
      final exit = await _showExitDialog();
      return exit ?? false;
    }
    if (_quizCompleted) {
      // Results screen → go back to start screen instead of popping the route
      _resetQuiz();
      return false;
    }
    // Start screen → pop normally
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
              const Icon(Icons.warning_amber_rounded,
                  color: _gold, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Leave Quiz?',
                style: TextStyle(
                  color: _softWhite,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Your current progress will be lost.',
                style: TextStyle(
                  color: _softWhite.withOpacity(0.6),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: _outlineButton('Keep Going', Colors.white38,
                        () => Navigator.pop(ctx, false)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _solidButton('Exit', _accent,
                        () => Navigator.pop(ctx, true)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── BUILD ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: _primary,
        body: Stack(
          children: [
            // Decorative background circles
            Positioned(
              top: -80,
              right: -60,
              child: _bgCircle(220, _accent.withOpacity(0.07)),
            ),
            Positioned(
              bottom: -100,
              left: -80,
              child: _bgCircle(280, _cardBg.withOpacity(0.6)),
            ),
            Positioned(
              top: 160,
              left: -40,
              child: _bgCircle(140, _accent.withOpacity(0.04)),
            ),
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
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );

  // ─── START SCREEN ────────────────────────────────────────────────────────────

  Widget _buildStartScreen() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with back button
            Row(
              children: [
                _backIconButton(() => Navigator.maybePop(context)),
                const Spacer(),
                _difficultyChip(),
              ],
            ),
            const SizedBox(height: 36),

            // Hero symbol display
            Center(
              child: ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _accent.withOpacity(0.9),
                        _cardBg,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _accent.withOpacity(0.35),
                        blurRadius: 40,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      '፩',
                      style: TextStyle(
                        fontSize: 64,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Title
            const Text(
              'Geez Numbers',
              style: TextStyle(
                color: _softWhite,
                fontSize: 34,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                height: 1.1,
              ),
            ),
            const Text(
              'Beginner Quiz',
              style: TextStyle(
                color: _accent,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Match Arabic numbers 1–10 with their\nGe\'ez script symbols.',
              style: TextStyle(
                color: _softWhite.withOpacity(0.55),
                fontSize: 15,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),

            // Info cards row
            Row(
              children: [
                Expanded(
                  child: _infoCard(
                    Icons.format_list_numbered_rounded,
                    '$_totalQuestions',
                    'Questions',
                    _gold,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _infoCard(
                    Icons.emoji_events_rounded,
                    '60%',
                    'To Pass',
                    _accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _infoCard(
                    Icons.all_inclusive_rounded,
                    '∞',
                    'Attempts',
                    const Color(0xFF4ECDC4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 36),

            // Start button
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: _startQuiz,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Begin Quiz',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Settings row
            Center(
              child: TextButton.icon(
                onPressed: _changeDifficulty,
                icon: Icon(Icons.tune_rounded,
                    color: _softWhite.withOpacity(0.5), size: 18),
                label: Text(
                  'Difficulty: $_difficulty',
                  style: TextStyle(
                    color: _softWhite.withOpacity(0.5),
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: _teal,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: _softWhite.withOpacity(0.45),
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _difficultyChip() {
    Color chipColor;
    switch (_difficulty) {
      case 'Hard':
        chipColor = _accent;
        break;
      case 'Medium':
        chipColor = _gold;
        break;
      default:
        chipColor = const Color(0xFF4ECDC4);
    }
    return GestureDetector(
      onTap: _changeDifficulty,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: chipColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: chipColor.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                  color: chipColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              _difficulty,
              style: TextStyle(
                color: chipColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── QUIZ SCREEN ─────────────────────────────────────────────────────────────

  Widget _buildQuizScreen() {
    final question = _questions[_currentQuestionIndex];

    return Column(
      children: [
        // Top bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              _backIconButton(() async {
                final exit = await _showExitDialog();
                if (exit == true && mounted) Navigator.pop(context);
              }),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: _gold, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '$_score pts',
                      style: const TextStyle(
                        color: _softWhite,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Progress section
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question ${_currentQuestionIndex + 1}',
                    style: TextStyle(
                      color: _softWhite.withOpacity(0.5),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${_currentQuestionIndex + 1} / ${_questions.length}',
                    style: TextStyle(
                      color: _softWhite.withOpacity(0.5),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (_currentQuestionIndex + 1) / _questions.length,
                  backgroundColor: _cardBg,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(_accent),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Question card
        Expanded(
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  children: [
                    // Number display card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      decoration: BoxDecoration(
                        color: _teal,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: _accent.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'What is the Ge\'ez symbol for',
                            style: TextStyle(
                              color: _softWhite.withOpacity(0.45),
                              fontSize: 13,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _primary,
                              border: Border.all(
                                  color: _accent.withOpacity(0.5),
                                  width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: _accent.withOpacity(0.2),
                                  blurRadius: 24,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                question.questionNumber.toString(),
                                style: const TextStyle(
                                  fontSize: 52,
                                  fontWeight: FontWeight.w900,
                                  color: _softWhite,
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '?',
                            style: TextStyle(
                              color: _accent,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Option buttons grid
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.4,
                      children: question.options
                          .map((opt) => _buildOptionTile(opt))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionTile(String option) {
    final bool isSelected = _selectedAnswer == option;
    final bool isCorrect =
        option == _questions[_currentQuestionIndex].correctAnswer;

    Color bgColor = _teal;
    Color borderColor = Colors.white.withOpacity(0.08);
    Color textColor = _softWhite;
    Widget? badge;

    if (_answered) {
      if (isSelected && isCorrect) {
        bgColor = const Color(0xFF1A3A2A);
        borderColor = const Color(0xFF4CAF50);
        textColor = const Color(0xFF4CAF50);
        badge = const Icon(Icons.check_circle_rounded,
            color: Color(0xFF4CAF50), size: 20);
      } else if (isSelected && !isCorrect) {
        bgColor = const Color(0xFF3A1A1A);
        borderColor = _accent;
        textColor = _accent;
        badge =
            Icon(Icons.cancel_rounded, color: _accent, size: 20);
      } else if (!isSelected && isCorrect) {
        bgColor = const Color(0xFF1A3A2A).withOpacity(0.6);
        borderColor = const Color(0xFF4CAF50).withOpacity(0.5);
        textColor = const Color(0xFF4CAF50).withOpacity(0.8);
      }
    }

    return GestureDetector(
      onTap: _answered ? null : () => _checkAnswer(option),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: borderColor.withOpacity(0.3),
                    blurRadius: 16,
                    spreadRadius: 2,
                  )
                ]
              : [],
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                option,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
            if (badge != null)
              Positioned(
                top: 10,
                right: 10,
                child: badge,
              ),
          ],
        ),
      ),
    );
  }

  // ─── RESULT SCREEN ────────────────────────────────────────────────────────────

  Widget _buildResultScreen() {
    final percentage = (_score / _totalQuestions) * 100;
    final passed = percentage >= 60;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            // Back to start
            Align(
              alignment: Alignment.centerLeft,
              child: _backIconButton(_resetQuiz),
            ),
            const SizedBox(height: 24),

            // Trophy / icon
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: passed
                        ? [_gold.withOpacity(0.9), _cardBg]
                        : [_accent.withOpacity(0.7), _cardBg],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: passed
                          ? _gold.withOpacity(0.3)
                          : _accent.withOpacity(0.3),
                      blurRadius: 40,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: Icon(
                  passed
                      ? Icons.emoji_events_rounded
                      : Icons.psychology_rounded,
                  size: 56,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              passed ? 'Excellent Work!' : 'Keep Practicing!',
              style: const TextStyle(
                color: _softWhite,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              passed
                  ? 'You\'ve mastered these numbers!'
                  : 'Review and try again to improve.',
              style: TextStyle(
                color: _softWhite.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 28),

            // Score ring card
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: _teal,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: (passed ? _gold : _accent).withOpacity(0.25),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _resultStat(
                          '$_score',
                          'Correct',
                          Icons.check_circle_outline_rounded,
                          const Color(0xFF4CAF50)),
                      Container(
                          width: 1,
                          height: 50,
                          color: Colors.white.withOpacity(0.1)),
                      _resultStat(
                          '${_totalQuestions - _score}',
                          'Wrong',
                          Icons.highlight_off_rounded,
                          _accent),
                      Container(
                          width: 1,
                          height: 50,
                          color: Colors.white.withOpacity(0.1)),
                      _resultStat(
                          '${percentage.toStringAsFixed(0)}%',
                          'Score',
                          Icons.trending_up_rounded,
                          _gold),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: _primary,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          passed ? _gold : _accent),
                      minHeight: 10,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: passed
                              ? const Color(0xFF4CAF50).withOpacity(0.15)
                              : _accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          passed ? '✓ PASSED' : '✗ FAILED',
                          style: TextStyle(
                            color: passed
                                ? const Color(0xFF4CAF50)
                                : _accent,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Answer review
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _teal,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Review',
                    style: TextStyle(
                      color: _softWhite.withOpacity(0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._userAnswers.map((ans) => _reviewRow(ans)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: _solidButton('Try Again', _accent, _resetQuiz),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _outlineButton('View Progress', Colors.white24,
                      _viewProgress),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _reviewRow(UserAnswer ans) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ans.isCorrect
                  ? const Color(0xFF4CAF50).withOpacity(0.15)
                  : _accent.withOpacity(0.15),
            ),
            child: Icon(
              ans.isCorrect
                  ? Icons.check_rounded
                  : Icons.close_rounded,
              color: ans.isCorrect
                  ? const Color(0xFF4CAF50)
                  : _accent,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Number ${ans.questionNumber}',
              style: const TextStyle(color: _softWhite, fontSize: 14),
            ),
          ),
          Text(
            ans.userAnswer,
            style: TextStyle(
              color: ans.isCorrect
                  ? const Color(0xFF4CAF50)
                  : _accent,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (!ans.isCorrect) ...[
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded,
                color: Colors.white30, size: 14),
            const SizedBox(width: 8),
            Text(
              ans.correctAnswer,
              style: const TextStyle(
                color: Color(0xFF4CAF50),
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _resultStat(
      String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: _softWhite.withOpacity(0.4),
            fontSize: 11,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  // ─── SHARED BUTTON HELPERS ───────────────────────────────────────────────────

  Widget _backIconButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: _teal,
          borderRadius: BorderRadius.circular(13),
          border:
              Border.all(color: Colors.white.withOpacity(0.08), width: 1),
        ),
        child: const Icon(Icons.arrow_back_ios_new_rounded,
            color: _softWhite, size: 18),
      ),
    );
  }

  Widget _solidButton(
      String label, Color color, VoidCallback onPressed) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(
          label,
          style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              letterSpacing: 0.3),
        ),
      ),
    );
  }

  Widget _outlineButton(
      String label, Color borderColor, VoidCallback onPressed) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: _softWhite,
          side: BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(
          label,
          style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              letterSpacing: 0.3),
        ),
      ),
    );
  }

  // ─── DIFFICULTY DIALOG ───────────────────────────────────────────────────────

  void _changeDifficulty() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _teal,
            borderRadius: BorderRadius.circular(24),
            border:
                Border.all(color: Colors.white.withOpacity(0.08), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Difficulty',
                style: TextStyle(
                  color: _softWhite,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              _difficultyOption(ctx, 'Easy', 5, const Color(0xFF4ECDC4)),
              _difficultyOption(ctx, 'Medium', 10, _gold),
              _difficultyOption(ctx, 'Hard', 10, _accent),
            ],
          ),
        ),
      ),
    );
  }

  Widget _difficultyOption(
      BuildContext ctx, String diff, int qs, Color color) {
    final selected = _difficulty == diff;
    return GestureDetector(
      onTap: () {
        setState(() {
          _difficulty = diff;
          _totalQuestions = qs;
        });
        Navigator.pop(ctx);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : _primary,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : Colors.white.withOpacity(0.07),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration:
                  BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            const SizedBox(width: 12),
            Text(
              diff,
              style: TextStyle(
                color: selected ? color : _softWhite.withOpacity(0.7),
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 15,
              ),
            ),
            const Spacer(),
            Text(
              '$qs questions',
              style: TextStyle(
                color: _softWhite.withOpacity(0.35),
                fontSize: 12,
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 8),
              Icon(Icons.check_rounded, color: color, size: 18),
            ],
          ],
        ),
      ),
    );
  }

  void _viewProgress() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QuizProgressPage(),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DATA MODELS (unchanged)
// ═══════════════════════════════════════════════════════════════════════════════

class QuizQuestion {
  final int questionNumber;
  final String correctAnswer;
  final List<String> options;
  final String geezName;

  QuizQuestion({
    required this.questionNumber,
    required this.correctAnswer,
    required this.options,
    required this.geezName,
  });
}

class UserAnswer {
  final int questionNumber;
  final String userAnswer;
  final String correctAnswer;
  final bool isCorrect;
  final String geezName;

  UserAnswer({
    required this.questionNumber,
    required this.userAnswer,
    required this.correctAnswer,
    required this.isCorrect,
    required this.geezName,
  });

  Map<String, dynamic> toJson() => {
        'questionNumber': questionNumber,
        'userAnswer': userAnswer,
        'correctAnswer': correctAnswer,
        'isCorrect': isCorrect,
        'geezName': geezName,
      };

  factory UserAnswer.fromJson(Map<String, dynamic> json) => UserAnswer(
        questionNumber: json['questionNumber'],
        userAnswer: json['userAnswer'],
        correctAnswer: json['correctAnswer'],
        isCorrect: json['isCorrect'],
        geezName: json['geezName'],
      );
}

class QuizResult {
  final DateTime date;
  final int score;
  final int totalQuestions;
  final double percentage;
  final bool passed;
  final String difficulty;
  final List<UserAnswer> answers;

  QuizResult({
    required this.date,
    required this.score,
    required this.totalQuestions,
    required this.percentage,
    required this.passed,
    required this.difficulty,
    required this.answers,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'score': score,
        'totalQuestions': totalQuestions,
        'percentage': percentage,
        'passed': passed,
        'difficulty': difficulty,
        'answers': answers.map((a) => a.toJson()).toList(),
      };

  factory QuizResult.fromJson(Map<String, dynamic> json) => QuizResult(
        date: DateTime.parse(json['date']),
        score: json['score'],
        totalQuestions: json['totalQuestions'],
        percentage: json['percentage'],
        passed: json['passed'],
        difficulty: json['difficulty'],
        answers: (json['answers'] as List)
            .map((a) => UserAnswer.fromJson(a))
            .toList(),
      );
}

// ═══════════════════════════════════════════════════════════════════════════════
// PROGRESS PAGE
// ═══════════════════════════════════════════════════════════════════════════════

class QuizProgressPage extends StatefulWidget {
  const QuizProgressPage({super.key});

  @override
  State<QuizProgressPage> createState() => _QuizProgressPageState();
}

class _QuizProgressPageState extends State<QuizProgressPage> {
  List<QuizResult> _results = [];
  double _bestScore = 0;
  int _totalQuizzes = 0;
  bool _isLoading = true;

  static const Color _primary = Color(0xFF1A1A2E);
  static const Color _accent = Color(0xFFE94560);
  static const Color _gold = Color(0xFFFFD700);
  static const Color _teal = Color(0xFF16213E);
  static const Color _cardBg = Color(0xFF0F3460);
  static const Color _softWhite = Color(0xFFF5F0E8);

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _bestScore = prefs.getDouble('best_score') ?? 0;
      _totalQuizzes = prefs.getInt('total_quizzes') ?? 0;
    });
    final resultsJson = prefs.getStringList('quiz_results') ?? [];
    setState(() {
      _results = resultsJson
          .map((json) => QuizResult.fromJson(jsonDecode(json)))
          .toList()
          .reversed
          .toList();
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
            color: _teal,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: Colors.white.withOpacity(0.08), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete_forever_rounded,
                  color: _accent, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Clear All History?',
                style: TextStyle(
                  color: _softWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This cannot be undone.',
                style: TextStyle(
                    color: _softWhite.withOpacity(0.5), fontSize: 13),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _softWhite,
                        side: BorderSide(
                            color: Colors.white.withOpacity(0.2)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Clear'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('quiz_results');
      await prefs.remove('best_score');
      await prefs.remove('total_quizzes');
      await _loadProgress();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('History cleared!'),
            backgroundColor: _cardBg,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primary,
      appBar: AppBar(
        backgroundColor: _primary,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _teal,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: _softWhite, size: 16),
          ),
        ),
        title: const Text(
          'Progress',
          style: TextStyle(
            color: _softWhite,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          if (_results.isNotEmpty)
            IconButton(
              icon:
                  Icon(Icons.delete_outline_rounded, color: _accent),
              onPressed: _clearHistory,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _accent))
          : _results.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    _buildStatsSummary(),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: _results.length,
                        itemBuilder: (context, index) =>
                            _buildResultCard(_results[index]),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart_rounded, size: 72, color: _teal),
          const SizedBox(height: 20),
          const Text(
            'No results yet',
            style: TextStyle(
              color: _softWhite,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete a quiz to track your progress.',
            style: TextStyle(color: _softWhite.withOpacity(0.4)),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              elevation: 0,
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Take a Quiz',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSummary() {
    final avgScore = _results.isNotEmpty
        ? _results.map((r) => r.percentage).reduce((a, b) => a + b) /
            _results.length
        : 0.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _teal,
        borderRadius: BorderRadius.circular(24),
        border:
            Border.all(color: Colors.white.withOpacity(0.06), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem('${_bestScore.toStringAsFixed(0)}%', 'Best',
              Icons.emoji_events_rounded, _gold),
          Container(width: 1, height: 40, color: Colors.white12),
          _statItem(_totalQuizzes.toString(), 'Total',
              Icons.quiz_rounded, _accent),
          Container(width: 1, height: 40, color: Colors.white12),
          _statItem('${avgScore.toStringAsFixed(0)}%', 'Average',
              Icons.trending_up_rounded, const Color(0xFF4ECDC4)),
        ],
      ),
    );
  }

  Widget _statItem(
      String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(value,
            style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w800)),
        Text(label,
            style: TextStyle(
                color: _softWhite.withOpacity(0.4),
                fontSize: 11,
                letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildResultCard(QuizResult result) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _teal,
        borderRadius: BorderRadius.circular(18),
        border:
            Border.all(color: Colors.white.withOpacity(0.06), width: 1),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: result.passed
                  ? const Color(0xFF4CAF50).withOpacity(0.15)
                  : _accent.withOpacity(0.15),
            ),
            child: Icon(
              result.passed
                  ? Icons.check_rounded
                  : Icons.close_rounded,
              color: result.passed
                  ? const Color(0xFF4CAF50)
                  : _accent,
              size: 20,
            ),
          ),
          title: Text(
            '${result.date.day}/${result.date.month}/${result.date.year}',
            style: const TextStyle(
              color: _softWhite,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          subtitle: Text(
            '${result.score}/${result.totalQuestions} · ${result.percentage.toStringAsFixed(0)}%',
            style: TextStyle(
                color: _softWhite.withOpacity(0.4), fontSize: 12),
          ),
          trailing: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              result.difficulty,
              style: TextStyle(
                  color: _softWhite.withOpacity(0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
          ),
          children: [
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  Divider(color: Colors.white.withOpacity(0.06)),
                  const SizedBox(height: 4),
                  ...result.answers.map((ans) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          children: [
                            Icon(
                              ans.isCorrect
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.highlight_off_rounded,
                              color: ans.isCorrect
                                  ? const Color(0xFF4CAF50)
                                  : _accent,
                              size: 16,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Number ${ans.questionNumber}',
                              style: TextStyle(
                                  color: _softWhite.withOpacity(0.7),
                                  fontSize: 13),
                            ),
                            const Spacer(),
                            Text(
                              ans.userAnswer,
                              style: TextStyle(
                                color: ans.isCorrect
                                    ? const Color(0xFF4CAF50)
                                    : _accent,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (!ans.isCorrect) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded,
                                  color: Colors.white24, size: 12),
                              const SizedBox(width: 8),
                              Text(
                                ans.correctAnswer,
                                style: const TextStyle(
                                  color: Color(0xFF4CAF50),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}