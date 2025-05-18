import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

enum TimeFrame { yearly, quarterly, monthly, weekly, daily, custom }

class AdvancedDashboard extends StatefulWidget {
  const AdvancedDashboard({Key? key}) : super(key: key);

  @override
  State<AdvancedDashboard> createState() => _AdvancedDashboardState();
}

class _AdvancedDashboardState extends State<AdvancedDashboard> {
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
  TimeFrame selectedTimeFrame = TimeFrame.yearly;
  DateTime? startDate;
  DateTime? endDate;

  // Statistics data
  Map<String, dynamic> statistics = {
    'orderCount': 0,
    'totalRevenue': 0.0,
    'totalProfit': 0.0,
    'productsSold': 0,
    'productTypes': 0,
  };

  // Chart data
  List<FlSpot> revenueSpots = [];
  List<FlSpot> profitSpots = [];
  List<FlSpot> orderSpots = [];

  @override
  void initState() {
    super.initState();
    _initializeDates();
    _loadDashboardData();
  }

  void _initializeDates() {
    final now = DateTime.now();
    switch (selectedTimeFrame) {
      case TimeFrame.yearly:
        startDate = DateTime(now.year, 1, 1);
        endDate = DateTime(now.year, 12, 31, 23, 59, 59);
        break;
      case TimeFrame.quarterly:
        final quarter = (now.month - 1) ~/ 3;
        startDate = DateTime(now.year, quarter * 3 + 1, 1);
        endDate = DateTime(now.year, (quarter + 1) * 3 + 1, 0, 23, 59, 59);
        break;
      case TimeFrame.monthly:
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case TimeFrame.weekly:
        startDate = DateTime.now().subtract(Duration(days: now.weekday - 1));
        endDate = startDate!.add(
          Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
        );
        break;
      case TimeFrame.daily:
        final today = DateTime.now();
        startDate = DateTime(today.year, today.month, today.day);
        endDate = DateTime(today.year, today.month, today.day, 23, 59, 59);
        break;
      case TimeFrame.custom:
        break;
    }

    print('Selected timeframe: $selectedTimeFrame');
    print('Start date: $startDate');
    print('End date: $endDate');
  }

