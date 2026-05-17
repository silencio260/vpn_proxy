class AppAssets {
  static const String loadingLottie = 'assets/lottie/loading.json';
  static const String worldImage = 'assets/images/world.png';
  static const String shieldHead = 'assets/images/head.png';
  static const String shieldLeft = 'assets/images/left.png';
  static const String shieldRight = 'assets/images/right.png';

  static String flagAsset(String countryShort) =>
      'assets/flags/${countryShort.toLowerCase()}.png';
}
