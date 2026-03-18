import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/social_post.dart';
import '../providers/auth_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/social_feed_provider.dart';
import '../services/social_story_export_service.dart';
import '../theme/app_density.dart';
import '../widgets/bottom_nav_bar.dart';

class SocialPage extends StatelessWidget {
  const SocialPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SocialScaffold();
  }
}

class _SocialScaffold extends StatefulWidget {
  const _SocialScaffold();

  @override
  State<_SocialScaffold> createState() => _SocialScaffoldState();
}

class _SocialScaffoldState extends State<_SocialScaffold> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<NavigationProvider>().setIndex(2);
      context.read<SocialFeedProvider>().ensureLoaded();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final feed = context.watch<SocialFeedProvider>().posts;
    final isClient = auth.isClient;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(isClient ? 'My Workout Stories' : 'Social')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colors.primary.withOpacity(0.06),
              colors.surfaceContainerLowest,
              colors.surfaceContainerLowest,
            ],
          ),
        ),
        child: feed.isEmpty
            ? _EmptySocialState(isClient: isClient)
            : ListView(
                controller: _scrollController,
                padding: EdgeInsets.fromLTRB(
                  AppDensity.space(12),
                  AppDensity.space(12),
                  AppDensity.space(12),
                  AppDensity.space(20),
                ),
                children: [
                  _SocialIntroCard(isClient: isClient),
                  SizedBox(height: AppDensity.space(14)),
                  ...feed.map(
                    (post) => Padding(
                      padding: EdgeInsets.only(bottom: AppDensity.space(14)),
                      child: _SocialPostCard(post: post),
                    ),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}

class _EmptySocialState extends StatelessWidget {
  const _EmptySocialState({required this.isClient});

  final bool isClient;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: AppDensity.all(20),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: AppDensity.all(20),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: AppDensity.circular(24),
            border: Border.all(color: colors.outlineVariant.withOpacity(0.32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      colors.primary.withOpacity(0.18),
                      colors.secondary.withOpacity(0.12),
                    ],
                  ),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: colors.primary,
                ),
              ),
              SizedBox(height: AppDensity.space(12)),
              Text(
                'No social cards yet',
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              SizedBox(height: AppDensity.space(8)),
              Text(
                isClient
                    ? 'Finish a workout and you will get a compact export card you can save as PNG and share.'
                    : 'Completed sessions will appear here with compact export cards ready for social sharing.',
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialIntroCard extends StatelessWidget {
  const _SocialIntroCard({required this.isClient});

  final bool isClient;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: AppDensity.all(16),
      decoration: BoxDecoration(
        borderRadius: AppDensity.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primary.withOpacity(0.12),
            colors.tertiary.withOpacity(0.08),
            colors.surface,
          ],
        ),
        border: Border.all(color: colors.outlineVariant.withOpacity(0.28)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: colors.primary.withOpacity(0.14),
            ),
            child: Icon(
              Icons.ios_share_rounded,
              color: colors.primary,
              size: 20,
            ),
          ),
          SizedBox(width: AppDensity.space(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isClient ? 'Export your workout card' : 'Export session cards',
                  style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                SizedBox(height: AppDensity.space(4)),
                Text(
                  'Each card is compact, gradient-based, and ready to save as a PNG for stories or posts.',
                  style: text.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialPostCard extends StatefulWidget {
  const _SocialPostCard({required this.post});

  final SocialPost post;

  @override
  State<_SocialPostCard> createState() => _SocialPostCardState();
}

class _SocialPostCardState extends State<_SocialPostCard> {
  final GlobalKey _captureKey = GlobalKey();
  final SocialStoryExportService _exportService = SocialStoryExportService();
  bool _exporting = false;

  Future<void> _export(BuildContext shareContext) async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final boundary = _captureKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();
      final safeName = widget.post.workoutTitle
          .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
          .replaceAll(RegExp(r'_+'), '_')
          .replaceAll(RegExp(r'^_|_$'), '');
      final shareBox = shareContext.findRenderObject() as RenderBox?;
      final shareOrigin = shareBox != null && shareBox.hasSize
          ? shareBox.localToGlobal(Offset.zero) & shareBox.size
          : null;
      await _exportService.exportPng(
        bytes: bytes,
        fileName:
            '${safeName.isEmpty ? 'workout_story' : safeName}_${widget.post.id}',
        sharePositionOrigin: shareOrigin,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Theme.of(context).platform == TargetPlatform.android ||
                    Theme.of(context).platform == TargetPlatform.iOS
                ? 'PNG ready to share'
                : 'PNG downloaded',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final post = widget.post;

    return Container(
      padding: AppDensity.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppDensity.circular(24),
        border: Border.all(color: colors.outlineVariant.withOpacity(0.28)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _MetaPill(
                icon: Icons.calendar_today_rounded,
                label: DateFormat('d MMM').format(post.completedAt.toLocal()),
              ),
              _MetaPill(
                icon: Icons.fitness_center_rounded,
                label: '${post.totalWeightLifted.toStringAsFixed(0)} kg',
              ),
              _MetaPill(
                icon: Icons.timer_outlined,
                label: _formatDuration(post.durationSeconds),
              ),
            ],
          ),
          SizedBox(height: AppDensity.space(12)),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 260),
              child: RepaintBoundary(
                key: _captureKey,
                child: _CompactStoryCard(post: post),
              ),
            ),
          ),
          SizedBox(height: AppDensity.space(12)),
          Text(
            post.workoutTitle,
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          SizedBox(height: AppDensity.space(4)),
          Text(
            post.ownerRole == 'CLIENT'
                ? 'Compact PNG card for your completed workout.'
                : 'Compact PNG card for sharing this completed session.',
            style: text.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: AppDensity.space(12)),
          SizedBox(
            width: double.infinity,
            child: Builder(
              builder: (buttonContext) => FilledButton.icon(
                onPressed: _exporting ? null : () => _export(buttonContext),
                icon: Icon(
                  _exporting ? Icons.hourglass_top : Icons.download_rounded,
                ),
                label: Text(_exporting ? 'Exporting PNG...' : 'Export PNG'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}m ${remainingSeconds.toString().padLeft(2, '0')}s';
  }
}

class _CompactStoryCard extends StatelessWidget {
  const _CompactStoryCard({required this.post});

  final SocialPost post;

  bool get _showLeaderboard =>
      post.leaderboard.isNotEmpty && post.participantCount > 1;

  List<Color> _gradient() {
    if (post.ownerRole == 'CLIENT') {
      return const [
        Color(0xFF131A3C),
        Color(0xFF224D8F),
        Color(0xFFFF8A5B),
      ];
    }
    return const [
      Color(0xFF082032),
      Color(0xFF2C74B3),
      Color(0xFFFFC857),
    ];
  }

  String _heroLabel() {
    if (post.ownerRole == 'CLIENT') {
      return post.rank != null ? 'Finished #${post.rank}' : 'Workout complete';
    }
    return 'Session recap';
  }

  String _subhead() {
    if (post.ownerRole == 'CLIENT') {
      return post.clientSummary.isNotEmpty
          ? post.clientSummary
          : 'Personal workout summary';
    }
    return '${post.participantCount} athletes · ${post.clientSummary}';
  }

  String _bestMetric() {
    if (post.bestSetKg > 0 && post.bestSetReps > 0) {
      return '${post.bestSetKg.toStringAsFixed(0)} kg x ${post.bestSetReps}';
    }
    return '${post.totalWeightLifted.toStringAsFixed(0)} kg total';
  }

  SocialPerformanceHighlight? get _primaryHighlight {
    return post.bestVolumeHighlight ??
        post.heaviestHighlight ??
        post.bestRepsHighlight;
  }

  @override
  Widget build(BuildContext context) {
    final primaryHighlight = _primaryHighlight;

    return AspectRatio(
      aspectRatio: 0.72,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _gradient(),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x29000000),
              blurRadius: 22,
              offset: Offset(0, 14),
            ),
          ],
        ),
        child: Stack(
          children: [
            const Positioned(
              top: -26,
              right: -18,
              child: _GlowOrb(size: 110),
            ),
            const Positioned(
              bottom: -30,
              left: -24,
              child: _GlowOrb(size: 120),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: Colors.white.withOpacity(0.15),
                      ),
                      child: Text(
                        _heroLabel(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      post.ownerRole == 'CLIENT'
                          ? Icons.bolt_rounded
                          : Icons.groups_rounded,
                      size: 18,
                      color: Colors.white.withOpacity(0.92),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  post.workoutTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    height: 0.98,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _subhead(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.82),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                _CompactMetricPanel(post: post, bestMetric: _bestMetric()),
                const SizedBox(height: 8),
                if (primaryHighlight != null)
                  _MiniHighlight(highlight: primaryHighlight)
                else
                  _CompactSummary(post: post),
                const Spacer(),
                if (_showLeaderboard)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _LeaderboardSnippet(entry: post.leaderboard.first),
                  ),
                Row(
                  children: [
                    Icon(
                      Icons.ios_share_rounded,
                      size: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Export as PNG',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.78),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      DateFormat('d MMM').format(post.completedAt.toLocal()),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.72),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactMetricPanel extends StatelessWidget {
  const _CompactMetricPanel({
    required this.post,
    required this.bestMetric,
  });

  final SocialPost post;
  final String bestMetric;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withOpacity(0.1),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _MetricStat(
                  label: 'Total',
                  value: '${post.totalWeightLifted.toStringAsFixed(0)} kg',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricStat(
                  label: 'Time',
                  value: _formatDuration(post.durationSeconds),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _MetricStat(
                  label: 'Exercises',
                  value: '${post.exerciseCount}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricStat(
                  label: 'Best set',
                  value: bestMetric,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}m ${remainingSeconds.toString().padLeft(2, '0')}s';
  }
}

class _MetricStat extends StatelessWidget {
  const _MetricStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withOpacity(0.08),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.68),
              fontWeight: FontWeight.w700,
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniHighlight extends StatelessWidget {
  const _MiniHighlight({required this.highlight});

  final SocialPerformanceHighlight highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.black.withOpacity(0.14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  highlight.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.72),
                    fontWeight: FontWeight.w700,
                    fontSize: 9,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                highlight.value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            highlight.detail,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.88),
              fontWeight: FontWeight.w600,
              fontSize: 10,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactSummary extends StatelessWidget {
  const _CompactSummary({required this.post});

  final SocialPost post;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.black.withOpacity(0.14),
      ),
      child: Row(
        children: [
          Icon(
            Icons.insights_rounded,
            size: 16,
            color: Colors.white.withOpacity(0.9),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${post.completedSetCount}/${post.totalSetCount} sets completed · ${post.sessionTotalWeightLifted.toStringAsFixed(0)} kg session total',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(0.86),
                fontWeight: FontWeight.w700,
                fontSize: 10,
                height: 1.15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardSnippet extends StatelessWidget {
  const _LeaderboardSnippet({required this.entry});

  final SocialLeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.09),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.14),
            ),
            child: const Text(
              '1',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              entry.clientName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${entry.totalWeightLifted.toStringAsFixed(0)} kg',
            style: TextStyle(
              color: Colors.white.withOpacity(0.94),
              fontWeight: FontWeight.w900,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: colors.surfaceContainerHighest.withOpacity(0.55),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colors.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: colors.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.08),
      ),
    );
  }
}
