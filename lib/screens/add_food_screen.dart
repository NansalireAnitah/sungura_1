import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddFoodItemScreen extends StatefulWidget {
  const AddFoodItemScreen({super.key});

  @override
  _AddFoodItemScreenState createState() => _AddFoodItemScreenState();
}

class _AddFoodItemScreenState extends State<AddFoodItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  late File _selectedImage; // Removed nullable type

  final ImagePicker _picker = ImagePicker();

  // Function to pick image from gallery
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery); // Removed `dynamic`
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Handle form submission
      String name = _nameController.text;
      String price = _priceController.text;

      print('Food Name: $name');
      print('Price: $price');
      print('Image Path: ${_selectedImage.path}');

      // Navigate back to dashboard
      Navigator.pop(context);
    // ignore: unnecessary_null_comparison
    } else if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload an image.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Food Item'),
        backgroundColor: const Color(0xFFAA2A00),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Food Name Input
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Food Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the food name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Price Input
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the price';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Image Upload Section
                const Text(
                  'Food Image',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                // ignore: unnecessary_null_comparison
                _selectedImage != null
                    ? Image.file(
                        _selectedImage,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : const Text('No image selected.'),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image),
                  label: const Text('Upload Image'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFAA2A00),
                  ),
                ),
                const SizedBox(height: 16),

                // Submit Button
                ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFAA2A00), // Button color
                  ),
                  child: const Text('Add Item'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
 