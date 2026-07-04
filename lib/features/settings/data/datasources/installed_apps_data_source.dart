import 'dart:io' show Platform;

import 'package:installed_apps/installed_apps.dart';

import '../../../../core/constants/app_packages.dart';
import '../../domain/entities/installed_app_entity.dart';

/// Lists the device's user-launchable apps for the split-tunneling picker.
/// Wraps the `installed_apps` plugin so the rest of the app only sees
/// [InstalledAppEntity]. Android-only — returns an empty list elsewhere.
///
/// The manifest declares a MAIN/LAUNCHER `<queries>` entry (not the sensitive
/// QUERY_ALL_PACKAGES permission), so on Android 11+ only apps with a launcher
/// icon are visible here — which is exactly the set worth offering for
/// exclusion.
abstract class InstalledAppsDataSource {
  Future<List<InstalledAppEntity>> getInstalledApps();
}

class InstalledAppsDataSourceImpl implements InstalledAppsDataSource {
  @override
  Future<List<InstalledAppEntity>> getInstalledApps() async {
    if (!Platform.isAndroid) return const [];
    // positional args: excludeSystemApps, withIcon
    final apps = await InstalledApps.getInstalledApps(true, true);
    // Hide our own app: it is always force-excluded from the tunnel by the
    // proxy engine, so users must not be able to toggle it here.
    final list = apps
        .where((a) => a.packageName != kOwnPackageName)
        .map((a) => InstalledAppEntity(
              name: a.name,
              packageName: a.packageName,
              icon: a.icon,
            ))
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }
}
