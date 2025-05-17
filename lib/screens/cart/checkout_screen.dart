import 'dart:async';
import 'dart:math';

import 'package:ecommerce_app/models/address_model.dart';
import 'package:ecommerce_app/models/cartitems_model.dart';
import 'package:ecommerce_app/models/order_details_model.dart';
import 'package:ecommerce_app/models/order_model.dart';
import 'package:ecommerce_app/models/product_model.dart';
import 'package:ecommerce_app/models/user_model.dart';
import 'package:ecommerce_app/models/voucher_model.dart';
import 'package:ecommerce_app/repository/address_repository.dart';
import 'package:ecommerce_app/repository/cart_repository.dart';
import 'package:ecommerce_app/repository/order_repository.dart';
import 'package:ecommerce_app/repository/product_repository.dart';
import 'package:ecommerce_app/repository/user_repository.dart';
import 'package:ecommerce_app/repository/user_voucher_repository.dart';
import 'package:ecommerce_app/repository/voucher_repository.dart';
import 'package:ecommerce_app/screens/cart/address_screen.dart';
import 'package:ecommerce_app/screens/setting/setting_screen.dart';
import 'package:ecommerce_app/services/mail_service.dart';
import 'package:ecommerce_app/utils/utils.dart';
import 'package:flutter/material.dart';

