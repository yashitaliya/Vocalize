import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import 'flashcards_screen.dart';
import 'vocabulary_list_screen.dart';
import 'favorites_screen.dart';

class FlashcardsHubScreen extends StatefulWidget {
  const FlashcardsHubScreen({super.key});

  @override
  State<FlashcardsHubScreen> createState() => _FlashcardsHubScreenState();
}

class _FlashcardsHubScreenState extends State<FlashcardsHubScreen> {
  String _selectedLanguage = '';
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadUserLanguage();
  }

  Future<void> _loadUserLanguage() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final userData = await _firestoreService.getUser(user.uid);
        if (mounted) {
          setState(() {
            _selectedLanguage = userData?.selectedLanguage ?? 'Spanish';
          });
        }
      }
    } catch (e) {
      print('Error loading language: $e');
      if (mounted) {
        setState(() {
          _selectedLanguage = 'Spanish';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        bottomNavigationBar: Container(
          color: AppTheme.white,
          child: SafeArea(
            child: TabBar(
              indicatorColor: AppTheme.primary,
              indicatorSize: TabBarIndicatorSize.label,
              indicatorWeight: 3,
              labelColor: AppTheme.primary,
              unselectedLabelColor: AppTheme.textSecondary,
              labelPadding:
                  const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
              labelStyle: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(
                  icon: Icon(Icons.library_books_rounded, size: 20),
                  iconMargin: EdgeInsets.only(bottom: 6),
                  text: 'Flashcards',
                ),
                Tab(
                  icon: Icon(Icons.list_rounded, size: 20),
                  iconMargin: EdgeInsets.only(bottom: 6),
                  text: 'Vocabulary',
                ),
                Tab(
                  icon: Icon(Icons.favorite_rounded, size: 20),
                  iconMargin: EdgeInsets.only(bottom: 6),
                  text: 'Favorites',
                ),
              ],
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Container(
                color: AppTheme.white,
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    IconButton(
                      padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
                      icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    if (_selectedLanguage.isNotEmpty)
                      Expanded(
                        child: Text(
                          _selectedLanguage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    const FlashcardsScreen(),
                    const VocabularyListScreen(),
                    const FavoritesScreen(),
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
