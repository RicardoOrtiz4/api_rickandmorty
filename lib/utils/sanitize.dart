/// Sanitiza texto plano para UI.
/// - Elimina caracteres de control.
/// - Sustituye '<' y '>' por vacíos.
/// - Colapsa espacios.
String sanitizeText(String input, {int maxLen = 80}) {
  var s = input
      .replaceAll(RegExp(r"[\x00-\x1F\x7F]"), "")
      .replaceAll('<', '')
      .replaceAll('>', '')
      .trim();
  s = s.replaceAll(RegExp(r"\s+"), ' ');
  if (s.length > maxLen) s = s.substring(0, maxLen);
  return s;
}

/// Valida una ciudad básica: letras (incluye acentos), espacios, comas y guiones.
/// Retorna null si es válida, o el mensaje de error si no lo es.
String? validateCity(String input) {
  final value = sanitizeText(input);
  if (value.isEmpty) return 'Ingresa una ciudad';
  if (value.length < 2) return 'La ciudad es muy corta';
  final allowed = RegExp(r"^[A-Za-zÁÉÍÓÚÜÑáéíóúüñ ,.-]{2,}$");
  if (!allowed.hasMatch(value)) {
    return 'Solo letras, espacios, coma, punto y guiones';
  }
  return null;
}

