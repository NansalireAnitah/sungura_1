import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:universal_html/html.dart' as html if (dart.library.io) 'dart:io';
import '../models/product_model.dart';
import '../providers/product_provider.dart';

class AddProductScreen extends StatefulWidget {
  final Product? product;
  const AddProductScreen({super.key, this.product});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _categoryController;
  dynamic _image; // Can be File (mobile) or html.File (web)
  Uint8List? _imageBytes; // Store image bytes for web
  bool _isAvailable = true;
  bool _isUploading = false;
  String? _uploadError;
  final _picker = ImagePicker();
  final String _imgbbApiKey = "a76d491b3f50093fddaf42dcfaedc1c6";

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.product?.description ?? '');
    _priceController =
        TextEditingController(text: widget.product?.price.toStringAsFixed(0) ?? '');
    _categoryController =
        TextEditingController(text: widget.product?.category ?? '');
    _isAvailable = widget.product?.isAvailable ?? true;
  }

  Future<void> _pickImage() async {
    try {
      if (kIsWeb) {
        // Web implementation
        final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
        uploadInput.accept = 'image/*';
        uploadInput.click();
        
        uploadInput.onChange.listen((e) {
          final files = uploadInput.files;
          if (files != null && files.isNotEmpty) {
            final file = files[0];
            final reader = html.FileReader();
            
            reader.onLoadEnd.listen((e) {
              setState(() {
                _imageBytes = reader.result as Uint8List?;
                _uploadError = null;
              });
            });
            
            reader.onError.listen((e) {
              setState(() => _uploadError = 'Failed to read image file');
            });
            
            reader.readAsArrayBuffer(file);
          }
        });
      } else {
        // Mobile implementation
        final pickedFile = await _picker.pickImage(
            source: ImageSource.gallery, imageQuality: 85);
        if (pickedFile != null) {
          setState(() {
            _image = File(pickedFile.path);
            _uploadError = null;
          });
        }
      }
    } catch (e) {
      setState(() => _uploadError = 'Image selection failed: $e');
    }
  }

  Future<String?> _uploadImageToImgBB() async {
    try {
      final uri = Uri.parse('https://api.imgbb.com/1/upload');
      final request = http.MultipartRequest('POST', uri);
      
      request.fields['key'] = _imgbbApiKey;
      
      if (kIsWeb) {
        if (_imageBytes == null) return null;
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            _imageBytes!,
            filename: 'product_image.jpg',
          ),
        );
      } else {
        if (_image == null) return null;
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            _image!.path,
          ),
        );
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonData = jsonDecode(responseData);

      if (jsonData['success'] == true) {
        return jsonData['data']['url'];
      } else {
        throw Exception('Failed to upload image: ${jsonData['error']?.toString() ?? 'Unknown error'}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Image upload error: $e');
      }
      throw Exception('Image upload failed: $e');
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    
    // For new products, require an image
    if ((_image == null && _imageBytes == null) && widget.product == null) {
      setState(() => _uploadError = 'Please select an image');
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadError = null;
    });

    try {
      String? imageUrl;
      
      // Upload new image if selected
      if (_image != null || _imageBytes != null) {
        imageUrl = await _uploadImageToImgBB();
        if (imageUrl == null) {
          throw Exception('Image upload returned no URL');
        }
      }

      final product = Product(
        id: widget.product?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        description: _descriptionController.text,
        price: double.parse(_priceController.text),
        category: _categoryController.text,
        imageUrl: imageUrl ?? widget.product?.imageUrl ?? 'https://via.placeholder.com/150',
        isAvailable: _isAvailable,
        createdAt: widget.product?.createdAt ?? DateTime.now(),
      );

      final provider = Provider.of<ProductProvider>(context, listen: false);
      if (widget.product == null) {
        await provider.addProduct(product);
      } else {
        await provider.updateProduct(product);
      }
      
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (kDebugMode) {
        print('Save product error: $e');
      }
      setState(() => _uploadError = 'Failed to save product: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildImageSelector(),
                    if (_uploadError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          _uploadError!,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    const SizedBox(height: 20),
                    _buildFormFields(),
                    const SizedBox(height: 20),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
          ),
          if (_isUploading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildImageSelector() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: _buildImageContent(),
      ),
    );
  }

  Widget _buildImageContent() {
    if (kIsWeb && _imageBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(_imageBytes!, fit: BoxFit.cover),
      );
    }
    if (!kIsWeb && _image != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(_image!, fit: BoxFit.cover),
      );
    }
    if (widget.product?.imageUrl.isNotEmpty == true) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          widget.product!.imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(child: CircularProgressIndicator());
          },
          errorBuilder: (context, error, stackTrace) {
            if (kDebugMode) {
              print('AddProductScreen image error: $error');
            }
            return _buildPlaceholderContent();
          },
        ),
      );
    }
    return _buildPlaceholderContent();
  }

  Widget _buildPlaceholderContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.image, size: 50, color: Colors.grey[400]),
        const SizedBox(height: 8),
        Text(
          'Tap to select image',
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Product Name',
            border: OutlineInputBorder(),
          ),
          validator: (value) => value!.isEmpty ? 'Required field' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          validator: (value) => value!.isEmpty ? 'Required field' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _priceController,
          decoration: const InputDecoration(
            labelText: 'Price (UGX)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value!.isEmpty) return 'Required field';
            if (double.tryParse(value) == null) return 'Invalid number';
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _categoryController,
          decoration: const InputDecoration(
            labelText: 'Category',
            border: OutlineInputBorder(),
          ),
          validator: (value) => value!.isEmpty ? 'Required field' : null,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Text('Available', style: TextStyle(fontSize: 16)),
            const Spacer(),
            Switch(
              value: _isAvailable,
              onChanged: (value) => setState(() => _isAvailable = value),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: _isUploading ? null : _saveProduct,
        child: _isUploading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.white,
                ),
              )
            : Text(
                widget.product == null ? 'SAVE PRODUCT' : 'UPDATE PRODUCT',
                style: const TextStyle(fontSize: 16),
              ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    super.dispose();
  }
}