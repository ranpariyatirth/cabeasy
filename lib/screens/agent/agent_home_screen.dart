/// CabEasy - AgentHomeScreen
/// Purpose: Agent dashboard with in-page request, profile, request list, and complaint sections.

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../providers/theme_provider.dart';
import '../../services/n8n_service.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/gradient_button.dart';
import 'agent_request_detail_screen.dart';
import '../auth_wrapper.dart';
import '../chat_screen.dart';

const double _kHorizontalPadding = 20.0;
const double _kCardBorderRadius = 20.0;
const double _kDrawerHeaderHeight = 164.0;

class AgentHomeScreen extends StatefulWidget {
  const AgentHomeScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<AgentHomeScreen> createState() => _AgentHomeScreenState();
}

class _AgentHomeScreenState extends State<AgentHomeScreen>
    with TickerProviderStateMixin {
  final GlobalKey<FormState> _requestFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _complaintFormKey = GlobalKey<FormState>();

  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _paxLeaderController = TextEditingController();
  final TextEditingController _itineraryController = TextEditingController();
  final TextEditingController _minBudgetController = TextEditingController();
  final TextEditingController _maxBudgetController = TextEditingController();
  final TextEditingController _referenceIdController = TextEditingController();
  final TextEditingController _concernController = TextEditingController();
  final TextEditingController _paxCountController = TextEditingController(
    text: '1',
  );
  final TextEditingController _nightsCountController = TextEditingController(
    text: '0',
  );

  final FocusNode _destinationFocus = FocusNode();
  final FocusNode _pickupFocus = FocusNode();
  final FocusNode _paxLeaderFocus = FocusNode();
  final FocusNode _itineraryFocus = FocusNode();
  final FocusNode _minBudgetFocus = FocusNode();
  final FocusNode _maxBudgetFocus = FocusNode();
  final FocusNode _referenceFocus = FocusNode();
  final FocusNode _concernFocus = FocusNode();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _agencyNameController = TextEditingController();
  final TextEditingController _agencyWebsiteController =
      TextEditingController();
  final TextEditingController _agencyEmailController = TextEditingController();

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _agencyNameFocus = FocusNode();
  final FocusNode _agencyWebsiteFocus = FocusNode();
  final FocusNode _agencyEmailFocus = FocusNode();

  final List<String> _cabTypes = <String>[
    'Sedan',
    'SUV',
    'Hatchback',
    'Traveller',
    'Bus',
  ];
  // ignore: unused_field
  final List<String> _hotelTypes = <String>[
    '3 Star',
    '4 Star',
    '4 Deluxe',
    'Budget',
    '4 Luxury',
  ];
  final List<String> _serviceOptions = <String>[
    'Flights',
    'Hotels',
    'Visa Processing',
    'Holiday Packages',
    'Corporate Travel',
    'Train Tickets',
  ];

  final List<String> _selectedServices = <String>[];

  int _currentIndex = 0;
  int _paxCount = 1;
  int _nightsCount = 0;

  String? _selectedCabType;
  String? _selectedHotelType;
  DateTime? _selectedDate;

  bool _clientConfirmed = false;
  bool _flightsBooked = false;
  bool _hotelsBooked = false;
  bool _hotelRequired = false;

  bool _isRequestLoading = false;
  bool _isComplaintLoading = false;
  bool _isProfilePageLoading = false;
  bool _isProfileSaving = false;
  bool _hasProfileChanges = false;

  late final AnimationController _fadeController;
  late final AnimationController _slideController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  String _uid = '';
  String _authPhone = '';

  Map<String, dynamic> _initialProfileData = <String, dynamic>{
    'name': '',
    'phone': '',
    'email': '',
    'agencyName': '',
    'agencyWebsite': '',
    'agencyEmail': '',
    'otherServices': <String>[],
  };

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    final User? user = FirebaseAuth.instance.currentUser;
    _uid = user?.uid ?? '';
    _authPhone = user?.phoneNumber ?? '';

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 320),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );
    _fadeController.forward();
    _slideController.forward();

    for (final FocusNode n in <FocusNode>[
      _destinationFocus,
      _pickupFocus,
      _paxLeaderFocus,
      _itineraryFocus,
      _minBudgetFocus,
      _maxBudgetFocus,
      _referenceFocus,
      _concernFocus,
      _nameFocus,
      _emailFocus,
      _agencyNameFocus,
      _agencyWebsiteFocus,
      _agencyEmailFocus,
    ]) {
      n.addListener(() {
        if (mounted) setState(() {});
      });
    }

    for (final TextEditingController c in <TextEditingController>[
      _nameController,
      _emailController,
      _agencyNameController,
      _agencyWebsiteController,
      _agencyEmailController,
    ]) {
      c.addListener(_onProfileFormChanged);
    }

    _itineraryController.addListener(() {
      if (mounted) setState(() {});
    });
    _concernController.addListener(() {
      if (mounted) setState(() {});
    });
    _paxCountController.addListener(() {
      final int parsed = int.tryParse(_paxCountController.text) ?? _paxCount;
      final int normalized = parsed.clamp(1, 50);
      if (normalized != _paxCount && mounted) {
        setState(() => _paxCount = normalized);
      }
    });
    _nightsCountController.addListener(() {
      final int parsed =
          int.tryParse(_nightsCountController.text) ?? _nightsCount;
      final int normalized = parsed.clamp(0, 30);
      if (normalized != _nightsCount && mounted) {
        setState(() => _nightsCount = normalized);
      }
    });

    _loadProfile();
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _pickupController.dispose();
    _paxLeaderController.dispose();
    _itineraryController.dispose();
    _minBudgetController.dispose();
    _maxBudgetController.dispose();
    _referenceIdController.dispose();
    _concernController.dispose();
    _paxCountController.dispose();
    _nightsCountController.dispose();

    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _agencyNameController.dispose();
    _agencyWebsiteController.dispose();
    _agencyEmailController.dispose();

    _destinationFocus.dispose();
    _pickupFocus.dispose();
    _paxLeaderFocus.dispose();
    _itineraryFocus.dispose();
    _minBudgetFocus.dispose();
    _maxBudgetFocus.dispose();
    _referenceFocus.dispose();
    _concernFocus.dispose();

    _nameFocus.dispose();
    _emailFocus.dispose();
    _agencyNameFocus.dispose();
    _agencyWebsiteFocus.dispose();
    _agencyEmailFocus.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _onIndexChanged(int index) {
    setState(() => _currentIndex = index);
    _fadeController
      ..reset()
      ..forward();
    _slideController
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final app_auth.AuthProvider auth = Provider.of<app_auth.AuthProvider>(
      context,
    );
    final String agentName = auth.currentUser?.name.trim().isNotEmpty == true
        ? auth.currentUser!.name
        : 'Agent';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: _buildDrawer(agentName, _resolveAgentContact(auth)),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: Builder(
          builder: (BuildContext ctx) => IconButton(
            onPressed: () => Scaffold.of(ctx).openDrawer(),
            icon: Icon(Icons.menu, color: Theme.of(context).colorScheme.onSurface),
          ),
        ),
        title: Text(
          _titleForIndex(),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColorsDark.borderDefault : AppColors.borderDefault,
                  width: 1,
                ),
              ),
            ),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(position: _slideAnimation, child: _buildBody()),
      ),
      bottomNavigationBar: _buildBottomNavigator(),
    );
  }

  Widget _buildBody() {
    if (_currentIndex == 1) return _buildMyRequestsSection();
    if (_currentIndex == 2) return _buildProfileSection();
    if (_currentIndex == 3) return _buildRaiseComplaintSection();
    if (_currentIndex == 4) return _buildChatSection();
    return _buildPostRequestSection();
  }

  Widget _buildBottomNavigator() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isChatActive = _currentIndex == 4;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? AppColors.primaryYellow.withValues(alpha: 0.15)
                : AppColors.borderDefault,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.5)
                : AppColors.shadowGrey.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: <Widget>[
              // Form Tab
              Expanded(
                child: _bottomNavItem(
                  isActive: _currentIndex == 0,
                  icon: Icons.edit_note_rounded,
                  label: 'Post Request',
                  onTap: () => _onIndexChanged(0),
                ),
              ),
              const SizedBox(width: 8),
              // FAB-style Chat Button (Center)
              _buildChatFab(isActive: isChatActive),
              const SizedBox(width: 8),
              // My Requests Tab
              Expanded(
                child: _bottomNavItem(
                  isActive: _currentIndex == 1,
                  icon: Icons.assignment_outlined,
                  label: 'My Requests',
                  onTap: () => _onIndexChanged(1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatFab({required bool isActive}) {
    return GestureDetector(
      onTap: () => _onIndexChanged(4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: isActive ? 70 : 60,
        height: isActive ? 70 : 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isActive
                ? [AppColors.primaryYellowDark, AppColors.primaryYellow]
                : [AppColors.primaryYellow, AppColors.primaryYellowDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryYellow.withValues(alpha: 0.4),
              blurRadius: isActive ? 20 : 12,
              offset: const Offset(0, 4),
            ),
            if (isActive)
              BoxShadow(
                color: AppColors.primaryYellow.withValues(alpha: 0.2),
                blurRadius: 30,
                spreadRadius: 2,
              ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Pulse animation when active
            if (isActive)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 1.0, end: 1.3),
                duration: const Duration(milliseconds: 1000),
                builder: (context, value, child) {
                  return Container(
                    width: 60 * value,
                    height: 60 * value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primaryYellow.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                  );
                },
              ),
            // Icon
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? Icons.chat_rounded : Icons.chat_bubble_outline_rounded,
                key: ValueKey(isActive),
                color: AppColors.textPrimary,
                size: isActive ? 32 : 28,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomNavItem({
    required bool isActive,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primaryYellow.withValues(alpha: isDark ? 0.15 : 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: isActive
                ? Border.all(
                    color: AppColors.primaryYellow.withValues(alpha: 0.3),
                    width: 1,
                  )
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: Icon(
                  icon,
                  key: ValueKey(isActive),
                  size: 24,
                  color: isActive
                      ? AppColors.primaryYellowDark
                      : (isDark ? AppColorsDark.textSecondary : AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive
                      ? AppColors.primaryYellowDark
                      : (isDark ? AppColorsDark.textSecondary : AppColors.textSecondary),
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatSection() {
    return const ChatScreen();
  }

  Widget _buildDrawer(String agentName, String contact) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Drawer(
      backgroundColor: isDark ? AppColorsDark.cardBg : Colors.white,
      child: SafeArea(
        child: Column(
          children: <Widget>[
            // Premium Header with gradient and shadow
            Container(
              height: _kDrawerHeaderHeight + 20,
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 20, 20, 24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: <Color>[
                    AppColors.primaryYellow,
                    AppColors.primaryYellowDark,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryYellow.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      agentName.isNotEmpty ? agentName[0].toUpperCase() : 'A',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryYellow,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    agentName.isNotEmpty ? agentName : 'Agent',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.phone_outlined,
                        size: 14,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        contact,
                        style: const TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _drawerItem(0, Icons.add_circle_outline_rounded, 'Post New Request'),
                  const SizedBox(height: 8),
                  _drawerItem(1, Icons.assignment_outlined, 'My Requests'),
                  const SizedBox(height: 8),
                  _drawerItem(2, Icons.person_outline, 'My Profile'),
                  const SizedBox(height: 8),
                  _drawerItem(3, Icons.report_problem_outlined, 'Raise Complaint'),
                  const SizedBox(height: 8),
                  _drawerItem(4, Icons.chat_bubble_outline_rounded, 'AI Chat'),
                  const SizedBox(height: 16),
                  Divider(height: 1, color: isDark ? AppColorsDark.borderDefault : Colors.grey[200]),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            // Logout Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Material(
                color: Colors.red.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: _logout,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.logout_rounded, color: Colors.red[400], size: 20),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.red[400],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Dark Mode Toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Consumer<ThemeProvider>(
                builder: (context, themeProvider, _) {
                  final themeDark = themeProvider.isDarkMode;
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => themeProvider.toggleTheme(),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: themeDark
                              ? AppColors.primaryYellow.withValues(alpha: 0.15)
                              : AppColors.primaryYellow.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primaryYellow.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primaryYellow.withValues(alpha: themeDark ? 0.3 : 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                themeDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                                color: AppColors.primaryYellowDark,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                themeDark ? 'Light Mode' : 'Dark Mode',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: themeDark ? AppColors.primaryYellowDark : AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Switch(
                              value: themeDark,
                              onChanged: (_) => themeProvider.toggleTheme(),
                              activeColor: AppColors.primaryYellow,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  int _drawerIndexToNavIndex(int drawerIndex) {
    // Map drawer items to navigation indices
    // 0=Post Request -> nav 0
    // 1=My Requests -> nav 1
    // 2=My Profile -> nav 2
    // 3=Raise Complaint -> nav 3
    // 4=AI Chat -> nav 4
    return drawerIndex;
  }

  Widget _drawerItem(int index, IconData icon, String label) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool active = _currentIndex == index;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(30 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            _onIndexChanged(_drawerIndexToNavIndex(index));
          },
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: active
                  ? AppColors.primaryYellow.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: active
                  ? Border.all(color: AppColors.primaryYellow.withValues(alpha: 0.3), width: 1.5)
                  : null,
            ),
            child: Row(
              children: <Widget>[
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.primaryYellow
                        : (isDark ? AppColorsDark.subtleBg : AppColors.subtleBg),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: active
                        ? AppColors.textPrimary
                        : (isDark ? AppColorsDark.textSecondary : AppColors.textSecondary),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: active
                          ? AppColors.primaryYellowDark
                          : (isDark ? AppColorsDark.textPrimary : AppColors.textPrimary),
                    ),
                  ),
                ),
                if (active)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryYellow,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _titleForIndex() {
    if (_currentIndex == 1) return 'My Requests';
    if (_currentIndex == 2) return 'My Profile';
    if (_currentIndex == 3) return 'Raise Complaint';
    if (_currentIndex == 4) return 'Chat';
    return 'Post New Request';
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute<void>(builder: (_) => const AuthWrapper()),
        (_) => false,
      );
    } catch (e) {
      debugPrint('Logout failed: $e');
      _showErrorSnackBar('Failed to logout. Please try again.');
    }
  }

  Widget _buildPostRequestSection() {
    return Form(
      key: _requestFormKey,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(_kHorizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _sectionLabel('TRIP DETAILS'),
            const SizedBox(height: 12),
            AppCard(
              borderRadius: _kCardBorderRadius,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _fieldLabel('Destination *'),
                  const SizedBox(height: 8),
                  _input(
                    _destinationController,
                    _destinationFocus,
                    'e.g. Kashmir, Goa, Manali',
                    validator: (String? v) => (v == null || v.trim().isEmpty)
                        ? 'Destination is required'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  _fieldLabel('Pickup / Starting Location *'),
                  const SizedBox(height: 8),
                  _input(
                    _pickupController,
                    _pickupFocus,
                    'e.g. Srinagar Airport',
                    validator: (String? v) => (v == null || v.trim().isEmpty)
                        ? 'Pickup is required'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  _fieldLabel('Cab Type *'),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (BuildContext context, int i) => _chip(
                        _cabTypes[i],
                        _selectedCabType == _cabTypes[i],
                        () => setState(() => _selectedCabType = _cabTypes[i]),
                      ),
                      separatorBuilder: (BuildContext context, int i) =>
                          const SizedBox(width: 10),
                      itemCount: _cabTypes.length,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _fieldLabel('Number of Passengers (Pax) *'),
                  const SizedBox(height: 8),
                  _stepper(
                    _paxCount,
                    _paxCountController,
                    () => setState(() {
                      _paxCount = _paxCount > 1 ? _paxCount - 1 : 1;
                      _paxCountController.text = _paxCount.toString();
                    }),
                    () => setState(() {
                      _paxCount = _paxCount < 50 ? _paxCount + 1 : 50;
                      _paxCountController.text = _paxCount.toString();
                    }),
                  ),
                  const SizedBox(height: 14),
                  _fieldLabel('Number of Nights *'),
                  const SizedBox(height: 8),
                  _stepper(
                    _nightsCount,
                    _nightsCountController,
                    () => setState(() {
                      _nightsCount = _nightsCount > 0 ? _nightsCount - 1 : 0;
                      _nightsCountController.text = _nightsCount.toString();
                    }),
                    () => setState(() {
                      _nightsCount = _nightsCount < 30 ? _nightsCount + 1 : 30;
                      _nightsCountController.text = _nightsCount.toString();
                    }),
                  ),
                  const SizedBox(height: 14),
                  _fieldLabel('Starting Date *'),
                  const SizedBox(height: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _pickStartDate,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _selectedDate == null
                              ? (Theme.of(context).brightness == Brightness.dark ? AppColorsDark.borderDefault : AppColors.borderDefault)
                              : AppColors.borderFocused,
                          width: _selectedDate == null ? 1.5 : 2,
                        ),
                        boxShadow: _selectedDate == null
                            ? <BoxShadow>[]
                            : <BoxShadow>[
                                BoxShadow(
                                  color: AppColors.primaryYellow.withOpacity(
                                    0.2,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                      ),
                      child: Row(
                        children: <Widget>[
                          const Icon(
                            Icons.calendar_today_outlined,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _selectedDate == null
                                ? 'Select start date'
                                : DateFormat(
                                    'dd MMM yyyy',
                                  ).format(_selectedDate!),
                            style: TextStyle(
                              color: _selectedDate == null
                                  ? AppColors.textHint
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _sectionLabel('TRAVELLER INFO'),
            const SizedBox(height: 12),
            AppCard(
              borderRadius: _kCardBorderRadius,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _fieldLabel('Pax Leader Name *'),
                  const SizedBox(height: 8),
                  _input(
                    _paxLeaderController,
                    _paxLeaderFocus,
                    'Lead traveller name',
                    validator: (String? v) => (v == null || v.trim().isEmpty)
                        ? 'Pax leader is required'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  _fieldLabel('Detailed Itinerary (Optional)'),
                  const SizedBox(height: 8),
                  _input(
                    _itineraryController,
                    _itineraryFocus,
                    'Day 1: Arrive Srinagar...',
                    maxLines: 4,
                    maxLength: 500,
                    hideCounter: true,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${_itineraryController.text.length}/500',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _sectionLabel('CONFIRMATIONS'),
            const SizedBox(height: 12),
            AppCard(
              borderRadius: _kCardBorderRadius,
              child: Column(
                children: <Widget>[
                  _check(
                    _clientConfirmed,
                    'Client Confirmation Received',
                    (bool v) => setState(() => _clientConfirmed = v),
                  ),
                  _check(
                    _flightsBooked,
                    'Flights Booked',
                    (bool v) => setState(() => _flightsBooked = v),
                  ),
                  _check(
                    _hotelsBooked,
                    'Hotels Booked',
                    (bool v) => setState(() => _hotelsBooked = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _sectionLabel('BUDGET (OPTIONAL)'),
            const SizedBox(height: 12),
            AppCard(
              borderRadius: _kCardBorderRadius,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: _input(
                      _minBudgetController,
                      _minBudgetFocus,
                      'Min Budget Rs',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _input(
                      _maxBudgetController,
                      _maxBudgetFocus,
                      'Max Budget Rs',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            /* Hotel requirements temporarily hidden as requested.
          _sectionLabel('HOTEL REQUIREMENTS (OPTIONAL)'),
          const SizedBox(height: 12),
          AppCard(borderRadius: _kCardBorderRadius, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            _check(_hotelRequired, 'Hotel Required?', (bool v) => setState(() {
              _hotelRequired = v;
              if (!v) _selectedHotelType = null;
            })),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              height: _hotelRequired ? 50 : 0,
              child: _hotelRequired
                  ? ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (BuildContext context, int i) => _chip(_hotelTypes[i], _selectedHotelType == _hotelTypes[i], () => setState(() => _selectedHotelType = _hotelTypes[i])),
                separatorBuilder: (BuildContext context, int i) => const SizedBox(width: 10),
                itemCount: _hotelTypes.length,
              )
                  : const SizedBox.shrink(),
            ),
          ])),
          const SizedBox(height: 20),
          */
            const SizedBox(height: 8),
            GradientButton(
              onTap: _isRequestLoading ? null : _submitRequest,
              text: 'GET BID',
              isLoading: _isRequestLoading,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _pickStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 5),
      builder: (BuildContext context, Widget? child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primaryYellow,
            onPrimary: Colors.black87,
          ),
          datePickerTheme: DatePickerThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            headerBackgroundColor: AppColors.primaryYellow,
            headerForegroundColor: Colors.black87,
            dayForegroundColor: WidgetStateProperty.resolveWith<Color?>((
              Set<WidgetState> states,
            ) {
              if (states.contains(WidgetState.selected)) return Colors.black87;
              return AppColors.textPrimary;
            }),
            dayBackgroundColor: WidgetStateProperty.resolveWith<Color?>((
              Set<WidgetState> states,
            ) {
              if (states.contains(WidgetState.selected))
                return AppColors.primaryYellow;
              return null;
            }),
            todayBorder: const BorderSide(
              color: AppColors.primaryYellowDark,
              width: 1.5,
            ),
          ),
          buttonTheme: const ButtonThemeData(
            textTheme: ButtonTextTheme.primary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _submitRequest() async {
    if (!_requestFormKey.currentState!.validate()) return;
    if (_selectedCabType == null)
      return _showErrorSnackBar('Please select cab type');
    if (_selectedDate == null)
      return _showErrorSnackBar('Please select starting date');
    _paxCount = (int.tryParse(_paxCountController.text.trim()) ?? _paxCount)
        .clamp(1, 50);
    _nightsCount =
        (int.tryParse(_nightsCountController.text.trim()) ?? _nightsCount)
            .clamp(0, 30);
    _paxCountController.text = _paxCount.toString();
    _nightsCountController.text = _nightsCount.toString();

    setState(() => _isRequestLoading = true);
    try {
      final app_auth.AuthProvider auth = Provider.of<app_auth.AuthProvider>(
        context,
        listen: false,
      );
      final String agentId = _resolveAgentId(
        auth.currentUser?.phone,
        auth.currentUser?.uid,
      );
      if (agentId.isEmpty) throw Exception('Missing agent id');

      final String rawId = FirebaseFirestore.instance
          .collection('agentRequirements')
          .doc()
          .id;
      final String reqId = 'R--$rawId';
      final DocumentReference<Map<String, dynamic>> docRef = FirebaseFirestore
          .instance
          .collection('agentRequirements')
          .doc(reqId);

      final Map<String, dynamic> data = <String, dynamic>{
        'reqId': reqId,
        'agentId': agentId,
        'destination': _destinationController.text.trim(),
        'pickUp': _pickupController.text.trim(),
        'cabType': _selectedCabType,
        'pax': _paxCount.toString(),
        'noOfNights': _nightsCount.toString(),
        'startDate': _selectedDate!.millisecondsSinceEpoch,
        'trackingId': _paxLeaderController.text.trim(),
        'otherInfo': _itineraryController.text.trim(),
        'minBudget': _minBudgetController.text.trim(),
        'maxBudget': _maxBudgetController.text.trim(),
        'clientConfirmed': _clientConfirmed,
        'flightsBooked': _flightsBooked,
        'hotelsBooked': _hotelsBooked,
        'hotelRequired': _hotelRequired,
        'hotelType': _hotelRequired ? (_selectedHotelType ?? '') : '',
        'route': '',
        'priority': 'flexible',
        'status': 'open',
        'adminStatus': 'Waiting For Confirmation',
        'bookingId': '',
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'bids': <dynamic>[],
      };
      await docRef.set(data);
      final String autoPhone =
          (FirebaseAuth.instance.currentUser?.phoneNumber ?? '')
              .trim()
              .isNotEmpty
          ? FirebaseAuth.instance.currentUser!.phoneNumber!.trim()
          : _resolveAgentContact(auth);
      unawaited(
        N8nService.sendAgentFormPayload(
          destination: _destinationController.text.trim(),
          cabType: (_selectedCabType ?? '').toLowerCase(),
          pax: _paxCount.toString(),
          noOfNights: _nightsCount.toString(),
          pickUp: _pickupController.text.trim(),
          detailedItinerary: _itineraryController.text.trim(),
          startDate: _selectedDate!,
          leadPaxName: _paxLeaderController.text.trim(),
          phone: autoPhone,
          flightsBooked: _flightsBooked,
          hotelsBooked: _hotelsBooked,
          minBudget: _minBudgetController.text.trim(),
          maxBudget: _maxBudgetController.text.trim(),
          needsPackage: _hotelRequired,
          reqId: reqId,
        ),
      );
      unawaited(_triggerLeadClassification(reqId, data));
      if (!mounted) return;
      await _showSuccessBottomSheet(reqId);
      _resetRequestForm();
    } catch (e) {
      debugPrint('Failed to post request: $e');
      _showErrorSnackBar('Failed to post request. Please try again.');
    } finally {
      if (mounted) setState(() => _isRequestLoading = false);
    }
  }

  Future<void> _triggerLeadClassification(
    String reqId,
    Map<String, dynamic> data,
  ) async {
    try {
      final int startMs =
          (data['startDate'] as int?) ?? DateTime.now().millisecondsSinceEpoch;
      final DateTime travelDate = DateTime.fromMillisecondsSinceEpoch(startMs);
      await N8nService.triggerLeadClassification(
        requestId: reqId,
        pickupLocation: (data['pickUp'] ?? '').toString(),
        dropLocation: (data['destination'] ?? '').toString(),
        travelDate: travelDate,
        passengerCount: int.tryParse((data['pax'] ?? '1').toString()) ?? 1,
        vehicleType: (data['cabType'] ?? '').toString(),
        agentId: (data['agentId'] ?? '').toString(),
      );
    } catch (e) {
      debugPrint('Lead classification call failed (non-critical): $e');
    }
  }

  Future<void> _showSuccessBottomSheet(String reqId) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Request Submitted',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your request has been created successfully.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.subtleBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderDefault),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Reference ID: $reqId',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: reqId));
                          if (!mounted) return;
                          _showErrorSnackBar('Reference ID copied');
                        },
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        tooltip: 'Copy',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                GradientButton(
                  onTap: () => Navigator.of(context).pop(),
                  text: 'Done',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _resetRequestForm() {
    _destinationController.clear();
    _pickupController.clear();
    _paxLeaderController.clear();
    _itineraryController.clear();
    _minBudgetController.clear();
    _maxBudgetController.clear();
    _paxCountController.text = '1';
    _nightsCountController.text = '0';
    setState(() {
      _paxCount = 1;
      _nightsCount = 0;
      _selectedCabType = null;
      _selectedHotelType = null;
      _selectedDate = null;
      _clientConfirmed = false;
      _flightsBooked = false;
      _hotelsBooked = false;
      _hotelRequired = false;
    });
  }

  Widget _buildMyRequestsSection() {
    final app_auth.AuthProvider auth = Provider.of<app_auth.AuthProvider>(
      context,
    );
    final Set<String> agentIds = _currentAgentIds(auth);
    if (agentIds.isEmpty) {
      return _emptyState('Unable to load requests. Agent not identified.');
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('agentRequirements')
          .snapshots(),
      builder:
          (
            BuildContext context,
            AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot,
          ) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryYellow,
                ),
              );
            }
            if (snapshot.hasError) {
              return _emptyState('Failed to load requests');
            }
            final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs =
                (snapshot.data?.docs ??
                        <QueryDocumentSnapshot<Map<String, dynamic>>>[])
                    .where((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
                      final String docAgentId = (doc.data()['agentId'] ?? '')
                          .toString()
                          .trim();
                      return docAgentId.isNotEmpty &&
                          agentIds.contains(docAgentId);
                    })
                    .toList()
                  ..sort((
                    QueryDocumentSnapshot<Map<String, dynamic>> a,
                    QueryDocumentSnapshot<Map<String, dynamic>> b,
                  ) {
                    final int aCreated = (a.data()['createdAt'] is num)
                        ? (a.data()['createdAt'] as num).toInt()
                        : 0;
                    final int bCreated = (b.data()['createdAt'] is num)
                        ? (b.data()['createdAt'] as num).toInt()
                        : 0;
                    return bCreated.compareTo(aCreated);
                  });
            if (docs.isEmpty) {
              return _emptyState(
                'No requests yet. Post a new request to get started.',
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(_kHorizontalPadding),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (BuildContext context, int index) {
                final bool isDark = Theme.of(context).brightness == Brightness.dark;
                final Map<String, dynamic> data = docs[index].data();
                final String reqId = (data['reqId'] ?? docs[index].id)
                    .toString();
                final String destination = (data['destination'] ?? '-')
                    .toString();
                final String pickUp = (data['pickUp'] ?? '-').toString();
                final String cabType = (data['cabType'] ?? '-').toString();
                final String status = (data['status'] ?? 'open').toString();
                final int createdMs =
                    int.tryParse((data['createdAt'] ?? '').toString()) ?? 0;
                final String createdText = createdMs > 0
                    ? DateFormat(
                        'dd MMM yyyy, hh:mm a',
                      ).format(DateTime.fromMillisecondsSinceEpoch(createdMs))
                    : '-';
                final int bidsCount = (data['bids'] is List<dynamic>)
                    ? (data['bids'] as List<dynamic>).length
                    : 0;

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(_kCardBorderRadius),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => AgentRequestDetailScreen(
                            requestData: data,
                            requestId: reqId,
                          ),
                        ),
                      );
                    },
                    child: AppCard(
                      borderRadius: _kCardBorderRadius,
                      showAccent: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          // Header: Status + Copy
                          Row(
                            children: <Widget>[
                              _statusChip(status),
                              const Spacer(),
                              InkWell(
                                onTap: () async {
                                  await Clipboard.setData(
                                    ClipboardData(text: reqId),
                                  );
                                  if (!mounted) return;
                                  _showSuccessSnackBar('Request ID copied');
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.copy_rounded,
                                        size: 14,
                                        color: isDark ? AppColorsDark.textHint : AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        reqId.length > 16 ? '${reqId.substring(0, 16)}...' : reqId,
                                        style: TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 11,
                                          color: isDark ? AppColorsDark.textSecondary : AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Route visualization
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Route dots + line
                              Column(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primaryYellow,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Container(
                                    width: 2,
                                    height: 28,
                                    color: isDark ? AppColorsDark.borderDefault : AppColors.borderDefault,
                                  ),
                                  Icon(
                                    Icons.location_on,
                                    size: 14,
                                    color: isDark ? AppColorsDark.textHint : AppColors.textHint,
                                  ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              // Route text
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pickUp,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: isDark ? AppColorsDark.textPrimary : AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      destination,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: isDark ? AppColorsDark.textPrimary : AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Divider
                          Divider(
                            height: 1,
                            color: isDark ? AppColorsDark.borderDefault : AppColors.borderDefault,
                          ),
                          const SizedBox(height: 12),

                          // Info row
                          Row(
                            children: <Widget>[
                              _infoPill(
                                Icons.directions_car_filled_outlined,
                                cabType,
                              ),
                              const SizedBox(width: 8),
                              _infoPill(
                                Icons.people_outlined,
                                '${data['pax'] ?? '-'} pax',
                              ),
                              const SizedBox(width: 8),
                              if (bidsCount > 0)
                                _infoPill(
                                  Icons.local_offer_outlined,
                                  '$bidsCount bids',
                                ),
                              const Spacer(),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: isDark ? AppColorsDark.textHint : AppColors.textHint,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            createdText,
                            style: TextStyle(
                              color: isDark ? AppColorsDark.textSecondary : AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
    );
  }

  Widget _buildProfileSection() {
    if (_isProfilePageLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryYellow),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(_kHorizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _sectionLabel('MY DETAILS'),
          const SizedBox(height: 12),
          AppCard(
            borderRadius: _kCardBorderRadius,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _fieldLabel('Name *'),
                const SizedBox(height: 8),
                _input(
                  _nameController,
                  _nameFocus,
                  'Enter your name',
                  validator: (String? value) =>
                      (value == null || value.trim().isEmpty)
                      ? 'Name is required'
                      : null,
                ),
                const SizedBox(height: 14),
                _fieldLabel('Phone'),
                const SizedBox(height: 8),
                _input(_phoneController, null, 'Phone', readOnly: true),
                const SizedBox(height: 14),
                _fieldLabel('Email'),
                const SizedBox(height: 8),
                _input(
                  _emailController,
                  _emailFocus,
                  'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionLabel('AGENCY DETAILS'),
          const SizedBox(height: 12),
          AppCard(
            borderRadius: _kCardBorderRadius,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _fieldLabel('Agency Name'),
                const SizedBox(height: 8),
                _input(
                  _agencyNameController,
                  _agencyNameFocus,
                  'Company / Agency name',
                ),
                const SizedBox(height: 14),
                _fieldLabel('Agency Website'),
                const SizedBox(height: 8),
                _input(
                  _agencyWebsiteController,
                  _agencyWebsiteFocus,
                  'https://example.com',
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 14),
                _fieldLabel('Agency Email'),
                const SizedBox(height: 8),
                _input(
                  _agencyEmailController,
                  _agencyEmailFocus,
                  'agency@example.com',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 14),
                _fieldLabel('Other Services'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _serviceOptions.map((String service) {
                    final bool selected = _selectedServices.contains(service);
                    return FilterChip(
                      selected: selected,
                      showCheckmark: false,
                      selectedColor: AppColors.primaryYellow.withAlpha(51),
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      side: BorderSide(
                        color: selected
                            ? AppColors.primaryYellow
                            : AppColors.borderDefault,
                      ),
                      label: Text(service),
                      onSelected: (bool value) {
                        setState(() {
                          if (value) {
                            if (!_selectedServices.contains(service))
                              _selectedServices.add(service);
                          } else {
                            _selectedServices.remove(service);
                          }
                        });
                        _onProfileFormChanged();
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GradientButton(
            onTap: (!_hasProfileChanges || _isProfileSaving)
                ? null
                : _saveProfile,
            text: _isProfileSaving ? 'Saving...' : 'Save Profile',
            isLoading: _isProfileSaving,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildRaiseComplaintSection() {
    final app_auth.AuthProvider auth = Provider.of<app_auth.AuthProvider>(
      context,
    );
    final Set<String> agentIds = _currentAgentIds(auth);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('agentRequirements')
          .snapshots(),
      builder:
          (
            BuildContext context,
            AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot,
          ) {
            final List<QueryDocumentSnapshot<Map<String, dynamic>>> reqDocs =
                (snapshot.data?.docs ??
                        <QueryDocumentSnapshot<Map<String, dynamic>>>[])
                    .where((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
                      final String docAgentId = (doc.data()['agentId'] ?? '')
                          .toString()
                          .trim();
                      return docAgentId.isNotEmpty &&
                          agentIds.contains(docAgentId);
                    })
                    .toList()
                  ..sort((
                    QueryDocumentSnapshot<Map<String, dynamic>> a,
                    QueryDocumentSnapshot<Map<String, dynamic>> b,
                  ) {
                    final int aCreated = (a.data()['createdAt'] is num)
                        ? (a.data()['createdAt'] as num).toInt()
                        : 0;
                    final int bCreated = (b.data()['createdAt'] is num)
                        ? (b.data()['createdAt'] as num).toInt()
                        : 0;
                    return bCreated.compareTo(aCreated);
                  });

            return Form(
              key: _complaintFormKey,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(_kHorizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _sectionLabel('RAISE COMPLAINT'),
                    const SizedBox(height: 12),
                    AppCard(
                      borderRadius: _kCardBorderRadius,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          if (reqDocs.isNotEmpty) ...<Widget>[
                            _fieldLabel('Select From My Requests'),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue:
                                  reqDocs
                                      .map(
                                        (
                                          QueryDocumentSnapshot<
                                            Map<String, dynamic>
                                          >
                                          d,
                                        ) => (d.data()['reqId'] ?? d.id)
                                            .toString(),
                                      )
                                      .contains(
                                        _referenceIdController.text.trim(),
                                      )
                                  ? _referenceIdController.text.trim()
                                  : null,
                              decoration: InputDecoration(
                                hintText: 'Choose request',
                                prefixIcon: const Icon(
                                  Icons.assignment_outlined,
                                ),
                                filled: true,
                                fillColor: Theme.of(context).colorScheme.surface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: AppColors.borderDefault,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: AppColors.borderDefault,
                                  ),
                                ),
                              ),
                              items: reqDocs.map((
                                QueryDocumentSnapshot<Map<String, dynamic>> doc,
                              ) {
                                final Map<String, dynamic> data = doc.data();
                                final String reqId = (data['reqId'] ?? doc.id)
                                    .toString();
                                final String route =
                                    '${(data['pickUp'] ?? '').toString()} -> ${(data['destination'] ?? '').toString()}';
                                return DropdownMenuItem<String>(
                                  value: reqId,
                                  child: Text(
                                    '$reqId - $route',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? value) {
                                if (value != null) {
                                  setState(
                                    () => _referenceIdController.text = value,
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 14),
                          ],
                          _fieldLabel('Request / Booking Reference *'),
                          const SizedBox(height: 8),
                          _input(
                            _referenceIdController,
                            _referenceFocus,
                            'Enter request ID',
                            validator: (String? value) =>
                                (value == null || value.trim().isEmpty)
                                ? 'Reference is required'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          _fieldLabel('Concern *'),
                          const SizedBox(height: 8),
                          _input(
                            _concernController,
                            _concernFocus,
                            'Explain the issue in detail',
                            maxLines: 5,
                            maxLength: 700,
                            hideCounter: true,
                            validator: (String? value) =>
                                (value == null || value.trim().isEmpty)
                                ? 'Concern is required'
                                : null,
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '${_concernController.text.length}/700',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    GradientButton(
                      onTap: _isComplaintLoading ? null : _submitComplaint,
                      text: 'Submit Complaint',
                      isLoading: _isComplaintLoading,
                    ),
                    const SizedBox(height: 20),
                    _buildComplaintHistory(agentIds),
                  ],
                ),
              ),
            );
          },
    );
  }

  Future<void> _submitComplaint() async {
    if (!_complaintFormKey.currentState!.validate()) return;
    if (_uid.isEmpty) {
      _showErrorSnackBar('Agent not identified. Please login again.');
      return;
    }

    setState(() => _isComplaintLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('complaints')
          .add(<String, dynamic>{
            'agentId': _uid,
            'agentPhone': _resolveAgentContact(
              Provider.of<app_auth.AuthProvider>(context, listen: false),
            ),
            'agentName':
                Provider.of<app_auth.AuthProvider>(
                  context,
                  listen: false,
                ).currentUser?.name ??
                '',
            'referenceId': _referenceIdController.text.trim(),
            'concern': _concernController.text.trim(),
            'status': 'open',
            'createdAt': DateTime.now().millisecondsSinceEpoch,
          });
      if (!mounted) return;
      _referenceIdController.clear();
      _concernController.clear();
      _showSuccessSnackBar('Complaint submitted successfully');
    } catch (e) {
      debugPrint('Failed to submit complaint: $e');
      _showErrorSnackBar('Failed to submit complaint. Please try again.');
    } finally {
      if (mounted) setState(() => _isComplaintLoading = false);
    }
  }

  Future<void> _loadProfile() async {
    if (_uid.isEmpty) return;
    setState(() => _isProfilePageLoading = true);
    try {
      final DocumentSnapshot<Map<String, dynamic>> doc = await FirebaseFirestore
          .instance
          .collection('users')
          .doc(_uid)
          .get();
      final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};

      _nameController.text = (data['name'] ?? '').toString();
      _phoneController.text =
          (data['phone'] ?? data['phoneNumber'] ?? _authPhone).toString();
      _emailController.text = (data['email'] ?? '').toString();
      _agencyNameController.text =
          (data['agencyName'] ?? data['companyName'] ?? '').toString();
      _agencyWebsiteController.text = (data['agencyWebsite'] ?? '').toString();
      _agencyEmailController.text = (data['agencyEmail'] ?? '').toString();

      final List<String> services =
          ((data['otherServices'] as List<dynamic>?) ?? <dynamic>[])
              .map((dynamic item) => item.toString())
              .toList();
      _selectedServices
        ..clear()
        ..addAll(services);

      _initialProfileData = _currentProfileData();
      _hasProfileChanges = false;
    } catch (e) {
      debugPrint('Failed to load profile: $e');
      _showErrorSnackBar('Could not load profile');
    } finally {
      if (mounted) setState(() => _isProfilePageLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (_uid.isEmpty) return;
    setState(() => _isProfileSaving = true);
    try {
      final Map<String, dynamic> payload = _currentProfileData()
        ..['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .set(payload, SetOptions(merge: true));
      _initialProfileData = _currentProfileData();
      _hasProfileChanges = false;
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated')));
    } catch (e) {
      debugPrint('Failed to save profile: $e');
      _showErrorSnackBar('Failed to save profile');
    } finally {
      if (mounted) setState(() => _isProfileSaving = false);
    }
  }

  void _onProfileFormChanged() {
    final bool changed = !_mapsShallowEqual(
      _initialProfileData,
      _currentProfileData(),
    );
    if (changed != _hasProfileChanges && mounted) {
      setState(() => _hasProfileChanges = changed);
    }
  }

  Map<String, dynamic> _currentProfileData() {
    final List<String> services = List<String>.from(_selectedServices)..sort();
    return <String, dynamic>{
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'email': _emailController.text.trim(),
      'agencyName': _agencyNameController.text.trim(),
      'agencyWebsite': _agencyWebsiteController.text.trim(),
      'agencyEmail': _agencyEmailController.text.trim(),
      'otherServices': services,
    };
  }

  bool _mapsShallowEqual(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    for (final String key in a.keys) {
      if (!b.containsKey(key)) return false;
      final dynamic av = a[key];
      final dynamic bv = b[key];
      if (av is List && bv is List) {
        final List<String> al = av.map((dynamic e) => e.toString()).toList()
          ..sort();
        final List<String> bl = bv.map((dynamic e) => e.toString()).toList()
          ..sort();
        if (al.length != bl.length) return false;
        for (int i = 0; i < al.length; i++) {
          if (al[i] != bl[i]) return false;
        }
      } else if ((av ?? '').toString() != (bv ?? '').toString()) {
        return false;
      }
    }
    return true;
  }

  String _resolveAgentContact(app_auth.AuthProvider auth) {
    final List<String?> candidates = <String?>[
      auth.currentUser?.phone,
      _phoneController.text,
      _authPhone,
      FirebaseAuth.instance.currentUser?.phoneNumber,
    ];
    for (final String? value in candidates) {
      if (value != null && value.trim().isNotEmpty) return value.trim();
    }
    return 'No contact';
  }

  String _resolveAgentId(String? providerPhone, String? providerUid) {
    final List<String?> candidates = <String?>[
      _uid,
      providerUid,
      FirebaseAuth.instance.currentUser?.uid,
      providerPhone,
      _authPhone,
    ];
    for (final String? value in candidates) {
      if (value != null && value.trim().isNotEmpty) return value.trim();
    }
    return '';
  }

  Widget _sectionLabel(String text) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
        color: isDark ? AppColorsDark.textSecondary : AppColors.textSecondary,
      ),
    );
  }

  Widget _fieldLabel(String text) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColorsDark.textPrimary : AppColors.textPrimary,
      ),
    );
  }

  Widget _input(
    TextEditingController controller,
    FocusNode? focusNode,
    String hint, {
    String? Function(String?)? validator,
    int maxLines = 1,
    int? maxLength,
    bool hideCounter = false,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final bool focused = focusNode?.hasFocus ?? false;
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      validator: validator,
      readOnly: readOnly,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      buildCounter: hideCounter
          ? (
              BuildContext context, {
              required int currentLength,
              required bool isFocused,
              required int? maxLength,
            }) => null
          : null,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textHint),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? AppColorsDark.borderDefault : AppColors.borderDefault),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? AppColorsDark.borderDefault : AppColors.borderDefault),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: focused ? AppColors.borderFocused : (Theme.of(context).brightness == Brightness.dark ? AppColorsDark.borderDefault : AppColors.borderDefault),
            width: focused ? 2 : 1.5,
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryYellow.withAlpha(51)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primaryYellow : AppColors.borderDefault,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black87 : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _stepper(
    int value,
    TextEditingController controller,
    VoidCallback onMinus,
    VoidCallback onPlus,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? AppColorsDark.borderDefault : AppColors.borderDefault),
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: onMinus,
            icon: const Icon(
              Icons.remove_circle_outline,
              color: AppColors.primaryYellow,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: onPlus,
            icon: const Icon(Icons.add_circle, color: AppColors.primaryYellow),
          ),
        ],
      ),
    );
  }

  Widget _check(bool value, String label, ValueChanged<bool> onChanged) {
    return CheckboxListTile(
      value: value,
      contentPadding: EdgeInsets.zero,
      dense: true,
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: AppColors.primaryYellow,
      title: Text(label, style: const TextStyle(fontSize: 14)),
      onChanged: (bool? next) => onChanged(next ?? false),
    );
  }

  Widget _statusChip(String status) {
    final String normalized = status.trim().toLowerCase();
    Color color = AppColors.infoBlue;
    if (normalized == 'open') color = AppColors.warningOrange;
    if (normalized == 'closed') color = AppColors.successGreen;
    if (normalized == 'cancelled') color = AppColors.errorRed;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _infoPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? AppColorsDark.subtleBg : AppColors.subtleBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? AppColorsDark.borderDefault : AppColors.borderDefault),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintHistory(Set<String> agentIds) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('complaints').snapshots(),
      builder:
          (
            BuildContext context,
            AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot,
          ) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryYellow,
                ),
              );
            }
            if (snapshot.hasError) {
              return _emptyState('Failed to load complaints');
            }

            final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs =
                (snapshot.data?.docs ??
                        <QueryDocumentSnapshot<Map<String, dynamic>>>[])
                    .where((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
                      final Map<String, dynamic> data = doc.data();
                      final String docAgentId = (data['agentId'] ?? '')
                          .toString()
                          .trim();
                      final String docPhone = (data['agentPhone'] ?? '')
                          .toString()
                          .trim();
                      return (docAgentId.isNotEmpty &&
                              agentIds.contains(docAgentId)) ||
                          (docPhone.isNotEmpty && agentIds.contains(docPhone));
                    })
                    .toList()
                  ..sort((
                    QueryDocumentSnapshot<Map<String, dynamic>> a,
                    QueryDocumentSnapshot<Map<String, dynamic>> b,
                  ) {
                    final int aCreated = (a.data()['createdAt'] is num)
                        ? (a.data()['createdAt'] as num).toInt()
                        : 0;
                    final int bCreated = (b.data()['createdAt'] is num)
                        ? (b.data()['createdAt'] as num).toInt()
                        : 0;
                    return bCreated.compareTo(aCreated);
                  });

            if (docs.isEmpty) {
              return _emptyState('No complaints raised yet.');
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _sectionLabel('PAST COMPLAINTS'),
                const SizedBox(height: 10),
                ListView.separated(
                  itemCount: docs.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (BuildContext context, int index) {
                    final Map<String, dynamic> data = docs[index].data();
                    final String status = (data['status'] ?? 'open').toString();
                    final String referenceId = (data['referenceId'] ?? '-')
                        .toString();
                    final String concern = (data['concern'] ?? '').toString();
                    final int createdMs = (data['createdAt'] is num)
                        ? (data['createdAt'] as num).toInt()
                        : 0;
                    final String createdText = createdMs > 0
                        ? DateFormat('dd MMM yyyy, hh:mm a').format(
                            DateTime.fromMillisecondsSinceEpoch(createdMs),
                          )
                        : '-';

                    return AppCard(
                      borderRadius: _kCardBorderRadius,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  'Ref: $referenceId',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              _complaintStatusBadge(status),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            concern,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            createdText,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            );
          },
    );
  }

  Widget _complaintStatusBadge(String status) {
    final String normalized = status.trim().toLowerCase();
    Color bg = AppColors.warningOrange.withAlpha(28);
    Color fg = AppColors.warningOrange;
    if (normalized == 'resolved' || normalized == 'closed') {
      bg = AppColors.successGreen.withAlpha(28);
      fg = AppColors.successGreen;
    } else if (normalized == 'in_review') {
      bg = AppColors.infoBlue.withAlpha(28);
      fg = AppColors.infoBlue;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }

  Set<String> _currentAgentIds(app_auth.AuthProvider auth) {
    return <String>{
      if ((auth.currentUser?.uid ?? '').trim().isNotEmpty)
        auth.currentUser!.uid.trim(),
      if ((auth.currentUser?.phone ?? '').trim().isNotEmpty)
        auth.currentUser!.phone.trim(),
      if ((_authPhone).trim().isNotEmpty) _authPhone.trim(),
    };
  }

  Widget _emptyState(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryYellow,
      ),
    );
  }
}
