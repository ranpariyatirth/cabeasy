import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import 'dart:math' as math;
import '../providers/chat_provider.dart';
import '../providers/auth_provider.dart';
import '../models/chat_message_model.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  bool _showScrollToBottom = false;
  bool _isInputFocused = false;

  late AnimationController _fabController;
  late AnimationController _messageController2;
  late AnimationController _shakeController;

  late Animation<double> _fabAnimation;
  late Animation<double> _messageAnimation;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();

    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _messageController2 = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fabAnimation = CurvedAnimation(
      parent: _fabController,
      curve: Curves.easeOutBack,
    );
    _messageAnimation = CurvedAnimation(
      parent: _messageController2,
      curve: Curves.easeOutCubic,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticOut),
    );

    _scrollController.addListener(_onScroll);
    _focusNode.addListener(() {
      setState(() {
        _isInputFocused = _focusNode.hasFocus;
      });
    });

    _messageController2.forward();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final showButton = _scrollController.offset > 200;
      if (showButton != _showScrollToBottom) {
        setState(() => _showScrollToBottom = showButton);
        if (showButton) {
          _fabController.forward();
        } else {
          _fabController.reverse();
        }
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _fabController.dispose();
    _messageController2.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  String? _getUserId() {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;
    if (user != null) {
      return user.phone.isNotEmpty ? user.phone : user.uid;
    }
    return null;
  }

  void _scrollToBottom({bool animate = true}) {
    if (_scrollController.hasClients) {
      if (animate) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      _shakeController.forward(from: 0);
      return;
    }

    final userId = _getUserId();
    if (userId == null) {
      _showSnackBar('Please login to use chat', isError: true);
      return;
    }

    _messageController.clear();
    _focusNode.unfocus();

    final chatProvider = context.read<ChatProvider>();
    await chatProvider.sendMessage(text, userId);

    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollToBottom();
    });

    _messageController2.forward(from: 0);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? AppColors.errorRed : AppColors.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                  const Color(0xFF1A1A1A),
                  const Color(0xFF0A0A0A),
                ]
                    : [
                  const Color(0xFFFFFCF5),
                  const Color(0xFFF5F5F5),
                ],
              ),
            ),
          ),

          // Main content
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Chat messages
                Expanded(
                  child: Consumer<ChatProvider>(
                    builder: (context, chatProvider, child) {
                      final messages = chatProvider.messages;
                      final isStreaming = chatProvider.isStreaming;

                      if (messages.isEmpty && !isStreaming) {
                        return _buildEmptyState(isDark, isSmallScreen);
                      }

                      return Stack(
                        children: [
                          ListView.builder(
                            controller: _scrollController,
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 16 : 24,
                              vertical: 20,
                            ),
                            itemCount: messages.length +
                                (chatProvider.isLoading && !isStreaming ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (chatProvider.isLoading &&
                                  !isStreaming &&
                                  index == messages.length) {
                                return _buildTypingIndicator(isDark);
                              }

                              final message = messages[index];
                              final showStreamed = isStreaming &&
                                  index == chatProvider.currentMessageIndex;

                              return _buildMessageBubble(
                                message,
                                isDark,
                                isSmallScreen,
                                streamedText: showStreamed
                                    ? chatProvider.displayedText
                                    : null,
                              );
                            },
                          ),

                          // Scroll to bottom FAB
                          if (_showScrollToBottom)
                            Positioned(
                              right: 16,
                              bottom: 16,
                              child: ScaleTransition(
                                scale: _fabAnimation,
                                child: _buildScrollToBottomButton(isDark),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),

                // Input area
                _buildInputArea(isDark, isSmallScreen),
              ],
            ),
          ),

          // Floating clear button (top right)
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, _) {
                if (chatProvider.messages.isEmpty) return const SizedBox.shrink();

                return _buildFloatingClearButton(isDark);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingClearButton(bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showClearChatDialog(isDark),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.refresh_rounded,
            color: isDark ? Colors.white70 : Colors.black54,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildScrollToBottomButton(bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _scrollToBottom(),
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryYellow,
                AppColors.primaryYellowDark,
              ],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryYellow.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.black87,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, bool isSmallScreen) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isSmallScreen ? 24 : 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated bot with glow effect (FIXED)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                final safeOpacity = value.clamp(0.0, 1.0);

                return Transform.scale(
                  scale: 0.5 + (0.5 * value), // keep overshoot for scale
                  child: Opacity(
                    opacity: safeOpacity, // CLAMPED → no crash
                    child: child,
                  ),
                );
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primaryYellow.withOpacity(0.3),
                          AppColors.primaryYellow.withOpacity(0),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primaryYellow,
                          AppColors.primaryYellowDark,
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryYellow.withOpacity(0.5),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      size: isSmallScreen ? 48 : 64,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: isSmallScreen ? 32 : 48),

            // Title (SAFE but optional clamp for extra safety)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                final safeOpacity = value.clamp(0.0, 1.0);

                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(
                    opacity: safeOpacity,
                    child: child,
                  ),
                );
              },
              child: ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    AppColors.primaryYellowDark,
                    AppColors.primaryYellow,
                  ],
                ).createShader(bounds),
                child: Text(
                  'AI Travel Assistant',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 28 : 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Subtitle (SAFE)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                final safeOpacity = value.clamp(0.0, 1.0);

                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(
                    opacity: safeOpacity,
                    child: child,
                  ),
                );
              },
              child: Text(
                'Ask me anything about travel, bookings,\nand cab services',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  color: isDark ? Colors.white60 : Colors.black54,
                  height: 1.5,
                ),
              ),
            ),

            SizedBox(height: isSmallScreen ? 40 : 56),

            // Suggestion chips (SAFE)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                final safeOpacity = value.clamp(0.0, 1.0);

                return Transform.scale(
                  scale: 0.8 + (0.2 * value),
                  child: Opacity(
                    opacity: safeOpacity,
                    child: child,
                  ),
                );
              },
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text, bool isDark, Color accentColor) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _messageController.text = text.split(' ').skip(1).join(' ');
          _sendMessage();
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accentColor.withOpacity(0.2),
                accentColor.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: accentColor.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            text,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.white.withOpacity(0.9),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) => _buildDot(i, isDark)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index, bool isDark) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        // Create looping animation safely
        final animationValue = (value + (index * 0.2)) % 1.0;

        // Safe scale between 0.6 → 1.0
        final scale = 0.6 + (0.4 * animationValue);

        // Safe opacity between 0.4 → 1.0
        final opacity = 0.4 + (0.6 * animationValue);

        return Transform.translate(
          offset: Offset(0, -4 * animationValue),
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity, // Always between 0 and 1
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: (isDark
                      ? AppColorsDark.primaryYellow
                      : AppColors.primaryYellow)
                      .withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isDark
                          ? AppColorsDark.primaryYellow
                          : AppColors.primaryYellow)
                          .withOpacity(0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Strip markdown formatting characters from text
  String _stripMarkdown(String text) {
    // Remove bold/italic markers: ** and *
    String cleaned = text.replaceAll(RegExp(r'\*{1,3}'), '');
    // Remove heading markers: # ## ###
    cleaned = cleaned.replaceAll(RegExp(r'^#{1,6}\s', multiLine: true), '');
    // Remove bullet markers: - at start of lines
    cleaned = cleaned.replaceAll(RegExp(r'^-\s', multiLine: true), '• ');
    return cleaned.trim();
  }

  Widget _buildMessageBubble(
      ChatMessage message,
      bool isDark,
      bool isSmallScreen, {
        String? streamedText,
      }) {
    final isUser = message.isUser;
    final rawContent = streamedText ?? message.content;
    // Strip markdown from bot responses
    final displayContent = isUser ? rawContent : _stripMarkdown(rawContent);
    final isComplete = streamedText == null || streamedText == message.content;
    final isError = message.isError;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisAlignment:
          isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isUser) ...[
              const SizedBox(width: 10),
            ],
            Flexible(
              child: GestureDetector(
                onLongPress: () {
                  _copyToClipboard(context, displayContent);
                },
                child: Column(
                crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  // Bot label
                  if (!isUser)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4, left: 4),
                      child: Text(
                        isError ? 'System' : 'AI Assistant',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isError
                              ? AppColors.errorRed.withValues(alpha: 0.7)
                              : (isDark ? AppColorsDark.textHint : AppColors.textSecondary),
                        ),
                      ),
                    ),
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width *
                          (isSmallScreen ? 0.75 : 0.6),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 16 : 20,
                      vertical: isSmallScreen ? 12 : 16,
                    ),
                    decoration: BoxDecoration(
                      gradient: isUser
                          ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primaryYellow,
                          AppColors.primaryYellowDark,
                        ],
                      )
                          : (isError
                          ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [const Color(0xFF2D1A1A), const Color(0xFF2A1515)]
                            : [const Color(0xFFFFF0F0), const Color(0xFFFFE8E8)],
                      )
                          : null),
                      color: (!isUser && !isError)
                          ? (isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.white.withOpacity(0.9))
                          : null,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(isUser ? 20 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 20),
                      ),
                      border: Border.all(
                        color: isError
                            ? AppColors.errorRed.withValues(alpha: 0.3)
                            : (isUser
                            ? Colors.transparent
                            : (isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.05))),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isUser
                              ? AppColors.primaryYellow.withOpacity(0.3)
                              : (isError
                              ? AppColors.errorRed.withOpacity(0.15)
                              : Colors.black.withOpacity(0.1)),
                          blurRadius: isUser ? 20 : 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Error icon row
                        if (isError) ...[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                size: 16,
                                color: AppColors.errorRed.withValues(alpha: 0.8),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Unable to process',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.errorRed.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                        SelectableText(
                          displayContent,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 15,
                            color: isUser
                                ? Colors.black87
                                : (isError
                                ? (isDark ? const Color(0xFFFF8A80) : const Color(0xFFC62828))
                                : (isDark ? Colors.white : Colors.black87)),
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatTime(message.timestamp),
                              style: TextStyle(
                                fontSize: 11,
                                color: isUser
                                    ? Colors.black45
                                    : (isDark ? Colors.white38 : Colors.black38),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (isUser) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.done_all_rounded,
                                size: 14,
                                color: Colors.black45,
                              ),
                            ],
                            if (!isComplete) ...[
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 10,
                                height: 10,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    AppColors.primaryYellow,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ),
            if (isUser) ...[
              const SizedBox(width: 10),
            ],
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    if (text.trim().isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Message copied', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryYellow,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Widget _buildBotAvatar({required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryYellow,
            AppColors.primaryYellowDark,
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryYellow.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        Icons.auto_awesome_rounded,
        size: size * 0.5,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildUserAvatar({required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[300]!,
            Colors.grey[400]!,
          ],
        ),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person_rounded,
        size: size * 0.55,
        color: Colors.white,
      ),
    );
  }

  Widget _buildInputArea(bool isDark, bool isSmallScreen) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final safePadding = MediaQuery.of(context).padding.bottom;
    final bottomPadding = bottomInset > 0 ? 8.0 : safePadding + 12;
    return Container(
      padding: EdgeInsets.fromLTRB(
        isSmallScreen ? 12 : 16,
        12,
        isSmallScreen ? 12 : 16,
        bottomPadding,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withOpacity(0.3)
            : Colors.white.withOpacity(0.9),
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _isInputFocused
                      ? AppColors.primaryYellow
                      : (isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05)),
                  width: _isInputFocused ? 2 : 1,
                ),
                boxShadow: _isInputFocused
                    ? [
                  BoxShadow(
                    color: AppColors.primaryYellow.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ]
                    : [],
              ),
              child: AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  final offset = 10 * _shakeAnimation.value *
                      (1 - _shakeAnimation.value) * 2;
                  return Transform.translate(
                    offset: Offset(offset, 0),
                    child: child,
                  );
                },
                child: TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 5,
                  minLines: 1,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black38,
                      fontWeight: FontWeight.normal,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 16 : 20,
                      vertical: 14,
                    ),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Use ValueListenableBuilder so the button reacts to typing
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _messageController,
            builder: (context, textValue, _) {
              return Consumer<ChatProvider>(
                builder: (context, chatProvider, _) {
                  final isLoading = chatProvider.isLoading;
                  final canSend = textValue.text.trim().isNotEmpty && !isLoading;

                  return GestureDetector(
                    onTap: canSend ? _sendMessage : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: canSend
                              ? [
                            AppColors.primaryYellow,
                            AppColors.primaryYellowDark,
                          ]
                              : [
                            Colors.grey[400]!,
                            Colors.grey[500]!,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: canSend
                            ? [
                          BoxShadow(
                            color:
                            AppColors.primaryYellow.withOpacity(0.5),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ]
                            : [],
                      ),
                      child: isLoading
                          ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: const AlwaysStoppedAnimation(
                            Colors.black87,
                          ),
                        ),
                      )
                          : Icon(
                        Icons.send_rounded,
                        color: Colors.black87,
                        size: 22,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _showClearChatDialog(bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
        isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.errorRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                color: AppColors.errorRed,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'Clear Chat?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        content: Text(
          'This will delete all your messages. This action cannot be undone.',
          style: TextStyle(
            fontSize: 15,
            color: isDark ? Colors.white70 : Colors.black54,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final chatProvider = context.read<ChatProvider>();
              chatProvider.clearChat();
              Navigator.pop(context);
              _showSnackBar('Chat cleared');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              elevation: 0,
            ),
            child: const Text(
              'Clear',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
