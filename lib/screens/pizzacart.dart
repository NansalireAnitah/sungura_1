import 'package:flutter/material.dart';
import 'package:front_end/screens/order_screen.dart';

class PizzaMenuScreen extends StatefulWidget {
  const PizzaMenuScreen(
      {super.key, required this.cartItems, required this.onAddToCart});

  final List<Map<String, dynamic>> cartItems;
  final void Function(Map<String, dynamic> product) onAddToCart;

  @override
  _PizzaMenuScreenState createState() => _PizzaMenuScreenState();
}

class _PizzaMenuScreenState extends State<PizzaMenuScreen> {
  String selectedPizza = "Meat Festivals Pizza";
  String selectedSize = "Large";
  int price = 36000; // Initial price

  final List<Map<String, dynamic>> pizzaOptions = [
    {"name": "Meat Festivals Pizza", "image": 'assets/images/PIZZA.jpg'},
    {"name": "Chicken Royal Pizza", "image": 'assets/images/PIZZA.jpg'},
    {"name": "Golden Crust Rabbit Pizza", "image": 'assets/images/PIZZA.jpg'},
    {"name": "Hawaiian Pizza", "image": 'assets/images/PIZZA.jpg'},
  ];

  void updatePrice(String size) {
    setState(() {
      selectedSize = size;
      price = size == "Large" ? 36000 : 30000;
    });
  }

  void addToCart() {
    bool exists = widget.cartItems.any((item) =>
        item['name'] == selectedPizza && item['size'] == selectedSize);

    if (!exists) {
      setState(() {
        widget.cartItems.add({
          'name': selectedPizza,
          'size': selectedSize,
          'price': price,
          'quantity': 1,
          'image': pizzaOptions
              .firstWhere((pizza) => pizza['name'] == selectedPizza)['image'],
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("$selectedPizza ($selectedSize) added to cart!")),
      );
    }
  }

  void navigateToCart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderScreen(
          cartItems: widget.cartItems,
          onAddToCart: (Map<String, dynamic> product) {
            // Handle the addition of product to cart if necessary
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pizza Menu"),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 247, 244, 244),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Pizza Image
              ClipRRect(
                borderRadius: BorderRadius.circular(16.0),
                child: Image.asset(
                  'assets/images/PIZZA.jpg',
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16.0),

              // Pizza Options
              Column(
                children: pizzaOptions.map((pizza) {
                  return InkWell(
                    onTap: () {
                      setState(() {
                        selectedPizza = pizza["name"];
                      });
                    },
                    child: MouseRegion(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: selectedPizza == pizza["name"]
                              ? const Color.fromARGB(255, 108, 82, 255)
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              pizza["name"],
                              style: TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                                color: selectedPizza == pizza["name"]
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16.0),

              // Size Selection
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  InkWell(
                    onTap: () => updatePrice("Large"),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                        color: selectedSize == "Large"
                            ? const Color.fromARGB(255, 99, 82, 255)
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text("Large"),
                    ),
                  ),
                  InkWell(
                    onTap: () => updatePrice("Medium"),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                        color: selectedSize == "Medium"
                            ? const Color.fromARGB(255, 82, 85, 255)
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text("Medium"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24.0),

              // Add to Cart Button
              ElevatedButton(
                onPressed: addToCart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 255, 82, 82),
                  padding: const EdgeInsets.symmetric(
                      vertical: 12.0, horizontal: 24.0),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0)),
                ),
                child: const Text("Add to Cart",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16.0),
            ],
          ),
        ),
      ),
    );
  }
}
