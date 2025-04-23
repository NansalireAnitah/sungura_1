import 'package:flutter/material.dart';

class JuiceScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems; // Accepting cartItems as a parameter
  final void Function(Map<String, dynamic> product) onAddToCart;

  const JuiceScreen({super.key, required this.cartItems, required this.onAddToCart});

  @override
  _JuiceScreenState createState() => _JuiceScreenState();
}

class _JuiceScreenState extends State<JuiceScreen> {
  String selectedJuice = 'Passion Fruit';
  int price = 8000; // Default price for Passion Fruit

  final List<Map<String, dynamic>> juiceOptions = [
    {"name": "Passion Fruit", "image": 'assets/images/juice.jpg', "price": 8000},
    {"name": "Mango", "image": 'assets/images/juice.jpg', "price": 7000},
    {"name": "Pineapple", "image": 'assets/images/juice.jpg', "price": 7500},
    {"name": "Lemon", "image": 'assets/images/juice.jpg', "price": 6000},
  ];

  void addToCart(String juiceName, int price, String image) {
    bool exists = widget.cartItems.any((item) => item['name'] == juiceName);

    if (!exists) {
      setState(() {
        widget.cartItems.add({
          'name': juiceName,
          'price': price,
          'quantity': 1,
          'image': image,
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$juiceName added to cart!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Juice Menu"),
        centerTitle: true,
        backgroundColor: Colors.red,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Juice Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // Two items per row
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                  childAspectRatio: 0.75, // Adjusted to fit the content
                ),
                itemCount: juiceOptions.length,
                itemBuilder: (context, index) {
                  final juice = juiceOptions[index];
                  return InkWell(
                    onTap: () {
                      setState(() {
                        selectedJuice = juice["name"];
                        price = juice["price"];
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 5,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Image that fits well in the box
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              juice["image"],
                              height: 150, // Adjust height as needed
                              width: double.infinity,
                              fit: BoxFit.cover, // Ensures the image covers the box well
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Juice Name
                          Text(
                            juice["name"],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // Row for Price and Add to Cart Icon
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Price
                                Text(
                                  'UGX.${juice["price"]}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                // Add to Cart Icon
                                IconButton(
                                  icon: const Icon(Icons.add_shopping_cart),
                                  onPressed: () {
                                    addToCart(juice["name"], juice["price"], juice["image"]);
                                  },
                                  color: Colors.red,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
