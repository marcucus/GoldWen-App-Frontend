import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/models.dart';
import '../providers/matching_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../widgets/report_dialog.dart';
import '../../profile/widgets/media_player_widget.dart';
import '../../../shared/widgets/optimized_image.dart';

/// Displays a real profile (from today's daily selection, from an existing
/// match, or from "qui m'a choisi·e") — never mock data.
///
/// `profileId` is looked up in whatever list the app has already loaded
/// (MatchingProvider keeps the daily selection, the matches list and the
/// who-liked-me list in memory), which covers every place that navigates
/// here. If none of those lists carry the profile yet — a deep link, or a
/// cold start — the page fetches them once before giving up.
class ProfileDetailPage extends StatefulWidget {
  final String profileId;

  const ProfileDetailPage({
    super.key,
    required this.profileId,
  });

  @override
  State<ProfileDetailPage> createState() => _ProfileDetailPageState();
}

class _ProfileDetailPageState extends State<ProfileDetailPage> {
  bool _isLoading = true;
  String? _error;
  Profile? _profile;
  double? _compatibilityScore;
  Map<String, double>? _compatibilityDetails;
  List<String> _sharedInterests = const [];
  bool _isFromDailySelection = false;
  String? _activeChatId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Profile? _findInProvider(MatchingProvider provider) {
    for (final p in provider.dailyProfiles) {
      if (p.id == widget.profileId) return p;
    }
    for (final m in provider.matches) {
      if (m.otherProfile?.id == widget.profileId) return m.otherProfile;
    }
    for (final item in provider.whoLikedMe) {
      if (item.user.id == widget.profileId) return item.user;
    }
    return null;
  }

  Match? _findMatch(MatchingProvider provider) {
    for (final m in provider.matches) {
      if (m.otherProfile?.id == widget.profileId) return m;
    }
    return null;
  }

