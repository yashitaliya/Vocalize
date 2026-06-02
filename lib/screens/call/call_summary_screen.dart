import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../models/call_models.dart';
import '../../models/session_data.dart';
import '../../screens/session_analysis/widgets/session_widgets.dart';
import '../../services/vocabulary_service.dart';
import '../../services/matchmaking_service.dart';
import '../../services/call_analysis_service.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

/// Model for a conversation message during call
class ConversationMessage {
  final String original;
  final String translated;
  final DateTime timestamp;

  ConversationMessage({
    required this.original,
    required this.translated,
    required this.timestamp,
  });
}

/// Screen shown after a call ends
class CallSummaryScreen extends StatefulWidget {
  final SpeakerMatch partner;
  final String matchId;
  final String channelName;
  final int durationSeconds;
  final List<ConversationMessage> messages;

  const CallSummaryScreen({
    super.key,
    required this.partner,
    required this.matchId,
    required this.channelName,
    required this.durationSeconds,
    required this.messages,
    this.isReadOnly = false,
    this.initialRating,
    this.initialFeedback,
  });

  final bool isReadOnly;
  final int? initialRating;
  final String? initialFeedback;

  @override
  State<CallSummaryScreen> createState() => _CallSummaryScreenState();
}

class _CallSummaryScreenState extends State<CallSummaryScreen> {
  final VocabularyService _vocabularyService = VocabularyService();
  final MatchmakingService _matchmakingService = MatchmakingService();
  final CallAnalysisService _callAnalysisService = CallAnalysisService();
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _feedbackController = TextEditingController();

  int _rating = 0;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isNewHighScore = false;

  // Session Analysis Data
  SessionData? _sessionData;

