import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vibetalk/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vibetalk/features/auth/presentation/bloc/auth_event.dart';
import 'package:vibetalk/features/auth/presentation/bloc/auth_state.dart';

/// Phone number input screen — step 1 of OTP auth flow.
class PhoneInputScreen extends StatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  State<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends State<PhoneInputScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocus = FocusNode();
  String _countryCode = '+1';
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_validate);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  void _validate() {
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    setState(() => _isValid = digits.length >= 8);
  }

  void _onCountryChanged(CountryCode code) {
    setState(() => _countryCode = code.dialCode ?? '+1');
  }

  void _onContinue() {
    if (!_isValid) return;
    FocusScope.of(context).unfocus();
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    context.read<AuthBloc>().add(
          SendOTPEvent(phoneNumber: digits, countryCode: _countryCode),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is OTPSent) {
          context.push('/otp', extra: {
            'verificationId': state.verificationId,
            'phoneNumber': state.phoneNumber,
          });
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: theme.colorScheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 64),

                  // Logo
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [primary, primary.withOpacity(0.7)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: primary.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.chat_bubble_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  Text(
                    'Welcome to VibeTalk',
                    style: theme.textTheme.displayMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your phone number to get started.\nWe\'ll send you a verification code.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 48),

                  // Phone input row
                  Container(
                    decoration: BoxDecoration(
                      color: theme.inputDecorationTheme.fillColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _phoneFocus.hasFocus
                            ? primary
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Country code picker
                        CountryCodePicker(
                          onChanged: _onCountryChanged,
                          initialSelection: 'US',
                          favorite: const ['+1', '+44', '+880'],
                          showCountryOnly: false,
                          showOnlyCountryWhenClosed: false,
                          alignLeft: false,
                          textStyle: theme.textTheme.bodyLarge,
                          dialogTextStyle: theme.textTheme.bodyMedium,
                          searchStyle: theme.textTheme.bodyMedium,
                          padding: EdgeInsets.zero,
                        ),

                        Container(
                          width: 1,
                          height: 24,
                          color: theme.colorScheme.onSurface.withOpacity(0.15),
                        ),

                        // Phone number field
                        Expanded(
                          child: TextField(
                            controller: _phoneController,
                            focusNode: _phoneFocus,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(15),
                            ],
                            decoration: const InputDecoration(
                              hintText: 'Phone number',
                              border: InputBorder.none,
                              fillColor: Colors.transparent,
                              filled: false,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16,
                              ),
                            ),
                            onSubmitted: (_) => _onContinue(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Continue button
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final isLoading = state is AuthLoading;
                      return AnimatedOpacity(
                        opacity: _isValid ? 1.0 : 0.45,
                        duration: const Duration(milliseconds: 200),
                        child: ElevatedButton(
                          onPressed: (_isValid && !isLoading) ? _onContinue : null,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Continue'),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'By continuing, you agree to our Terms of Service\nand Privacy Policy.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
