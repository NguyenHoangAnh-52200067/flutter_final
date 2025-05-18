// import 'package:ecommerce_app/utils/utils.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:uuid/uuid.dart';
// import '../../models/voucher_model.dart';
// import '../../repository/voucher_repository.dart';

// class AddVoucherScreen extends StatefulWidget {
//   const AddVoucherScreen({super.key});

//   @override
//   State<AddVoucherScreen> createState() => _AddVoucherScreenState();
// }

// class _AddVoucherScreenState extends State<AddVoucherScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _codeController = TextEditingController();
//   final VoucherRepository _voucherRepo = VoucherRepository();
//   final Uuid _uuid = Uuid();
//   double _selectedAmount = 10000;
//   int _maxUsage = 10;
//   int _pointNeeded = 10;
//   bool _isLoading = false;

//   final Map<double, int> _discountAmountsWithPoints = {
//     10000: 10,
//     20000: 20,
//     50000: 50,
//     100000: 100,
//   };

//   @override
//   void dispose() {
//     _codeController.dispose();
//     super.dispose();
//   }

//   Future<void> _saveVoucher() async {
//     if (!_formKey.currentState!.validate()) return;

//     setState(() => _isLoading = true);

//     try {
//       final voucher = VoucherModel(
//         id: _uuid.v4(),
//         code: _codeController.text.toUpperCase(),
//         discountAmount: _selectedAmount,
//         maxUsage: _maxUsage,
//         pointNeeded: _pointNeeded,
//         createdAt: DateTime.now(),
//       );

//       await _voucherRepo.addVoucher(voucher);

//       if (mounted) {
//         Navigator.pop(context, true);
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text(e.toString())));
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Thêm Voucher'),
//         backgroundColor: const Color(0xFF7AE582),
//       ),
//       body: Form(
//         key: _formKey,
//         child: ListView(
//           padding: const EdgeInsets.all(16),
//           children: [
//             TextFormField(
//               controller: _codeController,
//               textCapitalization: TextCapitalization.characters,
//               maxLength: 5,
//               style: const TextStyle(fontSize: 16),
//               decoration: InputDecoration(
//                 labelText: 'Mã voucher',
//                 prefixIcon: const Icon(Icons.discount),
//                 hintText: 'Nhập mã voucher',
//                 hintStyle: const TextStyle(color: Colors.grey, fontSize: 16),
//                 border: const OutlineInputBorder(),
//                 contentPadding: const EdgeInsets.symmetric(
//                   vertical: 16,
//                   horizontal: 12,
//                 ),
//               ),
//               inputFormatters: [
//                 FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
//                 LengthLimitingTextInputFormatter(5),
//               ],
//               validator: (value) {
//                 if (value == null || value.length != 5) {
//                   return 'Mã voucher phải có đúng 5 ký tự';
//                 }
//                 return null;
//               },
//             ),
//             const SizedBox(height: 16),
//             const Text(
//               'Giá trị giảm và điểm tích lũy cần thiết:',
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 8),
//             Wrap(
//               spacing: 8,
//               runSpacing: 12,
//               children:
//                   _discountAmountsWithPoints.entries.map((entry) {
//                     return ChoiceChip(
//                       selectedColor: Colors.blueAccent,
//                       checkmarkColor: Colors.white,
//                       label: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Text(
//                             Utils.formatCurrency(entry.key),
//                             style: TextStyle(
//                               fontSize: 16,
//                               color:
//                                   _selectedAmount == entry.key
//                                       ? Colors.white
//                                       : Colors.black,
//                             ),
//                           ),
//                           Text(
//                             '${entry.value} điểm',
//                             style: TextStyle(
//                               fontSize: 12,
//                               color:
//                                   _selectedAmount == entry.key
//                                       ? Colors.white
//                                       : Colors.black,
//                             ),
//                           ),
//                         ],
//                       ),
//                       selected: _selectedAmount == entry.key,
//                       onSelected: (selected) {
//                         if (selected) {
//                           setState(() {
//                             _selectedAmount = entry.key;
//                             _pointNeeded = entry.value;
//                           });
//                         }
//                       },
//                     );
//                   }).toList(),
//             ),
//             const SizedBox(height: 24),
//             const Text(
//               'Số lần sử dụng tối đa:',
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//             ),
//             Slider(
//               value: _maxUsage.toDouble(),
//               min: 1,
//               max: 10,
//               divisions: 9,
//               label: _maxUsage.toString(),
//               activeColor: Colors.blue,
//               onChanged: (value) {
//                 setState(() => _maxUsage = value.toInt());
//               },
//             ),
//             Text(
//               'Số lần sử dụng tối đa: $_maxUsage',
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 32),
//             ElevatedButton(
//               onPressed: _isLoading ? null : _saveVoucher,

