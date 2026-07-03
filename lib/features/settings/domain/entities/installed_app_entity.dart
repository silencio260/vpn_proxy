import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// A user-visible installed application, as listed on the split-tunneling
/// screen. Kept as a domain type so the UI never depends on the
/// `installed_apps` plugin's `AppInfo` directly.
class InstalledAppEntity extends Equatable {
  final String name;
  final String packageName;
  final Uint8List? icon;

  const InstalledAppEntity({
    required this.name,
    required this.packageName,
    this.icon,
  });

  @override
  List<Object?> get props => [name, packageName];
}
