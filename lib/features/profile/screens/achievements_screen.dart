import 'package:flutter/material.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF864AFF),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFE5D9F2),
                    Color(0xFFD6C3FF),
                    Color(0xFFA573FF),
                    Color(0xFF8841FF),
                  ],
                  stops: [0.0, 0.3, 0.7, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Color(0xFF38106A),
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'Achievements',
                        style: TextStyle(
                          color: Color(0xFF280A54),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 8.0,
                    ),
                    children: [
                      _buildAchievementCard(
                        'Fluency Pro',
                        'Attend 20 Live Speaking Workshops.',
                        12,
                        20,
                        '500 XP',
                        const Color(0xFF8841FF),
                      ),
                      const SizedBox(height: 12),
                      _buildAchievementCard(
                        'Perfect Score',
                        'Get 100% on any 5 Grammar Quizzes.',
                        2,
                        5,
                        '200 XP',
                        const Color(0xFF8841FF),
                      ),
                      const SizedBox(height: 12),
                      _buildAchievementCard(
                        'Early Bird',
                        'Complete a lesson before 8 AM.',
                        1,
                        1,
                        '100 XP',
                        const Color(0xFF8841FF),
                      ),
                      const SizedBox(height: 12),
                      _buildAchievementCard(
                        'Consistent Learner',
                        'Study for 7 consecutive days.',
                        4,
                        7,
                        '300 XP',
                        const Color(0xFF8841FF),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(
    String title,
    String subtitle,
    int progress,
    int total,
    String xp,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.military_tech,
              color: const Color(0xFF8841FF),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Color(0xFF280A54),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.5),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.emoji_events,
                            size: 12,
                            color: const Color(0xFF5E27B6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            xp,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF5E27B6),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF38106A).withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress / total,
                          backgroundColor: Colors.white.withValues(alpha: 0.4),
                          valueColor: const AlwaysStoppedAnimation(
                            Color(0xFF8841FF),
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$progress/$total',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF5E27B6),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
