import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddItemDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onAdd;

  const AddItemDialog({super.key, required this.onAdd});

  @override
  _AddItemDialogState createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  File? _image;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void _submitForm() {
    if (_nameController.text.isEmpty || _priceController.text.isEmpty || _image == null) {
      return;
    }

    final Map<String, dynamic> newItem = {
      'title': _nameController.text,
      'price': double.parse(_priceController.text),
      'imagePath': _image!.path,
      'isAddedToCart': false,
    };

    widget.onAdd(newItem);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Add Food Item"),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Food Name"),
            ),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: "Price"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            _image == null
                ? TextButton(
                    onPressed: _pickImage,
                    child: const Text("Pick Image"),
                  )
                : Image.file(
                    _image!,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _submitForm,
              child: const Text("Add Item"),
            ),
          ],
        ),
      ),
    );
  }
}
