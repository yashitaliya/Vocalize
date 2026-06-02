import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/interest_chip.dart';
import '../../widgets/language_card.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../auth/login_screen.dart';
import '../../main.dart';

class InterestLanguageScreen extends StatefulWidget {
  const InterestLanguageScreen({super.key});

  @override
  State<InterestLanguageScreen> createState() => _InterestLanguageScreenState();
}

class _InterestLanguageScreenState extends State<InterestLanguageScreen> {
  final Set<String> _selectedInterests = {};
  String? _selectedLanguage;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  bool _isSaving = false;

  final List<Map<String, String>> _interests = [
    {'label': 'Music', 'emoji': '🎵'},
    {'label': 'Travel', 'emoji': '✈️'},
    {'label': 'Cooking', 'emoji': '🍳'},
    {'label': 'Business', 'emoji': '💼'},
    {'label': 'Gaming', 'emoji': '🎮'},
    {'label': 'Books', 'emoji': '📚'},
    {'label': 'Sports', 'emoji': '⚽'},
    {'label': 'Art', 'emoji': '🎨'},
  ];

  final List<Map<String, dynamic>> _languages = [
    {
      'language': 'Spanish',
      'nativeName': 'Español',
      'symbol': '🇪🇸',
      'color': const Color(0xFFE74C3C),
    },
    {
      'language': 'French',
      'nativeName': 'Français',
      'symbol': '🇫🇷',
      'color': const Color(0xFF9B59B6),
    },
    {
      'language': 'German',
      'nativeName': 'Deutsch',
      'symbol': '🇩🇪',
      'color': const Color(0xFFF1C40F),
    },
    {
      'language': 'Italian',
      'nativeName': 'Italiano',
      'symbol': '🇮🇹',
      'color': const Color(0xFF27AE60),
    },
    {
      'language': 'Portuguese',
      'nativeName': 'Português',
      'symbol': '🇵🇹',
      'color': const Color(0xFF1ABC9C),
    },
    {
      'language': 'Mandarin',
      'nativeName': '中文',
      'symbol': '🇨🇳',
      'color': const Color(0xFFE67E22),
    },
    {
      'language': 'Japanese',
      'nativeName': '日本語',
      'symbol': '🇯🇵',
      'color': const Color(0xFFFF9FF3),
    },
    {
      'language': 'Korean',
      'nativeName': '한국어',
      'symbol': '🇰🇷',
      'color': const Color(0xFF54A0FF),
    },
    {
      'language': 'Russian',
      'nativeName': 'Русский',
      'symbol': '🇷🇺',
      'color': const Color(0xFF5F27CD),
    },
    {
      'language': 'Arabic',
      'nativeName': 'العربية',
      'symbol': '🇸🇦',
      'color': const Color(0xFF00D2D3),
    },
    {
      'language': 'Hindi',
      'nativeName': 'हिन्दी',
      'symbol': '🇮🇳',
      'color': const Color(0xFFFF6B35),
    },
  ];

  List<Map<String, dynamic>> get _filteredLanguages {
    if (_searchQuery.isEmpty) return _languages;
    return _languages.where((lang) {
      final query = _searchQuery.toLowerCase();
      return lang['language'].toString().toLowerCase().contains(query) ||
          lang['nativeName'].toString().toLowerCase().contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _savePreferences() async {
    if (_selectedInterests.isEmpty || _selectedLanguage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one interest and a language'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final user = _authService.currentUser;
      if (user != null) {
        debugPrint('Saving preferences for user: ${user.uid}');
        await _firestoreService.saveOnboardingPreferences(
          uid: user.uid,
          interests: _selectedInterests.toList(),
          selectedLanguage: _selectedLanguage!,
        );
        debugPrint(
          'Preferences saved: interests=$_selectedInterests, language=$_selectedLanguage',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferences saved successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        // Navigate to home (which is wrapped by AuthWrapper - will show HomeComingSoon)
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthWrapper()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Error saving preferences: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving preferences: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _handleBackPress() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Sign Out?',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Do you want to sign out and go back to login?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Sign Out',
              style: GoogleFonts.inter(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      await _authService.signOut();
      if (mounted) {
        // Navigate to login and clear navigation stack
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await _handleBackPress();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              // Header with back button
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.inputBorder),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, size: 20),
                        color: AppColors.textPrimary,
                        onPressed: _handleBackPress,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Interests Section
                      Text(
                        'What interests you?',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pick topics to practice conversations',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Interests Grid
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.4,
                            ),
                        itemCount: _interests.length,
                        itemBuilder: (context, index) {
                          final interest = _interests[index];
                          final isSelected = _selectedInterests.contains(
                            interest['label'],
                          );
                          return InterestChip(
                            label: interest['label']!,
                            emoji: interest['emoji']!,
                            isSelected: isSelected,
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedInterests.remove(interest['label']);
                                } else {
                                  _selectedInterests.add(interest['label']!);
                                }
                              });
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                      // Language Section
                      Text(
                        'Choose your language',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Which language do you want to learn?',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Note: English is required as the base language to learn any other language.',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Search Bar
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.inputBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.inputBorder),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search languages...',
                            hintStyle: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.textHint,
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: AppColors.textHint,
                              size: 20,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: AppColors.textHint,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _searchController.clear();
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Language Grid
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 0.85,
                            ),
                        itemCount: _filteredLanguages.length,
                        itemBuilder: (context, index) {
                          final language = _filteredLanguages[index];
                          final isSelected =
                              _selectedLanguage == language['language'];
                          return LanguageCard(
                            language: language['language']!,
                            nativeName: language['nativeName']!,
                            symbol: language['symbol']!,
                            symbolColor: language['color'] as Color,
                            isSelected: isSelected,
                            onTap: () {
                              setState(() {
                                _selectedLanguage = language['language'];
                              });
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      // Continue Button
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: GradientButton(
                          text: 'Continue',
                          showArrow: false,
                          isLoading: _isSaving,
                          onPressed: _savePreferences,
                        ),
                      ),
                    ],
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