  Future<void> _loadDashboardData() async {
    try {
      print('Loading data for timeframe: $selectedTimeFrame');
      print('Date range: $startDate to $endDate');

      final ordersSnapshot =
          await FirebaseFirestore.instance
              .collection('orders')
              .where('deliveryDate', isGreaterThanOrEqualTo: startDate)
              .where('deliveryDate', isLessThanOrEqualTo: endDate)
              .where('status', isEqualTo: 'Đã giao')
              .get();

      print('Found ${ordersSnapshot.docs.length} orders');

      double totalRevenue = 0;
      double totalProfit = 0;
      int orderCount = 0;
      int totalProductsSold = 0;
      Set<String> uniqueProducts = {};
      double totalProductsCostPrice = 0.0;

      Map<String, Map<String, dynamic>> groupedStats = {};
      List<String> labels = [];

      switch (selectedTimeFrame) {
        case TimeFrame.yearly:
          for (int i = 1; i <= 12; i++) {
            final monthKey = i.toString().padLeft(2, '0');
            groupedStats[monthKey] = {
              'revenue': 0.0,
              'profit': 0.0,
              'orders': 0,
            };
            labels.add('T$i');
          }
          break;

        case TimeFrame.quarterly:
          final quarter = (startDate!.month - 1) ~/ 3;
          for (int i = 0; i < 3; i++) {
            final month = quarter * 3 + i + 1;
            final monthKey = month.toString().padLeft(2, '0');
            groupedStats[monthKey] = {
              'revenue': 0.0,
              'profit': 0.0,
              'orders': 0,
            };
            labels.add('T$month');
          }
          break;

        case TimeFrame.monthly:
          for (int i = 0; i < 4; i++) {
            final weekKey = 'W$i';
            groupedStats[weekKey] = {
              'revenue': 0.0,
              'profit': 0.0,
              'orders': 0,
            };
            labels.add('Tuần ${i + 1}');
          }
          break;

        case TimeFrame.weekly:
          for (int i = 0; i < 7; i++) {
            final date = startDate!.add(Duration(days: i));
            final dayKey = DateFormat('yyyy-MM-dd').format(date);
            groupedStats[dayKey] = {'revenue': 0.0, 'profit': 0.0, 'orders': 0};
            labels.add('${date.day}/${date.month}');
          }
          break;

        case TimeFrame.daily:
          labels.clear();
          groupedStats.clear();
          for (int i = 0; i <= 6; i++) {
            final hour = i * 4;
            final hourKey = hour.toString().padLeft(2, '0');
            print(hour);
            groupedStats[hourKey] = {
              'revenue': 0.0,
              'profit': 0.0,
              'orders': 0,
            };
            labels.add('${hour}h');
          }
          break;

        case TimeFrame.custom:
          final daysBetween = endDate!.difference(startDate!).inDays + 1;
          for (int i = 0; i < daysBetween; i++) {
            final date = startDate!.add(Duration(days: i));
            final dayKey =
                '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
            groupedStats[dayKey] = {'revenue': 0.0, 'profit': 0.0, 'orders': 0};
            labels.add('${date.day}/${date.month}');
          }
          break;
      }

      for (var doc in ordersSnapshot.docs) {
        final orderData = doc.data();
        final amount = (orderData['totalAmount'] as num).toDouble();
        final revenue = (orderData['revenue'] as num).toDouble();
        final orderDate = (orderData['deliveryDate'] as Timestamp).toDate();
        final items = orderData['orderDetails'] as List<dynamic>;

        totalRevenue += amount;
        totalProfit += revenue;
        orderCount++;

        for (var item in items) {
          final productId = item['product']['id'] as String;
          final quantity = (item['quantity'] as num).toInt();
          final costPrice =
              (item['product']['costPrice'] as num?)?.toDouble() ?? 0.0;

          uniqueProducts.add(productId);
          totalProductsSold += quantity;
          totalProductsCostPrice += costPrice * quantity;
        }

        String groupKey;

        switch (selectedTimeFrame) {
          case TimeFrame.yearly:
            groupKey = orderDate.month.toString().padLeft(2, '0');
            break;

          case TimeFrame.quarterly:
            groupKey = orderDate.month.toString().padLeft(2, '0');
            break;

          case TimeFrame.monthly:
            final startOfMonth = DateTime(orderDate.year, orderDate.month, 1);
            final dayOfMonth = orderDate.day;
            final weekOfMonth = ((dayOfMonth - 1) / 7).floor();
            groupKey = 'W$weekOfMonth';
            break;

          case TimeFrame.weekly:
            groupKey = DateFormat('yyyy-MM-dd').format(orderDate);
            break;

          case TimeFrame.daily:
            final hourGroup = (orderDate.hour / 4).floor() * 4;
            groupKey = hourGroup.toString().padLeft(2, '0');
            break;

          case TimeFrame.custom:
            groupKey = DateFormat('yyyy-MM-dd').format(orderDate);
            break;
        }

        if (groupedStats.containsKey(groupKey)) {
          print('Group found, updating stats for group: $groupKey');
          final stats = groupedStats[groupKey]!;
          stats['revenue'] += amount;
          stats['profit'] += revenue;
          stats['orders'] += 1;
        } else {
          print('WARNING: No matching group found for key: $groupKey');
        }
      }

      List<FlSpot> revSpots = [];
      List<FlSpot> profSpots = [];
      List<FlSpot> ordSpots = [];

      final sortedKeys = groupedStats.keys.toList()..sort();

      for (var i = 0; i < sortedKeys.length; i++) {
        final stats = groupedStats[sortedKeys[i]]!;
        revSpots.add(FlSpot(i.toDouble(), stats['revenue']));
        profSpots.add(FlSpot(i.toDouble(), stats['profit']));
        ordSpots.add(FlSpot(i.toDouble(), stats['orders'].toDouble()));
      }

      setState(() {
        statistics = {
          'orderCount': orderCount,
          'totalRevenue': totalRevenue,
          'totalProfit': totalProfit,
          'productsSold': totalProductsSold,
          'productTypes': uniqueProducts.length,
        };
        revenueSpots = revSpots;
        profitSpots = profSpots;
        orderSpots = ordSpots;

        statistics['chartLabels'] = labels;
      });
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Thống kê chi tiết',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _initializeDates();
              _loadDashboardData();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTimeFrameSelector(),
            const SizedBox(height: 16),
            _buildStatisticsGrid(),
            const SizedBox(height: 24),
            _buildCharts(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeFrameSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: [
            ...TimeFrame.values.map((frame) {
              final isSelected = selectedTimeFrame == frame;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ElevatedButton(
                  onPressed: () {
                    if (frame == TimeFrame.custom) {
                      _showDateRangePicker();
                    } else {
                      setState(() {
                        selectedTimeFrame = frame;
                        _initializeDates();
                        _loadDashboardData();
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isSelected ? Colors.blueAccent : Colors.grey[200],
                    foregroundColor: isSelected ? Colors.white : Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(_getTimeFrameText(frame)),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Future<void> _showDateRangePicker() async {
    final now = DateTime.now();
    final lastDate = DateTime(now.year, now.month, now.day);

    DateTimeRange? initialRange;
    if (startDate != null && endDate != null) {
      final adjustedEndDate = endDate!.isAfter(lastDate) ? lastDate : endDate!;
      initialRange = DateTimeRange(start: startDate!, end: adjustedEndDate);
    }

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: lastDate,
      initialDateRange: initialRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF7AE582)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedTimeFrame = TimeFrame.custom;
        startDate = DateTime(
          picked.start.year,
          picked.start.month,
          picked.start.day,
        );
        endDate = DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day,
          23,
          59,
          59,
        );

        print('Custom date range selected:');
        print('Start date: $startDate');
        print('End date: $endDate');

        _loadDashboardData();
      });
    }
  }

  Widget _buildStatisticsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Số đơn hàng',
          statistics['orderCount'].toString(),
          Icons.shopping_cart,
          Colors.blue,
        ),
        _buildStatCard(
          'Doanh thu',
          currencyFormat.format(statistics['totalRevenue']),
          Icons.attach_money,
          Colors.green,
        ),
        _buildStatCard(
          'Lợi nhuận',
          currencyFormat.format(statistics['totalProfit']),
          Icons.trending_up,
          Colors.orange,
        ),
        _buildStatCard(
          'Sản phẩm đã bán',
          statistics['productsSold'].toString(),
          Icons.inventory,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharts() {
    if (revenueSpots.isEmpty) {
      return const Center(
        child: Text('Không có dữ liệu trong khoảng thời gian này'),
      );
    }

    return Column(
      children: [
        _buildLineChart(
          'Biểu đồ doanh thu',
          revenueSpots,
          Colors.blue,
          (value) => currencyFormat.format(value),
        ),
        const SizedBox(height: 24),
        _buildLineChart(
          'Biểu đồ lợi nhuận',
          profitSpots,
          Colors.green,
          (value) => currencyFormat.format(value),
        ),
        const SizedBox(height: 24),
        _buildLineChart(
          'Biểu đồ số đơn hàng',
          orderSpots,
          Colors.orange,
          (value) => value.toInt().toString(),
        ),
      ],
    );
  }

  Widget _buildLineChart(
    String title,
    List<FlSpot> spots,
    Color color,
    String Function(double) formatValue,
  ) {
    if (spots.isEmpty) {
      return const Center(
        child: Text('Không có dữ liệu trong khoảng thời gian này'),
      );
    }

    final labels = (statistics['chartLabels'] as List<String>?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 300,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: true),
              titlesData: FlTitlesData(
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),

                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      final valueInt = value.toInt();
                      if (valueInt < 0 || valueInt >= labels.length) {
                        return const SizedBox();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            labels[valueInt],
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 80,
                    getTitlesWidget: (value, meta) {
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          formatValue(value),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: true),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: false,
                  color: color,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: color.withOpacity(0.2),
                  ),
                ),
              ],
              minY: 0,
            ),
          ),
        ),
      ],
    );
  }

  String _getTimeFrameText(TimeFrame frame) {
    switch (frame) {
      case TimeFrame.daily:
        return 'Hôm nay';
      case TimeFrame.weekly:
        return 'Tuần';
      case TimeFrame.monthly:
        return 'Tháng';
      case TimeFrame.quarterly:
        return 'Quý';
      case TimeFrame.yearly:
        return 'Năm';
      case TimeFrame.custom:
        return 'Tùy chỉnh';
    }
  }
}
