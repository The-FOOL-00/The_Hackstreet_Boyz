/// Caregiver Dashboard Screen
///
/// A monitoring dashboard for family members/caregivers to track
/// an elderly user's daily cognitive and routine progress.
///
/// Design: Medical-tech aesthetic with soft whites, slate grays, and teal accents.
library;

import 'package:flutter/material.dart';
import '../services/caregiver_mock_data.dart';

class CaregiverDashboardScreen extends StatefulWidget {
  const CaregiverDashboardScreen({super.key});

  @override
  State<CaregiverDashboardScreen> createState() => _CaregiverDashboardScreenState();
}

class _CaregiverDashboardScreenState extends State<CaregiverDashboardScreen> {
  // Mock data
  late SeniorProfile _senior;
  late List<RoutinePeriod> _routinePeriods;
  late List<GameMetric> _gameMetrics;
  late List<ActivityLog> _activityLog;
  late List<String> _insights;

  @override
  void initState() {
    super.initState();
    _loadMockData();
  }

  void _loadMockData() {
    _senior = MockCaregiverData.getSeniorProfile();
    _routinePeriods = MockCaregiverData.getRoutinePeriods();
    _gameMetrics = MockCaregiverData.getGameMetrics();
    _activityLog = MockCaregiverData.getActivityLog();
    _insights = MockCaregiverData.getWellnessInsights();
  }

  void _makePhoneCall() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📞 Calling Grandpa Joe...'),
        backgroundColor: Color(0xFF0D9488),
      ),
    );
  }

  void _openChat() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('💬 Chat feature coming soon!'),
        backgroundColor: Color(0xFF0D9488),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Soft white background
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => _loadMockData());
        },
        color: const Color(0xFF0D9488),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Senior Status Card
                _buildSeniorStatusCard(),
                const SizedBox(height: 20),

                // Routine Overview
                _buildSectionHeader('Today\'s Routine', Icons.calendar_today_rounded),
                const SizedBox(height: 12),
                _buildRoutineSummary(),
                const SizedBox(height: 24),

                // Cognitive Insights
                _buildSectionHeader('Cognitive Insights', Icons.psychology_rounded),
                const SizedBox(height: 12),
                _buildCognitiveStatsGrid(),
                const SizedBox(height: 24),

                // Wellness Insights
                _buildSectionHeader('Quick Insights', Icons.lightbulb_rounded),
                const SizedBox(height: 12),
                _buildInsightsCard(),
                const SizedBox(height: 24),

                // Recent Activity
                _buildSectionHeader('Recent Activity', Icons.history_rounded),
                const SizedBox(height: 12),
                _buildActivityTimeline(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF0D9488), // Teal
      foregroundColor: Colors.white,
      elevation: 0,
      title: const Text(
        'Care Dashboard',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 20,
          letterSpacing: 0.5,
        ),
      ),
      actions: [
        // Chat button
        IconButton(
          onPressed: _openChat,
          icon: const Icon(Icons.chat_bubble_rounded),
          tooltip: 'Chat',
        ),
        // Call button
        IconButton(
          onPressed: _makePhoneCall,
          icon: const Icon(Icons.phone_rounded),
          tooltip: 'Call',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSeniorStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0D9488), // Teal
            Color(0xFF0F766E), // Darker teal
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D9488).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar with pulse indicator
          Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    '👴',
                    style: TextStyle(fontSize: 40),
                  ),
                ),
              ),
              // Online pulse indicator
              if (_senior.isOnline)
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: _buildPulsingDot(),
                ),
            ],
          ),
          const SizedBox(width: 16),
          
          // Info section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _senior.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _senior.mood,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _senior.isOnline 
                            ? const Color(0xFF4ADE80) 
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _senior.isOnline 
                          ? 'Online • ${_senior.lastActive}'
                          : 'Last seen ${_senior.lastActive}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Wellness Score
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.favorite_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Wellness Score: ${_senior.wellnessScore}/100',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
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
    );
  }

  Widget _buildPulsingDot() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: 1.4),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeInOut,
      builder: (context, scale, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer pulse
            Transform.scale(
              scale: scale,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF4ADE80).withOpacity(0.3),
                ),
              ),
            ),
            // Inner dot
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF4ADE80),
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ],
        );
      },
      onEnd: () => setState(() {}), // Trigger rebuild to repeat animation
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF0D9488).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF0D9488),
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildRoutineSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _routinePeriods.map((period) {
          return _buildRoutinePeriodIndicator(period);
        }).toList(),
      ),
    );
  }

  Widget _buildRoutinePeriodIndicator(RoutinePeriod period) {
    return Column(
      children: [
        // Circular progress
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                value: period.completion,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation<Color>(period.statusColor),
                strokeWidth: 5,
                strokeCap: StrokeCap.round,
              ),
            ),
            Icon(
              period.statusIcon,
              color: period.statusColor,
              size: 24,
            ),
            if (period.needsAttention)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.priority_high_rounded,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          period.period,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),
        Text(
          '${period.completedTasks}/${period.totalTasks}',
          style: TextStyle(
            fontSize: 12,
            color: period.statusColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCognitiveStatsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemCount: _gameMetrics.length,
      itemBuilder: (context, index) {
        return _buildGameMetricCard(_gameMetrics[index]);
      },
    );
  }

  Widget _buildGameMetricCard(GameMetric metric) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  metric.icon,
                  color: const Color(0xFF0D9488),
                  size: 18,
                ),
              ),
              const Spacer(),
              Icon(
                metric.trendIcon,
                color: metric.trendColor,
                size: 20,
              ),
            ],
          ),
          const Spacer(),
          Text(
            metric.gameName,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            metric.score,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          if (metric.reactionTime != null)
            Text(
              '⚡ ${metric.reactionTime}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF94A3B8),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInsightsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDFA), // Very light teal
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF99F6E4),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _insights.map((insight) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              insight,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF0F766E),
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActivityTimeline() {
    // Sort by timestamp descending (most recent first)
    final sortedLogs = List<ActivityLog>.from(_activityLog)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: sortedLogs.length,
        separatorBuilder: (context, index) => const Divider(
          height: 1,
          indent: 70,
        ),
        itemBuilder: (context, index) {
          final log = sortedLogs[index];
          return _buildActivityLogTile(log);
        },
      ),
    );
  }

  Widget _buildActivityLogTile(ActivityLog log) {
    final isAlert = log.type == 'alert';
    
    return Container(
      color: isAlert ? const Color(0xFFFEF2F2) : null, // Soft red for alerts
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: log.backgroundColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            log.icon,
            color: log.backgroundColor,
            size: 22,
          ),
        ),
        title: Text(
          log.event,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isAlert ? FontWeight.w600 : FontWeight.w500,
            color: isAlert ? const Color(0xFFDC2626) : const Color(0xFF1E293B),
          ),
        ),
        trailing: Text(
          log.time,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF94A3B8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
