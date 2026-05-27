import 'package:flutter/material.dart';
import 'package:fidel/model/FidelLetter.dart';
import 'package:fidel/service/fidel.dart';
import 'package:fidel/service/phonetic.dart';

class FidelKidsPage extends StatefulWidget {
  const FidelKidsPage({super.key});

  @override
  State<FidelKidsPage> createState() => _FidelKidsPageState();
}

class _FidelKidsPageState extends State<FidelKidsPage>
    with TickerProviderStateMixin {
  final TtsService tts = TtsService();
  int currentIndex = 0;
  String? _speakingFidel;

  late AnimationController _pulseController;
  late AnimationController _pageController;
  late AnimationController _gridController;

  late Animation<double> _pulseAnimation;
  late Animation<double> _pageFade;
  late Animation<Offset> _pageSlide;
  late Animation<double> _gridFade;

  // ── Colour palette ──────────────────────────────────────────────────────────
  static const Color _primary   = Color(0xFF1A1A2E);
  static const Color _accent    = Color(0xFFE94560);
  static const Color _gold      = Color(0xFFFFD700);
  static const Color _teal      = Color(0xFF16213E);
  static const Color _cardBg    = Color(0xFF0F3460);
  static const Color _softWhite = Color(0xFFF5F0E8);
  static const Color _tealPop   = Color(0xFF4ECDC4);

  // Grid cell accent cycle
  static const List<Color> _cellAccents = [
    _accent,
    _gold,
    _tealPop,
    Color(0xFF9B59B6),
    Color(0xFF2ECC71),
    Color(0xFF3498DB),
    Color(0xFFE67E22),
  ];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();

    _gridController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pageFade = CurvedAnimation(
        parent: _pageController, curve: Curves.easeOutCubic);
    _pageSlide = Tween<Offset>(
      begin: const Offset(0.15, 0),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _pageController, curve: Curves.easeOutCubic));
    _gridFade = CurvedAnimation(
        parent: _gridController, curve: Curves.easeOutCubic);

    _initTts();
  }

  Future<void> _initTts() async {
    await tts.initialize();
    _autoReadLetter();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _pageController.dispose();
    _gridController.dispose();
    tts.stop();
    super.dispose();
  }

  // ── TTS ─────────────────────────────────────────────────────────────────────

  void _autoReadLetter() {
    final letter = fidelLetters[currentIndex];
    tts.speak(
      'ወደ ${letter.base} እንኳን ደህና መጣቹህ።',
      specificVoice: tts.mekdesVoiceConfig,
    );
  }

  Future<void> _speakForm(String fidel) async {
    if (_speakingFidel != null) return;
    setState(() => _speakingFidel = fidel);
    try {
      await tts.speak(fidel, specificVoice: tts.mekdesVoiceConfig);
    } finally {
      if (mounted) setState(() => _speakingFidel = null);
    }
  }

  // ── Navigation ───────────────────────────────────────────────────────────────

  void _animateTransition() {
    _pageController.forward(from: 0);
    _gridController.forward(from: 0);
  }

  void _nextLetter() {
    if (currentIndex < fidelLetters.length - 1) {
      setState(() => currentIndex++);
      _animateTransition();
      _autoReadLetter();
    } else {
      _showFinishSnack();
    }
  }

  void _prevLetter() {
    if (currentIndex > 0) {
      setState(() => currentIndex--);
      _animateTransition();
      _autoReadLetter();
    }
  }

  void _showFinishSnack() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text(
        '🎉 You finished all ፊደላት!',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      behavior: SnackBarBehavior.floating,
      backgroundColor: _cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      duration: const Duration(seconds: 3),
    ));
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final letter = fidelLetters[currentIndex];
    final progress = (currentIndex + 1) / fidelLetters.length;

    return Scaffold(
      backgroundColor: _primary,
      body: Stack(
        children: [
          // Decorative bg circles
          Positioned(
              top: -80, right: -60,
              child: _bgCircle(220, _accent.withOpacity(0.06))),
          Positioned(
              bottom: -100, left: -80,
              child: _bgCircle(280, _cardBg.withOpacity(0.5))),
          Positioned(
              top: 200, left: -40,
              child: _bgCircle(140, _tealPop.withOpacity(0.04))),

          SafeArea(
            child: Column(
              children: [
                _buildAppBar(letter, progress),
                const SizedBox(height: 12),
                _buildHeroCard(letter),
                const SizedBox(height: 16),
                Expanded(child: _buildGrid(letter)),
                _buildNavBar(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bgCircle(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );

  // ── App Bar ──────────────────────────────────────────────────────────────────

  Widget _buildAppBar(FidelLetter letter, double progress) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.maybePop(context),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _teal,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.08), width: 1),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: _softWhite, size: 18),
                ),
              ),
              const SizedBox(width: 14),

              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Learn ፊደል ${letter.base}',
                      style: const TextStyle(
                        color: _softWhite,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      'Tap any form to hear it',
                      style: TextStyle(
                        color: _softWhite.withOpacity(0.4),
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Index badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_stories_rounded,
                        color: _gold, size: 14),
                    const SizedBox(width: 5),
                    Text(
                      '${currentIndex + 1}/${fidelLetters.length}',
                      style: const TextStyle(
                        color: _softWhite,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: _teal,
              valueColor: const AlwaysStoppedAnimation<Color>(_accent),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero Card ────────────────────────────────────────────────────────────────

  Widget _buildHeroCard(FidelLetter letter) {
    return SlideTransition(
      position: _pageSlide,
      child: FadeTransition(
        opacity: _pageFade,
        child: GestureDetector(
          onTap: () => _speakForm(letter.base),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
            decoration: BoxDecoration(
              color: _teal,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: _accent.withOpacity(0.25), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: _accent.withOpacity(0.12),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                // Pulsing symbol circle
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [_accent.withOpacity(0.9), _cardBg],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _accent.withOpacity(0.35),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        letter.base,
                        style: const TextStyle(
                          fontSize: 46,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),

                // Info column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Base Letter',
                        style: TextStyle(
                          color: _softWhite.withOpacity(0.4),
                          fontSize: 11,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        letter.base,
                        style: const TextStyle(
                          color: _softWhite,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: _accent.withOpacity(0.3), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.volume_up_rounded,
                                color: _accent, size: 14),
                            const SizedBox(width: 5),
                            Text(
                              'Tap to listen',
                              style: TextStyle(
                                color: _accent,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Forms count badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _primary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.07), width: 1),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${letter.forms.length}',
                        style: const TextStyle(
                          color: _gold,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'forms',
                        style: TextStyle(
                          color: _softWhite.withOpacity(0.35),
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Grid ─────────────────────────────────────────────────────────────────────

  Widget _buildGrid(FidelLetter letter) {
    return FadeTransition(
      opacity: _gridFade,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        itemCount: letter.forms.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.88,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (_, i) => _buildFormCell(letter.forms[i], i),
      ),
    );
  }

  Widget _buildFormCell(FidelForm form, int index) {
    final color = _cellAccents[index % _cellAccents.length];
    final isSpeaking = _speakingFidel == form.fidel;

    return GestureDetector(
      onTap: () => _speakForm(form.fidel),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: _teal,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSpeaking
                ? color.withOpacity(0.9)
                : color.withOpacity(0.2),
            width: isSpeaking ? 2 : 1.5,
          ),
          boxShadow: isSpeaking
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 18,
                    spreadRadius: 2,
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ],
        ),
        child: Stack(
          children: [
            // Corner decorative circle
            Positioned(
              top: -14, right: -14,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.07),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Fidel character
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withOpacity(0.1),
                      border: Border.all(
                          color: color.withOpacity(0.3), width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        form.fidel,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isSpeaking ? color : _softWhite,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Phonetic
                  Flexible(
                    child: Text(
                      form.phonetic,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _softWhite.withOpacity(0.75),
                        letterSpacing: 0.3,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 5),

                  // Speaker icon
                  Icon(
                    isSpeaking
                        ? Icons.volume_up_rounded
                        : Icons.volume_up_outlined,
                    size: 15,
                    color: isSpeaking
                        ? color
                        : _softWhite.withOpacity(0.22),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Nav Bar ──────────────────────────────────────────────────────────────────

  Widget _buildNavBar() {
    final atStart = currentIndex == 0;
    final atEnd   = currentIndex == fidelLetters.length - 1;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _teal,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.07), width: 1),
      ),
      child: Row(
        children: [
          // Prev button
          _navButton(
            icon: Icons.chevron_left_rounded,
            onTap: _prevLetter,
            enabled: !atStart,
          ),
          const Spacer(),

          // Center progress info
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${currentIndex + 1} / ${fidelLetters.length}',
                style: const TextStyle(
                  color: _softWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Letter',
                style: TextStyle(
                  color: _softWhite.withOpacity(0.3),
                  fontSize: 10,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const Spacer(),

          // Next button
          _navButton(
            icon: Icons.chevron_right_rounded,
            onTap: _nextLetter,
            enabled: !atEnd,
            highlight: true,
          ),
        ],
      ),
    );
  }

  Widget _navButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool enabled,
    bool highlight = false,
  }) {
    final color = highlight ? _accent : _softWhite;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: enabled
              ? (highlight
                  ? _accent.withOpacity(0.15)
                  : Colors.white.withOpacity(0.05))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: enabled ? color.withOpacity(0.35) : Colors.white12,
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: enabled ? color : _softWhite.withOpacity(0.18),
          size: 26,
        ),
      ),
    );
  }
}
