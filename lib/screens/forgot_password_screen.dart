import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../features/auth/auth_api.dart';
import '../features/auth/auth_repository.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailController = TextEditingController();
  bool isLoading = false;
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
    emailController.dispose();
    super.dispose();
  }

  Future<void> _handleRequestReset() async {
    if (emailController.text.trim().isEmpty) {
      setState(() => errorText = 'Please enter your email address');
      return;
    }

    setState(() {
      isLoading = true;
      errorText = null;
      successText = null;
    });

    try {
      await authRepository.requestPasswordReset(emailController.text.trim());
      if (!mounted) return;

      setState(() {
        successText =
            'Password reset code sent to your email. Check your inbox.';
      });

      // Navigate to reset password screen after 2 seconds
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              ResetPasswordScreen(email: emailController.text.trim()),
        ),
      );
    } catch (e) {
      setState(
        () => errorText = 'Unable to send reset code. Please try again.',
      );
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
                        // Email icon in teal circle
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: tealAccent,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.mail_outline,
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
                          'Enter your email and we\'ll send you a verification code',
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
                              // Email Label
                              const Text(
                                'Email Address',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Email Input
                              TextField(
                                controller: emailController,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _handleRequestReset(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'your.email@example.com',
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

                              // Error message
                              if (errorText != null)
                                Column(
                                  children: [
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
                                    const SizedBox(height: 16),
                                  ],
                                ),

                              // Success message
                              if (successText != null)
                                Column(
                                  children: [
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
                                    const SizedBox(height: 16),
                                  ],
                                ),

                              // Send Reset Code Button
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
                                      : _handleRequestReset,
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
                                          'Send Reset Code',
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
