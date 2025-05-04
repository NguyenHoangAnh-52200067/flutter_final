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
    extends State<AdminVoucherManagementScreen> {
  static const int _vouchersPerPage = 20;
  final VoucherRepository _voucherRepo = VoucherRepository();
  List<VoucherModel> _vouchers = [];
  List<VoucherModel> _filteredVouchers = [];
  bool _isLoading = false;
  int _currentPage = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _loadVouchers();
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
    final startIndex = (_currentPage - 1) * _vouchersPerPage;
    final endIndex = min(
      startIndex + _vouchersPerPage,
      _filteredVouchers.length,
    );

    if (startIndex >= _filteredVouchers.length) return [];
    return _filteredVouchers.sublist(startIndex, endIndex);
  }

  Widget _buildPagination() {
    return Row(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Voucher'),
        backgroundColor: const Color(0xFF7AE582),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _loadVouchers,
                      child: ListView.builder(
                        itemCount: _paginatedVouchers.length,
                        padding: const EdgeInsets.all(8),
                        itemBuilder:
                            (context, index) =>
                                _buildVoucherCard(_paginatedVouchers[index]),
                      ),
                    ),
                  ),
                  _buildPagination(),
                ],
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddVoucherScreen()),
          );
          if (result == true) {
            _loadVouchers();
          }
        },
        child: const Icon(Icons.add),
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
            return AlertDialog(
              title: const Text('Xác nhận xóa'),
              content: Text(
                'Bạn có chắc chắn muốn xóa voucher ${voucher.code}?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Hủy'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Xóa', style: TextStyle(color: Colors.red)),
                ),
              ],
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
        child: ExpansionTile(
          title: Text(
            'Mã: ${voucher.code}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                'Giảm: ${Utils.formatCurrency(voucher.discountAmount)}',
                style: const TextStyle(
                  color: Colors.red,
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
              padding: const EdgeInsets.only(top: 16, bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ngày tạo: ${DateFormat('dd/MM/yyyy HH:mm a').format(voucher.createdAt)}',
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Đơn hàng đã sử dụng:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (voucher.usedOrderIds.isEmpty)
                    const Text('Chưa có đơn hàng nào sử dụng')
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:
                          voucher.usedOrderIds
                              .map((orderId) => Text('- Đơn hàng: $orderId'))
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