  @override
  void initState() {
    super.initState();
    if (widget.initialRating != null) {
      _rating = widget.initialRating!;
    }
    if (widget.initialFeedback != null) {
      _feedbackController.text = widget.initialFeedback!;
    }
    _loadSessionData();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _loadSessionData() async {
    try {
      final currentUser = _authService.currentUser;
      // Create user-specific session ID
      final sessionId = currentUser != null
          ? '${widget.channelName}_${currentUser.uid}'
          : widget.channelName;
      debugPrint('CallSummary: Loading data for session: $sessionId');
      debugPrint('CallSummary: Messages count: ${widget.messages.length}');

      // CASE 1: Opening from Home (History) - Messages empty
      if (widget.messages.isEmpty) {
        debugPrint(
          'CallSummary: Opening from history, loading from Firestore...',
        );
        // Try new format first (channelName_userId), then fallback to old format (channelName)
        SessionData? savedData = await _firestoreService.getSessionAnalysis(
          sessionId,
        );
        if (savedData == null) {
          debugPrint('CallSummary: Trying old format with just channelName...');
          savedData = await _firestoreService.getSessionAnalysis(
            widget.channelName,
          );
        }

        if (savedData != null) {
          debugPrint(
            'CallSummary: Found saved data! Score: ${savedData.score}, Corrections: ${savedData.corrections.length}, Vocab: ${savedData.vocabulary.length}',
          );
          if (mounted) {
            setState(() {
              _sessionData = savedData;
              _isLoading = false;
            });
          }
          return;
        } else {
          // No data found in Firestore - show default state with estimated data
          debugPrint(
            'CallSummary: No saved data found, showing estimated data',
          );
          final durationMins = widget.durationSeconds ~/ 60;
          if (mounted) {
            setState(() {
              _sessionData = SessionData(
                score: (durationMins * 10).clamp(
                  10,
                  50,
                ), // Estimate based on duration
                minutes: durationMins > 0 ? durationMins : 1,
                exchanges: 0,
                newWords: 0,
                skills: [
                  SkillProgress(name: 'Vocabulary', percentage: 0.5),
                  SkillProgress(name: 'Grammar', percentage: 0.5),
                  SkillProgress(name: 'Pronunciation', percentage: 0.5),
                ],
                corrections: [],
                vocabulary: [],
                instructor: InstructorInfo(
                  name: widget.partner.name,
                  imageUrl: '',
                ),
              );
              _isLoading = false;
            });
          }
          return;
        }
      }

      // CASE 2: Fresh Call - Analyze and Save

      // 1. Load vocabulary words
      final words = await _vocabularyService.getSessionWords(
        widget.channelName,
      );

      // 2. Prepare vocabulary items
      final vocabItems = words
          .map(
            (word) => VocabularyItem(
              word: word.original,
              translation: word.translated,
            ),
          )
          .toList();

      // 3. Create instructor info
      final instructor = InstructorInfo(
        name: widget.partner.name,
        imageUrl: widget.partner.avatarUrl ?? '',
      );

      // 4. Analyze session
      // Use existing messages if available, otherwise use empty list (though typically wont happen in this branch)
      final analysis = _callAnalysisService.analyzeSession(
        messages: widget.messages,
        durationSeconds: widget.durationSeconds,
        vocabulary: vocabItems,
        instructor: instructor,
      );

      // 5. Save Analysis & Check High Score
      bool newHighScore = false;
      if (currentUser != null) {
        // Create user-specific session ID
        final sessionId = '${widget.channelName}_${currentUser.uid}';
        debugPrint('CallSummary: Saving analysis to Firestore...');
        debugPrint('CallSummary: Session ID: $sessionId');
        debugPrint(
          'CallSummary: Score: ${analysis.score}, Corrections: ${analysis.corrections.length}, Vocab: ${analysis.vocabulary.length}',
        );
        // Save full analysis with user-specific key
        await _firestoreService.saveSessionAnalysis(sessionId, analysis);

        // Update High Score
        newHighScore = await _firestoreService.updateUserHighScore(
          currentUser.uid,
          analysis.score,
        );
      }

      if (mounted) {
        setState(() {
          _sessionData = analysis;
          _isNewHighScore = newHighScore;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading session data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String get _formattedDuration {
    final minutes = widget.durationSeconds ~/ 60;
    final seconds = widget.durationSeconds % 60;
    return '${minutes}m ${seconds}s';
  }

  Future<void> _submitRating() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a rating')));
      return;
    }

    final user = _authService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User not logged in')));
      return;
    }

    setState(() => _isSaving = true);

    await _matchmakingService.updateRating(
      widget.matchId,
      user.uid,
      _rating,
      _feedbackController.text.trim(),
    );

    setState(() => _isSaving = false);

    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sessionBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Call Summary',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading || _sessionData == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Partner Info Card
                  _buildSummaryCard(),
                  const SizedBox(height: 32),

                  // Score Widget
                  Center(
                    child: CircularScoreWidget(
                      score: _sessionData!.score,
                      isNewHighScore: _isNewHighScore,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Session Stats Section
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: SessionStatsCard(
                            icon: Icons.access_time,
                            value: _formattedDuration,
                            label: 'Duration',
                            iconColor: AppColors.iconBlue,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SessionStatsCard(
                            icon: Icons.chat_bubble_outline,
                            value: '${_sessionData!.exchanges}',
                            label: 'Exchanges',
                            iconColor: AppColors.iconGreen,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SessionStatsCard(
                            icon: Icons.library_books,
                            value: '${_sessionData!.newWords}',
                            label: 'Words',
                            iconColor: AppColors.iconPurple,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Skills Progress Section
                  Text(
                    'Your Progress',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: _sessionData!.skills
                          .map(
                            (skill) => SkillProgressBar(
                              skillName: skill.name,
                              percentage: skill.percentage,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Conversation Timeline Section
                  Text(
                    'Conversation Timeline',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_sessionData!.corrections.isEmpty)
                    _buildEmptyState('No conversation recorded')
                  else
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: CorrectionsTimeline(
                        corrections: _sessionData!.corrections,
                      ),
                    ),
                  const SizedBox(height: 32),

                  // New Vocabulary Section
                  Text(
                    'New Vocabulary',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_sessionData!
                      .vocabulary
                      .isEmpty) // Use data from _sessionData
                    _buildEmptyState('No new words collected')
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.5,
                          ),
                      itemCount: _sessionData!.vocabulary.length,
                      itemBuilder: (context, index) {
                        return VocabularyCard(
                          item: _sessionData!.vocabulary[index],
                          index: index,
                        );
                      },
                    ),

                  const SizedBox(height: 32),

                  // Rating Section
                  if (!widget.isReadOnly || _rating > 0) ...[
                    _buildSection(
                      widget.isReadOnly ? 'Your Rating' : 'Rate Your Partner',
                      Icons.star_outline,
                      _buildRatingWidget(),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Submit Button (only if not read-only)
                  if (!widget.isReadOnly)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _submitRating,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Done',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: widget.partner.avatarUrl != null && widget.partner.avatarUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      widget.partner.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.person, color: Colors.white, size: 32),
                    ),
                  )
                : const Icon(Icons.person, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.partner.name,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Call ended',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Duration
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text(
                  _formattedDuration,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(message, style: TextStyle(color: Colors.grey.shade500)),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }

  Widget _buildRatingWidget() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Stars
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: widget.isReadOnly
                    ? null
                    : () => setState(() => _rating = index + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    size: 40,
                    color: Colors.amber,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),

          const SizedBox(height: 16),
          // Feedback text field - Read Only handling
          if (widget.isReadOnly)
            _feedbackController.text.isNotEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      _feedbackController.text,
                      style: GoogleFonts.inter(
                        color: Colors.black87,
                        fontSize: 14,
                      ),
                    ),
                  )
                : const SizedBox.shrink()
          else
            TextField(
              controller: _feedbackController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Share your experience (optional)',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
