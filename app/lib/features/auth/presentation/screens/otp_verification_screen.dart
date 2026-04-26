import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vibetalk/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vibetalk/features/auth/presentation/bloc/auth_event.dart';
import 'package:vibetalk/features/auth/presentation/bloc/auth_state.dart';
import 'package:vibetalk/features/auth/presentation/widgets/otp_input_widget.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;

  const OtpVerificationScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen>
    with SingleTickerProviderStateMixin {
  static const int _otpLength = 6;
  static const int _countdownSeconds = 60;

  final List<TextEditingController> _controllers =
      List.generate(_otpLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(_otpLength, (_) => FocusNode());

  late Timer _timer;
  int _secondsLeft = _countdownSeconds;
  bool _canResend = false;

  // Shake animation
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _startCountdown();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 12).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    _shakeController.dispose();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startCountdown() {
    _secondsLeft = _countdownSeconds;
    _canResend = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 0) {
        timer.cancel();
        setState(() => _canResend = true);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  String get _otp => _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    if (value.length == 1 && index < _otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    if (_otp.length == _otpLength) {
      _submit();
    }
  }

  void _onBackspace(int index) {
    if (index > 0) {
      _controllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
    }
  }

  void _submit() {
    final code = _otp;
    if (code.length == _otpLength) {
      FocusScope.of(context).unfocus();
      context.read<AuthBloc>().add(
            VerifyOTPEvent(
              verificationId: widget.verificationId,
              otpCode: code,
            ),
          );
    }
  }

  void _onResend() {
    if (!_canResend) return;
    _timer.cancel();
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes[0].requestFocus();
    _startCountdown();

    final parts = widget.phoneNumber.split('');
    // Extract country code vs number: if starts with +, first segment is country code
    context.read<AuthBloc>().add(
          ResendOTPEvent(phoneNumber: widget.phoneNumber, countryCode: ''),
        );
  }

  void _shake() {
    _shakeController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final last4 = widget.phoneNumber.length > 4
        ? widget.phoneNumber.substring(widget.phoneNumber.length - 4)
        : widget.phoneNumber;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go('/home');
        } else if (state is AuthNewUser) {
          context.go('/profile-setup');
        } else if (state is AuthError) {
          _shake();
          for (final c in _controllers) {
            c.clear();
          }
          _focusNodes[0].requestFocus();
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
          appBar: AppBar(
            title: const Text('Verify Phone'),
            leading: BackButton(onPressed: () => context.pop()),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),

                  // Lock icon
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.lock_rounded,
                        color: primary,
                        size: 36,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Enter verification code',
                    style: theme.textTheme.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We sent a 6-digit code to ···· $last4',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 40),

                  // OTP boxes with shake animation
                  AnimatedBuilder(
                    animation: _shakeAnim,
                    builder: (context, child) {
                      final dx = _shakeController.isAnimating
                          ? _shakeAnim.value *
                              ((_shakeController.value * 10).toInt().isEven
                                  ? 1
                                  : -1)
                          : 0.0;
                      return Transform.translate(
                        offset: Offset(dx, 0),
                        child: child,
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_otpLength, (i) {
                        return Padding(
                          padding: EdgeInsets.only(right: i < _otpLength - 1 ? 10 : 0),
                          child: OtpBox(
                            controller: _controllers[i],
                            focusNode: _focusNodes[i],
                            onChanged: (v) => _onDigitChanged(i, v),
                            onBackspace: () => _onBackspace(i),
                          ),
                        );
                      }),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Verify button
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final isLoading = state is AuthLoading;
                      return ElevatedButton(
                        onPressed: isLoading ? null : _submit,
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
                            : const Text('Verify Code'),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Resend countdown
                  Center(
                    child: _canResend
                        ? TextButton(
                            onPressed: _onResend,
                            child: Text(
                              'Resend Code',
                              style: TextStyle(color: primary),
                            ),
                          )
                        : Text(
                            'Resend code in $_secondsLeft s',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
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
