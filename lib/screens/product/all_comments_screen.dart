import 'package:ecommerce_app/models/comment_model.dart';
import 'package:ecommerce_app/models/product_model.dart';
import 'package:ecommerce_app/repository/comment_repository.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AllCommentsScreen extends StatefulWidget {
  final ProductModel product;

  const AllCommentsScreen({Key? key, required this.product}) : super(key: key);

  @override
  State<AllCommentsScreen> createState() => _AllCommentsScreenState();
}

class _AllCommentsScreenState extends State<AllCommentsScreen> {
  final CommentRepository _commentRepo = CommentRepository();
  List<CommentModel> comments = [];
  List<CommentModel> filteredComments = [];
  bool isLoading = true;

  // Các biến cho bộ lọc
  double? selectedRating;
  String? selectedUserType;
  final List<String> userTypeOptions = ['Tất cả', 'Khách', 'Thành viên'];

  @override
  void initState() {
    super.initState();
    _loadAllComments();
  }

  Future<void> _loadAllComments() async {
    setState(() => isLoading = true);
    final productComments = await _commentRepo.getProductComments(
      widget.product.id!,
    );
    productComments.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    setState(() {
      comments = productComments;
      filteredComments = productComments;
      isLoading = false;
    });
  }

  void _applyFilters() {
    setState(() {
      filteredComments =
          comments.where((comment) {
            // Lọc theo số sao
            if (selectedRating != null && comment.rating != selectedRating) {
              return false;
            }

            // Lọc theo loại người dùng
            if (selectedUserType != null && selectedUserType != 'Tất cả') {
              if (selectedUserType == 'Khách' && comment.userId != null) {
                return false;
              }
              if (selectedUserType == 'Thành viên' && comment.userId == null) {
                return false;
              }
            }

            return true;
          }).toList();
    });
  }

  Widget _buildFilterSection() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lọc đánh giá',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          // Lọc theo số sao
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: Text('Tất cả'),
                  selected: selectedRating == null,
                  onSelected: (bool selected) {
                    setState(() {
                      selectedRating = selected ? null : selectedRating;
                      _applyFilters();
                    });
                  },
                  backgroundColor: Colors.grey[200],
                  selectedColor: Colors.blue,
                  labelStyle: TextStyle(
                    color: selectedRating == null ? Colors.white : Colors.black,
                  ),
                ),
                SizedBox(width: 8),
                ...List.generate(5, (index) {
                  return Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${index + 1}'),
                          Icon(
                            Icons.star,
                            size: 16,
                            color:
                                selectedRating == index + 1
                                    ? Colors.white
                                    : Colors.amber,
                          ),
                        ],
                      ),
                      selected: selectedRating == index + 1,
                      onSelected: (bool selected) {
                        setState(() {
                          selectedRating = selected ? index + 1 : null;
                          _applyFilters();
                        });
                      },
                      backgroundColor: Colors.grey[200],
                      selectedColor: Colors.blue,
                      labelStyle: TextStyle(
                        color:
                            selectedRating == index + 1
                                ? Colors.white
                                : Colors.black,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          SizedBox(height: 16),
          // Lọc theo loại người dùng
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children:
                  userTypeOptions.map((type) {
                    return Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(type),
                        selected: selectedUserType == type,
                        onSelected: (bool selected) {
                          setState(() {
                            selectedUserType = selected ? type : null;
                            _applyFilters();
                          });
                        },
                        backgroundColor: Colors.grey[200],
                        selectedColor: Colors.blue,
                        labelStyle: TextStyle(
                          color:
                              selectedUserType == type
                                  ? Colors.white
                                  : Colors.black,
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Đánh giá ${widget.product.productName}',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, color: Colors.white),
            onPressed: () {
              setState(() {
                selectedRating = null;
                selectedUserType = null;
                _applyFilters();
              });
            },
            tooltip: 'Đặt lại bộ lọc',
          ),
        ],
      ),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  _buildFilterSection(),
                  Expanded(
                    child:
                        filteredComments.isEmpty
                            ? Center(
                              child: Text(
                                'Không tìm thấy đánh giá nào',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            )
                            : ListView.builder(
                              padding: EdgeInsets.all(16),
                              itemCount: filteredComments.length,
                              itemBuilder: (context, index) {
                                final comment = filteredComments[index];
                                return Card(
                                  margin: EdgeInsets.only(bottom: 16),
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  comment.userName,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                SizedBox(width: 8),
                                                Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        comment.userId != null
                                                            ? Colors.blue[100]
                                                            : Colors.grey[200],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    comment.userId != null
                                                        ? 'Thành viên'
                                                        : 'Khách',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          comment.userId != null
                                                              ? Colors.blue[900]
                                                              : Colors
                                                                  .grey[700],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              DateFormat(
                                                'dd/MM/yyyy HH:mm',
                                              ).format(comment.createdAt),
                                              style: TextStyle(
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (comment.rating != null) ...[
                                          SizedBox(height: 8),
                                          Row(
                                            children: List.generate(5, (index) {
                                              return Icon(
                                                index < (comment.rating ?? 0)
                                                    ? Icons.star
                                                    : Icons.star_border,
                                                color: Colors.amber,
                                                size: 20,
                                              );
                                            }),
                                          ),
                                        ],
                                        SizedBox(height: 8),
                                        Text(
                                          comment.content,
                                          style: TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
    );
  }
}
