import 'package:fidel/service/geez_number_generator.dart';
import 'package:flutter/material.dart';
import 'package:fidel/service/phonetic.dart';

class GeezNumberLearningPage extends StatefulWidget {
  const GeezNumberLearningPage({super.key});

  @override
  State<GeezNumberLearningPage> createState() => _GeezNumberLearningPageState();
}

class _GeezNumberLearningPageState extends State<GeezNumberLearningPage>
    with SingleTickerProviderStateMixin {
  final TtsService tts = TtsService();
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  List<GeezNumber> _allGeezNumbers = [];
  List<GeezNumber> _filteredGeezNumbers = [];
  int _currentPage = 0;
  final int _pageSize = 8;
  String _selectedCategory = 'All';
  bool _isSpeaking = false;

  final List<String> _categories = ['All', '1-100', '101-500', '501-1000', '1000+'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _allGeezNumbers = GeezNumberService.generateRange(1, 2050);
    _filteredGeezNumbers = _allGeezNumbers;
    _searchController.addListener(_onSearchChanged);
    _initializeTtsAndSpeakGreeting();
  }

  Future<void> _initializeTtsAndSpeakGreeting() async {
    await tts.initialize();
    if (tts.mekdesVoiceConfig != null) {
      await tts.speak("እንኳን ደህና መጣችሁ። የግዕዝ ቁጥሮችን እንማር።",
          specificVoice: tts.mekdesVoiceConfig);
    } else {
      await tts.speak("እንኳን ደህና መጣችሁ። የግዕዝ ቁጥሮችን እንማር።");
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    tts.stop();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty && _selectedCategory == 'All') {
        _filteredGeezNumbers = _allGeezNumbers;
      } else {
        _filteredGeezNumbers = _allGeezNumbers.where((number) {
          final matchesSearch = query.isEmpty ||
              number.number.toString().contains(query) ||
              number.symbol.contains(query) ||
              number.name.toLowerCase().contains(query);
          
          final matchesCategory = _getCategoryMatch(number);
          
          return matchesSearch && matchesCategory;
        }).toList();
      }
      _currentPage = 0;
    });
  }

  bool _getCategoryMatch(GeezNumber number) {
    switch (_selectedCategory) {
      case '1-100':
        return number.number <= 100;
      case '101-500':
        return number.number > 100 && number.number <= 500;
      case '501-1000':
        return number.number > 500 && number.number <= 1000;
      case '1000+':
        return number.number > 1000;
      default:
        return true;
    }
  }

  void _filterByCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _onSearchChanged();
    });
  }

  List<GeezNumber> _getPaginatedNumbers() {
    final startIndex = _currentPage * _pageSize;
    final endIndex = (startIndex + _pageSize).clamp(0, _filteredGeezNumbers.length);
    return _filteredGeezNumbers.sublist(startIndex, endIndex);
  }

  void _nextPage() {
    if ((_currentPage + 1) * _pageSize < _filteredGeezNumbers.length) {
      setState(() => _currentPage++);
      _animatePageTransition();
    } else {
      _showSnackBar('You\'ve reached the end! 🎉');
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      setState(() => _currentPage--);
      _animatePageTransition();
    } else {
      _showSnackBar('You\'re at the beginning! 👏');
    }
  }

  void _animatePageTransition() {
    _animationController.reset();
    _animationController.forward();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.grey[800],
      ),
    );
  }

  Future<void> _speakNumber(GeezNumber number) async {
    if (_isSpeaking) return;
    
    setState(() => _isSpeaking = true);
    
    try {
      // First speak the Geez name
      if (tts.mekdesVoiceConfig != null) {
        await tts.speak(number.name, specificVoice: tts.mekdesVoiceConfig);
        await Future.delayed(const Duration(milliseconds: 500));
        // Then speak the number in English
        await tts.speak(number.number.toString(),
            languageCode: 'en-US', specificVoice: tts.englishVoiceConfig);
      } else {
        await tts.speak("${number.name}, ${number.number}");
      }
    } finally {
      setState(() => _isSpeaking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final paginatedNumbers = _getPaginatedNumbers();
    final totalPages = (_filteredGeezNumbers.length / _pageSize).ceil();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              _buildSearchBar(),
              _buildCategoryChips(),
              Expanded(
                child: paginatedNumbers.isEmpty
                    ? _buildEmptyState()
                    : FadeTransition(
                        opacity: _fadeAnimation,
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: paginatedNumbers.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.85,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemBuilder: (context, index) {
                            final geezNumber = paginatedNumbers[index];
                            return _buildNumberCard(geezNumber);
                          },
                        ),
                      ),
              ),
              if (paginatedNumbers.isNotEmpty)
                _buildPaginationControls(totalPages),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'ግዕዝ ቁጥሮች',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.white),
              onPressed: () => _showInfoDialog(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search numbers... (e.g., 5, ፭, አምስት)',
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF667EEA)),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () => _searchController.clear(),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (_) => _filterByCategory(category),
              backgroundColor: Colors.white.withOpacity(0.2),
              selectedColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFF667EEA) : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: StadiumBorder(
                side: BorderSide(
                  color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
Widget _buildNumberCard(GeezNumber geezNumber) {
  return TweenAnimationBuilder(
    duration: const Duration(milliseconds: 400),
    tween: Tween<double>(begin: 0, end: 1),
    builder: (context, value, child) {
      return Transform.scale(
        scale: value,
        child: Opacity(opacity: value, child: child),
      );
    },
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _speakNumber(geezNumber),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _getCardGradient(geezNumber.number),
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: -20,
                left: -20,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min, // This helps prevent overflow
                  children: [
                    // Geez Symbol
                    Container(
                      width: 65,
                      height: 65,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          geezNumber.symbol,
                          style: const TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Amharic Name
                    Flexible(
                      child: Text(
                        geezNumber.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // English Number
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '#${geezNumber.number}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Speaker Icon
                    AnimatedOpacity(
                      opacity: _isSpeaking ? 0.5 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.volume_up_rounded,
                        size: 22,
                        color: Colors.white.withOpacity(0.9),
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
  Widget _buildPaginationControls(int totalPages) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildPaginationButton(
            icon: Icons.chevron_left,
            onPressed: _prevPage,
            isEnabled: _currentPage > 0,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_currentPage + 1} / $totalPages',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          _buildPaginationButton(
            icon: Icons.chevron_right,
            onPressed: _nextPage,
            isEnabled: _currentPage + 1 < totalPages,
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isEnabled,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? onPressed : null,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isEnabled ? const Color(0xFF667EEA).withOpacity(0.1) : Colors.grey.withOpacity(0.1),
          ),
          child: Icon(
            icon,
            color: isEnabled ? const Color(0xFF667EEA) : Colors.grey,
            size: 30,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No numbers found!',
            style: TextStyle(
              fontSize: 20,
              color: Colors.white.withOpacity(0.7),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search term',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('About Geez Numbers'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Geez numerals are an ancient numeral system used in Ethiopia and Eritrea.',
              style: TextStyle(height: 1.5),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF667EEA).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.tips_and_updates, color: Color(0xFF667EEA)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tap on any card to hear the pronunciation!',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  List<Color> _getCardGradient(int number) {
    final gradients = [
      [const Color(0xFF667EEA), const Color(0xFF764BA2)],
      [const Color(0xFFF093FB), const Color(0xFFF5576C)],
      [const Color(0xFF4FACFE), const Color(0xFF00F2FE)],
      [const Color(0xFF43E97B), const Color(0xFF38F9D7)],
      [const Color(0xFFFA709A), const Color(0xFFFEE140)],
      [const Color(0xFF30CFD0), const Color(0xFF330867)],
    ];
    final gradient = gradients[(number - 1) % gradients.length];
    return [gradient[0], gradient[1]];
  }
}