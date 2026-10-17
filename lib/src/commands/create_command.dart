import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../names.dart';
import '../process_runner.dart';
import '../template_source.dart';

const _tplPackage = 'flutter_backoffice_template';

/// Itens do template Flutter que não devem ir para o projeto novo.
const _flutterSkip = {
  '.git',
  '.metadata',
  'pubspec.lock',
  'tool',
  'build',
  '.dart_tool'
};

/// Itens dos templates React/Nest que não devem ir para o projeto novo.
const _nodeSkip = {'.git', 'node_modules', 'dist', 'coverage', '.env'};

class CreateCommand extends Command<int> {
  @override
  final name = 'create';
  @override
  final description =
      'Cria um projeto (Flutter, React ou Nest) já com a estrutura do template.';
  @override
  String get invocation =>
      'custom_cli_to_create_templates create <nome_do_projeto> [--stack flutter|react|nest]';

  CreateCommand() {
    argParser
      ..addOption('stack',
          abbr: 's',
          allowed: stacks,
          defaultsTo: 'flutter',
          help: 'Tipo de projeto.',
          allowedHelp: {
            'flutter': 'App Flutter (Modular + MobX + Dio). Nome em snake_case.',
            'react': 'Front React + Vite modular. Nome em kebab-case.',
            'nest': 'API NestJS em clean architecture. Nome em kebab-case.',
          })
      ..addOption('org',
          abbr: 'o',
          defaultsTo: 'br.com.example',
          help: '[flutter] Organização (applicationId).')
      ..addOption('title',
          abbr: 't', help: 'Título do app/API. Padrão: nome em Title Case.')
      ..addOption('template',
          help: 'URL git ou pasta local do template. Padrão: o da stack.')
      ..addOption('ref',
          help: 'Branch ou tag do template (padrão: branch principal).')
      ..addFlag('git', defaultsTo: true, help: 'Roda git init no projeto novo.')
      ..addOption('platforms',
          defaultsTo: 'web,android,ios',
          help: '[flutter] Plataformas do flutter create.')
      ..addFlag('install',
          defaultsTo: true,
          help: 'Instala dependências (flutter: pub get + geradores; react/nest: npm install).');
  }

  @override
  Future<int> run() async {
    if (argResults!.rest.length != 1) {
      usageException('Informe o nome do projeto.');
    }
    final stack = argResults!['stack'] as String;
    if (stack != 'flutter') {
      for (final o in ['org', 'platforms']) {
        if (argResults!.wasParsed(o)) {
          usageException('--$o só vale para --stack flutter.');
        }
      }
    }
    final template =
        (argResults!['template'] as String?) ?? defaultTemplates[stack]!;
    final ref = argResults!['ref'] as String?;
    final raw = argResults!.rest.first;

    return stack == 'flutter'
        ? _createFlutter(raw, template, ref)
        : _createNode(stack, raw, template, ref);
  }

