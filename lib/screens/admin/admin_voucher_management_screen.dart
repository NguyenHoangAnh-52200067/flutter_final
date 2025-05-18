import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/voucher_model.dart';
import '../../repository/voucher_repository.dart';
import '../../utils/utils.dart';
import 'add_voucher_screen.dart';

class AdminVoucherManagementScreen extends StatefulWidget {
  const AdminVoucherManagementScreen({super.key});

  @override
  State<AdminVoucherManagementScreen> createState() =>
      _AdminVoucherManagementScreenState();
}

class _AdminVoucherManagementScreenState
    extends State<AdminVoucherManagementScreen>
    with SingleTickerProviderStateMixin {
  static const int _vouchersPerPage = 20;
  final VoucherRepository _voucherRepo = VoucherRepository();
  List<VoucherModel> _vouchers = [];
  List<VoucherModel> _filteredVouchers = [];
  bool _isLoading = false;
  int _currentPage = 1;
  int _totalPages = 1;

  // Thêm AnimationController cho hiệu ứng fade, scale, và slide
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadVouchers();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutSine,
      ),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutSine,
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutSine,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadVouchers() async {
    setState(() => _isLoading = true);
    try {
      _vouchers = await _voucherRepo.getAllVouchers();
      _vouchers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      setState(() {
        _filteredVouchers = _vouchers;
        _updateTotalPages();
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
      setState(() => _isLoading = false);
    }
  }

  void _updateTotalPages() {
    _totalPages = (_filteredVouchers.length / _vouchersPerPage).ceil();
    if (_currentPage > _totalPages) {
      _currentPage = _totalPages;
    }
    if (_totalPages == 0) {
      _totalPages = 1;
    }
  }

  List<VoucherModel> get _paginatedVouchers {
    if (_filteredVouchers.isEmpty) return [];

    final startIndex = max(0, (_currentPage - 1) * _vouchersPerPage);
    final endIndex = min(
      startIndex + _vouchersPerPage,
      _filteredVouchers.length,
    );

    return _filteredVouchers.sublist(startIndex, endIndex);
  }

  Widget _buildPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          child: IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.blue),
            onPressed:
                _currentPage > 1 ? () => setState(() => _currentPage--) : null,
            color: _currentPage > 1 ? Colors.blue : Colors.grey,
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Trang $_currentPage/$_totalPages',
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          child: IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.blue),
            onPressed:
                _currentPage < _totalPages
                    ? () => setState(() => _currentPage++)
                    : null,
            color: _currentPage < _totalPages ? Colors.blue : Colors.grey,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quản lý Voucher',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.blue, // Màu xanh dương
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child:
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(color: Colors.blue),
                    )
                    : _filteredVouchers.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: ScaleTransition(
                              scale: _scaleAnimation,
                              child: const Icon(
                                Icons.local_offer_outlined,
                                size: 64,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: const Text(
                              'Không có voucher nào',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            child: ElevatedButton(
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => const AddVoucherScreen(),
                                  ),
                                );
                                if (result == true) {
                                  _loadVouchers();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.add, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    'Thêm voucher mới',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                    : Column(
                      children: [
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _loadVouchers,
                            color: Colors.blue,
                            child: ListView.builder(
                              itemCount: _paginatedVouchers.length,
                              padding: const EdgeInsets.all(8),
                              itemBuilder:
                                  (context, index) => FadeTransition(
                                    opacity: _fadeAnimation,
                                    child: ScaleTransition(
                                      scale: _scaleAnimation,
                                      child: _buildVoucherCard(
                                        _paginatedVouchers[index],
                                      ),
                                    ),
                                  ),
                            ),
                          ),
                        ),
                        _buildPagination(),
                      ],
                    ),
          ),
        ),
      ),
      floatingActionButton: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: FloatingActionButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddVoucherScreen(),
                ),
              );
              if (result == true) {
                _loadVouchers();
              }
            },
            backgroundColor: Colors.blue,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildVoucherCard(VoucherModel voucher) {
    return Dismissible(
      key: Key(voucher.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  backgroundColor: Colors.white,
                  title: const Text(
                    'Xác nhận xóa',
                    style: TextStyle(color: Colors.black87),
                  ),
                  content: Text(
                    'Bạn có chắc chắn muốn xóa voucher ${voucher.code}?',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(foregroundColor: Colors.blue),
                      child: const Text('Hủy', style: TextStyle(fontSize: 16)),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                          backgroundColor: Colors.red.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Xóa',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      onDismissed: (direction) async {
        try {
          await _voucherRepo.deleteVoucher(voucher.id);
          setState(() {
            _vouchers.remove(voucher);
          });
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Voucher đã được xóa thành công'),
              backgroundColor: Colors.green,
            ),
          );
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Không thể xóa voucher: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.blue.shade100),
        ),
        elevation: 3,
        child: ExpansionTile(
          title: Text(
            'Mã: ${voucher.code}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                'Giảm: ${Utils.formatCurrency(voucher.discountAmount)}',
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Đã dùng: ${voucher.currentUsage}/${voucher.maxUsage}',
                style: TextStyle(
                  color: voucher.isValid ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: 16,
                bottom: 16,
                left: 16,
                right: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ngày tạo: ${DateFormat('dd/MM/yyyy HH:mm a').format(voucher.createdAt)}',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Đơn hàng đã sử dụng:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  if (voucher.usedOrderIds.isEmpty)
                    const Text(
                      'Chưa có đơn hàng nào sử dụng',
                      style: TextStyle(color: Colors.black54),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:
                          voucher.usedOrderIds
                              .map(
                                (orderId) => Text(
                                  '- Đơn hàng: $orderId',
                                  style: const TextStyle(color: Colors.black54),
                                ),
                              )
                              .toList(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
