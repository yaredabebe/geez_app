import 'dart:convert';

import 'package:fidel/subPage/fidel_kids_page.dart';
import 'package:fidel/subPage/geez_numbers_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../subPage/AdvancedNumberQuizPage.dart';
import '../subPage/BeginnerNumberQuizPage.dart';
import '../subPage/FunGamesPage.dart';
import 'package:url_launcher/url_launcher.dart';
// ════════════════════════════════════════════════════════════════════════════
// HOME PAGE
// ════════════════════════════════════════════════════════════════════════════

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _staggerController;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  // ── Live stats loaded from SharedPreferences ───────────────────────────────
  int    _totalQuizzes    = 0;
  double _bestScore       = 0;
  int    _streakDays      = 0;
  double _dailyGoal       = 0;   // 0.0 – 1.0
  bool   _statsLoaded     = false;

  // ── Colour palette ─────────────────────────────────────────────────────────
  static const Color _primary   = Color(0xFF1A1A2E);
  static const Color _accent    = Color(0xFFE94560);
  static const Color _gold      = Color(0xFFFFD700);
  static const Color _teal      = Color(0xFF16213E);
  static const Color _cardBg    = Color(0xFF0F3460);
  static const Color _softWhite = Color(0xFFF5F0E8);
  static const Color _tealPop   = Color(0xFF4ECDC4);

  // ── Init ───────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _headerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..forward();
    _staggerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..forward();

    _headerFade  = CurvedAnimation(
        parent: _headerController, curve: Curves.easeOutCubic);
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _headerController, curve: Curves.easeOutCubic));

    _loadStats();
  }

  @override
  void dispose() {
    _headerController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  // ── Load live data from SharedPreferences ──────────────────────────────────

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();

    // Quiz stats (written by BeginnerNumberQuizPage / AdvancedNumberQuizPage)
    final totalQuizzes = prefs.getInt('total_quizzes') ?? 0;
    final bestScore    = prefs.getDouble('best_score') ?? 0.0;

    // Streak: compare last_active date to today
    final lastActiveStr = prefs.getString('last_active_date');
    final today         = _dateKey(DateTime.now());
    int streak          = prefs.getInt('streak_days') ?? 0;

    if (lastActiveStr == null) {
      // First launch — initialise
      streak = 1;
    } else if (lastActiveStr == today) {
      // Already opened today — keep streak
    } else if (lastActiveStr == _dateKey(
        DateTime.now().subtract(const Duration(days: 1)))) {
      // Opened yesterday → extend streak
      streak += 1;
    } else {
      // Missed a day → reset
      streak = 1;
    }
    await prefs.setString('last_active_date', today);
    await prefs.setInt('streak_days', streak);

    // Daily goal: count quizzes taken today
    final resultsJson   = prefs.getStringList('quiz_results') ?? [];
    int todayQuizzes    = 0;
    const dailyTarget   = 3; // 3 quizzes = 100% daily goal
    for (final json in resultsJson) {
      try {
        final map  = jsonDecode(json) as Map<String, dynamic>;
        final date = DateTime.parse(map['date'] as String);
        if (_dateKey(date) == today) todayQuizzes++;
      } catch (_) {}
    }
    final dailyGoal = (todayQuizzes / dailyTarget).clamp(0.0, 1.0);

    if (mounted) {
      setState(() {
        _totalQuizzes = totalQuizzes;
        _bestScore    = bestScore;
        _streakDays   = streak;
        _dailyGoal    = dailyGoal;
        _statsLoaded  = true;
      });
    }
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ── Refresh on return from sub-page ───────────────────────────────────────

  Future<void> _navigateAndRefresh(_MenuItem item) async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => item.page,
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.12, 0),
              end: Offset.zero,
            ).animate(anim),
            child: child,
          ),
        ),
      ),
    );
    // Reload stats when user returns
    _loadStats();
  }

  // ── Menu items ─────────────────────────────────────────────────────────────

  List<_MenuItem> get _menuItems => [
        _MenuItem(
          title: 'Learn Fidel',
          subtitle: 'Master the Ethiopic alphabet',
          geezLabel: 'ሀለ',
          accent: _accent,
          tag: 'ALPHABET',
          page: const FidelKidsPage(),
        ),
        _MenuItem(
          title: 'Geez Numbers',
          subtitle: 'Count in ancient script',
          geezLabel: '፩፪፫',
          accent: _tealPop,
          tag: 'NUMBERS',
          page: const GeezNumberLearningPage(),
        ),
        _MenuItem(
          title: 'Beginner Quiz',
          subtitle: 'Test numbers 1–10',
          icon: Icons.quiz_rounded,
          accent: _gold,
          tag: 'QUIZ',
          page: const BeginnerNumberQuizPage(),
        ),
        _MenuItem(
          title: 'Advanced Quiz',
          subtitle: 'Challenge yourself',
          icon: Icons.military_tech_rounded,
          accent: const Color(0xFF9B59B6),
          tag: 'ADVANCED',
          page: const AdvancedNumberQuizPage(),
        ),
        _MenuItem(
          title: 'Fun Games',
          subtitle: 'Learn while playing',
          icon: Icons.sports_esports_rounded,
          accent: const Color(0xFF2ECC71),
          tag: 'GAMES',
          page: const FunGamesPage(),
        ),
      ];

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primary,
      body: Stack(
        children: [
          Positioned(top: -100, right: -80,
              child: _bgCircle(260, _accent.withOpacity(0.06))),
          Positioned(top: 300, left: -60,
              child: _bgCircle(180, _tealPop.withOpacity(0.04))),
          Positioned(bottom: -120, right: -60,
              child: _bgCircle(300, _cardBg.withOpacity(0.7))),

          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildTopBar()),
                SliverToBoxAdapter(child: _buildHeroBanner()),
                SliverToBoxAdapter(child: _buildStatsRow()),
                SliverToBoxAdapter(child: _buildSectionHeader()),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _buildMenuCard(_menuItems[i], i),
                    childCount: _menuItems.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bgCircle(double size, Color color) => Container(
        width: size, height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );

  // ── Top Bar ────────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return SlideTransition(
      position: _headerSlide,
      child: FadeTransition(
        opacity: _headerFade,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(
            children: [
              // Logo mark
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                      colors: [_accent.withOpacity(0.9), _cardBg]),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(color: _accent.withOpacity(0.3),
                        blurRadius: 12, spreadRadius: 1)
                  ],
                ),
                child: const Center(
                  child: Text('ሀ',
                      style: TextStyle(fontSize: 22, color: Colors.white,
                          fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Geez Number',
                      style: TextStyle(color: _softWhite, fontSize: 18,
                          fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                  Text('የግዕዝ ቁጥር',
                      style: TextStyle(color: _accent, fontSize: 11,
                          fontWeight: FontWeight.w600, letterSpacing: 0.8)),
                ],
              ),
              const Spacer(),
              // Progress button → opens progress page
              _topBarButton(
                Icons.bar_chart_rounded,
                _gold,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const QuizProgressPage()),
                ).then((_) => _loadStats()),
              ),
              const SizedBox(width: 8),
              // Settings button → opens settings sheet
              _topBarButton(
                Icons.settings_outlined,
                _softWhite.withOpacity(0.6),
                _showSettingsSheet,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBarButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: _teal,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.07), width: 1),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  // ── Hero Banner ────────────────────────────────────────────────────────────

  Widget _buildHeroBanner() {
    return FadeTransition(
      opacity: _headerFade,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: _teal,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: _accent.withOpacity(0.2), width: 1.5),
          boxShadow: [
            BoxShadow(color: _accent.withOpacity(0.1),
                blurRadius: 24, spreadRadius: 2),
          ],
        ),
        child: Stack(
          children: [
            // Decorative Geez text watermark
            Positioned(
              right: 0, top: -8,
              child: Text('ፊደል',
                  style: TextStyle(fontSize: 72, fontWeight: FontWeight.w900,
                      color: _accent.withOpacity(0.06), height: 1)),
            ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Streak chip — live data
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: _accent.withOpacity(0.3), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_fire_department_rounded,
                                color: _accent, size: 13),
                            const SizedBox(width: 4),
                            Text(
                              _statsLoaded
                                  ? '$_streakDays day${_streakDays == 1 ? '' : 's'} streak'
                                  : '— streak',
                              style: TextStyle(color: _accent, fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('Welcome back!',
                          style: TextStyle(color: _softWhite, fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5, height: 1.1)),
                      const SizedBox(height: 4),
                      Text('Continue your Amharic\nlearning journey',
                          style: TextStyle(
                              color: _softWhite.withOpacity(0.5),
                              fontSize: 13, height: 1.5)),
                      const SizedBox(height: 16),
                      // Daily goal progress — live data
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Daily Goal',
                                  style: TextStyle(
                                      color: _softWhite.withOpacity(0.45),
                                      fontSize: 11, letterSpacing: 0.5)),
                              Text(
                                _statsLoaded
                                    ? '${(_dailyGoal * 100).toInt()}%'
                                    : '—',
                                style: const TextStyle(color: _gold,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: _statsLoaded ? _dailyGoal : 0,
                              backgroundColor: _primary,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  _gold),
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _statsLoaded
                                ? 'Complete ${(3 * (1 - _dailyGoal)).ceil().clamp(0, 3)} more quiz${(3 * (1 - _dailyGoal)).ceil() == 1 ? '' : 'zes'} to finish today'
                                : 'Take quizzes to reach your daily goal',
                            style: TextStyle(
                                color: _softWhite.withOpacity(0.3),
                                fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Avatar circle
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                        colors: [_accent.withOpacity(0.85), _cardBg]),
                    boxShadow: [
                      BoxShadow(color: _accent.withOpacity(0.35),
                          blurRadius: 24, spreadRadius: 4),
                    ],
                  ),
                  child: const Center(
                    child: Text('ሀ',
                        style: TextStyle(fontSize: 40, color: Colors.white,
                            fontWeight: FontWeight.bold, height: 1)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Stats Row — all live ───────────────────────────────────────────────────

  Widget _buildStatsRow() {
    final bestStr = _statsLoaded
        ? (_bestScore > 0 ? '${_bestScore.toInt()}%' : '—')
        : '…';
    final quizStr = _statsLoaded ? '$_totalQuizzes' : '…';
    final streakStr = _statsLoaded ? '$_streakDays' : '…';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          _statCard(quizStr,   'Quizzes',  Icons.quiz_rounded,            _accent),
          const SizedBox(width: 10),
          _statCard(bestStr,   'Best',     Icons.emoji_events_rounded,    _gold),
          const SizedBox(width: 10),
          _statCard(streakStr, 'Streak',   Icons.local_fire_department_rounded, _tealPop),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: _teal,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.18), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(color: color, fontSize: 20,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(color: _softWhite.withOpacity(0.4),
                    fontSize: 10, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  // ── Section Header ─────────────────────────────────────────────────────────

  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        children: [
          Container(
            width: 4, height: 20,
            decoration: BoxDecoration(
                color: _accent, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 10),
          const Text('Learning Path',
              style: TextStyle(color: _softWhite, fontSize: 18,
                  fontWeight: FontWeight.w800, letterSpacing: -0.2)),
          const Spacer(),
          Text('${_menuItems.length} modules',
              style: TextStyle(color: _softWhite.withOpacity(0.35),
                  fontSize: 12, letterSpacing: 0.3)),
        ],
      ),
    );
  }

  // ── Menu Card ──────────────────────────────────────────────────────────────

  Widget _buildMenuCard(_MenuItem item, int index) {
    final delay = index * 0.12;
    final cardAnim = CurvedAnimation(
      parent: _staggerController,
      curve: Interval(delay, (delay + 0.5).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: cardAnim,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, 24 * (1 - cardAnim.value)),
        child: Opacity(
            opacity: cardAnim.value.clamp(0.0, 1.0), child: child),
      ),
      child: _MenuCardTile(
        item: item,
        onTap: () => _navigateAndRefresh(item),
      ),
    );
  }

  // ── Settings Bottom Sheet ──────────────────────────────────────────────────

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SettingsSheet(
        onClearData: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('quiz_results');
          await prefs.remove('best_score');
          await prefs.remove('total_quizzes');
          await prefs.remove('streak_days');
          await prefs.remove('last_active_date');
          if (mounted) {
            Navigator.pop(context);
            _loadStats();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Text('All progress cleared'),
              backgroundColor: _cardBg,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ));
          }
        },
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// SETTINGS BOTTOM SHEET
// ════════════════════════════════════════════════════════════════════════════

class _SettingsSheet extends StatelessWidget {
  final VoidCallback onClearData;
  const _SettingsSheet({required this.onClearData});

  static const Color _primary   = Color(0xFF1A1A2E);
  static const Color _accent    = Color(0xFFE94560);
  static const Color _gold      = Color(0xFFFFD700);
  static const Color _teal      = Color(0xFF16213E);
  static const Color _cardBg    = Color(0xFF0F3460);
  static const Color _softWhite = Color(0xFFF5F0E8);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: _teal,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: Colors.white.withOpacity(0.07), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(Icons.settings_outlined,
                    color: _softWhite.withOpacity(0.6), size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Settings',
                  style: TextStyle(color: _softWhite, fontSize: 20,
                      fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 20),

          // App version tile
          _settingsTile(
            icon: Icons.info_outline_rounded,
            iconColor: _gold,
            title: 'App Version',
            trailing: Text('1.0.0',
                style: TextStyle(
                    color: _softWhite.withOpacity(0.4), fontSize: 13)),
          ),
          const SizedBox(height: 10),

          // Rate the app tile
          _settingsTile(
            icon: Icons.star_outline_rounded,
            iconColor: _gold,
            title: 'Rate the App',
            subtitle: 'Help us grow on Google Play',
            onTap: () {
              Navigator.pop(context);

              launchUrl(
                Uri.parse(
                  'https://play.google.com/store/apps/details?id=com.geez.number',
                ),
                mode: LaunchMode.externalApplication,
              );
            },
          ),
          const SizedBox(height: 10),

          _settingsTile(
            icon: Icons.privacy_tip_outlined,
            iconColor: const Color(0xFF4ECDC4),
            title: 'Privacy Policy',
            onTap: () {
              Navigator.pop(context);

              launchUrl(
                Uri.parse(
                  'https://sites.google.com/view/geez-quiz-privacy-policy',
                ),
                mode: LaunchMode.externalApplication,
              );
            },
          ),
          const SizedBox(height: 10),

          // View progress tile
          _settingsTile(
            icon: Icons.bar_chart_rounded,
            iconColor: _accent,
            title: 'View My Progress',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const QuizProgressPage()));
            },
          ),
          const SizedBox(height: 20),

          // Divider
          Divider(color: Colors.white.withOpacity(0.07)),
          const SizedBox(height: 10),

          // Clear data — destructive
          GestureDetector(
            onTap: () => _confirmClear(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _accent.withOpacity(0.3), width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_forever_rounded, color: _accent, size: 18),
                  const SizedBox(width: 8),
                  Text('Clear All Progress',
                      style: TextStyle(color: _accent, fontSize: 14,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _primary,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.06), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(color: _softWhite, fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                            color: _softWhite.withOpacity(0.4),
                            fontSize: 11)),
                  ],
                ],
              ),
            ),
            trailing ??
                (onTap != null
                    ? Icon(Icons.chevron_right_rounded,
                        color: _softWhite.withOpacity(0.25), size: 20)
                    : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _teal,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _accent.withOpacity(0.4), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, color: _accent, size: 44),
              const SizedBox(height: 14),
              const Text('Clear All Progress?',
                  style: TextStyle(color: _softWhite, fontSize: 18,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('Your quiz history, scores and streak will be permanently deleted.',
                  style: TextStyle(color: _softWhite.withOpacity(0.5),
                      fontSize: 13, height: 1.5),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _softWhite,
                        side: BorderSide(color: Colors.white.withOpacity(0.2)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Cancel',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        onClearData();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Clear',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// MENU CARD TILE  (stateful for press animation)
// ════════════════════════════════════════════════════════════════════════════

class _MenuCardTile extends StatefulWidget {
  final _MenuItem item;
  final VoidCallback onTap;
  const _MenuCardTile({required this.item, required this.onTap});

  @override
  State<_MenuCardTile> createState() => _MenuCardTileState();
}

class _MenuCardTileState extends State<_MenuCardTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _pressAnim;

  static const Color _teal      = Color(0xFF16213E);
  static const Color _softWhite = Color(0xFFF5F0E8);

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _pressAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
        CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _pressCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) { _pressCtrl.reverse(); widget.onTap(); },
      onTapCancel: () => _pressCtrl.reverse(),
      child: ScaleTransition(
        scale: _pressAnim,
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          decoration: BoxDecoration(
            color: _teal,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: item.accent.withOpacity(0.2), width: 1.5),
            boxShadow: [
              BoxShadow(color: item.accent.withOpacity(0.08),
                  blurRadius: 16, spreadRadius: 1, offset: const Offset(0, 4)),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(top: -20, right: -20,
                  child: Container(width: 80, height: 80,
                      decoration: BoxDecoration(
                          color: item.accent.withOpacity(0.06),
                          shape: BoxShape.circle))),
              Positioned(bottom: -24, left: -16,
                  child: Container(width: 70, height: 70,
                      decoration: BoxDecoration(
                          color: item.accent.withOpacity(0.03),
                          shape: BoxShape.circle))),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Row(
                  children: [
                    // Icon box
                    Container(
                      width: 58, height: 58,
                      decoration: BoxDecoration(
                        color: item.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: item.accent.withOpacity(0.3), width: 1.5),
                        boxShadow: [
                          BoxShadow(color: item.accent.withOpacity(0.15),
                              blurRadius: 12, spreadRadius: 1),
                        ],
                      ),
                      child: Center(
                        child: item.geezLabel != null
                            ? Text(item.geezLabel!,
                                style: TextStyle(fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: item.accent))
                            : Icon(item.icon, size: 26, color: item.accent),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Text block
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: item.accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(item.tag,
                                style: TextStyle(color: item.accent,
                                    fontSize: 9, fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2)),
                          ),
                          const SizedBox(height: 5),
                          Text(item.title,
                              style: const TextStyle(color: _softWhite,
                                  fontSize: 16, fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2)),
                          const SizedBox(height: 2),
                          Text(item.subtitle,
                              style: TextStyle(
                                  color: _softWhite.withOpacity(0.45),
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                    // Arrow
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: item.accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                            color: item.accent.withOpacity(0.3), width: 1),
                      ),
                      child: Icon(Icons.arrow_forward_ios_rounded,
                          color: item.accent, size: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// DATA MODEL
// ════════════════════════════════════════════════════════════════════════════

class _MenuItem {
  final String title;
  final String subtitle;
  final String? geezLabel;
  final IconData? icon;
  final Color accent;
  final String tag;
  final Widget page;

  const _MenuItem({
    required this.title,
    required this.subtitle,
    this.geezLabel,
    this.icon,
    required this.accent,
    required this.tag,
    required this.page,
  });
}