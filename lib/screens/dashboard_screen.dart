import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/shared_widgets.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:ntp/ntp.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  late DateTime _currentDate;
  late Timer _clockTimer;
  String _locationAddress = "Fetching location...";
  bool _isUsingNetworkTime = false;
  DateTime? _networkTime;
  Position? _currentPosition;
  String _networkProvider = "Checking...";
  
  @override
  void initState() {
    super.initState();
    _currentDate = DateTime.now();
    // Simulate loading dashboard data
    _isLoading = true;
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
    
    // Start the clock timer to update every second
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentDate = _networkTime != null
              ? _networkTime!.add(Duration(seconds: timer.tick))
              : DateTime.now();
        });
      }
    });
    
    // Get network time
    _fetchNetworkTime();
    
    // Get location
    _determinePosition();
    
    // Get network info
    _checkNetworkProvider();
  }
  
  @override
  void dispose() {
    _clockTimer.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchNetworkTime() async {
    try {
      final networkTime = await NTP.now();
      if (mounted) {
        setState(() {
          _networkTime = networkTime;
          _isUsingNetworkTime = true;
        });
      }
    } catch (e) {
      debugPrint('Error getting network time: $e');
      if (mounted) {
        setState(() {
          _isUsingNetworkTime = false;
        });
      }
    }
  }
  
  Future<void> _checkNetworkProvider() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      String provider = "Unknown";
      
      if (connectivityResult.contains(ConnectivityResult.mobile)) {
        provider = "Mobile Data";
      } else if (connectivityResult.contains(ConnectivityResult.wifi)) {
        provider = "WiFi";
      } else if (connectivityResult.contains(ConnectivityResult.ethernet)) {
        provider = "Ethernet";
      } else if (connectivityResult.contains(ConnectivityResult.vpn)) {
        provider = "VPN";
      } else if (connectivityResult.contains(ConnectivityResult.bluetooth)) {
        provider = "Bluetooth";
      } else {
        provider = "No Connection";
      }
      
      if (mounted) {
        setState(() {
          _networkProvider = provider;
        });
      }
    } catch (e) {
      debugPrint('Error checking network: $e');
      if (mounted) {
        setState(() {
          _networkProvider = "Network Error";
        });
      }
    }
  }
  
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        setState(() {
          _locationAddress = "Location services disabled";
        });
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          setState(() {
            _locationAddress = "Location permissions denied";
          });
        }
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() {
          _locationAddress = "Location permissions permanently denied";
        });
      }
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
        await _getAddressFromLatLng(position);
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (mounted) {
        setState(() {
          _locationAddress = "Could not determine location";
        });
      }
    }
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude, 
        position.longitude,
      );
      if (placemarks.isNotEmpty && mounted) {
        Placemark place = placemarks[0];
        setState(() {
          _locationAddress = '${place.street}, ${place.subLocality}, '
              '${place.locality}, ${place.postalCode}, ${place.country}';
        });
      }
    } catch (e) {
      debugPrint('Error getting address: $e');
      if (mounted) {
        setState(() {
          _locationAddress = "Address unavailable";
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? const SharedPreloader(
                message: 'Loading your dashboard...',
                useScaffold: false,
              )
            : ResponsiveRefreshWrapper(
                onRefresh: _refreshDashboard,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWelcomeCard(),
                      const SizedBox(height: 24),
                      _buildDateTime(),
                      const SizedBox(height: 24),
                      _buildSectionHeader('Announcements'),
                      const SizedBox(height: 12),
                      _buildAnnouncements(),
                      const SizedBox(height: 24),
                      _buildSectionHeader('Leave Status'),
                      const SizedBox(height: 12),
                      _buildLeaveAllocation(),
                      const SizedBox(height: 24),
                      _buildSectionHeader('Birthdays'),
                      const SizedBox(height: 12),
                      _buildBirthdays(),
                      const SizedBox(height: 24),
                      _buildSectionHeader('Holidays'),
                      const SizedBox(height: 12),
                      _buildHolidays(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showQuickActionMenu(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
  
  void _showQuickActionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange.withAlpha(50),
                  child: const Icon(Icons.beach_access, color: Colors.orange),
                ),
                title: const Text('Apply Leave'),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to leave application
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green.withAlpha(50),
                  child: const Icon(Icons.attach_money, color: Colors.green),
                ),
                title: const Text('Apply Company Loan'),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to loan application
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.withAlpha(50),
                  child: const Icon(Icons.headset_mic, color: Colors.blue),
                ),
                title: const Text('Tech Support'),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to tech support
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  Future<void> _refreshDashboard() async {
    setState(() {
      _isLoading = true;
    });
    
    // Refresh network time
    await _fetchNetworkTime();
    
    // Refresh location
    await _determinePosition();
    
    // Refresh network provider
    await _checkNetworkProvider();
    
    // Current time with network updates
    setState(() {
      _currentDate = _networkTime != null 
          ? DateTime.now().add(_networkTime!.difference(DateTime.now()))
          : DateTime.now();
    });
    
    // Simulate API call for other dashboard data
    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextButton(
          onPressed: () {
            // View all for this section
          },
          child: const Text('View All'),
        ),
      ],
    );
  }
  
  Widget _buildWelcomeCard() {
    final now = DateTime.now();
    final hour = now.hour;
    
    // Determine greeting based on time of day
    String greeting;
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }
    
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        final String initials = user?.initials ?? 'U';
        final String fullName = user?.fullName ?? 'User';
        final String position = user?.position ?? 'Employee';
        
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
                  children: [
                    user?.profileImage != null 
                      ? Stack(
                          alignment: Alignment.center,
                          children: [
                            // Background with preloader
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(51),
                              child: SharedPreloader(size: 20.0),
                            ),
                            // Network image with loading handling
                            CircleAvatar(
                              radius: 30,
                              backgroundImage: NetworkImage(user!.profileImage!),
                              backgroundColor: Colors.transparent,
                              onBackgroundImageError: (exception, stackTrace) {
                                // Handle image loading error by showing initials instead
                                debugPrint('Error loading profile image: $exception');
                              },
                            ),
                          ],
                        )
                      : CircleAvatar(
                          radius: 30,
                          backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(51),
                          child: Text(
                            initials,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$greeting,',
                            style: const TextStyle(fontSize: 16),
                          ),
                          Text(
                            fullName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            position,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }
  
  Widget _buildDateTime() {
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final timeFormat = DateFormat('h:mm:ss a');
    final dayOfYear = DateFormat('D').format(_currentDate);
    final weekOfYear = ((DateTime.parse(DateFormat('yyyy-MM-dd').format(_currentDate)).difference(DateTime(DateTime.now().year, 1, 1)).inDays) / 7).floor() + 1;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: Theme.of(context).colorScheme.primary,
                  size: 36,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            timeFormat.format(_currentDate),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _isUsingNetworkTime 
                            ? Icon(
                                Icons.verified, 
                                color: Colors.green, 
                                size: 16,
                              )
                            : Icon(
                                Icons.warning, 
                                color: Colors.orange, 
                                size: 16,
                              ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateFormat.format(_currentDate),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Day of Year: $dayOfYear  •  Week: $weekOfYear',
                  style: TextStyle(
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Location:',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _locationAddress,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 12,
                        ),
                      ),
                      if (_currentPosition != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            'GPS: ${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 10,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.network_cell,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Network Provider: $_networkProvider',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _isUsingNetworkTime ? Icons.sync : Icons.sync_disabled,
                  color: _isUsingNetworkTime ? Colors.green : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _isUsingNetworkTime 
                    ? 'Synchronized with network time (NTP)' 
                    : 'Using device time (not synchronized)',
                  style: TextStyle(
                    color: _isUsingNetworkTime ? Colors.green : Colors.orange,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Last Updated: ${DateFormat('h:mm:ss a').format(DateTime.now())}',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLeaveAllocation() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
            children: [
              Icon(
                  Icons.event_available,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
              ),
                const SizedBox(width: 8),
                const Text(
                  'Leave Status',
                  style: TextStyle(
                    fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
            const SizedBox(height: 16),
            _buildLeaveTypeProgress('Annual Leave', 15, 8, Colors.blue),
            const SizedBox(height: 12),
            _buildLeaveTypeProgress('Sick Leave', 10, 3, Colors.red),
            const SizedBox(height: 12),
            _buildLeaveTypeProgress('Casual Leave', 5, 2, Colors.amber),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLeaveTypeProgress(String type, int total, int used, Color color) {
    final remaining = total - used;
    final percentUsed = used / total;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(type),
            Text(
              '$remaining days remaining',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percentUsed,
          backgroundColor: color.withAlpha(51),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 4),
        Text(
          'Used $used of $total days',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
  
  Widget _buildBirthdays() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.cake,
                  color: Colors.pink,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Today\'s Birthdays',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildBirthdayPerson('John Doe', 'IT Department', true),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.event_note,
                  color: Colors.purple,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Upcoming Birthdays',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildBirthdayPerson('Jane Smith', 'HR Department', false, '5 Apr'),
            const Divider(),
            _buildBirthdayPerson('Mike Johnson', 'Finance Department', false, '12 Apr'),
            const Divider(),
            _buildBirthdayPerson('Sarah Williams', 'Marketing Department', false, '25 Apr'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBirthdayPerson(
    String name, 
    String department, 
    bool isToday, 
    [String? date]
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: (isToday ? Colors.pink : Colors.purple).withAlpha(51),
            child: Text(
              name[0],
              style: TextStyle(
                color: isToday ? Colors.pink : Colors.purple,
                fontWeight: FontWeight.bold,
              ),
            ),
            ),
          const SizedBox(width: 12),
            Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  department,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (!isToday && date != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.purple.withAlpha(51),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                date,
                style: const TextStyle(
                  color: Colors.purple,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (isToday)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.pink.withAlpha(51),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Today',
                style: TextStyle(
                  color: Colors.pink,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
      ),
    );
  }
  
  Widget _buildHolidays() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.celebration,
                  color: Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Today\'s Holidays',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Placeholder for when there's no holiday today
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'No holidays today',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.event_note,
                  color: Colors.blue,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Upcoming Holidays',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildHolidayItem('Labor Day', '1 May 2023', Colors.blue),
            const Divider(),
            _buildHolidayItem('Independence Day', '4 Jul 2023', Colors.blue),
            const Divider(),
            _buildHolidayItem('Company Foundation Day', '15 Aug 2023', Colors.blue),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHolidayItem(String name, String date, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withAlpha(51),
            child: Icon(
              Icons.event,
                color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.calendar_today_outlined,
            color: color,
            size: 16,
          ),
        ],
      ),
    );
  }
  
  Widget _buildAnnouncements() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildAnnouncementItem(
              'Company Holiday',
              'Our office will be closed on July 4th for Independence Day.',
              'HR Department',
              Colors.blue,
            ),
            const Divider(),
            _buildAnnouncementItem(
              'New Benefit Package',
              'We\'re excited to announce our enhanced health benefits starting next month.',
              'Benefits Team',
              Colors.green,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAnnouncementItem(
    String title,
    String content,
    String source,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.announcement_outlined,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(content),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'From: $source',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 