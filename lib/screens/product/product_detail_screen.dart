import 'package:ecommerce_app/models/cartitems_model.dart';
import 'package:ecommerce_app/models/comment_model.dart';
import 'package:ecommerce_app/models/product_model.dart';
import 'package:ecommerce_app/repository/cart_repository.dart';
import 'package:ecommerce_app/repository/comment_repository.dart';
import 'package:ecommerce_app/repository/product_repository.dart';
import 'package:ecommerce_app/repository/user_repository.dart';
import 'package:ecommerce_app/screens/cart/cart_screen.dart';
import 'package:ecommerce_app/screens/cart/checkout_screen.dart';
import 'package:ecommerce_app/screens/product/all_comments_screen.dart';
import 'package:ecommerce_app/screens/product/variant/add_variant_screen.dart';
import 'package:ecommerce_app/utils/image_utils.dart';
import 'package:ecommerce_app/utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:animate_do/animate_do.dart'; // Thêm thư viện animate_do

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;
  final bool fromDashboard;

  const ProductDetailScreen({
    super.key,
    required this.product,
    this.fromDashboard = false,
  });

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ProductRepository _productRepo = ProductRepository();
  final uuid = Uuid();
  final UserRepository _userRepo = UserRepository();
  final CartRepository _cartRepository = CartRepository();
  final CommentRepository _commentRepo = CommentRepository();
  late List<ProductModel> variants = [];
  bool isLoading = true;
  int _currentImageIndex = 0;
  late PageController _pageController;
  String? selectedOption;
  int quantity = 0;
  bool isBuyNow = false;
  late int stock;
  late String productId;
  late ProductModel currentProduct;
  String userId = "";
  String userMail = "";
  List<CommentModel> comments = [];

  @override
  void initState() {
    _loadUserId();
    super.initState();
    currentProduct = widget.product;
    stock = widget.product.stock;
    _fetchLatestProductStock();
    _pageController = PageController(initialPage: _currentImageIndex);
    productId = widget.product.id ?? "";
    selectedOption = widget.product.productName;
    _loadVariants();
    _loadComments();
    super.initState();
  }

  Future<void> _fetchLatestProductStock() async {
    if (widget.product.id != null) {
      final updatedProduct = await _productRepo.getProductById(
        widget.product.id!,
      );
      if (mounted && updatedProduct != null) {
        setState(() {
          stock = updatedProduct.stock;
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _loadUserId() async {
    final id = await _userRepo.getEffectiveUserId();
    final user = await _userRepo.getUserDetails(id);
    print("User ID: $id");
    setState(() {
      userMail = user?.email ?? "";
      userId = id;
    });
  }

  void _loadVariants() async {
    setState(() => isLoading = true);

    if (widget.product.id != null) {
      variants = await _productRepo.getVariants(widget.product.id!);
    }

    setState(() => isLoading = false);
  }

  void onChat() {
    print("Chuyển đến trang thanh toán!");
  }

  void _bottomSheet(bool isBuyNow) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      builder: (BuildContext context) {
        int tmpQuantity = 1;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(16),
              height: MediaQuery.of(context).size.height * 0.7,
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Color(0xFFBBDEFB),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Image.network(
                                    currentProduct.images.first,
                                    width: 140,
                                    height: 140,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.image_not_supported,
                                        size: 24,
                                        color: Colors.grey,
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 0, right: 0),
                              child: ZoomIn(
                                duration: Duration(milliseconds: 400),
                                child: IconButton(
                                  icon: Icon(
                                    Icons.close,
                                    color: Color(0xFF2196F3),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                ),
                              ),
                            ),
                            SizedBox(height: 32),
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 34,
                                top: 8,
                                bottom: 48,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  if (currentProduct.discount > 0) ...[
                                    Container(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Giá gốc: ${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(currentProduct.price)}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.bold,
                                          decoration:
                                              TextDecoration.lineThrough,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Giá: ${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(currentProduct.priceAfterDiscount)}',
                                        style: TextStyle(
                                          fontSize: 20,
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ] else
                                    Container(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Giá: ${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(currentProduct.price)}',
                                        style: TextStyle(
                                          fontSize: 20,
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Còn lại: $stock',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    height: 0.5,
                    color: Color(0xFFBBDEFB),
                    margin: EdgeInsets.symmetric(vertical: 8),
                  ),
                  if (variants.isNotEmpty) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Phân loại",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1976D2),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ZoomIn(
                              duration: Duration(milliseconds: 500),
                              child: GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    selectedOption = widget.product.productName;
                                    currentProduct = widget.product;
                                  });
                                  setState(() {
                                    selectedOption = widget.product.productName;
                                    currentProduct = widget.product;
                                    stock = widget.product.stock;
                                  });
                                },
                                child: _buildVariantOption(
                                  widget.product,
                                  selectedOption == widget.product.productName,
                                ),
                              ),
                            ),
                            ...variants.asMap().entries.map((entry) {
                              int index = entry.key;
                              ProductModel variant = entry.value;
                              bool isSelected =
                                  selectedOption == variant.productName;
                              return ZoomIn(
                                duration: Duration(
                                  milliseconds: 500 + index * 100,
                                ),
                                child: GestureDetector(
                                  onTap: () {
                                    setModalState(() {
                                      selectedOption = variant.productName;
                                      currentProduct = variant;
                                    });
                                    setState(() {
                                      selectedOption = variant.productName;
                                      currentProduct = variant;
                                      stock = variant.stock;
                                    });
                                  },
                                  child: _buildVariantOption(
                                    variant,
                                    isSelected,
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      height: 0.5,
                      color: Color(0xFFBBDEFB),
                      margin: EdgeInsets.symmetric(vertical: 8),
                    ),
                  ],
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Số lượng",
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF1976D2),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          ZoomIn(
                            duration: Duration(milliseconds: 500),
                            child: IconButton(
                              icon: Icon(
                                Icons.remove,
                                color: Color(0xFF2196F3),
                              ),
                              onPressed: () {
                                if (tmpQuantity > 1) {
                                  setModalState(() {
                                    tmpQuantity--;
                                  });
                                }
                              },
                            ),
                          ),
                          Text(
                            tmpQuantity.toString(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1976D2),
                            ),
                          ),
                          ZoomIn(
                            duration: Duration(milliseconds: 500),
                            child: IconButton(
                              icon: Icon(Icons.add, color: Color(0xFF2196F3)),
                              onPressed: () {
                                if (tmpQuantity < stock) {
                                  setModalState(() {
                                    tmpQuantity++;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (!isBuyNow) ...[
                    SizedBox(height: 16),
                    ZoomIn(
                      duration: Duration(milliseconds: 600),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              stock == 0
                                  ? null
                                  : () async {
                                    setState(() {
                                      quantity = tmpQuantity;
                                    });
                                    final cartRepo = CartRepository();
                                    final cart = await cartRepo.getCart(
                                      await _userRepo.getEffectiveUserId(),
                                    );
                                    final cartItem = CartItem(
                                      id: uuid.v4(),
                                      costPrice: currentProduct.costPrice,
                                      productId: currentProduct.id!,
                                      productName: currentProduct.productName,
                                      variantName: selectedOption,
                                      imageUrl:
                                          currentProduct.images.isNotEmpty
                                              ? currentProduct.images[0]
                                              : null,
                                      price: currentProduct.price,
                                      quantity: quantity,
                                      discountRate: currentProduct.discount,
                                      priceAfterDiscount:
                                          currentProduct.price *
                                          (1 - currentProduct.discount / 100),
                                    );
                                    setState(() {
                                      stock -= quantity;
                                    });
                                    await cartRepo.addItem(cart, cartItem);
                                    setState(() {
                                      quantity = 1;
                                    });
                                    if (!mounted) return;
                                    Navigator.pop(context);
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (BuildContext context) {
                                        Future.delayed(
                                          Duration(seconds: 2),
                                          () {
                                            Navigator.of(context).pop();
                                          },
                                        );
                                        return AlertDialog(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.check_circle,
                                                color: Color(0xFF2196F3),
                                                size: 50,
                                              ),
                                              SizedBox(height: 16),
                                              Text(
                                                'Đã thêm vào giỏ hàng',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Color(0xFF1976D2),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                stock == 0 ? Colors.grey : Color(0xFF2196F3),
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            stock == 0 ? "Hết hàng" : "Thêm vào Giỏ hàng",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ] else
                    ZoomIn(
                      duration: Duration(milliseconds: 600),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              stock == 0
                                  ? null
                                  : () {
                                    setState(() {
                                      quantity = tmpQuantity;
                                    });
                                    final cartItem = CartItem(
                                      id: uuid.v4(),
                                      productId: widget.product.id!,
                                      costPrice: widget.product.costPrice,
                                      productName: widget.product.productName,
                                      variantName: selectedOption,
                                      imageUrl:
                                          widget.product.images.isNotEmpty
                                              ? widget.product.images[0]
                                              : null,
                                      price: widget.product.price,
                                      quantity: quantity,
                                      discountRate: widget.product.discount,
                                      priceAfterDiscount:
                                          widget.product.price *
                                          (1 - widget.product.discount / 100),
                                    );
                                    setState(() {
                                      stock -= quantity;
                                    });
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => CheckoutScreen(
                                              cartItems: [cartItem],
                                            ),
                                      ),
                                    );
                                  },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                stock == 0 ? Colors.grey : Color(0xFF2196F3),
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            stock == 0 ? "Hết hàng" : "Mua ngay",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCommentDialog(BuildContext context) {
    final commentController = TextEditingController();
    final UserRepository _userRepo = UserRepository();
    final CommentRepository _commentRepo = CommentRepository();
    double rating = 0;
    showDialog(
      context: context,
      builder:
          (BuildContext context) => StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                title: Text(
                  'Đánh giá sản phẩm',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1976D2),
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_userRepo.isUserId(userId)) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return IconButton(
                            icon: Icon(
                              index < rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                            ),
                            onPressed: () {
                              setDialogState(() {
                                rating = index + 1.0;
                              });
                            },
                          );
                        }),
                      ),
                      SizedBox(height: 10),
                    ],
                    TextField(
                      controller: commentController,
                      decoration: InputDecoration(
                        hintText: 'Nhập đánh giá của bạn',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Color(0xFFBBDEFB)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Color(0xFF2196F3)),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Hủy',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final comment = CommentModel(
                        productId: widget.product.id!,
                        userId: userId,
                        userName:
                            _userRepo.isUserId(userId)
                                ? (await _userRepo.getUserDetails(
                                  userId,
                                ))!.fullName
                                : 'Khách',
                        content: commentController.text,
                        rating: _userRepo.isUserId(userId) ? rating : null,
                        createdAt: DateTime.now(),
                        reply: null,
                      );
                      await _commentRepo.addComment(comment);
                      await _loadComments();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF2196F3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Gửi', style: TextStyle(color: Colors.white)),
                  ),
                ],
              );
            },
          ),
    );
  }

  void _showCommentReplyDialog(BuildContext context, String commentId) {
    final commentController = TextEditingController();
    final UserRepository _userRepo = UserRepository();
    final CommentRepository _commentRepo = CommentRepository();
    showDialog(
      context: context,
      builder:
          (BuildContext context) => StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                title: Text(
                  'Trả lời bình luận',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1976D2),
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_userRepo.isUserId(userId)) ...[],
                    TextField(
                      controller: commentController,
                      decoration: InputDecoration(
                        hintText: 'Nhập câu trả lời...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Color(0xFFBBDEFB)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Color(0xFF2196F3)),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Hủy',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final replyText = commentController.text.trim();
                      if (replyText.isNotEmpty) {
                        await _commentRepo.replyToComment(commentId, replyText);
                        await _loadComments();
                      }
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF2196F3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Gửi', style: TextStyle(color: Colors.white)),
                  ),
                ],
              );
            },
          ),
    );
  }

  Future<void> _loadComments() async {
    final productComments = await _commentRepo.getProductComments(productId);
    if (mounted) {
      setState(() {
        comments = productComments;
        double avgRating = Utils.calculateAverageRating(comments);
        if (avgRating > 0 && currentProduct.id != null) {
          _productRepo.updateProductRating(currentProduct.id!, avgRating);
          currentProduct = currentProduct..rating = avgRating;
        }
      });
    }
  }

  Widget _buildCommentSection() {
    return FadeInUp(
      duration: Duration(milliseconds: 800),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 6,
                height: 24,
                decoration: BoxDecoration(
                  color: Color(0xFF2196F3),
                  borderRadius: BorderRadius.circular(3),
                ),
                margin: const EdgeInsets.only(right: 12),
              ),
              Expanded(
                child: Text(
                  "Đánh giá sản phẩm",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1976D2),
                  ),
                ),
              ),
              ZoomIn(
                duration: Duration(milliseconds: 500),
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                AllCommentsScreen(product: widget.product),
                      ),
                    );
                  },
                  child: Text(
                    "Xem tất cả",
                    style: TextStyle(color: Color(0xFF2196F3), fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (comments.isEmpty)
            FadeInUp(
              duration: Duration(milliseconds: 600),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "Chưa có đánh giá nào cho sản phẩm này",
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: comments.length,
              itemBuilder: (context, index) {
                final comment = comments[index];
                return FadeInUp(
                  duration: Duration(milliseconds: 700 + index * 100),
                  child: Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: BorderSide(color: Color(0xFFBBDEFB), width: 1),
                    ),
                    elevation: 5,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                comment.userName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF1976D2),
                                ),
                              ),
                              Text(
                                DateFormat(
                                  'dd/MM/yyyy HH:mm',
                                ).format(comment.createdAt),
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              if (userMail == "admin@gmail.com")
                                ElevatedButton(
                                  onPressed:
                                      () => _showCommentReplyDialog(
                                        context,
                                        comment.id.toString(),
                                      ),
                                  child: Text("Trả lời", style: TextStyle()),
                                ),
                            ],
                          ),

                          if (comment.rating != null) ...[
                            const SizedBox(height: 8),
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
                          const SizedBox(height: 8),
                          Text(
                            comment.content,
                            style: TextStyle(color: Colors.black87),
                          ),
                          if (comment.reply.toString().isNotEmpty &&
                              comment.reply != null) ...[
                            Container(
                              margin: const EdgeInsets.only(top: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Color(0xFFE3F2FD),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Color(0xFF90CAF9)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.reply,
                                    size: 20,
                                    color: Color(0xFF1976D2),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Admin đã trả lời: ',

                                          style: TextStyle(
                                            color: Color(0xFF0D47A1),
                                            fontStyle: FontStyle.italic,
                                          ),
                                          softWrap: true,
                                        ),
                                        Text(
                                          comment.reply.toString(),
                                          style: TextStyle(
                                            color: Color(0xFF0D47A1),
                                            fontStyle: FontStyle.italic,
                                          ),
                                          softWrap: true,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Color(0xFFBBDEFB)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeInDown(
                    duration: Duration(milliseconds: 500),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF2196F3).withOpacity(0.4),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          ZoomIn(
                            duration: Duration(milliseconds: 300),
                            child: IconButton(
                              icon: Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              widget.product.productName,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          ZoomIn(
                            duration: Duration(milliseconds: 300),
                            child: IconButton(
                              onPressed: () async {
                                final cart = await _cartRepository.getCart(
                                  userId,
                                );
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => CartScreen(cart: cart),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.shopping_cart_outlined,
                                color: Colors.white,
                              ),
                              iconSize: 28,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  FadeInUp(
                    duration: Duration(milliseconds: 600),
                    child: _buildProductImages(
                      widget.product,
                      _currentImageIndex,
                      (index) => setState(() => _currentImageIndex = index),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          widget.product.productName,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1976D2),
                          ),
                          softWrap: true,
                        ),
                      ),
                      const SizedBox(width: 20),
                      if (widget.product.discount > 0)
                        ZoomIn(
                          duration: Duration(milliseconds: 500),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '- ${widget.product.discount}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (widget.product.discount > 0) ...[
                        Text(
                          Utils.formatCurrency(
                            widget.product.price *
                                (1 - widget.product.discount / 100),
                          ),
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          Utils.formatCurrency(widget.product.price),
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ] else
                        Text(
                          Utils.formatCurrency(widget.product.price),
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  FadeInUp(
                    duration: Duration(milliseconds: 700),
                    child: FutureBuilder<Widget>(
                      future: Utils.getProductRatingStars(widget.product.id!),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox(
                            height: 20,
                            width: 100,
                            child: LinearProgressIndicator(
                              color: Color(0xFF2196F3),
                            ),
                          );
                        } else if (snapshot.hasData) {
                          return snapshot.data!;
                        } else {
                          return Utils.buildStarRating(0);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  FadeInUp(
                    duration: Duration(milliseconds: 800),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildSectionTitle("Mô tả"),
                        Container(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children:
                                (widget.product.description)
                                    .split('•')
                                    .where((e) => e.trim().isNotEmpty)
                                    .map(
                                      (e) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: Text(
                                          "• $e".trim(),
                                          style: TextStyle(
                                            fontSize: 16,
                                            height: 1.5,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (isLoading)
                    FadeIn(
                      duration: Duration(milliseconds: 500),
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF2196F3),
                          ),
                        ),
                      ),
                    )
                  else if (variants.isNotEmpty) ...[
                    FadeInUp(
                      duration: Duration(milliseconds: 900),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          buildSectionTitle("Biến thể"),
                          const SizedBox(height: 10),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: variants.length,
                            itemBuilder: (context, index) {
                              final variant = variants[index];
                              return FadeInUp(
                                duration: Duration(
                                  milliseconds: 1000 + index * 100,
                                ),
                                child: Card(
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    side: BorderSide(
                                      color: Color(0xFFBBDEFB),
                                      width: 1,
                                    ),
                                  ),
                                  elevation: 5,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    leading: ImageUtils.buildImage(
                                      variant.images.first,
                                    ),
                                    title: Text(
                                      variant.productName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1976D2),
                                      ),
                                    ),
                                    subtitle: Text(
                                      Utils.formatCurrency(variant.price),
                                      style: TextStyle(color: Colors.red),
                                    ),
                                    trailing: Icon(
                                      Icons.chevron_right,
                                      color: Color(0xFF2196F3),
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => ProductDetailScreen(
                                                product: variant,
                                                fromDashboard: true,
                                              ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    FadeInUp(
                      duration: Duration(milliseconds: 900),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          buildSectionTitle("Biến thể"),
                          const SizedBox(height: 8),
                          Text(
                            "Sản phẩm này không có biến thể.",
                            style: TextStyle(
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FadeInUp(
                    duration: Duration(milliseconds: 1000),
                    child: ZoomIn(
                      duration: Duration(milliseconds: 500),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _showCommentDialog(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF2196F3),
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            "Thêm đánh giá",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildCommentSection(),
                  FutureBuilder<String>(
                    future: _userRepo.getEffectiveUserId(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox();
                      }
                      if (userMail == "admin@gmail.com") {
                        return FadeInUp(
                          duration: Duration(milliseconds: 1100),
                          child: ZoomIn(
                            duration: Duration(milliseconds: 500),
                            child: Center(
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final newVariant = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => AddVariantScreen(
                                              parentProduct: widget.product,
                                            ),
                                      ),
                                    );
                                    if (newVariant != null) {
                                      _loadVariants();
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF2196F3),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text(
                                    "Thêm biến thể",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                  SizedBox(
                    height: 60,
                  ), // Đệm để không bị che bởi bottomNavigationBar
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: ClipRRect(
                borderRadius: BorderRadius.only(topLeft: Radius.circular(16)),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ZoomIn(
                        duration: Duration(milliseconds: 500),
                        child: IconButton(
                          icon: Icon(
                            Icons.chat_bubble_outline,
                            color: Colors.white,
                          ),
                          onPressed: onChat,
                        ),
                      ),
                      Container(width: 1, height: 40, color: Colors.white),
                      ZoomIn(
                        duration: Duration(milliseconds: 500),
                        child: IconButton(
                          icon: Icon(
                            Icons.add_shopping_cart,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            setState(() {
                              isBuyNow = false;
                            });
                            _bottomSheet(isBuyNow);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: ClipRRect(
                borderRadius: BorderRadius.only(topRight: Radius.circular(16)),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      isBuyNow = true;
                    });
                    _bottomSheet(isBuyNow);
                  },
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.red, Colors.redAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "Mua ngay",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return const Icon(
        Icons.image_not_supported,
        size: 80,
        color: Colors.grey,
      );
    }
    return ZoomIn(
      duration: Duration(milliseconds: 500),
      child: Image.network(
        imagePath,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.broken_image, size: 80, color: Colors.red);
        },
      ),
    );
  }

  Widget _buildProductImages(
    ProductModel product,
    int currentIndex,
    Function(int) onImageChanged,
  ) {
    if (product.images.isEmpty) {
      return const Center(
        child: Icon(Icons.image_not_supported, size: 150, color: Colors.grey),
      );
    }
    return Column(
      children: [
        SizedBox(
          height: 250,
          child: PageView.builder(
            controller: _pageController,
            itemCount: product.images.length,
            onPageChanged: onImageChanged,
            itemBuilder: (context, index) {
              return ZoomIn(
                duration: Duration(milliseconds: 500),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    product.images[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.broken_image,
                        size: 150,
                        color: Colors.red,
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        if (product.images.length > 1)
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: product.images.length,
              itemBuilder: (context, index) {
                return ZoomIn(
                  duration: Duration(milliseconds: 500 + index * 100),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _currentImageIndex = index);
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color:
                              currentIndex == index
                                  ? Color(0xFF2196F3)
                                  : Colors.transparent,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: _buildImage(product.images[index]),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 24,
          decoration: BoxDecoration(
            color: Color(0xFF2196F3),
            borderRadius: BorderRadius.circular(3),
          ),
          margin: const EdgeInsets.only(right: 12),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1976D2),
          ),
        ),
      ],
    );
  }

  Widget _buildVariantOption(ProductModel variant, bool isSelected) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: isSelected ? Color(0xFF2196F3) : Colors.grey),
        borderRadius: BorderRadius.circular(8),
        color:
            isSelected
                ? Color(0xFFBBDEFB).withOpacity(0.3)
                : Colors.grey.shade100,
      ),
      child: Text(
        variant.productName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: true,
        style: TextStyle(
          color: isSelected ? Color(0xFF2196F3) : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
