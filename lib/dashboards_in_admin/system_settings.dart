import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class SystemSettingsPage extends StatefulWidget {
  const SystemSettingsPage({super.key});

  @override
  State<SystemSettingsPage> createState() => _SystemSettingsPageState();
}

class _SystemSettingsPageState extends State<SystemSettingsPage> {
  bool emailNotifications = true;
  bool smsNotifications = false;
  bool autoApproval = false;
  bool maintenanceMode = false;
  String selectedTheme = 'Light';

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _saveSettings() async {
    _showSnackBar('Settings saved successfully', Colors.green);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('System Settings'),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildSectionCard(
              'Notification Settings',
              [
                _buildSwitchTile(
                  'Email Notifications',
                  'Send email notifications to users',
                  emailNotifications,
                      (value) => setState(() => emailNotifications = value),
                  Icons.email,
                ),
                _buildSwitchTile(
                  'SMS Notifications',
                  'Send SMS notifications to users',
                  smsNotifications,
                      (value) => setState(() => smsNotifications = value),
                  Icons.sms,
                ),
              ],
            ),
            _buildSectionCard(
              'Activity Management',
              [
                _buildSwitchTile(
                  'Auto Approval',
                  'Automatically approve activities meeting criteria',
                  autoApproval,
                      (value) => setState(() => autoApproval = value),
                  Icons.verified,
                ),
              ],
            ),
            _buildSectionCard(
              'System Configuration',
              [
                _buildSwitchTile(
                  'Maintenance Mode',
                  'Put system in maintenance mode',
                  maintenanceMode,
                      (value) => setState(() => maintenanceMode = value),
                  Icons.build,
                ),
                ListTile(
                  leading: Icon(Icons.palette, color: Colors.teal.shade700),
                  title: const Text('Theme', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Select application theme'),
                  trailing: DropdownButton<String>(
                    value: selectedTheme,
                    items: ['Light', 'Dark', 'System'].map((theme) {
                      return DropdownMenuItem(
                        value: theme,
                        child: Text(theme),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedTheme = value);
                      }
                    },
                  ),
                ),
              ],
            ),
            _buildSectionCard(
              'Database Management',
              [
                _buildActionTile(
                  'Backup Database',
                  'Create a backup of the database',
                  Icons.backup,
                      () => _showSnackBar('Database backup initiated', Colors.blue),
                ),
                _buildActionTile(
                  'Clear Cache',
                  'Clear all cached data',
                  Icons.delete_sweep,
                      () => _showSnackBar('Cache cleared successfully', Colors.green),
                ),
              ],
            ),
            _buildSectionCard(
              'Security Settings',
              [
                _buildActionTile(
                  'Password Policy',
                  'Configure password requirements',
                  Icons.security,
                      () => _showPasswordPolicyDialog(),
                ),
                _buildActionTile(
                  'Two-Factor Authentication',
                  'Configure 2FA settings',
                  Icons.shield,
                      () => _showSnackBar('2FA configuration opened', Colors.blue),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveSettings,
                  icon: const Icon(Icons.save),
                  label: const Text('Save All Settings'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
      String title,
      String subtitle,
      bool value,
      Function(bool) onChanged,
      IconData icon,
      ) {
    return SwitchListTile(
      secondary: Icon(icon, color: Colors.teal.shade700),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      value: value,
      onChanged: onChanged,
      activeColor: Colors.teal.shade700,
    );
  }

  Widget _buildActionTile(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.teal.shade700),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _showPasswordPolicyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Password Policy'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPolicyItem('Minimum length: 8 characters'),
            _buildPolicyItem('At least one uppercase letter'),
            _buildPolicyItem('At least one lowercase letter'),
            _buildPolicyItem('At least one number'),
            _buildPolicyItem('At least one special character'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar('Password policy updated', Colors.green);
            },
            child: const Text('Update Policy'),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.green.shade600),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}