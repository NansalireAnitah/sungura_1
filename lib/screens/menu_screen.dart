import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../models/product_model.dart';
import 'screen3.dart'; // Assuming this is your CheckoutScreen

typedef AddToCartCallback = void Function(Map<String, dynamic> product);

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Product> filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).fetchProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    setState(() {
      filteredProducts = query.isEmpty
          ? productProvider.products
          : productProvider.products.where((product) {
              final name = product.name.toLowerCase();
              return name.contains(query);
            }).toList();
    });
  }

  void _filterByCategory(String category) {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    setState(() {
      filteredProducts = productProvider.products
          .where((product) => product.category == category)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sungura House'),
        centerTitle: true,
        
      ),
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, _) {
          if (productProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (filteredProducts.isEmpty && !productProvider.isLoading) {
            filteredProducts = productProvider.products.where((p) => p.isAvailable).toList();
          }
          if (filteredProducts.isEmpty) {
            return const Center(child: Text('No products available'));
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'What do you like to eat?',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                CarouselSlider(
                  options: CarouselOptions(autoPlay: true),
                  items: productProvider.products
                      .where((p) => p.isAvailable)
                      .take(3)
                      .map((product) {
                    return Builder(
                      builder: (BuildContext context) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 5.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(
                              product.imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(child: CircularProgressIndicator());
                              },
                              errorBuilder: (context, error, stackTrace) {
                                if (kDebugMode) {
                                  print('Carousel image error for ${product.imageUrl}: $error');
                                }
                                return Image.network(
                                  'https://via.placeholder.com/150',
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text('Categories',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                SizedBox(
                  height: 120.0,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildCategoryChip('Pizza', 'assets/images/PIZZA.jpg'),
                      _buildCategoryChip('Chicken', 'assets/images/Whole Grilled chicken'),
                      _buildCategoryChip('Burger', 'assets/images/burgger'),
                      _buildCategoryChip('Beef', 'assets/images/frys'),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      final cartItem = {
                        'title': product.name,
                        'price': product.price,
                        'image': product.imageUrl,
                        'quantity': 1,
                      };
                      return ProductCard(
                        product: cartItem,
                        onAddToCart: () {
                          cartProvider.addItem(cartItem);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${product.name} added to cart')),
                          );
                        },
                        isInCart:
                            cartProvider.items.any((item) => item['title'] == product.name),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryChip(String label, String category) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: InkWell(
        onTap: () => _filterByCategory(category),
        child: Column(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: AssetImage('assets/images/$category.jpg'),
            ),
            const SizedBox(height: 5),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onAddToCart;
  final bool isInCart;

  const ProductCard({
    super.key,
    required this.product,
    required this.onAddToCart,
    required this.isInCart,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              child: _buildImage(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['title']?.toString() ?? 'Unknown Item',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'UGX ${product['price']?.toStringAsFixed(0) ?? '0'}',
                      style: TextStyle(color: Colors.green[700]),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.add_shopping_cart,
                        color: isInCart ? Colors.blue : Colors.black,
                      ),
                      onPressed: onAddToCart,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    final imageUrl = product['image']?.toString() ?? 'https://via.placeholder.com/150';
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(child: CircularProgressIndicator());
      },
      errorBuilder: (context, error, stackTrace) {
        if (kDebugMode) {
          print('ProductCard image error for $imageUrl: $error');
        }
        return Image.network(
          'https://via.placeholder.com/150',
          fit: BoxFit.cover,
          width: double.infinity,
        );
      },
    );
  }
}