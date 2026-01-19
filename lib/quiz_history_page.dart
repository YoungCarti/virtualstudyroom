import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class QuizHistoryPage extends StatefulWidget {
  const QuizHistoryPage({super.key});

  @override
  State<QuizHistoryPage> createState() => _QuizHistoryPageState();
}

class _QuizHistoryPageState extends State<QuizHistoryPage> {
  // Theme Colors
  final Color _deepNavy = const Color(0xFF0F172A);
  final Color _midnightBlue = const Color(0xFF1E293B);
  final Color _pureWhite = const Color(0xFFFFFFFF);
  final Color _purpleAccent = const Color(0xFF6366F1);
  final Color _mintGreen = const Color(0xFF10B981);
  final Color _softOrange = const Color(0xFFF59E0B);
  final Color _electricBlue = const Color(0xFF3B82F6);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: _deepNavy,
        body: Center(
          child: Text('Please log in to view history', style: GoogleFonts.outfit(color: _pureWhite)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _deepNavy,
      appBar: AppBar(
        title: Text('Quiz History', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _pureWhite,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('quiz_results')
            .where('userId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .limit(50) // Limit to last 50 for performance
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: GoogleFonts.outfit(color: Colors.red)));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_edu, size: 80, color: _pureWhite.withOpacity(0.2)),
                  const SizedBox(height: 16),
                  Text(
                    'No quiz history yet',
                    style: GoogleFonts.outfit(color: _pureWhite.withOpacity(0.5), fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Take a quiz to see your progress!',
                    style: GoogleFonts.outfit(color: _pureWhite.withOpacity(0.3)),
                  ),
                ],
              ),
            );
          }

          // Calculate Stats
          final totalQuizzes = docs.length;
          double totalScore = 0;
          for (var doc in docs) {
            totalScore += (doc['percentage'] as num?)?.toDouble() ?? 0;
          }
          final avgScore = totalQuizzes > 0 ? (totalScore / totalQuizzes).round() : 0;
          
          // Prepare Chart Data (Last 10 quizzes, chronological)
          final chartData = docs.take(10).toList().reversed.toList();
          final spots = chartData.asMap().entries.map((e) {
            final percentage = (e.value['percentage'] as num?)?.toDouble() ?? 0;
            return FlSpot(e.key.toDouble(), percentage);
          }).toList();

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Stats Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Total Quizzes',
                              totalQuizzes.toString(),
                              Icons.fact_check,
                              _electricBlue,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              'Avg. Score',
                              '$avgScore%',
                              Icons.analytics,
                              avgScore >= 70 ? _mintGreen : _softOrange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (spots.length > 1) ...[
                        Text(
                          'Performance Trend (Last 10)',
                          style: GoogleFonts.outfit(
                            color: _pureWhite.withOpacity(0.7),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 200,
                          padding: const EdgeInsets.only(right: 16, top: 16),
                          decoration: BoxDecoration(
                            color: _midnightBlue,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _pureWhite.withOpacity(0.1)),
                          ),
                          child: LineChart(
                            LineChartData(
                              gridData: FlGridData(show: false),
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 30,
                                    getTitlesWidget: (value, meta) {
                                      if (value % 25 == 0) {
                                        return Text(
                                          value.toInt().toString(),
                                          style: GoogleFonts.outfit(
                                            color: _pureWhite.withOpacity(0.5),
                                            fontSize: 10,
                                          ),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                ),
                                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              borderData: FlBorderData(show: false),
                              minX: 0,
                              maxX: (spots.length - 1).toDouble(),
                              minY: 0,
                              maxY: 100,
                              lineBarsData: [
                                LineChartBarData(
                                  spots: spots,
                                  isCurved: true,
                                  color: _purpleAccent,
                                  barWidth: 3,
                                  isStrokeCapRound: true,
                                  dotData: FlDotData(show: true),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: _purpleAccent.withOpacity(0.2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Recent List Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    'History',
                    style: GoogleFonts.outfit(
                      color: _pureWhite,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // History List
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final title = data['quizTitle'] ?? 'Untitled Quiz';
                    final score = data['score'] ?? 0;
                    final total = data['totalQuestions'] ?? 0;
                    final percent = data['percentage'] ?? 0;
                    final date = (data['createdAt'] as Timestamp?)?.toDate();
                    final dateStr = date != null 
                        ? DateFormat('MMM d, y • h:mm a').format(date) 
                        : 'Unknown Date';

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _midnightBlue,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _pureWhite.withOpacity(0.05)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: _getScoreColor(percent).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                '$percent%',
                                style: GoogleFonts.outfit(
                                  color: _getScoreColor(percent),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: GoogleFonts.outfit(
                                    color: _pureWhite,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$score/$total correct • $dateStr',
                                  style: GoogleFonts.outfit(
                                    color: _pureWhite.withOpacity(0.5),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: docs.length,
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
            ],
          );
        },
      ),
    );
  }

  Color _getScoreColor(num percent) {
    if (percent >= 80) return _mintGreen;
    if (percent >= 60) return _softOrange;
    return const Color(0xFFEF4444); // Red
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _midnightBlue,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: _pureWhite.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: _pureWhite,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
