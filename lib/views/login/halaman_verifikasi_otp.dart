import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fodos/constants/app_textstyle.dart';
import 'package:fodos/extention/extention.dart';
import 'package:fodos/views/login/halaman_reset_password.dart';

class HalamanVerifikasiOtp extends StatefulWidget {
  final String email;
  final String initialOtp;

  const HalamanVerifikasiOtp({
    super.key,
    required this.email,
    required this.initialOtp,
  });

  @override
  State<HalamanVerifikasiOtp> createState() => _HalamanVerifikasiOtpState();
}

class _HalamanVerifikasiOtpState extends State<HalamanVerifikasiOtp> {
  late String _currentOtp;
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  Timer? _timer;
  int _secondsRemaining = 60;
  bool _isVerifying = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _currentOtp = widget.initialOtp;
    _controllers = List.generate(6, (_) => TextEditingController());
    _focusNodes = List.generate(6, (_) => FocusNode());
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = 60;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String _getEnteredOtp() {
    return _controllers.map((c) => c.text).join();
  }

  void _resendOtp() {
    if (_secondsRemaining > 0) return;

    final random = Random();
    final newOtp = (100000 + random.nextInt(900000)).toString();

    setState(() {
      _currentOtp = newOtp;
      _errorMessage = null;
      for (var c in _controllers) {
        c.clear();
      }
    });
    _focusNodes[0].requestFocus();
    _startTimer();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.refresh_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Kode OTP baru telah dikirimkan ke ${widget.email}',
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _handleVerify() {
    final enteredOtp = _getEnteredOtp();

    if (enteredOtp.length < 6) {
      setState(() {
        _errorMessage = "Masukkan lengkap 6 digit kode OTP!";
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;

      if (enteredOtp == _currentOtp) {
        setState(() {
          _isVerifying = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white),
                SizedBox(width: 10),
                Text('Verifikasi OTP berhasil!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        context.pushReplacement(
          HalamanResetPassword(email: widget.email),
        );
      } else {
        setState(() {
          _isVerifying = false;
          _errorMessage = "Kode OTP salah! Silakan periksa kembali.";
        });
      }
    });
  }

  String _obscureEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final name = parts[0];
    final domain = parts[1];
    if (name.length <= 2) {
      return "${name[0]}***@$domain";
    }
    return "${name.substring(0, 2)}***${name.substring(name.length - 1)}@$domain";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Icon
                Center(
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.mark_email_read_rounded,
                        size: 46,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Title & Subtitle
                const Text(
                  "Verifikasi Kode OTP",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 10),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textGrey,
                      height: 1.5,
                    ),
                    children: [
                      const TextSpan(
                        text: "Masukkan 6 digit kode verifikasi yang telah dikirimkan ke ",
                      ),
                      TextSpan(
                        text: _obscureEmail(widget.email),
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Demo Helper Banner (shows current OTP for quick testing)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFA5D6A7)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFF2E7D32),
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF1B5E20),
                            ),
                            children: [
                              const TextSpan(text: "Kode OTP Anda: "),
                              TextSpan(
                                text: _currentOtp,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: "Salin Kode",
                        icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF2E7D32)),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _currentOtp));
                          for (int i = 0; i < 6; i++) {
                            _controllers[i].text = _currentOtp[i];
                          }
                          setState(() {
                            _errorMessage = null;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Kode OTP berhasil disalin & diisi!"),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // 6 OTP Digit Input Boxes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      width: 48,
                      height: 58,
                      child: TextField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          counterText: "",
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _errorMessage != null
                                  ? Colors.redAccent
                                  : AppColors.border,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 2.2,
                            ),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _errorMessage = null;
                          });
                          if (value.isNotEmpty) {
                            if (index < 5) {
                              _focusNodes[index + 1].requestFocus();
                            } else {
                              _focusNodes[index].unfocus();
                              _handleVerify();
                            }
                          } else if (value.isEmpty && index > 0) {
                            _focusNodes[index - 1].requestFocus();
                          }
                        },
                      ),
                    );
                  }),
                ),

                // Error Message if any
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),

                // Verify Button
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _isVerifying ? null : _handleVerify,
                    child: _isVerifying
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            "Verifikasi",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // Countdown & Resend Option
                Center(
                  child: _secondsRemaining > 0
                      ? RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textGrey,
                            ),
                            children: [
                              const TextSpan(text: "Kirim ulang kode dalam "),
                              TextSpan(
                                text: "00:${_secondsRemaining.toString().padLeft(2, '0')}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : TextButton.icon(
                          onPressed: _resendOtp,
                          icon: const Icon(
                            Icons.refresh_rounded,
                            color: AppColors.secondary,
                            size: 18,
                          ),
                          label: const Text(
                            "Kirim Ulang Kode OTP",
                            style: TextStyle(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
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
