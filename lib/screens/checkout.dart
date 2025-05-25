import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:front_end/screens/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:front_end/models/notification_model.dart';
import 'package:front_end/providers/notification_provider.dart';
import 'package:front_end/screens/login_screen.dart';
import 'package:front_end/screens/signup.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class CheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final Function(String) onOrderPlaced;
  final Function(Map<String, dynamic>) onAddToCart;

  const CheckoutScreen({
    Key? key,
    required this.cartItems,
    required this.onOrderPlaced,
    required this.onAddToCart,
  }) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int _currentStep = 0;
  String _selectedOption = 'Take Away';
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isMapReady = false;
  final firestore.FirebaseFirestore _firestore = firestore.FirebaseFirestore.instance;
  String? _userName;

  // Map-related variables
  GoogleMapController? _mapController;
  LatLng _selectedLocation = const LatLng(0.3476, 32.5825); // Kampala center
  String? _selectedAddress;
  List<Map<String, dynamic>> _placeSuggestions = [];
  bool _isSearching = false;
  Timer? _debounce;

  // Nearby locations variables
  List<Map<String, dynamic>> _nearbyLocations = [];
  bool _isFetchingNearby = false;

  // Google Maps API key
  final String _googleApiKey = 'AIzaSyA7w9jicOGfuPbUILRJBud1sVGCukZ-7rI'; // Replace with your actual API key

  static const _takeAwayImage = 'assets/images/takeaway.jpg';
  static const _deliveryImage = 'assets/images/delivery.jpg';

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _isMapReady = false;
    } else {
      Future.delayed(Duration(milliseconds: 500), () {
        setState(() => _isMapReady = true);
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeUserData();
    });
  }

  Future<void> _initializeUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (user.phoneNumber != null) {
        _phoneController.text = user.phoneNumber!.replaceAll('+256', '');
      }
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      _userName = userDoc.data()?['name']?.toString() ?? 'Anonymous';
    }
    await _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    if (FirebaseAuth.instance.currentUser == null && mounted) {
      _showAuthRequiredDialog();
    }
    setState(() => _isLoading = false);
  }

  void _showAuthRequiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Authentication Required'),
        content: const Text('You need an account to place orders. Please login or sign up.'),
        actions: [
          TextButton(
            onPressed: () => _navigateToAuthScreen(const LoginScreen()),
            child: const Text('Login'),
          ),
          TextButton(
            onPressed: () => _navigateToAuthScreen(const SignUpScreen(isEditing: false)),
            child: const Text('Sign Up'),
          ),
        ],
      ),
    );
  }

  void _navigateToAuthScreen(Widget screen) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen)).then((_) {
      if (mounted) {
        _checkAuthStatus();
      }
    });
  }

  void _handleStepContinue() {
    if (_currentStep == 2 && !_formKey.currentState!.validate()) return;
    if (_currentStep == 2 && _selectedOption == 'Delivery' && _selectedAddress == null) {
      _showErrorSnackbar('Please select a delivery address.');
      return;
    }

    setState(() {
      if (_currentStep < 2) {
        _currentStep++;
      } else {
        _processOrderConfirmation();
      }
    });
  }

  Future<void> _processOrderConfirmation() async {
    final orderId = DateTime.now().millisecondsSinceEpoch.toString();
    final phone = _formatPhone(_phoneController.text);

    try {
      await _saveOrderToFirestore(orderId, phone);
      widget.onOrderPlaced(orderId);
      await _showOrderSuccessDialog(orderId, phone);
    } catch (e) {
      _showErrorSnackbar('Failed to place order: ${e.toString()}');
    }
  }

  Future<void> _saveOrderToFirestore(String orderId, String phone) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final orderData = {
      'id': orderId,
      'items': _formatOrderItems(),
      'total': _calculateTotal(),
      'status': 'Pending',
      'createdAt': firestore.Timestamp.now(),
      'phone': phone,
      'deliveryMethod': _selectedOption,
      'location': _selectedOption == 'Delivery'
          ? {
              'address': _selectedAddress,
              'coordinates': firestore.GeoPoint(
                  _selectedLocation.latitude, _selectedLocation.longitude),
            }
          : null,
      'userId': user.uid,
      'userName': _userName ?? 'Anonymous',
    };

    await _firestore.collection('orders').doc(orderId).set(orderData);
  }

  List<Map<String, dynamic>> _formatOrderItems() {
    return widget.cartItems.map((item) {
      return {
        'name': item['title']?.toString() ?? 'Unknown Item',
        'image': item['image']?.toString() ?? '',
        'price': (item['price'] as num?)?.toDouble() ?? 0.0,
        'quantity': item['quantity'] as int? ?? 1,
      };
    }).toList();
  }

  Future<void> _showOrderSuccessDialog(String orderId, String phone) async {
    final notificationProvider = context.read<NotificationProvider>();
    final user = FirebaseAuth.instance.currentUser;
    final items = _formatOrderItems();
    final total = _calculateTotal();
    final location = _selectedOption == 'Delivery' ? _selectedAddress : 'Take Away';

    final notification = AppNotification(
      id: orderId,
      title: 'Order #${orderId.substring(0, 6)} Confirmed',
      body: 'Tap to view order details or cancel.',
      items: items,
      total: total,
      location: location,
    );

    // Save notification to Firestore
    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(orderId)
          .set(notification.toMap());
    }

    // Add to local provider
    notificationProvider.addNotification(notification);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Order #${orderId.substring(0, 8)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text('Total: ${_formatPrice(total)}'),
            const SizedBox(height: 8),
            Text('Phone: $phone'),
            if (_selectedOption == 'Delivery') ...[
              const SizedBox(height: 8),
              Text('Address: $_selectedAddress'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelOrder(String orderId) async {
    try {
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (!orderDoc.exists) {
        _showErrorSnackbar('Order not found.');
        return;
      }
      final status = orderDoc.data()?['status'] ?? 'Unknown';
      if (status != 'Pending') {
        _showErrorSnackbar('Cannot cancel order: Status is $status.');
        return;
      }
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Delete order and notification from Firestore
        await _firestore.collection('orders').doc(orderId).delete();
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .doc(orderId)
            .delete();
      }
      // Remove from local provider
      context.read<NotificationProvider>().deleteNotification(orderId);
      _showErrorSnackbar('Order cancelled successfully.');
    } catch (e) {
      _showErrorSnackbar('Failed to cancel order: $e');
    }
  }

  double _calculateTotal() {
    return widget.cartItems.fold(0.0, (sum, item) {
      final price = (item['price'] as num?)?.toDouble() ?? 0.0;
      final quantity = item['quantity'] as int? ?? 1;
      return sum + (price * quantity);
    });
  }

  String _formatPrice(double price) => 'UGX ${price.toStringAsFixed(0)}';

  String _formatPhone(String phone) {
    phone = phone.replaceAll(RegExp(r'\D'), '');
    if (phone.length == 9) return '+256 $phone';
    if (phone.length == 12) return '+${phone.substring(0, 3)} ${phone.substring(3)}';
    return phone;
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() {
        _placeSuggestions = [];
        _isSearching = false;
      });
      return;
    }

    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      setState(() => _isSearching = true);

      final lat = _selectedLocation.latitude;
      final lng = _selectedLocation.longitude;
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=$query'
        '&components=country:UG'
        '&location=$lat,$lng'
        '&radius=15000'
        '&types=address|locality'
        '&key=$_googleApiKey',
      );

      try {
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (kDebugMode) {
            print('Places API response: $data');
          }
          if (data['status'] == 'OK') {
            setState(() {
              _placeSuggestions = List<Map<String, dynamic>>.from(data['predictions']);
              _isSearching = false;
            });
            if (kDebugMode) {
              print('Suggestions: $_placeSuggestions');
            }
          } else {
            _showErrorSnackbar('Failed to fetch places: ${data['status']}');
            setState(() => _isSearching = false);
          }
        } else {
          _showErrorSnackbar('Failed to fetch places: HTTP ${response.statusCode}');
          setState(() => _isSearching = false);
        }
      } catch (e) {
        _showErrorSnackbar('Error searching places: $e');
        setState(() => _isSearching = false);
        if (kDebugMode) {
          print('Search error: $e');
        }
      }
    });
  }

  Future<void> _selectPlace(String placeId) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json'
      '?place_id=$placeId'
      '&fields=formatted_address,geometry,name'
      '&key=$_googleApiKey',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (kDebugMode) {
          print('Place details response: $data');
        }
        if (data['status'] == 'OK') {
          final result = data['result'];
          final lat = result['geometry']['location']['lat'];
          final lng = result['geometry']['location']['lng'];
          final address = result['formatted_address'];

          setState(() {
            _selectedLocation = LatLng(lat, lng);
            _selectedAddress = address;
            _placeSuggestions = [];
            _searchController.clear();
            _nearbyLocations = [];
          });

          await _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(_selectedLocation, 16),
          );
          if (kDebugMode) {
            print('Selected location: $_selectedLocation, Address: $_selectedAddress');
          }

          await _fetchNearbyLocations(_selectedLocation);
        } else {
          _showErrorSnackbar('Failed to get place details: ${data['status']}');
        }
      } else {
        _showErrorSnackbar('Failed to get place details: HTTP ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackbar('Error fetching place details: $e');
      if (kDebugMode) {
        print('Place details error: $e');
      }
    }
  }

  Future<void> _fetchNearbyLocations(LatLng location) async {
    if (_googleApiKey.isEmpty) {
      _showErrorSnackbar('Google API key is missing');
      return;
    }

    setState(() => _isFetchingNearby = true);

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
      '?location=${location.latitude},${location.longitude}'
      '&radius=1000'
      '&key=$_googleApiKey',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (kDebugMode) {
          print('Nearby places API response: $data');
        }
        if (data['status'] == 'OK') {
          setState(() {
            _nearbyLocations = List<Map<String, dynamic>>.from(data['results']);
          });
        } else {
          _showErrorSnackbar('Failed to fetch nearby places: ${data['status']}');
          if (kDebugMode) {
            print('Nearby places API error: ${data['status']}');
          }
        }
      } else {
        _showErrorSnackbar('Failed to fetch nearby places: HTTP ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackbar('Error fetching nearby locations: $e');
      if (kDebugMode) {
        print('Error fetching nearby locations: $e');
      }
    } finally {
      setState(() => _isFetchingNearby = false);
    }
  }

  IconData _getPlaceIcon(List<dynamic>? types) {
    if (types == null) return Icons.place;

    if (types.contains('restaurant') || types.contains('food')) {
      return Icons.restaurant;
    } else if (types.contains('store') || types.contains('shopping_mall')) {
      return Icons.shopping_bag;
    } else if (types.contains('school') || types.contains('university')) {
      return Icons.school;
    } else if (types.contains('hospital') || types.contains('health')) {
      return Icons.local_hospital;
    }
    return Icons.place;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _searchController.dispose();
    _mapController?.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Cancel Checkout?'),
                content: const Text('Your order will not be saved.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Stay'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: const Text('Leave'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: _handleStepContinue,
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep--);
          }
        },
        steps: [
          _buildMethodStep(),
          _buildReviewStep(),
          _buildConfirmStep(),
        ],
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: ElevatedButton(
              onPressed: details.onStepContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[800],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                _currentStep == 2 ? 'PLACE ORDER' : 'CONTINUE',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          );
        },
      ),
    );
  }

  Step _buildMethodStep() {
    return Step(
      title: const Text('Delivery Method'),
      content: Column(
        children: [
          _buildOptionCard(
            isSelected: _selectedOption == 'Take Away',
            imagePath: _takeAwayImage,
            label: 'Take Away',
            onTap: () => setState(() => _selectedOption = 'Take Away'),
          ),
          const SizedBox(height: 16),
          _buildOptionCard(
            isSelected: _selectedOption == 'Delivery',
            imagePath: _deliveryImage,
            label: 'Delivery',
            onTap: () => setState(() => _selectedOption = 'Delivery'),
          ),
        ],
      ),
    );
  }

  Step _buildReviewStep() {
    return Step(
      title: const Text('Review Order'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order Summary', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...widget.cartItems.map((item) {
            final price = (item['price'] as num?)?.toDouble() ?? 0.0;
            final quantity = item['quantity'] as int? ?? 1;
            final imageUrl = item['image']?.toString() ?? 'https://via.placeholder.com/150';
            return Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[200],
                            child: const Center(child: CircularProgressIndicator()),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          if (kDebugMode) {
                            print('Checkout item image error for $imageUrl: $error');
                          }
                          return Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[200],
                            child: const Icon(Icons.fastfood, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item['title']} x$quantity',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatPrice(price * quantity),
                            style: TextStyle(color: Colors.green[700], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                _formatPrice(_calculateTotal()),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Step _buildConfirmStep() {
    return Step(
      title: const Text('Confirm Details'),
      content: Directionality(
        textDirection: TextDirection.ltr,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixText: '+256 ',
                ),
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.start,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (!RegExp(r'^\d{9}$').hasMatch(value)) {
                    return 'Enter valid 9-digit number';
                  }
                  return null;
                },
              ),
              if (_selectedOption == 'Delivery') ...[
                const SizedBox(height: 16),
                const Text(
                  'Select Delivery Address',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (kIsWeb)
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: TextFormField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        labelText: 'Delivery Address',
                        hintText: 'Enter your delivery address',
                      ),
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.start,
                      onChanged: (value) {
                        setState(() => _selectedAddress = value);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter delivery address';
                        }
                        return null;
                      },
                    ),
                  )
                else ...[
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search Address in Kampala (e.g., Kireka)',
                      suffixIcon: _isSearching
                          ? const CircularProgressIndicator()
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _placeSuggestions = []);
                              },
                            ),
                    ),
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.start,
                    onChanged: (value) => _searchPlaces(value),
                  ),
                  if (_placeSuggestions.isNotEmpty)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _placeSuggestions.length,
                        itemBuilder: (context, index) {
                          final place = _placeSuggestions[index];
                          return ListTile(
                            title: Text(
                              place['structured_formatting']?['main_text'] ?? place['description'] ?? 'Unknown',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              place['structured_formatting']?['secondary_text'] ?? 'No additional info',
                              style: const TextStyle(fontSize: 12),
                            ),
                            onTap: () => _selectPlace(place['place_id']),
                          );
                        },
                      ),
                    )
                  else if (!_isSearching && _searchController.text.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'No suggestions found. Try a different search.',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Container(
                    height: 300,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _isMapReady
                        ? GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: _selectedLocation,
                              zoom: 12,
                            ),
                            onMapCreated: (controller) {
                              _mapController = controller;
                              controller.animateCamera(
                                CameraUpdate.newLatLngZoom(_selectedLocation, 12),
                              );
                            },
                            markers: {
                              Marker(
                                markerId: const MarkerId('delivery_spot'),
                                position: _selectedLocation,
                                infoWindow: InfoWindow(
                                  title: _selectedAddress ?? 'Delivery Spot',
                                ),
                              ),
                            },
                            onTap: (latLng) {
                              setState(() {
                                _selectedLocation = latLng;
                                _selectedAddress = 'Custom Location';
                                _nearbyLocations = [];
                              });
                              _getAddressFromLatLng(latLng);
                            },
                          )
                        : const Center(child: CircularProgressIndicator()),
                  ),
                  if (_selectedAddress != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Selected: $_selectedAddress',
                      style: const TextStyle(fontSize: 14, color: Colors.green),
                      textDirection: TextDirection.ltr,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Nearby Locations:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _isFetchingNearby
                        ? const Center(child: CircularProgressIndicator())
                        : _nearbyLocations.isEmpty
                            ? const Text('No nearby locations found')
                            : Container(
                                height: 120,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _nearbyLocations.length,
                                  itemBuilder: (context, index) {
                                    final place = _nearbyLocations[index];
                                    return Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: GestureDetector(
                                        onTap: () {
                                          final lat = place['geometry']['location']['lat'];
                                          final lng = place['geometry']['location']['lng'];
                                          setState(() {
                                            _selectedLocation = LatLng(lat, lng);
                                            _selectedAddress = place['vicinity'] ?? place['name'];
                                            _nearbyLocations = [];
                                          });
                                          _mapController?.animateCamera(
                                            CameraUpdate.newLatLngZoom(_selectedLocation, 16),
                                          );
                                          _fetchNearbyLocations(_selectedLocation);
                                        },
                                        child: Chip(
                                          avatar: Icon(
                                            _getPlaceIcon(place['types']),
                                            size: 20,
                                          ),
                                          label: Text(place['name'] ?? 'Unknown'),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                  ],
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _getAddressFromLatLng(LatLng latLng) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json'
      '?latlng=${latLng.latitude},${latLng.longitude}'
      '&key=$_googleApiKey',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (kDebugMode) {
          print('Geocode response: $data');
        }
        if (data['status'] == 'OK') {
          setState(() {
            _selectedAddress = data['results'][0]['formatted_address'];
            _selectedLocation = latLng;
          });
          await _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(_selectedLocation, 16),
          );
          await _fetchNearbyLocations(_selectedLocation);
        } else {
          _showErrorSnackbar('Failed to get address: ${data['status']}');
        }
      } else {
        _showErrorSnackbar('Failed to get address: HTTP ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackbar('Error fetching address: $e');
      if (kDebugMode) {
        print('Geocode error: $e');
      }
    }
  }

  Widget _buildOptionCard({
    required bool isSelected,
    required String imagePath,
    required String label,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected ? const BorderSide(color: Colors.orange, width: 2) : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  imagePath,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    if (kDebugMode) {
                      print('Option card image error for $imagePath: $error');
                    }
                    return const Icon(Icons.error, color: Colors.grey);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Text(label, style: const TextStyle(fontSize: 16)),
              const Spacer(),
              if (isSelected) const Icon(Icons.check_circle, color: Colors.green),
            ],
          ),
        ),
      ),
    );
  }
}