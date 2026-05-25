import 'package:fidel/service/geez_number_generator.dart';
import 'package:flutter/material.dart';
import 'package:fidel/service/phonetic.dart';

class GeezNumberLearningPage extends StatefulWidget {
  const GeezNumberLearningPage({super.key});

  @override
  State<GeezNumberLearningPage> createState() => _GeezNumberLearningPageState();
}

class _GeezNumberLearningPageState extends State<GeezNumberLearningPage>
    with TickerProviderStateMixin {
  final TtsService tts = TtsService();
  final TextEditingController _searchController = TextEditingController();

  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  List<GeezNumber> _allGeezNumbers = [];
  List<GeezNumber> _filteredGeezNumbers = [];
  int _currentPage = 0;
  final int _pageSize = 8;
  String _selectedCategory = 'All';
  String? _speakingSymbol;

  final List<String> _categories = [
    'All',
    '1–100',
    '101–500',
    '501–1000',
    '1000+',
  ];

  // ── Colour palette (identical to BeginnerNumberQuizPage) ──────────────────
  static const Color _primary   = Color(0xFF1A1A2E);
  static const Color _accent    = Color(0xFFE94560);
  static const Color _gold      = Color(0xFFFFD700);
  static const Color _teal      = Color(0xFF16213E);
  static const Color _cardBg    = Color(0xFF0F3460);
  static const Color _softWhite = Color(0xFFF5F0E8);
  static const Color _tealPop   = Color(0xFF4ECDC4);

  // Card accent cycle – gives each card a subtle identity without rainbow chaos
  static const List<Color> _cardAccents = [
    _accent,
    _gold,
    _tealPop,
    Color(0xFF9B59B6),
    Color(0xFF2ECC71),
    Color(0xFF3498DB),
  ];

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _allGeezNumbers = GeezNumberService.generateRange(1, 2050);
    _filteredGeezNumbers = _allGeezNumbers;
    _searchController.addListener(_onSearchChanged);
    _initTts();
  }

  Future<void> _initTts() async {
    await tts.initialize();
    if (tts.mekdesVoiceConfig != null) {
      await tts.speak(
        'እንኳን ደህና መጣችሁ። የግዕዝ ቁጥሮችን እንማር።',
        specificVoice: tts.mekdesVoiceConfig,
      );
    } else {
      await tts.speak('እንኳን ደህና መጣችሁ። የግዕዝ ቁጥሮችን እንማር።');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    tts.stop();
    super.dispose();
  }

  // ── Filtering ──────────────────────────────────────────────────────────────

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredGeezNumbers = _allGeezNumbers.where((n) {
        final matchSearch = query.isEmpty ||
            n.number.toString().contains(query) ||
            n.symbol.contains(query) ||
            n.name.toLowerCase().contains(query);
        return matchSearch && _getCategoryMatch(n);
      }).toList();
      _currentPage = 0;
    });
  }

  bool _getCategoryMatch(GeezNumber n) {
    switch (_selectedCategory) {
      case '1–100':
        return n.number <= 100;
      case '101–500':
        return n.number > 100 && n.number <= 500;
      case '501–1000':
        return n.number > 500 && n.number <= 1000;
      case '1000+':
        return n.number > 1000;
      default:
        return true;
    }
  }

  void _filterByCategory(String category) {
    setState(() => _selectedCategory = category);
    _onSearchChanged();
  }

  List<GeezNumber> _getPaginatedNumbers() {
    final start = _currentPage * _pageSize;
    final end = (start + _pageSize).clamp(0, _filteredGeezNumbers.length);
    return _filteredGeezNumbers.sublist(start, end);
  }

  // ── Pagination ─────────────────────────────────────────────────────────────

  void _nextPage() {
    final totalPages = (_filteredGeezNumbers.length / _pageSize).ceil();
    if (_currentPage + 1 < totalPages) {
      setState(() => _currentPage++);
      _animationController.forward(from: 0);
    } else {
      _showSnack('You\'ve reached the end! 🎉');
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      setState(() => _currentPage--);
      _animationController.forward(from: 0);
    } else {
      _showSnack('You\'re at the beginning! 👏');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      duration: const Duration(seconds: 1),
      behavior: SnackBarBehavior.floating,
      backgroundColor: _cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── TTS ────────────────────────────────────────────────────────────────────

  Future<void> _speakNumber(GeezNumber number) async {
    if (_speakingSymbol != null) return;
    setState(() => _speakingSymbol = number.symbol);
    try {
      if (tts.mekdesVoiceConfig != null) {
        await tts.speak(number.name, specificVoice: tts.mekdesVoiceConfig);
        await Future.delayed(const Duration(milliseconds: 500));
        await tts.speak(
          number.number.toString(),
          languageCode: 'en-US',
          specificVoice: tts.englishVoiceConfig,
        );
      } else {
        await tts.speak('${number.name}, ${number.number}');
      }
    } finally {
      if (mounted) setState(() => _speakingSymbol = null);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final paginated  = _getPaginatedNumbers();
    final totalPages = (_filteredGeezNumbers.length / _pageSize).ceil();

    return Scaffold(
      backgroundColor: _primary,
      body: Stack(
        children: [
          // Background decorative circles
          Positioned(
            top: -80, right: -60,
            child: _bgCircle(220, _accent.withOpacity(0.06)),
          ),
          Positioned(
            bottom: -100, left: -80,
            child: _bgCircle(280, _cardBg.withOpacity(0.5)),
          ),
          Positioned(
            top: 200, left: -40,
            child: _bgCircle(140, _tealPop.withOpacity(0.04)),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                _buildSearchBar(),
                _buildCategoryChips(),
                Expanded(
                  child: paginated.isEmpty
                      ? _buildEmptyState()
                      : FadeTransition(
                          opacity: _fadeAnimation,
                          child: GridView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                            itemCount: paginated.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.80,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                            ),
                            itemBuilder: (_, i) =>
                                _buildNumberCard(paginated[i]),
                          ),
                        ),
                ),
                if (paginated.isNotEmpty) _buildPaginationControls(totalPages),
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

  // ── App Bar ────────────────────────────────────────────────────────────────

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
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

          // Title block
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ግዕዝ ቁጥሮች',
                  style: TextStyle(
                    color: _softWhite,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    height: 1.1,
                  ),
                ),
                Text(
                  'Geez Numbers',
                  style: TextStyle(
                    color: _accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
          ),

          // Count badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.format_list_numbered_rounded,
                    color: _gold, size: 14),
                const SizedBox(width: 5),
                Text(
                  '${_filteredGeezNumbers.length}',
                  style: const TextStyle(
                    color: _softWhite,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Info button
          GestureDetector(
            onTap: _showInfoDialog,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _teal,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                    color: Colors.white.withOpacity(0.08), width: 1),
              ),
              child: Icon(Icons.info_outline_rounded,
                  color: _softWhite.withOpacity(0.6), size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ── Search Bar ─────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      height: 48,
      decoration: BoxDecoration(
        color: _teal,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: _softWhite, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search: 5, ፭, አምስት…',
          hintStyle:
              TextStyle(color: _softWhite.withOpacity(0.3), fontSize: 14),
          prefixIcon:
              Icon(Icons.search_rounded, color: _accent, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear_rounded,
                      color: _softWhite.withOpacity(0.4), size: 18),
                  onPressed: _searchController.clear,
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        ),
      ),
    );
  }

  // ── Category Chips ─────────────────────────────────────────────────────────

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = _categories[i];
          final selected = _selectedCategory == cat;
          return GestureDetector(
            onTap: () => _filterByCategory(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: selected ? _accent : _teal,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? _accent
                      : Colors.white.withOpacity(0.1),
                  width: 1,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: _accent.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        )
                      ]
                    : [],
              ),
              child: Text(
                cat,
                style: TextStyle(
                  color: selected ? Colors.white : _softWhite.withOpacity(0.55),
                  fontSize: 12,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Number Card ────────────────────────────────────────────────────────────

  Widget _buildNumberCard(GeezNumber geezNumber) {
    final accentColor =
        _cardAccents[(geezNumber.number - 1) % _cardAccents.length];
    final isSpeaking = _speakingSymbol == geezNumber.symbol;

    return GestureDetector(
      onTap: () => _speakNumber(geezNumber),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: _teal,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSpeaking
                ? accentColor.withOpacity(0.8)
                : accentColor.withOpacity(0.18),
            width: isSpeaking ? 2 : 1.5,
          ),
          boxShadow: isSpeaking
              ? [
                  BoxShadow(
                    color: accentColor.withOpacity(0.28),
                    blurRadius: 20,
                    spreadRadius: 3,
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
        ),
        child: Stack(
          children: [
            // Decorative corner circles
            Positioned(
              top: -18, right: -18,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.07),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -18, left: -18,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.04),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Symbol circle
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accentColor.withOpacity(0.12),
                      border: Border.all(
                        color: accentColor.withOpacity(0.35),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withOpacity(0.15),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        geezNumber.symbol,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),

                  // Amharic name — Flexible prevents overflow on long names
                  Flexible(
                    child: Text(
                      geezNumber.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _softWhite,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 5),

                  // Number badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _primary,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.08), width: 1),
                    ),
                    child: Text(
                      '#${geezNumber.number}',
                      style: TextStyle(
                        fontSize: 10,
                        color: _softWhite.withOpacity(0.5),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Speaker icon
                  Icon(
                    isSpeaking
                        ? Icons.volume_up_rounded
                        : Icons.volume_up_outlined,
                    size: 16,
                    color: isSpeaking
                        ? accentColor
                        : _softWhite.withOpacity(0.25),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Pagination ─────────────────────────────────────────────────────────────

  Widget _buildPaginationControls(int totalPages) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _teal,
        borderRadius: BorderRadius.circular(24),
        border:
            Border.all(color: Colors.white.withOpacity(0.07), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _pageButton(
            icon: Icons.chevron_left_rounded,
            onTap: _prevPage,
            enabled: _currentPage > 0,
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${_currentPage + 1} / $totalPages',
                style: const TextStyle(
                  color: _softWhite,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              Text(
                'Page',
                style: TextStyle(
                  color: _softWhite.withOpacity(0.3),
                  fontSize: 10,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          _pageButton(
            icon: Icons.chevron_right_rounded,
            onTap: _nextPage,
            enabled: _currentPage + 1 < totalPages,
          ),
        ],
      ),
    );
  }

  Widget _pageButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool enabled,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: enabled ? _accent.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: enabled ? _accent.withOpacity(0.4) : Colors.white12,
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: enabled ? _accent : _softWhite.withOpacity(0.2),
          size: 24,
        ),
      ),
    );
  }

  // ── Empty State ────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _teal,
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withOpacity(0.08), width: 1),
            ),
            child: Icon(Icons.search_off_rounded,
                size: 36, color: _softWhite.withOpacity(0.3)),
          ),
          const SizedBox(height: 16),
          const Text(
            'No results found',
            style: TextStyle(
              color: _softWhite,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try a different search or category',
            style: TextStyle(
              color: _softWhite.withOpacity(0.4),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ── Info Dialog ────────────────────────────────────────────────────────────

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: _teal,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: _accent.withOpacity(0.3), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.info_outline_rounded,
                        color: _accent, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'About Geez Numbers',
                    style: TextStyle(
                      color: _softWhite,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Geez numerals are an ancient numeral system used in Ethiopia and Eritrea, dating back over two millennia.',
                style: TextStyle(
                  color: _softWhite.withOpacity(0.6),
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _gold.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: _gold.withOpacity(0.2), width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.tips_and_updates_rounded,
                        color: _gold, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tap any card to hear the pronunciation!',
                        style: TextStyle(
                          color: _softWhite.withOpacity(0.75),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    'Got it',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
