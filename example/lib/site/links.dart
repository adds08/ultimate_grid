import 'package:url_launcher/url_launcher.dart';

/// Canonical external links (mirrors the repo README).
class Links {
  static const pubDev = 'https://pub.dev/packages/ultimate_grid';
  static const pubDocs = 'https://pub.dev/documentation/ultimate_grid/latest/';
  static const github = 'https://github.com/adds08/ultimate_grid';
  static const githubStars =
      'https://github.com/adds08/ultimate_grid/stargazers';

  /// shields.io badge image URLs (same as the README).
  static const badgePubVersion =
      'https://img.shields.io/pub/v/ultimate_grid.svg';
  static const badgePubPoints =
      'https://img.shields.io/pub/points/ultimate_grid';
  static const badgePubLikes = 'https://img.shields.io/pub/likes/ultimate_grid';
  static const badgeGithubStars =
      'https://img.shields.io/github/stars/adds08/ultimate_grid?style=flat&logo=github';
  static const badgeLicense =
      'https://img.shields.io/github/license/adds08/ultimate_grid';
}

Future<void> openExternal(String url) async {
  final uri = Uri.parse(url);
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
