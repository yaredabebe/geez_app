import 'package:fidel/subPage/fidel_kids_page.dart';
import 'package:fidel/subPage/geez_numbers_page.dart';
import 'package:flutter/material.dart';
import 'package:fidel/subPage/AlphabetPage.dart';

import '../subPage/AdvancedNumberQuizPage.dart';
import '../subPage/BeginnerNumberQuizPage.dart';
import '../subPage/FunGamesPage.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final menuItems = [
      MenuItem(
        title: 'Learn Fidel',
        subtitle: 'Master the basics',
        icon: 'ሀለ',
        iconType: IconType.text,
        gradient: const LinearGradient(
          colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        page: const FidelKidsPage(),
      ),
      MenuItem(
        title: 'Learn Geez Numbers',
        subtitle: '፩, ፪, ፫...',
        icon: '፩፪',
        iconType: IconType.text,
        gradient: const LinearGradient(
          colors: [Color(0xFF00B894), Color(0xFF55EFC4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        page: const GeezNumberLearningPage(),
      ),
      MenuItem(
  title: 'Beginner Number Quiz',
  subtitle: 'Test your knowledge',
  icon: Icons.quiz,
  iconType: IconType.material,
  gradient: const LinearGradient(
    colors: [Color(0xFF0984E3), Color(0xFF74B9FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ),
  page: const BeginnerNumberQuizPage(), // Changed from AlphabetPage
),
      MenuItem(
        title: 'Advanced Number Quiz',
        subtitle: 'Geez Number Challenge',
        icon: Icons.stars,
        iconType: IconType.material,
        gradient: const LinearGradient(
          colors: [Color(0xFFE17055), Color(0xFFFAB1A0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        page: const AdvancedNumberQuizPage(),
      ),
      MenuItem(
  title: 'Fun Games',
  subtitle: 'Learn while playing',
  icon: Icons.videogame_asset,
  iconType: IconType.material,
  gradient: const LinearGradient(
    colors: [Color(0xFFFD79A8), Color(0xFFFF9FF3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ),
  page: const FunGamesPage(), // Changed from AlphabetPage
),
      // MenuItem(
      //   title: 'My Progress',
      //   subtitle: 'Track your journey',
      //   icon: Icons.trending_up,
      //   iconType: IconType.material,
      //   gradient: const LinearGradient(
      //     colors: [Color(0xFFFDCB6E), Color(0xFFFFEAA7)],
      //     begin: Alignment.topLeft,
      //     end: Alignment.bottomRight,
      //   ),
      //   page: const MyProgressPage(),
      // ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              _buildWelcomeCard(context),
              const SizedBox(height: 24),
              _buildStatsRow(),
              const SizedBox(height: 24),
              _buildSectionTitle('Learning Path', Icons.school),
              const SizedBox(height: 16),
              ...menuItems.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _buildAnimatedCard(context, item),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Geez Learn',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 24,
          letterSpacing: -0.5,
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFF8F9FA)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Color(0xFF6C5CE7)),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: Color(0xFF6C5CE7)),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Welcome back! 👋",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    text: "Continue your ",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                    children: const [
                      TextSpan(
                        text: "Amharic",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(text: " learning journey"),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_fire_department, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        "5 day streak!",
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const CircleAvatar(
            radius: 35,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.auto_stories,
              color: Color(0xFF6C5CE7),
              size: 30,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard('Lessons', '12', Icons.menu_book),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('Words', '48', Icons.text_fields),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('Score', '85%', Icons.emoji_events),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF6C5CE7), size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3436),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF6C5CE7), size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3436),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedCard(BuildContext context, MenuItem item) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 500),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _navigateToPage(context, item),
          child: Container(
            decoration: BoxDecoration(
              gradient: item.gradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: item.gradient.colors.first.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Decorative circles
                Positioned(
                  right: -20,
                  top: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: item.iconType == IconType.text
                              ? Text(
                                  item.icon as String,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  item.icon as IconData,
                                  size: 28,
                                  color: Colors.white,
                                ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.subtitle,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 16,
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

  void _navigateToPage(BuildContext context, MenuItem item) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => item.page,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.2, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
      ),
    );
  }
}

enum IconType { text, material }

class MenuItem {
  final String title;
  final String subtitle;
  final dynamic icon;
  final IconType iconType;
  final LinearGradient gradient;
  final Widget page;

  MenuItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconType,
    required this.gradient,
    required this.page,
  });
}