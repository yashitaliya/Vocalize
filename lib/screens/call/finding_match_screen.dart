import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../models/call_models.dart';
import '../../services/auth_service.dart';
import '../../services/matchmaking_service.dart';
import '../../services/firestore_service.dart'; // Added import
import 'widgets/call_widgets.dart';
import 'video_call_screen.dart';

class FindingMatchScreen extends StatefulWidget {
  // We'll ignore the passed language if we find a user preference
  final String language;
  final String languageFlag;
  final String topic;
  final String topicEmoji;
  final String level;

  const FindingMatchScreen({
    super.key,
    this.language = 'Spanish',
    this.languageFlag = '🇪🇸',
    this.topic = 'Travel & Adventure',
    this.topicEmoji = '✈️',
    this.level = 'Intermediate',
  });

  @override
  State<FindingMatchScreen> createState() => _FindingMatchScreenState();
}

class _FindingMatchScreenState extends State<FindingMatchScreen>
    with SingleTickerProviderStateMixin {
  MatchStatus _currentStatus = MatchStatus.scanning;
  int _speakersFound = 0;

  final MatchmakingService _matchmakingService = MatchmakingService();
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  StreamSubscription? _matchSubscription;
  Timer? _timeoutTimer;
  bool _isDialogShowing = false;

  String? _targetLanguage; // State variable for fetched language
  String? _userAvatar; // Add user avatar state
  String? _userTopic;
  String? _userTopicEmoji;

  late AnimationController _pulseController;

  // Timeout duration in seconds (30 seconds default)
  static const int _timeoutSeconds = 30;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _loadUserPreferences(); // Load prefs first
  }

  Future<void> _loadUserPreferences() async {
    final user = _authService.currentUser;
    if (user != null) {
      final userModel = await _firestoreService.getUser(user.uid);
      if (mounted) {
        setState(() {
          if (userModel?.selectedLanguage != null) {
            _targetLanguage = userModel!.selectedLanguage;
          }
          _userAvatar = userModel?.avatarUrl ?? user.photoURL;
          if (userModel?.interests != null && userModel!.interests.isNotEmpty) {
            _userTopic = userModel.interests.first;
            _userTopicEmoji = _getEmojiForInterest(_userTopic!);
          }
        });
      }
    }
    _startMatchingProcess(); // Start after loading (or if null still start)
  }

  String _getEmojiForInterest(String interest) {
    switch (interest) {
      case 'Music':
        return '🎵';
      case 'Travel':
        return '✈️';
      case 'Cooking':
        return '🍳';
      case 'Business':
        return '💼';
      case 'Gaming':
        return '🎮';
      case 'Books':
        return '📚';
      case 'Sports':
        return '⚽';
      case 'Art':
        return '🎨';
      default:
        return '💬';
    }
  }

  String _getFlagForLanguage(String language) {
    switch (language.toLowerCase()) {
      case 'spanish':
        return '🇪🇸';
      case 'french':
        return '🇫🇷';
      case 'german':
        return '🇩🇪';
      case 'italian':
        return '🇮🇹';
      case 'portuguese':
        return '🇵🇹';
      case 'japanese':
        return '🇯🇵';
      case 'chinese':
        return '🇨🇳';
      case 'korean':
        return '🇰🇷';
      case 'arabic':
        return '🇸🇦';
      case 'hindi':
        return '🇮🇳';
      case 'russian':
        return '🇷🇺';
      case 'dutch':
        return '🇳🇱';
      case 'turkish':
        return '🇹🇷';
      default:
        return '🌐';
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _matchSubscription?.cancel();
    _timeoutTimer?.cancel();
    _matchmakingService.leaveQueue();
    super.dispose();
  }

  Future<void> _startMatchingProcess() async {
    final user = _authService.currentUser;
    if (user == null) {
      debugPrint('FindingMatchScreen: No user logged in');
      if (mounted) {
        Navigator.of(context).pop();
      }
      return;
    }

    setState(() {
      _currentStatus = MatchStatus.scanning;
    });

    // Short delay for UI animation
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    setState(() {
      _currentStatus = MatchStatus.foundSpeakers;
      _speakersFound = 1;
    });

    try {
      // Try to find or create a match
      final result = await _matchmakingService.findOrCreateMatch(
        userId: user.uid,
        displayName: user.displayName ?? 'User',
        language: _targetLanguage ?? widget.language,
        avatarUrl: _userAvatar ?? '',
      );

      if (!mounted) return;

      if (result.isMatched) {
        // Immediately matched with someone!
        debugPrint(
          'FindingMatchScreen: Matched immediately! Channel: ${result.channelName}',
        );
        setState(() {
          _currentStatus = MatchStatus.matchFound;
          _speakersFound = 2;
        });

        await Future.delayed(const Duration(milliseconds: 500));
        _navigateToVideoCall(
          result.channelName!,
          result.partner!,
          result.matchId!,
        );
      } else {
        // Added to waiting queue - listen for match
        debugPrint('FindingMatchScreen: Waiting for match...');
        setState(() {
          _currentStatus = MatchStatus.matchingPreferences;
          _speakersFound = 0;
        });

        _listenForMatch(user.uid);
      }
    } catch (e) {
      debugPrint('FindingMatchScreen: Error in matchmaking: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error finding match: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  void _listenForMatch(String userId) {
    // Start timeout timer
    _startTimeoutTimer();
    
    _matchSubscription = _matchmakingService.listenForMatch(userId).listen((
      result,
    ) {
      if (result.isMatched && mounted) {
        // Cancel timeout timer on match found
        _timeoutTimer?.cancel();
        
        debugPrint(
          'FindingMatchScreen: Match found via listener! Channel: ${result.channelName}',
        );
        setState(() {
          _currentStatus = MatchStatus.matchFound;
          _speakersFound = 2;
        });

        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _navigateToVideoCall(
              result.channelName!,
              result.partner!,
              result.matchId!,
            );
          }
        });
      }
    });
  }

  void _startTimeoutTimer() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(Duration(seconds: _timeoutSeconds), () {
      if (mounted && !_isDialogShowing && _currentStatus != MatchStatus.matchFound) {
        _showTimeoutDialog();
      }
    });
  }

  void _showTimeoutDialog() {
    _isDialogShowing = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: AppColors.background,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon with gradient background
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.hourglass_empty_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 20),
                // Title
                Text(
                  'No Match Yet',
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                // Content
                Text(
                  'We couldn\'t find a partner yet. Would you like to continue waiting or go back?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          _isDialogShowing = false;
                          _cancelSearch();
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.inputBorder),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Go Back',
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            _isDialogShowing = false;
                            // Restart the timeout timer
                            _startTimeoutTimer();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Keep Waiting',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToVideoCall(
    String channelName,
    SpeakerMatch partner,
    String matchId,
  ) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => VideoCallScreen(
          partner: partner,
          channelName: channelName,
          matchId: matchId,
        ),
      ),
    );
  }

  void _cancelSearch() {
    _matchSubscription?.cancel();
    _matchmakingService.leaveQueue();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f0f23)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Decorative circles
              const DecorativeCircles(),

              // Main content
              Center(
                child: SingleChildScrollView(
                  physics:
                      const ClampingScrollPhysics(), // Better for nested scrolls
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  child: ConstrainedBox(
                    // Ensure minimum height to center content if possible
                    constraints: BoxConstraints(
                      minHeight:
                          MediaQuery.of(context).size.height -
                          100, // Approximate safe area
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Pulsing avatar
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: 1.0 + (_pulseController.value * 0.1),
                              child: GlowingAvatar(
                                imageUrl: _userAvatar,
                                size: 100,
                                level: '',
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 32),

                        // Status badges
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            StatusBadge(
                              emoji: _getFlagForLanguage(
                                _targetLanguage ?? widget.language,
                              ),
                              label: _targetLanguage ?? widget.language,
                            ),
                            const SizedBox(width: 12),
                            StatusBadge(
                              emoji: _userTopicEmoji ?? widget.topicEmoji,
                              label: _userTopic ?? widget.topic,
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),

                        // Progress status
                        ProgressStatusItem(
                          text: 'Scanning for speakers...',
                          isActive: _currentStatus == MatchStatus.scanning,
                          isCompleted:
                              _currentStatus.index > MatchStatus.scanning.index,
                        ),
                        ProgressStatusItem(
                          text: _speakersFound > 0
                              ? 'Found $_speakersFound speakers online'
                              : 'Waiting for speakers...',
                          isActive:
                              _currentStatus == MatchStatus.foundSpeakers ||
                              _currentStatus == MatchStatus.matchingPreferences,
                          isCompleted:
                              _currentStatus.index >
                              MatchStatus.matchingPreferences.index,
                        ),
                        ProgressStatusItem(
                          text: 'Match found!',
                          isActive: _currentStatus == MatchStatus.matchFound,
                          isCompleted: false,
                        ),

                        const SizedBox(height: 48),

                        // Cancel button
                        OutlinedButton(
                          onPressed: _cancelSearch,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white24),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            'Cancel Search',
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
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
