import 'dart:math';
import 'package:ecommerce_app/models/order_model.dart';
import 'package:ecommerce_app/models/product_model.dart';
import 'package:ecommerce_app/repository/order_repository.dart';
import 'package:ecommerce_app/screens/cart/order_detail_screen.dart';
import 'package:ecommerce_app/utils/utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class OrderScreen extends StatefulWidget {
  final int initialTabIndex;

  const OrderScreen({super.key, this.initialTabIndex = 0});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen>
    with TickerProviderStateMixin {
  static const int _ordersPerPage = 20;
  int _currentPage = 1;
  int _totalPages = 1;

  late TabController _tabController;
  final OrderRepository _orderRepository = OrderRepository();
  bool _isLoading = false;
  String? _error;

  final List<OrderModel> allOrders = [];
  final List<OrderModel> waitingAcceptOrders = [];
  final List<OrderModel> waitingDeliveryOrders = [];
  final List<OrderModel> successOrders = [];
  final List<OrderModel> returnOrders = [];
  final List<OrderModel> canceledOrders = [];

  List<OrderModel> get _paginatedOrders {
    final List<OrderModel> currentOrders = _getOrdersByStatus(
      tabTitles[_tabController.index],
    );
    final int startIndex = (_currentPage - 1) * _ordersPerPage;
    final int endIndex = min(startIndex + _ordersPerPage, currentOrders.length);

    if (startIndex >= currentOrders.length) return [];
    return currentOrders.sublist(startIndex, endIndex);
  }

  final List<String> tabTitles = [
    'Tất cả',
    'Chờ xác nhận',
    'Chờ giao hàng',
    'Đã giao',
    'Trả hàng',
    'Đã hủy',
  ];

  // Sử dụng TickerProviderStateMixin để hỗ trợ nhiều ticker nếu cần
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: tabTitles.length,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _tabController.addListener(() {
      setState(() {
        _updateTotalPages();
        _currentPage = 1;
      });
    });
    _loadOrders();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.stop(); // Ngăn ticker chạy liên tục
      }
    });

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose(); // Đảm bảo dispose đúng cách
    super.dispose();
  }

  Future<void> _loadOrders() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final String userId = FirebaseAuth.instance.currentUser!.uid;
      final orderList = await _orderRepository.getOrdersByUserId(userId);

      if (!mounted) return;

      setState(() {
        allOrders.clear();
        waitingAcceptOrders.clear();
        waitingDeliveryOrders.clear();
        successOrders.clear();
        returnOrders.clear();
        canceledOrders.clear();
        orderList.sort((a, b) => b.orderDate.compareTo(a.orderDate));

        allOrders.addAll(orderList);
        waitingAcceptOrders.addAll(
          orderList.where((order) => order.status == 'Chờ xác nhận'),
        );
        waitingDeliveryOrders.addAll(
          orderList.where((order) => order.status == 'Chờ giao hàng'),
        );
        successOrders.addAll(
          orderList.where((order) => order.status == 'Đã giao'),
        );
        returnOrders.addAll(
          orderList.where((order) => order.status == 'Trả hàng'),
        );
        canceledOrders.addAll(
          orderList.where((order) => order.status == 'Đã hủy'),
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

  void updateOrderStatus(String orderId, String status) async {
    try {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title:
                status == 'Đã hủy'
                    ? const Text('Xác nhận hủy đơn')
                    : const Text('Xác nhận trả hàng'),
            content:
                status == 'Đã hủy'
                    ? const Text('Bạn có chắc chắn muốn hủy đơn hàng này?')
                    : const Text('Bạn có chắc chắn muốn trả lại đơn hàng này?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Không'),
              ),
              TextButton(
                onPressed: () async {
                  if (status == 'Đã hủy') {
                    await _orderRepository.markOrderAsCanceled(orderId);
                  } else {
                    await _orderRepository.markOrderAsReturned(orderId);
                  }
                  if (!mounted) return;
                  Navigator.of(context).pop();
                  _loadOrders();
                },
                child: const Text('Có', style: TextStyle(color: Colors.red)),
              ),
            ],
          );
        },
      );
    } catch (e) {
      setState(() {
        _error = 'Không thể cập nhật trạng thái đơn hàng: $e';
      });
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

  void _updateTotalPages() {
    final currentOrders = _getOrdersByStatus(tabTitles[_tabController.index]);
    _totalPages = (currentOrders.length / _ordersPerPage).ceil();
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
            Text(
              'Bạn chưa có đơn hàng nào',
              style: TextStyle(color: Colors.blue.shade700),
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
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadOrders,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildOrderItem(OrderModel order) {
    return InkWell(
      onTap: () {
        if (order.orderDetails.isNotEmpty &&
            order.orderDetails.every(
              (detail) => detail.product.images.isNotEmpty,
            )) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailScreen(order: order),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Không thể hiển thị chi tiết đơn hàng do thiếu thông tin',
              ),
              backgroundColor: Colors.blue,
            ),
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.blue.shade300),
          ),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Đơn hàng',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    Text(
                      order.status,
                      style: TextStyle(
                        color: _getStatusColor(order.status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Divider(height: 24, color: Colors.black54),
                ...order.orderDetails.map((detail) {
                  return Column(
                    children: [
                      _buildProductItem(detail.product),
                      if (detail != order.orderDetails.last)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Divider(
                            height: 16,
                            thickness: 1,
                            color: Color.fromARGB(255, 126, 125, 125),
                          ),
                        ),
                    ],
                  );
                }),
                Divider(height: 24, color: Colors.black45),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tổng số tiền: (${order.orderDetails.length} sản phẩm)',
                      style: TextStyle(fontSize: 15, color: Colors.black),
                    ),
                    Text(
                      Utils.formatCurrency(order.totalAmount),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (order.status == 'Chờ xác nhận' ||
                        order.status == 'Chờ giao hàng')
                      ElevatedButton(
                        style: ButtonStyle(
                          minimumSize: WidgetStateProperty.all(
                            const Size(80, 36),
                          ),
                          padding: MaterialStateProperty.all(
                            const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                          ),
                          backgroundColor: WidgetStateProperty.all(
                            Colors.white,
                          ),
                          side: WidgetStateProperty.all(
                            const BorderSide(color: Colors.black, width: 1.5),
                          ),
                        ),
                        onPressed: () {
                          updateOrderStatus(order.id, 'Đã hủy');
                        },
                        child: const Text(
                          'Hủy đơn hàng',
                          style: TextStyle(color: Colors.black, fontSize: 12),
                        ),
                      ),
                    const SizedBox(width: 8),
                    if (order.status == 'Đã giao')
                      ElevatedButton(
                        style: ButtonStyle(
                          minimumSize: WidgetStateProperty.all(
                            const Size(80, 36),
                          ),
                          padding: WidgetStateProperty.all(
                            const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                          ),
                          backgroundColor: WidgetStateProperty.all(
                            Colors.white,
                          ),
                          side: WidgetStateProperty.all(
                            const BorderSide(color: Colors.red, width: 1.5),
                          ),
                        ),
                        onPressed: () {
                          updateOrderStatus(order.id, 'Trả hàng');
                        },
                        child: const Text(
                          'Trả hàng',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    const SizedBox(width: 8),
                    if (order.status != 'Chờ giao hàng' &&
                        order.status != 'Chờ xác nhận' &&
                        order.status != 'Đã hủy')
                      ElevatedButton(
                        style: ButtonStyle(
                          minimumSize: WidgetStateProperty.all(
                            const Size(80, 36),
                          ),
                          padding: WidgetStateProperty.all(
                            const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                          ),
                          backgroundColor: WidgetStateProperty.all(
                            Colors.white,
                          ),
                          side: WidgetStateProperty.all(
                            BorderSide(color: Colors.blue, width: 1.5),
                          ),
                        ),
                        onPressed: () {},
                        child: Text(
                          'Đánh giá',
                          style: TextStyle(color: Colors.blue, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ],
            ),
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
        return Colors.red;
      case 'Đã hủy':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  Widget _buildProductItem(ProductModel product) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          _buildProductImage(product),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                if (product.discount > 0)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Utils.formatCurrency(product.price),
                        style: TextStyle(
                          color: Colors.black54,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Utils.formatCurrency(product.priceAfterDiscount!),
                        style: TextStyle(color: Colors.black),
                      ),
                    ],
                  )
                else
                  Text(
                    Utils.formatCurrency(product.price),
                    style: TextStyle(color: Colors.black),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage(ProductModel product) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          product.images.first,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.image_not_supported);
          },
        ),
      ),
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
            padding: const EdgeInsets.only(top: 16, bottom: 16),
            itemBuilder: (context, index) {
              final order = orders[index];
              try {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _buildOrderItem(order),
                  ),
                );
              } catch (e) {
                print('Error building order item at index $index: $e');
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  child: ListTile(
                    title: const Text('Error loading order'),
                    subtitle: Text('Order #$index'),
                  ),
                );
              }
            },
          ),
        ),
        _buildPagination(),
      ],
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left, color: Colors.blue),
            onPressed:
                _currentPage > 1 ? () => setState(() => _currentPage--) : null,
          ),
          Text(
            'Trang $_currentPage/$_totalPages',
            style: TextStyle(color: Colors.blue.shade700),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right, color: Colors.blue),
            onPressed:
                _currentPage < _totalPages
                    ? () => setState(() => _currentPage++)
                    : null,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Đơn hàng của tôi',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.blue,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
          ),
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            color: Colors.black26,
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelPadding: const EdgeInsets.symmetric(horizontal: 12),
          tabs:
              tabTitles
                  .map(
                    (title) => Tab(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        child: Text(title),
                      ),
                    ),
                  )
                  .toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: tabTitles.map((status) => _buildOrderList(status)).toList(),
      ),
    );
  }
}
