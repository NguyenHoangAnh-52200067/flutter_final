import 'dart:math';

import 'package:ecomerce_app/repository/user_repository.dart';
import 'package:flutter/material.dart';
import 'package:ecomerce_app/models/order_model.dart';
import 'package:ecomerce_app/repository/order_repository.dart';
import 'package:ecomerce_app/utils/utils.dart';
import 'package:ecomerce_app/screens/cart/order_detail_screen.dart';
import 'package:intl/intl.dart';

class AdminOrderManagementScreen extends StatefulWidget {
  const AdminOrderManagementScreen({super.key});

  @override
  State<AdminOrderManagementScreen> createState() =>
      _AdminOrderManagementScreenState();
}

class _AdminOrderManagementScreenState extends State<AdminOrderManagementScreen>
    with SingleTickerProviderStateMixin {
  static const int _ordersPerPage = 20;
  int _currentPage = 1;
  int _totalPages = 1;

  // Giữ nguyên các biến hiện có
  late TabController _tabController;
  final OrderRepository _orderRepository = OrderRepository();
  final TextEditingController _searchController = TextEditingController();
  final UserRepository _userRepository = UserRepository();

  bool _isLoading = false;
  String? _error;

  final List<OrderModel> allOrders = [];
  final List<OrderModel> waitingAcceptOrders = [];
  final List<OrderModel> waitingDeliveryOrders = [];
  final List<OrderModel> successOrders = [];
  final List<OrderModel> returnOrders = [];
  final List<OrderModel> canceledOrders = [];

  final List<String> tabTitles = [
    'Tất cả',
    'Chờ xác nhận',
    'Chờ giao hàng',
    'Đã giao',
    'Trả hàng',
    'Đã hủy',
  ];

  // Thêm getter để lấy danh sách đơn hàng đã phân trang
  List<OrderModel> get _paginatedOrders {
    final List<OrderModel> currentOrders = _getOrdersByStatus(
      tabTitles[_tabController.index],
    );
    final int startIndex = (_currentPage - 1) * _ordersPerPage;
    final int endIndex = min(startIndex + _ordersPerPage, currentOrders.length);

    if (startIndex >= currentOrders.length) return [];
    return currentOrders.sublist(startIndex, endIndex);
  }

  // Thêm các biến để theo dõi bộ lọc thời gian
  DateTime? _startDate;
  DateTime? _endDate;
  String _currentFilter = 'Tất cả'; // Giá trị mặc định

  // Thêm danh sách các tùy chọn lọc
  final List<String> filterOptions = [
    'Tất cả',
    'Hôm nay',
    'Tuần này',
    'Tháng này',
    'Tùy chọn',
  ];

  // Thêm phương thức để lấy khoảng thời gian dựa trên bộ lọc
  void _updateDateRange(String filter) {
    final now = DateTime.now();
    setState(() {
      _currentFilter = filter;
      switch (filter) {
        case 'Hôm nay':
          _startDate = DateTime(now.year, now.month, now.day);
          _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case 'Tuần này':
          _startDate = now.subtract(Duration(days: now.weekday - 1));
          _endDate = _startDate!.add(
            const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
          );
          break;
        case 'Tháng này':
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
          break;
        case 'Tất cả':
          _startDate = null;
          _endDate = null;
          break;
        default:
          break;
      }
      _loadOrders();
    });
  }

  Future<void> _loadOrders() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final orderList = await _orderRepository.getAllOrders();

      // Lọc đơn hàng theo khoảng thời gian
      final filteredOrders =
          _startDate != null && _endDate != null
              ? orderList.where((order) {
                return order.orderDate.isAfter(_startDate!) &&
                    order.orderDate.isBefore(_endDate!);
              }).toList()
              : orderList;

      if (!mounted) return;

      setState(() {
        allOrders.clear();
        waitingAcceptOrders.clear();
        waitingDeliveryOrders.clear();
        successOrders.clear();
        returnOrders.clear();
        canceledOrders.clear();

        // Sắp xếp theo thời gian mới nhất
        filteredOrders.sort((a, b) => b.orderDate.compareTo(a.orderDate));

        allOrders.addAll(filteredOrders);
        waitingAcceptOrders.addAll(
          filteredOrders.where((order) => order.status == 'Chờ xác nhận'),
        );
        waitingDeliveryOrders.addAll(
          filteredOrders.where((order) => order.status == 'Chờ giao hàng'),
        );
        successOrders.addAll(
          filteredOrders.where((order) => order.status == 'Đã giao'),
        );
        returnOrders.addAll(
          filteredOrders.where((order) => order.status == 'Trả hàng'),
        );
        canceledOrders.addAll(
          filteredOrders.where((order) => order.status == 'Đã hủy'),
        );

        _updateTotalPages();
        _currentPage = 1;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Không thể tải danh sách đơn hàng: $e';
        _isLoading = false;
      });
    }
  }

  int calculateMemberShipPoints(int orderTotalVND) {
    return (orderTotalVND * 0.10 / 1000).floor();
  }

  int convertPointsToVND(int points) {
    return points * 1000;
  }

  void _updateOrderStatus(OrderModel order, String newStatus) async {
    try {
      switch (newStatus) {
        case 'Chờ giao hàng':
          await _orderRepository.updateAcceptDate(order.id);
          await _orderRepository.updateShippingDate(order.id);
          break;
        case 'Đã giao':
          await _orderRepository.updateDeliveryDate(order.id);
          await _orderRepository.updatePaymentDate(order.id);
          break;
        default:
          break;
      }
      await _orderRepository.updateOrderStatus(order.id, newStatus);
      await _userRepository.updateMembershipPoints(
        order.customerId,
        calculateMemberShipPoints((order.totalAmount).truncate()).toInt(),
      );
      await _userRepository.addMembershipCurrentPoints(
        order.customerId,
        calculateMemberShipPoints((order.totalAmount).truncate()).toInt(),
      );
      await _loadOrders();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Cập nhật trạng thái thành công')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi cập nhật trạng thái: $e')),
      );
    }
  }

  List<OrderModel> _getOrdersByStatus(String status) {
    switch (status) {
      case 'Tất cả':
        return allOrders;
      case 'Chờ xác nhận':
        return waitingAcceptOrders;
      case 'Chờ giao hàng':
        return waitingDeliveryOrders;
      case 'Đã giao':
        return successOrders;
      case 'Trả hàng':
        return returnOrders;
      case 'Đã hủy':
        return canceledOrders;
      default:
        return [];
    }
  }

  Widget _buildOrderItem(OrderModel order) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ExpansionTile(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mã đơn: ${order.id}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Khách hàng: ${order.customerName}',
              style: const TextStyle(fontSize: 14),
            ),
            SizedBox(height: 8),
            Text(
              'Ngày đặt: ${DateFormat('dd/MM/yyyy').format(order.orderDate)}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8),
            Text(
              'Tổng tiền: ${Utils.formatCurrency(order.totalAmount)}',
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(order.status),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                order.status,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => OrderDetailScreen(order: order),
                          ),
                        );
                      },
                      child: const Text('Xem chi tiết'),
                    ),
                    if (order.status == 'Chờ xác nhận')
                      ElevatedButton(
                        onPressed:
                            () => _updateOrderStatus(order, 'Chờ giao hàng'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.lightBlue,
                        ),
                        child: const Text(
                          'Xác nhận',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    if (order.status == 'Chờ giao hàng')
                      ElevatedButton(
                        onPressed: () => _updateOrderStatus(order, 'Đã giao'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                        child: const Text(
                          'Giao hàng',
                          style: TextStyle(color: Colors.white, fontSize: 16),
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Chờ xác nhận':
        return Colors.orange;
      case 'Chờ giao hàng':
        return Colors.blue;
      case 'Đã giao':
        return Colors.green;
      case 'Trả hàng':
        return Colors.purple;
      case 'Đã hủy':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.network(
            'https://deo.shopeemobile.com/shopee/shopee-pcmall-live-sg/orderlist/4751043c866ed52f9661.png',
            width: 100,
            height: 100,
          ),
          SizedBox(height: 16),
          Text('Không có đơn hàng nào', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadOrders, child: const Text('Thử lại')),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildOrderList(String status) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState(_error!);
    }

    final orders = _paginatedOrders;
    if (orders.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: orders.length,
            padding: const EdgeInsets.all(8),
            itemBuilder: (context, index) => _buildOrderItem(orders[index]),
          ),
        ),
        _buildPagination(),
      ],
    );
  }

  // Thêm phương thức để cập nhật tổng số trang
  void _updateTotalPages() {
    final currentOrders = _getOrdersByStatus(tabTitles[_tabController.index]);
    _totalPages = (currentOrders.length / _ordersPerPage).ceil();
  }

  // Thêm widget phân trang
  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed:
                _currentPage > 1 ? () => setState(() => _currentPage--) : null,
          ),
          Text('Trang $_currentPage/$_totalPages'),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed:
                _currentPage < _totalPages
                    ? () => setState(() => _currentPage++)
                    : null,
          ),
        ],
      ),
    );
  }

  Future<void> _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange:
          _startDate != null && _endDate != null
              ? DateTimeRange(start: _startDate!, end: _endDate!)
              : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color.fromARGB(255, 122, 156, 229),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day,
          23,
          59,
          59,
        );
        _currentFilter = 'Tùy chọn';
        _loadOrders();
      });
    }
  }

  // Thêm widget để hiển thị các nút lọc
  Widget _buildFilterButtons() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children:
              filterOptions.map((filter) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(
                      filter,
                      style: TextStyle(
                        color:
                            _currentFilter == filter
                                ? Colors.white
                                : Colors.black,
                        fontSize: 12,
                      ),
                    ),
                    selected: _currentFilter == filter,
                    onSelected: (bool selected) {
                      if (selected) {
                        if (filter == 'Tùy chọn') {
                          _showDateRangePicker();
                        } else {
                          _updateDateRange(filter);
                        }
                      }
                    },
                    backgroundColor: Colors.grey[200],
                    selectedColor: const Color(0xFF7AE582),
                    checkmarkColor: Colors.white,
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabTitles.length, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _updateTotalPages();
        _currentPage = 1;
      });
    });
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý đơn hàng'),
        backgroundColor: const Color(0xFF7AE582),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: tabTitles.map((title) => Tab(text: title)).toList(),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm đơn hàng...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                // Implement search functionality
              },
            ),
          ),
          // Thêm dải nút lọc thời gian
          _buildFilterButtons(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children:
                  tabTitles.map((status) => _buildOrderList(status)).toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadOrders,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
