import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

class ScanResultScreen extends StatelessWidget {
  final Map<String, dynamic> studentData;

  const ScanResultScreen({super.key, required this.studentData});

  Future<void> _callOwner(BuildContext context, String phoneNumber) async {
    final Uri url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch dialer.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Found Item Details', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.check_circle, size: 80, color: Colors.green),
            const SizedBox(height: 16),
            const Text(
              'Owner Found!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.person, color: theme.primary),
                      title: const Text('Owner Name', style: TextStyle(color: Colors.grey)),
                      subtitle: Text(
                        studentData['name'],
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: Icon(Icons.phone, color: theme.primary),
                      title: const Text('Phone Number', style: TextStyle(color: Colors.grey)),
                      subtitle: Text(
                        studentData['phone'], // Masked phone number from API
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87, letterSpacing: 1),
                      ),
                    ),
                    if (studentData['email'] != null && studentData['email'].toString().isNotEmpty) ...[
                      const Divider(),
                      ListTile(
                        leading: Icon(Icons.email, color: theme.primary),
                        title: const Text('Email Address', style: TextStyle(color: Colors.grey)),
                        subtitle: Text(
                          studentData['email'],
                          style: const TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () => _callOwner(context, studentData['rawPhone']),
              icon: const Icon(Icons.phone),
              label: const Text('Call Owner (Secure)'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: theme.primary,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                context.push('/report', extra: studentData['studentId']);
              },
              icon: const Icon(Icons.report_problem),
              label: const Text('Report Found Item'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                padding: const EdgeInsets.symmetric(vertical: 16),
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
