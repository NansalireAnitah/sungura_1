import 'package:flutter/material.dart';
import 'order_screen.dart'; // Assuming the OrderScreen is in this file.

class ChickenCornerScreen extends StatefulWidget {
  const ChickenCornerScreen({
    super.key,
    required this.cartItems,
    required this.onAddToCart,
  });

  final List<Map<String, dynamic>> cartItems;
  final Function(Map<String, dynamic>) onAddToCart;

  @override
  _ChickenCornerScreenState createState() => _ChickenCornerScreenState();
}

class _ChickenCornerScreenState extends State<ChickenCornerScreen> {
  String selectedChicken = "Grilled Chicken";

  final List<Map<String, dynamic>> chickenOptions = [
    {
      "name": "Grilled Chicken Breast",
      "price": 25000,
      "image": 'assets/images/grilled chicken thigh.jpg'
    },
    {
      "name": "Pan-fried Chicken",
      "price": 28000,
      "image": 'assets/images/Panfriedchicken.jpg'
    },
    {
      "name": "African Boiled Chicken",
      "price": 25000,
      "image": 'assets/images/African Boiled chicken.jpg'
    },
    {
      "name": "Family Whole Grilled",
      "price": 55000,
      "image": 'assets/images/Whole Grilled chicken.jpg'
    },
    {
      "name": "Pan-fried DrumSticks",
      "price": 28000,
      "image": 'assets/images/panfried drumsticks.jpg'
    },
    {
      "name": "Chicken wings",
      "price": 25000,
      "image": 'assets/images/Chickenwings.jpg'
    },
    {
      "name": "Chicken lollipops",
      "price": 25000,
      "image": 'assets/images/Chicken lollipops.jpg'
    },
    {
      "name": "Chicken Stewers",
      "price": 25000,
      "image": 'assets/images/Chicken stewers.jpg'
    },
  ];

  void addToCart(String chickenName) {
    final selectedProduct = chickenOptions.firstWhere(
      (chicken) => chicken['name'] == chickenName,
      orElse: () => {},
    );

    if (selectedProduct.isNotEmpty) {
      final cartItem = {
        "name": selectedProduct["name"],
        "price": selectedProduct["price"],
        "image": selectedProduct["image"],
        "quantity": 1,
      };

      widget.onAddToCart(cartItem);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${selectedProduct['name']} added to cart!"),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No valid product selected!"),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void navigateToCart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderScreen(
            cartItems: widget.cartItems, onAddToCart: widget.onAddToCart),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chicken Corner"),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 88, 86, 248),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: ColorFiltered(
            colorFilter: const ColorFilter.mode(
              Colors.white,
              BlendMode.srcIn,
            ),
            child: Image.asset(
              'assets/images/back.png',
              width: 24,
              height: 24,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10.0,
                    mainAxisSpacing: 10.0,
                    childAspectRatio: 2 / 3,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final chicken = chickenOptions[index];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedChicken = chicken["name"];
                          });
                        },
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.asset(
                                    chicken["image"],
                                    height: double.infinity,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0, vertical: 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      chicken["name"] ?? "Unknown",
                                      style: const TextStyle(
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8.0),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "UGX ${chicken["price"] ?? 0}",
                                          style: const TextStyle(
                                            fontSize: 14.0,
                                            color: Colors.green,
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () =>
                                              addToCart(chicken["name"]),
                                          icon: const Icon(
                                            Icons.add_shopping_cart,
                                            color: Color.fromARGB(
                                                255, 245, 58, 105),
                                            size: 30,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: chickenOptions.length,
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 16.0,
            left: 16.0,
            right: 16.0,
            child: ElevatedButton(
              onPressed: navigateToCart,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(
                    vertical: 12.0, horizontal: 24.0),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0)),
              ),
              child: const Text("Go to Cart",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
