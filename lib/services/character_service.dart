import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/character.dart';
import '../utils/sanitize.dart';

class PageCharacters {
  final List<Character> items;
  final int? nextPage;
  final int? prevPage;
  const PageCharacters({required this.items, this.nextPage, this.prevPage});
}

class _CacheEntry<T> {
  final T value;
  final DateTime expiresAt;
  _CacheEntry(this.value, this.expiresAt);
  bool get isValid => DateTime.now().isBefore(expiresAt);
}

class CharacterService {
  CharacterService({required this.host, http.Client? client})
      : client = client ?? http.Client();

  final String host; // p.ej. rickandmortyapi.com
  final http.Client client;

  // Cache defensiva: TTL 5 minutos por consulta y página.
  final Map<String, _CacheEntry<PageCharacters>> _cache = {};
  Duration cacheTtl = const Duration(minutes: 5);

  Future<PageCharacters> search({
    required String rawName,
    String? rawStatus, // alive, dead, unknown
    String? rawSpecies,
    int page = 1,
  }) async {
    final name = sanitizeText(rawName, maxLen: 60);
    final v = _validateQuery(name);
    if (v != null) throw ArgumentError(v);

    String? status = sanitizeText(rawStatus ?? '', maxLen: 16).toLowerCase();
    if (status.isEmpty || status == 'any') status = null;
    String? species = sanitizeText(rawSpecies ?? '', maxLen: 40);
    if (species.isEmpty) species = null;

    final cacheKey = _cacheKey(name: name, status: status, species: species, page: page);
    final cached = _cache[cacheKey];
    if (cached != null && cached.isValid) return cached.value;

    final queryParams = <String, String>{
      'name': name,
      'page': page.toString(),
    };
    if (status != null) queryParams['status'] = status;
    if (species != null) queryParams['species'] = species;

    final uri = Uri.https(host, '/api/character', queryParams);
    final response = await _getWithRetry(uri);

    if (response.statusCode == 200) {
      final map = json.decode(response.body) as Map<String, dynamic>;
      final results = (map['results'] as List<dynamic>?) ?? [];
      final list = results
          .whereType<Map<String, dynamic>>()
          .map(Character.fromJson)
          .toList(growable: false);

      int? nextPage;
      int? prevPage;
      final info = map['info'] as Map<String, dynamic>?;
      final nextUrl = info?['next']?.toString();
      final prevUrl = info?['prev']?.toString();
      if (nextUrl != null && nextUrl.isNotEmpty) {
        final qp = Uri.parse(nextUrl).queryParameters['page'];
        nextPage = int.tryParse(qp ?? '');
      }
      if (prevUrl != null && prevUrl.isNotEmpty) {
        final qp = Uri.parse(prevUrl).queryParameters['page'];
        prevPage = int.tryParse(qp ?? '');
      }

      final pageResult = PageCharacters(items: list, nextPage: nextPage, prevPage: prevPage);
      _cache[cacheKey] = _CacheEntry(pageResult, DateTime.now().add(cacheTtl));
      return pageResult;
    }

    if (response.statusCode == 404) {
      return const PageCharacters(items: <Character>[], nextPage: null, prevPage: null);
    }

    if (response.statusCode >= 500 && response.statusCode <= 599) {
      throw StateError('Error del servidor (${response.statusCode}).');
    }

    throw StateError('Error ${response.statusCode}: ${response.reasonPhrase ?? 'desconocido'}');
  }

  Future<http.Response> _getWithRetry(Uri uri) async {
    const maxAttempts = 3;
    const baseDelayMs = 400;

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        final response = await client
            .get(uri)
            .timeout(const Duration(seconds: 8));

        if (_shouldRetryStatus(response.statusCode) && attempt < maxAttempts - 1) {
          final delay = Duration(milliseconds: baseDelayMs * (1 << attempt));
          await Future.delayed(delay);
          continue;
        }
        return response;
      } on TimeoutException {
        if (attempt < maxAttempts - 1) {
          final delay = Duration(milliseconds: baseDelayMs * (1 << attempt));
          await Future.delayed(delay);
          continue;
        }
        rethrow;
      }
    }
    throw StateError('Falló la solicitud después de múltiples intentos.');
  }

  bool _shouldRetryStatus(int code) {
    if (code >= 500 && code <= 599) return true; // errores del servidor
    return false;
  }

  String? _validateQuery(String q) {
    if (q.isEmpty) return 'Ingresa un nombre';
    if (q.length < 2) return 'La búsqueda es muy corta';
    final allowed = RegExp(r"^[A-Za-zÁÉÍÓÚÜÑáéíóúüñ ,.'-]{2,}$");
    if (!allowed.hasMatch(q)) {
      return 'Solo letras, espacios y puntuación básica (.-\' )';
    }
    return null;
  }

  String _cacheKey({required String name, String? status, String? species, required int page}) {
    return 'n=$name|s=${status ?? '-'}|sp=${species ?? '-'}|p=$page'.toLowerCase();
  }
}
