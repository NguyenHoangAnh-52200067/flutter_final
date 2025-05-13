import 'package:ecommerce_app/home.dart';
import 'package:ecommerce_app/models/cart_model.dart';
import 'package:ecommerce_app/models/cartitems_model.dart';
import 'package:ecommerce_app/repository/cart_repository.dart';
import 'package:ecommerce_app/repository/product_repository.dart';
import 'package:ecommerce_app/screens/cart/checkout_screen.dart';
import 'package:ecommerce_app/utils/utils.dart';
import 'package:flutter/material.dart';

class CartScreen extends StatefulWidget {
  final Cart cart;
  const CartScreen({super.key, required this.cart});
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartRepository _cartRepository = CartRepository();
  final ProductRepository _productRepository = ProductRepository();

  late List<CartItem> _cartItems;
  final Set<String> _selectedItems = {};

  @override
  void initState() {
    super.initState();
    _cartItems = widget.cart.items;
  }

  double _calculateSelectedTotal() => _cartItems
      .where((item) => _selectedItems.contains(item.id))
      .fold(
        0,
        (total, item) =>
            total +
            ((item.discountRate != null && item.discountRate! > 0
                    ? item.priceAfterDiscount!
                    : item.price) *
                item.quantity),
      );

  Future<void> _removeItem(CartItem item) async {
    await _productRepository.undoProductStock(item.productId, item.quantity);
    await _cartRepository.removeItem(widget.cart, item.id);
    setState(() {
      _cartItems.remove(item);
      _selectedItems.remove(item.id);
    });
  }

  Future<void> _updateItemQuantity(CartItem item, int newQuantity) async {
    if (newQuantity < 1) {
      _showDeleteConfirmationDialog(item);
      return;
    }

    await _cartRepository.updateItemQuantity(widget.cart, item.id, newQuantity);
    setState(() => item.quantity = newQuantity);
  }

  void _showDeleteConfirmationDialog(CartItem item) {
    showDialog(
      context: context,
      builder:
          (BuildContext context) => AlertDialog(
            title: const Text('Xác nhận'),
            content: const Text('Bạn có muốn xóa sản phẩm này khỏi giỏ hàng?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Không', style: TextStyle(fontSize: 18)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _removeItem(item);
                },
                child: const Text(
                  'Đồng ý',
                  style: TextStyle(color: Colors.red, fontSize: 18),
                ),
              ),
            ],
          ),
    );
  }

  void _navigateToCheckout() {
    final selectedProducts =
        _cartItems.where((item) => _selectedItems.contains(item.id)).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(cartItems: selectedProducts),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 238, 238, 238),
      appBar: AppBar(title: const Text('Giỏ hàng')),
      body:
          _cartItems.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16), // Bo tròn 4 góc
                      child: Image.network(
                        'https://cdni.iconscout.com/illustration/premium/thumb/online-shopping-cart-2748733-2289776.png',
                        width: 200,
                        height: 200,
                      ),
                    ),

                    const Text(
                      '"Hổng" có gì trong giỏ hết',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Lướt ShopOnline, lựa hàng ngay đi!',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HomeScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        'Mua sắm ngay!',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              )
              : SingleChildScrollView(
                child: Column(
                  children: _cartItems.map(_buildCartItem).toList(),
                ),
              ),
      bottomNavigationBar: _cartItems.isEmpty ? null : _buildBottomBar(),
    );
  }

  Widget _buildBottomBar() {
    return BottomAppBar(
      color: const Color.fromARGB(255, 233, 233, 233),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tổng cộng: ${Utils.formatCurrency(_calculateSelectedTotal())}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ElevatedButton(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.blueAccent),
              ),
              onPressed: _selectedItems.isEmpty ? null : _navigateToCheckout,
              child: Text(
                'Mua hàng (${_selectedItems.length})',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItem(CartItem item) {
    return Dismissible(
      key: Key(item.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _removeItem(item),
      child: Card(
        margin: const EdgeInsets.all(8),
        child: Row(
          children: [
            const SizedBox(width: 8),
            _buildCheckbox(item),
            Expanded(
              child: ListTile(
                leading: _buildItemImage(item),
                title: _buildItemTitle(item),
                subtitle: _buildItemSubtitle(item),
              ),
            ),
            _buildQuantityControls(item),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckbox(CartItem item) {
    return Padding(
      padding: const EdgeInsets.only(left: 0),
      child: Checkbox(
        value: _selectedItems.contains(item.id),
        onChanged: (bool? value) {
          setState(() {
            value ?? false
                ? _selectedItems.add(item.id)
                : _selectedItems.remove(item.id);
          });
        },
      ),
    );
  }

  Widget _buildItemImage(CartItem item) {
    return item.imageUrl != null
        ? Container(
          width: 70,
          height: 70,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(item.imageUrl!, fit: BoxFit.cover),
          ),
        )
        : const SizedBox(
          width: 70,
          height: 70,
          child: Icon(Icons.image_not_supported),
        );
  }

  Widget _buildItemTitle(CartItem item) {
    return Text(
      item.productName,
      style: const TextStyle(fontWeight: FontWeight.bold),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }

  Widget _buildItemSubtitle(CartItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (item.discountRate != null && item.discountRate! > 0)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                Utils.formatCurrency(item.price),
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Giảm giá: ${item.discountRate}%',
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 4),

              Text(
                Utils.formatCurrency(item.priceAfterDiscount!),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 8),
            ],
          )
        else
          Text(
            Utils.formatCurrency(item.price),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
      ],
    );
  }

  Widget _buildQuantityControls(CartItem item) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove),
          onPressed: () => _updateItemQuantity(item, item.quantity - 1),
        ),
        Text('${item.quantity}'),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => _updateItemQuantity(item, item.quantity + 1),
        ),
      ],
    );
  }
}
