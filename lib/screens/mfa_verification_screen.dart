import 'package:flutter/material.dart';
import 'dart:async';
import '../core/api_client.dart';
import '../features/auth/auth_api.dart';
import '../features/auth/auth_repository.dart';
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
      if (_timer.isActive) {
        _timer.cancel();
      }
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
    const darkBg = Color(0xFF0f172a);
    const darkBg2 = Color(0xFF1e293b);
    const tealAccent = Color(0xFF14b8a6);
    const borderColor = Color(0xFF334155);

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [darkBg, darkBg2],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back button
                      GestureDetector(
                        onTap: _handleBackToLogin,
                        child: Row(
                          children: const [
                            Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Back',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Center content
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Lock icon in teal circle
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: tealAccent,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.security,
                                color: darkBg,
                                size: 36,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Title
                          const Text(
                            'Two-Factor Authentication',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),

                          // Description
                          Text(
                            'Enter the 6-digit code sent to\n${widget.email}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF94a3b8),
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Card container
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              border: Border.all(color: borderColor, width: 1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Code input fields
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    6,
                                    (index) => Container(
                                      width: 46,
                                      height: 56,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                      ),
                                      child: TextField(
                                        controller: codeControllers[index],
                                        textAlign: TextAlign.center,
                                        keyboardType: TextInputType.number,
                                        maxLength: 1,
                                        enabled: !isVerifying && !_codeExpired,
                                        decoration: InputDecoration(
                                          counter: const SizedBox.shrink(),
                                          filled: true,
                                          fillColor: Colors.white.withValues(
                                            alpha: 0.05,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            borderSide: const BorderSide(
                                              color: borderColor,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            borderSide: const BorderSide(
                                              color: borderColor,
                                              width: 1,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            borderSide: const BorderSide(
                                              color: tealAccent,
                                              width: 1.5,
                                            ),
                                          ),
                                          errorBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            borderSide: BorderSide(
                                              color: Colors.red[400]!,
                                            ),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                vertical: 12,
                                              ),
                                        ),
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 4,
                                          color: Colors.white,
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

                                // Timer / expiry
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _codeExpired
                                        ? Colors.red.withValues(alpha: 0.12)
                                        : Colors.white.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: _codeExpired
                                          ? Colors.red.withValues(alpha: 0.3)
                                          : borderColor,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _codeExpired
                                            ? Icons.error_outline
                                            : Icons.schedule,
                                        color: _codeExpired
                                            ? Colors.red
                                            : tealAccent,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _codeExpired
                                            ? 'Code expired. Resend to get a new one.'
                                            : 'Code expires in ${_formatTime(_secondsRemaining)}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: _codeExpired
                                              ? Colors.red
                                              : Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Error message
                                if (errorText != null) ...[
                                  const SizedBox(height: 14),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.red.withValues(alpha: 0.15),
                                      border: Border.all(
                                        color: Colors.red.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.error_outline,
                                          color: Colors.red,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            errorText!,
                                            style: const TextStyle(
                                              color: Colors.red,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 18),

                                // Verify button
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: tealAccent,
                                      foregroundColor: darkBg,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      disabledBackgroundColor: tealAccent
                                          .withValues(alpha: 0.5),
                                    ),
                                    onPressed: (isVerifying || _codeExpired)
                                        ? null
                                        : _handleVerify,
                                    child: isVerifying
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    darkBg,
                                                  ),
                                            ),
                                          )
                                        : const Text(
                                            'Verify Code',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                  ),
                                ),

                                const SizedBox(height: 12),

                                // Resend code
                                TextButton(
                                  onPressed: isResending ? null : _handleResend,
                                  style: TextButton.styleFrom(
                                    foregroundColor: tealAccent,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 8,
                                    ),
                                    minimumSize: const Size(0, 36),
                                  ),
                                  child: isResending
                                      ? const SizedBox(
                                          height: 16,
                                          width: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  tealAccent,
                                                ),
                                          ),
                                        )
                                      : const Text(
                                          "Didn't receive code? Resend",
                                          style: TextStyle(fontSize: 13),
                                        ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Back to login
                          TextButton(
                            onPressed: _handleBackToLogin,
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF94a3b8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                              minimumSize: const Size(0, 36),
                            ),
                            child: const Text('Back to Login'),
                          ),

                          const SizedBox(height: 16),

                          // Footer
                          const Text(
                            '© 2025 AeroCrew. All rights reserved.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF94a3b8),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
