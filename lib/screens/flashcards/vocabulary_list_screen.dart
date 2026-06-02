import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../models/vocabulary_model.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../services/vocabulary_service.dart';

class VocabularyListScreen extends StatefulWidget {
  const VocabularyListScreen({super.key});

  @override
  State<VocabularyListScreen> createState() => _VocabularyListScreenState();
}

class _VocabularyListScreenState extends State<VocabularyListScreen> {
  String _selectedLanguage = '';
  String _selectedCategory = 'All';
  late List<VocabularyWord> _filteredWords;
  late List<VocabularyWord> _allWords;
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _allWords = [];
    _filteredWords = [];
    _searchController.addListener(_updateFilteredWords);
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
        } else {
          setState(() {
            _selectedLanguage = 'Spanish';
          });
        }
        await _loadVocabulary();
      }
    } catch (e) {
      print('Error loading user language: $e');
      setState(() {
        _selectedLanguage = 'Spanish';
      });
      await _loadVocabulary();
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
          _allWords = words;
          _isLoading = false;
          _updateFilteredWords();
        });
      }
    } catch (e) {
      print('Error loading vocabulary: $e');
      if (mounted) {
        setState(() {
          _allWords = VocabularySampleData.getSampleData(_selectedLanguage);
          _isLoading = false;
          _updateFilteredWords();
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateFilteredWords() {
    final searchQuery = _searchController.text.toLowerCase();

    _filteredWords = _allWords.where((word) {
      final matchesSearch = word.word.toLowerCase().contains(searchQuery) ||
          word.translation.toLowerCase().contains(searchQuery);
      final matchesCategory = _selectedCategory == 'All' ||
          word.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    setState(() {});
  }

  List<String> _getCategories() {
    final categories = {'All'};
    for (var word in _allWords) {
      categories.add(word.category);
    }
    return categories.toList();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Vocabulary List',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        backgroundColor: AppTheme.white,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [


              // Search Bar
              _buildSearchBar(),
              const SizedBox(height: 12),

              // Category Filter
              _buildCategoryFilter(),
              const SizedBox(height: 12),

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
                      const SizedBox(height: 12),
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
              else
                Column(
                  children: [
                    // Results Count
                    _buildResultsCount(),
                    const SizedBox(height: 12),

                    // Vocabulary List
                    if (_filteredWords.isNotEmpty)
                      _buildVocabularyList()
                    else
                      _buildEmptyState(),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }




  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.inter(
          fontSize: 14,
          color: AppTheme.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Search word or translation...',
          hintStyle: GoogleFonts.inter(
            fontSize: 14,
            color: AppTheme.textTertiary,
          ),
          prefixIcon: const Icon(Icons.search_rounded),
          prefixIconColor: AppTheme.textSecondary,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = _getCategories();
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = category;
                  _updateFilteredWords();
                });
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppTheme.proBadgeGradient : null,
                  color: isSelected ? null : AppTheme.white,
                  border: Border.all(
                    color: isSelected ? Colors.transparent : AppTheme.divider,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? AppTheme.white
                        : AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultsCount() {
    return Text(
      '${_filteredWords.length} word${_filteredWords.length != 1 ? 's' : ''} found',
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppTheme.textSecondary,
      ),
    );
  }

  Widget _buildVocabularyList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredWords.length,
      itemBuilder: (context, index) {
        final word = _filteredWords[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _VocabularyCard(
            key: ValueKey(word.word),
            word: word,
            language: _selectedLanguage,
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: AppTheme.textTertiary,
            ),
            const SizedBox(height: 8),
            Text(
              'No words found',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VocabularyCard extends StatefulWidget {
  final VocabularyWord word;
  final String language;

  const _VocabularyCard({super.key, required this.word, required this.language});

  @override
  State<_VocabularyCard> createState() => _VocabularyCardState();
}

class _VocabularyCardState extends State<_VocabularyCard> {
  late bool _isLearned;
  final VocabularyService _vocabularyService = VocabularyService();

  @override
  void initState() {
    super.initState();
    _isLearned = widget.word.isLearned;
    // Check real favorite status
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    final isFav = await _vocabularyService.isFavorite(
      widget.word.word,
      widget.language,
    );
    if (mounted && isFav != _isLearned) {
      setState(() {
        _isLearned = isFav;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isLearned ? AppTheme.primary : AppTheme.divider,
          width: _isLearned ? 2 : 1,
        ),
        boxShadow: _isLearned
            ? [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Word and Category
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.word.word,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.word.category,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () async {
                  // Optimistic update
                  setState(() {
                    _isLearned = !_isLearned;
                  });

                  final newStatus = await _vocabularyService.toggleFavorite(
                    word: widget.word.word,
                    translation: widget.word.translation,
                    pronunciation: widget.word.pronunciation,
                    category: widget.word.category,
                    example: widget.word.example,
                    language: widget.language,
                  );

                  // Revert if failed or state mismatch
                  if (mounted && newStatus != _isLearned) {
                    setState(() {
                      _isLearned = newStatus;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isLearned
                        ? AppTheme.primary
                        : AppTheme.background,
                    shape: BoxShape.circle,
                    border: _isLearned
                        ? null
                        : Border.all(
                            color: AppTheme.divider,
                            width: 1.5,
                          ),
                  ),
                  child: Icon(
                    _isLearned ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                    color: _isLearned ? AppTheme.white : AppTheme.textSecondary,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Translation
          Row(
            children: [
              Icon(
                Icons.language_rounded,
                size: 16,
                color: AppTheme.secondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.word.translation,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Pronunciation
          Row(
            children: [
              Icon(
                Icons.volume_up_rounded,
                size: 16,
                color: AppTheme.secondary,
              ),
              const SizedBox(width: 8),
              Text(
                widget.word.pronunciation,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.textTertiary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Example:',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.word.example,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textPrimary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
