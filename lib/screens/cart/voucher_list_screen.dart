import 'package:ecomerce_app/home.dart';
import 'package:ecomerce_app/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:ecomerce_app/models/voucher_model.dart';
import 'package:ecomerce_app/models/user_voucher_model.dart';
import 'package:ecomerce_app/repository/user_voucher_repository.dart';
import 'package:ecomerce_app/repository/user_repository.dart';
import 'package:ecomerce_app/utils/utils.dart';
import 'package:uuid/uuid.dart';

class VoucherListScreen extends StatefulWidget {
  final List<VoucherModel> vouchers;
  final bool showSaveButton;

  const VoucherListScreen({
    super.key,
    required this.vouchers,
    this.showSaveButton = true,
  });

  @override
  State<VoucherListScreen> createState() => _VoucherListScreenState();
}

class _VoucherListScreenState extends State<VoucherListScreen> {
  final UserVoucherRepository _userVoucherRepo = UserVoucherRepository();
  final UserRepository _userRepo = UserRepository();
  final _uuid = const Uuid();
  UserModel? _userModel;

  List<VoucherModel> _vouchers = [];

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        Future.delayed(const Duration(seconds: 2), () {
          if (context.mounted) Navigator.of(context).pop();
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
              Text('Lưu voucher thành công!', style: TextStyle(fontSize: 16)),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveVoucher(VoucherModel voucher) async {
    // final userId = _userRepo.getCurrentUserId();
    final userId = await _userRepo.getEffectiveUserId();
    UserModel? user = await _userRepo.getUserDetails(userId);
    try {
      final hasSaved = await _userVoucherRepo.hasUserSavedVoucher(
        userId,
        voucher.id,
      );

      if (hasSaved) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bạn đã lưu voucher này rồi')),
        );
        return;
      }
      final userVoucher = UserVoucherModel(
        id: _uuid.v4(),
        userId: userId,
        voucherId: voucher.id,
        voucherCode: voucher.code,
        isUsed: false,
      );
      final confirmSave = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Xác nhận'),
            content: Text(
              'Bạn có muốn đổi ${voucher.pointNeeded} điểm để lấy voucher này không?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Đồng ý'),
              ),
            ],
          );
        },
      );

      if (confirmSave != true) return;

      if (user!.memberShipCurrentPoint! < voucher.pointNeeded) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Bạn không đủ điểm để đổi voucher này. Điểm hiện tại của bạn là ${_userModel!.memberShipCurrentPoint!}',
            ),
          ),
        );
        return;
      }
      if (confirmSave == true &&
          user.memberShipCurrentPoint! > voucher.pointNeeded) {
        await _userVoucherRepo.addUserVoucher(userVoucher);
        await _userRepo.subtractMembershipCurrentPoints(
          _userModel!.id!,
          voucher.pointNeeded,
        );
        if (!mounted) return;
        _showSuccessDialog();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _loadUser() async {
    // final userId = _userRepo.getCurrentUserId();
    final userId = await _userRepo.getEffectiveUserId();

    final user = await _userRepo.getUserDetails(userId);
    if (user == null) return;

    if (mounted) {
      setState(() {
        _userModel = user;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUser();
    _vouchers = widget.vouchers;
  }

  Widget _buildVoucherItem(VoucherModel voucher) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 110,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF00BFA5),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.discount_outlined, color: Colors.white, size: 24),
                SizedBox(height: 4),
                Text(
                  "Giảm giá",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Mã: ${voucher.code}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Giảm ${Utils.formatCurrency(voucher.discountAmount)}",
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Đã sử dụng: ${voucher.currentUsage}/${voucher.maxUsage}",
                    style: TextStyle(
                      color: voucher.isValid ? Colors.green : Colors.red,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Điểm cần để đổi: ${voucher.pointNeeded} điểm",
                    style: TextStyle(color: Colors.green, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),

          if (widget.showSaveButton) ...[
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ElevatedButton(
                onPressed: voucher.isValid ? () => _saveVoucher(voucher) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00BFA5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text("Lưu"),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Danh sách Voucher',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF00BFA5),
        leading: IconButton(
          onPressed:
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen()),
              ),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),

      body:
          _vouchers.isEmpty
              ? const Center(child: Text('Không có voucher nào'))
              : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _vouchers.length,
                separatorBuilder:
                    (context, index) => const SizedBox(height: 16),
                itemBuilder:
                    (context, index) => _buildVoucherItem(_vouchers[index]),
              ),
    );
  }
}
