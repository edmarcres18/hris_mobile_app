import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../widgets/shared_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isLoading = false;
  bool _isRefreshing = false;
  
  // Controllers for editable fields
  final Map<String, TextEditingController> _controllers = {};
  
  // Add state variables for password and profile image
  bool _showPassword = false;
  bool _showPasswordConfirmation = false;
  File? _profileImageFile;
  
  @override
  void initState() {
    super.initState();
    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _animationController.forward();
    
    // Initialize controllers with user data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeControllers();
    });
  }
  
  void _initializeControllers() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    
    if (user != null) {
      _controllers['firstName'] = TextEditingController(text: user.firstName);
      _controllers['middleName'] = TextEditingController(text: user.middleName ?? '');
      _controllers['lastName'] = TextEditingController(text: user.lastName);
      _controllers['suffix'] = TextEditingController(text: user.suffix ?? '');
      _controllers['email'] = TextEditingController(text: user.email);
      _controllers['bio'] = TextEditingController(text: user.bio ?? '');
      _controllers['password'] = TextEditingController();
      _controllers['passwordConfirmation'] = TextEditingController();
    }
  }
  
  @override
  void dispose() {
    // Dispose controllers
    _controllers.forEach((key, controller) {
      controller.dispose();
    });
    _animationController.dispose();
    super.dispose();
  }

  // Add refresh functionality
  Future<void> _refreshProfile() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.refreshUserData();
      
      // Re-initialize controllers with fresh data
      _initializeControllers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing profile data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final theme = Theme.of(context);
    final isSmallScreen = mediaQuery.size.width < 600;
    final paddingValue = isSmallScreen ? 12.0 : 24.0;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Icon(
                _isEditing ? Icons.save_rounded : Icons.edit_rounded,
                key: ValueKey<bool>(_isEditing),
              ),
            ),
            onPressed: _isLoading 
              ? null 
              : () {
                  if (_isEditing) {
                    // Save profile
                    if (_formKey.currentState?.validate() ?? false) {
                      _saveProfile();
                    }
                  } else {
                    // Enter edit mode with animation
                    _animationController.reset();
                    setState(() {
                      _isEditing = true;
                    });
                    _animationController.forward();
                  }
                },
            tooltip: _isEditing ? 'Save Profile' : 'Edit Profile',
          ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Cancel Editing',
              onPressed: _isLoading ? null : _confirmCancelEditing,
            ),
        ],
      ),
      body: _isLoading
          ? const SharedPreloader(
              message: 'Loading profile data...',
              useScaffold: true,
            )
          : SafeArea(
              child: ResponsiveRefreshWrapper(
                onRefresh: _refreshProfile,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.all(paddingValue),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        switchInCurve: Curves.easeInOut,
                        switchOutCurve: Curves.easeInOut,
                        child: Column(
                          key: ValueKey<bool>(_isEditing),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildProfileHeader(isSmallScreen),
                            SizedBox(height: isSmallScreen ? 16 : 24),
                            _isEditing ? _buildEditForm(isSmallScreen) : _buildProfileDetails(isSmallScreen),
                            SizedBox(height: isSmallScreen ? 20 : 30),
                            _buildLogoutButton(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
      floatingActionButton: _isEditing
          ? FloatingActionButton.extended(
              onPressed: () {
                if (_formKey.currentState?.validate() ?? false) {
                  _saveProfile();
                }
              },
              icon: const Icon(Icons.check),
              label: const Text('Save Changes'),
              elevation: 2,
            )
          : null,
    );
  }
  
  Widget _buildProfileHeader(bool isSmallScreen) {
    final theme = Theme.of(context);
    final avatarSize = isSmallScreen ? 60.0 : 80.0;
    
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        final String initials = user?.initials ?? 'U';
        final String fullName = user?.fullName ?? 'User';
        final String position = user?.position ?? 'Employee';
        
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withAlpha(13),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 16.0 : 20.0),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Hero(
                      tag: 'profile_avatar',
                      child: Material(
                        elevation: 4,
                        shadowColor: theme.shadowColor.withAlpha(102),
                        shape: const CircleBorder(),
                        child: user?.profileImage != null 
                          ? CircleAvatar(
                              radius: avatarSize,
                              backgroundImage: NetworkImage(user!.profileImage!),
                              backgroundColor: theme.colorScheme.primary.withAlpha(36),
                              onBackgroundImageError: (exception, stackTrace) {
                                // Handle image loading error by showing initials instead
                                debugPrint('Error loading profile image: $exception');
                              },
                            )
                          : CircleAvatar(
                              radius: avatarSize,
                              backgroundColor: theme.colorScheme.primary.withAlpha(36),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: Text(
                                  initials,
                                  key: ValueKey<String>(initials),
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 32 : 40,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                      ),
                    ),
                    if (!_isEditing)
                      Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.add_a_photo,
                            color: Colors.white,
                            size: 18,
                          ),
                          onPressed: _showChangeProfilePhotoOptions,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  fullName,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 24 : 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  position,
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color?.withAlpha(179),
                    fontSize: isSmallScreen ? 16 : 18,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                if (user != null)
                  Text(
                    user.email,
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color?.withAlpha(128),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                if (user != null && user.bio != null && user.bio!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.dividerColor.withAlpha(50),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.format_quote,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Bio',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user.bio!,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.4,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (!_isEditing) 
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildQuickAction(
                          Icons.edit,
                          'Edit',
                          theme.colorScheme.primary,
                          () {
                            setState(() {
                              _isEditing = true;
                            });
                          },
                        ),
                        const SizedBox(width: 16),
                        _buildQuickAction(
                          Icons.qr_code,
                          'QR Code',
                          Colors.blue,
                          () {},
                        ),
                        const SizedBox(width: 16),
                        _buildQuickAction(
                          Icons.share,
                          'Share',
                          Colors.green,
                          () {},
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
  
  Widget _buildQuickAction(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 8.0 : 10.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              elevation: 2,
              shadowColor: color.withAlpha(128),
              borderRadius: BorderRadius.circular(isSmallScreen ? 18 : 22),
              child: CircleAvatar(
                radius: isSmallScreen ? 18 : 22,
                backgroundColor: color.withAlpha(32),
                child: Icon(
                  icon,
                  color: color,
                  size: isSmallScreen ? 18 : 22,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: isSmallScreen ? 12 : 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProfileDetails(bool isSmallScreen) {
    final theme = Theme.of(context);
    
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bio Section - Displayed prominently at the top
            if (user != null && user.bio != null && user.bio!.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'About Me',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 18 : 20,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: theme.dividerColor.withAlpha(20),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(
                        theme,
                        Icons.format_quote,
                        'Bio',
                        user.bio!,
                        isLast: true,
                        largeValue: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            // Personal Information Section
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: isSmallScreen ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: theme.dividerColor.withAlpha(20),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    if (user != null) ...[
                      _buildInfoRow(
                        theme,
                        Icons.person_outline,
                        'Full Name',
                        _buildFullName(user),
                        isLast: false,
                      ),
                      if (user.middleName != null && user.middleName!.isNotEmpty)
                        _buildInfoRow(
                          theme,
                          Icons.person_outline,
                          'Middle Name',
                          user.middleName!,
                          isLast: false,
                        ),
                      if (user.suffix != null && user.suffix!.isNotEmpty)
                        _buildInfoRow(
                          theme,
                          Icons.person_outline,
                          'Suffix',
                          user.suffix!,
                          isLast: false,
                        ),
                      _buildInfoRow(
                        theme,
                        Icons.email_outlined,
                        'Email',
                        user.email,
                        isLast: true,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            // Employment Information Section
            if (user != null && user.employee != null) ...[
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Employment Information',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 18 : 20,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: theme.dividerColor.withAlpha(20),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        theme,
                        Icons.work_outline,
                        'Position',
                        user.position ?? 'Not specified',
                        isLast: false,
                      ),
                      _buildInfoRow(
                        theme,
                        Icons.business_outlined,
                        'Department',
                        user.department ?? 'Not specified',
                        isLast: true,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      }
    );
  }
  
  String _buildFullName(User user) {
    String fullName = '${user.firstName} ${user.lastName}';
    if (user.suffix != null && user.suffix!.isNotEmpty) {
      fullName += ', ${user.suffix}';
    }
    return fullName;
  }
  
  Widget _buildEditForm(bool isSmallScreen) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Edit Profile',
              style: TextStyle(
                fontSize: isSmallScreen ? 18 : 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          // Profile Image
          _buildProfileImageSection(),
          const SizedBox(height: 24),
          
          // Personal Information Section
          Text(
            'Personal Information',
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          
          // First Name, Middle Name Row
          if (_controllers.containsKey('firstName') && _controllers.containsKey('middleName')) ...[
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildFormField(
                    'firstName',
                    'First Name',
                    Icons.person_outline,
                    TextInputType.name,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: _buildFormField(
                    'middleName',
                    'Middle Name',
                    Icons.person_outline,
                    TextInputType.name,
                    isRequired: false,
                  ),
                ),
              ],
            ),
          ],
          
          // Last Name, Suffix Row
          if (_controllers.containsKey('lastName') && _controllers.containsKey('suffix')) ...[
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildFormField(
                    'lastName',
                    'Last Name',
                    Icons.person_outline,
                    TextInputType.name,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: _buildFormField(
                    'suffix',
                    'Suffix',
                    Icons.person_outline,
                    TextInputType.name,
                    isRequired: false,
                    hintText: 'E.g., Jr., Sr., III',
                  ),
                ),
              ],
            ),
          ],
          
          // Email
          if (_controllers.containsKey('email'))
            _buildFormField(
              'email',
              'Email',
              Icons.email_outlined,
              TextInputType.emailAddress,
            ),
            
          // Bio - Now required
          if (_controllers.containsKey('bio'))
            _buildFormField(
              'bio',
              'Bio',
              Icons.info_outline,
              TextInputType.multiline,
              isRequired: true,
              maxLines: 3,
              hintText: 'Tell us about yourself',
            ),
          
          const SizedBox(height: 24),
          
          // Password Section
          Text(
            'Change Password',
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Leave blank if you don\'t want to change your password',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 16),
          
          // Password
          if (_controllers.containsKey('password'))
            _buildPasswordField(
              'password',
              'New Password',
              Icons.lock_outline,
              _showPassword,
              () {
                setState(() {
                  _showPassword = !_showPassword;
                });
              },
              isRequired: false,
            ),
            
          // Password Confirmation
          if (_controllers.containsKey('passwordConfirmation'))
            _buildPasswordField(
              'passwordConfirmation',
              'Confirm Password',
              Icons.lock_outline,
              _showPasswordConfirmation,
              () {
                setState(() {
                  _showPasswordConfirmation = !_showPasswordConfirmation;
                });
              },
              isRequired: false,
              validator: (value) {
                if (_controllers['password']!.text.isNotEmpty && (value == null || value.isEmpty)) {
                  return 'Please confirm your password';
                }
                if (value != _controllers['password']!.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(
    ThemeData theme,
    IconData icon,
    String label,
    String value, {
    bool isLast = false,
    bool largeValue = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: theme.colorScheme.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color?.withAlpha(179),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: largeValue ? 16 : 16,
                        height: largeValue ? 1.5 : 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!isLast)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Divider(
                color: theme.dividerColor.withAlpha(20),
                height: 1,
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildFormField(
    String field,
    String label,
    IconData icon,
    TextInputType keyboardType, {
    bool isRequired = true,
    String? hintText,
    int? maxLines,
  }) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: _controllers[field],
        keyboardType: keyboardType,
        textCapitalization: keyboardType == TextInputType.name 
            ? TextCapitalization.words 
            : TextCapitalization.none,
        style: const TextStyle(fontSize: 16),
        maxLines: maxLines ?? 1,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText ?? 'Enter your $label',
          prefixIcon: Icon(icon, color: theme.colorScheme.primary.withAlpha(128)),
          filled: true,
          fillColor: theme.inputDecorationTheme.fillColor ?? theme.cardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.dividerColor, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.dividerColor.withAlpha(32), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.colorScheme.error, width: 1),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
        ),
        validator: (value) {
          // Only validate required fields if they're empty
          if (isRequired && (value == null || value.isEmpty)) {
            return '$label is required';
          }
          
          // Validate email format if it's not empty
          if (field == 'email' && value != null && value.isNotEmpty && !_isValidEmail(value)) {
            return 'Please enter a valid email address';
          }
          
          return null;
        },
      ),
    );
  }
  
  Widget _buildPasswordField(
    String field,
    String label,
    IconData icon,
    bool showPassword,
    VoidCallback onTap, {
    bool isRequired = true,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: _controllers[field],
        keyboardType: TextInputType.visiblePassword,
        textCapitalization: TextCapitalization.none,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          hintText: 'Enter your $label',
          prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary.withAlpha(128)),
          filled: true,
          fillColor: Theme.of(context).inputDecorationTheme.fillColor ?? Theme.of(context).cardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).dividerColor, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).dividerColor.withAlpha(32), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: 1),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          suffixIcon: IconButton(
            icon: Icon(
              showPassword ? Icons.visibility : Icons.visibility_off,
              color: Theme.of(context).colorScheme.primary.withAlpha(128),
            ),
            onPressed: onTap,
          ),
        ),
        obscureText: !showPassword,
        validator: validator,
      ),
    );
  }
  
  Widget _buildLogoutButton() {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 16.0),
      child: ElevatedButton.icon(
        onPressed: _showLogoutConfirmation,
        icon: const Icon(Icons.logout, color: Colors.white),
        label: const Text(
          'Logout',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.error,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
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
    // Store context references before async operations
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await authProvider.logout();
      
      // Check if widget is still mounted
      if (!mounted) return;
      
      // Exit loading state
      setState(() {
        _isLoading = false;
      });
      
      // Show success message
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Logged out successfully'),
          duration: Duration(seconds: 2),
        ),
      );
      
      // Navigate to login screen (replacing the entire stack)
      navigator.pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {
      // Check if widget is still mounted
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error logging out: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _showChangeProfilePhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Change Profile Photo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(),
              _buildImageOption(
                context,
                'Take Photo',
                Icons.camera_alt,
                Colors.blue,
                () => _handleImageOption('camera'),
              ),
              _buildImageOption(
                context,
                'Choose from Gallery',
                Icons.photo_library,
                Colors.green,
                () => _handleImageOption('gallery'),
              ),
              _buildImageOption(
                context,
                'Remove Current Photo',
                Icons.delete,
                Colors.red,
                () => _handleImageOption('remove'),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildImageOption(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 24,
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _handleImageOption(String option) async {
    Navigator.pop(context);
    
    // Store context references before async operations
    final scaffoldMessengerContext = ScaffoldMessenger.of(context);
    
    if (option == 'camera' || option == 'gallery') {
      try {
        // Request permissions first
        PermissionStatus status;
        if (option == 'camera') {
          status = await Permission.camera.request();
        } else {
          status = await Permission.photos.request();
        }
        
        if (!mounted) return;
        
        if (status.isGranted) {
          _pickImage(option == 'camera' ? ImageSource.camera : ImageSource.gallery);
        } else if (status.isPermanentlyDenied) {
          _showPermissionDeniedDialog(option == 'camera' ? 'camera' : 'photo gallery');
        } else if (status.isDenied) {
          scaffoldMessengerContext.showSnackBar(
            SnackBar(
              content: Text('${option == 'camera' ? 'Camera' : 'Photo gallery'} permission denied'),
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'GRANT',
                onPressed: () {
                  // Try again
                  if (mounted) _showChangeProfilePhotoOptions();
                },
              ),
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        
        scaffoldMessengerContext.showSnackBar(
          SnackBar(
            content: Text('Error accessing ${option == 'camera' ? 'camera' : 'gallery'}: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else if (option == 'remove') {
      if (!mounted) return;
      
      setState(() {
        _profileImageFile = null;
      });
      
      scaffoldMessengerContext.showSnackBar(
        const SnackBar(
          content: Text('Profile photo removed'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  
  // Helper method to pick image
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    // Store context references before async operations
    final scaffoldMessengerContext = ScaffoldMessenger.of(context);
    
    try {
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (!mounted) return;
      
      if (image != null) {
        setState(() {
          _profileImageFile = File(image.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      
      scaffoldMessengerContext.showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  
  // Show dialog to guide user to app settings
  void _showPermissionDeniedDialog(String permissionType) {
    // Store a reference to the navigator before async operations
    final navigator = Navigator.of(context);
    final currentContext = context;
    
    showDialog(
      context: currentContext,
      builder: (dialogContext) => AlertDialog(
        title: Text('$permissionType access'),
        content: Text(
          'We need access to your $permissionType for profile photo. '
          'Please grant permission in app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              navigator.pop();
              await openAppSettings();
            },
            child: const Text('OPEN SETTINGS'),
          ),
        ],
      ),
    );
  }
  
  void _saveProfile() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    
    // Store context reference before async operation
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    setState(() {
      _isLoading = true;
    });
    
    // Get updated user data from form
    Map<String, dynamic> userData = {};
    
    // Required fields
    if (_controllers.containsKey('firstName')) {
      userData['first_name'] = _controllers['firstName']!.text;
    }
    
    if (_controllers.containsKey('lastName')) {
      userData['last_name'] = _controllers['lastName']!.text;
    }
    
    if (_controllers.containsKey('email')) {
      userData['email'] = _controllers['email']!.text;
    }
    
    // Bio is now required
    if (_controllers.containsKey('bio')) {
      userData['bio'] = _controllers['bio']!.text;
    }
    
    // Optional fields - only include if they're not empty
    if (_controllers.containsKey('middleName') && _controllers['middleName']!.text.isNotEmpty) {
      userData['middle_name'] = _controllers['middleName']!.text;
    }
    
    if (_controllers.containsKey('suffix') && _controllers['suffix']!.text.isNotEmpty) {
      userData['suffix'] = _controllers['suffix']!.text;
    }
    
    // Password fields - only include if new password is provided
    if (_controllers.containsKey('password') && 
        _controllers['password']!.text.isNotEmpty &&
        _controllers.containsKey('passwordConfirmation') &&
        _controllers['passwordConfirmation']!.text.isNotEmpty) {
      
      userData['password'] = _controllers['password']!.text;
      userData['password_confirmation'] = _controllers['passwordConfirmation']!.text;
    }
    
    try {
      final success = await authProvider.updateProfile(
        data: userData,
        imagePath: _profileImageFile?.path,
      );
      
      // Check if widget is still mounted before using setState
      if (!mounted) return;
      
      if (success) {
        // Exit edit mode
        setState(() {
          _isLoading = false;
          _isEditing = false;
          _profileImageFile = null; // Clear the file reference after successful upload
        });
        
        // Show success message
        _showSuccessSnackBar();
      } else {
        // Show error
        setState(() {
          _isLoading = false;
        });
        
        // Use stored scaffoldMessenger reference
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error: ${authProvider.error ?? "Unknown error"}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Check if widget is still mounted before using setState
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      // Use stored scaffoldMessenger reference
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _showSuccessSnackBar() {
    final snackBar = SnackBar(
      content: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: Colors.white,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Profile updated successfully',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.all(12),
      duration: const Duration(seconds: 3),
      action: SnackBarAction(
        label: 'DISMISS',
        textColor: Colors.white,
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      ),
    );
    
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
  
  bool _isValidEmail(String email) {
    // Simple email validation
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
  
  // Add the profile image section
  Widget _buildProfileImageSection() {
    final theme = Theme.of(context);
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              // Profile image
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.primary.withAlpha(100),
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(60),
                  child: _profileImageFile != null
                      ? Image.file(
                          _profileImageFile!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            // Handle local image loading error
                            debugPrint('Error loading profile image file: $error');
                            return Center(
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                color: theme.colorScheme.error,
                                size: 40,
                              ),
                            );
                          },
                        )
                      : user?.profileImage != null
                          ? Stack(
                              alignment: Alignment.center,
                              children: [
                                // Professional preloader for image loading
                                SharedPreloader(size: 30.0),
                                // Network image with loading/error handling
                                Image.network(
                                  user!.profileImage!,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return SharedPreloader(size: 30.0);
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    // Handle network image loading error by showing initials
                                    debugPrint('Error loading profile image: $error');
                                    return Center(
                                      child: Text(
                                        user.initials,
                                        style: TextStyle(
                                          fontSize: 40,
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            )
                          : Center(
                              child: Text(
                                user?.initials ?? 'U',
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                ),
              ),
              
              // Edit button
              Positioned(
                bottom: 0,
                right: 0,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _showChangeProfilePhotoOptions,
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: theme.shadowColor.withAlpha(77),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Tap to change profile photo',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
  
  // Add confirmation dialog for canceling edit mode
  void _confirmCancelEditing() {
    // Check if form has changes before showing dialog
    bool hasChanges = false;
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    
    if (user != null) {
      // Check for changes in each field
      if (_controllers['firstName']!.text != user.firstName ||
          _controllers['lastName']!.text != user.lastName ||
          _controllers['email']!.text != user.email ||
          (_controllers['middleName']!.text != (user.middleName ?? '')) ||
          (_controllers['suffix']!.text != (user.suffix ?? '')) ||
          (_controllers['bio']!.text != (user.bio ?? '')) ||
          _controllers['password']!.text.isNotEmpty ||
          _profileImageFile != null) {
        hasChanges = true;
      }
    }
    
    // If no changes, just exit edit mode without confirmation
    if (!hasChanges) {
      setState(() {
        _isEditing = false;
        _profileImageFile = null;
      });
      return;
    }
    
    // Show confirmation dialog for unsaved changes
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Discard Changes?'),
          content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Keep Editing'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                
                // Reset form and exit edit mode
                _initializeControllers(); // Reset to original values
                setState(() {
                  _isEditing = false;
                  _profileImageFile = null;
                });
              },
              child: const Text(
                'Discard',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
} 