  Future<int> _createFlutter(String projectName, String template, String? ref) async {
    if (!isValidPackageName(projectName)) {
      usageException(
          'Nome inválido "$projectName": use snake_case (ex.: meu_app).');
    }
    final org = argResults!['org'] as String;
    final title = (argResults!['title'] as String?) ?? toTitle(projectName);
    if (Directory(projectName).existsSync()) {
      usageException('A pasta "$projectName" já existe.');
    }

    // 1. Plataformas atualizadas vindas do próprio Flutter.
    await runProcess('flutter', [
      'create',
      '--empty',
      '--org',
      org,
      '--project-name',
      projectName,
      '--platforms',
      argResults!['platforms'] as String,
      projectName,
    ]);

    // 2. Obtém o template (clone raso em pasta temporária ou pasta local).
    final source = await TemplateSource.open(template, ref: ref);
    try {
      for (final d in ['lib', 'test']) {
        final dir = Directory(p.join(projectName, d));
        if (dir.existsSync()) dir.deleteSync(recursive: true);
      }
      final count = await _copy(source.dir, projectName, _flutterSkip,
          protectedRoots: const {
            'android',
            'ios',
            'web',
            'windows',
            'linux',
            'macos'
          },
          transform: (text) => text
              .replaceAll(_tplPackage, projectName)
              .replaceAll('Flutter Template', title)
              .replaceAll('Template Flutter', title));
      stdout.writeln('Template aplicado ($count arquivos).');
    } finally {
      source.dispose();
    }

    // 3. Dependências e geradores.
    if (argResults!['install'] as bool) {
      await runProcess('flutter', ['pub', 'get'], cwd: projectName);
      await runProcess('flutter', ['pub', 'run', 'intl_utils:generate'],
          cwd: projectName);
      await runProcess('dart',
          ['run', 'build_runner', 'build', '--delete-conflicting-outputs'],
          cwd: projectName);
    }
    if (argResults!['git'] as bool) {
      await runProcess('git', ['init', '-q', '-b', 'main'], cwd: projectName);
    }
    stdout.writeln('\nPronto! cd $projectName && flutter run -d chrome');
    return 0;
  }

  Future<int> _createNode(
      String stack, String raw, String template, String? ref) async {
    final projectName = toKebab(raw);
    if (!isValidKebabName(projectName)) {
      usageException(
          'Nome inválido "$raw": use kebab-case (ex.: meu-projeto).');
    }
    final title = (argResults!['title'] as String?) ?? toTitle(projectName);
    if (Directory(projectName).existsSync()) {
      usageException('A pasta "$projectName" já existe.');
    }

    final source = await TemplateSource.open(template, ref: ref);
    try {
      final count = await _copy(source.dir, projectName, _nodeSkip);
      stdout.writeln('Template aplicado ($count arquivos).');
    } finally {
      source.dispose();
    }

    // O template traz o próprio script de renomear; roda e remove, pois só serve uma vez.
    if (File(p.join(projectName, 'tool', 'rename-project.mjs')).existsSync()) {
      await runProcess('npm', ['run', 'rename', '--', projectName, title],
          cwd: projectName);
      File(p.join(projectName, 'tool', 'rename-project.mjs')).deleteSync();
      _removeScript(p.join(projectName, 'package.json'), 'rename');
    }

    if (argResults!['install'] as bool) {
      await runProcess('npm', ['install'], cwd: projectName);
    }
    if (argResults!['git'] as bool) {
      await runProcess('git', ['init', '-q', '-b', 'main'], cwd: projectName);
    }
    final run = stack == 'react'
        ? 'npm run dev'
        : 'cp .env.example .env && npm run start:dev';
    stdout.writeln('\nPronto! cd $projectName && $run');
    return 0;
  }
}

/// Copia o template para [dest] sem os itens de [skip]. Devolve quantos arquivos copiou.
Future<int> _copy(Directory src, String dest, Set<String> skip,
    {Set<String> protectedRoots = const {},
    String Function(String)? transform}) async {
  var count = 0;
  await for (final e in src.list(recursive: true, followLinks: false)) {
    if (e is! File) continue;
    final rel = p.relative(e.path, from: src.path);
    final parts = p.split(rel);
    if (parts.any(skip.contains)) continue;
    // Não sobrescreve as plataformas geradas pelo flutter create.
    if (protectedRoots.contains(parts.first)) continue;
    final out = File(p.join(dest, rel))..createSync(recursive: true);
    if (transform == null) {
      await e.copy(out.path);
    } else {
      out.writeAsStringSync(transform(await e.readAsString()));
    }
    count++;
  }
  return count;
}

/// Remove uma entrada de `scripts` do package.json (reescreve o JSON, preservando a ordem).
void _removeScript(String packageJson, String script) {
  final file = File(packageJson);
  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  (json['scripts'] as Map<String, dynamic>?)?.remove(script);
  file.writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(json)}\n');
}
