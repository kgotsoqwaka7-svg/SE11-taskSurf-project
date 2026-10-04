import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'view_task_screen.dart'; // Ensure this matches your file name for TaskDetailsScreen
import 'authScreen.dart';
import 'account_info.dart';
import 'conversations_screen.dart';
import 'settings.dart';

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

  bool _isLoading = true;

  // ── Explore tab state ──────────────────────────────────────────────
  final TextEditingController _exploreSearchController = TextEditingController();
  String _exploreSearchQuery = '';
  String? _exploreCategoryFilter;      // null = All categories
  double? _exploreRadiusKm;            // null = Any distance
  Position? _userPosition;             // cached device position for radius filter

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
    _loadUserData();
    _fetchUserPosition();
  }

  @override
  void dispose() {
    _exploreSearchController.dispose();
    super.dispose();
  }

  /// Quietly fetches the device's GPS position and caches it for radius filtering.
  Future<void> _fetchUserPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition();
      if (mounted) setState(() => _userPosition = pos);
    } catch (_) {}
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
          _area = data['area'] ?? 'Your area';
          _role = data['role'] ?? 'findWork';
          _profileImageUrl = data['profileImageUrl'] ?? '';
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
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    Position position = await Geolocator.getCurrentPosition();
    List<Placemark> placemarks = await Geocoding().placemarkFromCoordinates(position.latitude, position.longitude);

    if (placemarks.isNotEmpty) {
      Placemark place = placemarks[0];
      String newArea = '${place.locality}, ${place.country}';
      
      User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('Users').doc(user.uid).update({
          'area': newArea,
          'latitude': position.latitude,
          'longitude': position.longitude,
        });
        setState(() {
          _area = newArea;
        });
      }
    }
    if (mounted) Navigator.pop(context);
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
                      if (locationController.text.isNotEmpty) {
                        User? user = _auth.currentUser;
                        if (user != null) {
                          await _firestore.collection('Users').doc(user.uid).update({
                            'area': locationController.text,
                          });
                          setState(() {
                            _area = locationController.text;
                          });
                        }
                        if (mounted) Navigator.pop(context);
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

            _buildPlaceholderPage(
              Icons.add_circle_outline_rounded,
              isWorker ? 'My Applications' : 'My Tasks',
              isWorker
                  ? 'Your task applications will appear here.'
                  : 'Tasks you have posted will appear here.',
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
                    date: 'Flexible',
                    time: 'Anytime',
                    distance: 'Nearby',
                    description: data['description']?.toString() ?? 'No description provided.',
                    providerId: data['postedBy'] ?? '',
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
                    Text(
                      '${_fullName.split(' ').first} 👋',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

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

        // ── Category chips ──────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _exploreCategoryChip('All', null),
                ..._categories.map((c) => _exploreCategoryChip(c, c)),
              ],
            ),
          ),
        ),

        // ── Radius chips ────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.only(right: 8, left: 4),
                  child: Row(
                    children: [
                      Icon(Icons.my_location_rounded,
                          size: 14, color: Color(0xFF1976D2)),
                      SizedBox(width: 4),
                      Text('Radius:',
                          style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF1976D2),
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                ..._radiusOptions.map((opt) =>
                    _exploreRadiusChip(opt['label'] as String,
                        opt['value'] as double?)),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

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

              // ── Client-side filtering ──────────────────────────
              final filtered = allDocs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final title =
                    (data['title'] ?? '').toString().toLowerCase();
                final desc =
                    (data['description'] ?? '').toString().toLowerCase();
                final category =
                    (data['category'] ?? '').toString();
                final taskLat = data['latitude'] as double?;
                final taskLng = data['longitude'] as double?;

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
                  if (_userPosition == null ||
                      taskLat == null ||
                      taskLng == null) {
                    // Exclude tasks without coordinates when radius filter active
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
                              ? 'Enable location permission to use radius filter.'
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
                  final taskLat = data['latitude'] as double?;
                  final taskLng = data['longitude'] as double?;

                  // Compute distance label if possible
                  String distanceLabel = 'Nearby';
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
                    date: 'Flexible',
                    time: 'Anytime',
                    distance: distanceLabel,
                    description:
                        data['description']?.toString() ??
                            'No description provided.',
                    providerId: data['postedBy'] ?? '',
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _exploreCategoryChip(String label, String? value) {
    final bool selected = _exploreCategoryFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _exploreCategoryFilter = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF1976D2)
                : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : const Color(0xFF1A1A1A),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _exploreRadiusChip(String label, double? value) {
    final bool selected = _exploreRadiusKm == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _exploreRadiusKm = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFE3F2FD)
                : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? const Color(0xFF1976D2)
                  : Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? const Color(0xFF1976D2)
                  : Colors.grey.shade700,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
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

  Widget _buildProfilePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 30),

          CircleAvatar(
            radius: 50,
            backgroundColor: const Color(0xFFE3F2FD),
            backgroundImage: _profileImageUrl.isNotEmpty
                ? NetworkImage(_profileImageUrl) as ImageProvider
                : null,
            child: _profileImageUrl.isEmpty
                ? const Icon(
                    Icons.person_rounded,
                    color: Color(0xFF1976D2),
                    size: 55,
                  )
                : null,
          ),

          const SizedBox(height: 15),

          Text(
            _fullName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            _area,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
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

          _buildProfileOption(
            Icons.help_outline_rounded,
            'Help & Support',
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