/// OTP Verification Screen
///
/// Verifies phone number with OTP code.
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/phone_auth_service.dart';
import '../providers/notification_provider.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final PhoneAuthService _phoneAuthService = PhoneAuthService();
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  String? _phoneNumber;
  String? _verificationId;
  int? _resendToken;

  bool _isLoading = false;
  bool _isSendingOtp = true;
  bool _canResend = false;
  int _resendCountdown = 30;
  String? _error;

  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
    });
  }

  void _initializeScreen() {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _phoneNumber = args['phoneNumber'] as String?;
      if (_phoneNumber != null) {
        _sendOtp();
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _resendTimer?.cancel();
    super.dispose();
  }

  String get _otpCode => _otpControllers.map((c) => c.text).join();

  Future<void> _sendOtp() async {
    if (_phoneNumber == null) return;

    setState(() {
      _isSendingOtp = true;
      _error = null;
    });

    try {
      final result = await _phoneAuthService.sendOtp(
        phoneNumber: _phoneNumber!,
        resendToken: _resendToken,
      );

      if (result.success) {
        _verificationId = result.verificationId;
        _resendToken = result.resendToken;
        _startResendTimer();
      } else {
        setState(() {
          _error = result.error ?? 'Failed to send OTP';
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSendingOtp = false;
        });
      }
    }
  }

  void _startResendTimer() {
    _canResend = false;
    _resendCountdown = 30;

    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _resendCountdown--;
          if (_resendCountdown <= 0) {
            _canResend = true;
            timer.cancel();
          }
        });
      }
    });
  }

  Future<void> _verifyOtp() async {
    if (_verificationId == null || _phoneNumber == null) {
      setState(() {
        _error = 'Please request a new OTP';
      });
      return;
    }

    if (_otpCode.length != 6) {
      setState(() {
        _error = 'Please enter the complete OTP';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _phoneAuthService.verifyOtp(
        verificationId: _verificationId!,
        otp: _otpCode,
        phoneNumber: _phoneNumber!,
      );

      if (result.success && result.user != null) {
        // Initialize NotificationProvider with user info
        final userData = await _phoneAuthService.getUserData(result.user!.uid);

        if (mounted && userData != null) {
          final notificationProvider = context.read<NotificationProvider>();
          notificationProvider.init(
            result.user!.uid,
            userData['displayName'] ?? 'User',
          );
        }

        // Check if user needs to set up profile
        if (mounted) {
          if (userData != null &&
              userData['displayName'] != null &&
              userData['displayName'] != 'User') {
            // Existing user, go to home
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/home',
              (route) => false,
            );
          } else {
            // New user, go to profile setup
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/profile-setup',
              (route) => false,
            );
          }
        }
      } else {
        setState(() {
          _error = result.error ?? 'Verification failed';
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onOtpDigitChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      // Move to next field
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      // Move to previous field on backspace
      _focusNodes[index - 1].requestFocus();
    }

    // Auto-verify when all digits entered
    if (_otpCode.length == 6) {
      _verifyOtp();
    }
  }

  void _clearOtp() {
    for (var controller in _otpControllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2D3B36)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: size.height * 0.04),

              // Lock icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF6B9080),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.lock_outline,
                  size: 40,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 32),

              // Title
              Text(
                'Verify Your Number',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D3B36),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              // Phone number display
              Text(
                'We sent a code to $_phoneNumber',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: const Color(0xFF5C6B66),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // OTP input fields
              if (_isSendingOtp) ...[
                const Center(
                  child: CircularProgressIndicator(color: Color(0xFF6B9080)),
                ),
                const SizedBox(height: 16),
                Text(
                  'Sending OTP...',
                  style: GoogleFonts.poppins(color: const Color(0xFF5C6B66)),
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      width: 50,
                      height: 60,
                      child: TextFormField(
                        controller: _otpControllers[index],
                        focusNode: _focusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2D3B36),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE0E0E0),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF6B9080),
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE0E0E0),
                            ),
                          ),
                        ),
                        onChanged: (value) => _onOtpDigitChanged(index, value),
                      ),
                    );
                  }),
                ),
              ],

              if (_error != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _error!,
                          style: GoogleFonts.poppins(
                            color: Colors.red.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.refresh, color: Colors.red.shade700),
                        onPressed: _clearOtp,
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Verify button
              SizedBox(
                height: 60,
                child: ElevatedButton(
                  onPressed: _isLoading || _isSendingOtp ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B9080),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Verify',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // Resend OTP
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Didn't receive the code? ",
                    style: GoogleFonts.poppins(color: const Color(0xFF5C6B66)),
                  ),
                  TextButton(
                    onPressed: _canResend ? _sendOtp : null,
                    child: Text(
                      _canResend ? 'Resend' : 'Resend in ${_resendCountdown}s',
                      style: GoogleFonts.poppins(
                        color: _canResend
                            ? const Color(0xFF6B9080)
                            : const Color(0xFF9E9E9E),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 48),

              // Help text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0ED),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      '💡 Tip',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6B9080),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'The code might take a few seconds to arrive. Make sure you have network connectivity.',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF5C6B66),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
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
