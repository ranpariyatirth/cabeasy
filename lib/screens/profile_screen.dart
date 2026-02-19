import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import 'kyc_verification_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = '';
  String _selectedUserType = 'b2b';
  final List<String> _selectedServices = [];
  final List<String> _selectedDestinations = [];
  String? _userPhoneNumber;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Service options with icons and descriptions
  final List<Map<String, dynamic>> _serviceOptions = [
    {
      'name': 'Sightseeing Packages',
      'icon': Icons.tour_outlined,
      'color': Color(0xFFFF6B6B),
    },
    {
      'name': 'Hotel Bookings',
      'icon': Icons.hotel_outlined,
      'color': Color(0xFF4ECDC4),
    },
    {
      'name': 'Airport Transfers',
      'icon': Icons.flight_outlined,
      'color': Color(0xFF95E1D3),
    },
    {
      'name': 'Local Tours',
      'icon': Icons.location_city_outlined,
      'color': Color(0xFFF38181),
    },
    {
      'name': 'Adventure Activities',
      'icon': Icons.landscape_outlined,
      'color': Color(0xFFAA96DA),
    },
    {
      'name': 'Cultural Experiences',
      'icon': Icons.temple_hindu_outlined,
      'color': Color(0xFFFCBF49),
    },
    {
      'name': 'Food Tours',
      'icon': Icons.restaurant_outlined,
      'color': Color(0xFFFF9F1C),
    },
    {
      'name': 'Event Management',
      'icon': Icons.event_outlined,
      'color': Color(0xFF06FFA5),
    },
  ];

  // Indian states and major cities
  final List<Map<String, String>> _indianDestinations = [
    {'name': 'Agra, Uttar Pradesh', 'state': 'Uttar Pradesh'},
    {'name': 'Ahmedabad, Gujarat', 'state': 'Gujarat'},
    {'name': 'Ajmer, Rajasthan', 'state': 'Rajasthan'},
    {'name': 'Amritsar, Punjab', 'state': 'Punjab'},
    {'name': 'Bangalore, Karnataka', 'state': 'Karnataka'},
    {'name': 'Bhopal, Madhya Pradesh', 'state': 'Madhya Pradesh'},
    {'name': 'Chandigarh, Punjab', 'state': 'Punjab'},
    {'name': 'Chennai, Tamil Nadu', 'state': 'Tamil Nadu'},
    {'name': 'Coimbatore, Tamil Nadu', 'state': 'Tamil Nadu'},
    {'name': 'Darjeeling, West Bengal', 'state': 'West Bengal'},
    {'name': 'Delhi, National Capital Territory', 'state': 'Delhi'},
    {'name': 'Goa, Goa', 'state': 'Goa'},
    {'name': 'Guwahati, Assam', 'state': 'Assam'},
    {'name': 'Haridwar, Uttarakhand', 'state': 'Uttarakhand'},
    {'name': 'Hyderabad, Telangana', 'state': 'Telangana'},
    {'name': 'Indore, Madhya Pradesh', 'state': 'Madhya Pradesh'},
    {'name': 'Jaipur, Rajasthan', 'state': 'Rajasthan'},
    {'name': 'Jaisalmer, Rajasthan', 'state': 'Rajasthan'},
    {'name': 'Jodhpur, Rajasthan', 'state': 'Rajasthan'},
    {'name': 'Kochi, Kerala', 'state': 'Kerala'},
    {'name': 'Kolkata, West Bengal', 'state': 'West Bengal'},
    {'name': 'Lucknow, Uttar Pradesh', 'state': 'Uttar Pradesh'},
    {'name': 'Madurai, Tamil Nadu', 'state': 'Tamil Nadu'},
    {'name': 'Manali, Himachal Pradesh', 'state': 'Himachal Pradesh'},
    {'name': 'Mumbai, Maharashtra', 'state': 'Maharashtra'},
    {'name': 'Mussoorie, Uttarakhand', 'state': 'Uttarakhand'},
    {'name': 'Mysore, Karnataka', 'state': 'Karnataka'},
    {'name': 'Nainital, Uttarakhand', 'state': 'Uttarakhand'},
    {'name': 'Ooty, Tamil Nadu', 'state': 'Tamil Nadu'},
    {'name': 'Pondicherry, Puducherry', 'state': 'Puducherry'},
    {'name': 'Pune, Maharashtra', 'state': 'Maharashtra'},
    {'name': 'Pushkar, Rajasthan', 'state': 'Rajasthan'},
    {'name': 'Rishikesh, Uttarakhand', 'state': 'Uttarakhand'},
    {'name': 'Shimla, Himachal Pradesh', 'state': 'Himachal Pradesh'},
    {'name': 'Srinagar, Jammu & Kashmir', 'state': 'Jammu & Kashmir'},
    {'name': 'Udaipur, Rajasthan', 'state': 'Rajasthan'},
    {'name': 'Varanasi, Uttar Pradesh', 'state': 'Uttar Pradesh'},
    {'name': 'Visakhapatnam, Andhra Pradesh', 'state': 'Andhra Pradesh'},
  ];

  List<Map<String, String>> _filteredDestinations = [];

  @override
  void initState() {
    super.initState();
    _filteredDestinations = List.from(_indianDestinations);

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

    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _searchController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
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
              _nameController.text = data?['name'] ?? '';
              _emailController.text = data?['email'] ?? user.email ?? '';
              _selectedUserType = data?['isSupplier'] == true ? 'supplier' : 'b2b';

              if (data?['destinations'] != null) {
                _selectedDestinations.addAll(List<String>.from(data!['destinations']));
              }

              if (data?['otherServices'] != null) {
                _selectedServices.addAll(List<String>.from(data!['otherServices']));
              }
            });
          } else {
            setState(() {
              _emailController.text = user.email ?? '';
            });
          }
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your name';
      });
      return;
    }

    if (_selectedUserType == 'supplier' && _selectedDestinations.isEmpty) {
      setState(() {
        _errorMessage = 'Please select at least one destination';
      });
      return;
    }


    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      if (_userPhoneNumber == null) {
        setState(() {
          _errorMessage = 'Phone number not available';
          _isLoading = false;
        });
        return;
      }

      await FirebaseFirestore.instance
          .collection('userDetails')
          .doc(_userPhoneNumber!)
          .set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim().isEmpty
            ? '${user.uid}@cabeasy.in'
            : _emailController.text.trim(),
        'phone': _userPhoneNumber!,
        'userId': user.uid,
        'isSupplier': _selectedUserType == 'supplier',
        'isAgent': _selectedUserType == 'b2b',
        'isAdmin': false,
        'isKycVerified': false,
        'status': 'inactive',
        'destinations': _selectedDestinations,
        'otherServices': _selectedServices,
        'kycDocs': [],
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      }, SetOptions(merge: true));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => KycVerificationScreen()),
      );

    } catch (e) {
      print('Firestore Error: $e');
      setState(() {
        _errorMessage = 'Failed to save profile. Please try again.';
        _isLoading = false;
      });
    }
  }

  void _toggleService(String service) {
    setState(() {
      if (_selectedServices.contains(service)) {
        _selectedServices.remove(service);
      } else {
        _selectedServices.add(service);
      }
    });
  }

  void _toggleDestination(String destination) {
    setState(() {
      if (_selectedDestinations.contains(destination)) {
        _selectedDestinations.remove(destination);
      } else {
        _selectedDestinations.add(destination);
      }
    });
  }

  void _filterDestinations(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredDestinations = List.from(_indianDestinations);
      } else {
        _filteredDestinations = _indianDestinations
            .where((dest) =>
        dest['name']!.toLowerCase().contains(query.toLowerCase()) ||
            dest['state']!.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
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
                    _buildLogoSection(),
                    const SizedBox(height: 48),
                    _buildFormSection(),
                    const SizedBox(height: 40),
                    _buildFooter(),
                  ],
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
          const Text(
            'Complete Profile',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tell us more about yourself',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),

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

          _buildTextField(
            label: 'Full Name',
            controller: _nameController,
            icon: Icons.person_outline,
            hintText: 'Enter your full name',
          ),
          const SizedBox(height: 20),

          _buildTextField(
            label: 'Email Address (Optional)',
            controller: _emailController,
            icon: Icons.email_outlined,
            hintText: 'Enter your email',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 24),

          // User Type Selection
          _buildSectionTitle('Select Your Role', Icons.account_circle_outlined),
          const SizedBox(height: 16),
          _buildUserTypeSelection(),
          const SizedBox(height: 24),

          // Destinations for Supplier
          if (_selectedUserType == 'supplier') ...[
            _buildSectionTitle('Select Destinations', Icons.location_on_outlined),
            const SizedBox(height: 12),
            Text(
              'Choose cities where you provide services',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            _buildDestinationSelector(),
            const SizedBox(height: 24),
          ],

          // Services Selection
          _buildSectionTitle('Select Services You Offer', Icons.work_outline),
          const SizedBox(height: 12),
          Text(
            'We\'ll promote these after every booking',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          _buildServiceCards(),
          const SizedBox(height: 32),

          _buildGradientButton(
            onTap: _isLoading ? null : _saveProfile,
            text: 'Complete Sign Up',
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFD700).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFFFFD700),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildUserTypeSelection() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildEnhancedUserTypeCard(
              title: 'B2B Agent',
              subtitle: 'Request quotes from suppliers',
              icon: Icons.business_center_outlined,
              gradient: LinearGradient(
                colors: [
                  _selectedUserType == 'b2b'
                      ? const Color(0xFFFFD700)
                      : Colors.grey[300]!,
                  _selectedUserType == 'b2b'
                      ? const Color(0xFFFFC400)
                      : Colors.grey[200]!,
                ],
              ),
              isSelected: _selectedUserType == 'b2b',
              onTap: () {
                setState(() {
                  _selectedUserType = 'b2b';
                  _slideController.reset();
                  _slideController.forward();
                });
              },
            ),
          ),
          Container(
            width: 1,
            height: 80,
            color: Colors.grey[300],
          ),
          Expanded(
            child: _buildEnhancedUserTypeCard(
              title: 'Supplier',
              subtitle: 'Provide travel services',
              icon: Icons.local_shipping_outlined,
              gradient: LinearGradient(
                colors: [
                  _selectedUserType == 'supplier'
                      ? const Color(0xFFFFD700)
                      : Colors.grey[300]!,
                  _selectedUserType == 'supplier'
                      ? const Color(0xFFFFC400)
                      : Colors.grey[200]!,
                ],
              ),
              isSelected: _selectedUserType == 'supplier',
              onTap: () {
                setState(() {
                  _selectedUserType = 'supplier';
                  _slideController.reset();
                  _slideController.forward();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedUserTypeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: isSelected ? gradient : null,
                color: isSelected ? null : Colors.grey[200],
                shape: BoxShape.circle,
                boxShadow: isSelected
                    ? [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
                    : [],
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? const Color(0xFFFFD700) : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDestinationSelector() {
    return Column(
      children: [
        // Selected destinations chips
        if (_selectedDestinations.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9E6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedDestinations.map((destination) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFC400)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        destination.split(',')[0],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () => _toggleDestination(destination),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Add destination button
        InkWell(
          onTap: _showDestinationPicker,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFD700)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_location_outlined,
                  color: const Color(0xFFFFD700),
                ),
                const SizedBox(width: 12),
                Text(
                  _selectedDestinations.isEmpty
                      ? 'Select Destinations'
                      : 'Add More Destinations',
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showDestinationPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
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
                      'Select Destinations',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Search bar
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAFA),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setModalState(() {
                            _filterDestinations(value);
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search cities...',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(height: 1, color: Colors.grey[200]),
                  ],
                ),
              ),

              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _filteredDestinations.length,
                  itemBuilder: (context, index) {
                    final destination = _filteredDestinations[index];
                    final isSelected = _selectedDestinations.contains(destination['name']);

                    return InkWell(
                      onTap: () {
                        setState(() {
                          _toggleDestination(destination['name']!);
                        });
                        setModalState(() {});
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFFFF9E6)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    destination['name']!.split(',')[0],
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    destination['state']!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: Color(0xFFFFD700),
                                size: 24,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              Container(
                width: 200,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _searchController.clear();
                    _filterDestinations('');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    padding: const EdgeInsets.symmetric(vertical:10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(3),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Done (${_selectedDestinations.length} selected)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCards() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _serviceOptions.length,
      itemBuilder: (context, index) {
        final service = _serviceOptions[index];
        final isSelected = _selectedServices.contains(service['name']);

        return InkWell(
          onTap: () => _toggleService(service['name']),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFFFF9E6)
                  : const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFFFD700)
                    : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                BoxShadow(
                  color: const Color(0xFFFFD700).withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFFFD700)
                        : (service['color'] as Color).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    service['icon'],
                    color: isSelected ? Colors.white : service['color'],
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  service['name'],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? const Color(0xFFFFD700) : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isSelected) ...[
                  const SizedBox(height: 8),
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFFFFD700),
                    size: 20,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontWeight: FontWeight.w500,
              ),
              border: InputBorder.none,
              prefixIcon: Icon(icon, color: Colors.grey[600]),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGradientButton({
    required VoidCallback? onTap,
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
          onTap: onTap,
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
                const Icon(
                  Icons.arrow_forward,
                  color: Colors.black87,
                  size: 20,
                ),
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
                // Navigate to Terms of Service
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
                // Navigate to Privacy Policy
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
}
