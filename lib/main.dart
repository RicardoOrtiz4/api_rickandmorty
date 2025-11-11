import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'models/character.dart';
import 'services/character_service.dart';
import 'utils/sanitize.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env', isOptional: true);
  runApp(const RickMortyApp());
}

class RickMortyApp extends StatelessWidget {
  const RickMortyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final host = dotenv.env['RICKMORTY_HOST'] ?? 'rickandmortyapi.com';
    return MaterialApp(
      title: 'Rick and Morty',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: HomePage(service: CharacterService(host: host)),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.service});
  final CharacterService service;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _controller = TextEditingController();
  final _speciesController = TextEditingController();
  final _scroll = ScrollController();

  // Estado de datos y paginación
  final List<Character> _items = [];
  int? _nextPage;
  bool _loading = false;
  String? _error;
  String _status = 'any';

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_nextPage != null && !_loading) {
        if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 200) {
          _loadPage(_nextPage!);
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _speciesController.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _search() {
    setState(() {
      _error = null;
      _items.clear();
      _nextPage = null;
    });
    _loadPage(1);
  }

  Future<void> _loadPage(int page) async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final res = await widget.service.search(
        rawName: _controller.text,
        rawStatus: _status,
        rawSpecies: _speciesController.text,
        page: page,
      );
      setState(() {
        _items.addAll(res.items);
        _nextPage = res.nextPage;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rick and Morty')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Personaje (e.g., Rick, Morty)',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'any', child: Text('Any')),
                      DropdownMenuItem(value: 'alive', child: Text('Alive')),
                      DropdownMenuItem(value: 'dead', child: Text('Dead')),
                      DropdownMenuItem(value: 'unknown', child: Text('Unknown')),
                    ],
                    onChanged: (v) => setState(() => _status = v ?? 'any'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _speciesController,
                    decoration: const InputDecoration(
                      labelText: 'Species (opcional)',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _search,
              icon: const Icon(Icons.search),
              label: const Text('Buscar'),
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Text(
                sanitizeText(_error!),
                style: const TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: _buildResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_items.isEmpty && !_loading && _error == null) {
      return const Center(
        child: Text('Ingresa un nombre para buscar personajes.'),
      );
    }
    if (_items.isEmpty && _loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items.isEmpty && _error != null) {
      return Center(
        child: Text(
          sanitizeText(_error!),
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    return ListView.builder(
      controller: _scroll,
      itemCount: _items.length + ((_loading || _nextPage != null) ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < _items.length) {
          final c = _items[index];
          return _CharacterTile(character: c);
        }
        if (_loading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: OutlinedButton(
              onPressed: () {
                if (_nextPage != null) _loadPage(_nextPage!);
              },
              child: const Text('Cargar más'),
            ),
          ),
        );
      },
    );
  }
}

class _CharacterTile extends StatelessWidget {
  const _CharacterTile({required this.character});
  final Character character;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(character.imageUrl),
        ),
        title: Text(sanitizeText(character.name)),
        subtitle: Text('${sanitizeText(character.species)} • ${sanitizeText(character.status)}'),
      ),
    );
  }
}