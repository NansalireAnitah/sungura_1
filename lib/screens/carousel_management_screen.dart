import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CarouselManagementScreen extends StatefulWidget {
  const CarouselManagementScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _CarouselManagementScreenState createState() =>
      _CarouselManagementScreenState();
}

class _CarouselManagementScreenState extends State<CarouselManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imageUrlController = TextEditingController();
  final _labelController = TextEditingController();
  bool _isVisible = true;
  String? _editingId;
  File? _selectedFile;
  bool _isUploading = false;

  // Replace with your ImgBB API key
  final String _imgbbApiKey = 'a76d491b3f50093fddaf42dcfaedc1c6';

  // Firestore reference to the 'carousel_items' collection
  final CollectionReference carouselCollection =
      FirebaseFirestore.instance.collection('carousel_items');

  // Pick a file (image or video)
  Future<void> _pickFile() async {
    try {
      // FilePickerResult? result = await FilePicker.platform.pickFiles(
      //   type: FileType.custom,
      //   allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'mp4'],
      // );

      // if (result != null && result.files.single.path != null) {
      //   File file = File(result.files.single.path!);
      //   // Check file size (ImgBB limit: 32MB)
      //   final fileSizeMB = file.lengthSync() / (1024 * 1024);
      //   if (fileSizeMB > 32) {
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       const SnackBar(content: Text('File size exceeds 32MB limit')),
      //     );
      //     return;
      //   }
      //   setState(() {
      //     _selectedFile = file;
      //     _imageUrlController.text = result.files.single.name;
      //   });
      // }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    }
  }

  // Upload file to ImgBB and return the URL
  Future<String?> _uploadToImgBB(File file) async {
    setState(() {
      _isUploading = true;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.imgbb.com/1/upload'),
      );
      request.fields['key'] = _imgbbApiKey;
      request.files.add(await http.MultipartFile.fromPath('image', file.path));

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(responseBody);
        if (jsonResponse['success']) {
          return jsonResponse['data']['url'];
        } else {
          throw Exception(
              'ImgBB upload failed: ${jsonResponse['error']['message']}');
        }
      } else {
        throw Exception(
            'ImgBB upload failed with status: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload error: $e')),
      );
      return null;
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  // Adding or updating a carousel item
  Future<void> _saveCarouselItem() async {
    if (_formKey.currentState?.validate() ?? false) {
      String? imageUrl = _imageUrlController.text;

      // If a file is selected, upload to ImgBB
      if (_selectedFile != null) {
        imageUrl = await _uploadToImgBB(_selectedFile!);
        if (imageUrl == null) return; // Upload failed, exit
      }

      if (imageUrl.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image URL is required')),
        );
        return;
      }

      try {
        final data = {
          'imageUrl': imageUrl,
          'label': _labelController.text,
          'isVisible': _isVisible,
          'createdAt': FieldValue.serverTimestamp(),
        };

        if (_editingId != null) {
          // Update existing item
          await carouselCollection.doc(_editingId).update(data);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Updated ${_labelController.text}')),
          );
        } else {
          // Add new item
          await carouselCollection.add(data);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Added ${_labelController.text}')),
          );
        }

        // Clear form
        _imageUrlController.clear();
        _labelController.clear();
        setState(() {
          _isVisible = true;
          _editingId = null;
          _selectedFile = null;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  // Deleting a carousel item
  Future<void> _deleteCarouselItem(String id, String label) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Carousel Item'),
        content: Text('Delete $label permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await carouselCollection.doc(id).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deleted $label')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }

  // Building the form to add/edit carousel items
  Widget _buildCarouselForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _labelController,
            decoration: const InputDecoration(labelText: 'Label'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Label is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _imageUrlController,
                  decoration:
                      const InputDecoration(labelText: 'Image/Video URL'),
                  readOnly:
                      true, // Prevent manual editing since URL comes from ImgBB
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a file or enter a URL';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isUploading ? null : _pickFile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC107),
                  foregroundColor: Colors.black,
                ),
                child: Text(_isUploading ? 'Uploading...' : 'Pick File'),
              ),
            ],
          ),
          if (_selectedFile != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('Selected: ${_selectedFile!.path.split('/').last}'),
            ),
          SwitchListTile(
            title: const Text('Visibility'),
            value: _isVisible,
            onChanged: (bool value) {
              setState(() {
                _isVisible = value;
              });
            },
          ),
          ElevatedButton(
            onPressed: _isUploading ? null : _saveCarouselItem,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFC107),
              foregroundColor: Colors.black,
            ),
            child: Text(_editingId != null ? 'Update Item' : 'Add Item'),
          ),
        ],
      ),
    );
  }

  // Building the list of carousel items
  Widget _buildCarouselList() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          carouselCollection.orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        var items = snapshot.data?.docs ?? [];
        if (items.isEmpty) {
          return const Center(child: Text('No carousel items added.'));
        }

        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            var item = items[index];
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: ListTile(
                leading: SizedBox(
                  width: 50,
                  height: 50,
                  child: Image.network(
                    item['imageUrl'],
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) {
                      if (kDebugMode) {
                        print(
                            'Carousel image error for ${item['imageUrl']}: $error');
                      }
                      return const Icon(Icons.image_not_supported, size: 50);
                    },
                  ),
                ),
                title: Text(item['label']),
                subtitle: Text(item['imageUrl']),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item['isVisible']
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: item['isVisible'] ? Colors.green : Colors.red,
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        setState(() {
                          _editingId = item.id;
                          _imageUrlController.text = item['imageUrl'];
                          _labelController.text = item['label'];
                          _isVisible = item['isVisible'];
                          _selectedFile = null; // Clear file for editing
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () =>
                          _deleteCarouselItem(item.id, item['label']),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _imageUrlController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Carousel'),
        backgroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCarouselForm(),
            const SizedBox(height: 20),
            const Text(
              'Carousel Items',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Expanded(child: _buildCarouselList()),
          ],
        ),
      ),
    );
  }
}
