// otp_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen>
    with SingleTickerProviderStateMixin {
  // One controller per digit box — lets us read and clear each field independently.
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _hasError = false;
  bool _isVerifying = false;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Value runs 0 → 1 and is mapped to a horizontal offset in the builder,
    // creating a left-right oscillation that signals a failed code entry.
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    // Post-frame so the widget tree is built before we try to focus.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _shakeController.dispose();
    super.dispose();
  }

  // Joins all six fields into a single string for validation.
  String get _otpValue => _controllers.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_otpValue.length < 6) {
      _triggerError();
      return;
    }

    setState(() => _isVerifying = true);
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    // Intentionally permissive: any 6-digit number passes.
    // Replace this check with a real TOTP or backend validation later.
    final isValid = RegExp(r'^\d{6}$').hasMatch(_otpValue);

    if (isValid) {
      // Return true to auth_screen so it can proceed to MainNavigation.
      Navigator.of(context).pop(true);
    } else {
      setState(() => _isVerifying = false);
      _triggerError();
    }
  }

  void _triggerError() {
    setState(() => _hasError = true);
    _shakeController.forward(from: 0).then((_) {
      // Clear error highlight after the animation settles so the user
      // isn't staring at red fields while they type the next attempt.
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) setState(() => _hasError = false);
      });
    });
    // Clear all fields and refocus the first box for a clean retry.
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes[0].requestFocus();
  }

  void _onDigitEntered(int index, String value) {
    if (value.isNotEmpty) {
      if (index < 5) {
        // Auto-advance to the next box as soon as a digit is entered.
        _focusNodes[index + 1].requestFocus();
      } else {
        // Last digit entered — dismiss keyboard and verify immediately
        // without requiring the user to tap the button.
        _focusNodes[index].unfocus();
        _verify();
      }
    }
  }

  void _onKeyEvent(int index, KeyEvent event) {
    // Handle backspace on an empty field by jumping back to the previous box.
    // Without this, the user would be stuck unable to correct earlier digits.
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          // Returning false signals to auth_screen that verification was cancelled,
          // so it does not navigate to MainNavigation.
          onPressed: () => Navigator.pop(context, false),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    Icons.verified_user_rounded,
                    size: 52,
                    color: color,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Two-Factor Authentication',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Enter your 6-digit authentication code to continue.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withValues(alpha: 0.7),
                        height: 1.5,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Shake the entire row of boxes on a failed attempt.
                AnimatedBuilder(
                  animation: _shakeAnimation,
                  builder: (context, child) {
                    // Maps the 0→1 animation value to a side-to-side offset.
                    // The sign flip on each half-cycle creates the oscillation.
                    final offset = _shakeController.isAnimating
                        ? 8 *
                            (0.5 - (_shakeAnimation.value - 0.5).abs()) *
                            (_shakeAnimation.value < 0.5 ? -1 : 1)
                        : 0.0;
                    return Transform.translate(
                      offset: Offset(offset * 4, 0),
                      child: child,
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: KeyboardListener(
                          focusNode: FocusNode(),
                          onKeyEvent: (event) => _onKeyEvent(index, event),
                          child: SizedBox(
                            width: 44,
                            height: 56,
                            child: TextFormField(
                              controller: _controllers[index],
                              focusNode: _focusNodes[index],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: 1,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: _hasError ? AppTheme.errorRed : null,
                              ),
                              inputFormatters: [
                                // Blocks letters and symbols — only digits allowed.
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                counterText: '',
                                filled: true,
                                fillColor: _hasError
                                    ? AppTheme.errorRed.withValues(alpha: 0.08)
                                    : color.withValues(alpha: 0.06),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: _hasError
                                        ? AppTheme.errorRed
                                        : color.withValues(alpha: 0.3),
                                    width: 2,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: _hasError
                                        ? AppTheme.errorRed
                                        : color.withValues(alpha: 0.3),
                                    width: 2,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color:
                                        _hasError ? AppTheme.errorRed : color,
                                    width: 2.5,
                                  ),
                                ),
                              ),
                              onChanged: (value) =>
                                  _onDigitEntered(index, value),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                if (_hasError) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Invalid code. Please try again.',
                    style: TextStyle(
                      color: AppTheme.errorRed,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: _isVerifying ? null : _verify,
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isVerifying
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          )
                        : const Text(
                            'Verify',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    'Cancel and go back',
                    style: TextStyle(color: AppTheme.errorRed),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
