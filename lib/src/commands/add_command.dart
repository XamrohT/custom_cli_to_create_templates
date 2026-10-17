import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../names.dart';
import '../process_runner.dart';

class AddCommand extends Command<int> {
  @override
  final name = 'add';
  @override
  final description = 'Adiciona partes ao projeto atual.';

  AddCommand() {
    addSubcommand(_AddModuleCommand());
  }
}

/// Gera `lib/modules/<nome>/` (módulo + repository + use case + store + view) e registra no AppModule.
class _AddModuleCommand extends Command<int> {
  @override
  final name = 'module';
  @override
  final description = 'Cria um módulo (Modular + MobX + UseCase + Repository).';
  @override
  String get invocation => 'custom_cli_to_create_templates add module <nome_snake_case>';

  _AddModuleCommand() {
    argParser.addFlag('install',
        defaultsTo: true, help: 'Roda build_runner no final.');
  }

  @override
  Future<int> run() async {
    if (argResults!.rest.length != 1)
      usageException('Informe o nome do módulo.');
    final mod = toSnake(argResults!.rest.first);
    if (!isValidPackageName(mod))
      usageException('Nome inválido: use snake_case.');
    final pascal = toPascal(mod);

    final pubspec = File('pubspec.yaml');
    if (!pubspec.existsSync())
      usageException('Rode dentro da raiz de um projeto Flutter.');
    final pkg = RegExp(r'^name:\s*(\S+)', multiLine: true)
        .firstMatch(pubspec.readAsStringSync())![1]!;

    final base = p.join('lib', 'modules', mod);
    if (Directory(base).existsSync())
      usageException('lib/modules/$mod já existe.');
    final appModule = File(p.join('lib', 'modules', 'app', 'app_module.dart'));
    if (!appModule.existsSync())
      usageException('lib/modules/app/app_module.dart não encontrado.');

    void write(String rel, String content) {
      File(p.join(base, rel))
        ..createSync(recursive: true)
        ..writeAsStringSync(content);
    }

    write('${mod}_module.dart', '''
import 'package:flutter_modular/flutter_modular.dart';
import 'package:$pkg/modules/$mod/repositories/${mod}_repository.dart';
import 'package:$pkg/modules/$mod/stores/${mod}_store.dart';
import 'package:$pkg/modules/$mod/use_cases/get_${mod}_use_case.dart';
import 'package:$pkg/modules/$mod/views/${mod}_screen.dart';

class ${pascal}Module extends Module {
  static const String route = '/$mod';

  @override
  List<Bind> get binds => [
        Bind.singleton<${pascal}Repository>((i) => InMemory${pascal}Repository()),
        Bind.singleton((i) => Get${pascal}UseCase(i<${pascal}Repository>())),
        Bind.singleton((i) => ${pascal}Store(getUseCase: i<Get${pascal}UseCase>())),
      ];

  @override
  List<ModularRoute> get routes => [
        ChildRoute('/', child: (_, __) => const ${pascal}Screen()),
      ];
}
''');
    write('repositories/${mod}_repository.dart', '''
abstract interface class ${pascal}Repository {
  Future<String> get();
}

class InMemory${pascal}Repository implements ${pascal}Repository {
  @override
  Future<String> get() async => '$pascal';
}
''');
    write('use_cases/get_${mod}_use_case.dart', '''
import 'package:$pkg/core/protocols/use_case.dart';
import 'package:$pkg/modules/$mod/repositories/${mod}_repository.dart';

class Get${pascal}UseCase implements UseCase<String, void> {
  final ${pascal}Repository _repository;

  Get${pascal}UseCase(this._repository);

  @override
  Future<String> execute(void params) => _repository.get();
}
''');
    write('stores/${mod}_store.dart', '''
import 'package:mobx/mobx.dart';
import 'package:$pkg/modules/$mod/use_cases/get_${mod}_use_case.dart';

part '${mod}_store.g.dart';

class ${pascal}Store = ${pascal}StoreBase with _\$${pascal}Store;

abstract class ${pascal}StoreBase with Store {
  final Get${pascal}UseCase _getUseCase;

  ${pascal}StoreBase({required Get${pascal}UseCase getUseCase}) : _getUseCase = getUseCase;

  @observable
  String? data;

  @observable
  bool loading = false;

  @action
  Future<void> load() async {
    loading = true;
    try {
      data = await _getUseCase.execute(null);
    } finally {
      loading = false;
    }
  }
}
''');
    write('views/${mod}_screen.dart', '''
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:$pkg/modules/$mod/stores/${mod}_store.dart';

class ${pascal}Screen extends StatefulWidget {
  const ${pascal}Screen({super.key});

  @override
  State<${pascal}Screen> createState() => _${pascal}ScreenState();
}

class _${pascal}ScreenState extends State<${pascal}Screen> {
  final store = Modular.get<${pascal}Store>();

  @override
  void initState() {
    super.initState();
    store.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('$pascal')),
      body: Center(
        child: Observer(
          builder: (_) => store.loading ? const CircularProgressIndicator() : Text(store.data ?? ''),
        ),
      ),
    );
  }
}
''');

    // Registra a rota no AppModule.
    var text = appModule.readAsStringSync();
    // Preserva o fim de linha do arquivo (CRLF no Windows com autocrlf).
    final eol = text.contains('\r\n') ? '\r\n' : '\n';
    final importLine =
        "import 'package:$pkg/modules/$mod/${mod}_module.dart';$eol";
    final routeLine =
        '        ModuleRoute(${pascal}Module.route, module: ${pascal}Module()),$eol';

    final imports = RegExp(r'^import .*;[ \t]*\r?\n', multiLine: true)
        .allMatches(text)
        .toList();
    final importAt = imports.isEmpty ? 0 : imports.last.end;
    text = text.replaceRange(importAt, importAt, importLine);

    final routes = RegExp(r'List<ModularRoute> get routes => \[[ \t]*\r?\n')
        .firstMatch(text);
    if (routes == null) {
      stdout.writeln(
          'Não achei a lista de rotas: registre ${pascal}Module manualmente.');
    } else {
      text = text.replaceRange(routes.end, routes.end, routeLine);
    }

    appModule.writeAsStringSync(text);

    stdout.writeln(
        'Módulo "$mod" criado em $base e registrado em ${pascal}Module.route (/$mod).');
    if (argResults!['install'] as bool) {
      await runProcess('dart',
          ['run', 'build_runner', 'build', '--delete-conflicting-outputs']);
    }
    return 0;
  }
}
