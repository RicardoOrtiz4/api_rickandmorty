# Rick and Morty App (Flutter)

Aplicación Flutter que consume la API pública de Rick and Morty con manejo de secretos (.env opcional), estados de UI (cargando/error/vacío), validación de entrada, sanitización de texto, timeouts, reintentos exponenciales y cache defensiva en memoria.

## Requisitos
- Flutter instalado (canal estable).
- No requiere API key (la API es pública). Se conserva `.env` para demostrar buenas prácticas.

## Configuración de secretos
1. Copia `.env.example` a `.env`:
   - Windows: `copy .env.example .env`
   - Mac/Linux: `cp .env.example .env`
2. (Opcional) Edita `.env` si deseas sobreescribir el host:
   ```
   RICKMORTY_HOST=rickandmortyapi.com
   ```
3. `.env` está ignorado por `.gitignore`.

## Inicialización del proyecto
Este repositorio incluye solo los archivos esenciales de `lib/` y `pubspec.yaml` para enfocarse en la lógica. Si aún no tienes las plataformas generadas, crea la estructura completa de Flutter en esta carpeta:

```bash
flutter create .
```

Luego instala dependencias:

```bash
flutter pub get
```

## Ejecución
- Emulador: inicia un emulador de Android/iOS y corre:
  ```bash
  flutter run
  ```
- Dispositivo físico: habilita la depuración y corre el mismo comando.

## Uso
- Ingresa el nombre de un personaje (por ejemplo, `Rick` o `Morty`).
- Filtra opcionalmente por `Status` (Any/Alive/Dead/Unknown) y `Species` (texto libre).
- Desplázate para cargar más (infinite scroll) o presiona "Cargar más".
- La app muestra: estados de carga, errores (incluye 404 sin resultados), y resultados en una lista con imagen, especie y estatus.

## Diseño técnico
- HTTP seguro: `Uri.https` + `http` con `timeout(Duration(seconds: 8))`.
- Secretos: `flutter_dotenv` lee `RICKMORTY_HOST` desde `.env` (opcional).
- Validación: solo letras, espacios, coma y guiones; longitud razonable.
- Sanitización: remueve caracteres de control y `<>`.
- Retry exponencial: reintenta ante `5xx` y `TimeoutException` (hasta 3 intentos, backoff 400ms, 800ms, 1600ms). La API no requiere API key; ante `404` se informa "sin resultados".
- Cache defensiva: TTL 5 minutos por consulta.

## Notas
- API: https://rickandmortyapi.com/documentation/#rest
- Docs Flutter: "Fetch data from the internet" (docs.flutter.dev)
- Puedes adaptar el servicio fácilmente para otras APIs.

## Evidencia
- Ejecuta en emulador y dispositivo; captura pantallas de los estados (vacío, cargando, error y éxito).
