/// Landing Page Screen
/// 
/// Public-facing landing page matching the PHP version layout and features

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/landing_page_service.dart';
import '../../services/room_service.dart';
import '../../models/room_model.dart';
import '../../core/theme/colors.dart';

class LandingPageScreen extends StatefulWidget {
  const LandingPageScreen({super.key});

  @override
  State<LandingPageScreen> createState() => _LandingPageScreenState();
}

class _LandingPageScreenState extends State<LandingPageScreen> {
  final LandingPageService _landingService = LandingPageService();
  final RoomService _roomService = RoomService();
  
  Map<String, dynamic> _content = {};
  List<RoomModel> _rooms = [];
  Map<String, int> _roomStats = {};
  bool _isLoading = true;
  bool _isVideoMuted = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await Future.wait([
        _landingService.getLandingPageContent(),
        _roomService.getRooms(),
        _landingService.getRoomStatistics(),
      ]);

      setState(() {
        _content = results[0] as Map<String, dynamic>;
        _rooms = results[1] as List<RoomModel>;
        _roomStats = results[2] as Map<String, int>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _openBookingModal() {
    showDialog(
      context: context,
      builder: (context) => _BookingModal(rooms: _rooms),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            _Header(content: _content),
            
            // Hero Section
            _HeroSection(
              content: _content,
              isVideoMuted: _isVideoMuted,
              onMuteToggle: () {
                setState(() {
                  _isVideoMuted = !_isVideoMuted;
                });
              },
              onBookNow: _openBookingModal,
            ),
            
            // Rooms Section
            _RoomsSection(
              rooms: _rooms,
              onBookNow: _openBookingModal,
            ),
            
            // Amenities Section
            const _AmenitiesSection(),
            
            // About Section
            _AboutSection(content: _content),
            
            // Contact Section
            _ContactSection(content: _content),
            
            // Footer
            _Footer(content: _content),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Map<String, dynamic> content;

  const _Header({required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.hotel, color: Color(0xFFd4af37), size: 28),
                  const SizedBox(width: 10),
                  Text(
                    content['hotel_name'] ?? 'Grand Hotel',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFd4af37),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _NavLink(label: 'Rooms', onTap: () {}),
                  const SizedBox(width: 30),
                  _NavLink(label: 'Amenities', onTap: () {}),
                  const SizedBox(width: 30),
                  _NavLink(label: 'About', onTap: () {}),
                  const SizedBox(width: 30),
                  _NavLink(label: 'Contact', onTap: () {}),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () => context.go('/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFd4af37),
                      foregroundColor: const Color(0xFF1a1a2e),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: const Text(
                      'Staff Login',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _NavLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  final Map<String, dynamic> content;
  final bool isVideoMuted;
  final VoidCallback onMuteToggle;
  final VoidCallback onBookNow;

  const _HeroSection({
    required this.content,
    required this.isVideoMuted,
    required this.onMuteToggle,
    required this.onBookNow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 600,
      width: double.infinity,
      child: Stack(
        children: [
          // Video background placeholder (in Flutter, you'd use video_player package)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.black.withOpacity(0.5),
                ],
              ),
            ),
            child: Image.network(
              'https://images.unsplash.com/photo-1566073771259-6a8506099945?ixlib=rb-4.0.3&auto=format&fit=crop&w=1920&q=80',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          // Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.4),
                  Colors.black.withOpacity(0.4),
                ],
              ),
            ),
          ),
          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  content['hero_title'] ?? 'Experience Luxury at Grand Hotel',
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        offset: Offset(2, 2),
                        blurRadius: 4,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  content['hero_subtitle'] ?? content['hotel_description'] ?? '',
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        offset: Offset(1, 1),
                        blurRadius: 2,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: onBookNow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFd4af37),
                    foregroundColor: const Color(0xFF1a1a2e),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  child: const Text(
                    'Book Now',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          // Mute/Unmute button
          Positioned(
            bottom: 30,
            right: 30,
            child: IconButton(
              onPressed: onMuteToggle,
              icon: Icon(
                isVideoMuted ? Icons.volume_off : Icons.volume_up,
                color: const Color(0xFF1a1a2e),
                size: 28,
              ),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFd4af37),
                padding: const EdgeInsets.all(15),
                shape: const CircleBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomsSection extends StatelessWidget {
  final List<RoomModel> rooms;
  final VoidCallback onBookNow;

  const _RoomsSection({required this.rooms, required this.onBookNow});

  @override
  Widget build(BuildContext context) {
    // Group rooms by type (show one per type)
    final roomsByType = <String, RoomModel>{};
    for (var room in rooms) {
      if (!roomsByType.containsKey(room.roomType)) {
        roomsByType[room.roomType] = room;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80),
      color: const Color(0xFFf8f9fa),
      child: Column(
        children: [
          const Text(
            'Our Rooms',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1a1a2e),
            ),
          ),
          Container(
            width: 80,
            height: 4,
            margin: const EdgeInsets.only(top: 20, bottom: 50),
            decoration: BoxDecoration(
              color: const Color(0xFFd4af37),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Container(
            constraints: const BoxConstraints(maxWidth: 1200),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 30,
                mainAxisSpacing: 30,
                childAspectRatio: 0.75,
              ),
              itemCount: roomsByType.length,
              itemBuilder: (context, index) {
                final room = roomsByType.values.elementAt(index);
                return _RoomCard(room: room, onBookNow: onBookNow);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  final RoomModel room;
  final VoidCallback onBookNow;

  const _RoomCard({required this.room, required this.onBookNow});

  String _getRoomTypeName(String type) {
    switch (type.toLowerCase()) {
      case 'single':
        return 'Single Room';
      case 'double':
        return 'Double Room';
      case 'suite':
        return 'Suite';
      case 'deluxe':
        return 'Deluxe Suite';
      default:
        return type;
    }
  }

  String _getRoomImage(String type) {
    final images = {
      'single': 'https://images.unsplash.com/photo-1631049307264-da0ec9d70304?ixlib=rb-4.0.3&auto=format&fit=crop&w=1200&q=80',
      'double': 'https://images.unsplash.com/photo-1611892440504-42a792e24d32?ixlib=rb-4.0.3&auto=format&fit=crop&w=1200&q=80',
      'suite': 'https://images.unsplash.com/photo-1578500494198-246f612d03b3?ixlib=rb-4.0.3&auto=format&fit=crop&w=1200&q=80',
      'deluxe': 'https://images.unsplash.com/photo-1591088398332-8c5ecd3b3c4d?ixlib=rb-4.0.3&auto=format&fit=crop&w=1200&q=80',
    };
    return images[type.toLowerCase()] ?? images['double']!;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                  child: Image.network(
                    _getRoomImage(room.roomType),
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.hotel, size: 50),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 15,
                  right: 15,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFd4af37),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      '${room.capacity} Guest${room.capacity > 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1a1a2e),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.roomType.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFd4af37),
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getRoomTypeName(room.roomType),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1a1a2e),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Luxuriously appointed ${_getRoomTypeName(room.roomType).toLowerCase()} with premium amenities and modern comfort.',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                      height: 1.6,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '\$${room.pricePerNight.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFd4af37),
                    ),
                  ),
                  const Text(
                    'per night',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onBookNow,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFd4af37),
                            foregroundColor: const Color(0xFF1a1a2e),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          child: const Text('Book Now', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1a1a2e),
                            side: const BorderSide(color: Color(0xFFd4af37), width: 2),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          child: const Text('Details', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmenitiesSection extends StatelessWidget {
  const _AmenitiesSection();

  @override
  Widget build(BuildContext context) {
    final amenities = [
      {'icon': Icons.wifi, 'title': 'Free WiFi', 'subtitle': 'High-speed internet throughout the hotel'},
      {'icon': Icons.pool, 'title': 'Swimming Pool', 'subtitle': 'Olympic-sized pool with heated water'},
      {'icon': Icons.restaurant, 'title': 'Restaurant & Bar', 'subtitle': 'Fine dining with international cuisine'},
      {'icon': Icons.fitness_center, 'title': 'Fitness Center', 'subtitle': 'State-of-the-art gym equipment'},
      {'icon': Icons.room_service, 'title': '24/7 Room Service', 'subtitle': 'Round-the-clock service for your convenience'},
      {'icon': Icons.spa, 'title': 'Spa & Wellness', 'subtitle': 'Relaxation and rejuvenation treatments'},
      {'icon': Icons.local_parking, 'title': 'Free Parking', 'subtitle': 'Secure parking for all guests'},
      {'icon': Icons.airport_shuttle, 'title': 'Airport Shuttle', 'subtitle': 'Complimentary airport transportation'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Column(
        children: [
          const Text(
            'Hotel Amenities',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1a1a2e),
            ),
          ),
          Container(
            width: 80,
            height: 4,
            margin: const EdgeInsets.only(top: 20, bottom: 50),
            decoration: BoxDecoration(
              color: const Color(0xFFd4af37),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Container(
            constraints: const BoxConstraints(maxWidth: 1200),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 30,
                mainAxisSpacing: 30,
                childAspectRatio: 1.2,
              ),
              itemCount: amenities.length,
              itemBuilder: (context, index) {
                final amenity = amenities[index];
                return _AmenityCard(
                  icon: amenity['icon'] as IconData,
                  title: amenity['title'] as String,
                  subtitle: amenity['subtitle'] as String,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AmenityCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _AmenityCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: const Color(0xFFf8f9fa),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: const Color(0xFFd4af37),
              ),
              const SizedBox(height: 15),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1a1a2e),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  final Map<String, dynamic> content;

  const _AboutSection({required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80),
      color: const Color(0xFFf8f9fa),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1200),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const Text(
              'About Grand Hotel',
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1a1a2e),
              ),
            ),
            Container(
              width: 80,
              height: 4,
              margin: const EdgeInsets.only(top: 20, bottom: 50),
              decoration: BoxDecoration(
                color: const Color(0xFFd4af37),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome to Luxury',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1a1a2e),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        content['about_text'] ?? 'Grand Hotel stands as a beacon of luxury and hospitality...',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF666666),
                          height: 1.8,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 50),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      content['about_image_url'] ?? 'https://images.unsplash.com/photo-1566073771259-6a8506099945?ixlib=rb-4.0.3&auto=format&fit=crop&w=1170&q=80',
                      height: 400,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 400,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image, size: 50),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactSection extends StatelessWidget {
  final Map<String, dynamic> content;

  const _ContactSection({required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Column(
        children: [
          const Text(
            'Contact Us',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1a1a2e),
            ),
          ),
          Container(
            width: 80,
            height: 4,
            margin: const EdgeInsets.only(top: 20, bottom: 50),
            decoration: BoxDecoration(
              color: const Color(0xFFd4af37),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Container(
            constraints: const BoxConstraints(maxWidth: 1200),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: _ContactCard(
                    icon: Icons.location_on,
                    title: 'Address',
                    content: content['contact_address'] ?? '123 Luxury Avenue\nNew York, NY 10001\nUnited States',
                  ),
                ),
                const SizedBox(width: 30),
                Expanded(
                  child: _ContactCard(
                    icon: Icons.phone,
                    title: 'Phone',
                    content: content['contact_phone'] ?? '+1 (555) 123-4567\n+1 (555) 123-4568\nAvailable 24/7',
                  ),
                ),
                const SizedBox(width: 30),
                Expanded(
                  child: _ContactCard(
                    icon: Icons.email,
                    title: 'Email',
                    content: content['contact_email'] ?? 'info@grandhotel.com\nreservations@grandhotel.com\nsupport@grandhotel.com',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;

  const _ContactCard({
    required this.icon,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: const Color(0xFFf8f9fa),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            Icon(icon, size: 36, color: const Color(0xFFd4af37)),
            const SizedBox(height: 15),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1a1a2e),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              content,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final Map<String, dynamic> content;

  const _Footer({required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About ${content['hotel_name'] ?? 'Grand Hotel'}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFd4af37),
                        ),
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        'Experience luxury and comfort at Grand Hotel, your premier destination for world-class hospitality.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFFcccccc),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 30),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quick Links',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFd4af37),
                        ),
                      ),
                      const SizedBox(height: 15),
                      _FooterLink(label: 'Rooms', onTap: () {}),
                      _FooterLink(label: 'Amenities', onTap: () {}),
                      _FooterLink(label: 'About Us', onTap: () {}),
                      _FooterLink(label: 'Contact', onTap: () {}),
                    ],
                  ),
                ),
                const SizedBox(width: 30),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Policies',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFd4af37),
                        ),
                      ),
                      const SizedBox(height: 15),
                      _FooterLink(label: 'Privacy Policy', onTap: () {}),
                      _FooterLink(label: 'Terms & Conditions', onTap: () {}),
                      _FooterLink(label: 'Cancellation Policy', onTap: () {}),
                      _FooterLink(label: 'Booking Terms', onTap: () {}),
                    ],
                  ),
                ),
                const SizedBox(width: 30),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Contact Info',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFd4af37),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        'Address:\n${content['contact_address'] ?? '123 Luxury Avenue\nNew York, NY 10001'}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFFcccccc),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Phone:\n${content['contact_phone'] ?? '+1 (555) 123-4567'}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFFcccccc),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Email:\n${content['contact_email'] ?? 'info@grandhotel.com'}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFFcccccc),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(color: Color(0xFF444444), height: 40),
            const Center(
              child: Text(
                '© 2024 Grand Hotel. All rights reserved. | Designed with ❤️ for your comfort',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF999999),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _FooterLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFFcccccc),
          ),
        ),
      ),
    );
  }
}

class _BookingModal extends StatelessWidget {
  final List<RoomModel> rooms;

  const _BookingModal({required this.rooms});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              ),
              padding: const EdgeInsets.all(25),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Book Your Room',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'GUEST INFORMATION',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1a1a2e),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'First Name *',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Last Name *',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    const TextField(
                      decoration: InputDecoration(
                        labelText: 'Email *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Phone *',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Country',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'ROOM & DATES',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1a1a2e),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Room Type *',
                        border: OutlineInputBorder(),
                      ),
                      items: ['Single Room', 'Double Room', 'Suite', 'Deluxe Suite']
                          .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                          .toList(),
                      onChanged: (value) {},
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Check-in Date *',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Check-out Date *',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: const Color(0xFFf8f9fa),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Nights:', style: TextStyle(fontSize: 14)),
                              const Text('0', style: TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Price per Night:', style: TextStyle(fontSize: 14)),
                              const Text('\$0.00', style: TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const Text('\$0.00', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFd4af37))),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Handle booking submission
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFd4af37),
                          foregroundColor: const Color(0xFF1a1a2e),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        child: const Text(
                          'Confirm Booking',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

