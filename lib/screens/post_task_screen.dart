import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class PostTaskScreen extends StatefulWidget {
  final String? taskId;
  final Map<String, dynamic>? existingData;

  const PostTaskScreen({
    super.key, 
    this.taskId, 
    this.existingData,
  });

  @override
  State<PostTaskScreen> createState() => _PostTaskScreenState();
}

class _PostTaskScreenState extends State<PostTaskScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _budgetController = TextEditingController();
  final _workersController = TextEditingController(text: '1'); 
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  // New Controllers
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _collectionController = TextEditingController();
  final _deliveryController = TextEditingController();

  String? _selectedCategory;
  bool _isLoading = false;
  bool _isLocating = false;
  double? _taskLatitude;
  double? _taskLongitude;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Cleaning', 'icon': Icons.cleaning_services_outlined},
    {'name': 'Repairs', 'icon': Icons.build_outlined},
    {'name': 'Gardening', 'icon': Icons.eco_outlined},
    {'name': 'Delivery', 'icon': Icons.inventory_2_outlined},
    {'name': 'Painting', 'icon': Icons.format_paint_outlined},
    {'name': 'Shopping', 'icon': Icons.shopping_cart_outlined},
    {'name': 'Pet Care', 'icon': Icons.pets},
    {'name': 'Tech Help', 'icon': Icons.computer_outlined},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      _titleController.text = widget.existingData!['title'] ?? '';
      _budgetController.text = (widget.existingData!['paymentAmount'] ?? '').toString();
      _workersController.text = (widget.existingData!['numOfWorkers'] ?? '1').toString();
      _locationController.text = widget.existingData!['location'] ?? '';
      _descriptionController.text = widget.existingData!['description'] ?? '';
      _dateController.text = widget.existingData!['date'] ?? '';
      _timeController.text = widget.existingData!['time'] ?? '';
      _collectionController.text = widget.existingData!['collectionAddress'] ?? '';
      _deliveryController.text = widget.existingData!['deliveryAddress'] ?? '';
      _selectedCategory = widget.existingData!['category'];
      if (widget.existingData!['latitude'] != null) _taskLatitude = (widget.existingData!['latitude'] as num).toDouble();
      if (widget.existingData!['longitude'] != null) _taskLongitude = (widget.existingData!['longitude'] as num).toDouble();
    } else {
      _fillCurrentLocation();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _budgetController.dispose();
    _workersController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _collectionController.dispose();
    _deliveryController.dispose();
    super.dispose();
  }

  Future<void> _fillCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      var text = '';
      try {
        final placemarks = await Geocoding().placemarkFromCoordinates(
          pos.latitude,
          pos.longitude,
        );
        if (placemarks.isNotEmpty) {
          text = [
            placemarks[0].subLocality,
            placemarks[0].locality,
            placemarks[0].administrativeArea,
          ].where((part) => part != null && part.isNotEmpty).join(', ');
        }
      } catch (error) {
        debugPrint('Could not resolve address for task location: $error');
      }
      if (mounted) {
        setState(() {
          _locationController.text = text.isNotEmpty
              ? text
              : '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
          _taskLatitude = pos.latitude;
          _taskLongitude = pos.longitude;
        });
      }
    } catch (error) {
      debugPrint('Could not fill task location from device: $error');
    }
  }

  Future<void> _useCurrentLocationExplicit() async {
    setState(() => _isLocating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled. Please enable them in settings.')),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permissions are denied.')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are permanently denied. Please enable them in app settings.')),
          );
        }
        return;
      }

      Position pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      String text = '';
      try {
        final placemarks = await Geocoding().placemarkFromCoordinates(
          pos.latitude,
          pos.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks[0];
          final parts = [
            p.subLocality,
            p.locality,
            p.administrativeArea,
          ].where((part) => part != null && part.isNotEmpty).toList();
          text = parts.isNotEmpty
              ? parts.join(', ')
              : '${p.locality ?? ''}, ${p.country ?? ''}';
        }
      } catch (error) {
        debugPrint('Could not resolve address for task location: $error');
      }
      if (text.isEmpty) {
        text = '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
      }

      if (mounted) {
        setState(() {
          _locationController.text = text;
          _taskLatitude = pos.latitude;
          _taskLongitude = pos.longitude;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _selectTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && mounted) {
      setState(() {
        _timeController.text = picked.format(context);
      });
    }
  }

  Future<void> _submitTask() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('User not logged in');

      double? lat = _taskLatitude;
      double? lng = _taskLongitude;
      if (lat == null || lng == null) {
        try {
          List<Location> locs = await Geocoding().locationFromAddress(_locationController.text.trim());
          if (locs.isNotEmpty) {
            lat = locs.first.latitude;
            lng = locs.first.longitude;
          }
        } catch (_) {}
      }

      final Map<String, dynamic> taskData = {
        'creatorID': currentUser.uid,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'status': 'Active', 
        'paymentAmount': double.tryParse(_budgetController.text.replaceAll('R', '').trim()) ?? 0.0,
        'numOfWorkers': int.tryParse(_workersController.text.trim()) ?? 1,
        'category': _selectedCategory,
        'date': _dateController.text.trim(),
        'time': _timeController.text.trim(),
      };
      if (lat != null && lng != null) {
        taskData['latitude'] = lat;
        taskData['longitude'] = lng;
      }

      // Only save delivery addresses if it is a delivery task
      if (_selectedCategory == 'Delivery') {
        taskData['collectionAddress'] = _collectionController.text.trim();
        taskData['deliveryAddress'] = _deliveryController.text.trim();
      }

      if (widget.taskId != null) {
        await FirebaseFirestore.instance.collection('Tasks').doc(widget.taskId).update(taskData);
      } else {
        final docRef = FirebaseFirestore.instance.collection('Tasks').doc();
        taskData['taskID'] = docRef.id;
        await docRef.set(taskData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.taskId != null ? 'Task successfully updated!' : 'Task successfully posted!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving task: $e'), backgroundColor: Colors.red));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFF1976D2); 

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      appBar: AppBar(
        backgroundColor: themeColor,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text(widget.taskId != null ? 'Edit Task' : 'Post a Task', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('TASK TITLE *'),
              TextFormField(
                controller: _titleController,
                decoration: _inputDecoration('e.g. Fix leaking sink'),
                validator: (val) => val == null || val.isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 20),
              
              _buildLabel('CATEGORY *'),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 0.9,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat['name'];
                  return InkWell(
                    onTap: () => setState(() => _selectedCategory = cat['name']),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? themeColor : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? themeColor : Colors.grey.shade300, width: isSelected ? 2 : 1),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(cat['icon'], color: isSelected ? Colors.white : Colors.grey.shade600, size: 24),
                          const SizedBox(height: 6),
                          Text(cat['name'], textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: isSelected ? Colors.white : Colors.grey.shade700, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // DYNAMIC DELIVERY FIELDS
              if (_selectedCategory == 'Delivery') ...[
                _buildLabel('COLLECTION ADDRESS *'),
                TextFormField(
                  controller: _collectionController,
                  decoration: _inputDecoration('e.g. 123 Pick Up St'),
                  validator: (val) => val == null || val.isEmpty ? 'Collection address required' : null,
                ),
                const SizedBox(height: 20),
                _buildLabel('DELIVERY ADDRESS *'),
                TextFormField(
                  controller: _deliveryController,
                  decoration: _inputDecoration('e.g. 456 Drop Off Ave'),
                  validator: (val) => val == null || val.isEmpty ? 'Delivery address required' : null,
                ),
                const SizedBox(height: 20),
              ],
              
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('BUDGET (R) *'),
                        TextFormField(
                          controller: _budgetController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration('e.g. 350'),
                          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('WORKERS *'),
                        TextFormField(
                          controller: _workersController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration('e.g. 1'),
                          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('DATE *'),
                        TextFormField(
                          controller: _dateController,
                          readOnly: true,
                          onTap: _selectDate,
                          decoration: _inputDecoration('Select Date').copyWith(suffixIcon: const Icon(Icons.calendar_today, size: 18)),
                          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('TIME *'),
                        TextFormField(
                          controller: _timeController,
                          readOnly: true,
                          onTap: _selectTime,
                          decoration: _inputDecoration('Select Time').copyWith(suffixIcon: const Icon(Icons.access_time, size: 18)),
                          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              _buildLabel('LOCATION (General Area) *'),
              TextFormField(
                controller: _locationController,
                onChanged: (val) {
                  _taskLatitude = null;
                  _taskLongitude = null;
                },
                decoration: _inputDecoration('e.g. Bellville, Cape Town').copyWith(
                  suffixIcon: _isLocating
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: themeColor),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.my_location, color: themeColor),
                          tooltip: 'Use current location',
                          onPressed: _useCurrentLocationExplicit,
                        ),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Location is required' : null,
              ),
              const SizedBox(height: 20),
              
              _buildLabel('DESCRIPTION *'),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: _inputDecoration('What needs doing? Materials available, access info...'),
                validator: (val) => val == null || val.isEmpty ? 'Description is required' : null,
              ),
              const SizedBox(height: 30),
              
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          widget.taskId != null ? 'Update Task' : 'Post Task',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1976D2))),
    );
  }
}