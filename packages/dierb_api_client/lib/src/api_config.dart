class DierbApiConfig {
  const DierbApiConfig({required this.baseUrl, this.timeout = const Duration(seconds: 20)});
  final String baseUrl;
  final Duration timeout;
  static const fromEnvironment = DierbApiConfig(baseUrl: String.fromEnvironment('DIERB_API_URL', defaultValue: 'http://10.0.2.2:3000'));
  Uri uri(String path, [Map<String,String>? query]) => Uri.parse('$baseUrl/v1/$path').replace(queryParameters: query);
}
