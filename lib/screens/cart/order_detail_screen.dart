import 'package:ecommerce_app/models/order_model.dart';
import 'package:ecommerce_app/models/product_model.dart';
import 'package:ecommerce_app/models/voucher_model.dart';
import 'package:ecommerce_app/repository/voucher_repository.dart';
import 'package:ecommerce_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderDetailScreen extends StatefulWidget {
  final OrderModel order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen>
    with SingleTickerProviderStateMixin {
  final VoucherRepository _voucherRepository = VoucherRepository();
  VoucherModel? voucher;
  late OrderModel order;

  // Khởi tạo animation controller
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    order = widget.order;
    _loadVoucher();

    // Khởi tạo animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

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
    _animationController.dispose();
    super.dispose();
  }

  double getTotalPayment(
    double totalAmount,
    String shippingFee,
    VoucherModel? voucher,
    double? conversionPoint,
  ) {
    double totalPayment = totalAmount - double.parse(shippingFee);
    if (voucher != null) {
      totalPayment -= voucher.discountAmount;
    }
    if (conversionPoint != null && conversionPoint != 0) {
      totalPayment -= conversionPoint;
    }
    return totalPayment;
  }

  void _loadVoucher() {
    if (order.voucherCode != null) {
      _voucherRepository.getVoucherById(order.voucherCode!).then((value) {
        setState(() {
          voucher = value;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Chi tiết đơn hàng',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    _buildOrderInfo(context),
                    const SizedBox(height: 12),
                    _buildDeliveryInfo(context),
                    const SizedBox(height: 12),
                    _buildProductList(context),
                    const SizedBox(height: 12),
                    _buildPaymentInfo(context),
                    const SizedBox(height: 12),
                    if (order.status == 'Đã giao')
                      _buildOrderDeliveryInfo(context),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderInfo(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.shade300), // Viền xanh nhạt
      ),
      color: Colors.white,
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(order.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                order.status,
                style: TextStyle(
                  color: _getStatusColor(order.status),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mã đơn hàng: #${order.id}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                    overflow: TextOverflow.ellipsis,
                  ),
                  maxLines: 1,
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Ngày đặt: ${DateFormat('dd/MM/yyyy HH:mm').format(order.orderDate)}',
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryInfo(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.shade300), // Viền xanh nhạt
      ),
      color: Colors.white,
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_shipping_outlined,
                  color: Colors.blue,
                ), // Màu xanh dương
                const SizedBox(width: 8),
                Text(
                  'Thông tin giao hàng',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700, // Màu xanh đậm
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Người nhận', order.customerName),
            const SizedBox(height: 8),
            _buildInfoRow('Số điện thoại', order.customerPhone),
            const SizedBox(height: 8),
            _buildInfoRow('Địa chỉ', order.shippingAddress),
            const SizedBox(height: 8),
            _buildInfoRow('Phương thức vận chuyển', order.shippingMethod),
          ],
        ),
      ),
    );
  }

  Widget _buildProductList(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.shade300), // Viền xanh nhạt
      ),
      color: Colors.white,
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  color: Colors.blue,
                ), // Màu xanh dương
                const SizedBox(width: 8),
                Text(
                  'Sản phẩm (${order.orderDetails.length})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700, // Màu xanh đậm
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...order.orderDetails.map(
              (detail) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          detail.product.images.first,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              detail.product.productName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.black,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'x${detail.quantity}',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(children: [_buildProductPrice(detail.product)]),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInfo(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.shade300), // Viền xanh nhạt
      ),
      color: Colors.white,
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payment, color: Colors.blue), // Màu xanh dương
                const SizedBox(width: 8),
                Text(
                  'Thông tin thanh toán',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700, // Màu xanh đậm
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Phương thức thanh toán: ',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
                Text(
                  order.paymentMethod,
                  style: TextStyle(
                    color: Colors.black, // Màu xanh đậm
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (order.voucherCode == null)
              _buildPriceRow(
                'Tổng tiền hàng',
                getTotalPayment(
                  order.totalAmount,
                  order.shippingFee,
                  voucher,
                  order.conversionPoint ?? 0,
                ),
              ),
            const SizedBox(height: 8),
            if (order.voucherCode != null && voucher != null) ...[
              _buildPriceRow(
                'Tổng tiền hàng',
                order.totalAmount -
                    (order.conversionPoint ?? 0) -
                    double.parse(order.shippingFee) -
                    voucher!.discountAmount,
              ),
              const SizedBox(height: 8),
              _buildPriceRow(
                'Giảm giá',
                voucher!.discountAmount,
                isDiscount: true,
              ),
              const SizedBox(height: 8),
            ],
            if (order.conversionPoint != null) ...[
              _buildPriceRow('Điểm quy đổi', order.conversionPoint!),
              const SizedBox(height: 8),
            ],
            _buildPriceRow('Phí vận chuyển', double.parse(order.shippingFee)),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(thickness: 1, color: Colors.blue.shade300),
            ),
            _buildPriceRow('Tổng thanh toán', order.totalAmount, isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 150,
          child: Text(label, style: TextStyle(color: Colors.black54)),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black),
          ),
        ),
      ],
    );
  }

  Widget _buildDateRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: Colors.black54),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: true,
          ),
        ),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black),
        ),
      ],
    );
  }

  Widget _buildPriceRow(
    String label,
    double amount, {
    bool isTotal = false,
    bool isDiscount = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? Colors.black : Colors.black54,
          ),
        ),
        Text(
          isDiscount
              ? "-${Utils.formatCurrency(amount)}"
              : Utils.formatCurrency(amount),
          style: TextStyle(
            fontSize: isTotal ? 18 : 15,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color:
                isDiscount
                    ? Colors.green
                    : (isTotal ? Colors.black : Colors.black),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'chờ xác nhận':
        return Colors.orange;
      case 'chờ giao hàng':
        return Colors.blue;
      case 'đang giao':
        return Colors.purple;
      case 'đã giao':
        return Colors.green;
      case 'đã hủy':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildOrderDeliveryInfo(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.shade300), // Viền xanh nhạt
      ),
      color: Colors.white,
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_box, color: Colors.blue), // Màu xanh dương
                const SizedBox(width: 8),
                Text(
                  'Chi tiết đơn hàng',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black, // Màu xanh đậm
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDateRow('Mã đơn hàng', order.id),
            const SizedBox(height: 14),
            _buildDateRow(
              'Ngày đặt hàng',
              DateFormat(
                'dd/MM/yyyy HH:mm a',
              ).format(order.orderDate).toString(),
            ),
            if (order.acceptDate != null) ...[
              const SizedBox(height: 14),
              _buildDateRow(
                'Ngày vận chuyển',
                DateFormat(
                  'dd/MM/yyyy HH:mm a',
                ).format(order.shippingDate!).toString(),
              ),
              const SizedBox(height: 14),
              _buildDateRow(
                'Ngày giao hàng',
                DateFormat(
                  'dd/MM/yyyy HH:mm a',
                ).format(order.deliveryDate!).toString(),
              ),
              const SizedBox(height: 14),
              _buildDateRow(
                'Ngày thanh toán',
                DateFormat(
                  'dd/MM/yyyy HH:mm a',
                ).format(order.paymentDate!).toString(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Widget _buildProductPrice(ProductModel product) {
  final hasDiscount = product.discount > 0;
  final discountedPrice =
      product.price - (product.price * product.discount / 100);

  return Row(
    children: [
      if (hasDiscount) ...[
        Text(
          Utils.formatCurrency(discountedPrice),
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          Utils.formatCurrency(product.price),
          style: TextStyle(
            color: Colors.black54,
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.lineThrough,
            decorationColor: const Color.fromARGB(137, 54, 53, 53),
          ),
        ),
      ] else
        Text(
          Utils.formatCurrency(product.price),
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
    ],
  );
}
