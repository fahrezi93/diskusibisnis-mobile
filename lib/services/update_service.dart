import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';

/// Service to check for app updates
class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  /// Check if update is available
  Future<UpdateInfo?> checkForUpdate() async {
    try {
      final response = await http
          .get(
            Uri.parse('${AppConfig.apiUrl}/app/version'),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final versionData = data['data'];
          final packageInfo = await PackageInfo.fromPlatform();

          final currentVersion = packageInfo.version;
          final latestVersion = versionData['version'];
          final minVersion = versionData['minVersion'];
          final forceUpdate = versionData['forceUpdate'] ?? false;

          // Compare versions
          final needsUpdate =
              _compareVersions(currentVersion, latestVersion) < 0;
          final mustUpdate =
              _compareVersions(currentVersion, minVersion) < 0 || forceUpdate;

          if (needsUpdate) {
            return UpdateInfo(
              currentVersion: currentVersion,
              latestVersion: latestVersion,
              downloadUrl: versionData['downloadUrl'],
              releaseNotes: versionData['releaseNotes'],
              forceUpdate: mustUpdate,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking for update: $e');
    }
    return null;
  }

  /// Compare two version strings
  /// Returns -1 if v1 < v2, 0 if v1 == v2, 1 if v1 > v2
  int _compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final parts2 = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    // Pad with zeros
    while (parts1.length < 3) parts1.add(0);
    while (parts2.length < 3) parts2.add(0);

    for (int i = 0; i < 3; i++) {
      if (parts1[i] < parts2[i]) return -1;
      if (parts1[i] > parts2[i]) return 1;
    }
    return 0;
  }

  /// Show update dialog
  Future<void> showUpdateDialog(
      BuildContext context, UpdateInfo updateInfo) async {
    return showDialog(
      context: context,
      barrierDismissible: !updateInfo.forceUpdate,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.system_update, color: Color(0xFF059669)),
            ),
            const SizedBox(width: 12),
            const Text('Update Tersedia'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Versi baru ${updateInfo.latestVersion} tersedia!',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Versi Anda: ${updateInfo.currentVersion}',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            if (updateInfo.releaseNotes != null) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Yang Baru:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                updateInfo.releaseNotes!,
                style: TextStyle(color: Colors.grey[700], fontSize: 13),
              ),
            ],
            if (updateInfo.forceUpdate) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red[700], size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Update ini wajib diinstall untuk melanjutkan.',
                        style: TextStyle(color: Colors.red[700], fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (!updateInfo.forceUpdate)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Nanti'),
            ),
          ElevatedButton(
            onPressed: () async {
              final url = Uri.parse(updateInfo.downloadUrl);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Download Update'),
          ),
        ],
      ),
    );
  }
}

class UpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final String downloadUrl;
  final String? releaseNotes;
  final bool forceUpdate;

  UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.downloadUrl,
    this.releaseNotes,
    this.forceUpdate = false,
  });
}