//               style: ElevatedButton.styleFrom(
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//                 backgroundColor: Colors.blue,
//               ),
//               child:
//                   _isLoading
//                       ? const CircularProgressIndicator()
//                       : const Text(
//                         'Tạo Voucher',
//                         style: TextStyle(fontSize: 18, color: Colors.white),
//                       ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:ecommerce_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../../models/voucher_model.dart';
import '../../repository/voucher_repository.dart';

class AddVoucherScreen extends StatefulWidget {
  const AddVoucherScreen({super.key});

  @override
  State<AddVoucherScreen> createState() => _AddVoucherScreenState();
}

class _AddVoucherScreenState extends State<AddVoucherScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final VoucherRepository _voucherRepo = VoucherRepository();
  final Uuid _uuid = Uuid();
  double _selectedAmount = 10000;
  int _maxUsage = 10;
  int _pointNeeded = 10;
  bool _isLoading = false;

  final Map<double, int> _discountAmountsWithPoints = {
    10000: 10,
    20000: 20,
    50000: 50,
    100000: 100,
  };

  // Thêm AnimationController cho hiệu ứng fade và scale
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _saveVoucher() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final voucher = VoucherModel(
        id: _uuid.v4(),
        code: _codeController.text.toUpperCase(),
        discountAmount: _selectedAmount,
        maxUsage: _maxUsage,
        pointNeeded: _pointNeeded,
        createdAt: DateTime.now(),
      );

      await _voucherRepo.addVoucher(voucher);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Thêm Voucher',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue, // Màu xanh dương
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 5,
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                  decoration: InputDecoration(
                    labelText: 'Mã voucher',
                    prefixIcon: const Icon(Icons.discount, color: Colors.blue),
                    hintText: 'Nhập mã voucher',
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 16),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 12,
                    ),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                    LengthLimitingTextInputFormatter(5),
                  ],
                  validator: (value) {
                    if (value == null || value.length != 5) {
                      return 'Mã voucher phải có đúng 5 ký tự';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Giá trị giảm và điểm tích lũy cần thiết:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 12,
                  children: _discountAmountsWithPoints.entries.map((entry) {
                    return ChoiceChip(
                      selectedColor: Colors.blue,
                      checkmarkColor: Colors.white,
                      label: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            Utils.formatCurrency(entry.key),
                            style: TextStyle(
                              fontSize: 16,
                              color: _selectedAmount == entry.key ? Colors.white : Colors.black54,
                            ),
                          ),
                          Text(
                            '${entry.value} điểm',
                            style: TextStyle(
                              fontSize: 12,
                              color: _selectedAmount == entry.key ? Colors.white : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      selected: _selectedAmount == entry.key,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedAmount = entry.key;
                            _pointNeeded = entry.value;
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Số lần sử dụng tối đa:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                Slider(
                  value: _maxUsage.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: _maxUsage.toString(),
                  activeColor: Colors.blue,
                  inactiveColor: Colors.blue.shade100,
                  thumbColor: Colors.blue,
                  overlayColor: MaterialStateProperty.all(Colors.blue.withOpacity(0.2)),
                  onChanged: (value) {
                    setState(() => _maxUsage = value.toInt());
                  },
                ),
                Text(
                  'Số lần sử dụng tối đa: $_maxUsage',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 32),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveVoucher,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: _isLoading ? 0 : 4,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.add, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Tạo Voucher',
                                style: TextStyle(fontSize: 18, color: Colors.white),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}