import 'package:uuid/uuid.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartItem> cartItems;

  const CheckoutScreen({super.key, required this.cartItems});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // Constants
  static const _defaultShippingMethod = 'Nhanh';
  static const _defaultPaymentMethod = 'Cash on Delivery';
  static const _orderPendingStatus = 'Chờ xác nhận';

  // Controllers
  final _addressController = TextEditingController();
  final _voucherController = TextEditingController();

  // Repositories
  final _userRepository = UserRepository();
  final _productRepository = ProductRepository();
  final _orderRepository = OrderRepository();
  final _cartRepository = CartRepository();
  final _addressRepository = AddressRepository();
  final _uuid = Uuid();
  final MailService _mailService = MailService();

  // State variables
  late List<CartItem> _cartItems;
  UserModel? _userModel;
  List<AddressModel> _addressList = [];
  List<ProductModel> _products = [];
  AddressModel? _selectedAddress;
  AddressModel? _selectedAddressGuest;

  String _selectedShippingMethod = _defaultShippingMethod;
  String _addressSelected = '';
  final String _paymentMethod = _defaultPaymentMethod;
  double _voucherDiscount = 0.0;
  String? _userID;

  final List<ShippingMethod> _shippingMethods = [
    ShippingMethod(
      name: 'Tiết kiệm',
      fee: 0.0,
      description: 'Đảm bảo nhận hàng trong 7 đến 10 ngày',
      icon: Icons.delivery_dining_outlined,
    ),
    ShippingMethod(
      name: 'Nhanh',
      fee: 50000.0,
      description: 'Đảm bảo nhận hàng trong 3 đến 5 ngày',
      icon: Icons.local_shipping_outlined,
    ),
    ShippingMethod(
      name: 'Hỏa tốc',
      fee: 100000.0,
      description: 'Đảm bảo nhận hàng vào ngày hôm sau',
      icon: Icons.flight_takeoff_outlined,
    ),
  ];

  final UserVoucherRepository _userVoucherRepo = UserVoucherRepository();
  final VoucherRepository _voucherRepo = VoucherRepository();
  final UserRepository _userRepo = UserRepository();

  List<VoucherModel> _userVouchers = [];
  VoucherModel? _selectedVoucher;
  bool _isLoadingVouchers = false;

  // Thêm các biến mới
  bool _isUsingPoints = false;
  int _maxPointsCanUse = 0;
  int _pointsToUse = 0;

  double _calculatedTotal = 0.0;

  bool _isPlacingOrder = false;

  double get _totalCartPrice => _cartItems.fold(
    0.0,
    (total, item) =>
        total +
        ((item.discountRate > 0)
            ? item.priceAfterDiscount! * item.quantity
            : item.price * item.quantity),
  );
  double get _shippingFee =>
      _shippingMethods
          .firstWhere(
            (m) => m.name == _selectedShippingMethod,
            orElse: () => _shippingMethods.first,
          )
          .fee;

  double get _totalPayment => _calculatedTotal;

  @override
  void initState() {
    super.initState();
    _cartItems = widget.cartItems;
    _initializeShippingMethod();
    _fetchUser();
    _loadUserVouchers();
    _calculateMaxPoints();
    _updateTotalPayment();
    _selectedGuestAddress();
    _loadProductsForCart();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _voucherController.dispose();
    super.dispose();
  }

  void _selectedGuestAddress() async {
    final userId = await _userRepo.getEffectiveUserId();

    final address = await _addressRepository.getAddressesByUserId(userId);
    if (address.isEmpty) return;
    if (!_userRepo.isUserId(userId)) {
      setState(() {
        _selectedAddressGuest = address.firstWhere(
          (address) => address.isDefault,
        );
      });
    }
  }

  void _applyVoucher(VoucherModel voucher) {
    setState(() {
      _selectedVoucher = voucher;
      _voucherDiscount = voucher.discountAmount;
      _updateTotalPayment();
    });
  }

  void _initializeShippingMethod() {
    _selectedShippingMethod = _defaultShippingMethod;
  }

  Future<void> _sendOrderConfirmationEmail(
    String email,
    String name,
    String orderId,
    String total,
    List<ProductModel> products,
    String shippingFee,
    double pointsConversion,
  ) async {
    await _mailService.sendOrderConfirmationEmail(
      email,
      name,
      orderId,
      total,
      products,
      shippingFee,
      pointsConversion,
    );
  }

  Future<void> _fetchUser() async {
    final userId = await _userRepository.getEffectiveUserId();
    final user = await _userRepository.getUserDetails(userId);
    final addresses = await _addressRepository.getAddressesByUserId(userId);
    print(addresses.firstWhere((address) => address.isDefault).fullAddress);
    setState(() {
      _userID = userId;
      _userModel = user;
      _addressList = addresses;

      if (_userRepo.isUserId(userId)) {
        if (addresses.isNotEmpty) {
          final defaultAddress = addresses.firstWhere(
            (address) => address.isDefault,
            orElse: () => addresses.first,
          );
          _selectedAddress = defaultAddress;
          _addressSelected = defaultAddress.fullAddress;
          print(_addressSelected);
        }
      } else {
        final _selectedAddressGuest = addresses.firstWhere(
          (address) => address.isDefault,
          orElse: () => addresses.first,
        );
        _selectedAddress = _selectedAddressGuest;
        _addressSelected = _selectedAddressGuest!.fullAddress;
        print(_addressSelected);
      }
    });
  }

  Future<void> _chooseAddress() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => AddressScreen()),
    );

    if (result == true) {
      print("Chọn địa chỉ thành công");
      print("Đang tải lại thông tin người dùng");
      await _fetchUser();
    }
  }

  Future<void> _placeOrder() async {
    if (_selectedAddress == null) {
      _showErrorSnackBar('Vui lòng chọn địa chỉ giao hàng');
      return;
    }

    if (_userRepo.isUserId(await _userRepo.getEffectiveUserId())) {
      if (_addressList.isEmpty) {
        _showErrorSnackBar('Vui lòng nhập địa chỉ giao hàng');
        return;
      }
    }

    setState(() {
      _isPlacingOrder = true;
    });

    try {
      final orderId = _uuid.v4();
      final orderDetails = await _createOrderDetails();
      if (orderDetails == null) return;

      final order = _createOrder(orderId, orderDetails);
      await _processOrder(order);

      if (_selectedVoucher != null) {
        await _orderRepository.updateVoucherCode(
          order.id,
          _selectedVoucher!.id,
        );
      }
      _showSuccessDialog();
    } catch (e, stackTrace) {
      print('Đặt hàng thất bại: $e');
      print('Chi tiết lỗi: $stackTrace');
      _showErrorSnackBar('Đặt hàng thất bại: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isPlacingOrder = false;
        });
      }
    }
  }

  Future<List<OrderDetailsModel>?> _createOrderDetails() async {
    try {
      return await Future.wait(
        _cartItems.map((item) async {
          final product = await _productRepository.getProductById(
            item.productId,
          );
          if (product == null) throw Exception('Product not found');

          await _productRepository.updateProductStock(
            product.id!,
            item.quantity,
          );

          return OrderDetailsModel(
            product: product,
            quantity: item.quantity,
            orderId: _uuid.v4(),
            revenue:
                (item.price * (1 - item.discountRate / 100) - item.costPrice) *
                item.quantity,
          );
        }),
      );
    } catch (e) {
      _showErrorSnackBar('Lỗi xử lý chi tiết đơn hàng: ${e.toString()}');
      return null;
    }
  }

  OrderModel _createOrder(
    String orderId,
    List<OrderDetailsModel> orderDetails,
  ) {
    return OrderModel(
      id: orderId,
      customerId: _userID!,
      paymentMethod: _paymentMethod,
      customerEmail: _selectedAddress!.userMail,
      customerName: _selectedAddress!.userName,
      customerPhone: _selectedAddress!.userPhone,
      shippingMethod: _selectedShippingMethod,
      shippingFee: _shippingFee.toString(),
      shippingAddress: _selectedAddress!.fullAddress,
      orderDate: DateTime.now(),
      totalAmount: _totalPayment,
      status: _orderPendingStatus,
      orderDetails: orderDetails,
      revenue: orderDetails.fold(0, (sum, detail) => sum + detail.revenue),
    );
  }

  Future<void> _processOrder(OrderModel order) async {
    await _orderRepository.addOrder(order);
    await _processPoints(order.id, _pointsToUse.toDouble());

    await _sendOrderConfirmationEmail(
      _selectedAddress!.userMail,
      _selectedAddress!.userName,
      order.id,
      Utils.formatCurrency(_totalPayment),
      _products,
      order.shippingFee,
      _pointsToUse.toDouble() * 1000,
    );

    if (_selectedVoucher != null) {
      await _processVoucher(order.id);
    }

    if (_isUsingPoints && _pointsToUse > 0) {
      await _userRepo.subtractMembershipCurrentPoints(
        _userModel!.id!,
        _pointsToUse,
      );
    }

    try {
      if (_userRepo.isUserId(_userID!)) {
        await _cartRepository.removeSelectedItems(
          _userID!,
          _cartItems.map((item) => item.id).toList(),
        );
      } else {
        for (var item in _cartItems) {
          try {
            await _cartRepository.removeGuestCartItem(_userID!, item.id);
          } catch (e) {
            print('Không thể xóa item ${item.id}: $e');
            // Continue with next item even if this one fails
          }
        }
      }
    } catch (e) {
      print('Lỗi khi xóa items khỏi giỏ hàng: $e');
      // Don't throw exception here, as the order is already created
    }
  }

  Future<void> _processPoints(String orderid, double points) async {
    if (_isUsingPoints && _pointsToUse > 0) {
      await _orderRepository.updateConversionPoint(orderid, points * 1000);
    }
  }

  Future<void> _processVoucher(String orderId) async {
    await _voucherRepo.updateVoucherUsage(_selectedVoucher!.id, orderId);
    await _userVoucherRepo.updateVoucherUsageStatus(
      _userModel!.id!,
      _selectedVoucher!.id,
      true,
      orderId,
    );
    await _userRepo.subtractMembershipCurrentPoints(
      _userModel!.id!,
      _selectedVoucher!.pointNeeded,
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.of(context).pop();
          _navigateToSettings();
        });

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.check_circle, color: Colors.green, size: 50),
              SizedBox(height: 16),
              Text(
                'Đơn hàng đã được đặt thành công!',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToSettings() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SettingScreen()),
    );
  }

  Future<void> _loadUserVouchers() async {
    try {
      setState(() => _isLoadingVouchers = true);

      final userId = await _userRepo.getEffectiveUserId();

      final userVoucherList = await _userVoucherRepo.getUnusedUserVouchers(
        userId,
      );
      final userVoucherIds = userVoucherList.map((e) => e.voucherId).toList();

      final allVouchers = await _voucherRepo.getAllVouchers();
      final availableVouchers =
          allVouchers
              .where((v) => userVoucherIds.contains(v.id) && v.isValid)
              .toList();

      setState(() {
        _userVouchers = availableVouchers;
        _isLoadingVouchers = false;
      });
    } catch (e) {
      setState(() => _isLoadingVouchers = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tải voucher: $e')));
      }
    }
  }

  void _showVoucherDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Chọn Voucher',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_isLoadingVouchers)
                        const Center(child: CircularProgressIndicator())
                      else if (_userVouchers.isEmpty)
                        const Center(child: Text('Không có voucher khả dụng'))
                      else
                        Expanded(
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: _userVouchers.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (context, index) {
                              final voucher = _userVouchers[index];
                              final isSelected =
                                  _selectedVoucher?.id == voucher.id;
                              return ListTile(
                                selected: isSelected,
                                title: Text(voucher.code),
                                subtitle: Text(
                                  'Giảm ${Utils.formatCurrency(voucher.discountAmount)}',
                                ),
                                trailing: ElevatedButton(
                                  style: ButtonStyle(
                                    backgroundColor: WidgetStateProperty.all(
                                      Colors.blueAccent,
                                    ),
                                  ),
                                  onPressed: () {
                                    setState(() => _selectedVoucher = voucher);
                                    Navigator.pop(context);
                                    _applyVoucher(voucher);
                                  },
                                  child: const Text(
                                    'Áp dụng',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
          ),
    );
  }

  void _calculateMaxPoints() {
    if (_userModel == null) return;

    double baseTotal = _totalCartPrice + _shippingFee;
    if (_selectedVoucher != null) {
      baseTotal -= _selectedVoucher!.discountAmount;
    }
    baseTotal = max(0, baseTotal);

    _maxPointsCanUse = min(
      _userModel!.memberShipCurrentPoint ?? 0,
      (baseTotal / 1000).floor(),
    );

    if (_pointsToUse > _maxPointsCanUse) {
      _pointsToUse = _maxPointsCanUse;
    }
  }

  Widget _buildPointsSection() {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sử dụng điểm tích lũy',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Switch(
                  value: _isUsingPoints,
                  onChanged: (value) {
                    setState(() {
                      _isUsingPoints = value;
                      if (!value) {
                        _pointsToUse = 0;
                      } else {
                        _calculateMaxPoints();
                        _pointsToUse = _maxPointsCanUse;
                      }
                      _updateTotalPayment();
                    });
                  },
                  activeColor: const Color(0xFF7AE582),
                ),
              ],
            ),
            if (_isUsingPoints) ...[
              const SizedBox(height: 8),
              Text(
                'Điểm hiện có: ${_userModel!.memberShipCurrentPoint}',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                'Có thể sử dụng tối đa: $_maxPointsCanUse điểm (${Utils.formatCurrency(_maxPointsCanUse * 1000)})',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Slider(
                value: _pointsToUse.toDouble(),
                min: 0,
                max: _maxPointsCanUse.toDouble(),
                divisions: _maxPointsCanUse,
                label: '$_pointsToUse điểm',
                onChanged: (double value) {
                  setState(() {
                    _pointsToUse = value.round();
                    _updateTotalPayment();
                  });
                },
                activeColor: const Color(0xFF7AE582),
              ),
              Text(
                'Số điểm sử dụng: $_pointsToUse (${Utils.formatCurrency(_pointsToUse * 1000)})',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _updateTotalPayment() {
    double total = _totalCartPrice + _shippingFee;

    if (_selectedVoucher != null) {
      total -= _selectedVoucher!.discountAmount;
    }

    if (_isUsingPoints && _pointsToUse > 0) {
      total -= (_pointsToUse * 1000);
    }

    total = max(0, total);

    setState(() {
      _calculatedTotal = total;
    });
  }

  Future<void> _loadProductsForCart() async {
    try {
      final loadedProducts = await Future.wait(
        _cartItems.map((item) async {
          final product = await _productRepository.getProductById(
            item.productId,
          );
          if (product == null) throw Exception('Product not found');
          return product;
        }),
      );

      setState(() {
        _products = loadedProducts;
      });
    } catch (e) {
      print('Error loading products: $e');
      _showErrorSnackBar('Failed to load products: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAddressSection(),
              const SizedBox(height: 8),
              _buildProductsSection(),
              const SizedBox(height: 8),
              _buildShippingMethodSection(),
              const SizedBox(height: 8),
              if (_userModel != null) _buildVoucherSection(),
              const SizedBox(height: 8),
              if (_userModel != null && _userModel!.memberShipCurrentPoint! > 0)
                _buildPointsSection(),
              const SizedBox(height: 8),
              _buildPaymentDetailsSection(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Thanh toán'),
      backgroundColor: Colors.white,
      elevation: 1,
    );
  }

  Widget _buildAddressSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: _chooseAddress,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.blue),
                        const SizedBox(width: 12),
                        Text(
                          _selectedAddress?.userName ??
                              _userModel?.fullName ??
                              ' Tên người nhận chưa được thêm',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            _selectedAddress?.userPhone ??
                                'Số điện thoại chưa được thêm',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _addressSelected,
                      style: const TextStyle(fontSize: 14),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey,
              ), // Add arrow icon
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductsSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
            child: Text(
              'Sản phẩm',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.85,
              child: const Divider(),
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _cartItems.length,
            separatorBuilder:
                (context, index) => Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.8,
                    child: const Divider(),
                  ),
                ),
            itemBuilder: (context, index) {
              final item = _cartItems[index];
              return ListTile(
                leading: Image.network(
                  item.imageUrl!,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
                title: Text(
                  item.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  'Số lượng: ${item.quantity}',
                  style: const TextStyle(color: Colors.grey),
                ),
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      Utils.formatCurrency(
                        item.discountRate != null && item.discountRate! > 0
                            ? item.priceAfterDiscount! * item.quantity
                            : item.price * item.quantity,
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 4),
                    if (item.discountRate != null && item.discountRate! > 0)
                      Text(
                        Utils.formatCurrency(item.price * item.quantity),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildShippingMethodSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
            child: Text(
              'Phương thức vận chuyển',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.85,
              child: const Divider(),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _shippingMethods.length,
            itemBuilder: (context, index) {
              final method = _shippingMethods[index];
              return RadioListTile<String>(
                value: method.name,
                groupValue: _selectedShippingMethod,
                onChanged: (value) {
                  setState(() {
                    _selectedShippingMethod = value!;
                  });
                },
                title: Row(
                  children: [
                    Icon(method.icon),
                    const SizedBox(width: 8),
                    Text(method.name),
                  ],
                ),
                subtitle: Text(method.description),
                secondary: Text(
                  Utils.formatCurrency(method.fee),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.discount_outlined),
                const SizedBox(width: 8),
                const Text(
                  'Voucher giảm giá',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_selectedVoucher != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mã: ${_selectedVoucher!.code}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Giảm: ${Utils.formatCurrency(_selectedVoucher!.discountAmount)}',
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _selectedVoucher = null;
                          _voucherDiscount = 0;
                          _updateTotalPayment();
                        });
                      },
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _showVoucherDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  _selectedVoucher == null
                      ? 'Chọn Voucher'
                      : 'Thay đổi Voucher',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetailsSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chi tiết thanh toán',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildPaymentRow('Tổng tiền hàng', _totalCartPrice),
            _buildPaymentRow('Phí vận chuyển', _shippingFee),
            if (_voucherDiscount > 0)
              _buildPaymentRow('Voucher giảm giá', -_voucherDiscount),
            if (_isUsingPoints && _pointsToUse > 0)
              _buildPaymentRow(
                'Điểm quy đổi',
                -(_pointsToUse * 1000).toDouble(),
              ),
            const Divider(),
            _buildPaymentRow('Tổng thanh toán', _totalPayment, isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            Utils.formatCurrency(amount),
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.red : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tổng thanh toán', style: TextStyle(fontSize: 14)),
                Text(
                  Utils.formatCurrency(_totalPayment),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _isPlacingOrder ? null : _placeOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child:
                _isPlacingOrder
                    ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                    : const Text(
                      'Đặt hàng',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
          ),
        ],
      ),
    );
  }
}

class ShippingMethod {
  final String name;
  final double fee;
  final String description;
  final IconData icon;

  const ShippingMethod({
    required this.name,
    required this.fee,
    required this.description,
    required this.icon,
  });
}
