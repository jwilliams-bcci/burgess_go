import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'stats_controller.dart';
import '../../../core/models/inspection/inspection.dart';
import 'community_detail_screen.dart';
import '../../dialogs/ai_chat_dialog.dart';

class AreaManagerDashboard extends ConsumerStatefulWidget {
  final List<Inspection> inspections;

  const AreaManagerDashboard({super.key, required this.inspections});

  @override
  ConsumerState<AreaManagerDashboard> createState() =>
      _AreaManagerDashboardState();
}

class _AreaManagerDashboardState extends ConsumerState<AreaManagerDashboard> {
  // Track selected range (Default to This Month for relevance)
  DateRange _selectedRange = DateRange.thisMonth;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  @override
  void didUpdateWidget(covariant AreaManagerDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.inspections != widget.inspections) {
      _calculate();
    }
  }

  void _calculate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(statsProvider.notifier)
          .calculateStats(widget.inspections, _selectedRange);
    });
  }

  void _onRangeChanged(DateRange newRange) {
    setState(() {
      _selectedRange = newRange;
    });
    _calculate();
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(statsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error: $err")),
        data: (stats) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 0. DATE FILTER ROW (NEW)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip("This Week", DateRange.thisWeek),
                      const SizedBox(width: 8),
                      _buildFilterChip("This Month", DateRange.thisMonth),
                      const SizedBox(width: 8),
                      _buildFilterChip("Last 90 Days", DateRange.last90Days),
                      const SizedBox(width: 8),
                      _buildFilterChip("All Time", DateRange.allTime),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 1. KPI ROW
                Row(
                  children: [
                    _buildKpiCard(
                      "Pass Rate",
                      "${stats.passRate.toStringAsFixed(1)}%",
                      stats.passRate >= 85 ? Colors.green : Colors.red,
                    ),
                    _buildKpiCard(
                      "Total Jobs",
                      "${stats.totalInspections}",
                      Colors.blue,
                    ),
                    _buildKpiCard("Failed", "${stats.failedCount}", Colors.red),
                  ],
                ),

                const SizedBox(height: 24),

                // 2. PIE CHART SECTION
                Container(
                  height: 340,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Resolution Breakdown",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: PieChart(
                          PieChartData(
                            sections: _buildPieSections(stats),
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 16,
                        children: [
                          _LegendItem(color: Colors.green, label: "Pass"),
                          _LegendItem(color: Colors.red, label: "Fail"),
                          _LegendItem(color: Colors.orange, label: "Cancel"),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 3. SUPERINTENDENT SCORECARD
                const Text(
                  "Superintendent Scorecard",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                Container(
                  height: 350,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _LegendItem(color: Colors.green, label: "Pass"),
                          SizedBox(width: 12),
                          _LegendItem(color: Colors.red, label: "Fail"),
                          SizedBox(width: 12),
                          _LegendItem(color: Colors.orange, label: "Cancel"),
                        ],
                      ),
                      const SizedBox(height: 20),

                      Expanded(
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: _getMaxY(stats.superintendentStats),
                            barTouchData: BarTouchData(
                              enabled: true,
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipItem:
                                    (group, groupIndex, rod, rodIndex) {
                                      final superName = stats
                                          .superintendentStats[group.x.toInt()]
                                          .name;
                                      String type = "";
                                      if (rodIndex == 0) type = "Pass";
                                      if (rodIndex == 1) type = "Fail";
                                      if (rodIndex == 2) type = "Cancel";
                                      return BarTooltipItem(
                                        "$superName\n$type: ${rod.toY.toInt()}",
                                        const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      );
                                    },
                              ),
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget:
                                      (double value, TitleMeta meta) {
                                        if (value.toInt() >=
                                            stats.superintendentStats.length)
                                          return const SizedBox();
                                        final fullName = stats
                                            .superintendentStats[value.toInt()]
                                            .name;
                                        final initials = fullName
                                            .split(" ")
                                            .take(2)
                                            .map(
                                              (e) => e.isNotEmpty ? e[0] : "",
                                            )
                                            .join();
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8.0,
                                          ),
                                          child: Text(
                                            initials.toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        );
                                      },
                                ),
                              ),
                              leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                            barGroups: stats.superintendentStats
                                .asMap()
                                .entries
                                .map((entry) {
                                  final index = entry.key;
                                  final s = entry.value;
                                  return BarChartGroupData(
                                    x: index,
                                    barRods: [
                                      BarChartRodData(
                                        toY: s.total.toDouble(),
                                        width: 16,
                                        color: Colors.transparent,
                                        rodStackItems: [
                                          BarChartRodStackItem(
                                            0,
                                            s.passed.toDouble(),
                                            Colors.green,
                                          ),
                                          BarChartRodStackItem(
                                            s.passed.toDouble(),
                                            (s.passed + s.failed).toDouble(),
                                            Colors.red,
                                          ),
                                          BarChartRodStackItem(
                                            (s.passed + s.failed).toDouble(),
                                            s.total.toDouble(),
                                            Colors.orange,
                                          ),
                                        ],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ],
                                  );
                                })
                                .toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 4. COMMUNITY TABLE
                const Text(
                  "Community Performance",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  "Community",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  "Pass %",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  "Avg Def",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  "Days",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),

                        ...stats.communityStats.map((comm) {
                          final Color rateColor = comm.passRate >= 85
                              ? Colors.green
                              : (comm.passRate < 70
                                    ? Colors.red
                                    : Colors.orange);

                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CommunityDetailScreen(
                                    communityName: comm.name,
                                    allInspections: widget.inspections,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      comm.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      "${comm.passRate.toStringAsFixed(0)}%",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: rateColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      comm.avgDefectsPerInspection
                                          .toStringAsFixed(1),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      "${comm.avgDaysToPass.toStringAsFixed(1)}",
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.blueGrey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AIChatDialog(
              // We pass the RAW data so the AI can analyze it
              contextData: widget.inspections,
            ),
          );
        },
        backgroundColor: Colors.blue[900],
        icon: const Icon(Icons.auto_awesome, color: Colors.white),
        label: const Text(
          "Ask Burgess Buddy",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, DateRange range) {
    final bool isSelected = _selectedRange == range;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          _onRangeChanged(range);
        }
      },
      selectedColor: Colors.blue[100],
      labelStyle: TextStyle(
        color: isSelected ? Colors.blue[900] : Colors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? Colors.blue : Colors.grey[300]!),
      ),
    );
  }

  // --- HELPERS ---

  double _getMaxY(List<SuperintendentStats> stats) {
    if (stats.isEmpty) return 10;
    final maxTotal = stats.map((e) => e.total).reduce((a, b) => a > b ? a : b);
    return maxTotal.toDouble() * 1.1;
  }

  List<PieChartSectionData> _buildPieSections(DashboardStats stats) {
    List<PieChartSectionData> sections = [];
    if (stats.passedCount > 0) {
      sections.add(
        PieChartSectionData(
          value: stats.passedCount.toDouble(),
          title: "${stats.passedCount}",
          color: Colors.green[400],
          radius: 60,
          titleStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }
    if (stats.failedCount > 0) {
      sections.add(
        PieChartSectionData(
          value: stats.failedCount.toDouble(),
          title: "${stats.failedCount}",
          color: Colors.red[400],
          radius: 60,
          titleStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }
    if (stats.cancelledCount > 0) {
      sections.add(
        PieChartSectionData(
          value: stats.cancelledCount.toDouble(),
          title: "${stats.cancelledCount}",
          color: Colors.orange[300],
          radius: 60,
          titleStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }
    return sections;
  }

  Widget _buildKpiCard(String label, String value, Color color) {
    return Expanded(
      child: Card(
        elevation: 0,
        color: Colors.white,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, color: color, size: 12),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }
}
