import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/sidebar.dart';
import '../widgets/bottom_navigation.dart';
import '../screens/dashboard_screen.dart';
import '../screens/attendance_screen.dart';
import '../screens/payslip_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/login_screen.dart';
import '../screens/apply_leave_screen.dart';
import '../screens/apply_overtime_screen.dart';
import '../screens/apply_night_premium_screen.dart';
import '../screens/apply_company_loan_screen.dart';
import '../screens/loan_contributions_screen.dart';
import '../screens/birthdays_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/chat_list_screen.dart';
import '../providers/auth_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.initialTabIndex = 0});
  
  final int initialTabIndex;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedIndex;
  int _selectedSidebarIndex = -1;
  final String _appName = "MHRIS Employee";
  
  final List<Widget> _screens = [
    const DashboardScreen(),
    const AttendanceScreen(),
    const ChatListScreen(),
    const PayslipScreen(),
    const ProfileScreen(),
  ];

  final List<String> _screenTitles = [
    'Dashboard',
    'Attendance',
    'Messages',
    'Payslips',
    'Profile',
  ];
  
  // Screens for sidebar navigation
  final Map<int, Widget> _sidebarScreens = {
    0: const ApplyLeaveScreen(),
    1: const ApplyOvertimeScreen(),
    2: const ApplyNightPremiumScreen(),
    3: const ApplyCompanyLoanScreen(),
    4: const LoanContributionsScreen(),
    5: const BirthdaysScreen(),
    6: const CalendarScreen(),
    7: Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.settings,
              size: 80,
              color: Colors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Settings',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This feature is coming soon',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    ),
    8: Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.help_outline,
              size: 80,
              color: Colors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Help & Support',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This feature is coming soon',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    ),
    9: Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              size: 80,
              color: Colors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'About This App',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'MHR-HRIS Mobile App - Version 1.0.0',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    ),
  };

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTabIndex;
  }
  
  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _selectedSidebarIndex = -1; // Reset sidebar selection
    });
  }
  
  void _onSidebarItemTapped(int index) {
    setState(() {
      if (_selectedSidebarIndex == index) {
        // Deselect if tapped again, show main screen
        _selectedSidebarIndex = -1;
      } else {
        _selectedSidebarIndex = index;
      }
    });
    
    // Close the drawer if open (for mobile layout)
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }
  
  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(
                Icons.logout,
                color: Theme.of(context).colorScheme.error,
              ),
              const Text('Confirm Logout'),
            ],
          ),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _logout();
              },
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
  
  void _logout() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();
      
      // Navigate to login screen
      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged out successfully'),
            duration: Duration(seconds: 2),
          ),
        );
        
        // Navigate to login screen (replacing the entire stack)
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Custom purple theme
    final customColorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6A1B9A), // Deep Purple
    );

    // Get subtitle for the app bar - shows the current section
    final String screenSubtitle = _selectedSidebarIndex == -1
        ? _screenTitles[_selectedIndex]
        : _getSidebarTitle(_selectedSidebarIndex);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              _appName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
        ),
            if (screenSubtitle != 'Dashboard') // Only show subtitle if not on dashboard
              Text(
                screenSubtitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        centerTitle: true,
        backgroundColor: customColorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifications',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notifications coming soon'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _showLogoutConfirmation,
          ),
        ],
      ),
      drawer: AppSidebar(
        selectedIndex: _selectedSidebarIndex,
        onItemTapped: _onSidebarItemTapped,
        onLogout: _showLogoutConfirmation,
      ),
      body: _selectedSidebarIndex == -1
          ? _screens[_selectedIndex]
          : _sidebarScreens[_selectedSidebarIndex] ??
              Center(
                child: Text('Screen not found for index $_selectedSidebarIndex'),
              ),
      bottomNavigationBar: BottomNavigation(
        selectedIndex: _selectedIndex,
        onItemTapped: _onBottomNavTapped,
      ),
    );
  }
  
  // Helper method to get the title for sidebar screens
  String _getSidebarTitle(int index) {
    switch (index) {
      case 0: return 'Apply Leave';
      case 1: return 'Apply Overtime';
      case 2: return 'Apply Night Premium';
      case 3: return 'Apply Company Loan';
      case 4: return 'Loan & Contributions';
      case 5: return 'Birthdays';
      case 6: return 'Calendar';
      case 7: return 'Settings';
      case 8: return 'Help & Support';
      case 9: return 'About';
      default: return 'MHR-HRIS';
    }
  }
} 