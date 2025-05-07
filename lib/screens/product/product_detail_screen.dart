import 'package:ecomerce_app/models/cartitems_model.dart';
import 'package:ecomerce_app/models/comment_model.dart';
import 'package:ecomerce_app/models/product_model.dart';
import 'package:ecomerce_app/repository/cart_repository.dart';
import 'package:ecomerce_app/repository/comment_repository.dart';
import 'package:ecomerce_app/repository/product_repository.dart';
import 'package:ecomerce_app/repository/user_repository.dart';
import 'package:ecomerce_app/screens/cart/cart_screen.dart';
import 'package:ecomerce_app/screens/cart/checkout_screen.dart';
import 'package:ecomerce_app/screens/product/all_comments_screen.dart';
import 'package:ecomerce_app/screens/product/variant/add_variant_screen.dart';
import 'package:ecomerce_app/utils/image_utils.dart';
import 'package:ecomerce_app/utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

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
    final id = await _userRepo.getEffectiveUserId(); // Get the ID
    if (mounted) {
      setState(() {
        userId = id;
      });
    }
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
            // renamed setState to setModalState
            return Container(
              padding: const EdgeInsets.all(16),
              height: MediaQuery.of(context).size.height * 0.7,
              width: MediaQuery.of(context).size.width,

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
                                      color: Colors.grey,
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
                              child: IconButton(
                                icon: Icon(Icons.close),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
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
                                          color: Colors.grey,
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
                                          color: Colors.deepOrange,
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
                                          color: Colors.deepOrange,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Còn lại: $stock',
                                      style: TextStyle(fontSize: 14),
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
                    height: 0.3,
                    color: Colors.grey,
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
                            GestureDetector(
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
                            ...variants.map((variant) {
                              bool isSelected =
                                  selectedOption == variant.productName;
                              return GestureDetector(
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
                                child: _buildVariantOption(variant, isSelected),
                              );
                            }),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      height: 0.3,
                      color: Colors.grey,
                      margin: EdgeInsets.symmetric(vertical: 8),
                    ),
                  ],

                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Số lượng", style: TextStyle(fontSize: 16)),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.remove),
                            onPressed: () {
                              if (tmpQuantity > 1) {
                                setState(() {
                                  tmpQuantity--;
                                });
                              }
                            },
                          ),
                          Text(
                            tmpQuantity.toString(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.add),
                            onPressed: () {
                              if (tmpQuantity < widget.product.stock) {
                                setState(() {
                                  tmpQuantity++;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (!isBuyNow) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            stock == 0
                                ? null // Disable button when stock is 0
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
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (BuildContext context) {
                                      Future.delayed(Duration(seconds: 2), () {
                                        Navigator.of(context).pop();
                                      });
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
                                              color: Colors.green,
                                              size: 50,
                                            ),
                                            SizedBox(height: 16),
                                            Text(
                                              'Đã thêm vào giỏ hàng',
                                              style: TextStyle(fontSize: 16),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              stock == 0
                                  ? Colors.grey
                                  : Colors
                                      .red, // Change color when out of stock
                          padding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          stock == 0
                              ? "Hết hàng"
                              : "Thêm vào Giỏ hàng", // Change text when out of stock
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ] else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            stock == 0
                                ? null // Disable button when stock is 0
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
                              stock == 0
                                  ? Colors.grey
                                  : Colors
                                      .red, // Change color when out of stock
                          padding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          stock == 0
                              ? "Hết hàng"
                              : "Mua ngay", // Change text when out of stock
                          style: TextStyle(fontSize: 16, color: Colors.white),
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
                title: Text('Đánh giá sản phẩm'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // if (_userRepo.getCurrentUserId() != null) ...[
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
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Hủy'),
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
                      );

                      await _commentRepo.addComment(comment);
                      await _loadComments();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
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
    final productComments = await _commentRepo.getProductComments(
      widget.product.id!,
    );

    productComments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    setState(() {
      comments = productComments;
    });
  }

  Widget _buildCommentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 5,
              height: 20,
              color: const Color(0xFF7AE582),
              margin: const EdgeInsets.only(right: 10),
            ),
            Expanded(
              child: const Text(
                "Đánh giá sản phẩm",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => AllCommentsScreen(product: widget.product),
                  ),
                );
              },
              child: const Text("Xem tất cả"),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (comments.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Chưa có đánh giá nào cho sản phẩm này",
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: comments.length,
            itemBuilder: (context, index) {
              final comment = comments[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            DateFormat(
                              'dd/MM/yyyy HH:mm',
                            ).format(comment.createdAt),
                            style: const TextStyle(color: Colors.grey),
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
                      Text(comment.content),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.product.productName,
          style: TextStyle(color: Colors.white),
        ),

        actions: [
          IconButton(
            onPressed: () async {
              final cart = await _cartRepository.getCart(userId);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CartScreen(cart: cart)),
              );
            },
            icon: const Icon(Icons.shopping_cart_outlined),
            color: Colors.white,
            iconSize: 28,
          ),
        ],
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Colors.blue,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProductImages(
              widget.product,
              _currentImageIndex,
              (index) => setState(() => _currentImageIndex = index),
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    widget.product.productName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    softWrap: true,
                  ),
                ),
                const SizedBox(width: 20),

                if (widget.product.discount > 0)
                  Container(
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
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
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
            Utils.buildStarRating(widget.product.rating),

            const SizedBox(height: 20),
            Column(
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
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  "• $e".trim(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (variants.isNotEmpty) ...[
              buildSectionTitle("Biến thể"),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: variants.length,
                itemBuilder: (context, index) {
                  final variant = variants[index];
                  return Card(
                    child: ListTile(
                      leading: ImageUtils.buildImage(variant.images.first),
                      title: Text(variant.productName),
                      subtitle: Text(Utils.formatCurrency(variant.price)),
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
                  );
                },
              ),
            ] else ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSectionTitle("Biến thể"),
                  const SizedBox(height: 8),
                  const Text(
                    "Sản phẩm này không có biến thể.",
                    style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _showCommentDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                "Thêm đánh giá",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            _buildCommentSection(),
            if (_userRepo.isUserId(userId) &&
                _userRepo.getUserRole(userId) == 'admin' &&
                widget.product.parentId == null)
              Center(
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
                      backgroundColor: const Color(0xFF7AE582),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "Thêm biến thể",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
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
              child: Container(
                height: 50, // Set fixed height
                color: Color(0xFF20A39E),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.white,
                      ),
                      onPressed: onChat,
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.white,
                    ), // Đường kẻ dọc
                    IconButton(
                      icon: Icon(Icons.add_shopping_cart, color: Colors.white),
                      //Thêm vào giỏ hàng
                      onPressed: () {
                        _bottomSheet(isBuyNow);
                      },
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    isBuyNow = true;
                  });
                  _bottomSheet(isBuyNow);
                },
                child: Container(
                  height: 50,
                  color: Color(0xFFE63946),
                  alignment: Alignment.center,
                  child: Text(
                    "Mua ngay",
                    style: TextStyle(color: Colors.white, fontSize: 18),
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

    return Image.network(
      imagePath,
      width: 80,
      height: 80,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(Icons.broken_image, size: 80, color: Colors.red);
      },
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
              return ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _buildImage(product.images[index]),
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
                return GestureDetector(
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
                                ? Colors.green
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
          width: 5,
          height: 20,
          color: const Color(0xFF7AE582),
          margin: const EdgeInsets.only(right: 10),
        ),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildVariantOption(ProductModel variant, bool isSelected) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: isSelected ? Colors.red : Colors.grey),
            borderRadius: BorderRadius.circular(8),
            color: isSelected ? Colors.red.shade50 : Colors.grey.shade200,
          ),
          child: Text(
            variant.productName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: true,
            style: TextStyle(
              color: isSelected ? Colors.red : Colors.black,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}
