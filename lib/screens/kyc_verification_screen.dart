import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'home_screen.dart';

class KycVerificationScreen extends StatefulWidget {
  @override
  _KycVerificationScreenState createState() => _KycVerificationScreenState();
}

class _KycVerificationScreenState extends State<KycVerificationScreen> {
  bool _isLoading = true;
  String _userStatus = 'inactive';
  String? _userPhoneNumber;

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  Future<void> _checkUserStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _userPhoneNumber = user.phoneNumber;

        if (_userPhoneNumber != null) {
          final doc = await FirebaseFirestore.instance
              .collection('userDetails')
              .doc(_userPhoneNumber!)
              .get();

          if (doc.exists) {
            final data = doc.data() as Map<String, dynamic>?;
            setState(() {
              _userStatus = data?['status'] ?? 'inactive';
              _isLoading = false;
            });

            // If user is not inactive, go directly to home screen
            if (_userStatus != 'inactive') {
              _navigateToHome();
            }
          } else {
            setState(() {
              _isLoading = false;
              _userStatus = 'inactive';
            });
          }
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _userStatus = 'inactive';
      });
    }
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()),
    );
  }

  Future<void> _openKycForm() async {
    // Immediately navigate to home screen
    _navigateToHome();

    // Then open the KYC form in browser
    final url = Uri.parse('https://forms.gle/tR1p39JZH2afo1NG8');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _markAsSubmitted() async {
    try {
      if (_userPhoneNumber != null) {
        await FirebaseFirestore.instance
            .collection('userDetails')
            .doc(_userPhoneNumber!)
            .update({
          'status': 'pending',
          'kycSubmittedAt': DateTime.now().millisecondsSinceEpoch,
        });
      }
      _navigateToHome();
    } catch (e) {
      print('Error updating KYC status: $e');
      _navigateToHome();
    }
  }

  Future<void> _skipKyc() async {
    try {
      if (_userPhoneNumber != null) {
        await FirebaseFirestore.instance
            .collection('userDetails')
            .doc(_userPhoneNumber!)
            .update({
          'status': 'inactive',
          'kycSkippedAt': DateTime.now().millisecondsSinceEpoch,
        });
      }
      _navigateToHome();
    } catch (e) {
      print('Error skipping KYC: $e');
      _navigateToHome();
    }
  }

  @override
  Widget build(BuildContext context) {
    // If loading or user is not inactive, show loading and then navigate
    if (_isLoading || _userStatus != 'inactive') {
      return Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Color(0xFFFFD700),
              ),
              SizedBox(height: 20),
              Text(
                'Loading...',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    // Only show KYC screen for inactive users
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildLogoSection(),
                const SizedBox(height: 48),
                _buildKycSection(),
                const SizedBox(height: 40),
                _buildFooter(),
              ],
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

  Widget _buildKycSection() {
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
          const Text(
            'KYC Verification',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Complete KYC to unlock all features',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),

          // Benefits
          _buildBenefit('Verified Account', 'Build trust with partners', Icons.verified_user_outlined),
          _buildBenefit('Full Access', 'Access all platform features', Icons.lock_open_outlined),
          _buildBenefit('Priority Support', 'Faster customer service', Icons.support_agent_outlined),

          const SizedBox(height: 32),

          // Open Form Button
          _buildGradientButton(
            onTap: _openKycForm,
            text: 'Open KYC Form',
            icon: Icons.open_in_browser,
          ),

          const SizedBox(height: 16),

          // Mark as Submitted Button
          _buildOutlineButton(
            onTap: _markAsSubmitted,
            text: 'I Already Submitted',
            icon: Icons.check_circle_outline,
          ),

          const SizedBox(height: 16),

          // Skip Button
          TextButton(
            onPressed: _skipKyc,
            child: const Text(
              'Skip for Now',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFFFFD700),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Info Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9E6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'You can complete KYC later from your profile settings',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefit(String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFFFFD700), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientButton({
    required VoidCallback onTap,
    required String text,
    required IconData icon,
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
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.black87, size: 20),
              const SizedBox(width: 12),
              Text(
                text,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOutlineButton({
    required VoidCallback onTap,
    required String text,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD700), width: 2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFFFFD700), size: 20),
              const SizedBox(width: 12),
              Text(
                text,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFD700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Text(
          'Your information is secured and encrypted',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const SizedBox(height: 20),
        Text(
          'CabEasy © 2026. All Rights Reserved.',
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
      ],
    );
  }
}
