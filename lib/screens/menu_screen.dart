import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:front_end/screens/category.dart';
import 'package:front_end/screens/order_screen.dart';
import 'package:front_end/screens/notification_screen.dart';
import 'package:front_end/screens/product_card.dart';
import 'package:front_end/screens/profile_screen.dart';
import 'package:front_end/screens/pizzacart.dart'; 
import 'package:front_end/screens/chickencart.dart'; 

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final List<Map<String, dynamic>> products = [
    {
      'imagePath': 'assets/images/grill.jpg',
      'title': 'Grilled Chicken',
      'price': 60000,
      'isAddedToCart': false,
    },
    {
      'imagePath': 'assets/images/PIZZA.jpg',
      'title': 'Cheesy Pizza',
      'price': 45000,
      'isAddedToCart': false,
    },
    {
      'imagePath': 'assets/images/burgger.jpg',
      'title': 'Beef Burger',
      'price': 35000,
      'isAddedToCart': false,
    },
    {
      'imagePath': 'assets/images/meat.jpg',
      'title': 'Fresh Salad',
      'price': 25000,
      'isAddedToCart': false,
    },
    {
      'imagePath': 'assets/images/lit1.jpg',
      'title': 'Chocolate Cake',
      'price': 20000,
      'isAddedToCart': false,
    },
    {
      'imagePath': 'assets/images/juicy.jpg',
      'title': 'Fresh Juice',
      'price': 15000,
      'isAddedToCart': false,
    },
  ];

  final List<Map<String, dynamic>> cartItems = [];

  void addToCart(Map<String, dynamic> product) {
    setState(() {
      final existingItem = cartItems.firstWhere(
        (item) => item['name'] == product['title'],
        orElse: () => {},
      );
      if (existingItem.isNotEmpty) {
        existingItem['quantity'] += 1;
      } else {
        cartItems.add({
          'name': product['title'],
          'price': product['price'],
          'image': product['imagePath'],
          'quantity': 1,
        });
      }
      product['isAddedToCart'] = true;
    });
  }

  void navigateToCart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderScreen(cartItems: cartItems, onAddToCart: addToCart),
      ),
    );
  }

  void navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProfileScreen(),
      ),
    );
  }

  void navigateToPizzaMenu() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PizzaMenuScreen(cartItems: cartItems, onAddToCart: addToCart),
      ),
    );
  }

  void navigateToChickenMenu() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChickenCornerScreen(cartItems: cartItems, onAddToCart: addToCart),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: ColorFiltered(
            colorFilter: const ColorFilter.mode(
              Colors.white,
              BlendMode.srcIn,
            ),
            child: Image.asset(
              'assets/images/back.png',
              width: 24.0,
              height: 24.0,
            ),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Container(
          padding: const EdgeInsets.all(8.0),
          child: const Text(
            'Menu',
            style: TextStyle(color: Color.fromARGB(255, 253, 253, 253)),
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 103, 100, 253),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search',
                  prefixIcon:
                      const Icon(Icons.search, color: Color(0xFFF02B3D)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            // Carousel for images
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: CarouselSlider(
                options: CarouselOptions(
                  height: 200,
                  enlargeCenterPage: true,
                  autoPlay: true,
                  aspectRatio: 16 / 9,
                  viewportFraction: 0.8,
                ),
                items: [
                  'assets/images/PIZZA.jpg',
                  'assets/images/meat.jpg',
                  'assets/images/sungura.png',
                ].map((image) {
                  return Builder(
                    builder: (BuildContext context) {
                      return Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage(image),
                            fit: BoxFit.cover,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Categories",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
              ),
            ),
            // Horizontally scrollable categories
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Category Icon for Pizza
                  CategoryIcon(
                    imagePath: 'assets/images/PIZZA.jpg',
                    label: 'Pizza',
                    onTap: navigateToPizzaMenu,
                  ),
                  // Category Icon for Chicken
                  CategoryIcon(
                    imagePath: 'assets/images/grill.jpg',
                    label: 'Chicken',
                    onTap: navigateToChickenMenu,
                  ),
                  // Add more categories as needed
                ],
              ),
            ),
            // Product Grid
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10.0,
                  crossAxisSpacing: 10.0,
                  childAspectRatio: 2 / 3,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return ProductCard(
                    imagePath: product['imagePath'],
                    title: product['title'],
                    price: product['price'].toString(),
                    onAddToCart: () => addToCart(product),
                    cartButtonColor: product['isAddedToCart']
                        ? Colors.purple.withOpacity(0.6)
                        : Colors.black,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF0050A5),
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        onTap: (index) {
          if (index == 1) {
            navigateToCart();
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const NotificationScreen(notifications: []),
              ),
            );
          } else if (index == 3) {
            navigateToProfile();
          }
        },
      ),
    );
  }
}
