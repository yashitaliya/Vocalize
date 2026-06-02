import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../models/test_model.dart';
import '../../models/test_result_model.dart';
import '../../services/auth_service.dart';
import '../../services/test_service.dart';
import '../../services/firestore_service.dart';
import 'test_taking_screen.dart';
import 'test_result_screen.dart';

class TestListScreen extends StatefulWidget {
  const TestListScreen({Key? key}) : super(key: key);

  @override
  State<TestListScreen> createState() => _TestListScreenState();
}

class _TestListScreenState extends State<TestListScreen> {
  final AuthService _authService = AuthService();
  final TestService _testService = TestService();
  final FirestoreService _firestoreService = FirestoreService();

  String? _selectedLanguage;
  List<TestModel> _availableTests = [];
  Map<String, TestResultModel?> _testResults = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserLanguageAndTests();
  }

  Future<void> _loadUserLanguageAndTests() async {
    setState(() => _isLoading = true);

    final user = _authService.currentUser;
    if (user != null) {
      final userData = await _firestoreService.getUser(user.uid);
      final language = userData?.selectedLanguage ?? 'Spanish';

      setState(() => _selectedLanguage = language);

      // Get tests for the language
      var tests = await _testService.getTestsForLanguage(language);

      // Generate and store new tests ONLY if none exist
      if (tests.isEmpty) {
        final generatedTests = TestService.generateTestsForLanguage(language);
        for (var test in generatedTests) {
          await _firestoreService.createTest(test);
        }
        tests = generatedTests;
      }

      // Load all test results at once to avoid N+1 queries and use Firestore cache
      final allResults = await _firestoreService.getUserTestResults(user.uid);
      _testResults.clear();
      
      for (var result in allResults) {
        // Keep the most recent result for each test
        if (!_testResults.containsKey(result.testId) || 
            result.completedAt.isAfter(_testResults[result.testId]!.completedAt)) {
          _testResults[result.testId] = result;
        }
      }

      setState(() {
        _availableTests = tests;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.white,
      elevation: 0,
      title: Text(
        'Language Tests',
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildBody() {
    if (_selectedLanguage == null) {
      return _buildNoLanguageSelected();
    }

    if (_availableTests.isEmpty) {
      return _buildNoTestsAvailable();
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLanguageHeader(),
          const SizedBox(height: 24),
          _buildTestsList(),
        ],
      ),
    );
  }

  Widget _buildLanguageHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.language, color: AppTheme.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Learning Language',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedLanguage!,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Tests',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ..._availableTests.map((test) => _buildTestCard(test)),
      ],
    );
  }

  Widget _buildTestCard(TestModel test) {
    final result = _testResults[test.testId];
    final hasAttempted = result != null;

    // Locking Logic
    bool isLocked = false;
    if (test.level > 1) {
      // Find previous level test
      // Assuming _availableTests is sorted by level 1-10
      // Previous level index is current level - 2 (since levels are 1-based)
      final prevIndex = test.level - 2;
      if (prevIndex >= 0 && prevIndex < _availableTests.length) {
        final prevTest = _availableTests[prevIndex];
        final prevResult = _testResults[prevTest.testId];

        // Locked if previous result is missing OR previous percentage < 80
        if (prevResult == null || prevResult.percentage < 80) {
          isLocked = true;
        }
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isLocked ? AppTheme.surface : AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor.withValues(alpha: isLocked ? 0.3 : 1.0),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      test.title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isLocked
                            ? AppTheme.textSecondary
                            : AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      test.description,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasAttempted)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getScoreColor(
                      result.percentage,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${result.percentage.toStringAsFixed(0)}%',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _getScoreColor(result.percentage),
                    ),
                  ),
                )
              else if (isLocked)
                Icon(Icons.lock_outline, color: AppTheme.textTertiary),
            ],
          ),
          const SizedBox(height: 16),
          if (isLocked) ...[
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: AppTheme.textTertiary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Pass Level ${test.level - 1} with 80% to unlock',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ] else ...[
            Row(
              children: [
                Icon(
                  Icons.quiz_outlined,
                  size: 16,
                  color: AppTheme.textTertiary,
                ),
                const SizedBox(width: 6),
                Text(
                  '${test.questions.length} Questions',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.textTertiary,
                  ),
                ),
                if (hasAttempted) ...[
                  const SizedBox(width: 16),
                  Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: AppTheme.achievementGreen,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Completed',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.achievementGreen,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
          ],

          if (hasAttempted)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _viewResult(test, result),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(color: AppTheme.primary),
                    ),
                    child: Text(
                      'View Result',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _startTest(test),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Retake Test',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.white,
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLocked ? null : () => _startTest(test),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLocked
                      ? AppTheme.textTertiary
                      : AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  isLocked ? 'Locked' : 'Start Test',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNoLanguageSelected() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.language_outlined,
              size: 80,
              color: AppTheme.textTertiary,
            ),
            const SizedBox(height: 24),
            Text(
              'No Language Selected',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Please select a language in your profile to see available tests.',
              textAlign: TextAlign.center,
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

  Widget _buildNoTestsAvailable() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.quiz_outlined, size: 80, color: AppTheme.textTertiary),
            const SizedBox(height: 24),
            Text(
              'No Tests Available',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tests for $_selectedLanguage are coming soon!',
              textAlign: TextAlign.center,
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

  Color _getScoreColor(double percentage) {
    if (percentage >= 80) return AppTheme.achievementGreen;
    if (percentage >= 60) return AppTheme.achievementGold;
    return AppTheme.achievementRed;
  }

  void _viewResult(TestModel test, TestResultModel result) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TestResultScreen(test: test, result: result),
      ),
    );
  }

  void _startTest(TestModel test) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TestTakingScreen(test: test)),
    ).then((_) => _loadUserLanguageAndTests());
  }
}
