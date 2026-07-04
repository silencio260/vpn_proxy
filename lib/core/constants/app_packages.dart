/// This app's own Android `applicationId`.
///
/// Kept in one place so the two features that must agree never drift:
///  • the split-tunnel picker hides this package (users can't toggle it), and
///  • the proxy engine always excludes it from the tunnel.
///
/// Must match `applicationId` in `android/app/build.gradle.kts`.
const String kOwnPackageName =
    'com.privatevpnproxy.proxifyprivatevpntunnel.vpn.proxy.vpn_proxy';
