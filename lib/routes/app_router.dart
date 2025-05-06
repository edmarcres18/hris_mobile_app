import 'package:flutter/material.dart';
import '../screens/dashboard_screen.dart';
import '../screens/attendance_screen.dart';
import '../screens/payslip_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/home_screen.dart';
import '../screens/intro_screen.dart';
import '../screens/login_screen.dart';
import '../screens/chat_list_screen.dart';
import '../screens/chat_screen.dart';

class AppRouter {
  static const String intro = '/intro';
  static const String login = '/login';
  static const String home = '/';
  static const String dashboard = '/dashboard';
  static const String attendance = '/attendance';
  static const String payslip = '/payslip';
  static const String profile = '/profile';
  static const String chatList = '/chat-list';
  static const String chat = '/chat';
  
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case intro:
        return MaterialPageRoute(builder: (_) => const IntroScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case home:
        // Extract tab index from arguments if provided
        final args = settings.arguments;
        int tabIndex = 0;
        if (args != null && args is int) {
          tabIndex = args;
        }
        return MaterialPageRoute(builder: (_) => HomeScreen(initialTabIndex: tabIndex));
      case dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case attendance:
        return MaterialPageRoute(builder: (_) => const AttendanceScreen());
      case payslip:
        return MaterialPageRoute(builder: (_) => const PayslipScreen());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case chatList:
        return MaterialPageRoute(builder: (_) => const ChatListScreen());
      case chat:
        // Extract chat parameters from arguments
        final args = settings.arguments;
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => ChatScreen(
              contactId: args['contactId'] ?? '1', // Default to first contact if missing
              contactName: args['contactName'] ?? 'Unknown Contact',
              contactAvatar: args['contactAvatar'] ?? 'https://i.pravatar.cc/150?img=1',
              isGroup: args['isGroup'] ?? false,
            ),
          );
        }
        // Fallback to default chat screen with HR Department if no arguments
        return MaterialPageRoute(
          builder: (_) => const ChatScreen(
            contactId: '1',
            contactName: 'HR Department',
            contactAvatar: 'https://i.pravatar.cc/150?img=1',
            isGroup: false,
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(
              title: const Text('MHR-HRIS'),
            ),
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
  
  // Custom page route with transitions
  static Route<dynamic> _createPageRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);
        
        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
  
  // Function to navigate to a screen with custom transition
  static void navigateTo(BuildContext context, String routeName, {Object? arguments}) {
    Widget targetScreen;
    
    switch (routeName) {
      case intro:
        targetScreen = const IntroScreen();
        break;
      case login:
        targetScreen = const LoginScreen();
        break;
      case home:
        final int tabIndex = arguments is int ? arguments : 0;
        targetScreen = HomeScreen(initialTabIndex: tabIndex);
        break;
      case dashboard:
        targetScreen = const DashboardScreen();
        break;
      case attendance:
        targetScreen = const AttendanceScreen();
        break;
      case payslip:
        targetScreen = const PayslipScreen();
        break;
      case profile:
        targetScreen = const ProfileScreen();
        break;
      case chatList:
        targetScreen = const ChatListScreen();
        break;
      case chat:
        // Extract chat parameters from arguments
        if (arguments is Map<String, dynamic>) {
          targetScreen = ChatScreen(
            contactId: arguments['contactId'] ?? '1',
            contactName: arguments['contactName'] ?? 'Unknown Contact',
            contactAvatar: arguments['contactAvatar'] ?? 'https://i.pravatar.cc/150?img=1',
            isGroup: arguments['isGroup'] ?? false,
          );
        } else {
          // Fallback to default chat screen with HR Department
          targetScreen = const ChatScreen(
            contactId: '1',
            contactName: 'HR Department',
            contactAvatar: 'https://i.pravatar.cc/150?img=1',
            isGroup: false,
          );
        }
        break;
      default:
        targetScreen = Scaffold(
          appBar: AppBar(
            title: const Text('MHR-HRIS'),
          ),
          body: Center(
            child: Text('No route defined for $routeName'),
          ),
        );
    }
    
    Navigator.of(context).push(_createPageRoute(targetScreen));
  }
  
  // Helper function to navigate to chat screen
  static void navigateToChat(BuildContext context, {
    required String contactId, 
    required String contactName, 
    required String contactAvatar, 
    bool isGroup = false
  }) {
    Navigator.of(context).pushNamed(
      chat,
      arguments: {
        'contactId': contactId,
        'contactName': contactName,
        'contactAvatar': contactAvatar,
        'isGroup': isGroup,
      },
    );
  }
  
  // Function to perform a specific navigation action
  static void navigateToHomeTab(BuildContext context, int tabIndex) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      home,
      (route) => false,
      arguments: tabIndex,
    );
  }
  
  // Function to log out and return to login screen
  static void logout(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      login,
      (route) => false,
    );
  }
} 