import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../utils/firebase_vocab_setup.dart';

class VocabularySetupScreen extends StatefulWidget {
  const VocabularySetupScreen({super.key});

  @override
  State<VocabularySetupScreen> createState() => _VocabularySetupScreenState();
}

class _VocabularySetupScreenState extends State<VocabularySetupScreen> {
  bool _isLoading = false;
  String _statusMessage = '';
  bool _setupComplete = false;

  @override
  void initState() {
    super.initState();
    _checkSetupStatus();
  }

  Future<void> _checkSetupStatus() async {
    final isPopulated = await FirebaseVocabSetup.isVocabularyPopulated();
    setState(() {
      _setupComplete = isPopulated;
    });
  }

  Future<void> _setupVocabulary() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Setting up vocabulary database...';
    });

    try {
      await FirebaseVocabSetup.setupVocabularyDatabase();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = '✓ Vocabulary database setup completed!';
          _setupComplete = true;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vocabulary database populated successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = '✗ Error: ${e.toString()}';
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _getStatistics() async {
    setState(() => _isLoading = true);

    try {
      final stats = await FirebaseVocabSetup.getVocabularyStats();
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Vocabulary Statistics'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Words: ${stats['totalWords'] ?? 0}'),
                Text('Languages: ${stats['languageCount'] ?? 0}'),
                Text('Categories: ${stats['categoryCount'] ?? 0}'),
                const SizedBox(height: 16),
                const Text('Languages:'),
                Text(
                  (stats['languages'] as List?)?.join(', ') ?? 'None',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Vocabulary Database',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        backgroundColor: AppTheme.white,
        elevation: 0.5,
        centerTitle: false,
        toolbarHeight: 56,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _setupComplete ? Colors.green[50] : Colors.orange[50],
                  border: Border.all(
                    color: _setupComplete ? Colors.green : Colors.orange,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _setupComplete
                          ? '✓ Vocabulary Database Ready'
                          : '⚠ Vocabulary Database Not Found',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _setupComplete ? Colors.green[700] : Colors.orange[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _setupComplete
                          ? 'Your vocabulary collection is already populated and ready to use!'
                          : 'No vocabulary collection found in Firebase. Tap below to create and populate it automatically.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Instructions
              Text(
                'What This Does',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '• Creates a "vocabulary" collection in Firebase\n'
                '• Uploads 176 vocabulary words across 8 languages\n'
                '• Includes Spanish, French, German, Italian, Portuguese, Japanese, Chinese, Korean\n'
                '• Each word has pronunciation, examples, and categories',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 30),

              // Setup Button
              if (!_setupComplete)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _setupVocabulary,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue,
                      disabledBackgroundColor: Colors.grey,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Setup Vocabulary Database',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),

              if (_setupComplete)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _getStatistics,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.green,
                    ),
                    child: Text(
                      'View Statistics',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // Status Message
              if (_statusMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    border: Border.all(color: AppTheme.divider),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusMessage,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: _statusMessage.contains('✓')
                          ? Colors.green[700]
                          : _statusMessage.contains('✗')
                              ? Colors.red[700]
                              : AppTheme.textSecondary,
                    ),
                  ),
                ),

              const SizedBox(height: 30),

              // Info Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  border: Border.all(color: Colors.blue[200]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ℹ About This Setup',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[900],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This setup screen initializes your vocabulary database with all the language data. '
                      'Once complete, the Flashcards and Vocabulary screens will fetch data from Firebase instead of using hardcoded data.\n\n'
                      'You can manually edit vocabulary in the Firebase Console if needed.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.blue[800],
                        height: 1.5,
                      ),
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
}
