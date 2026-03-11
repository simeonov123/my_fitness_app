import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/social_post.dart';
import '../providers/navigation_provider.dart';
import '../providers/social_feed_provider.dart';
import '../widgets/bottom_nav_bar.dart';

class SocialPage extends StatelessWidget {
  const SocialPage({super.key});

  @override
  Widget build(BuildContext context) {
    context.read<NavigationProvider>().setIndex(2);
    return const _SocialScaffold();
  }
}

class _SocialScaffold extends StatefulWidget {
  const _SocialScaffold();

  @override
  State<_SocialScaffold> createState() => _SocialScaffoldState();
}

class _SocialScaffoldState extends State<_SocialScaffold> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SocialFeedProvider>().ensureLoaded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final feed = context.watch<SocialFeedProvider>().posts;
    return Scaffold(
      appBar: AppBar(title: const Text('Social')),
      body: feed.isEmpty
          ? const Center(
              child: Text('Completed workouts you share will appear here.'),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: feed.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, index) => _SocialPostCard(post: feed[index]),
            ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}

class _SocialPostCard extends StatelessWidget {
  final SocialPost post;

  const _SocialPostCard({required this.post});

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}m ${remainingSeconds.toString().padLeft(2, '0')}s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF1D976C), Color(0xFF93F9B9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              post.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              post.workoutTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _pill('Trainer: ${post.trainerName}'),
                _pill(post.clientSummary),
                _pill('${post.totalWeightLifted.toStringAsFixed(0)} kg lifted'),
                _pill(_formatDuration(post.durationSeconds)),
                _pill('${post.exerciseCount} exercises'),
              ],
            ),
            if (post.leaderboard.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text(
                'Leaderboard',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              ...post.leaderboard.take(3).toList().asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '#${entry.key + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              entry.value.clientName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '${entry.value.totalWeightLifted.toStringAsFixed(0)} kg',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
            const SizedBox(height: 12),
            Text(
              'Completed on ${post.completedAt.toLocal()}',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
