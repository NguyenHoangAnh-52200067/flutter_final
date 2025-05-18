import 'package:ecommerce_app/models/user_model.dart';
import 'package:ecommerce_app/models/user_voucher_model.dart';
import 'package:ecommerce_app/models/voucher_model.dart';
import 'package:ecommerce_app/repository/user_repository.dart';
import 'package:ecommerce_app/repository/user_voucher_repository.dart';
import 'package:ecommerce_app/repository/voucher_repository.dart';
import 'package:ecommerce_app/screens/cart/voucher_list_screen.dart';
import 'package:ecommerce_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class VoucherWidget extends StatefulWidget {
  const VoucherWidget({super.key});

  @override
  State<VoucherWidget> createState() => _VoucherWidgetState();
}

class _VoucherWidgetState extends State<VoucherWidget> {
  final VoucherRepository _voucherRepo = VoucherRepository();
  final UserRepository _userRepository = UserRepository();
  final UserVoucherRepository _userVoucherRepo = UserVoucherRepository();
  final Uuid _uuid = Uuid();

  List<VoucherModel> _vouchers = [];
  VoucherModel? _voucherModel;

  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadVouchers();
  }

  Future<void> _loadUser() async {
    final userId = await _userRepository.getEffectiveUserId();
    final user = await _userRepository.getUserDetails(userId);
    if (user == null) return;

    if (mounted) {
      setState(() {
        _user = user;
      });
    }
  }

  Future<void> _loadVouchers() async {
    try {
      _vouchers = await _voucherRepo.getAllVouchers();
      _vouchers.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (_vouchers.isEmpty) return;
      _voucherModel =
          _vouchers.where((voucher) => voucher.currentUsage < 5).first;
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null || _voucherModel == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.blue.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "VOUCHER DÀNH CHO BẠN",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade50, // Bóng xanh nhạt
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          bottomLeft: Radius.circular(6),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            "Giảm giá",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Icon(Icons.discount_outlined, color: Colors.white),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "GIẢM ${Utils.formatCurrency(_voucherModel!.discountAmount)}",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              "Áp dụng cho đơn tối thiểu 0đ",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            UserVoucherModel userVoucher = UserVoucherModel(
                              id: _uuid.v4(),
                              userId: _user!.id!,
                              voucherId: _voucherModel!.id,
                              voucherCode: _voucherModel!.code,
                              isUsed: false,
                            );

                            final hasSaved = await _userVoucherRepo
                                .hasUserSavedVoucher(
                                  _user!.id!,
                                  _voucherModel!.id,
                                );

                            if (hasSaved) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Bạn đã lưu voucher này rồi'),
                                ),
                              );
                              return;
                            }

                            await _userVoucherRepo.addUserVoucher(userVoucher);
                            if (!mounted) return;
                            _showSuccessDialog();
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue, // Nút xanh dương
                          minimumSize: const Size(50, 30),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: const Text(
                          "Lưu",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: -8,
            right: 0,
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => VoucherListScreen(vouchers: _vouchers),
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor:
                    Colors.blue, // Văn bản và biểu tượng xanh dương
              ),
              child: Row(
                children: const [
                  Text("Xem tất cả", style: TextStyle(fontSize: 12)),
                  Icon(Icons.arrow_right_sharp, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

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
          backgroundColor: Colors.white, // Nền trắng cho dialog
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(
                Icons.check_circle,
                color: Colors.blue,
                size: 50,
              ), // Icon xanh dương
              SizedBox(height: 16),
              Text(
                'Lưu voucher thành công!',
                style: TextStyle(fontSize: 16, color: Colors.blue),
              ),
            ],
          ),
        );
      },
    );
  }
}
