import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart' as carousel;
import 'package:cloud_firestore/cloud_firestore.dart';
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
  String? _selectedCategory;

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
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          filteredProducts = query.isEmpty
              ? _selectedCategory == null
                  ? productProvider.products
                  : productProvider.products
                      .where((product) => product.category == _selectedCategory)
                      .toList()
              : productProvider.products.where((product) {
                  final name = product.name.toLowerCase();
                  return name.contains(query);
                }).toList();
          if (query.isNotEmpty)
            _selectedCategory = null; // Clear category filter on search
        });
      }
    });
  }

  void _filterByCategory(String category) {
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _selectedCategory = category;
          filteredProducts = productProvider.products
              .where((product) => product.category == category)
              .toList();
        });
      }
    });
  }

  void _clearCategoryFilter() {
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _selectedCategory = null;
          filteredProducts = productProvider.products
              .where((product) => product.isAvailable)
              .toList();
        });
      }
    });
  }

  double getViewportFraction(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return 0.85;
    if (width < 1200) return 0.6;
    return 0.4;
  }

  double getCarouselHeight(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return height < 600 ? height * 0.3 : height * 0.4;
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sungura House'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 2,
      ),
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, _) {
          if (productProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (filteredProducts.isEmpty && !productProvider.isLoading) {
            filteredProducts =
                productProvider.products.where((p) => p.isAvailable).toList();
          }
          if (filteredProducts.isEmpty) {
            return const Center(child: Text('No products available'));
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  margin: const EdgeInsets.symmetric(
                      horizontal: 10.0, vertical: 5.0),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('carousel_items')
                        .where('isVisible', isEqualTo: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return const Center(
                            child: Text('Error loading carousel'));
                      }
                      final items = snapshot.data?.docs ?? [];
                      if (items.isEmpty) {
                        return const Center(child: Text('No carousel items'));
                      }
                      return carousel.CarouselSlider(
                        options: carousel.CarouselOptions(
                          height: getCarouselHeight(context),
                          aspectRatio: 16 / 9,
                          viewportFraction: getViewportFraction(context),
                          initialPage: 0,
                          enableInfiniteScroll: true,
                          reverse: false,
                          autoPlay: true,
                          autoPlayInterval: const Duration(seconds: 3),
                          autoPlayAnimationDuration:
                              const Duration(milliseconds: 800),
                          autoPlayCurve: Curves.fastOutSlowIn,
                          enlargeCenterPage: true,
                          scrollDirection: Axis.horizontal,
                        ),
                        items: items.map((item) {
                          return Container(
                            margin: const EdgeInsets.all(6.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8.0),
                              image: DecorationImage(
                                image: NetworkImage(item['imageUrl']),
                                fit: BoxFit.cover,
                                onError: (exception, stackTrace) {
                                  if (kDebugMode) {
                                    print(
                                        'Carousel image error for ${item['imageUrl']}: $exception');
                                  }
                                },
                              ),
                            ),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                color: Colors.black.withOpacity(0.5),
                                padding: const EdgeInsets.all(8.0),
                                width: double.infinity,
                                child: Text(
                                  item['label'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Categories',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      if (_selectedCategory != null)
                        TextButton(
                          onPressed: _clearCategoryFilter,
                          child: const Text(
                            'Clear',
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 100.0,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    children: [
                      _buildCategoryChip('Pizza', 'assets/images/pizza.jpg'),
                      _buildCategoryChip('Chicken', 'assets/images/grill.jpg'),
                      _buildCategoryChip('Burger', 'assets/images/burgger.jpg'),
                      _buildCategoryChip('Beef', 'assets/images/frys.jpg'),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      final cartItem = {
                        'id': product
                            .id, // Added to support CartProvider duplicate check
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
                            SnackBar(
                                content: Text('${product.name} added to cart')),
                          );
                        },
                        isInCart: cartProvider.items
                            .any((item) => item['id'] == product.id),
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

  Widget _buildCategoryChip(String label, String imagePath) {
    final isSelected = _selectedCategory == label;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: InkWell(
        onTap: () => _filterByCategory(label),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor:
                  isSelected ? Colors.green[100] : Colors.grey[200],
              child: ClipOval(
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  width: 60,
                  height: 60,
                  errorBuilder: (context, error, stackTrace) {
                    if (kDebugMode) {
                      print('Category image error for $imagePath: $error');
                    }
                    return Icon(
                      Icons.image_not_supported,
                      size: 30,
                      color: Colors.grey[600],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.green : Colors.black,
              ),
            ),
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
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(10)),
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
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'UGX ${product['price']?.toStringAsFixed(0) ?? '0'}',
                      style: TextStyle(color: Colors.green[700], fontSize: 12),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.add_shopping_cart,
                        color: isInCart ? Colors.blue : Colors.black,
                        size: 20,
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
    final imageUrl =
        product['image']?.toString() ?? 'https://via.placeholder.com/150';
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
