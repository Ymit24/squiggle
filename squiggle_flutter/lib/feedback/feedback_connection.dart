/// The report server the app sends bug reports and ideas to.
class FeedbackConnection {
  const FeedbackConnection({required this.serverUrl, required this.apiToken});

  final Uri serverUrl;
  final String apiToken;

  Map<String, String> get authHeaders => {'Authorization': 'Bearer $apiToken'};

  /// Resolves [path] under [serverUrl], keeping any path prefix it has.
  Uri endpoint(String path) {
    final base = serverUrl.path.endsWith('/')
        ? serverUrl
        : serverUrl.replace(path: '${serverUrl.path}/');
    return base.resolve(path);
  }

  /// An error message for [input], or null when it is a usable server URL.
  ///
  /// Plain `http` is only allowed for loopback so the token never crosses a
  /// network unencrypted.
  static String? validateServerUrl(String input) {
    final uri = Uri.tryParse(input.trim());
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return 'Enter a full URL, like https://example.ts.net';
    }
    if (uri.hasQuery || uri.hasFragment) {
      return 'The server URL cannot have a query or fragment.';
    }
    if (uri.scheme == 'https') return null;
    if (uri.scheme == 'http' && _isLoopback(uri.host)) return null;
    return "Use https:// so the token isn't sent in the clear.";
  }

  static bool _isLoopback(String host) =>
      host == 'localhost' || host == '127.0.0.1' || host == '::1';
}
