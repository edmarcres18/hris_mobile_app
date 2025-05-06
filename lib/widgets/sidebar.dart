import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class AppSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final VoidCallback onLogout;

  const AppSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Size screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 360;
    final EdgeInsets viewPadding = MediaQuery.of(context).viewPadding;
    
    return Drawer(
      elevation: 2,
      child: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.colorScheme.primary.withAlpha(230),
                theme.colorScheme.surface,
              ],
              stops: const [0.0, 0.3],
            ),
          ),
          child: Column(
            children: [
              SizedBox(height: viewPadding.top),
              _buildHeader(context, isSmallScreen),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutQuart,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    child: ListView(
                      padding: const EdgeInsets.only(top: 16, bottom: 16),
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildSectionTitle(context, 'APPLICATIONS'),
                        _buildSidebarItem(
                          context,
                          index: 0,
                          icon: Icons.time_to_leave_outlined,
                          title: 'Apply Leave',
                          isSelected: selectedIndex == 0,
                          onTap: () => onItemTapped(0),
                        ),
                        _buildSidebarItem(
                          context,
                          index: 1,
                          icon: Icons.access_time_outlined,
                          title: 'Apply Overtime',
                          isSelected: selectedIndex == 1,
                          onTap: () => onItemTapped(1),
                        ),
                        _buildSidebarItem(
                          context,
                          index: 2,
                          icon: Icons.nightlight_outlined,
                          title: 'Apply Night Premium',
                          isSelected: selectedIndex == 2,
                          onTap: () => onItemTapped(2),
                        ),
                        _buildSidebarItem(
                          context,
                          index: 3,
                          icon: Icons.account_balance_outlined,
                          title: 'Apply Company Loan',
                          isSelected: selectedIndex == 3,
                          onTap: () => onItemTapped(3),
                        ),
                        const SizedBox(height: 8),
                        _buildSectionTitle(context, 'OTHER'),
                        _buildSidebarItem(
                          context,
                          index: 4,
                          icon: Icons.attach_money_outlined,
                          title: 'Loan and Contributions',
                          isSelected: selectedIndex == 4,
                          onTap: () => onItemTapped(4),
                        ),
                        _buildSidebarItem(
                          context,
                          index: 5,
                          icon: Icons.cake_outlined,
                          title: 'Birthdays',
                          isSelected: selectedIndex == 5,
                          onTap: () => onItemTapped(5),
                        ),
                        _buildSidebarItem(
                          context,
                          index: 6,
                          icon: Icons.calendar_today_outlined,
                          title: 'Calendar',
                          isSelected: selectedIndex == 6,
                          onTap: () => onItemTapped(6),
                        ),
                        const SizedBox(height: 8),
                        _buildSectionTitle(context, 'PREFERENCES'),
                        _buildSidebarItem(
                          context,
                          index: 7,
                          icon: Icons.settings_outlined,
                          title: 'Settings',
                          isSelected: selectedIndex == 7,
                          onTap: () => onItemTapped(7),
                        ),
                        _buildSidebarItem(
                          context,
                          index: 8,
                          icon: Icons.help_outline,
                          title: 'Help & Support',
                          isSelected: selectedIndex == 8,
                          onTap: () => onItemTapped(8),
                        ),
                        _buildSidebarItem(
                          context,
                          index: 9,
                          icon: Icons.info_outline,
                          title: 'About this app',
                          isSelected: selectedIndex == 9,
                          onTap: () => onItemTapped(9),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _buildLogoutButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isSmallScreen) {
    final theme = Theme.of(context);
    
    return Container(
      height: isSmallScreen ? 160 : 180,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                final user = authProvider.currentUser;
                final String initials = user?.initials ?? 'U';
                final String fullName = user?.fullName ?? 'User';
                final String position = user?.position ?? 'Employee';
                
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Hero(
                        tag: 'profile_avatar',
                        child: Material(
                          elevation: 8,
                          shadowColor: Colors.black54,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: user?.profileImage != null 
                            ? CircleAvatar(
                                radius: isSmallScreen ? 32 : 40,
                                backgroundImage: NetworkImage(user!.profileImage!),
                              )
                            : CircleAvatar(
                                radius: isSmallScreen ? 32 : 40,
                                backgroundColor: Colors.white,
                                child: Text(
                                  initials,
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 24 : 32,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.6,
                        ),
                        child: Text(
                          fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        width: double.infinity,
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.6,
                        ),
                        child: Text(
                          position,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Positioned(
            right: 8,
            top: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'MHR-HRIS',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withAlpha(200),
                    fontSize: 14,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.edit,
                    color: Colors.white70,
                    size: 20,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    // Navigate to edit profile
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 0.5,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildSidebarItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    String? badge,
  }) {
    final theme = Theme.of(context);
    
    return Tooltip(
      message: title,
      preferBelow: false,
      verticalOffset: 20,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withAlpha(51),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            splashColor: theme.colorScheme.primary.withAlpha(26),
            highlightColor: theme.colorScheme.primary.withAlpha(13),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.primary.withAlpha(26),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      color: isSelected ? Colors.white : theme.colorScheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                        fontSize: 14,
                      ),
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                  if (badge != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    final theme = Theme.of(context);
    final EdgeInsets viewPadding = MediaQuery.of(context).viewPadding;
    
    return Container(
      width: double.infinity,
      color: theme.colorScheme.surface,
      padding: EdgeInsets.only(
        bottom: viewPadding.bottom > 0 ? viewPadding.bottom : 8,
        top: 4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(height: 1, thickness: 1),
          SafeArea(
            top: false,
            child: InkWell(
              onTap: onLogout,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.logout_outlined,
                        color: theme.colorScheme.error,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Logout',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.error,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: theme.colorScheme.error,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 