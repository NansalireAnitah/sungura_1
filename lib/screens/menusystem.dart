// // lib/screens/menusystem.dart
// import 'package:flutter/material.dart';
// import 'package:front_end/models/menuitem.dart'; // Import MenuItem model
// import 'package:front_end/screens/add_food_screen.dart'; // Import form for adding/editing menu items

// class MenuManagementScreen extends StatefulWidget {
//   const MenuManagementScreen({super.key, required List<Map<String, dynamic>> menuItems});

//   @override
//   _MenuManagementScreenState createState() => _MenuManagementScreenState();
// }

// class _MenuManagementScreenState extends State<MenuManagementScreen> {
//   List<MenuItem> menuItems = []; // List of menu items

//   @override
//   void initState() {
//     super.initState();
//     // Load menu items, for example, from a database or API.
//     // For testing, let's add some dummy data.
//     menuItems = [
//       MenuItem(
//         name: "Pizza",
//         description: "Delicious cheese pizza",
//         price: 12.99,
//         imageUrl: "assets/images/pizza.jpg",
//       ),
//       MenuItem(
//         name: "Burger",
//         description: "Juicy beef burger",
//         price: 8.99,
//         imageUrl: "assets/images/burger.jpg",
//       ),
//     ];
//   }

//   // Add a new menu item
//   Future<void> addMenuItem(MenuItem menuItem) async {
//     setState(() {
//       menuItems.add(menuItem);
//     });
//   }

//   // Edit an existing menu item
//   Future<void> updateMenuItem(MenuItem menuItem, int index) async {
//     setState(() {
//       menuItems[index] = menuItem;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Manage Menu'),
//       ),
//       body: menuItems.isEmpty
//           ? const Center(child: Text('No menu items available.'))
//           : ListView.builder(
//               itemCount: menuItems.length,
//               itemBuilder: (context, index) {
//                 var item = menuItems[index];
//                 return ListTile(
//                   title: Text(item.name),
//                   subtitle: Text(item.description),
//                   trailing: Text('\$${item.price}'),
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => AddEditMenuItemForm(
//                           menuItem: item,
//                           onSave: (updatedItem) {
//                             updateMenuItem(updatedItem, index);
//                           },
//                         ),
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//     );
//   }
// }
