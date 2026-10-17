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

/// `meu_projeto` / `Meu Projeto` -> `meu-projeto`.
String toKebab(String input) => toSnake(input).replaceAll('_', '-');

final _validKebab = RegExp(r'^[a-z][a-z0-9]*(-[a-z0-9]+)*$');
bool isValidKebabName(String n) => _validKebab.hasMatch(n);

/// `meu-app` / `meu_app` -> `Meu App`.
String toTitle(String name) => name
    .split(RegExp(r'[-_]'))
    .where((w) => w.isNotEmpty)
    .map((w) => w[0].toUpperCase() + w.substring(1))
    .join(' ');
