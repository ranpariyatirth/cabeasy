import 'package:cabeasy/screens/profile_screen.dart';
import 'package:cabeasy/screens/registration_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController();
  final AuthService _authService = AuthService();
  final FocusNode _phoneFocusNode = FocusNode();

  String? _verificationId;
  bool _codeSent = false;
  bool _isLoading = false;
  String _errorMessage = '';

  // Country selection
  String _selectedCountryCode = '+91';
  String _selectedCountryName = 'India';
  String _selectedCountryFlag = '🇮🇳';
  bool _isPhoneFocused = false;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Extended country list with more countries
  final List<Map<String, String>> _countries = [
    {'name': 'India', 'code': '+91', 'flag': '🇮🇳'},
    {'name': 'United States', 'code': '+1', 'flag': '🇺🇸'},
    {'name': 'United Kingdom', 'code': '+44', 'flag': '🇬🇧'},
    {'name': 'Canada', 'code': '+1', 'flag': '🇨🇦'},
    {'name': 'Australia', 'code': '+61', 'flag': '🇦🇺'},
    {'name': 'Germany', 'code': '+49', 'flag': '🇩🇪'},
    {'name': 'France', 'code': '+33', 'flag': '🇫🇷'},
    {'name': 'Italy', 'code': '+39', 'flag': '🇮🇹'},
    {'name': 'Spain', 'code': '+34', 'flag': '🇪🇸'},
    {'name': 'Japan', 'code': '+81', 'flag': '🇯🇵'},
    {'name': 'China', 'code': '+86', 'flag': '🇨🇳'},
    {'name': 'South Korea', 'code': '+82', 'flag': '🇰🇷'},
    {'name': 'Brazil', 'code': '+55', 'flag': '🇧🇷'},
    {'name': 'Mexico', 'code': '+52', 'flag': '🇲🇽'},
    {'name': 'Russia', 'code': '+7', 'flag': '🇷🇺'},
    {'name': 'Singapore', 'code': '+65', 'flag': '🇸🇬'},
    {'name': 'UAE', 'code': '+971', 'flag': '🇦🇪'},
    {'name': 'Saudi Arabia', 'code': '+966', 'flag': '🇸🇦'},
    {'name': 'Netherlands', 'code': '+31', 'flag': '🇳🇱'},
    {'name': 'Switzerland', 'code': '+41', 'flag': '🇨🇭'},
  ];

  // OTP controllers
  final List<TextEditingController> _otpControllers = [];
  final List<FocusNode> _otpFocusNodes = [];

  @override
  void initState() {
    super.initState();
    _phoneFocusNode.addListener(() {
      setState(() {
        _isPhoneFocused = _phoneFocusNode.hasFocus;
      });
    });

    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    _slideController.forward();

    // Initialize OTP controllers
    for (int i = 0; i < 6; i++) {
      _otpControllers.add(TextEditingController());
      _otpFocusNodes.add(FocusNode());
    }

    _setupOtpAutofill();
  }

  @override
  void dispose() {
    _phoneController.removeListener(_autoSubmitPhone);
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    _fadeController.dispose();
    _slideController.dispose();

    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }

    super.dispose();
  }


  Future<void> _sendVerificationCode() async {
    String cleanPhone = _phoneController.text.replaceAll(RegExp(r'\D'), '');

    if (cleanPhone.length < 10) {
      setState(() {
        _errorMessage = 'Please enter a valid 10-digit phone number';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    FocusScope.of(context).unfocus();
    String phoneNumber = '$_selectedCountryCode$cleanPhone';

    await _authService.sendVerificationCode(
      phoneNumber,
          (String verificationId) {
        setState(() {
          _verificationId = verificationId;
          _codeSent = true;
          _isLoading = false;
        });
        _slideController.reset();
        _slideController.forward();
        if (_otpFocusNodes.isNotEmpty) {
          Future.delayed(const Duration(milliseconds: 300), () {
            _otpFocusNodes[0].requestFocus();
          });
        }
      },
          (FirebaseAuthException error) {
        setState(() {
          _isLoading = false;
          _errorMessage = error.message ?? 'Failed to send code';
        });
      },
    );
  }


  void _autoSubmitPhone() {
    String cleanPhone = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.length == 10 && !_codeSent && !_isLoading) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _sendVerificationCode();
      });
    }
  }


  Future<void> _verifyCode() async {
    String otp = _currentOtp;

    if (otp.length < 6) {
      setState(() {
        _errorMessage = 'Please enter 6-digit code';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    // Close keyboard when verifying
    FocusScope.of(context).unfocus();

    final user = await _authService.verifyAndSignIn(
      _verificationId!,
      otp,
    );

    setState(() {
      _isLoading = false;
    });

    if (user == null) {
      setState(() {
        _errorMessage = 'Invalid verification code';
      });
      for (var controller in _otpControllers) {
        controller.clear();
      }
      _otpFocusNodes[0].requestFocus();
    } else {
      // Navigate to ProfileScreen with actual user ID
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileScreen(userId: user.uid),
        ),
      );
    }
  }


  void _resetToPhoneNumber() {
    setState(() {
      _codeSent = false;
      _errorMessage = '';
    });
    // Clear OTP boxes
    for (var controller in _otpControllers) {
      controller.clear();
    }
    _slideController.reset();
    _slideController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _phoneFocusNode.requestFocus();
    });
  }

  void _updateCountry(String code, String name, String flag) {
    setState(() {
      _selectedCountryCode = code;
      _selectedCountryName = name;
      _selectedCountryFlag = flag;
    });
  }

  String get _currentOtp => _otpControllers.map((c) => c.text).join();

  void _setupOtpAutofill() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (int i = 0; i < _otpControllers.length; i++) {
        _otpControllers[i].addListener(() {
          if (_otpControllers[i].text.length > 1) {
            String pastedValue = _otpControllers[i].text;
            if (pastedValue.length == 6) {
              for (int j = 0; j < 6; j++) {
                if (j < pastedValue.length) {
                  _otpControllers[j].text = pastedValue[j];
                }
              }
              _verifyCode();
            }
          }
        });
      }
    });
  }

  Widget _buildOtpBox(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 50,
      height: 62,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _otpFocusNodes[index].hasFocus
              ? const Color(0xFFFFD700)
              : _otpControllers[index].text.isNotEmpty
              ? const Color(0xFFFFE066)
              : Colors.grey[300]!,
          width: _otpFocusNodes[index].hasFocus ? 2.5 : 1.5,
        ),
        boxShadow: [
          if (_otpFocusNodes[index].hasFocus)
            BoxShadow(
              color: const Color(0xFFFFD700).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          else
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _otpFocusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            if (index < 5) {
              _otpFocusNodes[index + 1].requestFocus();
            } else {
              _otpFocusNodes[index].unfocus();
            }

            if (_currentOtp.length == 6) {
              Future.delayed(const Duration(milliseconds: 200), () {
                _verifyCode();
              });
            }
          } else {
            if (index > 0) {
              _otpFocusNodes[index - 1].requestFocus();
            }
          }
        },
        onTap: () {
          if (_otpControllers[index].text.isNotEmpty) {
            _otpControllers[index].selection = TextSelection.fromPosition(
              TextPosition(offset: _otpControllers[index].text.length),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      // Force light theme for login screen
      data: ThemeData.light().copyWith(
        colorScheme: ColorScheme.light(
          primary: const Color(0xFFFFD700),
          onPrimary: Colors.black87,
          surface: Colors.white,
        ),
      ),
      child: GestureDetector(
        onTap: () {
          // Close keyboard when tapping anywhere
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),

                        // Logo Section with enhanced styling
                        _buildLogoSection(),

                        const SizedBox(height: 48),

                        // Form Section
                        _buildFormSection(),

                        const SizedBox(height: 40),

                        // Footer
                        _buildFooter(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withOpacity(0.3),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Container(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFFFD700).withOpacity(0.1),
                    const Color(0xFFFFC400).withOpacity(0.1),
                  ],
                ),
              ),
              child: Image.network(
                "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSM12BNQAK4bOiZUJaHGAKbE8wNRwN_EO6INA&s",
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: const Color(0xFFFFD700),
                    child: const Icon(
                      Icons.local_taxi,
                      size: 70,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildFormSection() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _codeSent ? 'Verify OTP' : 'Sign in',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _codeSent
                ? 'We sent a code to your phone'
                : 'Enter your phone number to continue',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),

          // Error Message
          if (_errorMessage.isNotEmpty) ...[
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[700], size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage,
                      style: TextStyle(
                        color: Colors.red[800],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          if (!_codeSent) ..._buildPhoneInputSection() else ..._buildOtpInputSection(),
        ],
      ),
    );
  }

  List<Widget> _buildPhoneInputSection() {
    return [
      // Country & Phone Input
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Country Selector
          InkWell(
            onTap: () => _showCountrySelector(),
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isPhoneFocused
                      ? const Color(0xFFFFD700)
                      : Colors.grey[300]!,
                  width: _isPhoneFocused ? 2 : 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedCountryFlag,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _selectedCountryCode,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down, color: Colors.grey[600], size: 24),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Phone Input
          Expanded(
            child: AnimatedContainer(
              height: 70,
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isPhoneFocused
                      ? const Color(0xFFFFD700)
                      : Colors.grey[300]!,
                  width: _isPhoneFocused ? 2 : 1.5,
                ),
                boxShadow: _isPhoneFocused
                    ? [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
                    : [],
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(0),
                  child: TextField(
                    controller: _phoneController,
                    focusNode: _phoneFocusNode,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Phone number',
                      hintStyle: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      const SizedBox(height: 24),

      // Get OTP Button
      _buildGradientButton(
        onTap: _sendVerificationCode,
        text: 'Get OTP',
        isLoading: _isLoading,
      ),

      const SizedBox(height: 24),

      // Sign Up Link
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Don't have an account?",
            style: TextStyle(color: Colors.grey[600], fontSize: 15),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen(userId: '',)),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                "Sign Up",
                style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildOtpInputSection() {
    return [
      // Phone display with edit option
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(Icons.phone_android, color: Colors.grey[700], size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$_selectedCountryCode ${_phoneController.text}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),

      const SizedBox(height: 32),

      // OTP Boxes
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(6, (index) => _buildOtpBox(index)),
      ),

      const SizedBox(height: 24),

      // Verify Button
      _buildGradientButton(
        onTap: _verifyCode,
        text: 'Verify & Continue',
        isLoading: _isLoading,
      ),

      const SizedBox(height: 20),

      // Resend Code
      Center(
        child: TextButton.icon(
          onPressed: _isLoading ? null : _sendVerificationCode,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text(
            'Resend Code',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFFFD700),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
    ];
  }

  Widget _buildGradientButton({
    required VoidCallback onTap,
    required String text,
    required bool isLoading,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFD700), Color(0xFFFFC400)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap, // Fix: Use the onTap parameter instead of hardcoded navigation
          child: Center(
            child: isLoading
                ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildFooter() {
    return Column(
      children: [
        Text(
          'By continuing, you agree to our',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InkWell(
              onTap: () {
                // Terms action
              },
              child: const Text(
                'Terms of Service',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFFFFD700),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(' & ', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            InkWell(
              onTap: () {
                // Privacy action
              },
              child: const Text(
                'Privacy Policy',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFFFFD700),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'CabEasy © 2026. All Rights Reserved.',
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
      ],
    );
  }

  void _showCountrySelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text(
                    'Select Country',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 1,
                    color: Colors.grey[200],
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _countries.length,
                itemBuilder: (context, index) {
                  final country = _countries[index];
                  final isSelected = country['code'] == _selectedCountryCode;

                  return InkWell(
                    onTap: () {
                      _updateCountry(
                        country['code']!,
                        country['name']!,
                        country['flag']!,
                      );
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFFFF9E6) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Text(
                            country['flag']!,
                            style: const TextStyle(fontSize: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              country['name']!,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Text(
                            country['code']!,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.check_circle,
                              color: Color(0xFFFFD700),
                              size: 22,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}