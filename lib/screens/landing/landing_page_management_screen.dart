/// Landing Page Management Screen
/// 
/// Admin interface for managing landing page content, media/images, and viewing room statistics

import 'package:flutter/material.dart';
import '../../services/landing_page_service.dart';
import '../../services/room_service.dart';
import '../../core/theme/colors.dart';
import '../../core/widgets/common_widgets.dart';

class LandingPageManagementScreen extends StatefulWidget {
  const LandingPageManagementScreen({super.key});

  @override
  State<LandingPageManagementScreen> createState() => _LandingPageManagementScreenState();
}

class _LandingPageManagementScreenState extends State<LandingPageManagementScreen> {
  final LandingPageService _landingService = LandingPageService();
  final RoomService _roomService = RoomService();
  
  Map<String, dynamic> _content = {};
  Map<String, int> _roomStats = {};
  bool _isLoading = true;
  bool _isSaving = false;

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
        _landingService.getRoomStatistics(),
      ]);

      setState(() {
        _content = results[0] as Map<String, dynamic>;
        _roomStats = results[1] as Map<String, int>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _saveContent() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final success = await _landingService.updateLandingPageContent(_content);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Landing page content saved successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingWidget(message: 'Loading landing page data...');
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Landing Page Management',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2c3e50),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveContent,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3498db),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),

          // Room Statistics Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.door_front_door, color: Color(0xFF3498db), size: 28),
                      const SizedBox(width: 12),
                      const Text(
                        'Room Statistics',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2c3e50),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () async {
                          final stats = await _landingService.getRoomStatistics();
                          setState(() {
                            _roomStats = stats;
                          });
                        },
                        tooltip: 'Refresh Statistics',
                      ),
                    ],
                  ),
                  const Divider(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Total Rooms',
                          value: '${_roomStats['total'] ?? 0}',
                          icon: Icons.hotel,
                          color: const Color(0xFF3498db),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _StatCard(
                          label: 'Available',
                          value: '${_roomStats['available'] ?? 0}',
                          icon: Icons.check_circle,
                          color: const Color(0xFF2ecc71),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _StatCard(
                          label: 'Occupied',
                          value: '${_roomStats['occupied'] ?? 0}',
                          icon: Icons.people,
                          color: const Color(0xFFe74c3c),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _StatCard(
                          label: 'Booked',
                          value: '${_roomStats['booked'] ?? 0}',
                          icon: Icons.calendar_today,
                          color: const Color(0xFFf39c12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),

          // Content Management Tabs
          DefaultTabController(
            length: 4,
            child: Column(
              children: [
                const TabBar(
                  labelColor: Color(0xFF3498db),
                  unselectedLabelColor: Color(0xFF7f8c8d),
                  indicatorColor: Color(0xFF3498db),
                  tabs: [
                    Tab(text: 'General', icon: Icon(Icons.info)),
                    Tab(text: 'Hero Section', icon: Icon(Icons.video_library)),
                    Tab(text: 'About Section', icon: Icon(Icons.description)),
                    Tab(text: 'Contact & Social', icon: Icon(Icons.contact_mail)),
                  ],
                ),
                SizedBox(
                  height: 600,
                  child: TabBarView(
                    children: [
                      _GeneralTab(content: _content, onUpdate: (key, value) {
                        setState(() {
                          _content[key] = value;
                        });
                      }),
                      _HeroTab(content: _content, onUpdate: (key, value) {
                        setState(() {
                          _content[key] = value;
                        });
                      }),
                      _AboutTab(content: _content, onUpdate: (key, value) {
                        setState(() {
                          _content[key] = value;
                        });
                      }),
                      _ContactTab(content: _content, onUpdate: (key, value) {
                        setState(() {
                          _content[key] = value;
                        });
                      }),
                    ],
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

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF7f8c8d),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GeneralTab extends StatelessWidget {
  final Map<String, dynamic> content;
  final Function(String, dynamic) onUpdate;

  const _GeneralTab({required this.content, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            decoration: const InputDecoration(
              labelText: 'Hotel Name',
              border: OutlineInputBorder(),
            ),
            controller: TextEditingController(text: content['hotel_name'] ?? ''),
            onChanged: (value) => onUpdate('hotel_name', value),
          ),
          const SizedBox(height: 20),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Hotel Description',
              border: OutlineInputBorder(),
              hintText: 'Short description for hero section',
            ),
            maxLines: 3,
            controller: TextEditingController(text: content['hotel_description'] ?? ''),
            onChanged: (value) => onUpdate('hotel_description', value),
          ),
        ],
      ),
    );
  }
}

class _HeroTab extends StatelessWidget {
  final Map<String, dynamic> content;
  final Function(String, dynamic) onUpdate;

  const _HeroTab({required this.content, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            decoration: const InputDecoration(
              labelText: 'Hero Title',
              border: OutlineInputBorder(),
            ),
            controller: TextEditingController(text: content['hero_title'] ?? ''),
            onChanged: (value) => onUpdate('hero_title', value),
          ),
          const SizedBox(height: 20),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Hero Subtitle',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
            controller: TextEditingController(text: content['hero_subtitle'] ?? ''),
            onChanged: (value) => onUpdate('hero_subtitle', value),
          ),
          const SizedBox(height: 20),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Hero Video URL',
              border: OutlineInputBorder(),
              hintText: 'URL to video file or YouTube/Vimeo link',
            ),
            controller: TextEditingController(text: content['hero_video_url'] ?? ''),
            onChanged: (value) => onUpdate('hero_video_url', value),
          ),
          const SizedBox(height: 20),
          const Text(
            'Room Images',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          ...['single', 'double', 'suite', 'deluxe'].map((type) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: TextField(
                decoration: InputDecoration(
                  labelText: '${type[0].toUpperCase()}${type.substring(1)} Room Image URL',
                  border: const OutlineInputBorder(),
                ),
                controller: TextEditingController(
                  text: (content['room_images'] as Map<String, dynamic>?)?[type] ?? '',
                ),
                onChanged: (value) {
                  final roomImages = Map<String, dynamic>.from(
                    content['room_images'] as Map<String, dynamic>? ?? {},
                  );
                  roomImages[type] = value;
                  onUpdate('room_images', roomImages);
                },
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

class _AboutTab extends StatelessWidget {
  final Map<String, dynamic> content;
  final Function(String, dynamic) onUpdate;

  const _AboutTab({required this.content, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            decoration: const InputDecoration(
              labelText: 'About Title',
              border: OutlineInputBorder(),
            ),
            controller: TextEditingController(text: content['about_title'] ?? ''),
            onChanged: (value) => onUpdate('about_title', value),
          ),
          const SizedBox(height: 20),
          TextField(
            decoration: const InputDecoration(
              labelText: 'About Text',
              border: OutlineInputBorder(),
              hintText: 'Description about the hotel',
            ),
            maxLines: 8,
            controller: TextEditingController(text: content['about_text'] ?? ''),
            onChanged: (value) => onUpdate('about_text', value),
          ),
          const SizedBox(height: 20),
          TextField(
            decoration: const InputDecoration(
              labelText: 'About Image URL',
              border: OutlineInputBorder(),
            ),
            controller: TextEditingController(text: content['about_image_url'] ?? ''),
            onChanged: (value) => onUpdate('about_image_url', value),
          ),
        ],
      ),
    );
  }
}

class _ContactTab extends StatelessWidget {
  final Map<String, dynamic> content;
  final Function(String, dynamic) onUpdate;

  const _ContactTab({required this.content, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contact Information',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Address',
              border: OutlineInputBorder(),
              hintText: 'Multi-line address',
            ),
            maxLines: 3,
            controller: TextEditingController(text: content['contact_address'] ?? ''),
            onChanged: (value) => onUpdate('contact_address', value),
          ),
          const SizedBox(height: 20),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Phone',
              border: OutlineInputBorder(),
            ),
            controller: TextEditingController(text: content['contact_phone'] ?? ''),
            onChanged: (value) => onUpdate('contact_phone', value),
          ),
          const SizedBox(height: 20),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
            controller: TextEditingController(text: content['contact_email'] ?? ''),
            onChanged: (value) => onUpdate('contact_email', value),
          ),
          const SizedBox(height: 30),
          const Text(
            'Social Media Links',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Facebook URL',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.facebook),
            ),
            controller: TextEditingController(text: content['social_facebook'] ?? ''),
            onChanged: (value) => onUpdate('social_facebook', value),
          ),
          const SizedBox(height: 15),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Twitter URL',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.alternate_email),
            ),
            controller: TextEditingController(text: content['social_twitter'] ?? ''),
            onChanged: (value) => onUpdate('social_twitter', value),
          ),
          const SizedBox(height: 15),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Instagram URL',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.camera_alt),
            ),
            controller: TextEditingController(text: content['social_instagram'] ?? ''),
            onChanged: (value) => onUpdate('social_instagram', value),
          ),
          const SizedBox(height: 15),
          TextField(
            decoration: const InputDecoration(
              labelText: 'LinkedIn URL',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.business),
            ),
            controller: TextEditingController(text: content['social_linkedin'] ?? ''),
            onChanged: (value) => onUpdate('social_linkedin', value),
          ),
        ],
      ),
    );
  }
}

