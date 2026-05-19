import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/profile.dart';
import '../../auth/providers/auth_provider.dart';
import '../../matching/providers/matching_provider.dart';
import '../../chat/providers/chat_provider.dart';
import '../../subscription/providers/subscription_provider.dart';

class HomePage extends StatefulWidget {
  final void Function(int)? onNavigate;
  const HomePage({super.key, this.onNavigate});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _pseudo;
  Timer? _noonRefreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _scheduleNoonRefresh();
    });
  }

  @override
  void dispose() {
    _noonRefreshTimer?.cancel();
    super.dispose();
  }

  /// Schedules a timer that fires at the next local noon and refreshes the
  /// daily selection. After each firing it re-schedules itself for the
  /// following noon, so the refresh recurs every day.
  void _scheduleNoonRefresh() {
    final now = DateTime.now();
    var nextNoon = DateTime(now.year, now.month, now.day, 12);
    if (!now.isBefore(nextNoon)) {
      // Already past noon today — schedule for tomorrow.
      nextNoon = nextNoon.add(const Duration(days: 1));
    }
    final delay = nextNoon.difference(now);

    _noonRefreshTimer = Timer(delay, () {
      if (mounted) {
        context.read<MatchingProvider>().loadDailySelection();
      }
      // Re-schedule for the next noon.
      _scheduleNoonRefresh();
    });
  }

  Future<void> _loadData() async {
    unawaited(context.read<MatchingProvider>().loadDailySelection());
    try {
      final res = await ApiService.getProfile();
      final data = res['data'] ?? res;
      if (mounted) setState(() => _pseudo = data['pseudo'] as String?);
    } catch (_) {}
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bonjour';
    if (h < 17) return 'Bon après-midi';
    return 'Bonsoir';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final firstName = _pseudo ?? auth.user?.displayName ?? 'vous';
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHero(firstName)),
              SliverToBoxAdapter(child: _buildStreakCard()),
              SliverToBoxAdapter(child: _buildProfilesHeader()),
              SliverToBoxAdapter(child: _buildProfilesList()),
              SliverToBoxAdapter(child: _buildActiveConversation()),
              SliverToBoxAdapter(child: _buildConseilDuJour()),
              SliverToBoxAdapter(child: _buildPlusBanner()),
              const SliverToBoxAdapter(child: SizedBox(height: 110)),
            ],
          );
        },
      ),
    );
  }

  // --- Hero header -------------------------------------------------------

  Widget _buildHero(String firstName) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return Container(
          height: 280,
          decoration: BoxDecoration(gradient: AppColors.heroGradient),
          child: Stack(
            children: [
              // Mountain silhouettes
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: CustomPaint(
                  size: const Size(double.infinity, 120),
                  painter: _MountainPainter(),
                ),
              ),
              // Safe area padding + content
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Avatar button
                          GestureDetector(
                            onTap: () => widget.onNavigate?.call(2),
                            child: Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppColors.premiumGradient,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.25),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  firstName.isNotEmpty ? firstName[0].toUpperCase() : 'G',
                                  style: const TextStyle(
                                    fontFamily: 'Playfair Display',
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Notifications
                          GestureDetector(
                            onTap: () => context.push('/notifications'),
                            child: Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.20),
                              ),
                              child: const Icon(
                                Icons.notifications_outlined,
                                size: 18,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      // Greeting
                      Text(
                        '$_greeting,',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        firstName,
                        style: const TextStyle(
                          fontFamily: 'Playfair Display',
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '« Prenez le temps. »',
                        style: TextStyle(
                          fontFamily: 'Playfair Display',
                          fontStyle: FontStyle.italic,
                          fontSize: 13,
                          color: AppColors.textDark.withOpacity(0.78),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Streak / Ritual card -----------------------------------------------

  Widget _buildStreakCard() {
    final days = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    final todayIdx = DateTime.now().weekday - 1; // Mon=0

    return Consumer<MatchingProvider>(
      builder: (context, mp, _) {
        final hasEngagedToday = mp.dailySelection != null;
        final subtitle = hasEngagedToday
            ? 'Actif aujourd\'hui ✓'
            : 'Revenez chaque jour';

    return Container(
      margin: const EdgeInsets.fromLTRB(18, -22, 18, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppShadows.medium(),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.primaryGold.withOpacity(0.12),
                ),
                child: const Icon(Icons.local_fire_department_rounded,
                    size: 22, color: AppColors.primaryGold),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Votre rituel',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Playfair Display',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final done = i < todayIdx && hasEngagedToday;
              final today = i == todayIdx;
              return Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done ? AppColors.primaryGold : Colors.transparent,
                        border: Border.all(
                          color: today
                              ? AppColors.primaryGold
                              : done
                                  ? Colors.transparent
                                  : AppColors.dividerLight,
                          width: today ? 2 : 1.5,
                        ),
                      ),
                      child: Center(
                        child: done
                            ? const Icon(Icons.check, size: 13, color: Colors.white)
                            : today
                                ? Container(
                                    width: 8, height: 8,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.primaryGold,
                                    ),
                                  )
                                : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      days[i],
                      style: TextStyle(
                        fontSize: 10,
                        color: today ? AppColors.primaryGold : AppColors.textTertiary,
                        fontWeight: today ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
      }, // end Consumer builder
    ); // end Consumer
  }

  // --- Profiles du jour --------------------------------------------------

  Widget _buildProfilesHeader() {
    return Consumer<MatchingProvider>(
      builder: (context, mp, _) {
        final used = mp.remainingSelections == 0;
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Profils du jour',
                      style: TextStyle(
                        fontFamily: 'Playfair Display',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${mp.dailyProfiles.length} personnes choisies pour vous',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                used ? 'Choix utilisé' : '${mp.remainingSelections} choix',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryGold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfilesList() {
    return Consumer<MatchingProvider>(
      builder: (context, mp, _) {
        if (mp.isLoading) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppColors.primaryGold),
                strokeWidth: 2,
              ),
            ),
          );
        }

        final profiles = mp.dailyProfiles;
        if (profiles.isEmpty) {
          return _buildEmptyState();
        }

        final used = mp.remainingSelections == 0;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: profiles.map((p) {
              return _buildProfileCard(p, dimmed: used);
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildProfileCard(Profile profile, {bool dimmed = false}) {
    final score = ((profile.compatibilityScore ?? 0.88) * 100).round();
    final firstPhoto = profile.photos.isNotEmpty ? profile.photos.first.url : null;
    final firstPrompt = profile.promptAnswers.isNotEmpty
        ? profile.promptAnswers.first
        : null;

    // Gradient colors for the card header when no photo
    final cardGradients = [
      [const Color(0xFFF5E6B8), const Color(0xFFD4AF37), const Color(0xFF8B6914)],
      [const Color(0xFFFFE5D1), const Color(0xFFE8C547), const Color(0xFFB8941F)],
      [const Color(0xFFFAF0E6), const Color(0xFFF5E6B8), const Color(0xFFD4AF37)],
    ];
    final gradIdx = profile.id.hashCode.abs() % cardGradients.length;
    final grad = cardGradients[gradIdx];

    return GestureDetector(
      onTap: () => context.push('/profile/${profile.id}'),
      child: AnimatedOpacity(
        duration: AppAnimations.fast,
        opacity: dimmed ? 0.55 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppShadows.soft(),
            border: Border.all(
              color: AppColors.primaryGold.withOpacity(0.20),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo / gradient area (240px)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(23)),
                child: SizedBox(
                  height: 240,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Background
                      firstPhoto != null
                          ? Image.network(firstPhoto, fit: BoxFit.cover)
                          : Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: grad,
                                ),
                              ),
                            ),
                      // Compatibility badge
                      Positioned(
                        top: 14, right: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.90),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded,
                                  size: 11, color: AppColors.primaryGold),
                              const SizedBox(width: 4),
                              Text(
                                '$score% compatible',
                                style: const TextStyle(
                                  fontFamily: 'Playfair Display',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: AppColors.goldDeep,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Name / city overlay bottom
                      Positioned(
                        bottom: 18, left: 18,
                        child: DefaultTextStyle(
                          style: const TextStyle(
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Color(0x66000000),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${profile.pseudo ?? 'Profil'}, ${profile.age ?? '?'}',
                                style: const TextStyle(
                                  fontFamily: 'Playfair Display',
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              if (profile.location != null)
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_rounded,
                                        size: 12, color: Colors.white),
                                    const SizedBox(width: 3),
                                    Text(
                                      profile.location!,
                                      style: const TextStyle(
                                          fontSize: 12.5, height: 1),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Prompt preview
              if (firstPrompt != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                  child: Text(
                    '« ${firstPrompt.answer} »',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Playfair Display',
                      fontStyle: FontStyle.italic,
                      fontSize: 14.5,
                      color: AppColors.textDark,
                      height: 1.45,
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                  child: Text(
                    profile.bio ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppShadows.soft(),
        ),
        child: Column(
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryGold.withOpacity(0.12),
              ),
              child: const Icon(Icons.favorite_outline_rounded,
                  size: 28, color: AppColors.primaryGold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Revenez à midi',
              style: TextStyle(
                fontFamily: 'Playfair Display',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Votre sélection du jour sera prête à midi.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Active conversation -----------------------------------------------

  Widget _buildActiveConversation() {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, _) {
        final activeChats = chatProvider.activeConversations;
        if (activeChats.isEmpty) return const SizedBox.shrink();
        final chat = activeChats.first;

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Conversation active',
                    style: TextStyle(
                      fontFamily: 'Playfair Display',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => widget.onNavigate?.call(1),
                    child: const Text(
                      'Toutes →',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryGold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => context.push('/chat/${chat.id}'),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppShadows.soft(),
                  ),
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.premiumGradient,
                        ),
                        child: Center(
                          child: Text(
                            (chat.otherParticipant?.pseudo ?? 'M')[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Playfair Display',
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  chat.otherParticipant?.pseudo ?? 'Match',
                                  style: const TextStyle(
                                    fontFamily: 'Playfair Display',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14.5,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                if (chat.expiresAt != null)
                                  _buildTimer(chat.expiresAt!),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              chat.lastMessage?.content ?? 'Commencez la conversation',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimer(DateTime expiresAt) {
    final remaining = expiresAt.difference(DateTime.now());
    final hours = remaining.inHours;
    final color = hours < 4 ? AppColors.errorRed : AppColors.primaryGold;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.access_time_rounded, size: 10, color: color),
        const SizedBox(width: 3),
        Text(
          '${hours}h',
          style: TextStyle(
            fontSize: 10.5,
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // --- Conseil du jour ---------------------------------------------------

  Widget _buildConseilDuJour() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primaryGold.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primaryGold.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  size: 12, color: AppColors.primaryGold),
              const SizedBox(width: 6),
              const Text(
                'CONSEIL DU JOUR',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryGold,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '« Une question ouverte vaut mille messages. Demandez ce qui les fait vibrer. »',
            style: TextStyle(
              fontFamily: 'Playfair Display',
              fontStyle: FontStyle.italic,
              fontSize: 15,
              color: AppColors.textDark,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  // --- GoldWen Plus banner -----------------------------------------------

  Widget _buildPlusBanner() {
    return Consumer<SubscriptionProvider>(
      builder: (context, sub, _) {
        if (sub.hasActiveSubscription) return const SizedBox.shrink();
        return GestureDetector(
          onTap: () => context.push('/subscription'),
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 22, 20, 0),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: AppColors.premiumGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppShadows.gold(),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.star_rounded, size: 15, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'GoldWen Plus',
                      style: TextStyle(
                        fontFamily: 'Playfair Display',
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Triplez vos rencontres',
                  style: TextStyle(
                    fontFamily: 'Playfair Display',
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Choisissez 3 profils chaque jour. Et prolongez vos conversations.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.white,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Mountain silhouette painter for hero
class _MountainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = AppColors.goldDeep.withOpacity(0.20)
      ..style = PaintingStyle.fill;

    final paint2 = Paint()
      ..color = AppColors.primaryGoldDark.withOpacity(0.14)
      ..style = PaintingStyle.fill;

    final path1 = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.67)
      ..lineTo(size.width * 0.15, size.height * 0.33)
      ..lineTo(size.width * 0.275, size.height * 0.58)
      ..lineTo(size.width * 0.40, size.height * 0.25)
      ..lineTo(size.width * 0.55, size.height * 0.625)
      ..lineTo(size.width * 0.70, size.height * 0.375)
      ..lineTo(size.width * 0.85, size.height * 0.67)
      ..lineTo(size.width, size.height * 0.46)
      ..lineTo(size.width, size.height)
      ..close();

    final path2 = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.79)
      ..lineTo(size.width * 0.10, size.height * 0.625)
      ..lineTo(size.width * 0.25, size.height * 0.75)
      ..lineTo(size.width * 0.375, size.height * 0.54)
      ..lineTo(size.width * 0.525, size.height * 0.75)
      ..lineTo(size.width * 0.675, size.height * 0.58)
      ..lineTo(size.width * 0.825, size.height * 0.79)
      ..lineTo(size.width, size.height * 0.67)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path1, paint1);
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(_MountainPainter old) => false;
}
