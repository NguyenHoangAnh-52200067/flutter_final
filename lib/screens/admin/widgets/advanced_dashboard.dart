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
        // Sửa lỗi: Tính toán ngày đầu tuần và cuối tuần chính xác hơn
        // Lấy ngày đầu tuần (thứ 2)
        startDate = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: now.weekday - 1));
        // Lấy ngày cuối tuần (chủ nhật)
        endDate = startDate!.add(
          const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
        );
        break;
      case TimeFrame.daily:
        final today = DateTime.now();
        startDate = DateTime(today.year, today.month, today.day);
        endDate = DateTime(today.year, today.month, today.day, 23, 59, 59);
        break;
      case TimeFrame.custom:
        // Giữ nguyên ngày đã chọn
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

      // Sửa lỗi: Đảm bảo truy vấn Firestore chính xác
      final ordersSnapshot =
          await FirebaseFirestore.instance
              .collection('orders')
              .where('deliveryDate', isGreaterThanOrEqualTo: startDate)
              .where('deliveryDate', isLessThanOrEqualTo: endDate)
              .where('status', isEqualTo: 'Đã giao')
              .get();

      print('Found ${ordersSnapshot.docs.length} orders');

      // Nếu không có đơn hàng, hiển thị biểu đồ trống
      if (ordersSnapshot.docs.isEmpty) {
        setState(() {
          statistics = {
            'orderCount': 0,
            'totalRevenue': 0.0,
            'totalProfit': 0.0,
            'productsSold': 0,
            'productTypes': 0,
          };
          revenueSpots = [];
          profitSpots = [];
          orderSpots = [];
        });
        return;
      }

      double totalRevenue = 0;
      double totalProfit = 0;
      int orderCount = 0;
      int totalProductsSold = 0;
      Set<String> uniqueProducts = {};
      double totalProductsCostPrice = 0.0;

      Map<DateTime, Map<String, dynamic>> dailyStats = {};

      for (
        DateTime date = startDate!;
        date.isBefore(endDate!.add(const Duration(days: 1)));
        date = date.add(const Duration(days: 1))
      ) {
        final dateKey = DateTime(date.year, date.month, date.day);
        dailyStats[dateKey] = {'revenue': 0.0, 'profit': 0.0, 'orders': 0};
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
        print("Tổng giá trị tiền hàng gốc $totalProductsCostPrice");
        final dateKey = DateTime(
          orderDate.year,
          orderDate.month,
          orderDate.day,
        );

        final stats = dailyStats[dateKey]!;
        stats['revenue'] += amount;
        stats['profit'] += revenue;
        stats['orders'] += 1;
      }

      final sortedDates = dailyStats.keys.toList()..sort();
      List<FlSpot> revSpots = [];
      List<FlSpot> profSpots = [];
      List<FlSpot> ordSpots = [];

      for (var i = 0; i < sortedDates.length; i++) {
        final stats = dailyStats[sortedDates[i]]!;
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
      });
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      // Hiển thị lỗi cụ thể hơn
      print('Chi tiết lỗi: $e');
      setState(() {
        statistics = {
          'orderCount': 0,
          'totalRevenue': 0.0,
          'totalProfit': 0.0,
          'productsSold': 0,
          'productTypes': 0,
        };
        revenueSpots = [];
        profitSpots = [];
        orderSpots = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê chi tiết'),
        backgroundColor: const Color(0xFF7AE582),
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
                        isSelected ? const Color(0xFF7AE582) : Colors.grey[200],
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
      // Ensure the initial range is valid
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
        // Set start date to beginning of the day
        startDate = DateTime(
          picked.start.year,
          picked.start.month,
          picked.start.day,
        );
        // Set end date to end of the day
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
        _buildBarChart(
          'Biểu đồ doanh thu',
          revenueSpots,
          Colors.blue,
          (value) => currencyFormat.format(value),
        ),
        const SizedBox(height: 24),
        _buildBarChart(
          'Biểu đồ lợi nhuận',
          profitSpots,
          Colors.green,
          (value) => currencyFormat.format(value),
        ),
        const SizedBox(height: 24),
        _buildBarChart(
          'Biểu đồ số đơn hàng',
          orderSpots,
          Colors.orange,
          (value) => value.toInt().toString(),
        ),
      ],
    );
  }

  Widget _buildBarChart(
    String title,
    List<FlSpot> spots,
    Color color,
    String Function(double) formatValue,
  ) {
    // Tính toán khoảng cách giữa các nhãn dựa trên loại khung thời gian
    final double interval = _calculateInterval(spots.length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 300,
          child: BarChart(
            BarChartData(
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
                    interval: interval,
                    getTitlesWidget: (value, meta) {
                      if (value % interval != 0 || value >= spots.length) {
                        return const SizedBox();
                      }

                      // Lấy ngày tương ứng với vị trí trên trục x
                      final date = startDate!.add(
                        Duration(days: value.toInt()),
                      );

                      // Định dạng nhãn dựa trên loại khung thời gian
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          _formatDateLabel(date),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
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
              barGroups:
                  spots.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.y,
                          color: color,
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY:
                                spots
                                    .map((spot) => spot.y)
                                    .reduce((a, b) => a > b ? a : b) *
                                1.1,
                            color: Colors.grey.withOpacity(0.1),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
              minY: 0,
            ),
          ),
        ),
      ],
    );
  }

  // Tính toán khoảng cách giữa các nhãn dựa trên loại khung thời gian
  double _calculateInterval(int spotsLength) {
    switch (selectedTimeFrame) {
      case TimeFrame.yearly:
        return 30.0; // Hiển thị khoảng 12 tháng
      case TimeFrame.quarterly:
        return 7.0; // Hiển thị khoảng 12-13 tuần
      case TimeFrame.monthly:
        return 5.0; // Hiển thị khoảng 6 ngày trong tháng
      case TimeFrame.weekly:
        return 1.0; // Hiển thị tất cả các ngày trong tuần
      case TimeFrame.daily:
        return 2.0; // Hiển thị khoảng 12 giờ trong ngày
      case TimeFrame.custom:
        // Tính toán khoảng cách dựa trên số lượng ngày
        final days = endDate!.difference(startDate!).inDays + 1;
        if (days <= 7) return 1.0;
        if (days <= 31) return (days / 6).ceil().toDouble();
        if (days <= 90) return (days / 12).ceil().toDouble();
        return (days / 15).ceil().toDouble();
    }
  }

  // Định dạng nhãn ngày tháng dựa trên loại khung thời gian
  String _formatDateLabel(DateTime date) {
    switch (selectedTimeFrame) {
      case TimeFrame.yearly:
        return DateFormat('MM').format(date); // Tháng/Năm
      case TimeFrame.quarterly:
        return DateFormat('dd/MM').format(date); // Ngày/Tháng
      case TimeFrame.monthly:
        return DateFormat('dd').format(date); // Ngày
      case TimeFrame.weekly:
        return DateFormat('EEE').format(date); // Thứ (T2, T3...)
      case TimeFrame.daily:
        return DateFormat('HH:mm').format(date); // Giờ:Phút
      case TimeFrame.custom:
        final days = endDate!.difference(startDate!).inDays + 1;
        if (days <= 7) return DateFormat('EEE').format(date); // Thứ
        if (days <= 31) return DateFormat('dd').format(date); // Ngày
        if (days <= 90) return DateFormat('dd/MM').format(date); // Ngày/Tháng
        return DateFormat('MM/yyyy').format(date); // Tháng/Năm
    }
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
