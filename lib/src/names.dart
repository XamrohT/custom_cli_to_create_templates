/// Converte `meu_modulo` -> `MeuModulo`.
String toPascal(String snake) => snake
    .split('_')
    .where((p) => p.isNotEmpty)
    .map((p) => p[0].toUpperCase() + p.substring(1))
    .join();

/// Converte `Meu Projeto` / `meu-projeto` / `MeuProjeto` -> `meu_projeto`.
String toSnake(String input) => input
    .trim()
    .replaceAllMapped(RegExp(r'([a-z0-9])([A-Z])'), (m) => '${m[1]}_${m[2]}')
    .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
    .toLowerCase();

final _validName = RegExp(r'^[a-z][a-z0-9_]*$');
bool isValidPackageName(String n) => _validName.hasMatch(n);
