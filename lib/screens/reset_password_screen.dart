import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../features/auth/auth_api.dart';
import '../features/auth/auth_repository.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;

  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final codeController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool isLoading = false;
  bool showPassword = false;
  bool showConfirmPassword = false;
  String? errorText;
  String? successText;

  late final AuthRepository authRepository;

  @override
  void initState() {
    super.initState();
    final api = AuthApi(ApiClient());
    authRepository = AuthRepository(
      api: api,
      storage: api.client.secureStorage,
    );
  }

  @override
  void dispose() {
    codeController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    // Validation
    if (codeController.text.trim().isEmpty) {
      setState(() => errorText = 'Please enter the verification code');
      return;
    }

    if (passwordController.text.isEmpty) {
      setState(() => errorText = 'Please enter a new password');
      return;
    }

    if (passwordController.text.length < 6) {
      setState(() => errorText = 'Password must be at least 6 characters');
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      setState(() => errorText = 'Passwords do not match');
      return;
    }

    setState(() {
      isLoading = true;
      errorText = null;
      successText = null;
    });

    try {
      await authRepository.resetPassword(
        widget.email,
        codeController.text.trim(),
        passwordController.text,
      );

      if (!mounted) return;

      setState(() {
        successText = 'Password reset successfully! Redirecting to login...';
      });

      // Navigate back to login screen after 2 seconds
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    } catch (e) {
      setState(() => errorText = 'Password reset failed. Please try again.');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const darkBg = Color(0xFF0f172a);
    const darkBg2 = Color(0xFF1e293b);
    const tealAccent = Color(0xFF14b8a6);
    const borderColor = Color(0xFF334155);

    return Scaffold(
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Row(
                        children: const [
                          Icon(Icons.arrow_back, color: Colors.white, size: 20),
                          SizedBox(width: 4),
                          Text(
                            'Back',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),

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
                              Icons.lock_reset,
                              color: darkBg,
                              size: 36,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Heading
                        const Text(
                          'Reset Password',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),

                        // Subtitle
                        const Text(
                          'Enter the code we sent and choose a new password',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF94a3b8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        // Card Container
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            border: Border.all(color: borderColor, width: 1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Code label
                              const Text(
                                'Verification Code',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Code input
                              TextField(
                                controller: codeController,
                                textInputAction: TextInputAction.next,
                                onSubmitted: (_) =>
                                    FocusScope.of(context).nextFocus(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                                decoration: InputDecoration(
                                  hintText: '6-digit code',
                                  hintStyle: const TextStyle(
                                    color: Color(0xFF64748b),
                                    fontSize: 13,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withValues(
                                    alpha: 0.05,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: borderColor,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: borderColor,
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: tealAccent,
                                      width: 1.5,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // New password label
                              const Text(
                                'New Password',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // New password input
                              TextField(
                                controller: passwordController,
                                obscureText: !showPassword,
                                textInputAction: TextInputAction.next,
                                onSubmitted: (_) =>
                                    FocusScope.of(context).nextFocus(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Enter new password',
                                  hintStyle: const TextStyle(
                                    color: Color(0xFF64748b),
                                    fontSize: 13,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withValues(
                                    alpha: 0.05,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      showPassword
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: const Color(0xFF64748b),
                                      size: 20,
                                    ),
                                    onPressed: () => setState(
                                      () => showPassword = !showPassword,
                                    ),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: borderColor,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: borderColor,
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: tealAccent,
                                      width: 1.5,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Confirm password label
                              const Text(
                                'Confirm Password',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Confirm password input
                              TextField(
                                controller: confirmPasswordController,
                                obscureText: !showConfirmPassword,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _handleResetPassword(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Re-enter new password',
                                  hintStyle: const TextStyle(
                                    color: Color(0xFF64748b),
                                    fontSize: 13,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withValues(
                                    alpha: 0.05,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      showConfirmPassword
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: const Color(0xFF64748b),
                                      size: 20,
                                    ),
                                    onPressed: () => setState(
                                      () => showConfirmPassword =
                                          !showConfirmPassword,
                                    ),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: borderColor,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: borderColor,
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: tealAccent,
                                      width: 1.5,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                ),
                              ),

                              // Error message
                              if (errorText != null)
                                Column(
                                  children: [
                                    const SizedBox(height: 16),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.red.withValues(
                                          alpha: 0.15,
                                        ),
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
                                ),

                              // Success message
                              if (successText != null)
                                Column(
                                  children: [
                                    const SizedBox(height: 16),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: tealAccent.withValues(
                                          alpha: 0.15,
                                        ),
                                        border: Border.all(
                                          color: tealAccent.withValues(
                                            alpha: 0.3,
                                          ),
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.check_circle_outline,
                                            color: tealAccent,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              successText!,
                                              style: const TextStyle(
                                                color: tealAccent,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                              const SizedBox(height: 20),

                              // Reset Password button
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
                                  onPressed: isLoading
                                      ? null
                                      : _handleResetPassword,
                                  child: isLoading
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
                                          'Reset Password',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
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
    );
  }
}