  Future<void> _load() async {
    if (!mounted) return;
    final matchingProvider = context.read<MatchingProvider>();

    Profile? profile = _findInProvider(matchingProvider);

    // Deep link or cold start: the list that normally already carries this
    // profile hasn't been fetched yet in this session. Fetch them once
    // before concluding the profile doesn't exist.
    if (profile == null) {
      await Future.wait([
        matchingProvider.dailyProfiles.isEmpty
            ? matchingProvider.loadDailySelection()
            : Future<void>.value(),
        matchingProvider.matches.isEmpty
            ? matchingProvider.loadMatches()
            : Future<void>.value(),
        matchingProvider.whoLikedMe.isEmpty
            ? matchingProvider.loadWhoLikedMe()
            : Future<void>.value(),
      ]);
      if (!mounted) return;
      profile = _findInProvider(matchingProvider);
    }

    if (profile == null) {
      setState(() {
        _isLoading = false;
        _error = "Ce profil n'est plus disponible.";
      });
      return;
    }

    final match = _findMatch(matchingProvider);

    setState(() {
      _profile = profile;
      _compatibilityScore = profile!.compatibilityScore ?? match?.compatibilityScore;
      _compatibilityDetails = profile.compatibilityDetails;
      _sharedInterests = profile.sharedInterests;
      _isFromDailySelection =
          matchingProvider.dailyProfiles.any((p) => p.id == widget.profileId);
      _activeChatId =
          (match != null && match.status == 'active') ? match.chatId : null;
      _isLoading = false;
    });

    // No compatibility breakdown embedded yet (e.g. a "qui m'a choisi·e"
    // profile) — fetch it in the background rather than block the page.
    if (_compatibilityDetails == null) {
      final result =
          await matchingProvider.getCompatibility(widget.profileId);
      if (!mounted || result == null) return;
      setState(() {
        _compatibilityScore ??= result.score;
        _compatibilityDetails = result.categoryScores;
        if (_sharedInterests.isEmpty) {
          _sharedInterests = result.commonInterests;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _profile == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_off_outlined,
                    size: 48, color: AppColors.textSecondary),
                const SizedBox(height: AppSpacing.md),
                Text(
                  _error ?? "Ce profil n'est plus disponible.",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final profile = _profile!;
    final photos = [...profile.photos]..sort((a, b) => a.order.compareTo(b.order));
    final displayName = profile.firstName ?? profile.pseudo ?? 'Profil';
    final ageSuffix = profile.age != null ? ', ${profile.age}' : '';
    final promptCatalog = context.watch<ProfileProvider>().availablePrompts;
    final sortedPrompts = [...profile.promptAnswers]
      ..sort((a, b) => a.order.compareTo(b.order));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar with real photo(s)
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                ),
              ),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.flag,
                    color: Colors.white,
                  ),
                ),
                onPressed: () => _showReportDialog(context, profile),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (photos.isNotEmpty)
                    OptimizedImage(
                      imageUrl: photos.first.url,
                      fit: BoxFit.cover,
                      errorWidget: _photoFallback(),
                    )
                  else
                    _photoFallback(),

                  // Gradient overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Name and compatibility
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$displayName$ageSuffix',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        if (_compatibilityScore != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGold,
                              borderRadius: BorderRadius.circular(
                                  AppBorderRadius.medium),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.favorite,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  '${(_compatibilityScore! * 100).round()}% compatible',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bio section
                  _buildSection(
                    context,
                    'À propos',
                    (profile.bio == null || profile.bio!.trim().isEmpty)
                        ? "Cette personne n'a pas encore ajouté de description."
                        : profile.bio!,
                    Icons.info_outline,
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Favorite song section
                  if (profile.favoriteSong != null &&
                      profile.favoriteSong!.trim().isNotEmpty) ...[
                    _buildSection(
                      context,
                      'Morceau/Artiste préféré',
                      profile.favoriteSong!,
                      Icons.music_note,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],

                  // Compatibility breakdown
                  if (_compatibilityDetails != null ||
                      _sharedInterests.isNotEmpty) ...[
                    _buildCompatibilityBreakdown(context),
                    const SizedBox(height: AppSpacing.xl),
                  ],

                  // Prompts section
                  if (sortedPrompts.isNotEmpty) ...[
                    Text(
                      'En savoir plus',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ...sortedPrompts.map((promptAnswer) {
                      Prompt? matchingPrompt;
                      for (final p in promptCatalog) {
                        if (p.id == promptAnswer.promptId) {
                          matchingPrompt = p;
                          break;
                        }
                      }

                      return Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppSpacing.lg),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: AppColors.accentCream,
                            borderRadius: BorderRadius.circular(
                                AppBorderRadius.large),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                matchingPrompt?.text ?? 'Prompt',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(
                                      color: AppColors.primaryGold,
                                    ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                promptAnswer.answer,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: AppSpacing.xl),
                  ],

                  // Photo gallery
                  if (photos.length > 1) ...[
                    Text(
                      'Plus de photos',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: photos.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: EdgeInsets.only(
                              right: index < photos.length - 1
                                  ? AppSpacing.md
                                  : 0,
                            ),
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(AppBorderRadius.medium),
                              child: OptimizedImage(
                                imageUrl: photos[index].url,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],

                  // Media files section (Audio/Video)
                  if (profile.mediaFiles.isNotEmpty) ...[
                    Text(
                      'Médias',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ...profile.mediaFiles.map((mediaFile) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: MediaPlayerWidget(
                          mediaFile: mediaFile,
                          autoPlay: false,
                          showControls: true,
                        ),
                      );
                    }),
                    const SizedBox(height: AppSpacing.xxl),
                  ],

                  // Action buttons
                  _buildActionRow(context, profile),

                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoFallback() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primaryGold.withValues(alpha: 0.3),
            AppColors.primaryGold.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: const Icon(
        Icons.person,
        size: 120,
        color: Colors.white,
      ),
    );
  }

  Widget _buildActionRow(BuildContext context, Profile profile) {
    // Still part of today's daily selection: the usual "Choisir / Passer".
    if (_isFromDailySelection) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showSelectionDialog(context, profile),
              icon: const Icon(Icons.favorite),
              label: const Text('Choisir'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.close),
              label: const Text('Passer'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      );
    }

    // Already an active match: go straight to the (ephemeral) chat.
    if (_activeChatId != null) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => context.push('/chat/$_activeChatId'),
          icon: const Icon(Icons.chat_bubble_outline),
          label: const Text('Discuter'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      );
    }

    // Otherwise (e.g. "qui m'a choisi·e"): choosing them completes the match.
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showSelectionDialog(context, profile),
        icon: const Icon(Icons.favorite),
        label: const Text('Choisir'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildCompatibilityBreakdown(BuildContext context) {
    final details = _compatibilityDetails;
    final labels = <String, String>{
      'communication': 'Communication',
      'values': 'Valeurs',
      'lifestyle': 'Style de vie',
      'personality': 'Personnalité',
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primaryGold.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppBorderRadius.large),
        border:
            Border.all(color: AppColors.primaryGold.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights,
                  color: AppColors.primaryGold, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Compatibilité détaillée',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
          if (details != null) ...[
            const SizedBox(height: AppSpacing.md),
            ...labels.entries.map((entry) {
              final value = details[entry.key] ?? 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.value,
                            style: Theme.of(context).textTheme.bodySmall),
                        Text('${(value * 100).round()}%',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryGold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: value,
                        minHeight: 6,
                        backgroundColor: AppColors.backgroundGrey,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primaryGold),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          if (_sharedInterests.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text('Intérêts communs',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: _sharedInterests
                  .map((interest) => Chip(
                        label: Text(interest,
                            style: const TextStyle(fontSize: 12)),
                        backgroundColor:
                            AppColors.primaryGold.withValues(alpha: 0.15),
                        side: BorderSide.none,
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection(
      BuildContext context, String title, String content, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: AppColors.primaryGold,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          content,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  void _showSelectionDialog(BuildContext context, Profile profile) {
    final displayName = profile.firstName ?? profile.pseudo ?? 'cette personne';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.large),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.favorite,
                color: AppColors.primaryGold,
              ),
              SizedBox(width: AppSpacing.sm),
              Text('Confirmer votre choix'),
            ],
          ),
          content: Text(
            'Voulez-vous vraiment choisir $displayName ? Cette action terminera votre sélection du jour.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _selectProfile(context, profile);
              },
              child: const Text('Confirmer'),
            ),
          ],
        );
      },
    );
  }

  void _selectProfile(BuildContext context, Profile profile) {
    final matchingProvider =
        Provider.of<MatchingProvider>(context, listen: false);
    final displayName = profile.firstName ?? profile.pseudo ?? 'ce profil';

    matchingProvider.selectProfile(profile.id);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Vous avez choisi $displayName ! Revenez demain pour votre nouvelle sélection.'),
        backgroundColor: AppColors.successGreen,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            context.go('/home');
          },
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted) {
        context.go('/home');
      }
    });
  }

  void _showReportDialog(BuildContext context, Profile profile) {
    showDialog(
      context: context,
      builder: (context) => ReportDialog(
        targetUserId: profile.userId,
        targetUserName: profile.firstName ?? profile.pseudo,
      ),
    );
  }
}
