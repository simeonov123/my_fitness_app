import 'dart:typed_data';
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

    return Scaffold(
      appBar: AppBar(title: Text(isClient ? 'My Workout Stories' : 'Social')),
      body: feed.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  isClient
                      ? 'Your completed workout stories will appear here after you finish or open a completed session.'
                      : 'Completed workout stories you create will appear here.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.separated(
              controller: _scrollController,
              primary: false,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              itemCount: feed.length,
              separatorBuilder: (_, __) => const SizedBox(height: 24),
              itemBuilder: (_, index) => _SocialPostCard(post: feed[index]),
            ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}

class _SocialPostCard extends StatefulWidget {
  final SocialPost post;

  const _SocialPostCard({required this.post});

  @override
  State<_SocialPostCard> createState() => _SocialPostCardState();
}

class _SocialPostCardState extends State<_SocialPostCard> {
  final GlobalKey _captureKey = GlobalKey();
  final SocialStoryExportService _exportService = SocialStoryExportService();
  bool _exporting = false;

  Future<void> _export() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final boundary =
          _captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();
      final safeName = widget.post.workoutTitle
          .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
          .replaceAll(RegExp(r'_+'), '_')
          .replaceAll(RegExp(r'^_|_$'), '');
      await _exportService.exportPng(
        bytes: bytes,
        fileName: '${safeName.isEmpty ? 'workout_story' : safeName}_${widget.post.id}',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Theme.of(context).platform == TargetPlatform.android ||
                      Theme.of(context).platform == TargetPlatform.iOS
                  ? 'Story image ready to share'
                  : 'Story image downloaded',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RepaintBoundary(
          key: _captureKey,
          child: _StoryWorkoutCard(post: widget.post),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _exporting ? null : _export,
                icon: Icon(_exporting ? Icons.hourglass_top : Icons.ios_share),
                label: Text(_exporting ? 'Exporting...' : 'Export story'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StoryWorkoutCard extends StatelessWidget {
  final SocialPost post;

  const _StoryWorkoutCard({required this.post});

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}m ${remainingSeconds.toString().padLeft(2, '0')}s';
  }

  String _formatDate(DateTime date) {
    return DateFormat('d MMM yyyy • HH:mm').format(date.toLocal());
  }

  String _headline() {
    if (post.ownerRole == 'CLIENT') {
      return post.rank != null
          ? 'You finished #${post.rank}'
          : 'You finished strong';
    }
    return 'Session complete';
  }

  String _subhead() {
    if (post.ownerRole == 'CLIENT') {
      return post.clientSummary.isNotEmpty
          ? post.clientSummary
          : 'Your personal workout recap';
    }
    return '${post.participantCount} athletes • ${post.clientSummary}';
  }

  bool get _showLeaderboard =>
      post.leaderboard.isNotEmpty && post.participantCount > 1;

  List<Color> _gradient() {
    if (post.ownerRole == 'CLIENT') {
      return const [Color(0xFF0B132B), Color(0xFF1C2541), Color(0xFFF25F5C)];
    }
    return const [Color(0xFF032B43), Color(0xFF3F88C5), Color(0xFFF6AE2D)];
  }

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatTile(label: 'Lifted', value: '${post.totalWeightLifted.toStringAsFixed(0)} kg'),
      _StatTile(label: 'Duration', value: _formatDuration(post.durationSeconds)),
      _StatTile(label: 'Exercises', value: '${post.exerciseCount}'),
      _StatTile(label: 'Sets', value: '${post.completedSetCount}/${post.totalSetCount}'),
    ];
    final highlights = [
      post.bestVolumeHighlight,
      post.heaviestHighlight,
      post.bestRepsHighlight,
    ].whereType<SocialPerformanceHighlight>().toList(growable: false);

    return AspectRatio(
      aspectRatio: 9 / 16,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: LinearGradient(
            colors: _gradient(),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 24,
              offset: Offset(0, 16),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -40,
              right: -10,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -70,
              left: -30,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: Colors.white.withValues(alpha: 0.14),
                        ),
                        child: Text(
                          _headline(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        post.ownerRole == 'CLIENT'
                            ? Icons.auto_awesome
                            : Icons.groups_rounded,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text(
                    post.workoutTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _subhead(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.84),
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Coach ${post.trainerName} • ${_formatDate(post.completedAt)}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.68),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.ownerRole == 'CLIENT'
                              ? 'Your workout snapshot'
                              : 'Session snapshot',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 2.2,
                          children: cards,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (post.ownerRole == 'CLIENT' && post.rank != null) ...[
                    _InsightStrip(
                      label: 'Rank',
                      value: '#${post.rank}',
                    ),
                    const SizedBox(height: 8),
                  ],
                  _InsightStrip(
                    label: post.ownerRole == 'CLIENT'
                        ? 'Session total'
                        : 'Crew total',
                    value:
                        '${post.sessionTotalWeightLifted.toStringAsFixed(0)} kg',
                  ),
                  if (highlights.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Performance highlights',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...highlights.map(
                      (highlight) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _HighlightCard(highlight: highlight),
                      ),
                    ),
                  ],
                  if (_showLeaderboard) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Top performers',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...post.leaderboard.take(2).toList().asMap().entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    color: Colors.white.withValues(alpha: 0.14),
                                  ),
                                  child: Text(
                                    '${entry.key + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    entry.value.clientName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    '${entry.value.totalWeightLifted.toStringAsFixed(0)} kg',
                                    maxLines: 1,
                                    textAlign: TextAlign.right,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.95),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ],
                  const Spacer(),
                  Row(
                    children: [
                      Icon(
                        Icons.camera_outlined,
                        color: Colors.white.withValues(alpha: 0.82),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Built to share as a story',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;

  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;

  const _MiniMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.08),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.68),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  final SocialPerformanceHighlight highlight;

  const _HighlightCard({required this.highlight});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.08),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: 4,
            spacing: 8,
            children: [
              Text(
                highlight.label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
              Text(
                highlight.value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            highlight.detail,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            softWrap: true,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.86),
              fontWeight: FontWeight.w600,
              height: 1.25,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightStrip extends StatelessWidget {
  final String label;
  final String value;

  const _InsightStrip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.black.withValues(alpha: 0.14),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runSpacing: 4,
        spacing: 8,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
