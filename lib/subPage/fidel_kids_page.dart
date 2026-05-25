

import 'package:flutter/material.dart';
import 'package:fidel/service/fidel.dart';
import 'package:fidel/service/phonetic.dart';

class FidelKidsPage extends StatefulWidget {
  const FidelKidsPage({super.key});

  @override
  State<FidelKidsPage> createState() => _FidelKidsPageState();
}

class _FidelKidsPageState extends State<FidelKidsPage>
    with SingleTickerProviderStateMixin {
  final TtsService tts = TtsService();
  int currentIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _initializeAndAutoRead();
  }

  Future<void> _initializeAndAutoRead() async {
    await tts.initialize(); // Initialize TTS Service
    _autoReadLetter(); // Then auto-read
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // --- MODIFIED _autoReadLetter FUNCTION ---
  void _autoReadLetter() {
    final letter = fidelLetters[currentIndex];
    // Directly use the desired Amharic phrase with the base letter
    // If Mekdes is found, it will be used for this specific call.
    // Otherwise, the default Amharic voice will be used.
    tts.speak(
      "ወደ ${letter.base} እንኳን ደህና መጣቹህ።",
      specificVoice: tts.mekdesVoiceConfig, // Pass Mekdes voice if available
    );
    print('Attempting to speak "Welcome" with Mekdes voice.');
  }
  // --- END OF MODIFIED _autoReadLetter FUNCTION ---

  void _nextLetter() {
    if (currentIndex < fidelLetters.length - 1) {
      setState(() => currentIndex++);
      _autoReadLetter();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Center(
            child: Text(
              '🎉 You finished all ፊደላት!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    blurRadius: 3.0,
                    color: Colors.black54,
                    offset: Offset(1, 1),
                  ),
                ],
              ),
            ),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.teal,
          margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          duration: Duration(seconds: 3),
        ),
      );

      Future.delayed(const Duration(seconds: 2), () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                const Text('🔥 Now challenge yourself and change yourself!'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      });
    }
  }

  void _prevLetter() {
    if (currentIndex > 0) {
      setState(() => currentIndex--);
      _autoReadLetter();
    }
  }

  @override
  Widget build(BuildContext context) {
    final letter = fidelLetters[currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Learn ፊደል ${letter.base}',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
        elevation: 10,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  color: const Color(0xFF9C27B0),
                  child: InkWell(
                    // These will now use the default Amharic voice (not Mekdes)
                    onTap: () => tts.speak(letter.base),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'ፊደል ${letter.base}',
                                style: const TextStyle(
                                  fontSize: 60,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Icon(
                                Icons.volume_up,
                                size: 40,
                                color: Colors.white,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Tap the letter to hear its sound',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  itemCount: letter.forms.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.9,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemBuilder: (context, index) {
                    final form = letter.forms[index];
                    return InkWell(
                      // These will now use the default Amharic voice (not Mekdes)
                      onTap: () => tts.speak(form.fidel),
                      borderRadius: BorderRadius.circular(20),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          color: _getColorForIndex(index),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purple.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                form.fidel,
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                form.phonetic,
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.volume_up,
                                    color: Colors.white, size: 24),
                                // These will now use the default Amharic voice (not Mekdes)
                                onPressed: () => tts.speak(form.fidel),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    FloatingActionButton(
                      heroTag: 'back_button',
                      onPressed: _prevLetter,
                      backgroundColor: Colors.blue,
                      child: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    Text(
                      '${currentIndex + 1}/${fidelLetters.length}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    FloatingActionButton(
                      heroTag: 'next_button',
                      onPressed: _nextLetter,
                      backgroundColor: Colors.blue,
                      child:
                          const Icon(Icons.arrow_forward, color: Colors.white),
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

  Color _getColorForIndex(int index) {
    final colors = [
      const Color(0xFFF44336), // Red
      const Color(0xFFFF9800), // Orange
      const Color(0xFFFFEB3B), // Yellow
      const Color(0xFF4CAF50), // Green
      const Color(0xFF2196F3), // Blue
      const Color(0xFF3F51B5), // Indigo
      const Color(0xFF9C27B0), // Purple
    ];
    return colors[index % colors.length];
  }
}
