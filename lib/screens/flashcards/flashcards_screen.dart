import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../models/vocabulary_model.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';

class FlashcardsScreen extends StatefulWidget {
  const FlashcardsScreen({super.key});

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen>
    with TickerProviderStateMixin {
  String _selectedLanguage = '';
  late List<VocabularyWord> _currentWords;
  int _currentCardIndex = 0;
  bool _isFlipped = false;
  late AnimationController _flipController;
  late AnimationController _slideController;
  bool _isLoading = true;
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _currentWords = [];
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _loadUserLanguage();
  }

  Future<void> _loadUserLanguage() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final userData = await _firestoreService.getUser(user.uid);
        if (userData?.selectedLanguage != null) {
          setState(() {
            _selectedLanguage = userData!.selectedLanguage ?? 'Spanish';
          });
          await _loadVocabulary();
        } else {
          // Default to Spanish if no language selected
          setState(() {
            _selectedLanguage = 'Spanish';
          });
          await _loadVocabulary();
        }
      }
    } catch (e) {
      print('Error loading user language: $e');
    }
  }

  Future<void> _loadVocabulary() async {
    try {
      final words = await VocabularySampleData.getSampleDataFromFirebase(
        _selectedLanguage,
        firestoreService: _firestoreService,
      );
      if (mounted) {
        setState(() {
          _currentWords = words;
          _currentCardIndex = 0;
          _isFlipped = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading vocabulary: $e');
      if (mounted) {
        setState(() {
          _currentWords =
              VocabularySampleData.getSampleData(_selectedLanguage);
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    if (_isFlipped) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() {
      _isFlipped = !_isFlipped;
    });
  }

  void _nextCard() {
    if (_currentCardIndex < _currentWords.length - 1) {
      _slideController.forward().then((_) {
        setState(() {
          _currentCardIndex++;
          _isFlipped = false;
        });
        _slideController.reset();
      });
    }
  }

  void _previousCard() {
    if (_currentCardIndex > 0) {
      _slideController.forward().then((_) {
        setState(() {
          _currentCardIndex--;
          _isFlipped = false;
        });
        _slideController.reset();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Loading indicator
              if (_isLoading)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Loading vocabulary...',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              else if (_currentWords.isEmpty)
                Center(
                  child: Text(
                    'No vocabulary available',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    // Progress Bar
                    _buildProgressBar(),
                    const SizedBox(height: 10),

                    // Flashcard Display
                    _buildFlashcard(),
                    const SizedBox(height: 10),

                    // Navigation Buttons
                    _buildNavigationButtons(),
                    const SizedBox(height: 10),

                    // Word Statistics
                    _buildStatistics(),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = (_currentCardIndex + 1) / _currentWords.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
            Text(
              '${_currentCardIndex + 1}/${_currentWords.length}',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: AppTheme.divider,
            valueColor: AlwaysStoppedAnimation(
              Color.lerp(
                AppTheme.primary,
                const Color(0xFF10B981),
                progress,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFlashcard() {
    final word = _currentWords[_currentCardIndex];
    final animation = Tween<double>(begin: 0, end: 1).animate(_flipController);

    return GestureDetector(
      onTap: _toggleFlip,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final isBack = animation.value > 0.5;
          final angle = animation.value * 3.14159;
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle);

          return Transform(
            alignment: Alignment.center,
            transform: transform,
            child: Container(
              width: double.infinity,
              height: 360,
              decoration: BoxDecoration(
                gradient: isBack
                    ? const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : AppTheme.proBadgeGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Animated background pattern
                  Positioned(
                    right: -50,
                    top: -50,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -30,
                    bottom: -30,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  ),
                  // Card Content
                  Padding(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Language Tag
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isBack ? 'Answer' : _selectedLanguage,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.white,
                            ),
                          ),
                        ),
                        // Main Content
                        Expanded(
                          child: Center(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (!isBack)
                                    Text(
                                      'Word',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                  Transform(
                                    transform: Matrix4.identity()
                                      ..rotateY(isBack ? 3.14159 : 0),
                                    alignment: Alignment.center,
                                    child: Text(
                                      isBack ? word.translation : word.word,
                                      style: GoogleFonts.poppins(
                                        fontSize: 48,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  if (!isBack)
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.volume_up_rounded,
                                          color: Colors.white.withOpacity(0.8),
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            word.pronunciation,
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w400,
                                              color: Colors.white.withOpacity(0.8),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  if (isBack)
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Transform(
                                          transform: Matrix4.identity()
                                            ..rotateY(3.14159),
                                          alignment: Alignment.center,
                                          child: Text(
                                            'Example:',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.white.withOpacity(0.8),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Transform(
                                          transform: Matrix4.identity()
                                            ..rotateY(3.14159),
                                          alignment: Alignment.center,
                                          child: Text(
                                            word.example,
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w400,
                                              color: Colors.white.withOpacity(0.9),
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Tap hint
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Transform(
                              transform: Matrix4.identity()
                                ..rotateY(isBack ? 3.14159 : 0),
                              alignment: Alignment.center,
                              child: Text(
                                'Tap to flip',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Previous Button
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _currentCardIndex > 0 ? _previousCard : null,
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Previous'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _currentCardIndex > 0
                  ? AppTheme.white
                  : AppTheme.divider,
              foregroundColor: _currentCardIndex > 0
                  ? AppTheme.textSecondary
                  : AppTheme.textTertiary,
              padding: const EdgeInsets.symmetric(vertical: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: _currentCardIndex > 0
                      ? AppTheme.divider
                      : Colors.transparent,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Next Button
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _currentCardIndex < _currentWords.length - 1
                ? _nextCard
                : null,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Next'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _currentCardIndex < _currentWords.length - 1
                  ? AppTheme.primary
                  : AppTheme.divider,
              foregroundColor: AppTheme.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatistics() {
    final word = _currentWords[_currentCardIndex];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Word Details',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          // Category
          Row(
            children: [
              Icon(
                Icons.label_rounded,
                size: 18,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Category',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      word.category,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Translation
          Row(
            children: [
              Icon(
                Icons.language_rounded,
                size: 18,
                color: AppTheme.secondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'English Translation',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      word.translation,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
