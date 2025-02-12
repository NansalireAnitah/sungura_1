import 'package:flutter/material.dart';

class ProductCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String price;
  final VoidCallback onAddToCart;
  final Color cartButtonColor;

  const ProductCard({
    super.key,
    required this.imagePath,
    required this.title,
    required this.price,
    required this.onAddToCart,
    required this.cartButtonColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(10)),
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              'UGX $price',
              style: const TextStyle(fontSize: 14, color: Colors.green),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: onAddToCart,
              icon: const Icon(
                Icons.add_shopping_cart,
                color: Color.fromARGB(255, 8, 6, 6),
              ),
              iconSize: 30,
              splashColor: const Color.fromARGB(255, 248, 2, 22),
              tooltip: 'Add to Cart',
            ),
          ),
        ],
      ),
    );
  }
}
