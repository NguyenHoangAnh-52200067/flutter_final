import 'dart:math';

import 'package:ecommerce_app/models/order_model.dart';
import 'package:ecommerce_app/models/product_model.dart';
import 'package:ecommerce_app/repository/order_repository.dart';
import 'package:ecommerce_app/repository/product_repository.dart';
import 'package:ecommerce_app/repository/user_repository.dart';
import 'package:ecommerce_app/screens/cart/order_detail_screen.dart';
import 'package:ecommerce_app/services/mail_service.dart';
import 'package:ecommerce_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminOrderManagementScreen extends StatefulWidget {
  const AdminOrderManagementScreen({super.key});

  @override
  State<AdminOrderManagementScreen> createState() =>
      _AdminOrderManagementScreenState();
}

class _AdminOrderManagementScreenState extends State<AdminOrderManagementScreen>
    with TickerProviderStateMixin {
  static const int _ordersPerPage = 20;
  int _currentPage = 1;
  int _totalPages = 1;

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

  List<OrderModel> get _paginatedOrders {
    final List<OrderModel> currentOrders = _getOrdersByStatus(
      tabTitles[_tabController.index],
    );
    final int startIndex = (_currentPage - 1) * _ordersPerPage;
    final int endIndex = min(startIndex + _ordersPerPage, currentOrders.length);

    if (startIndex >= currentOrders.length) return [];
    return currentOrders.sublist(startIndex, endIndex);
  }

  DateTime? _startDate;
  DateTime? _endDate;
  String _currentFilter = 'Tất cả';

  final List<String> filterOptions = [
    'Tất cả',
    'Hôm nay',
    'Tuần này',
    'Tháng này',
    'Tùy chọn',
  ];

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

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

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));
    _fadeController.forward();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
    _scaleController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _scaleController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _scaleController.forward();
      }
    });
    _scaleController.forward();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _slideController.forward();

    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    super.dispose();
  }

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
      _fadeController.reset();
      _fadeController.forward();
      _slideController.reset();
      _slideController.forward();
    });

    try {
      print("trước lấy order");
      final orderList = await _orderRepository.getAllOrders();
      print("lấy được all order");
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
          await _orderRepository.markOrderAsAccepted(order.id);
          break;
        case 'Đã giao':
          await _orderRepository.markOrderAsDelivered(order.id);
          break;
        case 'Đã hủy':
          await _orderRepository.markOrderAsCanceled(order.id);
          break;
        case 'Trả hàng':
          await _orderRepository.markOrderAsReturned(order.id);
          break;
        default:
          await _orderRepository.updateOrderStatus(order.id, newStatus);
          break;
      }

      await _loadOrders();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật trạng thái thành công')),
      );
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

  Future<List<ProductModel>> _fetchOrderProducts(OrderModel order) async {
    final List<ProductModel> products = [];
    final productRepository = ProductRepository();

    for (var detail in order.orderDetails) {
      final product = await productRepository.getProductById(
        detail.product.id!,
      );
      if (product != null) {
        products.add(product);
      }
    }

    return products;
  }

  Widget _buildOrderItem(OrderModel order) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.blue),
          ),

          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          color: Colors.white,
          child: ExpansionTile(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mã đơn: ${order.id}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Khách hàng: ${order.customerName}',
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ngày đặt: ${DateFormat('dd/MM/yyyy').format(order.orderDate)}',
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  'Tổng tiền: ${Utils.formatCurrency(order.totalAmount)}',
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    order.status,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => OrderDetailScreen(order: order),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ).copyWith(
                          backgroundColor: MaterialStateProperty.resolveWith((
                            states,
                          ) {
                            if (states.contains(MaterialState.hovered)) {
                              return Colors.blue;
                            }
                            return Colors.blueAccent;
                          }),
                        ),
                        icon: const Icon(
                          Icons.visibility,
                          size: 18,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Xem chi tiết',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                    if (order.status == 'Chờ xác nhận')
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: ElevatedButton.icon(
                          onPressed:
                              () => _updateOrderStatus(order, 'Chờ giao hàng'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ).copyWith(
                            backgroundColor: MaterialStateProperty.resolveWith((
                              states,
                            ) {
                              if (states.contains(MaterialState.hovered)) {
                                return Colors.blue;
                              }
                              return Colors.blueAccent;
                            }),
                          ),
                          icon: const Icon(
                            Icons.check_circle,
                            size: 18,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Xác nhận',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                    if (order.status == 'Chờ giao hàng')
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: ElevatedButton.icon(
                          onPressed: () => _updateOrderStatus(order, 'Đã giao'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ).copyWith(
                            backgroundColor: MaterialStateProperty.resolveWith((
                              states,
                            ) {
                              if (states.contains(MaterialState.hovered)) {
                                return Colors.blue;
                              }
                              return Colors.blueAccent;
                            }),
                          ),
                          icon: const Icon(
                            Icons.local_shipping,
                            size: 18,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Giao hàng',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              'https://deo.shopeemobile.com/shopee/shopee-pcmall-live-sg/orderlist/4751043c866ed52f9661.png',
              width: 100,
              height: 100,
            ),
            const SizedBox(height: 16),
            const Text(
              'Không có đơn hàng nào',
              style: TextStyle(color: Colors.blueAccent, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ScaleTransition(
              scale: _scaleAnimation,
              child: ElevatedButton.icon(
                onPressed: _loadOrders,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ).copyWith(
                  backgroundColor: MaterialStateProperty.resolveWith((states) {
                    if (states.contains(MaterialState.hovered)) {
                      return Colors.blue;
                    }
                    return Colors.blueAccent;
                  }),
                ),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Thử lại', style: TextStyle(fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: Colors.blueAccent),
    );
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

  void _updateTotalPages() {
    final currentOrders = _getOrdersByStatus(tabTitles[_tabController.index]);
    _totalPages = (currentOrders.length / _ordersPerPage).ceil();
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _scaleAnimation,
            child: IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.black54),
              onPressed:
                  _currentPage > 1
                      ? () => setState(() => _currentPage--)
                      : null,
            ),
          ),
          Text(
            'Trang $_currentPage/$_totalPages',
            style: const TextStyle(color: Colors.black54, fontSize: 16),
          ),
          ScaleTransition(
            scale: _scaleAnimation,
            child: IconButton(
              icon: const Icon(Icons.chevron_right, color: Colors.black54),
              onPressed:
                  _currentPage < _totalPages
                      ? () => setState(() => _currentPage++)
                      : null,
            ),
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
            colorScheme: const ColorScheme.light(primary: Colors.blueAccent),
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

  Widget _buildFilterButtons() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5),
        child: Row(
          children:
              filterOptions.map((filter) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      child: FilterChip(
                        label: Text(
                          filter,
                          style: TextStyle(
                            color:
                                _currentFilter == filter
                                    ? Colors.white
                                    : Colors.black87,
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
                        backgroundColor: Colors.white,
                        selectedColor: Colors.blueAccent,
                        checkmarkColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quản lý đơn hàng',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.blueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            color: Colors.blueAccent,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              tabs: tabTitles.map((title) => Tab(text: title)).toList(),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFBBDEFB)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm đơn hàng...',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Colors.blueAccent,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.blue),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.blue),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.blueAccent,
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (value) {
                  // Implement search functionality
                },
              ),
            ),
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
      ),
      floatingActionButton: ScaleTransition(
        scale: _scaleAnimation,
        child: FloatingActionButton(
          onPressed: _loadOrders,
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          child: const Icon(Icons.refresh),
        ),
      ),
    );
  }
}
