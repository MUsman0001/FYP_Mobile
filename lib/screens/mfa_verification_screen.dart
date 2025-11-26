import 'package:flutter/material.dart';
import 'dart:async';
import '../core/api_client.dart';
import '../features/auth/auth_api.dart';
import '../features/auth/auth_repository.dart';
import '../core/app_theme.dart';
import 'home_screen.dart';
import 'login_screen.dart' as login;

class MfaVerificationScreen extends StatefulWidget {
  final int userId;
  final String email;
  final String pNo;
  final String userName;

  const MfaVerificationScreen({
    super.key,
    required this.userId,
    required this.email,
    required this.pNo,
    required this.userName,
  });

  @override
  State<MfaVerificationScreen> createState() => _MfaVerificationScreenState();
}

class _MfaVerificationScreenState extends State<MfaVerificationScreen> {
  final codeControllers = List<TextEditingController>.generate(
    6,
    (_) => TextEditingController(),
  );
  late final AuthRepository authRepository;
  bool isVerifying = false;
  bool isResending = false;
  String? errorText;
  int _secondsRemaining = 600; // 10 minutes
  late Timer _timer;
  bool _codeExpired = false;

  @override
  void initState() {
    super.initState();
    final api = AuthApi(ApiClient());
    authRepository = AuthRepository(
      api: api,
      storage: api.client.secureStorage,
    );
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    for (var controller in codeControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsRemaining--;
        if (_secondsRemaining <= 0) {
          _codeExpired = true;
          timer.cancel();
        }
      });
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _handleVerify() async {
    final code = codeControllers.map((c) => c.text).join();

    if (code.length != 6) {
      setState(() => errorText = 'Please enter all 6 digits');
      return;
    }

    if (_codeExpired) {
      setState(() => errorText = 'Code has expired. Please request a new one.');
      return;
    }

    setState(() {
      isVerifying = true;
      errorText = null;
    });

    try {
      await authRepository.verifyMfa(userId: widget.userId, code: code);

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } catch (e) {
      setState(() {
        errorText = 'Invalid or expired code. Please try again.';
      });
      // Clear the input fields
      for (var controller in codeControllers) {
        controller.clear();
      }
    } finally {
      if (mounted) setState(() => isVerifying = false);
    }
  }

  Future<void> _handleResend() async {
    setState(() => isResending = true);

    try {
      await authRepository.resendMfaCode(userId: widget.userId);
      setState(() {
        errorText = null;
        _secondsRemaining = 600;
        _codeExpired = false;
        for (var controller in codeControllers) {
          controller.clear();
        }
      });
      _startTimer();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code resent to your email')),
      );
    } catch (e) {
      setState(() => errorText = 'Failed to resend code. Please try again.');
    } finally {
      if (mounted) setState(() => isResending = false);
    }
  }

  Future<void> _handleBackToLogin() async {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const login.LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFF003f2a);
    final brandFill = brand.withValues(alpha: 0.06);
    final brandBorder = brand.withValues(alpha: 0.30);

    return PopScope(
      canPop: false, // Prevent back button
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Lock icon
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.lightGreen,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.security,
                        size: 48,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    const Text(
                      'Two-Factor Authentication',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Description
                    Text(
                      'Enter the 6-digit verification code sent to\n${widget.email}',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 24),

                    // Code input fields
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        6,
                        (index) => Container(
                          width: 50,
                          height: 60,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          child: TextField(
                            controller: codeControllers[index],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 1,
                            enabled: !isVerifying && !_codeExpired,
                            decoration: InputDecoration(
                              counter: const SizedBox.shrink(),
                              filled: true,
                              fillColor: brandFill,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: brandBorder),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: brandBorder),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: brand,
                                  width: 1.5,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.red[400]!),
                              ),
                            ),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 8,
                            ),
                            onChanged: (value) {
                              if (value.isNotEmpty && index < 5) {
                                FocusScope.of(context).nextFocus();
                              }
                            },
                            onSubmitted: (_) {
                              if (index == 5) {
                                _handleVerify();
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Timer and expiry warning
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _codeExpired ? Colors.red[50] : Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _codeExpired
                              ? Colors.red[200]!
                              : Colors.blue[200]!,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _codeExpired ? Icons.error_outline : Icons.schedule,
                            color: _codeExpired
                                ? Colors.red[700]
                                : Colors.blue[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _codeExpired
                                ? 'Code expired. Resend to get a new one.'
                                : 'Code expires in ${_formatTime(_secondsRemaining)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: _codeExpired
                                  ? Colors.red[700]
                                  : Colors.blue[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Error message
                    if (errorText != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          border: Border.all(color: Colors.red[200]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red[700]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorText!,
                                style: TextStyle(color: Colors.red[700]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Verify button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          backgroundColor: brand,
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        onPressed: (isVerifying || _codeExpired)
                            ? null
                            : _handleVerify,
                        child: isVerifying
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text('Verify'),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Resend code
                    SizedBox(
                      width: double.infinity,
                      child: Align(
                        alignment: Alignment.center,
                        child: TextButton(
                          onPressed: isResending ? null : _handleResend,
                          style: TextButton.styleFrom(
                            foregroundColor: brand,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: const Size(0, 36),
                          ),
                          child: isResending
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text("Didn't receive code? Resend"),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Back to login button
                    SizedBox(
                      width: double.infinity,
                      child: Align(
                        alignment: Alignment.center,
                        child: TextButton(
                          onPressed: _handleBackToLogin,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey[600],
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: const Size(0, 36),
                          ),
                          child: const Text('Back to Login'),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Footer
                    Text(
                      '© 2025 Pakistan International Airlines',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
