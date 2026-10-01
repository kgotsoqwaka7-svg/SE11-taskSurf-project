import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'view_task_screen.dart'; // Ensure this matches your file name for TaskDetailsScreen
import 'authScreen.dart';
import 'account_info.dart';

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

  @override
  void initState() {
    super.initState();
    _loadUserData();
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
    final TextEditingController _locationController = TextEditingController();
    
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
                controller: _locationController,
                decoration: InputDecoration(
                  hintText: 'e.g. Cape Town',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.check, color: Color(0xFF1976D2)),
                    onPressed: () async {
                      if (_locationController.text.isNotEmpty) {
                        User? user = _auth.currentUser;
                        if (user != null) {
                          await _firestore.collection('Users').doc(user.uid).update({
                            'area': _locationController.text,
                          });
                          setState(() {
                            _area = _locationController.text;
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

            Column(
              children: [
                const SizedBox(height: 20),
                _buildSearchBar(),
                Expanded(
                  child: _buildPlaceholderPage(
                    Icons.search_rounded,
                    'Explore',
                    isWorker
                        ? 'Find tasks near you.'
                        : 'Explore the TaskSurf marketplace.',
                  ),
                ),
              ],
            ),

            _buildPlaceholderPage(
              Icons.add_circle_outline_rounded,
              isWorker ? 'My Applications' : 'My Tasks',
              isWorker
                  ? 'Your task applications will appear here.'
                  : 'Tasks you have posted will appear here.',
            ),

            _buildPlaceholderPage(
              Icons.chat_bubble_outline_rounded,
              'Messages',
              'Your conversations will appear here.',
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

          // Replaced hardcoded tasks with a live Firebase StreamBuilder
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
                  final data = tasks[index].data() as Map<String, dynamic>;
                  
                  return _buildTaskCard(
                    title: data['title']?.toString() ?? 'Untitled Task',
                    category: data['category']?.toString() ?? 'General',
                    location: data['location']?.toString() ?? 'Location not specified',
                    payment: 'R${data['paymentAmount'] ?? 0}',
                    date: 'Flexible', // Placeholders as TaskModel does not store exact date/time yet
                    time: 'Anytime',
                    distance: 'Nearby',
                    description: data['description']?.toString() ?? 'No description provided.',
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
    String firstName = _fullName.split(' ').first;

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
              // Logo
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

              // Notification button
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

              // Role indicator
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

 

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Search for tasks...',
            hintStyle: TextStyle(
              color: Colors.grey.shade500,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: Color(0xFF1976D2),
            ),
            suffixIcon: Icon(
              Icons.tune_rounded,
              color: Colors.grey.shade600,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
            ),
          ),
        ),
      ),
    );
  }

 

  Widget _buildLocationCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: Color(0xFF1976D2),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your location',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _area,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          TextButton(
            onPressed: () {},
            child: const Text(
              'Change',
              style: TextStyle(
                color: Color(0xFF1976D2),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  

  Widget _buildCategories() {
    final categories = [
      {
        'name': 'Moving',
        'icon': Icons.local_shipping_outlined,
      },
      {
        'name': 'Cleaning',
        'icon': Icons.cleaning_services_outlined,
      },
      {
        'name': 'Gardening',
        'icon': Icons.yard_outlined,
      },
      {
        'name': 'Tech',
        'icon': Icons.computer_outlined,
      },
      {
        'name': 'Delivery',
        'icon': Icons.delivery_dining_outlined,
      },
    ];

    return SizedBox(
      height: 105,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return Container(
            width: 82,
            margin: const EdgeInsets.only(right: 12),
            child: Column(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    categories[index]['icon'] as IconData,
                    color: const Color(0xFF1976D2),
                    size: 28,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  categories[index]['name'] as String,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
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

  
  // Added required 'description' to the parameters so it can be passed to TaskDetailsScreen
  Widget _buildTaskCard({
    required String title,
    required String category,
    required String location,
    required String payment,
    required String date,
    required String time,
    required String distance,
    required String description,
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
                            title: title,
                            category: category,
                            location: location,
                            payment: payment,
                            date: date,
                            time: time,
                            distance: distance,
                            description: description, // Passes the live description
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

          // Profile photo — shows uploaded image or default icon
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
              // Reload user data so name/photo update is reflected immediately
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