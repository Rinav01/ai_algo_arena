import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:algo_arena/core/app_theme.dart';
import 'package:algo_arena/services/auth_service.dart';
import 'package:algo_arena/state/auth_provider.dart';
import 'package:algo_arena/widgets/premium_glass_container.dart';
import 'package:algo_arena/state/performance_provider.dart';
import 'package:algo_arena/services/performance_monitor.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();
  
  bool _isLoading = false;
  bool _isOtpLoading = false;
  String? _errorMessage;
  bool _otpSent = false;
  String? _verificationId;

  final List<Map<String, String>> _countryCodes = [
    {'name': 'India', 'code': '+91', 'flag': '🇮🇳'},
    {'name': 'USA', 'code': '+1', 'flag': '🇺🇸'},
    {'name': 'UK', 'code': '+44', 'flag': '🇬🇧'},
    {'name': 'Australia', 'code': '+61', 'flag': '🇦🇺'},
    {'name': 'Canada', 'code': '+1', 'flag': '🇨🇦'},
    {'name': 'Germany', 'code': '+49', 'flag': '🇩🇪'},
    {'name': 'UAE', 'code': '+971', 'flag': '🇦🇪'},
    {'name': 'Singapore', 'code': '+65', 'flag': '🇸🇬'},
  ];
  String _selectedCountryCode = '+91';

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a valid phone number';
      });
      return;
    }

    final fullPhone = '$_selectedCountryCode$phone';

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthService.verifyPhoneNumber(
        phoneNumber: fullPhone,
        onCodeSent: (verificationId) {
          setState(() {
            _verificationId = verificationId;
            _otpSent = true;
          });
        },
        onVerificationFailed: (errorMessage) {
          setState(() {
            _errorMessage = errorMessage;
          });
        },
        onAutoVerificationCompleted: (user) {
          if (user != null && mounted) {
            _onSuccess();
          }
        },
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll("Exception: ", "");
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Successfully authenticated!')),
    );
    if (Navigator.of(context).canPop()) {
      Navigator.pop(context);
    } else {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    }
  }

  Future<void> _handleVerifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty || otp.length < 6) {
      setState(() {
        _errorMessage = 'Please enter the 6-digit verification code';
      });
      return;
    }

    if (_verificationId == null) {
      setState(() {
        _errorMessage = 'Verification ID not found. Please try sending the code again.';
      });
      return;
    }

    setState(() {
      _isOtpLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await AuthService.signInWithSmsCode(_verificationId!, otp);
      if (user != null) {
        if (mounted) {
          _onSuccess();
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to authenticate. Please check the code and try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll("Exception: ", "");
      });
    } finally {
      setState(() {
        _isOtpLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (previous, next) {
      if (next.value != null && !next.value!.isAnonymous) {
        if (mounted) {
          if (Navigator.of(context).canPop()) {
            Navigator.pop(context);
          } else {
            Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
          }
        }
      }
    });

    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    final quality = ref.watch(qualityLevelProvider);
    final isLowFidelity = quality == QualityLevel.performance;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          if (!isLowFidelity) ...[
            Positioned(
              top: -80,
              left: -80,
              child: RepaintBoundary(
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.accent.withValues(alpha: 0.18),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 120,
              right: -100,
              child: RepaintBoundary(
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.cyan.withValues(alpha: 0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],

          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.06,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Banner: Logo, Title, and Settings icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6.0),
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.terminal_rounded,
                              color: AppTheme.accent,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'AI ALGORITHM ARENA',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 1.2,
                              fontFamily: 'SpaceGrotesk',
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined, color: Color(0xFF64748B), size: 22),
                        onPressed: () => Navigator.pushNamed(context, '/settings'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Security Protocol Tag
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1435).withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: AppTheme.accent.withValues(alpha: 0.25),
                          width: 1.0,
                        ),
                      ),
                      child: const Text(
                        'SECURITY PROTOCOL V4.0.2',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: Color(0xFFD0BCFF),
                          fontFamily: 'SpaceGrotesk',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Access Protocol Headers
                  const Center(
                    child: Column(
                      children: [
                        Text(
                          'ACCESS',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'SpaceGrotesk',
                            color: Colors.white,
                            letterSpacing: -0.2,
                            height: 1.0,
                          ),
                        ),
                        Text(
                          'PROTOCOL',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'SpaceGrotesk',
                            color: Colors.white,
                            letterSpacing: -0.2,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Helper subtext
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.0),
                    child: Text(
                      'Identity verification required to initialize algorithmic weights. Please follow the two-step authorization sequence.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Animated Stage Container (Cross-Fade)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    switchInCurve: Curves.easeIn,
                    switchOutCurve: Curves.easeOut,
                    child: !_otpSent
                        ? PremiumGlassContainer(
                            key: const ValueKey('step_email'),
                            radius: 16,
                            blurSigma: 12,
                            opacity: 0.25,
                            padding: const EdgeInsets.all(22.0),
                            animate: false,
                            border: Border.all(
                              color: AppTheme.accent.withValues(alpha: 0.15),
                              width: 1.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'AUTHORIZED PHONE NUMBER',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.1,
                                    color: Color(0xFFD0BCFF),
                                    fontFamily: 'SpaceGrotesk',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      height: 52,
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0F121D),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.04),
                                        ),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: _selectedCountryCode,
                                          dropdownColor: const Color(0xFF0F121D),
                                          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF475569), size: 16),
                                          items: _countryCodes.map((country) {
                                            return DropdownMenuItem<String>(
                                              value: country['code'],
                                              child: Text(
                                                '${country['flag']} ${country['code']}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontFamily: 'SpaceGrotesk',
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (val) {
                                            if (val != null) {
                                              setState(() {
                                                _selectedCountryCode = val;
                                              });
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: _phoneController,
                                        keyboardType: TextInputType.phone,
                                        style: const TextStyle(color: Colors.white, fontSize: 15),
                                        decoration: InputDecoration(
                                          hintText: 'Phone Number',
                                          hintStyle: const TextStyle(color: Color(0xFF475569)),
                                          filled: true,
                                          fillColor: const Color(0xFF0F121D),
                                          contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide.none,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.04)),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: const BorderSide(color: AppTheme.accent),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_errorMessage != null) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    _errorMessage!,
                                    style: const TextStyle(color: AppTheme.error, fontSize: 13),
                                  ),
                                ],
                                const SizedBox(height: 20),
                                GestureDetector(
                                  onTap: _isLoading ? null : _handleSendOtp,
                                  child: Container(
                                    height: 50,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF6366F1), AppTheme.accent],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.accent.withValues(alpha: 0.3),
                                          blurRadius: 16,
                                          offset: const Offset(0, 4),
                                        )
                                      ],
                                    ),
                                    child: Center(
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2.2,
                                              ),
                                            )
                                          : const Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  'REQUEST OTP',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                    fontFamily: 'SpaceGrotesk',
                                                    letterSpacing: 1.0,
                                                  ),
                                                ),
                                                SizedBox(width: 6),
                                                Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                                              ],
                                            ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Center(
                                  child: TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _otpSent = true;
                                        _errorMessage = null;
                                      });
                                    },
                                    child: const Text(
                                      'ALREADY HAVE AN OTP?',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.8,
                                        color: Color(0xFFD0BCFF),
                                        fontFamily: 'SpaceGrotesk',
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : PremiumGlassContainer(
                            key: const ValueKey('step_token'),
                            radius: 16,
                            blurSigma: 12,
                            opacity: 0.25,
                            padding: const EdgeInsets.all(22.0),
                            animate: false,
                            border: Border.all(
                              color: AppTheme.accent.withValues(alpha: 0.15),
                              width: 1.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'INPUT ACCESS TOKEN',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.1,
                                        color: Colors.white,
                                        fontFamily: 'SpaceGrotesk',
                                      ),
                                    ),
                                    TextButton.icon(
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _otpSent = false;
                                          _otpController.clear();
                                          _errorMessage = null;
                                        });
                                      },
                                      icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFFD0BCFF), size: 12),
                                      label: const Text(
                                        'CHANGE PHONE',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFD0BCFF),
                                          letterSpacing: 0.8,
                                          fontFamily: 'SpaceGrotesk',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  '6-digit cryptographic hash sent via SMS.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Stack(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: List.generate(6, (index) {
                                        final codeText = _otpController.text;
                                        final char = (index < codeText.length) ? codeText[index] : '';
                                        return Container(
                                          width: 44,
                                          height: 52,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1E2433),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: char.isNotEmpty
                                                  ? AppTheme.cyan.withValues(alpha: 0.6)
                                                  : const Color(0xFF334155).withValues(alpha: 0.4),
                                              width: char.isNotEmpty ? 1.5 : 1.0,
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            char.isNotEmpty ? char : '•',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: char.isNotEmpty ? AppTheme.cyan : const Color(0xFF475569),
                                              fontFamily: 'SpaceGrotesk',
                                            ),
                                          ),
                                        );
                                      }),
                                    ),
                                    Positioned.fill(
                                      child: Opacity(
                                        opacity: 0.0,
                                        child: TextField(
                                          controller: _otpController,
                                          focusNode: _otpFocusNode,
                                          keyboardType: TextInputType.number,
                                          maxLength: 6,
                                          autofocus: true,
                                          cursorColor: Colors.transparent,
                                          enableInteractiveSelection: false,
                                          onChanged: (text) {
                                            if (text.length <= 6) {
                                              setState(() {});
                                            }
                                          },
                                          decoration: const InputDecoration(
                                            counterText: '',
                                            border: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_errorMessage != null) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    _errorMessage!,
                                    style: const TextStyle(color: AppTheme.error, fontSize: 12),
                                  ),
                                ],
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    TextButton(
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      onPressed: _handleSendOtp,
                                      child: const Text(
                                        'RESEND TOKEN',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFD0BCFF),
                                          letterSpacing: 0.8,
                                          fontFamily: 'SpaceGrotesk',
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: _isOtpLoading ? null : _handleVerifyOtp,
                                      child: Container(
                                        height: 44,
                                        padding: const EdgeInsets.symmetric(horizontal: 24),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFF6366F1), AppTheme.accent],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(8.0),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppTheme.accent.withValues(alpha: 0.3),
                                              blurRadius: 16,
                                              offset: const Offset(0, 4),
                                            )
                                          ],
                                        ),
                                        child: Center(
                                          child: _isOtpLoading
                                              ? const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: CircularProgressIndicator(
                                                    color: Colors.white,
                                                    strokeWidth: 2.2,
                                                  ),
                                                )
                                              : const Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      'Verify Identity',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.white,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                    SizedBox(width: 8),
                                                    Icon(Icons.verified_user_outlined, color: Colors.white, size: 16),
                                                  ],
                                                ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                  ),

                  const SizedBox(height: 48),

                  // High-Performance Flat Footer
                  if (!keyboardVisible) ...[
                    const Center(
                      child: Text(
                        '© 2024 KINETIC OBSERVATORY. SYSTEM STATUS: OPTIMAL',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () {},
                          child: const Text(
                            'DOCUMENTATION',
                            style: TextStyle(fontSize: 10, color: Color(0xFF475569), fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text('|', style: TextStyle(color: Color(0xFF1E2433), fontSize: 10)),
                        const SizedBox(width: 4),
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () {},
                          child: const Text(
                            'SECURITY PROTOCOL',
                            style: TextStyle(fontSize: 10, color: Color(0xFF475569), fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text('|', style: TextStyle(color: Color(0xFF1E2433), fontSize: 10)),
                        const SizedBox(width: 4),
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () {},
                          child: const Text(
                            'PRIVACY PATH',
                            style: TextStyle(fontSize: 10, color: Color(0xFF475569), fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

