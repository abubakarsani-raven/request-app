import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../../../core/utils/validators.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/services/permission_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final AuthController _authController = Get.find<AuthController>();
  final _obscurePassword = true.obs;

  bool _showBiometricButton = false;
  String _biometricLabel = 'Biometric';
  bool _biometricLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricOption();
  }

  Future<void> _loadBiometricOption() async {
    if (!Get.isRegistered<BiometricService>()) return;
    try {
      final bio = Get.find<BiometricService>();
      final available = await bio.isBiometricAvailable();
      final hasStored = await bio.hasStoredCredentials();
      final label = available ? await bio.getBiometricLabel() : 'Biometric';
      if (mounted) {
        setState(() {
          _showBiometricButton = available && hasStored;
          _biometricLabel = label;
        });
      }
    } catch (_) {
      // ignore
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.darkBackground,
                    AppColors.darkSurface,
                  ],
                )
              : AppColors.primaryGradient,
        ),
        child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.spacingXL),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                  SizedBox(height: AppConstants.spacingXXL - 8),
                  // Animated Logo
                  RepaintBoundary(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
                            padding: EdgeInsets.all(AppConstants.spacingM),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.primary.withOpacity(0.3)
                                  : AppColors.textOnPrimary.withOpacity(0.2),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (isDark ? AppColors.darkBackground : AppColors.textPrimary).withOpacity(0.1),
                                  blurRadius: 15,
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.directions_car_rounded,
                              size: 60,
                              color: isDark
                                  ? AppColors.primaryLight
                                  : AppColors.textOnPrimary,
                            ),
                          ),
                        );
                      },
                    ),
                ),
                  SizedBox(height: AppConstants.spacingXL),
                  // Welcome Text with Animation
                  RepaintBoundary(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 15 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: Column(
                      children: [
                Text(
                  'Welcome Back',
                  style: AppTextStyles.h2.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textOnPrimary,
                    fontSize: 32,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppConstants.spacingS),
                Text(
                  'Sign in to continue',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textOnPrimary.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                        ),
                      ],
                      ),
                    ),
                ),
                SizedBox(height: AppConstants.spacingXXL),
                  // Glassmorphism Card for Form
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurface
                          : theme.colorScheme.surface.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(AppConstants.radiusXL),
                      border: isDark
                          ? Border.all(
                              color: AppColors.darkBorderDefined.withOpacity(0.5),
                              width: 1,
                            )
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: (isDark ? AppColors.darkBackground : AppColors.textPrimary).withOpacity(isDark ? 0.5 : 0.1),
                          blurRadius: 30,
                          spreadRadius: 5,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(AppConstants.spacingL),
                    child: Column(
                      children: [
                CustomTextField(
                  label: 'Email',
                  hint: 'Enter your email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: Validators.email,
                ),
                SizedBox(height: AppConstants.spacingM),
                Obx(
                  () => CustomTextField(
                    label: 'Password',
                    hint: 'Enter your password',
                    controller: _passwordController,
                    obscureText: _obscurePassword.value,
                    prefixIcon: Icons.lock_outlined,
                    suffixIcon: _obscurePassword.value
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    onSuffixTap: () => _obscurePassword.value =
                        !_obscurePassword.value,
                    validator: Validators.password,
                  ),
                ),
                if (_showBiometricButton) ...[
                  OutlinedButton.icon(
                    onPressed: _biometricLoading || _authController.isLoading.value
                        ? null
                        : _handleBiometricLogin,
                    icon: _biometricLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.primary),
                          )
                        : Icon(Icons.fingerprint_rounded, color: theme.colorScheme.primary),
                    label: Text('Sign in with $_biometricLabel'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingM),
                      foregroundColor: theme.colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: AppConstants.spacingM),
                ],
                SizedBox(height: AppConstants.spacingL),
                Obx(
                  () => CustomButton(
                    text: 'Sign In',
                    onPressed: _authController.isLoading.value
                        ? null
                        : () => _handleLogin(context),
                    isLoading: _authController.isLoading.value,
                  ),
                ),
                      ],
                  ),
                ),
                SizedBox(height: AppConstants.spacingM),
                Obx(
                  () => _authController.error.value.isNotEmpty
                        ? TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 300),
                            builder: (context, value, child) {
                              return Opacity(
                                opacity: value,
                                child: Transform.scale(
                                  scale: 0.9 + (0.1 * value),
                                  child: Container(
                                    padding: EdgeInsets.all(AppConstants.spacingM),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(AppConstants.radiusL),
                                      border: Border.all(
                                        color: AppColors.error,
                                        width: 1.5,
                          ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.error.withOpacity(0.2),
                                          blurRadius: 10,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.error_outline_rounded,
                                          color: AppColors.error,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                          child: Text(
                            _authController.error.value,
                                            style: TextStyle(
                                              color: AppColors.error,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            textAlign: TextAlign.left,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                              );
                            },
                        )
                      : const SizedBox(),
                ),
              ],
            ),
          ),
        ),
      ),
      )
    );
  }

  Future<void> _handleLogin(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      final success = await _authController.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (success && context.mounted) {
        if (Get.isRegistered<BiometricService>()) {
          final bio = Get.find<BiometricService>();
          final available = await bio.isBiometricAvailable();
          final hasStored = await bio.hasStoredCredentials();
          if (available && !hasStored && context.mounted) {
            final label = await bio.getBiometricLabel();
            if (!context.mounted) return;
            final useBiometric = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Use biometrics next time?'),
                content: Text(
                  'You can sign in quickly with $label next time.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Not now'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Enable'),
                  ),
                ],
              ),
            );
            if (useBiometric == true) {
              await bio.saveCredentialsForBiometric(
                _emailController.text.trim(),
                _passwordController.text,
              );
            }
          }
        }
        _navigateAfterLogin();
      }
    }
  }

  Future<void> _handleBiometricLogin() async {
    if (!Get.isRegistered<BiometricService>()) return;
    setState(() => _biometricLoading = true);
    try {
      final bio = Get.find<BiometricService>();
      final creds = await bio.authenticateAndGetCredentials();
      if (creds == null || !mounted) return;
      final success = await _authController.login(creds.email, creds.password);
      if (success && mounted) {
        _navigateAfterLogin();
      } else if (mounted && _authController.error.value.isNotEmpty) {
        // Error already shown by AuthController
      }
    } finally {
      if (mounted) setState(() => _biometricLoading = false);
    }
  }

  void _navigateAfterLogin() {
    if (!Get.isRegistered<PermissionService>()) {
      Get.offAllNamed('/dashboard');
      return;
    }
    final user = _authController.user.value;
    if (user == null) {
      Get.offAllNamed('/dashboard');
      return;
    }
    final permissionService = Get.find<PermissionService>();
    if (permissionService.isDriver(user)) {
      Get.offAllNamed('/driver/dashboard');
    } else {
      Get.offAllNamed('/dashboard');
    }
  }
}

