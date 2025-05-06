import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:ecomerce_app/repository/address_repository.dart';
import 'package:ecomerce_app/screens/widgets/dialogs/update_user_profile_dialog.dart';
import 'package:flutter/material.dart';
import 'package:ecomerce_app/models/user_model.dart';
import 'package:ecomerce_app/repository/user_repository.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() =>
      _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  static const int _usersPerPage = 20;
  final UserRepository _userRepository = UserRepository();
  final AddressRepository _addressRepository = AddressRepository();
  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoading = true;
  int _currentPage = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _userRepository.getAllUsers();
      setState(() {
        _users = users;
        _filteredUsers = users;
        _updateTotalPages();
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải danh sách người dùng: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  void _updateTotalPages() {
    _totalPages = (_filteredUsers.length / _usersPerPage).ceil();
    if (_currentPage > _totalPages) {
      _currentPage = _totalPages;
    }
    if (_totalPages == 0) {
      _totalPages = 1;
    }
  }

  void _filterUsers(String query) {
    setState(() {
      _filteredUsers =
          _users.where((user) {
            final fullNameLower = user.fullName.toLowerCase();
            final emailLower = user.email.toLowerCase();
            final searchLower = query.toLowerCase();
            return fullNameLower.contains(searchLower) ||
                emailLower.contains(searchLower);
          }).toList();
      _currentPage = 1;
      _updateTotalPages();
    });
  }

  List<UserModel> get _paginatedUsers {
    final startIndex = (_currentPage - 1) * _usersPerPage;
    final endIndex = min(startIndex + _usersPerPage, _filteredUsers.length);

    if (startIndex >= _filteredUsers.length) return [];
    return _filteredUsers.sublist(startIndex, endIndex);
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Trang $_currentPage/$_totalPages',
            style: const TextStyle(fontSize: 16),
          ),
        ),
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
        title: const Text('Quản lý người dùng'),
        backgroundColor: const Color(0xFF7AE582),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm người dùng...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: _filterUsers,
            ),
          ),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                      children: [
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _loadUsers,
                            child: ListView.builder(
                              itemCount: _paginatedUsers.length,
                              itemBuilder: (context, index) {
                                final user = _paginatedUsers[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundImage:
                                          user.linkImage != null &&
                                                  user.linkImage!.isNotEmpty
                                              ? NetworkImage(user.linkImage!)
                                              : NetworkImage(
                                                'https://th.bing.com/th/id/OIP.52T8HHBWh6b0dwrG6tSpVQHaFe?rs=1&pid=ImgDetMain',
                                              ),
                                    ),
                                    title: Text(user.fullName),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(user.email),
                                        Text(
                                          'Hạng: ${user.memberShipLevel ?? "Thành viên"}',
                                          style: const TextStyle(
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.more_vert),
                                      onPressed: () => _showUserOptions(user),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        _buildPagination(),
                      ],
                    ),
          ),
        ],
      ),
    );
  }

  void _showUserOptions(UserModel user) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('Xem chi tiết'),
                  onTap: () {
                    Navigator.pop(context);
                    _showUserDetails(user);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Cập nhật thông tin'),
                  onTap: () {
                    Navigator.pop(context);
                    UpdateUserProfileDialog.show(context, user, (updatedUser) {
                      setState(() {
                        final index = _users.indexWhere(
                          (u) => u.id == updatedUser.id,
                        );
                        if (index != -1) {
                          _users[index] = updatedUser;
                          _filterUsers('');
                        }
                      });
                    });
                  },
                ),
                ListTile(
                  leading: FutureBuilder<bool>(
                    future: _userRepository.isUserBanned(user.id!),
                    builder: (context, snapshot) {
                      return Icon(
                        snapshot.data == true ? Icons.lock_open : Icons.block,
                        color:
                            snapshot.data == true ? Colors.green : Colors.red,
                      );
                    },
                  ),
                  title: FutureBuilder<bool>(
                    future: _userRepository.isUserBanned(user.id!),
                    builder: (context, snapshot) {
                      return Text(
                        snapshot.data == true
                            ? 'Mở khóa tài khoản'
                            : 'Khóa tài khoản',
                        style: TextStyle(
                          color:
                              snapshot.data == true ? Colors.green : Colors.red,
                        ),
                      );
                    },
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _blockUser(user);
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _showUserDetails(UserModel user) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage:
                            user.linkImage != null && user.linkImage!.isNotEmpty
                                ? NetworkImage(user.linkImage!)
                                : null,
                        child:
                            user.linkImage == null || user.linkImage!.isEmpty
                                ? const Icon(Icons.person, size: 35)
                                : null,
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.fullName,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              user.memberShipLevel ?? "Thành viên",
                              style: TextStyle(
                                color: _getMembershipColor(
                                  user.memberShipLevel,
                                ),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 20),

                  // User details
                  _buildDetailItem(
                    Icons.email,
                    'Email',
                    user.email,
                    Colors.blue,
                  ),
                  const SizedBox(height: 15),
                  _buildDetailItem(
                    Icons.location_on,
                    'Địa chỉ',
                    (_addressRepository.getAddressesByUserId(
                      user.id!,
                    )).toString(),
                    Colors.green,
                  ),
                  // chỉnh sửa
                  const SizedBox(height: 15),
                  _buildDetailItem(
                    Icons.star,
                    'Điểm tích lũy',
                    '${user.memberShipPoint ?? 0} điểm',
                    Colors.orange,
                  ),
                  const SizedBox(height: 15),
                  _buildDetailItem(
                    Icons.card_membership,
                    'Điểm hiện có',
                    '${user.memberShipCurrentPoint ?? 0} điểm',
                    Colors.purple,
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 20),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Đóng',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _blockUser(user);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Khóa tài khoản',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildDetailItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: color, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getMembershipColor(String? level) {
    switch (level?.toLowerCase()) {
      case 'hạng bạc':
        return Colors.grey[400]!;
      case 'hạng vàng':
        return Colors.amber[600]!;
      case 'hạng bạch kim':
        return Colors.grey[300]!;
      case 'hạng kim cương':
        return Colors.blue;
      default:
        return Colors.blue[700]!; // Thành viên
    }
  }

  void _blockUser(UserModel user) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: FutureBuilder<bool>(
              future: _userRepository.isUserBanned(user.id!),
              builder: (context, snapshot) {
                return Text(
                  snapshot.data == true
                      ? 'Mở khóa tài khoản'
                      : 'Khóa tài khoản',
                );
              },
            ),
            content: Text(
              'Bạn có chắc muốn khóa tài khoản của ${user.fullName}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  disableUser(user.id!);
                },
                child: const Text('Khóa', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  Future<void> disableUser(String uid) async {
    try {
      final isCurrentlyBanned = await _userRepository.isUserBanned(uid);
      final success =
          isCurrentlyBanned
              ? await _userRepository.unbanUser(uid)
              : await _userRepository.banUser(uid);

      if (success) {
        setState(() {
          _loadUsers();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isCurrentlyBanned
                  ? 'Tài khoản đã được mở khóa thành công'
                  : 'Tài khoản đã bị khóa thành công',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isCurrentlyBanned
                  ? 'Không thể mở khóa tài khoản'
                  : 'Không thể khóa tài khoản',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Có lỗi xảy ra: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
