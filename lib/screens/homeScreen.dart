import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'view_task_screen.dart'; 
import 'authScreen.dart';
import 'account_info.dart';
import 'conversations_screen.dart';
import 'settings.dart';
import 'my_applications_screen.dart';
import 'help_support_screen.dart';
import 'verification_screen.dart';
import 'user_profile.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _fullName = 'User';
  String _area = 'Your area';
  String _role = 'findWork';
  String _profileImageUrl = '';
  bool _isVerified = false; // Added to track verification status globally

  bool _isLoading = true;

  // ── Explore tab state ──────────────────────────────────────────────
  final TextEditingController _exploreSearchController = TextEditingController();
  String _exploreSearchQuery = '';
  String? _exploreCategoryFilter;      // null = All categories
  double? _exploreRadiusKm;            // null = Any distance
  double? _customRadiusKm;             // stores user-entered custom radius
  bool _isCustomRadius = false;        // true when custom radius is active
  Position? _userPosition;             // cached device position for radius filter
  final Map<String, List<double>> _taskCoordCache = {}; // Cache geocoded coords for tasks missing lat/lng
  bool _isFetchingUserPosition = false;

  static const List<String> _categories = [
    'Cleaning', 'Repairs', 'Gardening', 'Delivery',
    'Painting', 'Shopping', 'Pet Care', 'Tech Help',
  ];

  static const List<Map<String, dynamic>> _radiusOptions = [
    {'label': '5 km',  'value': 5.0},
    {'label': '10 km', 'value': 10.0},
    {'label': '20 km', 'value': 20.0},
    {'label': 'Any',   'value': null},
  ];

  @override
  void initState() {
    super.initState();
    _initializeHome();
  }

  Future<void> _initializeHome() async {
    await _loadUserData();
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fetchUserPosition();
    });
  }

  @override
  void dispose() {
    _exploreSearchController.dispose();
    super.dispose();
  }

  /// Fetches the device's GPS position, with fallback to geocoding the user's saved area if GPS is disabled or denied.
  Future<void> _fetchUserPosition() async {
    if (_isFetchingUserPosition) return;
    _isFetchingUserPosition = true;

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
          Position? position;
          try {
            position = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high,
                timeLimit: Duration(seconds: 8),
              ),
            );
          } catch (error) {
            debugPrint('Could not get current location: $error');
            try {
              position = await Geolocator.getLastKnownPosition();
            } catch (lastKnownError) {
              debugPrint('Could not get last known location: $lastKnownError');
            }
          }

          if (position != null) {
            if (mounted) {
              setState(() => _userPosition = position);
            }

            final user = _auth.currentUser;
            if (user != null) {
              try {
                await _firestore.collection('Users').doc(user.uid).set({
                  'latitude': position.latitude,
                  'longitude': position.longitude,
                }, SetOptions(merge: true));
              } catch (error) {
                debugPrint('Could not save user location: $error');
              }
            }
          }
        } else {
          debugPrint('Location permission is not granted: $permission');
        }
      } else {
        debugPrint('Location services are disabled.');
      }
    } catch (error) {
      debugPrint('Could not access device location: $error');
    } finally {
      _isFetchingUserPosition = false;
    }

    // Fallback: If device GPS couldn't be obtained, resolve coordinates from the saved user area/location
    if (_userPosition == null && _area.isNotEmpty && _area != 'Your area') {
      try {
        final locs = await Geocoding().locationFromAddress(_area);
        if (locs.isNotEmpty && mounted) {
          setState(() {
            _userPosition = Position(
              latitude: locs.first.latitude,
              longitude: locs.first.longitude,
              timestamp: DateTime.now(),
              accuracy: 0,
              altitude: 0,
              heading: 0,
              speed: 0,
              speedAccuracy: 0,
              altitudeAccuracy: 0,
              headingAccuracy: 0,
            );
          });
        }
      } catch (error) {
        debugPrint('Could not resolve saved user area: $error');
      }
    }
  }

  // Get the logged-in user's information from Firestore
  Future<void> _loadUserData() async {
    try {
      User? user = _auth.currentUser;

      if (user == null) {
        return;
      }

      DocumentSnapshot userDocument = await _firestore.collection('Users').doc(user.uid).get();

      if (userDocument.exists) {
        Map<String, dynamic> data =
            userDocument.data() as Map<String, dynamic>;

        setState(() {
          _fullName = data['name'] ?? 'User';
          _area = data['area'] ?? data['location'] ?? 'Your area';
          _role = data['role'] ?? 'findWork';
          if (_userPosition == null && data['latitude'] != null && data['longitude'] != null) {
            final lat = (data['latitude'] as num).toDouble();
            final lng = (data['longitude'] as num).toDouble();
            _userPosition = Position(
              latitude: lat,
              longitude: lng,
              timestamp: DateTime.now(),
              accuracy: 0,
              altitude: 0,
              heading: 0,
              speed: 0,
              speedAccuracy: 0,
              altitudeAccuracy: 0,
              headingAccuracy: 0,
            );
          } else if (_userPosition == null && _area.isNotEmpty && _area != 'Your area') {
            // Geocode user saved area as immediate fallback
            Geocoding().locationFromAddress(_area).then((locs) {
              if (locs.isNotEmpty && mounted && _userPosition == null) {
                setState(() {
                  _userPosition = Position(
                    latitude: locs.first.latitude,
                    longitude: locs.first.longitude,
                    timestamp: DateTime.now(),
                    accuracy: 0,
                    altitude: 0,
                    heading: 0,
                    speed: 0,
                    speedAccuracy: 0,
                    altitudeAccuracy: 0,
                    headingAccuracy: 0,
                  );
                });
              }
            }).catchError((_) {});
          }
          _isVerified = data['isVerified'] == true;
          _profileImageUrl = (data['profileImageUrl'] ??
                  data['photoUrl'] ??
                  data['photoURL'] ??
                  data['profilePicture'] ??
                  data['profileImage'] ??
                  user.photoURL ??
                  '')
              .toString();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');

      setState(() {
        _isLoading = false;
      });
    }
  }

  // Sign out
  Future<void> _signOut() async {
    await _auth.signOut();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AuthScreen()),
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled. Please enable them in settings.')),
          );
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                permission == LocationPermission.deniedForever
                    ? 'Location permission is permanently denied. Please enable it in app settings.'
                    : 'Location permission is denied.',
              ),
            ),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      var newArea = '';
      try {
        final placemarks = await Geocoding().placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          newArea =
              '${placemarks[0].locality ?? ''}, ${placemarks[0].country ?? ''}'
                  .trim();
        }
      } catch (error) {
        debugPrint('Could not resolve address for current location: $error');
      }
      if (newArea.isEmpty || newArea == ',') {
        newArea =
            '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      }

      if (mounted) {
        setState(() {
          _area = newArea;
          _userPosition = position;
        });
      }

      User? user = _auth.currentUser;
      if (user != null) {
        try {
          await _firestore.collection('Users').doc(user.uid).set({
            'area': newArea,
            'latitude': position.latitude,
            'longitude': position.longitude,
          }, SetOptions(merge: true));
        } catch (error) {
          debugPrint('Could not save current location: $error');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not save location to your profile.')),
            );
          }
        }
      }
      if (mounted) Navigator.pop(context);
    } catch (error) {
      debugPrint('Could not update current location: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $error')),
        );
      }
    }
  }

  void _showLocationBottomSheet() {
    final TextEditingController locationController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20, right: 20, top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Update Location', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  _getCurrentLocation();
                },
                icon: const Icon(Icons.my_location),
                label: const Text('Use My Current Location'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: const Color(0xFFE3F2FD),
                  foregroundColor: const Color(0xFF1976D2),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Or enter manually:', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 10),
              TextField(
                controller: locationController,
                decoration: InputDecoration(
                  hintText: 'e.g. Cape Town',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.check, color: Color(0xFF1976D2)),
                    onPressed: () async {
                      final text = locationController.text.trim();
                      if (text.isNotEmpty) {
                        User? user = _auth.currentUser;
                        if (user != null) {
                          double? lat;
                          double? lng;
                          try {
                            final locs = await Geocoding().locationFromAddress(text);
                            if (locs.isNotEmpty) {
                              lat = locs.first.latitude;
                              lng = locs.first.longitude;
                            }
                          } catch (_) {}

                          final Map<String, dynamic> updateData = {
                            'area': text,
                            'location': text,
                          };
                          if (lat != null && lng != null) {
                            updateData['latitude'] = lat;
                            updateData['longitude'] = lng;
                          }

                          await _firestore.collection('Users').doc(user.uid).set(
                            updateData,
                            SetOptions(merge: true),
                          );

                          if (lat != null && lng != null) {
                            _userPosition = Position(
                              latitude: lat,
                              longitude: lng,
                              timestamp: DateTime.now(),
                              accuracy: 0,
                              altitude: 0,
                              heading: 0,
                              speed: 0,
                              speedAccuracy: 0,
                              altitudeAccuracy: 0,
                              headingAccuracy: 0,
                            );
                          }
                        }
                        if (mounted && context.mounted) {
                          setState(() {
                            _area = text;
                          });
                          Navigator.pop(context);
                        }
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  // Bottom navigation
  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF1976D2),
          ),
        ),
      );
    }

    bool isWorker = _role == 'findWork';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),

      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            isWorker
                ? _buildWorkerHome()
                : _buildTaskProviderHome(),

            _buildExploreTab(),

            isWorker
                ? const MyApplicationsScreen() 
                : _buildPlaceholderPage(
                    Icons.add_circle_outline_rounded,
                    'My Tasks',
                    'Tasks you have posted will appear here.',
                  ),

            _auth.currentUser != null
                ? ConversationsScreen(
                    currentUserId: _auth.currentUser!.uid,
                  )
                : const Center(
                    child: Text('Please log in to view messages.'),
          ),

            _buildProfilePage(),
          ],
        ),
      ),

      bottomNavigationBar: _buildBottomNavigationBar(isWorker),
    );
  }

  Widget _buildWorkerHome() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),

          const SizedBox(height: 20),

          _buildSectionTitle(
            'Tasks near you',
            'See all',
          ),

          const SizedBox(height: 15),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Tasks')
                .where('status', isEqualTo: 'Active')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(color: Color(0xFF1976D2)),
                  ),
                );
              }

              if (snapshot.hasError) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text('Error loading tasks.'),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      'No tasks available in your area right now.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                );
              }

              final tasks = snapshot.data!.docs;

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final doc = tasks[index];
                  final data = doc.data() as Map<String, dynamic>;
                  
                  return _buildTaskCard(
                    taskId: data['taskID']?.toString() ?? doc.id,
                    title: data['title']?.toString() ?? 'Untitled Task',
                    category: data['category']?.toString() ?? 'General',
                    location: data['location']?.toString() ?? 'Location not specified',
                    payment: 'R${data['paymentAmount'] ?? 0}',
                    // FETCHING EXACT DATE & TIME FROM FIRESTORE
                    date: data['date']?.toString() ?? 'Flexible',
                    time: data['time']?.toString() ?? 'Anytime',
                    distance: 'Nearby',
                    description: data['description']?.toString() ?? 'No description provided.',
                    providerId: data['creatorID']?.toString() ?? '',
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTaskProviderHome() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),

          const SizedBox(height: 20),

          _buildProviderBanner(),

          const SizedBox(height: 25),

          _buildSectionTitle(
            'Quick Actions',
            '',
          ),

          const SizedBox(height: 15),

          _buildProviderActions(),

          const SizedBox(height: 28),

          _buildSectionTitle(
            'Your Active Tasks',
            'See all',
          ),

          const SizedBox(height: 15),

          _buildProviderTaskCard(
            title: 'Help Move Furniture',
            applications: '5 applications',
            status: 'Active',
            payment: 'R350',
          ),

          _buildProviderTaskCard(
            title: 'Garden Cleaning',
            applications: '3 applications',
            status: 'Active',
            payment: 'R250',
          ),

          _buildProviderTaskCard(
            title: 'Computer Setup',
            applications: '2 applications',
            status: 'Active',
            payment: 'R300',
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      decoration: const BoxDecoration(
        color: Color(0xFF1976D2),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/images/tasksurfLogo.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.water,
                        color: Color(0xFF1976D2),
                        size: 30,
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(width: 12),

              const Expanded(
                child: Text(
                  'TaskSurf',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.person_rounded,
                  color: Color(0xFF1976D2),
                  size: 30,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good day,',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '${_fullName.split(' ').first} 👋',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_isVerified) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.verified_rounded, color: Colors.white, size: 20),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _role == 'findWork' ? 'Worker' : 'Provider',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (!_isVerified) ...[
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VerificationScreen())),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade400,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('Verify Profile', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Explore Tab ────────────────────────────────────────────────────

  Widget _buildExploreTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          decoration: const BoxDecoration(
            color: Color(0xFF1976D2),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Explore Tasks',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Find the right task for you',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 14),
              // ── Search field ────────────────────────────────────
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: _exploreSearchController,
                  onChanged: (val) =>
                      setState(() => _exploreSearchQuery = val.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search for tasks...',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF1976D2),
                    ),
                    suffixIcon: _exploreSearchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded,
                                color: Colors.grey),
                            onPressed: () {
                              _exploreSearchController.clear();
                              setState(() => _exploreSearchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Modern Category & Radius Filter Dropdowns ──────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Row(
            children: [
              Expanded(
                child: _buildCategoryDropdown(),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildRadiusDropdown(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 6),

        // ── Results ──────────────────────────────────────────────────
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Tasks')
                .where('status', isEqualTo: 'Active')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child:
                      CircularProgressIndicator(color: Color(0xFF1976D2)),
                );
              }
              if (snapshot.hasError) {
                return const Center(child: Text('Error loading tasks.'));
              }

              final allDocs = snapshot.data?.docs ?? [];
              _resolveMissingTaskCoordinates(allDocs);

              // ── Client-side filtering ──────────────────────────
              final filtered = allDocs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final title =
                    (data['title'] ?? '').toString().toLowerCase();
                final desc =
                    (data['description'] ?? '').toString().toLowerCase();
                final category =
                    (data['category'] ?? '').toString();
                final cached = _taskCoordCache[doc.id];
                final taskLat = (data['latitude'] as num?)?.toDouble() ?? cached?[0];
                final taskLng = (data['longitude'] as num?)?.toDouble() ?? cached?[1];

                // 1. Keyword search
                if (_exploreSearchQuery.isNotEmpty &&
                    !title.contains(_exploreSearchQuery) &&
                    !desc.contains(_exploreSearchQuery)) {
                  return false;
                }

                // 2. Category filter
                if (_exploreCategoryFilter != null &&
                    category != _exploreCategoryFilter) {
                  return false;
                }

                // 3. Radius filter
                if (_exploreRadiusKm != null) {
                  if (_userPosition == null) {
                    // Radius filter is active but user position is not yet known
                    return false;
                  }
                  if (taskLat == null || taskLng == null) {
                    return false;
                  }
                  final distM = Geolocator.distanceBetween(
                    _userPosition!.latitude,
                    _userPosition!.longitude,
                    taskLat,
                    taskLng,
                  );
                  if (distM / 1000 > _exploreRadiusKm!) return false;
                }

                return true;
              }).toList();

              // Sort filtered tasks by distance from user (closest first)
              if (_userPosition != null) {
                filtered.sort((a, b) {
                  final dataA = a.data() as Map<String, dynamic>;
                  final dataB = b.data() as Map<String, dynamic>;
                  final cachedA = _taskCoordCache[a.id];
                  final cachedB = _taskCoordCache[b.id];
                  final latA = (dataA['latitude'] as num?)?.toDouble() ?? cachedA?[0];
                  final lngA = (dataA['longitude'] as num?)?.toDouble() ?? cachedA?[1];
                  final latB = (dataB['latitude'] as num?)?.toDouble() ?? cachedB?[0];
                  final lngB = (dataB['longitude'] as num?)?.toDouble() ?? cachedB?[1];

                  final distA = (latA != null && lngA != null)
                      ? Geolocator.distanceBetween(_userPosition!.latitude, _userPosition!.longitude, latA, lngA)
                      : double.infinity;
                  final distB = (latB != null && lngB != null)
                      ? Geolocator.distanceBetween(_userPosition!.latitude, _userPosition!.longitude, latB, lngB)
                      : double.infinity;

                  return distA.compareTo(distB);
                });
              }

              if (filtered.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.search_off_rounded,
                              size: 40, color: Color(0xFF1976D2)),
                        ),
                        const SizedBox(height: 16),
                        const Text('No tasks found',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(
                          _exploreRadiusKm != null &&
                                  _userPosition == null
                              ? 'Allow location access and enable location services to filter by radius.'
                              : 'Try adjusting your search or filters.',
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 20),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final doc = filtered[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final cached = _taskCoordCache[doc.id];
                  final taskLat = (data['latitude'] as num?)?.toDouble() ?? cached?[0];
                  final taskLng = (data['longitude'] as num?)?.toDouble() ?? cached?[1];

                  // Compute distance label if possible
                  String distanceLabel = 'Distance unavailable';
                  if (_userPosition != null &&
                      taskLat != null &&
                      taskLng != null) {
                    final distM = Geolocator.distanceBetween(
                      _userPosition!.latitude,
                      _userPosition!.longitude,
                      taskLat,
                      taskLng,
                    );
                    distanceLabel = distM < 1000
                        ? '${distM.toStringAsFixed(0)} m away'
                        : '${(distM / 1000).toStringAsFixed(1)} km away';
                  }

                  return _buildTaskCard(
                    taskId:
                        data['taskID']?.toString() ?? doc.id,
                    title: data['title']?.toString() ??
                        'Untitled Task',
                    category: data['category']?.toString() ??
                        'General',
                    location: data['location']?.toString() ??
                        'Location not specified',
                    payment:
                        'R${data['paymentAmount'] ?? 0}',
                    // FETCHING EXACT DATE & TIME FROM FIRESTORE
                    date: data['date']?.toString() ?? 'Flexible',
                    time: data['time']?.toString() ?? 'Anytime',
                    distance: distanceLabel,
                    description:
                        data['description']?.toString() ??
                            'No description provided.',
                    providerId: data['creatorID']?.toString() ?? '',
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatKm(double km) {
    return km % 1 == 0 ? km.toInt().toString() : km.toString();
  }

  Widget _buildCategoryDropdown() {
    final bool isActive = _exploreCategoryFilter != null;
    final String label = _exploreCategoryFilter ?? 'All Categories';

    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFE3F2FD) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? const Color(0xFF1976D2) : Colors.grey.shade300,
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: PopupMenuButton<String?>(
              tooltip: 'Select Category',
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              color: Colors.white,
              offset: const Offset(0, 46),
              onSelected: (val) {
                setState(() => _exploreCategoryFilter = val);
              },
              itemBuilder: (context) => [
                PopupMenuItem<String?>(
                  value: null,
                  child: Row(
                    children: [
                      Icon(
                        _exploreCategoryFilter == null
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        size: 18,
                        color: _exploreCategoryFilter == null
                            ? const Color(0xFF1976D2)
                            : Colors.grey.shade400,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'All Categories',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: _exploreCategoryFilter == null
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _exploreCategoryFilter == null
                              ? const Color(0xFF1976D2)
                              : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(height: 1),
                ..._categories.map(
                  (c) => PopupMenuItem<String?>(
                    value: c,
                    child: Row(
                      children: [
                        Icon(
                          _exploreCategoryFilter == c
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          size: 18,
                          color: _exploreCategoryFilter == c
                              ? const Color(0xFF1976D2)
                              : Colors.grey.shade400,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          c,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: _exploreCategoryFilter == c
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: _exploreCategoryFilter == c
                                ? const Color(0xFF1976D2)
                                : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    Icon(
                      Icons.grid_view_rounded,
                      size: 15,
                      color: isActive
                          ? const Color(0xFF1976D2)
                          : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w500,
                          color: isActive
                              ? const Color(0xFF1976D2)
                              : Colors.grey.shade800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: isActive
                          ? const Color(0xFF1976D2)
                          : Colors.grey.shade600,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isActive)
            GestureDetector(
              onTap: () => setState(() => _exploreCategoryFilter = null),
              child: const Padding(
                padding: EdgeInsets.only(right: 8, left: 2),
                child: Icon(
                  Icons.close_rounded,
                  size: 15,
                  color: Color(0xFF1976D2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _resolveMissingTaskCoordinates(List<QueryDocumentSnapshot> docs) {
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final lat = (data['latitude'] as num?)?.toDouble();
      final lng = (data['longitude'] as num?)?.toDouble();
      final locText = (data['location'] ?? '').toString().trim();
      if ((lat == null || lng == null) && locText.isNotEmpty && !_taskCoordCache.containsKey(doc.id)) {
        Geocoding().locationFromAddress(locText).then((locs) {
          if (locs.isNotEmpty) {
            _taskCoordCache[doc.id] = [locs.first.latitude, locs.first.longitude];
            // Auto backfill in Firestore if possible
            FirebaseFirestore.instance.collection('Tasks').doc(doc.id).update({
              'latitude': locs.first.latitude,
              'longitude': locs.first.longitude,
            }).catchError((_) {});
            if (mounted) setState(() {});
          }
        }).catchError((_) {});
      }
    }
  }

  Widget _buildRadiusDropdown() {
    final bool isActive = _exploreRadiusKm != null;
    final String label = !isActive
        ? 'Any Distance'
        : '${_formatKm(_exploreRadiusKm!)} km';

    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFE3F2FD) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? const Color(0xFF1976D2) : Colors.grey.shade300,
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: PopupMenuButton<String>(
              tooltip: 'Select Radius',
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              color: Colors.white,
              offset: const Offset(0, 46),
              onSelected: (val) {
                if (val == 'any') {
                  setState(() {
                    _exploreRadiusKm = null;
                    _isCustomRadius = false;
                  });
                } else if (val == 'custom') {
                  _showCustomRadiusDialog();
                } else {
                  final parsed = double.tryParse(val);
                  if (parsed != null) {
                    setState(() {
                      _exploreRadiusKm = parsed;
                      _isCustomRadius = false;
                    });
                    if (_userPosition == null) {
                      _fetchUserPosition();
                    }
                  }
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: 'any',
                  child: Row(
                    children: [
                      Icon(
                        _exploreRadiusKm == null
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        size: 18,
                        color: _exploreRadiusKm == null
                            ? const Color(0xFF1976D2)
                            : Colors.grey.shade400,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Any Distance',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: _exploreRadiusKm == null
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _exploreRadiusKm == null
                              ? const Color(0xFF1976D2)
                              : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(height: 1),
                ...[5.0, 10.0, 20.0].map((km) {
                  final isSelected = !_isCustomRadius && _exploreRadiusKm == km;
                  return PopupMenuItem<String>(
                    value: km.toInt().toString(),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          size: 18,
                          color: isSelected
                              ? const Color(0xFF1976D2)
                              : Colors.grey.shade400,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${km.toInt()} km',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? const Color(0xFF1976D2)
                                : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const PopupMenuDivider(height: 1),
                PopupMenuItem<String>(
                  value: 'custom',
                  child: Row(
                    children: [
                      Icon(
                        _isCustomRadius && _exploreRadiusKm != null
                            ? Icons.check_circle_rounded
                            : Icons.tune_rounded,
                        size: 18,
                        color: const Color(0xFF1976D2),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _isCustomRadius && _exploreRadiusKm != null
                              ? 'Custom: ${_formatKm(_exploreRadiusKm!)} km'
                              : (_customRadiusKm != null
                                  ? 'Custom (${_formatKm(_customRadiusKm!)} km)...'
                                  : 'Custom distance...'),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                _isCustomRadius && _exploreRadiusKm != null
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                            color: const Color(0xFF1976D2),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.edit_outlined,
                        size: 14,
                        color: Color(0xFF1976D2),
                      ),
                    ],
                  ),
                ),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    Icon(
                      Icons.my_location_rounded,
                      size: 15,
                      color: const Color(0xFF1976D2),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w500,
                          color: isActive
                              ? const Color(0xFF1976D2)
                              : Colors.grey.shade800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: isActive
                          ? const Color(0xFF1976D2)
                          : Colors.grey.shade600,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isActive)
            GestureDetector(
              onTap: () {
                setState(() {
                  _exploreRadiusKm = null;
                  _isCustomRadius = false;
                });
              },
              child: const Padding(
                padding: EdgeInsets.only(right: 8, left: 2),
                child: Icon(
                  Icons.close_rounded,
                  size: 15,
                  color: Color(0xFF1976D2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showCustomRadiusDialog() {
    final String initialText = _customRadiusKm != null
        ? _formatKm(_customRadiusKm!)
        : (_exploreRadiusKm != null &&
                !_radiusOptions.any((opt) => opt['value'] == _exploreRadiusKm))
            ? _formatKm(_exploreRadiusKm!)
            : '';

    final TextEditingController textController =
        TextEditingController(text: initialText);
    if (initialText.isNotEmpty) {
      textController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: initialText.length,
      );
    }
    String? localError;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            void submit() {
              final raw = textController.text.trim().replaceAll(',', '.');
              final val = double.tryParse(raw);
              if (val == null || val <= 0) {
                setDialogState(() {
                  localError = 'Enter a valid number greater than 0';
                });
                return;
              }
              setState(() {
                _customRadiusKm = val;
                _exploreRadiusKm = val;
                _isCustomRadius = true;
              });
              if (_userPosition == null) {
                _fetchUserPosition();
              }
              Navigator.pop(ctx);
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  Icon(Icons.tune_rounded, color: Color(0xFF1976D2), size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Custom Radius',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter your preferred radius in kilometres:',
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: textController,
                    autofocus: true,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => submit(),
                    decoration: InputDecoration(
                      hintText: 'e.g. 15',
                      suffixText: 'km',
                      suffixStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1976D2),
                      ),
                      errorText: localError,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF1976D2),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                if (_isCustomRadius && _exploreRadiusKm != null)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _exploreRadiusKm = null;
                        _isCustomRadius = false;
                      });
                      Navigator.pop(ctx);
                    },
                    child: const Text(
                      'Clear',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: submit,
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, String action) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),

          if (action.isNotEmpty)
            TextButton(
              onPressed: () {},
              child: Text(
                action,
                style: const TextStyle(
                  color: Color(0xFF1976D2),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTaskCard({
    required String taskId,
    required String title,
    required String category,
    required String location,
    required String payment,
    required String date,
    required String time,
    required String distance,
    required String description,
    required String providerId,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.work_outline_rounded,
                  color: Color(0xFF1976D2),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      category,
                      style: const TextStyle(
                        color: Color(0xFF1976D2),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              Text(
                payment,
                style: const TextStyle(
                  color: Color(0xFF1976D2),
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          const Divider(height: 1),

          const SizedBox(height: 12),

          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 17,
                color: Colors.grey.shade600,
              ),

              const SizedBox(width: 5),

              Expanded(
                child: Text(
                  '$location • $distance',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12,
                  ),
                ),
              ),

              Icon(
                Icons.calendar_today_outlined,
                size: 15,
                color: Colors.grey.shade600,
              ),

              const SizedBox(width: 5),

              Text(
                date,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 12,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 17,
                color: Colors.grey.shade600,
              ),

              const SizedBox(width: 5),

              Text(
                time,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 12,
                ),
              ),

              const Spacer(),

              SizedBox(
                height: 38,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TaskDetailsScreen(
                        taskId: taskId,
                        title: title,
                        category: category,
                        location: location,
                        payment: payment,
                        date: date,
                        time: time,
                        distance: distance,
                        description: description,
                        providerId: providerId,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'View Task',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProviderBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1976D2),
            Color(0xFF42A5F5),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Need something done?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 7),

                Text(
                  'Post a task and find someone nearby to help.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 15),

                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1976D2),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Post a Task',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          const Icon(
            Icons.waves_rounded,
            color: Colors.white,
            size: 70,
          ),
        ],
      ),
    );
  }

  // ADDED VERIFY ACTION TO PROVIDER ACTIONS
  Widget _buildProviderActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              icon: Icons.add_task_rounded,
              title: 'Post Task',
              onTap: () {},
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: _buildActionButton(
              icon: Icons.people_outline_rounded,
              title: 'Applications',
              onTap: () {},
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: _buildActionButton(
              icon: Icons.history_rounded,
              title: 'History',
              onTap: () {},
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: _buildActionButton(
              icon: Icons.verified_user_rounded,
              title: 'Verify',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VerificationScreen())),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 5,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withValues(alpha: 0.07),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: const Color(0xFF1976D2),
              size: 27,
            ),

            const SizedBox(height: 8),

            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderTaskCard({
    required String title,
    required String applications,
    required String status,
    required String payment,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 15),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.work_outline_rounded,
              color: Color(0xFF1976D2),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  applications,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 6),

                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),

                    const SizedBox(width: 5),

                    Text(
                      status,
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                payment,
                style: const TextStyle(
                  color: Color(0xFF1976D2),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 8),

              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderPage(
    IconData icon,
    String title,
    String description,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(
                icon,
                size: 45,
                color: const Color(0xFF1976D2),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              title,
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider? _getProfileImageProvider(String? url) {
    if (url == null) return null;
    final clean = url.trim();
    if (clean.isEmpty || clean == 'null') return null;
    if (clean.startsWith('data:image')) {
      try {
        final base64String = clean.split(',').last;
        return MemoryImage(base64Decode(base64String));
      } catch (_) {
        return null;
      }
    }
    if (!clean.startsWith('http://') && !clean.startsWith('https://')) {
      try {
        return MemoryImage(base64Decode(clean));
      } catch (_) {
        return null;
      }
    }
    return NetworkImage(clean);
  }

  Widget _buildProfilePage() {
    final user = _auth.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: user != null
          ? _firestore.collection('Users').doc(user.uid).snapshots()
          : null,
      builder: (context, snapshot) {
        Map<String, dynamic>? data;
        if (snapshot.hasData && snapshot.data!.exists) {
          data = snapshot.data!.data() as Map<String, dynamic>?;
        }

        final String photoUrl = (data?['profileImageUrl'] ??
                data?['photoUrl'] ??
                data?['photoURL'] ??
                data?['profilePicture'] ??
                data?['profileImage'] ??
                user?.photoURL ??
                _profileImageUrl)
            .toString()
            .trim();

        final String name = data?['name']?.toString() ?? _fullName;
        final String area = data?['location']?.toString() ??
            data?['area']?.toString() ??
            _area;
        final bool isVerified = data?['isVerified'] == true;

        final imageProvider = _getProfileImageProvider(photoUrl);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 30),

              CircleAvatar(
                radius: 50,
                backgroundColor: const Color(0xFFE3F2FD),
                backgroundImage: imageProvider,
                onBackgroundImageError: imageProvider != null
                    ? (exception, stackTrace) {
                        debugPrint('Error loading profile image: $exception');
                      }
                    : null,
                child: imageProvider == null
                    ? const Icon(
                        Icons.person_rounded,
                        color: Color(0xFF1976D2),
                        size: 55,
                      )
                    : null,
              ),

              const SizedBox(height: 15),

              // Name + optional blue verified tick
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isVerified) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.verified_rounded,
                        color: Color(0xFF1976D2), size: 22),
                  ],
                ],
              ),

              const SizedBox(height: 5),

              Text(
                area,
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 12),

              // LIVE AVERAGE RATING CALCULATOR & BADGE
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('reviews')
                    .where('reviewedUserId', isEqualTo: user?.uid)
                    .snapshots(),
                builder: (context, reviewSnap) {
                  double avgRating = 0.0;
                  int totalReviews = 0;

                  if (reviewSnap.hasData && reviewSnap.data!.docs.isNotEmpty) {
                    totalReviews = reviewSnap.data!.docs.length;
                    double sum = 0.0;
                    for (var doc in reviewSnap.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      sum += (data['rating'] as num?)?.toDouble() ?? 0.0;
                    }
                    avgRating = sum / totalReviews;
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          totalReviews > 0 ? avgRating.toStringAsFixed(1) : 'New User',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "($totalReviews ${totalReviews == 1 ? 'review' : 'reviews'})",
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 30),

              _buildProfileOption(
                Icons.person_outline_rounded,
                'Edit Profile',
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AccountInfoScreen()),
                  );
                  _loadUserData();
                },
              ),

              _buildProfileOption(
                Icons.star_outline_rounded,
                'My Public Profile & Reviews',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UserProfileScreen()),
                ),
              ),

              _buildProfileOption(
                Icons.location_on_outlined,
                'Location',
                onTap: _showLocationBottomSheet,
              ),

              _buildProfileOption(
                Icons.settings_outlined,
                'Settings',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),

              // Verify Profile option — shows tick status dynamically
              _buildVerifyProfileOption(context, isVerified),

              _buildProfileOption(
                Icons.help_outline_rounded,
                'Help & Support',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
                ),
              ),

              const SizedBox(height: 10),

              ListTile(
                onTap: _signOut,
                leading: const Icon(
                  Icons.logout_rounded,
                  color: Colors.red,
                ),
                title: const Text(
                  'Sign Out',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                tileColor: Colors.white,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileOption(
    IconData icon,
    String title, {
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: const Color(0xFF1976D2),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Colors.grey,
        ),
        onTap: onTap ?? () {},
      ),
    );
  }

  Widget _buildVerifyProfileOption(BuildContext context, bool isVerified) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('verificationRequests')
          .where('userId', isEqualTo: _auth.currentUser?.uid ?? '')
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get(),
      builder: (context, snapshot) {
        final isPending =
            snapshot.hasData && snapshot.data!.docs.isNotEmpty;

        Widget? badge;
        if (isVerified) {
          badge = Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.verified_rounded, color: Color(0xFF1976D2), size: 20),
              SizedBox(width: 4),
              Text('Verified',
                  style: TextStyle(
                      color: Color(0xFF1976D2),
                      fontWeight: FontWeight.w600,
                      fontSize: 12)),
            ],
          );
        } else if (isPending) {
          badge = Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Pending',
              style: TextStyle(
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.w600,
                  fontSize: 11),
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: ListTile(
            leading: const Icon(
              Icons.verified_user_rounded,
              color: Color(0xFF1976D2),
            ),
            title: const Text(
              'Verify Profile',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            trailing: badge ??
                const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const VerificationScreen()),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomNavigationBar(bool isWorker) {
    return NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: _onBottomNavTapped,
      backgroundColor: Colors.white,
      elevation: 5,
      indicatorColor: const Color(0xFFE3F2FD),
      height: 70,
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(
            Icons.home_rounded,
            color: Color(0xFF1976D2),
          ),
          label: 'Home',
        ),

        NavigationDestination(
          icon: const Icon(Icons.explore_outlined),
          selectedIcon: const Icon(
            Icons.explore_rounded,
            color: Color(0xFF1976D2),
          ),
          label: isWorker ? 'Explore' : 'Browse',
        ),

        NavigationDestination(
          icon: Icon(
            isWorker
                ? Icons.assignment_outlined
                : Icons.add_task_outlined,
          ),
          selectedIcon: Icon(
            isWorker
                ? Icons.assignment_rounded
                : Icons.add_task_rounded,
            color: const Color(0xFF1976D2),
          ),
          label: isWorker ? 'Applications' : 'My Tasks',
        ),

        NavigationDestination(
          icon: const Icon(Icons.chat_bubble_outline_rounded),
          selectedIcon: const Icon(
            Icons.chat_bubble_rounded,
            color: Color(0xFF1976D2),
          ),
          label: 'Messages',
        ),

        NavigationDestination(
          icon: const Icon(Icons.person_outline_rounded),
          selectedIcon: const Icon(
            Icons.person_rounded,
            color: Color(0xFF1976D2),
          ),
          label: 'Profile',
        ),
      ],
    );
  }
}