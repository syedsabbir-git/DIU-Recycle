import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:diurecycle/Screen/login.dart';
import 'package:diurecycle/services/auth_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String _appVersion = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.green.shade800,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Account Section
                _buildSectionHeader('Account'),
                _buildSettingCard(
                  icon: Icons.person_outline,
                  title: 'Email',
                  subtitle: currentUser?.email ?? 'Not logged in',
                  trailing: null,
                ),
                const SizedBox(height: 12),

                // Safety & Privacy Section
                _buildSectionHeader('Safety & Privacy'),
                _buildSettingCard(
                  icon: Icons.flag_outlined,
                  title: 'Report a Problem',
                  subtitle: 'Report content or users',
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showReportOptions(context),
                ),
                const SizedBox(height: 8),
                _buildSettingCard(
                  icon: Icons.shield_outlined,
                  title: 'Privacy Policy',
                  subtitle: 'View our privacy policy',
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _launchPrivacyPolicy(),
                ),
                const SizedBox(height: 8),
                _buildSettingCard(
                  icon: Icons.delete_outline,
                  title: 'Delete Account',
                  subtitle: 'Permanently delete your account',
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showDeleteAccountDialog(context),
                  titleColor: Colors.red,
                ),
                const SizedBox(height: 12),

                // Support Section
                _buildSectionHeader('Support'),
                _buildSettingCard(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  subtitle: 'Get help with DIU Recycle',
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _launchSupport(),
                ),
                const SizedBox(height: 8),
                _buildSettingCard(
                  icon: Icons.info_outline,
                  title: 'About',
                  subtitle: 'Version $_appVersion',
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showAboutDialog(context),
                ),
                const SizedBox(height: 24),

                // Logout Button
                ElevatedButton.icon(
                  onPressed: () => _handleLogout(context),
                  icon: const Icon(Icons.logout),
                  label: const Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
                const SizedBox(height: 32),

                // Footer
                Center(
                  child: Text(
                    '© 2025 DIU Recycle\nSustainable Campus Marketplace',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? titleColor,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: titleColor ?? Colors.green.shade700,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: titleColor ?? Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  void _showReportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Report a Problem',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Help us keep DIU Recycle safe and trustworthy',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.shopping_bag_outlined, color: Colors.orange),
              title: const Text('Report a Product'),
              subtitle: const Text('Report inappropriate product listings'),
              onTap: () {
                Navigator.pop(context);
                _showReportInfo('To report a product, visit the product details page and tap the report icon.');
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline, color: Colors.blue),
              title: const Text('Report a User'),
              subtitle: const Text('Report user behavior or profile'),
              onTap: () {
                Navigator.pop(context);
                _showReportInfo('To report a user, visit their profile page and tap the report icon.');
              },
            ),
            ListTile(
              leading: const Icon(Icons.bug_report_outlined, color: Colors.red),
              title: const Text('Report a Bug'),
              subtitle: const Text('Technical issues with the app'),
              onTap: () {
                Navigator.pop(context);
                _launchSupport();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showReportInfo(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to Report'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Delete Account?',
          style: TextStyle(color: Colors.red),
        ),
        content: const Text(
          'This will permanently delete your account and all associated data including:\n\n'
          '• Your profile information\n'
          '• All product listings\n'
          '• Chat messages\n'
          '• Uploaded images\n\n'
          'This action cannot be undone.\n\n'
          'To delete your account, please contact us at:\n'
          'syedsabbirahmed.contact@gmail.com',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _launchEmail();
            },
            child: const Text(
              'Contact Support',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About DIU Recycle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: $_appVersion'),
            const SizedBox(height: 16),
            const Text(
              'DIU Recycle is a sustainable marketplace for the Daffodil International University community.',
            ),
            const SizedBox(height: 16),
            const Text(
              'Buy and sell used items, connect with fellow students, and promote sustainability on campus.',
            ),
            const SizedBox(height: 16),
            const Text(
              'Developer: Syed Sabbir Ahmed',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isLoading = true);

      try {
        await _authService.signout();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => LoginPage()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Logout failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _launchPrivacyPolicy() async {
    final url = Uri.parse('https://diurecycle.vercel.app');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open privacy policy')),
        );
      }
    }
  }

  Future<void> _launchSupport() async {
    await _launchEmail();
  }

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'syedsabbirahmed.contact@gmail.com',
      queryParameters: {
        'subject': 'DIU Recycle Support Request',
      },
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email: syedsabbirahmed.contact@gmail.com'),
          ),
        );
      }
    }
  }
}
