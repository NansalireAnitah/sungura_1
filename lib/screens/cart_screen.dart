import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import 'checkout.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
        centerTitle: true,
        actions: [
          Consumer<CartProvider>(
            builder: (context, cart, _) {
              return Visibility(
                visible: cart.items.isNotEmpty,
                child: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Clear Cart',
                  onPressed: () => _showClearCartDialog(context, cart),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, _) {
          if (cart.items.isEmpty) {
            return _buildEmptyCart();
          }
          return Column(
            children: [
              _buildCartItemsList(cart),
              _buildCheckoutSection(context, cart),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('Your cart is empty', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text('Browse our menu to add items', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildCartItemsList(CartProvider cart) {
    return Expanded(
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        itemCount: cart.items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = cart.items[index];
          return _buildCartItem(item, cart);
        },
      ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item, CartProvider cart) {
    final title = item['title']?.toString() ?? 'Unknown Item';
    final price = (item['price'] as num?)?.toDouble() ?? 0.0;
    final quantity = (item['quantity'] as int?) ?? 1;
    final imageUrl = item['image']?.toString() ?? 'https://via.placeholder.com/150';
    final cartItemId = item['cartItemId']?.toString() ?? '';

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  if (kDebugMode) {
                    print('Cart item image error for $imageUrl: $error');
                  }
                  return Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[200],
                    child: const Icon(Icons.fastfood, color: Colors.grey),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => cart.removeItem(cartItemId),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'UGX ${(price * quantity).toStringAsFixed(0)}',
                        style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold),
                      ),
                      _buildQuantitySelector(cart, cartItemId, quantity),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantitySelector(CartProvider cart, String itemId, int quantity) {
    return Container(
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 18),
            onPressed: () => cart.decrementQuantity(itemId),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text('$quantity', style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            onPressed: () => cart.incrementQuantity(itemId),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutSection(BuildContext context, CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, -4))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal:', style: TextStyle(fontSize: 16)),
              Text(
                'UGX ${cart.totalPrice.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[800],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
              onPressed: () {
                // Defer navigation to avoid frame conflicts
                Future.delayed(Duration.zero, () {
                  try {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CheckoutScreen(
                          cartItems: cart.items,
                          onOrderPlaced: (orderId) {
                            cart.clearCart();
                            Navigator.popUntil(context, (route) => route.isFirst);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Order #$orderId placed successfully!'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          onAddToCart: (product) {
                            cart.addItem(product);
                          },
                        ),
                      ),
                    );
                  } catch (e) {
                    if (kDebugMode) {
                      print('Navigation error: $e');
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to navigate to checkout: $e')),
                    );
                  }
                });
              },
              child: const Text(
                'PROCEED TO CHECKOUT',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearCartDialog(BuildContext context, CartProvider cart) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart?'),
        content: const Text('This will remove all items from your cart.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              cart.clearCart();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cart cleared'), behavior: SnackBarBehavior.floating),
              );
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}